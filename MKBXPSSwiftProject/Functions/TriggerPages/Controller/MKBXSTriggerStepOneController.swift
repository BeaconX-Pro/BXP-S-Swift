//
//  MKBXSTriggerStepOneController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSTriggerStepOneController: MKSwiftBaseViewController {

    public var slotIndex: Int = 0

    // MARK: - Data

    private lazy var section0List: [MKSwiftTextSwitchCellModel] = []
    private lazy var section1List: [MKSwiftTextButtonCellModel] = []
    private lazy var section2List: [MKSwiftTextButtonCellModel] = []
    private lazy var section3List: [MKSwiftNormalSliderCellModel] = []
    private lazy var section4List: [MKSwiftNormalSliderCellModel] = []
    private lazy var section5List: [MKSwiftTextFieldCellModel] = []
    private lazy var section6List: [MKSwiftTextSwitchCellModel] = []
    private lazy var section7List: [MKSwiftTextFieldCellModel] = []
    private lazy var headerList: [MKSwiftTableSectionLineHeaderModel] = []

    // MARK: - UI

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

    deinit {
        MKBXSTriggerParamManager.sharedDealloc()
    }

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
        MKBXSTriggerParamManager.shared.slotIndex = slotIndex
        readDataFromDevice()
    }

    // MARK: - Read

    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        MKBXSTriggerParamManager.shared.read(sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.loadSectionDatas()
            let nextTitle = MKBXSTriggerParamManager.shared.stepOneModel.trigger ? "Next" : "Done"
            self.nextButton.setTitle(nextTitle, for: .normal)
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - Events

    @objc private func nextButtonPressed() {
        let stepOne = MKBXSTriggerParamManager.shared.stepOneModel

        if nextButton.title(for: .normal) == "Done" {
            MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
            MKBXSTriggerParamManager.shared.config(sucBlock: { [weak self] in
                MKSwiftHudManager.shared.hide()
                self?.view.showCentralToast("Success")
                self?.perform(#selector(self?.goback), with: nil, afterDelay: 0.5)
            }, failedBlock: { [weak self] error in
                MKSwiftHudManager.shared.hide()
                self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
            })
            return
        }

        if stepOne.fetchTriggerType() == 2 {
            let period = Int(stepOne.motionVerificationPeriod) ?? 0
            if stepOne.motionEvent < 0 || stepOne.motionEvent > 1 || period < 1 || period > 65535 {
                view.showCentralToast("Params Error")
                return
            }
        }

        // ⬇️ 不传 slotIndex，和 OC 一致
        let vc = MKBXSTriggerStepTwoController()
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
        loadSection3Datas()
        loadSection4Datas()
        loadSection5Datas()
        loadSection6Datas()
        loadSection7Datas()

        headerList.removeAll()
        for _ in 0..<8 {
            headerList.append(MKSwiftTableSectionLineHeaderModel())
        }
        tableView.reloadData()
    }

    private func loadSection0Datas() {
        section0List.removeAll()
        let model = MKSwiftTextSwitchCellModel()
        model.index = 0
        model.msg = "Trigger"
        model.isOn = MKBXSTriggerParamManager.shared.stepOneModel.trigger
        section0List.append(model)
    }

    private func loadSection1Datas() {
        section1List.removeAll()
        let model = MKSwiftTextButtonCellModel()
        model.index = 0
        model.msg = "Trigger type"
        model.dataList = MKBXSTriggerParamManager.shared.stepOneModel.fetchTriggerTypeList()
        model.dataListIndex = MKBXSTriggerParamManager.shared.stepOneModel.triggerIndex
        model.buttonLabelFont = MKFont.font(12)
        section1List.append(model)
    }

    private func loadSection2Datas() {
        section2List.removeAll()
        let model = MKSwiftTextButtonCellModel()
        model.index = 1
        model.msg = "Trigger event"
        model.dataList = loadTriggerEventList()
        model.dataListIndex = loadTriggerEventIndex()
        model.buttonLabelFont = MKFont.font(12)
        section2List.append(model)
    }

    private func loadSection3Datas() {
        section3List.removeAll()
        let model = MKSwiftNormalSliderCellModel()
        model.index = 0
        model.msg = MKSwiftUIAdaptor.createAttributedString(
            strings: ["Temperature threshold", "   (-40℃~150℃)"],
            fonts: [MKFont.font(13), MKFont.font(12)],
            colors: [MKColor.defaultText, UIColor(red: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha: 1)]
        )
        model.sliderMinValue = -40
        model.sliderMaxValue = 150
        model.unit = "℃"
        model.sliderValue = MKBXSTriggerParamManager.shared.stepOneModel.temperature
        section3List.append(model)
    }

    private func loadSection4Datas() {
        section4List.removeAll()
        let model = MKSwiftNormalSliderCellModel()
        model.index = 1
        model.msg = MKSwiftUIAdaptor.createAttributedString(
            strings: ["Humidity threshold", "   (0%~95%)"],
            fonts: [MKFont.font(13), MKFont.font(12)],
            colors: [MKColor.defaultText, UIColor(red: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha: 1)]
        )
        model.sliderMinValue = 0
        model.sliderMaxValue = 95
        model.unit = "%"
        model.sliderValue = MKBXSTriggerParamManager.shared.stepOneModel.humidity
        section4List.append(model)
    }

    private func loadSection5Datas() {
        section5List.removeAll()
        let model = MKSwiftTextFieldCellModel()
        model.index = 0
        model.msg = "Static verify period"
        model.textFieldType = .realNumberOnly
        model.textPlaceholder = "1~65535"
        model.unit = "s"
        model.maxLength = 5
        model.textFieldValue = MKBXSTriggerParamManager.shared.stepOneModel.motionVerificationPeriod
        model.noteMsg = "*Static verify period: the parameter that determines when a stationary event occurs on the device."
        model.noteMsgColor = UIColor(red: 201/255.0, green: 90/255.0, blue: 49/255.0, alpha: 1)
        section5List.append(model)
    }

    private func loadSection6Datas() {
        section6List.removeAll()
        let model = MKSwiftTextSwitchCellModel()
        model.index = 1
        model.msg = "Locked ADV function"
        model.isOn = MKBXSTriggerParamManager.shared.stepOneModel.lockedAdvIsOn
        if MKBXSTriggerParamManager.shared.stepOneModel.lockedAdvIsOn {
            model.noteMsg = "*Lock Event Occurs ADV Duration: If the device quickly returns to a state where the triggering condition is no longer met after initially satisfying the triggering condition, it can only broadcast for a short duration, or might not broadcast at all. The Locked ADV function ensures that, in such cases, the set post-trigger broadcast duration is fully executed, regardless of changes in the triggering condition.\n\n Note: If the Event Occurs Total adv duration is set to 0, the Lock post-trigger adv duration will default to a locked broadcast of 5 seconds."
        }
        model.noteMsgColor = UIColor(red: 201/255.0, green: 90/255.0, blue: 49/255.0, alpha: 1)
        section6List.append(model)
    }

    private func loadSection7Datas() {
        section7List.removeAll()
        let model = MKSwiftTextFieldCellModel()
        model.index = 1
        model.msg = "Locked ADV duration"
        model.textFieldType = .realNumberOnly
        model.textPlaceholder = "1~65535"
        model.unit = "s"
        model.maxLength = 5
        model.noteMsg = "*Lock ADV duration: If the device quickly returns to a state that does not meet the trigger conditions after initially satisfying them, it may only broadcast for a short period. The lock broadcast duration feature ensures that, in such cases, the device broadcasts for the set lock broadcast duration. This feature's parameter must be set to a value less than the post-trigger broadcast duration."
        model.noteMsgColor = UIColor(red: 201/255.0, green: 90/255.0, blue: 49/255.0, alpha: 1)
        section7List.append(model)
    }

    private func loadTriggerEventList() -> [String] {
        switch MKBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() {
        case 0: return ["Temperature above", "Temperature below"]
        case 1: return ["Humidity above", "Humidiby below"]
        case 2: return ["Device start moving", "Device keep static"]
        case 3: return ["Door open", "Door close"]
        default: return []
        }
    }

    private func loadTriggerEventIndex() -> Int {
        switch MKBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() {
        case 0: return MKBXSTriggerParamManager.shared.stepOneModel.tempEvent
        case 1: return MKBXSTriggerParamManager.shared.stepOneModel.humidityEvent
        case 2: return MKBXSTriggerParamManager.shared.stepOneModel.motionEvent
        case 3: return MKBXSTriggerParamManager.shared.stepOneModel.hallEvent
        default: return 0
        }
    }

    // MARK: - UI

    private func loadSubViews() {
        // 用传入的 slotIndex（和 OC 一致，StepOne 用 self.slotIndex）
        defaultTitle = "SLOT\(slotIndex + 1)"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }

    private func tableHeaderView() -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: MKScreen.width, height: 110))
        headerView.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)

        let stepLabel = UILabel(frame: CGRect(x: 15, y: 10, width: MKScreen.width - 30, height: 20))
        stepLabel.textAlignment = .left
        stepLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(
            strings: ["1", "/3", ":", "Initail Setting"],
            fonts: [MKFont.font(15), MKFont.font(13), MKFont.font(13), MKFont.font(18)],
            colors: [MKColor.navBar, UIColor(red: 137/255.0, green: 137/255.0, blue: 137/255.0, alpha: 1), MKColor.navBar, MKColor.defaultText]
        )
        headerView.addSubview(stepLabel)

        let noteLabel = UILabel(frame: CGRect(x: 15, y: 40, width: MKScreen.width - 30, height: 65))
        noteLabel.textAlignment = .left
        noteLabel.textColor = UIColor(red: 204/255.0, green: 102/255.0, blue: 72/255.0, alpha: 1)
        noteLabel.font = MKFont.font(13)
        noteLabel.numberOfLines = 0
        noteLabel.text = "*In this step1, you can enable or diable the trigger feature , You can also configure the trigger type and define the event criteria that meet the trigger conditions (Trigger event)."
        headerView.addSubview(noteLabel)

        return headerView
    }

    private func tableFooterView() -> UIView {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: MKScreen.width, height: 80))
        footer.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        nextButton.frame = CGRect(x: 30, y: 20, width: MKScreen.width - 60, height: 40)
        footer.addSubview(nextButton)
        return footer
    }
}

// MARK: - TableView

extension MKBXSTriggerStepOneController: UITableViewDelegate, UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        headerList.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let stepOne = MKBXSTriggerParamManager.shared.stepOneModel
        switch section {
        case 0: return section0List.count
        case 1: return stepOne.trigger ? section1List.count : 0
        case 2: return stepOne.trigger ? section2List.count : 0
        case 3: return stepOne.trigger && stepOne.fetchTriggerType() == 0 ? section3List.count : 0
        case 4: return stepOne.trigger && stepOne.fetchTriggerType() == 1 ? section4List.count : 0
        case 5: return stepOne.trigger && stepOne.fetchTriggerType() == 2 ? section5List.count : 0
        case 6: return stepOne.trigger && stepOne.fetchTriggerType() != 2 ? section6List.count : 0
        case 7: return 0
        default: return 0
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 3: return section3List[indexPath.row].cellHeightWithContentWidth(MKScreen.width)
        case 4: return section4List[indexPath.row].cellHeightWithContentWidth(MKScreen.width)
        case 5: return section5List[indexPath.row].cellHeightWithContentWidth(MKScreen.width)
        case 6: return section6List[indexPath.row].cellHeightWithContentWidth(MKScreen.width)
        case 7: return section7List[indexPath.row].cellHeightWithContentWidth(MKScreen.width)
        default: return 44
        }
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 7 ? 0 : 10
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
            let cell = MKSwiftTextButtonCell.initCellWithTableView(tableView)
            cell.dataModel = section1List[indexPath.row]
            cell.delegate = self
            return cell
        case 2:
            let cell = MKSwiftTextButtonCell.initCellWithTableView(tableView)
            cell.dataModel = section2List[indexPath.row]
            cell.delegate = self
            return cell
        case 3:
            let cell = MKSwiftNormalSliderCell.initCellWithTableView(tableView)
            cell.dataModel = section3List[indexPath.row]
            cell.delegate = self
            return cell
        case 4:
            let cell = MKSwiftNormalSliderCell.initCellWithTableView(tableView)
            cell.dataModel = section4List[indexPath.row]
            cell.delegate = self
            return cell
        case 5:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section5List[indexPath.row]
            cell.delegate = self
            return cell
        case 6:
            let cell = MKSwiftTextSwitchCell.initCellWithTableView(tableView)
            cell.dataModel = section6List[indexPath.row]
            cell.delegate = self
            return cell
        default:
            let cell = MKSwiftTextFieldCell.initCellWithTableView(tableView)
            cell.dataModel = section7List[indexPath.row]
            cell.delegate = self
            return cell
        }
    }
}

// MARK: - Cell Delegates

extension MKBXSTriggerStepOneController: MKSwiftTextSwitchCellDelegate {
    public func MKSwiftTextSwitchCellStatusChanged(isOn: Bool, index: Int) {
        if index == 0 {
            MKBXSTriggerParamManager.shared.stepOneModel.trigger = isOn
            section0List[0].isOn = isOn
            let nextTitle = isOn ? "Next" : "Done"
            nextButton.setTitle(nextTitle, for: .normal)
            tableView.reloadData()
        } else if index == 1 {
            MKBXSTriggerParamManager.shared.stepOneModel.lockedAdvIsOn = isOn
            section6List[0].isOn = isOn
            if isOn {
                section6List[0].noteMsg = "*Lock Event Occurs ADV Duration: If the device quickly returns to a state where the triggering condition is no longer met after initially satisfying the triggering condition, it can only broadcast for a short duration, or might not broadcast at all. The Locked ADV function ensures that, in such cases, the set post-trigger broadcast duration is fully executed, regardless of changes in the triggering condition.\n\n Note: If the Event Occurs Total adv duration is set to 0, the Lock post-trigger adv duration will default to a locked broadcast of 5 seconds."
            } else {
                section6List[0].noteMsg = ""
            }
            tableView.reloadSections(IndexSet(integer: 6), with: .none)
        }
    }
}

extension MKBXSTriggerStepOneController: MKSwiftTextButtonCellDelegate {
    public func MKSwiftTextButtonCellSelected(index: Int, dataListIndex: Int, value: String) {
        if index == 0 {
            MKBXSTriggerParamManager.shared.stepOneModel.triggerIndex = dataListIndex
            section1List[0].dataListIndex = dataListIndex
            section2List[0].dataList = loadTriggerEventList()
            section2List[0].dataListIndex = 0
            tableView.reloadData()
        } else if index == 1 {
            section2List[0].dataListIndex = dataListIndex
            switch MKBXSTriggerParamManager.shared.stepOneModel.fetchTriggerType() {
            case 0: MKBXSTriggerParamManager.shared.stepOneModel.tempEvent = dataListIndex
            case 1: MKBXSTriggerParamManager.shared.stepOneModel.humidityEvent = dataListIndex
            case 2: MKBXSTriggerParamManager.shared.stepOneModel.motionEvent = dataListIndex
            case 3: MKBXSTriggerParamManager.shared.stepOneModel.hallEvent = dataListIndex
            default: break
            }
        }
    }
}

extension MKBXSTriggerStepOneController: MKSwiftNormalSliderCellDelegate {
    public func mk_normalSliderValueChanged(_ value: Int, index: Int) {
        if index == 0 {
            MKBXSTriggerParamManager.shared.stepOneModel.temperature = value
            section3List[0].sliderValue = value
        } else if index == 1 {
            MKBXSTriggerParamManager.shared.stepOneModel.humidity = value
            section4List[0].sliderValue = value
        }
    }
}

extension MKBXSTriggerStepOneController: MKSwiftTextFieldCellDelegate {
    public func mkDeviceTextCellValueChanged(_ index: Int, textValue: String) {
        if index == 0 {
            MKBXSTriggerParamManager.shared.stepOneModel.motionVerificationPeriod = textValue
            section5List[0].textFieldValue = textValue
        }
    }
}
