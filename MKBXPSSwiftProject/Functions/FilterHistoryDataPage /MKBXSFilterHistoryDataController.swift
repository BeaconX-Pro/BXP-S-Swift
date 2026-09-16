//
//  MKBXSFilterHistoryDataController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import MessageUI

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSFilterHistoryDataController: MKSwiftBaseViewController {

    public var dataList: [[String: Any]] = []

    private var hasHumidity: Bool = false

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var topView: MKBXSFilterHistoryHeaderView = {
        let header = MKBXSFilterHistoryHeaderView()
        header.delegate = self
        return header
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

    private lazy var temperatureList: [String] = []
    private lazy var humidityList: [String] = []

    // MARK: - Constants

    private let timeTextViewWidth: CGFloat = 130
    private let htTextViewWidth: CGFloat = 80
    private let htTextViewOffsetY: CGFloat = 60

    private var textBackViewHeight: CGFloat {
        MKScreen.height - MKLayout.topBarHeight - 70
    }

    private var textViewSpace: CGFloat {
        (MKScreen.width - 30 - timeTextViewWidth - 2 * htTextViewWidth) / 4
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        hasHumidity = (MKBXSConnectManager.shared.thSensorType == .th)
        loadSubViews()
        processDatas()
    }

    // MARK: - Load SubViews

    private func loadSubViews() {
        defaultTitle = hasHumidity ? "Export T&H Data" : "Export Temperature Data"
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

        backView.addSubview(textBackView)
        textBackView.addSubview(textView)
        backView.addSubview(curveContainerView)

        textBackView.frame = CGRect(x: 10, y: htTextViewOffsetY, width: MKScreen.width - 30, height: textBackViewHeight)
        curveContainerView.frame = CGRect(x: MKScreen.width - 10, y: htTextViewOffsetY, width: MKScreen.width - 30, height: textBackViewHeight)

        // Header labels
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

        textView.frame = CGRect(x: 10, y: 15 + MKFont.font(13).lineHeight, width: MKScreen.width - 50, height: textBackViewHeight - 55 - MKFont.font(13).lineHeight)

        // Curve view
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

    // MARK: - Process

    private func processDatas() {
        guard !dataList.isEmpty else { return }
        MKSwiftHudManager.shared.showHUD(with: "Loading...", in: view, isPenetration: false)
        var text = ""
        for dic in dataList {
            let temperature = (dic["temperature"] as? String) ?? ""
            temperatureList.append(temperature)
            let tempDisplay = "\(temperature)℃"

            if hasHumidity {
                let humidity = (dic["humidity"] as? String) ?? ""
                humidityList.append(humidity)
                let humDisplay = "\(humidity)%RH"
                let line = "\n\(dic["date"] as? String ?? "")\t\t\(tempDisplay)\t\t\(humDisplay)"
                text += line
            } else {
                let line = "\n\(dic["date"] as? String ?? "")\t\t\(tempDisplay)"
                text += line
            }
        }
        MKSwiftHudManager.shared.hide()

        textView.text = (textView.text ?? "") + text
        textView.scrollRangeToVisible(NSRange(location: textView.text.count, length: 1))
        topView.updateSumRecord("\(dataList.count)")
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

    private func loadTextLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(13)
        label.textAlignment = .center
        label.text = text
        return label
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
}

// MARK: - MFMailComposeViewControllerDelegate

extension MKBXSFilterHistoryDataController: MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController,
                                      didFinishWith result: MFMailComposeResult,
                                      error: Error?) {
        if result == .sent {
            view.showCentralToast("send success")
        }
        dismiss(animated: true)
    }
}

// MARK: - MKBXSFilterHistoryHeaderViewDelegate

extension MKBXSFilterHistoryDataController: MKBXSFilterHistoryHeaderViewDelegate {
    public func bxs_filterHistoryHeaderView_switchButtonPressed(_ selected: Bool) {
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

    public func bxs_filterHistoryHeaderView_exportButtonPressed() {
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
