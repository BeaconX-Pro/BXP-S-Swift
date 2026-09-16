//
//  MKBXSSensorAdvancedController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSSensorAdvancedController: MKSwiftBaseViewController {

    // MARK: - Properties

    private var hasHumidity: Bool = false

    private lazy var headerViewModel: MKBXSSensorHeaderViewModel = {
        let vm = MKBXSSensorHeaderViewModel()
        vm.humidity = "--"
        return vm
    }()

    private lazy var headerView: MKBXSSensorHeaderView = {
        let height: CGFloat = hasHumidity ? 200 : 170
        let header = MKBXSSensorHeaderView(frame: CGRect(x: 0, y: 0, width: MKScreen.width, height: height))
        header.delegate = self
        header.hasHumidity = hasHumidity
        return header
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        tv.delegate = self
        tv.dataSource = self
        tv.tableHeaderView = headerView
        tv.separatorStyle = .none
        if #available(iOS 15.0, *) {
            tv.sectionHeaderTopPadding = 0
        }
        return tv
    }()

    private lazy var section0List: [MKSwiftTextSwitchCellModel] = []
    private lazy var section1List: [MKSwiftTextFieldCellModel] = []
    private lazy var section2List: [MKBXSTempAlertThresholdCellModel] = []
    private lazy var section3List: [MKBXSSyncTimeCellModel] = []
    private lazy var section4List: [MKSwiftSettingTextCellModel] = []
    private lazy var section5List: [MKSwiftSettingTextCellModel] = []
    private lazy var headerList: [MKSwiftTableSectionLineHeaderModel] = []

    private let dataModel = MKBXSSensorModel()

    deinit {
        MKBXSCentralManager.shared.notifyTHSensorData(false)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        hasHumidity = (MKBXSConnectManager.shared.thSensorType == .th)
        loadSubViews()
        readDataFromDevice()
    }

    public override func rightButtonMethod() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        dataModel.config(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Success")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - Read

    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.read(sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.headerViewModel.interval = self.dataModel.samplingInterval
            // ⬇️ 关键：主动把 viewModel 赋值给 headerView，刷新 textField
            self.headerView.dataModel = self.headerViewModel
            self.loadSectionDatas()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.receiveHTData(_:)),
                                                   name: .mk_bxs_receiveHTData,
                                                   object: nil)
            MKBXSCentralManager.shared.notifyTHSensorData(true)
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - Notification

    @objc private func receiveHTData(_ note: Notification) {
        guard let dic = note.userInfo as? [String: Any] else { return }
        headerViewModel.temperature = (dic["temperature"] as? String) ?? ""
        if hasHumidity {
            headerViewModel.humidity = (dic["humidity"] as? String) ?? ""
        }
        headerView.dataModel = headerViewModel
    }

    // MARK: - Interface

    private func syncTime() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        let timestamp = formatter.string(from: date)
        MKBXSInterface.configDeviceTime(timestamp: UInt(date.timeIntervalSince1970), sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            if self.section3List.count > 0 {
                self.section3List[0].date = timestamp
                self.dataModel.deviceTime = timestamp
                self.tableView.reloadData()
            }
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    private func clearTemperatureTriggerCount() {
        MKSwiftHudManager.shared.showHUD(with: "Clearing...", in: view, isPenetration: false)
        dataModel.clearTemperatureTriggerCount(sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.dataModel.temperatureTriggerCount = "0"
            if self.section2List.count > 0 {
                self.section2List[0].count = "0"
                self.tableView.reloadData()
            }
            self.view.showCentralToast("Clear Success")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - Load Section

    private func loadSectionDatas() {
        section0List.removeAll()
        section1List.removeAll()
        section2List.removeAll()
        section3List.removeAll()
        section4List.removeAll()
        section5List.removeAll()
        headerList.removeAll()

        // 0: 存储开关
        let cell0 = MKSwiftTextSwitchCellModel()
        cell0.msg = hasHumidity ? "T&H Data Store" : "Temperature Data Store"
        cell0.index = 0
        cell0.isOn = dataModel.dataStore
        section0List.append(cell0)

        // 1: 存储参数
        let cell1a = MKSwiftTextFieldCellModel()
        cell1a.msg = "Storage interval"
        cell1a.index = 0
        cell1a.textFieldType = .realNumberOnly
        cell1a.textPlaceholder = hasHumidity ? "0~65535" : "1~65535"
        cell1a.maxLength = 5
        cell1a.textFieldValue = dataModel.interval
        cell1a.unit = "min"
        section1List.append(cell1a)

        let cell1b = MKSwiftTextFieldCellModel()
        cell1b.msg = "Storage start delay"
        cell1b.index = 1
        cell1b.textFieldType = .realNumberOnly
        cell1b.textPlaceholder = "0~1440"
        cell1b.maxLength = 4
        cell1b.textFieldValue = dataModel.storageStartDelay
        cell1b.unit = "min"
        section1List.append(cell1b)

        // 2: 温度告警阈值
        let cell2 = MKBXSTempAlertThresholdCellModel()
        cell2.isOn = dataModel.temperatureTriggerOn
        cell2.maxTemperature = dataModel.maxTemperature.isEmpty ? "0.0" : dataModel.maxTemperature
        cell2.minTemperature = dataModel.minTemperature.isEmpty ? "0.0" : dataModel.minTemperature
        cell2.count = dataModel.temperatureTriggerCount.isEmpty ? "0" : dataModel.temperatureTriggerCount
        section2List.append(cell2)

        // 3: 同步时间
        let cell3 = MKBXSSyncTimeCellModel()
        cell3.date = dataModel.deviceTime
        section3List.append(cell3)

        // 4: 导出温湿度数据
        let cell4 = MKSwiftSettingTextCellModel()
        cell4.leftMsg = hasHumidity ? "Export T&H data" : "Export Temperature data"
        section4List.append(cell4)

        // 5: 导出 Mark 数据
        let cell5 = MKSwiftSettingTextCellModel()
        cell5.leftMsg = "ExportMark data"
        section5List.append(cell5)

        for _ in 0..<6 {
            headerList.append(MKSwiftTableSectionLineHeaderModel())
        }
        tableView.reloadData()
    }

    // MARK: - UI

    private func loadSubViews() {
        setNavTitleFont(MKFont.font(15))
        defaultTitle = hasHumidity ? "Temperature & Humidity" : "Temperature"
        rightButton.setImage(UIImage(named: "bxs_slotSaveIcon.png"), for: .normal)
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }
}

// MARK: - TableView

extension MKBXSSensorAdvancedController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int { headerList.count }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0List.count
        case 1: return dataModel.dataStore ? section1List.count : 0
        case 2: return dataModel.supportAdvancedFeatures ? section2List.count : 0
        case 3: return section3List.count
        case 4: return section4List.count
        case 5: return MKBXSConnectManager.shared.deviceType == .nordic ? section5List.count : 0
        default: return 0
        }
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = MKSwiftTextSwitchCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[indexPath.row]
            cell.delegate = self
            return cell
        case 1:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            cell.delegate = self
            return cell
        case 2:
            let cell = MKBXSTempAlertThresholdCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[indexPath.row]
            cell.delegate = self
            return cell
        case 3:
            let cell = MKBXSSyncTimeCell.initCellWithTableView(tableView)
            cell.dataModel = section3List[indexPath.row]
            cell.delegate = self
            return cell
        case 4:
            let cell = MKSwiftSettingTextCell.initCellWithTableView(tableView)
            cell.dataModel = section4List[indexPath.row]
            return cell
        default:
            let cell = MKSwiftSettingTextCell.initCellWithTableView(tableView)
            cell.dataModel = section5List[indexPath.row]
            return cell
        }
    }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 2: return 140
        case 3: return 80
        default: return 44
        }
    }
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 10 }
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        header.headerModel = headerList[section]
        return header
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 4 && indexPath.row == 0 {
            let vc = MKBXSNewExportDataController()
            navigationController?.pushViewController(vc, animated: true)
        }
        if indexPath.section == 5 && indexPath.row == 0 {
            let vc = MKBXSExportMarkDataController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - Delegates

extension MKBXSSensorAdvancedController: MKSwiftTextSwitchCellDelegate {
    public func MKSwiftTextSwitchCellStatusChanged(isOn: Bool, index: Int) {
        if index == 0 {
            dataModel.dataStore = isOn
            section0List[0].isOn = isOn
            tableView.reloadSections(IndexSet(integer: 1), with: .none)
        }
    }
}

extension MKBXSSensorAdvancedController: MKSwiftTextFieldCellDelegate {
    public func mkDeviceTextCellValueChanged(_ index: Int, textValue: String) {
        if index == 0 {
            dataModel.interval = textValue
            section1List[0].textFieldValue = textValue
        } else if index == 1 {
            dataModel.storageStartDelay = textValue
            section1List[1].textFieldValue = textValue
        }
    }
}

extension MKBXSSensorAdvancedController: MKBXSSyncTimeCellDelegate {
    public func bxs_syncTimeCell_syncTimePressed() {
        syncTime()
    }
}

extension MKBXSSensorAdvancedController: MKBXSSensorHeaderViewDelegate {
    public func bxs_sensorHeaderView_samplingIntervalChanged(_ interval: String) {
        dataModel.samplingInterval = interval
        headerViewModel.interval = interval
    }
}

extension MKBXSSensorAdvancedController: MKBXSTempAlertThresholdCellDelegate {
    public func bxs_tempAlertThresholdCell_thresholdStatusChanged(_ isOn: Bool) {
        dataModel.temperatureTriggerOn = isOn
        if section2List.count > 0 { section2List[0].isOn = isOn }
    }
    public func bxs_tempAlertThresholdCell_temperatureChanged(_ maxTemperature: String, minTemperature: String) {
        dataModel.maxTemperature = maxTemperature
        dataModel.minTemperature = minTemperature
        if section2List.count > 0 {
            section2List[0].maxTemperature = maxTemperature
            section2List[0].minTemperature = minTemperature
        }
    }
    public func bxs_tempAlertThresholdCell_tempAlertStatusClear() {
        clearTemperatureTriggerCount()
    }
}
