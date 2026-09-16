//
//  MKBXSTriggerStepThreeController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSTriggerStepThreeController: MKSwiftBaseViewController {

    private lazy var section0List: [MKSwiftTextSwitchCellModel] = []
    private lazy var section1List: [MKSwiftNormalTextCellModel] = []
    private lazy var section2List: [Any] = []
    private lazy var section3List: [MKBXSSlotParamCellModel] = []
    private lazy var headerList: [MKSwiftTableSectionLineHeaderModel] = []

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        tv.delegate = self
        tv.dataSource = self
        tv.tableHeaderView = tableHeaderView()
        tv.tableFooterView = tableFooterView()
        tv.separatorStyle = .none
        if #available(iOS 15.0, *) {
            tv.sectionHeaderTopPadding = 0
        }
        return tv
    }()

    private lazy var doneButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Done",
                                                    target: self,
                                                    action: #selector(doneButtonPressed))
    }()

    // MARK: - Lifecycle

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        loadSectionDatas()
    }

    // MARK: - Events

    @objc private func doneButtonPressed() {
        let manager = MKBXSTriggerParamManager.shared
        let stepOne = manager.stepOneModel
        let stepThree = manager.stepThreeModel

        if stepOne.trigger && stepOne.fetchTriggerType() == 2 && stepOne.motionEvent == 1 {
            stepThree.advDuration = stepOne.motionVerificationPeriod
        }

        if stepThree.trigger && !stepThree.validParams() {
            view.showCentralToast("Params Error")
            return
        }

        if !stepThree.powerModeIsOn {
            stepThree.standbyDuration = "0"
            stepThree.advDuration = "1"
        }

        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.saveDataToDevice()
        })
        let msg = manager.fetchStepThreeAlert()
        alert.showAlert(title: "", message: msg)
    }

    private func saveDataToDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        MKBXSTriggerParamManager.shared.config(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Success")
            self?.perform(#selector(self?.goback), with: nil, afterDelay: 0.5)
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    @objc private func goback() {
        popToViewController(withClassName: "MKBXSSlotController")
    }

    // MARK: - Load Section

    private func loadSectionDatas() {
        loadSection0Datas()
        loadSection1Datas()
        loadSection2Datas()
        loadSection3Datas()
        headerList = (0..<4).map { _ in MKSwiftTableSectionLineHeaderModel() }
        tableView.reloadData()
    }

    private func loadSection0Datas() {
        section0List.removeAll()
        let model = MKSwiftTextSwitchCellModel()
        model.index = 0
        model.msg = "Advertising before trigger event occurs"
        model.isOn = MKBXSTriggerParamManager.shared.stepThreeModel.trigger
        section0List.append(model)
    }

    private func loadSection1Datas() {
        section1List.removeAll()
        let model = MKSwiftNormalTextCellModel()
        model.leftMsg = "Frame type"
        model.rightMsg = fetchFrameTypeMsg()
        section1List.append(model)
    }

    private func loadSection2Datas() {
        section2List.removeAll()
        let stepThree = MKBXSTriggerParamManager.shared.stepThreeModel
        switch stepThree.slotType {
        case .uid:
            let model = MKBXSSlotUIDCellModel()
            model.namespaceID = stepThree.namespaceID
            model.instanceID = stepThree.instanceID
            section2List.append(model)
        case .url:
            let model = MKBXSSlotURLCellModel()
            model.urlType = stepThree.urlType
            model.urlContent = stepThree.urlContent
            section2List.append(model)
        case .beacon:
            let model = MKBXSSlotBeaconCellModel()
            model.major = stepThree.major
            model.minor = stepThree.minor
            model.uuid = stepThree.uuid
            section2List.append(model)
        case .sensorInfo:
            let model = MKBXSSlotSensorInfoCellModel()
            model.deviceName = stepThree.deviceName
            model.tagEnable = !MKBXSConnectManager.shared.tagIdAutoFill
            if MKBXSConnectManager.shared.tagIdAutoFill {
                let mac = MKBXSConnectManager.shared.macAddress
                model.tagID = mac.replacingOccurrences(of: ":", with: "")
            } else {
                model.tagID = stepThree.tagID
            }
            section2List.append(model)
        default:
            break
        }
    }

    private func loadSection3Datas() {
        section3List.removeAll()
        let stepThree = MKBXSTriggerParamManager.shared.stepThreeModel
        guard stepThree.slotType != .null else { return }

        let model = MKBXSSlotParamCellModel()
        model.cellType = stepThree.slotType
        model.interval = stepThree.advInterval
        model.advDuration = stepThree.advDuration
        model.standbyDuration = stepThree.standbyDuration
        model.rssi = stepThree.rssi
        model.txPower = stepThree.txPower
        model.powerModeIsOn = stepThree.powerModeIsOn

        let stepOne = MKBXSTriggerParamManager.shared.stepOneModel
        if stepOne.trigger && stepOne.fetchTriggerType() == 2 && stepOne.motionEvent == 1 {
            model.powerModeButtonEnabled = false
        } else {
            model.powerModeButtonEnabled = true
        }
        section3List.append(model)
    }

    private func fetchFrameTypeMsg() -> String {
        switch MKBXSTriggerParamManager.shared.stepThreeModel.slotType {
        case .tlm: return "TLM"
        case .uid: return "UID"
        case .url: return "URL"
        case .beacon: return "iBeacon"
        case .sensorInfo: return "Sensor info"
        case .null: return "No Data"
        }
    }

    // MARK: - UI

    private func loadSubViews() {
        // ⬇️ 用 manager.slotIndex，和 OC 一致
        defaultTitle = "SLOT\(MKBXSTriggerParamManager.shared.slotIndex + 1)"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }

    private func tableHeaderView() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: MKScreen.width, height: 100))
        header.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        let stepLabel = UILabel(frame: CGRect(x: 15, y: 10, width: MKScreen.width - 30, height: 20))
        stepLabel.textAlignment = .left
        stepLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(
            strings: ["3", "/3", ":", "Before event occurs setting"],
            fonts: [MKFont.font(15), MKFont.font(13), MKFont.font(13), MKFont.font(18)],
            colors: [MKColor.navBar, UIColor(red: 137/255.0, green: 137/255.0, blue: 137/255.0, alpha: 1), MKColor.navBar, MKColor.defaultText]
        )
        header.addSubview(stepLabel)

        let noteLabel = UILabel(frame: CGRect(x: 15, y: 40, width: MKScreen.width - 30, height: 60))
        noteLabel.textAlignment = .left
        noteLabel.textColor = UIColor(red: 204/255.0, green: 102/255.0, blue: 72/255.0, alpha: 1)
        noteLabel.font = MKFont.font(13)
        noteLabel.numberOfLines = 0
        noteLabel.text = "*In this step, you can configure whether to enable pre-trigger broadcasting and related advertising parameters."
        header.addSubview(noteLabel)

        return header
    }

    private func tableFooterView() -> UIView {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: MKScreen.width, height: 80))
        footer.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        let btnWidth = (MKScreen.width - 3 * 30) / 2

        let backBtn = MKSwiftUIAdaptor.createRoundedButton(title: "Back",
                                                           target: self,
                                                           action: #selector(leftButtonMethod))
        backBtn.frame = CGRect(x: 30, y: 20, width: btnWidth, height: 40)
        footer.addSubview(backBtn)

        doneButton.frame = CGRect(x: 2 * 30 + btnWidth, y: 20, width: btnWidth, height: 40)
        footer.addSubview(doneButton)

        return footer
    }
}

// MARK: - TableView

extension MKBXSTriggerStepThreeController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        headerList.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let stepThree = MKBXSTriggerParamManager.shared.stepThreeModel
        switch section {
        case 0: return section0List.count
        case 1: return stepThree.trigger ? section1List.count : 0
        case 2: return stepThree.trigger ? section2List.count : 0
        case 3: return stepThree.trigger ? section3List.count : 0
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let stepThree = MKBXSTriggerParamManager.shared.stepThreeModel
        if indexPath.section == 2 && indexPath.row == 0 {
            switch stepThree.slotType {
            case .uid: return 120
            case .url: return 100
            case .beacon: return 160
            case .sensorInfo: return 120
            default: return 0
            }
        }
        if indexPath.section == 3 && indexPath.row == 0 {
            switch stepThree.slotType {
            case .tlm: return stepThree.powerModeIsOn ? 260 : 180
            case .uid, .url, .beacon, .sensorInfo: return stepThree.powerModeIsOn ? 300 : 220
            default: return 0
            }
        }
        return 44
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        10
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        header.headerModel = headerList[section]
        return header
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = MKSwiftTextSwitchCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[indexPath.row]
            cell.delegate = self
            return cell
        case 1:
            let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            return cell
        case 2:
            return loadSection2Cell(indexPath.row)
        default:
            return loadSection3Cell(indexPath.row)
        }
    }

    private func loadSection2Cell(_ row: Int) -> UITableViewCell {
        let stepThree = MKBXSTriggerParamManager.shared.stepThreeModel
        switch stepThree.slotType {
        case .uid:
            let cell = MKBXSSlotUIDCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[row] as? MKBXSSlotUIDCellModel
            cell.delegate = self
            return cell
        case .url:
            let cell = MKBXSSlotURLCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[row] as? MKBXSSlotURLCellModel
            cell.delegate = self
            return cell
        case .beacon:
            let cell = MKBXSSlotBeaconCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[row] as? MKBXSSlotBeaconCellModel
            cell.delegate = self
            return cell
        case .sensorInfo:
            let cell = MKBXSSlotSensorInfoCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[row] as? MKBXSSlotSensorInfoCellModel
            cell.delegate = self
            return cell
        default:
            return UITableViewCell(style: .default, reuseIdentifier: "MKBXSTriggerStepThreeControllerCell")
        }
    }

    private func loadSection3Cell(_ row: Int) -> UITableViewCell {
        let stepThree = MKBXSTriggerParamManager.shared.stepThreeModel
        guard stepThree.slotType != .null else {
            return UITableViewCell(style: .default, reuseIdentifier: "MKBXSTriggerStepThreeControllerCell")
        }
        let cell = MKBXSSlotParamCell.initCellWithTableView(tableView)
        cell.dataModel = section3List[row]
        cell.delegate = self
        return cell
    }
}

// MARK: - Cell Delegates

extension MKBXSTriggerStepThreeController: MKSwiftTextSwitchCellDelegate {
    public func MKSwiftTextSwitchCellStatusChanged(isOn: Bool, index: Int) {
        if index == 0 {
            section0List[0].isOn = isOn
            MKBXSTriggerParamManager.shared.stepThreeModel.trigger = isOn
            tableView.reloadData()
        }
    }
}

extension MKBXSTriggerStepThreeController: MKBXSSlotBeaconCellDelegate {
    public func bxs_advContent_majorChanged(_ major: String) {
        MKBXSTriggerParamManager.shared.stepThreeModel.major = major
    }
    public func bxs_advContent_minorChanged(_ minor: String) {
        MKBXSTriggerParamManager.shared.stepThreeModel.minor = minor
    }
    public func bxs_advContent_uuidChanged(_ uuid: String) {
        MKBXSTriggerParamManager.shared.stepThreeModel.uuid = uuid
    }
}

extension MKBXSTriggerStepThreeController: MKBXSSlotSensorInfoCellDelegate {
    public func bxs_advContent_tagInfo_deviceNameChanged(_ text: String) {
        MKBXSTriggerParamManager.shared.stepThreeModel.deviceName = text
    }
    public func bxs_advContent_tagInfo_tagIDChanged(_ text: String) {
        MKBXSTriggerParamManager.shared.stepThreeModel.tagID = text
    }
}

extension MKBXSTriggerStepThreeController: MKBXSSlotUIDCellDelegate {
    public func bxs_advContent_namespaceIDChanged(_ text: String) {
        MKBXSTriggerParamManager.shared.stepThreeModel.namespaceID = text
    }
    public func bxs_advContent_instanceIDChanged(_ text: String) {
        MKBXSTriggerParamManager.shared.stepThreeModel.instanceID = text
    }
}

extension MKBXSTriggerStepThreeController: MKBXSSlotURLCellDelegate {
    public func bxs_advContent_urlTypeChanged(_ urlType: Int) {
        MKBXSTriggerParamManager.shared.stepThreeModel.urlType = urlType
    }
    public func bxs_advContent_urlContentChanged(_ content: String) {
        MKBXSTriggerParamManager.shared.stepThreeModel.urlContent = content
    }
}

extension MKBXSTriggerStepThreeController: MKBXSSlotParamCellDelegate {
    public func bxs_slotParam_advIntervalChanged(_ interval: String) {
        MKBXSTriggerParamManager.shared.stepThreeModel.advInterval = interval
    }
    public func bxs_slotParam_advDurationChanged(_ duration: String) {
        MKBXSTriggerParamManager.shared.stepThreeModel.advDuration = duration
    }
    public func bxs_slotParam_standbyDurationChanged(_ duration: String) {
        MKBXSTriggerParamManager.shared.stepThreeModel.standbyDuration = duration
    }
    public func bxs_slotParam_rssiChanged(_ rssi: Int) {
        MKBXSTriggerParamManager.shared.stepThreeModel.rssi = rssi
    }
    public func bxs_slotParam_txPowerChanged(_ txPower: MKBXSTxPower) {
        MKBXSTriggerParamManager.shared.stepThreeModel.txPower = txPower
    }
    public func bxs_slotParam_lowerPowerDetailPressed() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "OK") {})
        alert.showAlert(title: "Low-power mode", message: "If this function is enabled, the device will periodically sleeps for a period of time during broadcast.")
    }
    public func bxs_slotParam_lowerPowerModeChanged(_ isOn: Bool) {
        MKBXSTriggerParamManager.shared.stepThreeModel.powerModeIsOn = isOn
        loadSectionDatas()
    }
}
