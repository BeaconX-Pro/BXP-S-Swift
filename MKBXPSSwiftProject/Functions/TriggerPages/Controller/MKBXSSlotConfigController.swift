//
//  MKBXSSlotConfigController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSSlotConfigController: MKSwiftBaseViewController {

    public var slotIndex: Int = 0

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        tv.delegate = self
        tv.dataSource = self
        tv.tableHeaderView = headerView
        tv.separatorStyle = .none
        // iOS 15+ 需要关掉默认的 section header top padding
        if #available(iOS 15.0, *) {
            tv.sectionHeaderTopPadding = 0
        }
        return tv
    }()

    private lazy var headerView: MKBXSSlotFrameTypePickView = {
        let header = MKBXSSlotFrameTypePickView(frame: CGRect(x: 0, y: 20, width: MKScreen.width, height: 130))
        header.delegate = self
        return header
    }()

    // MARK: - Data

    private lazy var section0List: [Any] = []
    private lazy var section1List: [MKBXSSlotParamCellModel] = []
    private lazy var section2List: [MKSwiftNormalTextCellModel] = []
    private lazy var headerList: [MKSwiftTableSectionLineHeaderModel] = []

    private lazy var dataModel = MKBXSSlotConfigDataModel(slotIndex: slotIndex)

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
        readDataFromDevice()
    }

    // MARK: - Super Method

    public override func rightButtonMethod() {
        saveDataToDevice()
    }

    // MARK: - Interface

    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.read(sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.headerView.updateFrameType(self.dataModel.slotType)
            self.loadSectionDatas()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    private func saveDataToDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        dataModel.config(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Success")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - Load Section

    private func loadSectionDatas() {
        loadSection0Datas()
        loadSection1Datas()
        loadSection2Datas()
        headerList = (0..<3).map { _ in MKSwiftTableSectionLineHeaderModel() }
        tableView.reloadData()
    }

    private func loadSection0Datas() {
        section0List.removeAll()
        switch dataModel.slotType {
        case .uid:
            let cellModel = MKBXSSlotUIDCellModel()
            cellModel.namespaceID = dataModel.namespaceID
            cellModel.instanceID = dataModel.instanceID
            section0List.append(cellModel)
        case .url:
            let cellModel = MKBXSSlotURLCellModel()
            cellModel.urlType = dataModel.urlType
            cellModel.urlContent = dataModel.urlContent
            section0List.append(cellModel)
        case .beacon:
            let cellModel = MKBXSSlotBeaconCellModel()
            cellModel.major = dataModel.major
            cellModel.minor = dataModel.minor
            cellModel.uuid = dataModel.uuid
            section0List.append(cellModel)
        case .sensorInfo:
            let cellModel = MKBXSSlotSensorInfoCellModel()
            cellModel.deviceName = dataModel.deviceName
            cellModel.tagEnable = !MKBXSConnectManager.shared.tagIdAutoFill
            if MKBXSConnectManager.shared.tagIdAutoFill {
                let mac = MKBXSConnectManager.shared.macAddress
                cellModel.tagID = mac.replacingOccurrences(of: ":", with: "")
            } else {
                cellModel.tagID = dataModel.tagID
            }
            section0List.append(cellModel)
        default:
            break
        }
    }

    private func loadSection1Datas() {
        section1List.removeAll()
        guard dataModel.slotType != .null else { return }
        let cellModel = MKBXSSlotParamCellModel()
        cellModel.cellType = dataModel.slotType
        cellModel.interval = dataModel.advInterval
        cellModel.advDuration = dataModel.advDuration
        cellModel.standbyDuration = dataModel.standbyDuration
        cellModel.rssi = dataModel.rssi
        cellModel.txPower = dataModel.txPower
        cellModel.powerModeIsOn = dataModel.powerModeIsOn
        section1List.append(cellModel)
    }

    private func loadSection2Datas() {
        section2List.removeAll()
        let cellModel = MKSwiftNormalTextCellModel()
        cellModel.leftMsg = "Trigger"
        cellModel.showRightIcon = true
        cellModel.rightMsg = "OFF"
        section2List.append(cellModel)
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "SLOT\(slotIndex + 1)"
        rightButton.setImage(UIImage(named: "bxs_slotSaveIcon.png"), for: .normal)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }
}

// MARK: - TableView

extension MKBXSSlotConfigController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        headerList.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return (dataModel.slotType == .tlm || dataModel.slotType == .null) ? 0 : section0List.count
        case 1:
            return dataModel.slotType == .null ? 0 : section1List.count
        case 2:
            let manager = MKBXSConnectManager.shared
            if manager.thSensorType == .none && manager.accStatus == 0 && (manager.hallStatus || manager.resetByButton) {
                return 0
            }
            return section2List.count
        default:
            return 0
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            switch dataModel.slotType {
            case .uid: return 120
            case .url: return 100
            case .beacon: return 160
            case .sensorInfo: return 120
            default: return 0
            }
        }
        if indexPath.section == 1 && indexPath.row == 0 {
            switch dataModel.slotType {
            case .tlm:
                return dataModel.powerModeIsOn ? 260 : 180
            case .uid, .url, .beacon, .sensorInfo:
                return dataModel.powerModeIsOn ? 300 : 220
            default:
                return 0
            }
        }
        if indexPath.section == 2 && indexPath.row == 0 {
            let manager = MKBXSConnectManager.shared
            if manager.thSensorType == .none && manager.accStatus == 0 && (manager.hallStatus || manager.resetByButton) {
                return 0
            }
            return 44
        }
        return 0
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
        case 0: return loadSection0Cell(indexPath.row)
        case 1: return loadSection1Cell(indexPath.row)
        default: return loadSection2Cell(indexPath.row)
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row == 0 {
            let vc = MKBXSTriggerStepOneController()
            vc.slotIndex = slotIndex
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: - Cell Loader

    private func loadSection0Cell(_ row: Int) -> UITableViewCell {
        switch dataModel.slotType {
        case .uid:
            let cell = MKBXSSlotUIDCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[row] as? MKBXSSlotUIDCellModel
            cell.delegate = self
            return cell
        case .url:
            let cell = MKBXSSlotURLCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[row] as? MKBXSSlotURLCellModel
            cell.delegate = self
            return cell
        case .beacon:
            let cell = MKBXSSlotBeaconCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[row] as? MKBXSSlotBeaconCellModel
            cell.delegate = self
            return cell
        case .sensorInfo:
            let cell = MKBXSSlotSensorInfoCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[row] as? MKBXSSlotSensorInfoCellModel
            cell.delegate = self
            return cell
        default:
            return UITableViewCell(style: .default, reuseIdentifier: "MKBXSSlotConfigControllerCell")
        }
    }

    private func loadSection1Cell(_ row: Int) -> UITableViewCell {
        guard dataModel.slotType != .null else {
            return UITableViewCell(style: .default, reuseIdentifier: "MKBXSSlotConfigControllerCell")
        }
        let cell = MKBXSSlotParamCell.initCellWithTableView(tableView)
        cell.dataModel = section1List[row]
        cell.delegate = self
        return cell
    }

    private func loadSection2Cell(_ row: Int) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = section2List[row]
        return cell
    }
}

// MARK: - MKBXSSlotFrameTypePickViewDelegate

extension MKBXSSlotConfigController: MKBXSSlotFrameTypePickViewDelegate {
    public func bxs_slotFrameTypeChanged(_ frameType: MKBXSSlotType) {
        dataModel.slotType = frameType
        loadSectionDatas()
    }
}

// MARK: - Cell Delegates

extension MKBXSSlotConfigController: MKBXSSlotUIDCellDelegate {
    public func bxs_advContent_namespaceIDChanged(_ text: String) { dataModel.namespaceID = text }
    public func bxs_advContent_instanceIDChanged(_ text: String) { dataModel.instanceID = text }
}

extension MKBXSSlotConfigController: MKBXSSlotURLCellDelegate {
    public func bxs_advContent_urlTypeChanged(_ urlType: Int) { dataModel.urlType = urlType }
    public func bxs_advContent_urlContentChanged(_ content: String) { dataModel.urlContent = content }
}

extension MKBXSSlotConfigController: MKBXSSlotBeaconCellDelegate {
    public func bxs_advContent_majorChanged(_ major: String) { dataModel.major = major }
    public func bxs_advContent_minorChanged(_ minor: String) { dataModel.minor = minor }
    public func bxs_advContent_uuidChanged(_ uuid: String) { dataModel.uuid = uuid }
}

extension MKBXSSlotConfigController: MKBXSSlotSensorInfoCellDelegate {
    public func bxs_advContent_tagInfo_deviceNameChanged(_ text: String) { dataModel.deviceName = text }
    public func bxs_advContent_tagInfo_tagIDChanged(_ text: String) { dataModel.tagID = text }
}

extension MKBXSSlotConfigController: MKBXSSlotParamCellDelegate {
    public func bxs_slotParam_txPowerChanged(_ txPower: MKBXSTxPower) {
        dataModel.txPower = txPower
    }
    public func bxs_slotParam_advIntervalChanged(_ interval: String) { dataModel.advInterval = interval }
    public func bxs_slotParam_advDurationChanged(_ duration: String) { dataModel.advDuration = duration }
    public func bxs_slotParam_standbyDurationChanged(_ duration: String) { dataModel.standbyDuration = duration }
    public func bxs_slotParam_rssiChanged(_ rssi: Int) { dataModel.rssi = rssi }
    public func bxs_slotParam_lowerPowerDetailPressed() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "OK") {})
        alert.showAlert(title: "Low-power mode", message: "If this function is enabled, the device will periodically sleeps for a period of time during broadcast.")
    }
    public func bxs_slotParam_lowerPowerModeChanged(_ isOn: Bool) {
        dataModel.powerModeIsOn = isOn
        loadSectionDatas()
    }
}
