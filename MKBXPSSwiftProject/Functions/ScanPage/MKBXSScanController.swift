//
//  MKBXSScanController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import CoreBluetooth

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBeaconXCustomUI
import MKSwiftBleModule

public final class MKBXSScanController: MKSwiftBaseViewController {

    // MARK: - Constants

    private let localPasswordKey = "mk_bxs_passwordKey"
    private let offsetX: CGFloat = 15
    private let searchButtonHeight: CGFloat = 40
    private let headerViewHeight: CGFloat = 90
    private let kRefreshInterval: TimeInterval = 0.5

    // MARK: - Properties

    private var dataList: [MKBXSScanInfoCellModel] = []
    private let buttonModel: MKSwiftBXScanSearchButtonModel = {
        let m = MKSwiftBXScanSearchButtonModel()
        m.placeholder = "Edit Filter"
        m.minSearchRssi = -100
        m.searchRssi = -100
        return m
    }()

    private var observerRef: CFRunLoopObserver?
    private var isNeedRefresh: Bool = false
    private var asciiText: String = ""

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.delegate = self
        tv.dataSource = self
        return tv
    }()

    private lazy var searchButton: MKSwiftBXScanSearchButton = {
        let btn = MKSwiftBXScanSearchButton()
        btn.delegate = self
        return btn
    }()

    private lazy var refreshIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_scan_refreshIcon.png")
        return iv
    }()

    private lazy var refreshButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(refreshButtonPressed), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle

    deinit {
        NotificationCenter.default.removeObserver(self)
        if let observer = observerRef {
            CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, .commonModes)
        }
        MKBXSCentralManager.shared.stopScan()
        MKBXSCentralManager.removeFromCentralList()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        startRefresh()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(dfuUpdateComplete),
                                               name: Notification.Name("mk_bxs_centralDeallocNotification"),
                                               object: nil)
    }

    public override func rightButtonMethod() {
        let vc = MKBXSAboutController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Events

    @objc private func refreshButtonPressed() {
        if MKSwiftBleBaseCentralManager.shared.centralManager.state == .unauthorized {
            showAuthorizationAlert()
            return
        }
        if MKSwiftBleBaseCentralManager.shared.centralManager.state == .poweredOff {
            showBLEDisable()
            return
        }
        refreshButton.isSelected.toggle()
        refreshIcon.layer.removeAnimation(forKey: "mk_refreshAnimationKey")
        if !refreshButton.isSelected {
            MKBXSCentralManager.shared.stopScan()
            return
        }
        dataList.removeAll()
        tableView.reloadData()
        defaultTitle = "DEVICE(\(dataList.count))"

        // 内联 refreshAnimation
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.duration = 2.0
        animation.fromValue = 0
        animation.toValue = 2 * Double.pi
        animation.autoreverses = false
        animation.repeatCount = MAXFLOAT
        animation.isRemovedOnCompletion = false
        refreshIcon.layer.add(animation, forKey: "mk_refreshAnimationKey")

        MKBXSCentralManager.shared.startScan()
    }

    @objc private func dfuUpdateComplete() {
        mk_bxs_needResetScanDelegate(true)
    }

    public func mk_bxs_needResetScanDelegate(_ need: Bool) {
        if need {
            MKBXSCentralManager.shared.delegate = self
        }
        perform(#selector(startScanDevice), with: nil, afterDelay: need ? 1.0 : 0.1)
    }

    @objc private func startScanDevice() {
        refreshButton.isSelected = false
        refreshButtonPressed()
    }

    // MARK: - Refresh

    private func startRefresh() {
        searchButton.dataModel = buttonModel
        runloopObserver()
        MKBXSCentralManager.shared.delegate = self

        let firstInstall = UserDefaults.standard.object(forKey: "mk_bxs_firstInstall")
        var afterTime: TimeInterval = 0.5
        if firstInstall == nil {
            UserDefaults.standard.set(false, forKey: "mk_bxs_firstInstall")
            afterTime = 3.5
        }
        perform(#selector(refreshButtonPressed), with: nil, afterDelay: afterTime)
    }

    private func needRefreshList() {
        isNeedRefresh = true
        CFRunLoopWakeUp(CFRunLoopGetMain())
    }

    private func runloopObserver() {
        var timeInterval = Date().timeIntervalSince1970
        observerRef = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.allActivities.rawValue, true, 0) { [weak self] _, activity in
            guard let self = self else { return }
            if activity == .beforeWaiting {
                let currentInterval = Date().timeIntervalSince1970
                if currentInterval - timeInterval < self.kRefreshInterval { return }
                timeInterval = currentInterval
                if self.isNeedRefresh {
                    self.tableView.reloadData()
                    self.defaultTitle = "DEVICE(\(self.dataList.count))"
                    self.isNeedRefresh = false
                }
            }
        }
        if let observer = observerRef {
            CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, .commonModes)
        }
    }

    // MARK: - Data

    private func updateDataWithBeacon(_ beacon: MKBXSBaseBeacon) {
        guard beacon.frameType != .unknown else { return }

        let searchMac = buttonModel.searchMac ?? ""
        let searchName = buttonModel.searchName ?? ""

        // 开启了名字/MAC 过滤
        if !searchMac.isEmpty || !searchName.isEmpty {
            if beacon.rssi.intValue >= buttonModel.searchRssi {
                filterBeaconWithSearchName(beacon)
            }
            return
        }

        // 只开了 RSSI 过滤
        if buttonModel.searchRssi > buttonModel.minSearchRssi {
            if beacon.rssi.intValue >= buttonModel.searchRssi {
                processBeacon(beacon)
            }
            return
        }

        // 无过滤
        processBeacon(beacon)
    }

    private func filterBeaconWithSearchName(_ beacon: MKBXSBaseBeacon) {
        let searchName = (buttonModel.searchName ?? "").uppercased()
        let searchMac = (buttonModel.searchMac ?? "").uppercased()

        if let sensorBeacon = beacon as? MKBXSSensorInfoBeacon {
            let name = (sensorBeacon.deviceName ?? "").uppercased()
            let tagID = sensorBeacon.tagID.uppercased()
            if name.contains(searchName) || tagID.contains(searchMac) {
                processBeacon(beacon)
            }
            return
        }
        guard let peripheral = beacon.peripheral else { return }
        let identy = peripheral.identifier.uuidString
        guard let existing = dataList.first(where: { $0.identifier == identy }) else { return }
        MKBXSScanPageAdopter.updateInfoCellModel(existing, beaconData: beacon)
        needRefreshList()
    }

    private func processBeacon(_ beacon: MKBXSBaseBeacon) {
        guard let peripheral = beacon.peripheral else { return }
        let identy = peripheral.identifier.uuidString
        if let existing = dataList.first(where: { $0.identifier == identy }) {
            MKBXSScanPageAdopter.updateInfoCellModel(existing, beaconData: beacon)
            needRefreshList()
            return
        }
        let deviceModel = MKBXSScanPageAdopter.parseBaseBeaconToInfoModel(beacon)
        dataList.append(deviceModel)
        needRefreshList()
    }

    // MARK: - Connect

    private func connectPeripheral(_ peripheral: CBPeripheral) {
        refreshIcon.layer.removeAnimation(forKey: "mk_refreshAnimationKey")
        MKBXSCentralManager.shared.stopScan()
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        MKBXSCentralManager.shared.readNeedPassword(peripheral: peripheral) { [weak self] result in
            MKSwiftHudManager.shared.hide()
            guard let self = self else { return }
            let state = result["state"] as? String ?? ""
            if state == "00" {
                self.connectDeviceWithoutPassword(peripheral)
                return
            }
            self.connectDeviceWithPassword(peripheral)
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
            self?.connectFailed()
        }
    }

    private func connectDeviceWithPassword(_ peripheral: CBPeripheral) {
        let localPassword = UserDefaults.standard.string(forKey: localPasswordKey) ?? ""
        asciiText = localPassword

        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") { [weak self] in
            self?.refreshButton.isSelected = false
            self?.refreshButtonPressed()
        })
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.startConnectPeripheral(peripheral, needPassword: true)
        })
        let textField = MKSwiftAlertViewTextField(textValue: localPassword,
                                                  placeholder: "No more than 16 characters.",
                                                  textFieldType: .normal,
                                                  maxLength: 16) { [weak self] text in
            self?.asciiText = text
        }
        alert.addTextField(textField)
        alert.showAlert(title: "Enter password", message: "Please enter connection password.")
    }

    private func connectDeviceWithoutPassword(_ peripheral: CBPeripheral) {
        startConnectPeripheral(peripheral, needPassword: false)
    }

    private func startConnectPeripheral(_ peripheral: CBPeripheral, needPassword: Bool) {
        if needPassword {
            let password = asciiText
            if password.isEmpty {
                view.showCentralToast("Password cannot be empty.")
                return
            }
            if password.count > 16 {
                view.showCentralToast("No more than 16 characters.")
                return
            }
        }
        MKSwiftHudManager.shared.showHUD(with: "Connecting...", in: view, isPenetration: false)
        MKBXSConnectManager.shared.connectDevice(peripheral: peripheral,
                                                 password: needPassword ? asciiText : "") { [weak self] in
            guard let self = self else { return }
            if !self.asciiText.isEmpty && self.asciiText.count <= 16 {
                UserDefaults.standard.set(self.asciiText, forKey: self.localPasswordKey)
            }
            MKSwiftHudManager.shared.hide()
            self.perform(#selector(self.pushTabBarPage), with: nil, afterDelay: 0.6)
        } failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
            self?.connectFailed()
        }
    }

    @objc private func pushTabBarPage() {
        let vc = MKBXSTabBarController()
        vc.modalPresentationStyle = .fullScreen
        // delegate 已被 UITabBarController 占用，改用 mkDelegate
        vc.mkDelegate = self
        present(vc, animated: true)
    }

    private func connectFailed() {
        refreshButton.isSelected = false
        refreshButtonPressed()
    }

    // MARK: - Alerts

    private func showAuthorizationAlert() {
        let alert = UIAlertController(title: "", message: "This function requires Bluetooth authorization, please enable MK Tag permission in Settings-Privacy-Bluetooth.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showBLEDisable() {
        let alert = UIAlertController(title: "", message: "The current system of bluetooth is not available!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - UI

    private func loadSubViews() {
        view.backgroundColor = UIColor(red: 237/255.0, green: 243/255.0, blue: 250/255.0, alpha: 1)
        rightButton.setImage(UIImage(named: "bxs_scanRightAboutIcon.png"), for: .normal)
        defaultTitle = "DEVICE(0)"

        let topView = UIView()
        topView.backgroundColor = UIColor(red: 237/255.0, green: 243/255.0, blue: 250/255.0, alpha: 1)
        view.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.height.equalTo(searchButtonHeight + 30)
        }

        refreshButton.addSubview(refreshIcon)
        topView.addSubview(refreshButton)
        refreshIcon.snp.makeConstraints { make in
            make.centerX.equalTo(refreshButton)
            make.centerY.equalTo(refreshButton)
            make.width.height.equalTo(22)
        }
        refreshButton.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.width.height.equalTo(40)
            make.top.equalTo(15)
        }
        topView.addSubview(searchButton)
        searchButton.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(refreshButton.snp.left).offset(-10)
            make.top.equalTo(15)
            make.height.equalTo(searchButtonHeight)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(topView.snp.bottom)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 5))
        }
    }
}

// MARK: - TableView

extension MKBXSScanController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        dataList.count
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (dataList[section].advertiseList.count + 1)
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = MKBXSScanDeviceInfoCell.initCellWithTableView(tableView)
            cell.dataModel = dataList[indexPath.section]
            cell.delegate = self
            return cell
        }
        let model = dataList[indexPath.section]
        let dataModel = model.advertiseList[indexPath.row - 1] as! MKSwiftBXScanBaseModel
        return MKBXSScanPageAdopter.loadCellWithTableView(tableView, dataModel: dataModel)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 { return headerViewHeight }
        let model = dataList[indexPath.section]
        let dataModel = model.advertiseList[indexPath.row - 1] as! MKSwiftBXScanBaseModel
        return MKBXSScanPageAdopter.loadCellHeightWithDataModel(dataModel)
    }
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 0 ? 0 : 5
    }
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = MKSwiftTableSectionLineHeader.dequeueHeader(with: tableView)
        let sectionData = MKSwiftTableSectionLineHeaderModel()
        sectionData.contentColor = UIColor(red: 237/255.0, green: 243/255.0, blue: 250/255.0, alpha: 1)
        header.headerModel = sectionData
        return header
    }
}

// MARK: - MKSwiftBXScanSearchButtonDelegate

extension MKBXSScanController: MKSwiftBXScanSearchButtonDelegate {
    public func mk_bx_scanSearchButtonMethod() {
        MKBXSScanFilterView.showSearchName(buttonModel.searchName,
                                           tagID: buttonModel.searchMac,
                                           rssi: buttonModel.searchRssi) { [weak self] name, tagID, rssi in
            guard let self = self else { return }
            self.buttonModel.searchRssi = rssi
            self.buttonModel.searchName = name
            self.buttonModel.searchMac = tagID
            self.searchButton.dataModel = self.buttonModel
            self.refreshButton.isSelected = false
            self.refreshButtonPressed()
        }
    }
    public func mk_bx_scanSearchButtonClearMethod() {
        buttonModel.searchRssi = -100
        buttonModel.searchMac = ""
        buttonModel.searchName = ""
        refreshButton.isSelected = false
        refreshButtonPressed()
    }
}

// MARK: - MKBXSCentralManagerScanDelegate

extension MKBXSScanController: MKBXSCentralManagerScanDelegate {
    public func mk_bxs_receiveBeacon(_ beaconList: [MKBXSBaseBeacon]) {
        for beacon in beaconList {
            updateDataWithBeacon(beacon)
        }
    }
    public func mk_bxs_stopScan() {
        if refreshButton.isSelected {
            refreshIcon.layer.removeAnimation(forKey: "mk_refreshAnimationKey")
            refreshButton.isSelected = false
        }
    }
}

// MARK: - MKBXSScanDeviceInfoCellDelegate

extension MKBXSScanController: MKBXSScanDeviceInfoCellDelegate {
    public func mk_bxs_connectPeripheral(_ dataModel: MKBXSScanInfoCellModel) {
        guard let peripheral = dataModel.peripheral else { return }
        if dataModel.otaMode {
            MKSwiftHudManager.shared.showHUD(with: "Connecting...", in: view, isPenetration: false)
            MKBXSCentralManager.shared.dfuConnect(peripheral: peripheral) { [weak self] _ in
                MKSwiftHudManager.shared.hide()
                let vc = MKBXSUpdateController()
                self?.navigationController?.pushViewController(vc, animated: true)
            } failedBlock: { [weak self] error in
                MKSwiftHudManager.shared.hide()
                self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
                self?.connectFailed()
            }
            return
        }
        connectPeripheral(peripheral)
    }
}

// MARK: - MKBXSTabBarControllerDelegate

extension MKBXSScanController: MKBXSTabBarControllerDelegate {}
