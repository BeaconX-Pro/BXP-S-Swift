//
//  MKBXSExportMarkDataController.swift
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
public final class MKBXSExportMarkDataController: MKSwiftBaseViewController {

    // MARK: - Constants

    private let timeViewWidth: CGFloat = 130
    private let tempTextViewWidth: CGFloat = 80
    private let tTextViewOffsetY: CGFloat = 70

    private var textBackViewHeight: CGFloat {
        MKScreen.height - MKLayout.topBarHeight - 110
    }

    private var textViewSpace: CGFloat {
        (MKScreen.width - 30 - timeViewWidth - 2 * tempTextViewWidth) / 4
    }

    // MARK: - Properties

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var topView: MKBXSExportMarkDataHeaderView = {
        let header = MKBXSExportMarkDataHeaderView()
        header.delegate = self
        return header
    }()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .white
        tv.font = MKFont.font(13)
        tv.layoutManager.allowsNonContiguousLayout = false
        tv.isEditable = false
        tv.textColor = MKColor.defaultText
        tv.text = ""
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

    private lazy var dataList: [[String: Any]] = []
    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return f
    }()
    private var runDate: Date = Date()
    private var hasHumidity: Bool = false

    // MARK: - Lifecycle

    deinit {
        // 无需清理定时器
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        readDeviceRunTimes()
    }

    // MARK: - Interface

    private func readDeviceRunTimes() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        MKBXSInterface.readDeviceRuntime(sucBlock: { [weak self] returnData in
            MKSwiftHudManager.shared.hide()
            guard let self = self else { return }
            // ✅ 修复：time 是 String，不是 Int
            let timeStr = (returnData["time"] as? String) ?? "0"
            let count = Int(timeStr) ?? 0
            let current = Date().timeIntervalSince1970
            self.runDate = Date(timeIntervalSince1970: current - TimeInterval(count))
            self.loadSubViews()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    private func clearMarkData() {
        MKSwiftHudManager.shared.showHUD(with: "Clearing...", in: view, isPenetration: false)
        MKBXSInterface.clearMarkData(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.dataList.removeAll()
            self?.textView.text = ""
            self?.view.showCentralToast("Empty successfully!")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    private func parseTemperatureHumidityData(_ content: String) {
        dataList.removeAll()
        var text = ""
        let total = content.count / 16
        for i in 0..<total {
            let subContent = content.bleSubstring(from: i * 16, length: 16)
            let time = strtoul(subContent.bleSubstring(from: 0, length: 8), nil, 16)
            let timestamp: String
            if time < 1577808000 {
                timestamp = dateFormatter.string(from: runDate.addingTimeInterval(TimeInterval(time)))
            } else {
                timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(time)))
            }

            // 温度：跟 OC 一致，带 ℃ 后缀（N/A 除外）
            let tempHex = subContent.bleSubstring(from: 8, length: 4)
            let temperature: String
            if tempHex.uppercased() == "7FFF" {
                temperature = "N/A"
            } else {
                let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnToInt(tempHex)
                temperature = String(format: "%.1f℃", Double(tempTemp) * 0.1)
            }

            if hasHumidity {
                // 湿度：跟 OC 一致，带 %RH 后缀（N/A 除外）
                let humiHex = subContent.bleSubstring(from: 12, length: 4)
                let humidity: String
                if humiHex.uppercased() == "7FFF" {
                    humidity = "N/A"
                } else {
                    let tempHui = strtoul(humiHex, nil, 16)
                    humidity = String(format: "%.1f%%RH", Double(tempHui) * 0.1)
                }
                text += "\n\(timestamp)\t\t\(temperature)\t\t\(humidity)"
                dataList.append(["temperature": temperature, "humidity": humidity, "date": timestamp])
            } else {
                text += "\n\(timestamp)\t\t\(temperature)"
                dataList.append(["temperature": temperature, "date": timestamp])
            }
        }

        if dataList.isEmpty {
            textView.text = ""
        } else {
            textView.text = text
            // 跟 OC 保持一致：NSMakeRange(length, 1)，UIKit 会 clamp
            textView.scrollRangeToVisible(NSRange(location: textView.text.count, length: 1))
        }
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "Export Mark Data"
        setNavTitleFont(MKFont.font(15))
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        // 跟 OC 一致：在 loadSubViews 里赋值
        hasHumidity = (MKBXSConnectManager.shared.thSensorType == .th)

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

        textBackView.frame = CGRect(x: 10, y: tTextViewOffsetY, width: MKScreen.width - 30, height: textBackViewHeight)
        textView.frame = CGRect(x: 10, y: 15 + MKFont.font(13).lineHeight, width: MKScreen.width - 50, height: textBackViewHeight - 55 - MKFont.font(13).lineHeight)

        let timeLabel = loadTextLabel("Time")
        let tempLabel = loadTextLabel("Temperature")
        textBackView.addSubview(timeLabel)
        textBackView.addSubview(tempLabel)

        if hasHumidity {
            let humidityLabel = loadTextLabel("Humidity")
            textBackView.addSubview(humidityLabel)
            timeLabel.frame = CGRect(x: textViewSpace, y: 5, width: timeViewWidth, height: MKFont.font(13).lineHeight)
            tempLabel.frame = CGRect(x: 2 * textViewSpace + timeViewWidth, y: 5, width: tempTextViewWidth, height: MKFont.font(13).lineHeight)
            humidityLabel.frame = CGRect(x: 3 * textViewSpace + timeViewWidth + tempTextViewWidth, y: 5, width: tempTextViewWidth, height: MKFont.font(13).lineHeight)
        } else {
            timeLabel.frame = CGRect(x: textViewSpace, y: 5, width: timeViewWidth, height: MKFont.font(13).lineHeight)
            tempLabel.frame = CGRect(x: 2 * textViewSpace + timeViewWidth, y: 5, width: tempTextViewWidth, height: MKFont.font(13).lineHeight)
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

extension MKBXSExportMarkDataController: MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController,
                                      didFinishWith result: MFMailComposeResult,
                                      error: Error?) {
        if result == .sent {
            view.showCentralToast("send success")
        }
        dismiss(animated: true)
    }
}

// MARK: - MKBXSExportMarkDataHeaderViewDelegate

extension MKBXSExportMarkDataController: MKBXSExportMarkDataHeaderViewDelegate {
    public func bxs_markSyncButtonPressed() {
        // 读取 Mark 数据
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        MKBXSInterface.readDeviceMarkData(sucBlock: { [weak self] returnData in
            MKSwiftHudManager.shared.hide()
            guard let self = self else { return }
            // ⚠️ 注意：这里取 content 的 key 取决于 Swift 版 MKBXSInterface 的实现
            // 如果 Swift 接口跟 OC 一样返回 ["result": ["content": ...]]，要改成：
            //   let content = ((returnData["result"] as? [String: Any])?["content"] as? String) ?? ""
            let content = (returnData["content"] as? String) ?? ""
            self.parseTemperatureHumidityData(content)
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    public func bxs_markDeleteButtonPressed() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") {})
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.clearMarkData()
        })
        alert.showAlert(title: "Warning!", message: "Are you sure to erase all the saved mark datas?")
    }

    public func bxs_markExportButtonPressed() {
        // TODO: 导出 Mark 数据
        view.showCentralToast("Export Mark Data")
    }
}
