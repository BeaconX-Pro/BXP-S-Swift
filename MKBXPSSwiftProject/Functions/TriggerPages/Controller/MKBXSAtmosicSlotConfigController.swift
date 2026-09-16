//
//  MKBXSAtmosicSlotConfigController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/13.
//

import UIKit
import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSAtmosicSlotConfigController: MKSwiftBaseViewController {

    public var slotIndex: Int = 0

    // MARK: - Data

    private lazy var section0List: [MKBXSSlotSensorInfoCellModel] = []
    private lazy var section1List: [MKBXSSlotParamCellModel] = []
    private lazy var headerList: [MKSwiftTableSectionLineHeaderModel] = []

    private lazy var dataModel = MKBXSAtmosicSlotConfigModel(slotIndex: slotIndex)

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        tv.delegate = self
        tv.dataSource = self
        tv.separatorStyle = .none
        if #available(iOS 15.0, *) {
            tv.sectionHeaderTopPadding = 0
        }
        return tv
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

        headerList.removeAll()
        for _ in 0..<2 {
            headerList.append(MKSwiftTableSectionLineHeaderModel())
        }
        tableView.reloadData()
    }

    private func loadSection0Datas() {
        section0List.removeAll()

        let cellModel = MKBXSSlotSensorInfoCellModel()
        cellModel.deviceName = dataModel.deviceName
        cellModel.tagEnable = !MKBXSConnectManager.shared.tagIdAutoFill
        if MKBXSConnectManager.shared.tagIdAutoFill {
            let macAddress = MKBXSConnectManager.shared.macAddress
            cellModel.tagID = macAddress.replacingOccurrences(of: ":", with: "")
        } else {
            cellModel.tagID = dataModel.tagID
        }

        section0List.append(cellModel)
    }

    private func loadSection1Datas() {
        section1List.removeAll()

        let cellModel = MKBXSSlotParamCellModel()
        cellModel.cellType = .sensorInfo
        cellModel.interval = dataModel.advInterval
        cellModel.advDuration = dataModel.advDuration
        cellModel.standbyDuration = dataModel.standbyDuration
        cellModel.rssi = dataModel.rssi
        cellModel.txPower = dataModel.txPower
        cellModel.powerModeIsOn = dataModel.powerModeIsOn

        section1List.append(cellModel)
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

// MARK: - UITableViewDelegate, UITableViewDataSource

extension MKBXSAtmosicSlotConfigController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        headerList.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return section0List.count
        case 1: return section1List.count
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return 120
        }
        if indexPath.section == 1 && indexPath.row == 0 {
            return dataModel.powerModeIsOn ? 300 : 220
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
        if indexPath.section == 0 {
            return loadSection0Cell(indexPath.row)
        }
        return loadSection1Cell(indexPath.row)
    }

    private func loadSection0Cell(_ row: Int) -> UITableViewCell {
        let cell = MKBXSSlotSensorInfoCell.initCellWithTableView(tableView)
        cell.dataModel = section0List[row]
        cell.delegate = self
        return cell
    }

    private func loadSection1Cell(_ row: Int) -> UITableViewCell {
        let cell = MKBXSSlotParamCell.initCellWithTableView(tableView)
        cell.dataModel = section1List[row]
        cell.delegate = self
        return cell
    }
}

// MARK: - MKBXSSlotSensorInfoCellDelegate

extension MKBXSAtmosicSlotConfigController: MKBXSSlotSensorInfoCellDelegate {

    public func bxs_advContent_tagInfo_deviceNameChanged(_ text: String) {
        dataModel.deviceName = text
    }

    public func bxs_advContent_tagInfo_tagIDChanged(_ text: String) {
        dataModel.tagID = text
    }
}

// MARK: - MKBXSSlotParamCellDelegate

extension MKBXSAtmosicSlotConfigController: MKBXSSlotParamCellDelegate {

    public func bxs_slotParam_advIntervalChanged(_ interval: String) {
        dataModel.advInterval = interval
    }

    public func bxs_slotParam_advDurationChanged(_ duration: String) {
        dataModel.advDuration = duration
    }

    public func bxs_slotParam_standbyDurationChanged(_ duration: String) {
        dataModel.standbyDuration = duration
    }

    public func bxs_slotParam_rssiChanged(_ rssi: Int) {
        dataModel.rssi = rssi
    }

    public func bxs_slotParam_txPowerChanged(_ txPower: MKBXSTxPower) {
        dataModel.txPower = txPower
    }

    public func bxs_slotParam_lowerPowerDetailPressed() {
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "OK") {})
        alert.showAlert(title: "Low-power mode",
                        message: "If this function is enabled, the device will periodically sleeps for a period of time during broadcast.")
    }

    public func bxs_slotParam_lowerPowerModeChanged(_ isOn: Bool) {
        dataModel.powerModeIsOn = isOn
        loadSectionDatas()
    }
}
