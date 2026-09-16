//
//  MKBXSSlotParamCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

// MARK: - Model

public final class MKBXSSlotParamCellModel: NSObject {
    public var cellType: MKBXSSlotType = .null
    public var interval: String = ""
    public var powerModeButtonEnabled: Bool = true
    public var powerModeIsOn: Bool = false
    public var advDuration: String = ""
    public var standbyDuration: String = ""
    public var rssi: Int = 0
    public var txPower: MKBXSTxPower = .neg20dBm

    public override init() {
        super.init()
        self.powerModeButtonEnabled = true
    }
}

public protocol MKBXSSlotParamCellDelegate: AnyObject {
    func bxs_slotParam_advIntervalChanged(_ interval: String)
    func bxs_slotParam_advDurationChanged(_ duration: String)
    func bxs_slotParam_standbyDurationChanged(_ duration: String)
    func bxs_slotParam_rssiChanged(_ rssi: Int)
    func bxs_slotParam_txPowerChanged(_ txPower: MKBXSTxPower)
    func bxs_slotParam_lowerPowerDetailPressed()
    func bxs_slotParam_lowerPowerModeChanged(_ isOn: Bool)
}

public final class MKBXSSlotParamCell: MKSwiftBaseCell {

    public var dataModel: MKBXSSlotParamCellModel? {
        didSet { updateContent() }
    }
    public weak var delegate: MKBXSSlotParamCellDelegate?

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSSlotParamCell {
        let identifier = "MKBXSSlotParamCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSSlotParamCell {
            return cell
        }
        return MKBXSSlotParamCell(style: .default, reuseIdentifier: identifier)
    }

    // MARK: - UI Components

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var leftIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_slot_baseParams.png")
        return iv
    }()

    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Parameters"
        return label
    }()

    private lazy var modeLabel: UILabel = loadLabelWithMsg("Low-power mode")

    private lazy var modeButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "bxs_detailIcon.png"), for: .normal)
        btn.addTarget(self, action: #selector(modeButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var powerButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "bxs_switchSelectedIcon.png"), for: .normal)
        btn.addTarget(self, action: #selector(powerButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var intervalLabel: UILabel = loadLabelWithMsg("Adv interval")
    private lazy var intervalUnitLabel: UILabel = loadLabelWithMsg("x100ms")
    private lazy var advDurationLabel: UILabel = loadLabelWithMsg("Adv duration")
    private lazy var advDurationUnitLabel: UILabel = loadLabelWithMsg("s")
    private lazy var standbyDurationLabel: UILabel = loadLabelWithMsg("Standby duration")
    private lazy var standbyDurationUnitLabel: UILabel = loadLabelWithMsg("s")

    private lazy var intervalField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .realNumberOnly)
        tf.placeholder = "1~100"
        tf.maxLength = 3
        tf.font = MKFont.font(12)
        tf.textColor = MKColor.defaultText
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKLine.color.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_slotParam_advIntervalChanged(text)
        }
        return tf
    }()

    private lazy var advDurationField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .realNumberOnly)
        tf.placeholder = "1~65535"
        tf.maxLength = 5
        tf.font = MKFont.font(12)
        tf.textColor = MKColor.defaultText
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKLine.color.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_slotParam_advDurationChanged(text)
        }
        return tf
    }()

    private lazy var standbyDurationField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .realNumberOnly)
        tf.placeholder = "1~65535"
        tf.maxLength = 5
        tf.font = MKFont.font(12)
        tf.textColor = MKColor.defaultText
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKLine.color.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_slotParam_standbyDurationChanged(text)
        }
        return tf
    }()

    private lazy var rssiLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        return label
    }()

    private lazy var rssiSlider: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 0
        slider.minimumValue = -100
        slider.addTarget(self, action: #selector(rssiSliderValueChanged), for: .valueChanged)
        return slider
    }()

    private lazy var rssiValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(11)
        return label
    }()

    private lazy var txPowerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        return label
    }()

    private lazy var txPowerSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.value = 0
        slider.addTarget(self, action: #selector(txPowerSliderValueChanged), for: .valueChanged)
        return slider
    }()

    private lazy var txPowerValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(11)
        return label
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Events

    @objc private func rssiSliderValueChanged() {
        var value = String(format: "%.f", rssiSlider.value)
        if value == "-0" { value = "0" }
        rssiValueLabel.text = "\(value)dBm"
        delegate?.bxs_slotParam_rssiChanged(Int(value) ?? 0)
    }

    @objc private func txPowerSliderValueChanged() {
        let sliderIndex = Int(txPowerSlider.value)
        let enumValue = txPowerEnumValueFromSliderIndex(sliderIndex)
        txPowerValueLabel.text = txPowerValueText(enumValue)
        delegate?.bxs_slotParam_txPowerChanged(enumValue)
    }

    @objc private func modeButtonPressed() {
        delegate?.bxs_slotParam_lowerPowerDetailPressed()
    }

    @objc private func powerButtonPressed() {
        powerButton.isSelected.toggle()
        let iconName = powerButton.isSelected ? "bxs_switchSelectedIcon.png" : "bxs_switchUnselectedIcon.png"
        powerButton.setImage(UIImage(named: iconName), for: .normal)
        delegate?.bxs_slotParam_lowerPowerModeChanged(powerButton.isSelected)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        setupConstraints()
    }

    private func setupConstraints() {
        guard let model = dataModel else { return }
        guard model.cellType != .null else { return }

        backView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        leftIcon.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.height.equalTo(22)
            make.top.equalTo(10)
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(15)
            make.right.equalTo(-15)
            make.centerY.equalTo(leftIcon)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        powerButton.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(40)
            make.top.equalTo(leftIcon.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        modeLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon)
            make.width.equalTo(110)
            make.centerY.equalTo(powerButton)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        modeButton.snp.remakeConstraints { make in
            make.left.equalTo(modeLabel.snp.right).offset(5)
            make.width.height.equalTo(25)
            make.centerY.equalTo(powerButton)
        }
        intervalUnitLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(50)
            make.centerY.equalTo(intervalField)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        intervalField.snp.remakeConstraints { make in
            make.right.equalTo(intervalUnitLabel.snp.left).offset(-5)
            make.width.equalTo(60)
            make.top.equalTo(powerButton.snp.bottom).offset(10)
            make.height.equalTo(25)
        }
        intervalLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon)
            make.right.equalTo(intervalField.snp.left).offset(-10)
            make.centerY.equalTo(intervalField)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }

        if model.powerModeIsOn {
            advDurationUnitLabel.snp.remakeConstraints { make in
                make.right.equalTo(-15)
                make.width.equalTo(50)
                make.centerY.equalTo(advDurationField)
                make.height.equalTo(MKFont.font(12).lineHeight)
            }
            advDurationField.snp.remakeConstraints { make in
                make.right.equalTo(advDurationUnitLabel.snp.left).offset(-5)
                make.width.equalTo(60)
                make.top.equalTo(intervalField.snp.bottom).offset(10)
                make.height.equalTo(25)
            }
            advDurationLabel.snp.remakeConstraints { make in
                make.left.equalTo(leftIcon)
                make.right.equalTo(advDurationField.snp.left).offset(-10)
                make.centerY.equalTo(advDurationField)
                make.height.equalTo(MKFont.font(12).lineHeight)
            }
            standbyDurationUnitLabel.snp.remakeConstraints { make in
                make.right.equalTo(-15)
                make.width.equalTo(50)
                make.centerY.equalTo(standbyDurationField)
                make.height.equalTo(MKFont.font(12).lineHeight)
            }
            standbyDurationField.snp.remakeConstraints { make in
                make.right.equalTo(standbyDurationUnitLabel.snp.left).offset(-5)
                make.width.equalTo(60)
                make.top.equalTo(advDurationField.snp.bottom).offset(10)
                make.height.equalTo(25)
            }
            standbyDurationLabel.snp.remakeConstraints { make in
                make.left.equalTo(leftIcon)
                make.right.equalTo(standbyDurationField.snp.left).offset(-10)
                make.centerY.equalTo(standbyDurationField)
                make.height.equalTo(MKFont.font(12).lineHeight)
            }
        }

        if model.cellType == .tlm {
            let topAnchor = model.powerModeIsOn ? standbyDurationField.snp.bottom : intervalField.snp.bottom
            txPowerLabel.snp.remakeConstraints { make in
                make.left.equalTo(15)
                make.top.equalTo(topAnchor).offset(15)
                make.right.equalTo(-15)
                make.height.equalTo(MKFont.font(15).lineHeight)
            }
            txPowerSlider.snp.remakeConstraints { make in
                make.left.equalTo(15)
                make.right.equalTo(txPowerValueLabel.snp.left).offset(-5)
                make.top.equalTo(txPowerLabel.snp.bottom).offset(5)
                make.height.equalTo(10)
            }
            txPowerValueLabel.snp.remakeConstraints { make in
                make.right.equalTo(-15)
                make.width.equalTo(60)
                make.centerY.equalTo(txPowerSlider)
                make.height.equalTo(MKFont.font(12).lineHeight)
            }
        } else {
            let topAnchor = model.powerModeIsOn ? standbyDurationField.snp.bottom : intervalField.snp.bottom
            rssiLabel.snp.remakeConstraints { make in
                make.left.equalTo(15)
                make.top.equalTo(topAnchor).offset(15)
                make.right.equalTo(-15)
                make.height.equalTo(MKFont.font(15).lineHeight)
            }
            rssiSlider.snp.remakeConstraints { make in
                make.left.equalTo(15)
                make.right.equalTo(rssiValueLabel.snp.left).offset(-5)
                make.top.equalTo(rssiLabel.snp.bottom).offset(5)
                make.height.equalTo(10)
            }
            rssiValueLabel.snp.remakeConstraints { make in
                make.right.equalTo(-15)
                make.width.equalTo(60)
                make.centerY.equalTo(rssiSlider)
                make.height.equalTo(MKFont.font(12).lineHeight)
            }
            txPowerLabel.snp.remakeConstraints { make in
                make.left.equalTo(15)
                make.top.equalTo(rssiSlider.snp.bottom).offset(15)
                make.right.equalTo(-15)
                make.height.equalTo(MKFont.font(15).lineHeight)
            }
            txPowerSlider.snp.remakeConstraints { make in
                make.left.equalTo(15)
                make.right.equalTo(txPowerValueLabel.snp.left).offset(-5)
                make.top.equalTo(txPowerLabel.snp.bottom).offset(5)
                make.height.equalTo(10)
            }
            txPowerValueLabel.snp.remakeConstraints { make in
                make.right.equalTo(-15)
                make.width.equalTo(60)
                make.centerY.equalTo(txPowerSlider)
                make.height.equalTo(MKFont.font(12).lineHeight)
            }
        }
    }

    // MARK: - Update

    private func updateContent() {
        guard let model = dataModel else { return }

        backView.subviews.forEach { $0.removeFromSuperview() }
        backView.removeFromSuperview()

        guard model.cellType != .null else { return }
        contentView.addSubview(backView)

        powerButton.isEnabled = model.powerModeButtonEnabled
        powerButton.isSelected = model.powerModeIsOn
        let iconName = powerButton.isSelected ? "bxs_switchSelectedIcon.png" : "bxs_switchUnselectedIcon.png"
        powerButton.setImage(UIImage(named: iconName), for: .normal)

        setupTxPowerParams()

        if model.cellType == .tlm {
            addTLMSubViews()
        } else {
            addNormalSubViews()
        }

        intervalField.text = model.interval
        advDurationField.text = model.advDuration
        standbyDurationField.text = model.standbyDuration
        txPowerSlider.value = Float(txPowerSliderIndexFromEnumValue(model.txPower))
        txPowerValueLabel.text = txPowerValueText(model.txPower)

        if model.cellType != .tlm {
            rssiSlider.value = Float(model.rssi)
            var value = String(format: "%.f", rssiSlider.value)
            if value == "-0" { value = "0" }
            rssiValueLabel.text = "\(value)dBm"
            updateRssiMsg()
        }

        setNeedsLayout()
    }

    private func addNormalSubViews() {
        backView.addSubview(leftIcon)
        backView.addSubview(msgLabel)
        backView.addSubview(modeLabel)
        backView.addSubview(modeButton)
        backView.addSubview(powerButton)
        backView.addSubview(intervalLabel)
        backView.addSubview(intervalField)
        backView.addSubview(intervalUnitLabel)

        if dataModel?.powerModeIsOn == true {
            backView.addSubview(advDurationLabel)
            backView.addSubview(advDurationField)
            backView.addSubview(advDurationUnitLabel)
            backView.addSubview(standbyDurationLabel)
            backView.addSubview(standbyDurationField)
            backView.addSubview(standbyDurationUnitLabel)
        }

        backView.addSubview(rssiLabel)
        backView.addSubview(rssiSlider)
        backView.addSubview(rssiValueLabel)
        backView.addSubview(txPowerLabel)
        backView.addSubview(txPowerSlider)
        backView.addSubview(txPowerValueLabel)
    }

    private func addTLMSubViews() {
        backView.addSubview(leftIcon)
        backView.addSubview(msgLabel)
        backView.addSubview(modeLabel)
        backView.addSubview(modeButton)
        backView.addSubview(powerButton)
        backView.addSubview(intervalLabel)
        backView.addSubview(intervalField)
        backView.addSubview(intervalUnitLabel)

        if dataModel?.powerModeIsOn == true {
            backView.addSubview(advDurationLabel)
            backView.addSubview(advDurationField)
            backView.addSubview(advDurationUnitLabel)
            backView.addSubview(standbyDurationLabel)
            backView.addSubview(standbyDurationField)
            backView.addSubview(standbyDurationUnitLabel)
        }

        backView.addSubview(txPowerLabel)
        backView.addSubview(txPowerSlider)
        backView.addSubview(txPowerValueLabel)
    }

    // MARK: - TxPower 映射

    private var txPowerEnumList: [MKBXSTxPower] {
        let deviceType = MKBXSConnectManager.shared.deviceType
        if deviceType == .atmosic {
            return [.neg20dBm, .neg10dBm, .neg6dBm, .neg4dBm, .neg2dBm, .dBm0, .dBm2, .dBm4]
        }
        if deviceType == .nordic {
            return [.neg20dBm, .neg16dBm, .neg12dBm, .neg8dBm, .neg4dBm, .dBm0, .dBm3, .dBm4, .dBm6, .dBm8]
        }
        return [.neg20dBm, .neg16dBm, .neg12dBm, .neg8dBm, .neg4dBm, .dBm0, .dBm3, .dBm4, .dBm6]
    }

    private func txPowerEnumValueFromSliderIndex(_ index: Int) -> MKBXSTxPower {
        let list = txPowerEnumList
        guard index >= 0, index < list.count else { return .neg20dBm }
        return list[index]
    }

    private func txPowerSliderIndexFromEnumValue(_ value: MKBXSTxPower) -> Int {
        let list = txPowerEnumList
        return list.firstIndex(of: value) ?? 0
    }

    private func setupTxPowerParams() {
        let list = txPowerEnumList
        let max = list.count - 1
        let deviceType = MKBXSConnectManager.shared.deviceType
        let rangeText: String
        if deviceType == .atmosic {
            rangeText = "   (-20,-10,-6,-4,-2,0,+2,+4)"
        } else if deviceType == .nordic {
            rangeText = "   (-20,-16,-12,-8,-4,0,+3,+4,+6,+8)"
        } else {
            rangeText = "   (-20,-16,-12,-8,-4,0,+3,+4,+6)"
        }
        txPowerLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(
            strings: ["Tx power", rangeText],
            fonts: [MKFont.font(13), MKFont.font(12)],
            colors: [MKColor.defaultText, UIColor(red: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha: 1)]
        )
        txPowerSlider.maximumValue = Float(max)
        txPowerSlider.minimumValue = 0
    }

    private func txPowerValueText(_ value: MKBXSTxPower) -> String {
        value.displayName
    }

    // MARK: - RSSI

    private func updateRssiMsg() {
        guard let model = dataModel else { return }
        if model.cellType == .null || model.cellType == .tlm { return }
        let rangeText = "   (-100dBm ~ 0dBm)"
        switch model.cellType {
        case .uid, .url:
            rssiLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(
                strings: ["RSSI@0m", rangeText],
                fonts: [MKFont.font(13), MKFont.font(12)],
                colors: [MKColor.defaultText, UIColor(red: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha: 1)]
            )
        case .beacon:
            rssiLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(
                strings: ["RSSI@1m", rangeText],
                fonts: [MKFont.font(13), MKFont.font(12)],
                colors: [MKColor.defaultText, UIColor(red: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha: 1)]
            )
        case .sensorInfo:
            rssiLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(
                strings: ["Ranging data", rangeText],
                fonts: [MKFont.font(13), MKFont.font(12)],
                colors: [MKColor.defaultText, UIColor(red: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha: 1)]
            )
        default: break
        }
    }

    // MARK: - Helpers

    private func loadLabelWithMsg(_ msg: String) -> UILabel {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(12)
        label.text = msg
        return label
    }
}
