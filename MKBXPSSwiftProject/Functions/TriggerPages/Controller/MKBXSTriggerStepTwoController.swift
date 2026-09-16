//
//  MKBXSTriggerStepTwoController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSTriggerStepTwoController: MKSwiftBaseViewController {

    private lazy var section0List: [MKSwiftTextButtonCellModel] = []
    private lazy var section1List: [Any] = []
    private lazy var section2List: [MKBXSTriggerSlotParamCellModel] = []
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

    private lazy var nextButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Next",
                                                    target: self,
                                                    action: #selector(nextButtonPressed))
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

    @objc private func nextButtonPressed() {
        let manager = MKBXSTriggerParamManager.shared
        guard manager.stepTwoModel.validParams() else {
            view.showCentralToast("Params Error")
            return
        }

        let stepOne = manager.stepOneModel
        if stepOne.trigger && stepOne.fetchTriggerType() == 2 && stepOne.motionEvent == 0 {
            let duration = Int(manager.stepTwoModel.advDuration) ?? 0
            let period = Int(stepOne.motionVerificationPeriod) ?? 0
            if duration > period {
                view.showCentralToast("Params Error")
                return
            }
        }
        manager.stepThreeModel.slotType = manager.stepTwoModel.slotType

        // ⬇️ 不传 slotIndex，和 OC 一致
        let vc = MKBXSTriggerStepThreeController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func goback() {
        popToViewController(withClassName: "MKBXSSlotController")
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
        let model = MKSwiftTextButtonCellModel()
        model.index = 0
        model.msg = "Frame type"
        model.dataList = ["TLM", "UID", "URL", "iBeacon", "Sensor info"]
        model.dataListIndex = MKBXSTriggerParamManager.shared.stepTwoModel.slotType.rawValue
        section0List.append(model)
    }

    private func loadSection1Datas() {
        section1List.removeAll()
        let stepTwo = MKBXSTriggerParamManager.shared.stepTwoModel
        switch stepTwo.slotType {
        case .uid:
            let model = MKBXSSlotUIDCellModel()
            model.namespaceID = stepTwo.namespaceID
            model.instanceID = stepTwo.instanceID
            section1List.append(model)
        case .url:
            let model = MKBXSSlotURLCellModel()
            model.urlType = stepTwo.urlType
            model.urlContent = stepTwo.urlContent
            section1List.append(model)
        case .beacon:
            let model = MKBXSSlotBeaconCellModel()
            model.major = stepTwo.major
            model.minor = stepTwo.minor
            model.uuid = stepTwo.uuid
            section1List.append(model)
        case .sensorInfo:
            let model = MKBXSSlotSensorInfoCellModel()
            model.deviceName = stepTwo.deviceName
            model.tagEnable = !MKBXSConnectManager.shared.tagIdAutoFill
            if MKBXSConnectManager.shared.tagIdAutoFill {
                let mac = MKBXSConnectManager.shared.macAddress
                model.tagID = mac.replacingOccurrences(of: ":", with: "")
            } else {
                model.tagID = stepTwo.tagID
            }
            section1List.append(model)
        default:
            break
        }
    }

    private func loadSection2Datas() {
        section2List.removeAll()
        let stepTwo = MKBXSTriggerParamManager.shared.stepTwoModel
        guard stepTwo.slotType != .null else { return }

        let model = MKBXSTriggerSlotParamCellModel()
        model.cellType = stepTwo.slotType
        model.interval = stepTwo.advInterval
        model.advDuration = stepTwo.advDuration

        let stepOne = MKBXSTriggerParamManager.shared.stepOneModel
        if stepOne.trigger && stepOne.fetchTriggerType() == 2 && stepOne.motionEvent == 0 {
            model.needChangeAdvDurationRange = true
            model.advDurationMaxValue = Int(stepOne.motionVerificationPeriod) ?? 0
        } else {
            model.needChangeAdvDurationRange = false
            model.advDurationMaxValue = 0
        }
        model.rssi = stepTwo.rssi
        model.txPower = stepTwo.txPower
        section2List.append(model)
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
        let header = UIView(frame: CGRect(x: 0, y: 0, width: MKScreen.width, height: 90))
        header.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        let stepLabel = UILabel(frame: CGRect(x: 15, y: 10, width: MKScreen.width - 30, height: 20))
        stepLabel.textAlignment = .left
        stepLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(
            strings: ["2", "/3", ":", "Event occurs setting"],
            fonts: [MKFont.font(15), MKFont.font(13), MKFont.font(13), MKFont.font(18)],
            colors: [MKColor.navBar, UIColor(red: 137/255.0, green: 137/255.0, blue: 137/255.0, alpha: 1), MKColor.navBar, MKColor.defaultText]
        )
        header.addSubview(stepLabel)

        let noteLabel = UILabel(frame: CGRect(x: 15, y: 40, width: MKScreen.width - 30, height: 45))
        noteLabel.textAlignment = .left
        noteLabel.textColor = UIColor(red: 204/255.0, green: 102/255.0, blue: 72/255.0, alpha: 1)
        noteLabel.font = MKFont.font(13)
        noteLabel.numberOfLines = 0
        noteLabel.text = "*In this step, you can configure the advertising parameters of trigger event occurs."
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

        nextButton.frame = CGRect(x: 2 * 30 + btnWidth, y: 20, width: btnWidth, height: 40)
        footer.addSubview(nextButton)

        return footer
    }
}

// MARK: - TableView

extension MKBXSTriggerStepTwoController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        headerList.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let stepTwo = MKBXSTriggerParamManager.shared.stepTwoModel
        switch section {
        case 0: return section0List.count
        case 1: return (stepTwo.slotType == .tlm || stepTwo.slotType == .null) ? 0 : section1List.count
        case 2: return stepTwo.slotType == .null ? 0 : section2List.count
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let stepTwo = MKBXSTriggerParamManager.shared.stepTwoModel
        if indexPath.section == 1 && indexPath.row == 0 {
            switch stepTwo.slotType {
            case .uid: return 120
            case .url: return 100
            case .beacon: return 160
            case .sensorInfo: return 120
            default: return 0
            }
        }
        if indexPath.section == 2 && indexPath.row == 0 {
            switch stepTwo.slotType {
            case .tlm: return 200
            case .uid, .url, .beacon, .sensorInfo: return 260
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
            let cell = MKSwiftTextButtonCell.initCellWithTableView(tableView)
            cell.dataModel = section0List[indexPath.row]
            cell.delegate = self
            return cell
        case 1:
            return loadSection1Cell(indexPath.row)
        default:
            return loadSection2Cell(indexPath.row)
        }
    }

    private func loadSection1Cell(_ row: Int) -> UITableViewCell {
        let stepTwo = MKBXSTriggerParamManager.shared.stepTwoModel
        switch stepTwo.slotType {
        case .uid:
            let cell = MKBXSSlotUIDCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[row] as? MKBXSSlotUIDCellModel
            cell.delegate = self
            return cell
        case .url:
            let cell = MKBXSSlotURLCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[row] as? MKBXSSlotURLCellModel
            cell.delegate = self
            return cell
        case .beacon:
            let cell = MKBXSSlotBeaconCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[row] as? MKBXSSlotBeaconCellModel
            cell.delegate = self
            return cell
        case .sensorInfo:
            let cell = MKBXSSlotSensorInfoCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[row] as? MKBXSSlotSensorInfoCellModel
            cell.delegate = self
            return cell
        default:
            return UITableViewCell(style: .default, reuseIdentifier: "MKBXSTriggerStepTwoControllerCell")
        }
    }

    private func loadSection2Cell(_ row: Int) -> UITableViewCell {
        let stepTwo = MKBXSTriggerParamManager.shared.stepTwoModel
        guard stepTwo.slotType != .null else {
            return UITableViewCell(style: .default, reuseIdentifier: "MKBXSTriggerStepTwoControllerCell")
        }
        let cell = MKBXSTriggerSlotParamCell.initCellWithTableView(tableView)
        cell.dataModel = section2List[row]
        cell.delegate = self
        return cell
    }
}

// MARK: - Cell Delegates

extension MKBXSTriggerStepTwoController: MKSwiftTextButtonCellDelegate {
    public func MKSwiftTextButtonCellSelected(index: Int, dataListIndex: Int, value: String) {
        if index == 0 {
            MKBXSTriggerParamManager.shared.stepTwoModel.slotType = MKBXSSlotType(rawValue: dataListIndex) ?? .tlm
            loadSectionDatas()
        }
    }
}

extension MKBXSTriggerStepTwoController: MKBXSSlotBeaconCellDelegate {
    public func bxs_advContent_majorChanged(_ major: String) {
        MKBXSTriggerParamManager.shared.stepTwoModel.major = major
    }
    public func bxs_advContent_minorChanged(_ minor: String) {
        MKBXSTriggerParamManager.shared.stepTwoModel.minor = minor
    }
    public func bxs_advContent_uuidChanged(_ uuid: String) {
        MKBXSTriggerParamManager.shared.stepTwoModel.uuid = uuid
    }
}

extension MKBXSTriggerStepTwoController: MKBXSSlotSensorInfoCellDelegate {
    public func bxs_advContent_tagInfo_deviceNameChanged(_ text: String) {
        MKBXSTriggerParamManager.shared.stepTwoModel.deviceName = text
    }
    public func bxs_advContent_tagInfo_tagIDChanged(_ text: String) {
        MKBXSTriggerParamManager.shared.stepTwoModel.tagID = text
    }
}

extension MKBXSTriggerStepTwoController: MKBXSSlotUIDCellDelegate {
    public func bxs_advContent_namespaceIDChanged(_ text: String) {
        MKBXSTriggerParamManager.shared.stepTwoModel.namespaceID = text
    }
    public func bxs_advContent_instanceIDChanged(_ text: String) {
        MKBXSTriggerParamManager.shared.stepTwoModel.instanceID = text
    }
}

extension MKBXSTriggerStepTwoController: MKBXSSlotURLCellDelegate {
    public func bxs_advContent_urlTypeChanged(_ urlType: Int) {
        MKBXSTriggerParamManager.shared.stepTwoModel.urlType = urlType
    }
    public func bxs_advContent_urlContentChanged(_ content: String) {
        MKBXSTriggerParamManager.shared.stepTwoModel.urlContent = content
    }
}

extension MKBXSTriggerStepTwoController: MKBXSTriggerSlotParamCellDelegate {
    public func bxs_triggerSlotParam_advIntervalChanged(_ interval: String) {
        MKBXSTriggerParamManager.shared.stepTwoModel.advInterval = interval
    }
    public func bxs_triggerSlotParam_advDurationChanged(_ duration: String) {
        MKBXSTriggerParamManager.shared.stepTwoModel.advDuration = duration
    }
    public func bxs_triggerSlotParam_rssiChanged(_ rssi: Int) {
        MKBXSTriggerParamManager.shared.stepTwoModel.rssi = rssi
    }
    public func bxs_triggerSlotParam_txPowerChanged(_ txPower: MKBXSTxPower) {
        MKBXSTriggerParamManager.shared.stepTwoModel.txPower = txPower
    }
}
