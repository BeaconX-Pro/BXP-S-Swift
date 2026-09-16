//
//  MKBXSSettingController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSSettingController: MKSwiftBaseViewController {

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.separatorStyle = .none
        if #available(iOS 15.0, *) {
            tv.sectionHeaderTopPadding = 0
        }
        return tv
    }()

    // MARK: - Data

    private lazy var section0List: [MKSwiftNormalTextCellModel] = []
    private lazy var section1List: [MKSwiftNormalTextCellModel] = []
    private lazy var section2List: [MKSwiftNormalTextCellModel] = []
    private lazy var section3List: [MKSwiftNormalTextCellModel] = []
    private lazy var section4List: [MKSwiftTextButtonCellModel] = []

    private var dfuModule: Bool = false
    private var passwordAsciiStr: String = ""
    private var confirmAsciiStr: String = ""

    private let dataModel = MKBXSSettingModel()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if dfuModule { return }
        readDatas()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceStartDFUProcess),
                                               name: Notification.Name("mk_bxs_startDfuProcessNotification"),
                                               object: nil)
    }

    public override func leftButtonMethod() {
        NotificationCenter.default.post(name: Notification.Name("mk_bxs_popToRootViewControllerNotification"), object: nil)
    }

    // MARK: - Read

    private func readDatas() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.readData(sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.loadSection0Datas()
            self.loadSection1Datas()
            self.loadSection2Datas()
            self.loadSection3Datas()
            self.loadSection4Datas()
            self.tableView.reloadData()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    @objc private func deviceStartDFUProcess() {
        dfuModule = true
    }

    // MARK: - Section 0

    private func loadSection0Datas() {
        section0List.removeAll()
        if dataModel.supportThreeAcc || dataModel.supportTH || !dataModel.hallStatus {
            let model = MKSwiftNormalTextCellModel()
            model.showRightIcon = true
            model.leftMsg = "Sensor configurations"
            model.methodName = "pushSensorConfigPage"
            section0List.append(model)
        }
        let quick = MKSwiftNormalTextCellModel()
        quick.showRightIcon = true
        quick.leftMsg = "Quick switch"
        quick.methodName = "pushQuickSwitchPage"
        section0List.append(quick)
    }

    @objc func pushSensorConfigPage() {
        let vc = MKBXSSensorConfigController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func pushQuickSwitchPage() {
        let vc = MKBXSQuickSwitchController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func powerOff() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") {})
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.commandPowerOff()
        })
        alert.showAlert(title: "Warning!", message: "Are you sure to turn off the Beacon?Please make sure the Beacon has a button to turn on!")
    }

    private func commandPowerOff() {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXSInterface.configPowerOff(sucBlock: {
            MKSwiftHudManager.shared.hide()
        }, failedBlock: { error in
            MKSwiftHudManager.shared.hide()
            self.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - Section 1

    private func loadSection1Datas() {
        section1List.removeAll()
        let manager = MKBXSConnectManager.shared
        if manager.needPassword {
            let reset = MKSwiftNormalTextCellModel()
            reset.leftMsg = "Reset Beacon"
            reset.showRightIcon = true
            reset.methodName = "factoryReset"
            section1List.append(reset)
        }
        if !manager.password.isEmpty && manager.needPassword {
            let password = MKSwiftNormalTextCellModel()
            password.leftMsg = "Modify password"
            password.showRightIcon = true
            password.methodName = "configPassword"
            section1List.append(password)
        }
    }

    @objc func configPassword() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") {})
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.setPasswordToDevice()
        })
        let passwordField = MKSwiftAlertViewTextField(textValue: "",
                                                      placeholder: "Enter new password",
                                                      textFieldType: .normal,
                                                      maxLength: 16) { [weak self] text in
            self?.passwordAsciiStr = text
        }
        let confirmField = MKSwiftAlertViewTextField(textValue: "",
                                                     placeholder: "Enter new password again",
                                                     textFieldType: .normal,
                                                     maxLength: 16) { [weak self] text in
            self?.confirmAsciiStr = text
        }
        alert.addTextField(passwordField)
        alert.addTextField(confirmField)
        alert.showAlert(title: "Modify password", message: "Note:The password should not be exceed 16 characters in length.")
    }

    private func setPasswordToDevice() {
        let password = passwordAsciiStr
        let confirm = confirmAsciiStr
        guard !password.isEmpty, !confirm.isEmpty, password.count <= 16, confirm.count <= 16 else {
            view.showCentralToast("Length error.")
            return
        }
        guard password == confirm else {
            view.showCentralToast("Password not match! Please try again.")
            return
        }
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXSInterface.configConnectPassword(password, sucBlock: {
            MKSwiftHudManager.shared.hide()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    @objc func factoryReset() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") {})
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.sendResetCommandToDevice()
        })
        alert.showAlert(title: "Warning!", message: "Are you sure to reset the Beacon?")
    }

    private func sendResetCommandToDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXSInterface.factoryReset(sucBlock: {
            MKSwiftHudManager.shared.hide()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - Section 2

    private func loadSection2Datas() {
        section2List.removeAll()
        let dfu = MKSwiftNormalTextCellModel()
        dfu.leftMsg = "DFU"
        dfu.showRightIcon = true
        dfu.methodName = "pushDFUPage"
        section2List.append(dfu)
    }

    @objc func pushDFUPage() {
        let vc = MKBXSUpdateController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Section 3

    private func loadSection3Datas() {
        section3List.removeAll()
        let remote = MKSwiftNormalTextCellModel()
        remote.leftMsg = "Remote reminder"
        remote.showRightIcon = true
        remote.methodName = "pushRemoteReminder"
        section3List.append(remote)

        let resetBattery = MKSwiftNormalTextCellModel()
        resetBattery.leftMsg = "Reset Battery"
        resetBattery.showRightIcon = true
        resetBattery.methodName = "resetBattery"
        section3List.append(resetBattery)
    }

    @objc func pushRemoteReminder() {
        let vc = MKBXSRemoteReminderController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func resetBattery() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") {})
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.sendResetBatteryCommandToDevice()
        })
        alert.showAlert(title: "Warning!", message: "*Please ensure you have replaced the new battery for this beacon before reset the Battery")
    }

    private func sendResetBatteryCommandToDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXSInterface.batteryReset(sucBlock: {
            MKSwiftHudManager.shared.hide()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - Section 4

    private func loadSection4Datas() {
        section4List.removeAll()

        let battery = MKSwiftTextButtonCellModel()
        battery.index = 0
        battery.msg = "Battery ADV mode"
        battery.dataList = ["Voltage", "Percentage"]
        battery.dataListIndex = dataModel.batteryAdvMode
        section4List.append(battery)

        let channel = MKSwiftTextButtonCellModel()
        channel.index = 1
        channel.msg = "ADV Channel"
        channel.dataList = ["CH37&38&39", "CH37", "CH38", "CH39"]
        channel.dataListIndex = dataModel.advChannel
        section4List.append(channel)
    }

    private func configBatteryAdvMode(_ mode: Int) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        // mode == 0 → Voltage；mode == 1 → Percentage
        let tempMode: MKBXSBatteryADVMode = (mode == 0) ? .voltage : .percentage
        MKBXSInterface.configBatteryADVMode(tempMode, sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.section4List[0].dataListIndex = mode
            self.dataModel.batteryAdvMode = mode
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
            self?.tableView.reloadRows(at: [IndexPath(row: 0, section: 4)], with: .none)
        })
    }

    private func configAdvChannel(_ channel: Int) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        var channelValue: MKBXSADVChannel = .all
        if channel == 1 { channelValue = .ch37 }
        else if channel == 2 { channelValue = .ch38 }
        else if channel == 3 { channelValue = .ch39 }

        MKBXSInterface.configADVChannel(channel: channelValue, sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.section4List[1].dataListIndex = channel
            self.dataModel.advChannel = channel
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
            self?.tableView.reloadRows(at: [IndexPath(row: 1, section: 4)], with: .none)
        })
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "SETTING"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 49))
        }
    }
}

// MARK: - TableView

extension MKBXSSettingController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int { 5 }
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
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 44 }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 4 {
            let cell = MKSwiftTextButtonCell.initCellWithTableView(tableView)
            cell.dataModel = section4List[indexPath.row]
            cell.delegate = self
            return cell
        }
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        let list: [MKSwiftNormalTextCellModel]
        switch indexPath.section {
        case 0: list = section0List
        case 1: list = section1List
        case 2: list = section2List
        default: list = section3List
        }
        cell.dataModel = list[indexPath.row]
        return cell
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 4 { return }
        let list: [MKSwiftNormalTextCellModel]
        switch indexPath.section {
        case 0: list = section0List
        case 1: list = section1List
        case 2: list = section2List
        default: list = section3List
        }
        let cellModel = list[indexPath.row]
        let methodName = cellModel.methodName
        guard !methodName.isEmpty else { return }
        let selector = NSSelectorFromString(methodName)
        if responds(to: selector) {
            perform(selector, with: nil)
        }
    }
}

// MARK: - MKSwiftTextButtonCellDelegate

extension MKBXSSettingController: MKSwiftTextButtonCellDelegate {
    public func MKSwiftTextButtonCellSelected(index: Int, dataListIndex: Int, value: String) {
        if index == 0 {
            configBatteryAdvMode(dataListIndex)
        } else if index == 1 {
            configAdvChannel(dataListIndex)
        }
    }
}
