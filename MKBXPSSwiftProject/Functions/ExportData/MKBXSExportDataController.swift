//
//  MKBXSExportDataController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import MessageUI

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBleModule

@MainActor
public final class MKBXSExportDataController: MKSwiftBaseViewController {

    // MARK: - Constants

    private let timeTextViewWidth: CGFloat = 130
    private let htTextViewWidth: CGFloat = 80
    private let htTextViewOffsetY: CGFloat = 160

    private var textBackViewHeight: CGFloat {
        MKScreen.height - MKLayout.topBarHeight - 170
    }

    private var textViewSpace: CGFloat {
        (MKScreen.width - 30 - timeTextViewWidth - 2 * htTextViewWidth) / 4
    }

    // MARK: - Properties

    private var hasHumidity: Bool = false

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var topView: MKBXSExportDataHeaderView = {
        let header = MKBXSExportDataHeaderView()
        header.delegate = self
        return header
    }()

    private lazy var filterView: MKBXSFilterHistoryDataView = {
        let view = MKBXSFilterHistoryDataView()
        view.delegate = self
        return view
    }()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.font = MKFont.font(13)
        tv.layoutManager.allowsNonContiguousLayout = false
        tv.isEditable = false
        tv.textColor = MKColor.defaultText
        return tv
    }()

    private lazy var textBackView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 2
        view.layer.borderColor = UIColor(red: 227/255.0, green: 227/255.0, blue: 227/255.0, alpha: 1).cgColor
        return view
    }()

    private lazy var curveContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private var parseTimer: DispatchSourceTimer?
    private var displayTimer: DispatchSourceTimer?
    private var receiveComplete: Bool = false

    private lazy var temperatureList: [String] = []
    private lazy var humidityList: [String] = []
    private lazy var dataList: [[String: Any]] = []
    private lazy var contentList: [String] = []

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return f
    }()

    private var runDate: Date = Date()
    private var textMsg: String = ""
    private lazy var maskView = MKBXSHistoryDataMaskView()

    private var totalCount: Int = 0
    private var parseIndex: Int = 0
    private var lastParseIndex: Int = 0
    private var stallCount: Int = 0

    // MARK: - Lifecycle

    isolated deinit {
        NotificationCenter.default.removeObserver(self, name: .mk_bxs_receiveRecordHTData, object: nil)
        MKBXSCentralManager.shared.notifyRecordTHData(false)
        parseTimer?.cancel()
        parseTimer = nil
        displayTimer?.cancel()
        displayTimer = nil
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        hasHumidity = (MKBXSConnectManager.shared.thSensorType == .th)
        readDeviceRunTimes()
    }

    // MARK: - Interface

    private func readDeviceRunTimes() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        MKBXSInterface.readDeviceRuntime(sucBlock: { [weak self] returnData in
            MKSwiftHudManager.shared.hide()
            guard let self = self else { return }
            // time 是 String，不是 Int
            let timeStr = (returnData["time"] as? String) ?? "0"
            let count = Int(timeStr) ?? 0
            let current = Date().timeIntervalSince1970
            self.runDate = Date(timeIntervalSince1970: current - TimeInterval(count))
            self.loadSubViews()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.receiveRecordHTData(_:)),
                                                   name: .mk_bxs_receiveRecordHTData,
                                                   object: nil)
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    private func readTotalNumbers() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        receiveComplete = false
        totalCount = 0
        parseIndex = 0
        lastParseIndex = 0
        stallCount = 0

        MKBXSInterface.readHTRecordTotalNumbers(sucBlock: { [weak self] returnData in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.maskView.show(with: self.view)
            let count = (returnData["count"] as? String) ?? "0"
            self.maskView.updateTotalNumber(count)
            if Int(count) == 0 {
                self.topView.resetAllStatus()
                self.textView.text = ""
                self.textMsg = ""
                self.maskView.updateCurrentNumber("0")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.dismissMaskView()
                }
                return
            }
            self.startTHDataReceive()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    private func startTHDataReceive() {
        MKBXSCentralManager.shared.notifyRecordTHData(true)
        startParseTimer()
        startDisplayTimer()
    }

    private func deleteRecordDatas() {
        dataList.removeAll()
        temperatureList.removeAll()
        humidityList.removeAll()
        contentList.removeAll()
        receiveComplete = false
        totalCount = 0
        parseIndex = 0
        lastParseIndex = 0
        stallCount = 0
        textView.text = ""
        textMsg = ""
        topView.resetAllStatus()

        UIView.animate(withDuration: 0.3) {
            self.textBackView.frame = CGRect(x: 10, y: self.htTextViewOffsetY, width: MKScreen.width - 30, height: self.textBackViewHeight)
            self.curveContainerView.frame = CGRect(x: MKScreen.width - 10, y: self.htTextViewOffsetY, width: MKScreen.width - 30, height: self.textBackViewHeight)
        }

        MKBXSCentralManager.shared.notifyRecordTHData(false)
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXSInterface.deleteBXPRecordHTDatas(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Empty successfully!")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - Notification

    @objc private func receiveRecordHTData(_ note: Notification) {
        guard let content = note.userInfo?["content"] as? String else { return }
        let total = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 6, length: 4))
        let index = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 10, length: 4))
        totalCount = total
        contentList.append(content)
        if total == index + 1 {
            MKBXSCentralManager.shared.notifyRecordTHData(false)
        }
    }

    // MARK: - Timers

    private func startParseTimer() {
        parseTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer.schedule(deadline: .now() + 0.3, repeating: 0.3)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.parseIndex == self.lastParseIndex {
                    self.stallCount += 1
                    if self.stallCount >= 10 {
                        self.receiveComplete = true
                    }
                } else {
                    self.lastParseIndex = self.parseIndex
                    self.stallCount = 0
                }

                if self.receiveComplete {
                    self.parseTimer?.cancel()
                    self.parseTimer = nil
                    self.topView.resetAllStatus()
                    self.textView.text = self.textMsg
                    self.textView.scrollRangeToVisible(NSRange(location: self.textView.text.count, length: 1))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.dismissMaskView()
                    }
                }
                self.processNotifyDatas()
            }
        }
        parseTimer = timer
        timer.resume()
    }

    private func startDisplayTimer() {
        displayTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.textView.text = self.textMsg
                if self.receiveComplete {
                    self.displayTimer?.cancel()
                    self.displayTimer = nil
                }
            }
        }
        displayTimer = timer
        timer.resume()
    }

    private func processNotifyDatas() {
        guard parseIndex < contentList.count else { return }
        let content = contentList[parseIndex]
        let text = parseTemperatureHumidityData(
            content.bleSubstring(from: 16, length: content.count - 16)
        )
        textMsg = text + textMsg
        maskView.updateCurrentNumber("\(dataList.count)")
        parseIndex += 1
        if parseIndex == totalCount {
            receiveComplete = true
        }
    }

    private func dismissMaskView() {
        maskView.dismiss()
    }

    // MARK: - Parse

    private func parseTemperatureHumidityData(_ content: String) -> String {
        let total = content.count / 16
        var text = ""
        for i in 0..<total {
            let subContent = content.bleSubstring(from: i * 16, length: 16)
            let time = strtoul(subContent.bleSubstring(from: 0, length: 8), nil, 16)
            let timestamp: String
            if time < 1577808000 {
                timestamp = dateFormatter.string(from: runDate.addingTimeInterval(TimeInterval(time)))
            } else {
                timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(time)))
            }

            let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnToInt(subContent.bleSubstring(from: 8, length: 4))
            let temperature = String(format: "%.1f", Double(tempTemp) * 0.1)
            temperatureList.append(temperature)

            if hasHumidity {
                let tempHui = strtoul(subContent.bleSubstring(from: 12, length: 4), nil, 16)
                let humidity = String(format: "%.1f", Double(tempHui) * 0.1)
                humidityList.append(humidity)
                text += "\n\(timestamp)\t\t\(temperature)℃\t\t\(humidity)%RH"
                dataList.append(["temperature": temperature, "humidity": humidity, "date": timestamp])
            } else {
                text += "\n\(timestamp)\t\t\(temperature)℃"
                dataList.append(["temperature": temperature, "date": timestamp])
            }
        }
        return text
    }

    private func drawCurveView() {
        MKSwiftHudManager.shared.showHUD(with: "Loading...", in: view, isPenetration: false)
        if hasHumidity {
            if let curveView = curveContainerView.viewWithTag(100) as? MKBXSExportHTDataCurveView {
                let tempMax = temperatureList.compactMap { Float($0) }.max() ?? 0
                let tempMin = temperatureList.compactMap { Float($0) }.min() ?? 0
                let humMax = humidityList.compactMap { Float($0) }.max() ?? 0
                let humMin = humidityList.compactMap { Float($0) }.min() ?? 0
                curveView.updateTemperatureDatas(temperatureList,
                                                 temperatureMax: CGFloat(tempMax),
                                                 temperatureMin: CGFloat(tempMin),
                                                 humidityList: humidityList,
                                                 humidityMax: CGFloat(humMax),
                                                 humidityMin: CGFloat(humMin)) {
                    MKSwiftHudManager.shared.hide()
                }
            }
        } else {
            if let curveView = curveContainerView.viewWithTag(101) as? MKBXSExportTempDataCurveView {
                let tempMax = temperatureList.compactMap { Float($0) }.max() ?? 0
                let tempMin = temperatureList.compactMap { Float($0) }.min() ?? 0
                curveView.updateTemperatureDatas(temperatureList,
                                                 temperatureMax: CGFloat(tempMax),
                                                 temperatureMin: CGFloat(tempMin)) {
                    MKSwiftHudManager.shared.hide()
                }
            }
        }
    }

    private func sharedExcel() {
        guard MFMailComposeViewController.canSendMail() else {
            if let url = URL(string: "MESSAGE://") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            return
        }
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let fileName = hasHumidity ? "Temperature&HumidityDatas.xlsx" : "Temperature.xlsx"
        let path = (documentPath as NSString).appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: path) else {
            view.showCentralToast("File not exist")
            return
        }
        guard let data = FileManager.default.contents(atPath: path) else {
            view.showCentralToast("Load file error")
            return
        }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let bodyMsg = "APP Version: \(version) + + OS: \(UIDevice.current.systemVersion)"

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients(["Development@mokotechnology.com"])
        mailComposer.setSubject("Feedback of mail")
        mailComposer.addAttachmentData(data, mimeType: "application/xlsx", fileName: fileName)
        mailComposer.setMessageBody(bodyMsg, isHTML: false)
        present(mailComposer, animated: true)
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = hasHumidity ? "Export T&H Data" : "Export Temperature Data"
        setNavTitleFont(MKFont.font(15))
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        view.addSubview(backView)
        backView.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(view).offset(MKLayout.topBarHeight + 10)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 10))
        }

        backView.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(5)
            make.height.equalTo(50)
        }

        backView.addSubview(filterView)
        filterView.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(topView.snp.bottom).offset(20)
            make.height.equalTo(80)
        }

        backView.addSubview(textBackView)
        textBackView.addSubview(textView)
        backView.addSubview(curveContainerView)

        textBackView.frame = CGRect(x: 10, y: htTextViewOffsetY, width: MKScreen.width - 30, height: textBackViewHeight)
        curveContainerView.frame = CGRect(x: MKScreen.width - 10, y: htTextViewOffsetY, width: MKScreen.width - 30, height: textBackViewHeight)
        textView.frame = CGRect(x: 10, y: 15 + MKFont.font(13).lineHeight, width: MKScreen.width - 50, height: textBackViewHeight - 55 - MKFont.font(13).lineHeight)

        let timeLabel = loadTextLabel("Time")
        let tempLabel = loadTextLabel("Temperature")
        textBackView.addSubview(timeLabel)
        textBackView.addSubview(tempLabel)

        if hasHumidity {
            let humidityLabel = loadTextLabel("Humidity")
            textBackView.addSubview(humidityLabel)
            timeLabel.frame = CGRect(x: textViewSpace, y: 5, width: timeTextViewWidth, height: MKFont.font(13).lineHeight)
            tempLabel.frame = CGRect(x: 2 * textViewSpace + timeTextViewWidth, y: 5, width: htTextViewWidth, height: MKFont.font(13).lineHeight)
            humidityLabel.frame = CGRect(x: 3 * textViewSpace + timeTextViewWidth + htTextViewWidth, y: 5, width: htTextViewWidth, height: MKFont.font(13).lineHeight)
        } else {
            timeLabel.frame = CGRect(x: textViewSpace, y: 5, width: timeTextViewWidth, height: MKFont.font(13).lineHeight)
            tempLabel.frame = CGRect(x: 2 * textViewSpace + timeTextViewWidth, y: 5, width: htTextViewWidth, height: MKFont.font(13).lineHeight)
        }

        if hasHumidity {
            let curveView = MKBXSExportHTDataCurveView(frame: curveContainerView.bounds)
            curveView.tag = 100
            curveContainerView.addSubview(curveView)
        } else {
            let curveView = MKBXSExportTempDataCurveView(frame: curveContainerView.bounds)
            curveView.tag = 101
            curveContainerView.addSubview(curveView)
        }
    }

    private func loadTextLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(13)
        label.textAlignment = .center
        label.text = text
        return label
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension MKBXSExportDataController: MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController,
                                      didFinishWith result: MFMailComposeResult,
                                      error: Error?) {
        if result == .sent {
            view.showCentralToast("send success")
        }
        dismiss(animated: true)
    }
}

// MARK: - MKBXSExportDataHeaderViewDelegate

extension MKBXSExportDataController: MKBXSExportDataHeaderViewDelegate {
    public func bxs_syncButtonPressed(_ selected: Bool) {
        if selected {
            textView.text = ""
            textMsg = ""
            contentList.removeAll()
            dataList.removeAll()
            temperatureList.removeAll()
            humidityList.removeAll()
            readTotalNumbers()
            return
        }
        MKBXSCentralManager.shared.notifyRecordTHData(false)
        receiveComplete = false
        totalCount = 0
        parseIndex = 0
        lastParseIndex = 0
        stallCount = 0
        parseTimer?.cancel()
        parseTimer = nil
        displayTimer?.cancel()
        displayTimer = nil
    }

    public func bxs_switchButtonPressed(_ selected: Bool) {
        if selected {
            UIView.animate(withDuration: 0.3) {
                self.textBackView.frame = CGRect(x: -(MKScreen.width - 10), y: self.htTextViewOffsetY, width: MKScreen.width - 30, height: self.textBackViewHeight)
                self.curveContainerView.frame = CGRect(x: 10, y: self.htTextViewOffsetY, width: MKScreen.width - 30, height: self.textBackViewHeight)
            } completion: { _ in
                self.drawCurveView()
            }
            return
        }
        UIView.animate(withDuration: 0.3) {
            self.textBackView.frame = CGRect(x: 10, y: self.htTextViewOffsetY, width: MKScreen.width - 30, height: self.textBackViewHeight)
            self.curveContainerView.frame = CGRect(x: MKScreen.width - 10, y: self.htTextViewOffsetY, width: MKScreen.width - 30, height: self.textBackViewHeight)
        }
    }

    public func bxs_deleteButtonPressed() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") {})
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.deleteRecordDatas()
        })
        let msg = hasHumidity ? "Are you sure to erase all the saved T&H datas?" : "Are you sure to erase all the saved temperature datas?"
        alert.showAlert(title: "Warning!", message: msg)
    }

    public func bxs_exportButtonPressed() {
        MKSwiftHudManager.shared.showHUD(with: "Waiting...", in: view, isPenetration: false)
        MKBXSExcelManager.exportExcelWithTHDataList(dataList,
                                                    hasHumidity: hasHumidity,
                                                    sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.sharedExcel()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }
}

// MARK: - MKBXSFilterHistoryDataViewDelegate

extension MKBXSExportDataController: MKBXSFilterHistoryDataViewDelegate {
    public func bxs_dateSelectedView_startPressed(_ startDate: String, endDate: String) {
        MKSwiftHudManager.shared.showHUD(with: "Loading...", in: view, isPenetration: false)
        guard let start = dateFormatter.date(from: startDate),
              let end = dateFormatter.date(from: endDate) else {
            MKSwiftHudManager.shared.hide()
            return
        }
        let filtered = dataList.filter { dic in
            guard let dateStr = dic["date"] as? String,
                  let date = dateFormatter.date(from: dateStr) else { return false }
            return date >= start && date <= end
        }
        MKSwiftHudManager.shared.hide()

        guard !filtered.isEmpty else {
            view.showCentralToast("No matching data!")
            return
        }

        let vc = MKBXSFilterHistoryDataController()
        vc.dataList = filtered
        navigationController?.pushViewController(vc, animated: true)
    }
}
