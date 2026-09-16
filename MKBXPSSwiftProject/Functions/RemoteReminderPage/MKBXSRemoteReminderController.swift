//
//  MKBXSRemoteReminderController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSRemoteReminderController: MKSwiftBaseViewController {

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        return tv
    }()

    private lazy var section0List: [MKBXSRemoteReminderCellModel] = []
    private lazy var section1List: [MKSwiftTextFieldCellModel] = []
    private lazy var section2List: [MKBXSRemoteReminderCellModel] = []
    private lazy var section3List: [MKSwiftTextFieldCellModel] = []
    private lazy var section4List: [MKSwiftTextButtonCellModel] = []
    private lazy var headerList: [MKSwiftTableSectionLineHeaderModel] = []

    private let dataModel = MKBXSRemoteReminderModel()

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        readDatasFromDevice()
    }

    // MARK: - Data

    private func readDatasFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.readData(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.loadSectionDatas()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - LED

    private func reminderLED() {
        guard !dataModel.ledBlinkingTime.isEmpty,
              let time = Int(dataModel.ledBlinkingTime), time >= 1, time <= 600 else {
            view.showCentralToast("Blink Time Error")
            return
        }
        guard !dataModel.ledBlinkingInterval.isEmpty,
              let interval = Int(dataModel.ledBlinkingInterval), interval >= 1, interval <= 100 else {
            view.showCentralToast("Blink Interval Error")
            return
        }
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        let color = ledColorValue()
        MKBXSInterface.configRemoteReminderLEDNotiParams(blinkingTime: time,
                                                         blinkingInterval: interval,
                                                         color: color,
                                                         sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Success")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    /// LED color 值
    private func ledColorValue() -> String {
        let type = MKBXSConnectManager.shared.deviceType
        if type == .atmosic { return "0D" }   // BXP-S-A
        if type == .nordic  { return "28" }   // BXP-S-E (DL001)
        return "03"                            // 其他
    }

    // MARK: - Buzzer

    /// 点击 Buzzer 按钮：弹窗警告
    private func reminderBuzzer() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") {})
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.buzzerCmdToDevice()
        })
        let msg = "*Please make sure to confirm whether your device is equipped with a buzzer. If it does not have a buzzer, do NOT execute this command, as it may cause Flash memory issues with the product !!!"
        alert.showAlert(title: "Warning!", message: msg)
    }

    /// 弹窗确认后：校验参数并发命令
    private func buzzerCmdToDevice() {
        guard !dataModel.buzzerRingingTime.isEmpty,
              let time = Int(dataModel.buzzerRingingTime), time >= 1, time <= 600 else {
            view.showCentralToast("Ringing Time Error")
            return
        }
        guard !dataModel.buzzerRingingInterval.isEmpty,
              let interval = Int(dataModel.buzzerRingingInterval), interval >= 1, interval <= 100 else {
            view.showCentralToast("Ringing Interval Error")
            return
        }
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        dataModel.configBuzzerData(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Success")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - Section Data

    private func loadSectionDatas() {
        // Section 0: LED
        let ledModel = MKBXSRemoteReminderCellModel()
        ledModel.msg = "LED notification"
        ledModel.index = 0
        section0List = [ledModel]

        // Section 1: LED params
        let ledTime = MKSwiftTextFieldCellModel()
        ledTime.index = 0
        ledTime.msg = "Blinking time"
        ledTime.textPlaceholder = "1~600"
        ledTime.textFieldValue = dataModel.ledBlinkingTime
        ledTime.textFieldType = .realNumberOnly
        ledTime.unit = "s"
        ledTime.maxLength = 3

        let ledInterval = MKSwiftTextFieldCellModel()
        ledInterval.index = 1
        ledInterval.msg = "Blinking interval"
        ledInterval.textPlaceholder = "1~100"
        ledInterval.textFieldValue = dataModel.ledBlinkingInterval
        ledInterval.textFieldType = .realNumberOnly
        ledInterval.unit = "x 100ms"
        ledInterval.maxLength = 3
        section1List = [ledTime, ledInterval]

        // Section 2: Buzzer（始终显示）
        let buzzerModel = MKBXSRemoteReminderCellModel()
        buzzerModel.msg = "Buzzer notification"
        buzzerModel.index = 1
        section2List = [buzzerModel]

        // Section 3: Buzzer params
        let ringTime = MKSwiftTextFieldCellModel()
        ringTime.index = 2
        ringTime.msg = "Ringing time"
        ringTime.textPlaceholder = "1~600"
        ringTime.textFieldValue = dataModel.buzzerRingingTime
        ringTime.textFieldType = .realNumberOnly
        ringTime.unit = "s"
        ringTime.maxLength = 3

        let ringInterval = MKSwiftTextFieldCellModel()
        ringInterval.index = 3
        ringInterval.msg = "Ringing interval"
        ringInterval.textPlaceholder = "1~100"
        ringInterval.textFieldValue = dataModel.buzzerRingingInterval
        ringInterval.textFieldType = .realNumberOnly
        ringInterval.unit = "x 100ms"
        ringInterval.maxLength = 3
        section3List = [ringTime, ringInterval]

        // Section 4: Ringing frequency
        let freq = MKSwiftTextButtonCellModel()
        freq.index = 0
        freq.msg = "Ringing frequency"
        freq.dataList = ["4000 Hz", "4500 Hz"]
        freq.dataListIndex = dataModel.ringingFre
        section4List = [freq]

        // Headers：始终 5 个
        headerList = (0..<5).map { _ in MKSwiftTableSectionLineHeaderModel() }

        tableView.reloadData()
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "Remote reminder"
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }
}

// MARK: - TableView

extension MKBXSRemoteReminderController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return headerList.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0List.count
        case 1: return section1List.count
        case 2: return section2List.count
        case 3: return section3List.count
        case 4: return section4List.count
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        (section == 0 || section == 2) ? 10 : 0
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        if section < headerList.count {
            header.headerModel = headerList[section]
        }
        return header
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = MKBXSRemoteReminderCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[indexPath.row]
            cell.delegate = self
            return cell
        case 1:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            cell.delegate = self
            return cell
        case 2:
            let cell = MKBXSRemoteReminderCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[indexPath.row]
            cell.delegate = self
            return cell
        case 3:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section3List[indexPath.row]
            cell.delegate = self
            return cell
        default:
            let cell = MKSwiftTextButtonCell.initCellWithTableView(tableView)
            cell.dataModel = section4List[indexPath.row]
            cell.delegate = self
            return cell
        }
    }
}

// MARK: - Delegates

extension MKBXSRemoteReminderController: MKSwiftTextFieldCellDelegate {
    public func mkDeviceTextCellValueChanged(_ index: Int, textValue: String) {
        switch index {
        case 0: dataModel.ledBlinkingTime = textValue; section1List[0].textFieldValue = textValue
        case 1: dataModel.ledBlinkingInterval = textValue; section1List[1].textFieldValue = textValue
        case 2: dataModel.buzzerRingingTime = textValue; section3List[0].textFieldValue = textValue
        case 3: dataModel.buzzerRingingInterval = textValue; section3List[1].textFieldValue = textValue
        default: break
        }
    }
}

extension MKBXSRemoteReminderController: MKSwiftTextButtonCellDelegate {
    public func MKSwiftTextButtonCellSelected(index: Int, dataListIndex: Int, value: String) {
        if index == 0 {
            dataModel.ringingFre = dataListIndex
            section4List[0].dataListIndex = dataListIndex
        }
    }
}

extension MKBXSRemoteReminderController: MKBXSRemoteReminderCellDelegate {
    public func bxs_remindButtonPressed(_ index: Int) {
        if index == 0 { reminderLED() }
        else if index == 1 { reminderBuzzer() }
    }
}
