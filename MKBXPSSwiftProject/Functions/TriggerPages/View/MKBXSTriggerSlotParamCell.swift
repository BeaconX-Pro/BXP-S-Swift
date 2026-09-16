//
//  MKBXSTriggerSlotParamCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSTriggerSlotParamCellModel: NSObject {
    public var cellType: MKBXSSlotType = .null
    public var interval: String = ""
    public var needChangeAdvDurationRange: Bool = false
    public var advDurationMaxValue: Int = 0
    public var advDuration: String = ""
    public var rssi: Int = 0
    public var txPower: MKBXSTxPower = .neg20dBm
    public override init() { super.init() }
}

public protocol MKBXSTriggerSlotParamCellDelegate: AnyObject {
    func bxs_triggerSlotParam_advIntervalChanged(_ interval: String)
    func bxs_triggerSlotParam_advDurationChanged(_ duration: String)
    func bxs_triggerSlotParam_rssiChanged(_ rssi: Int)
    func bxs_triggerSlotParam_txPowerChanged(_ txPower: MKBXSTxPower)
}

public final class MKBXSTriggerSlotParamCell: MKSwiftBaseCell {

    public var dataModel: MKBXSTriggerSlotParamCellModel? {
        didSet { updateContent() }
    }
    public weak var delegate: MKBXSTriggerSlotParamCellDelegate?

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSTriggerSlotParamCell {
        let identifier = "MKBXSTriggerSlotParamCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSTriggerSlotParamCell {
            return cell
        }
        return MKBXSTriggerSlotParamCell(style: .default, reuseIdentifier: identifier)
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

    private lazy var intervalLabel: UILabel = loadLabelWithMsg("Adv interval")
    private lazy var intervalUnitLabel: UILabel = loadLabelWithMsg("x100ms")
    private lazy var advDurationLabel: UILabel = loadLabelWithMsg("Total adv duration")
    private lazy var advDurationUnitLabel: UILabel = loadLabelWithMsg("s")

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
            self?.delegate?.bxs_triggerSlotParam_advIntervalChanged(text)
        }
        return tf
    }()

    private lazy var advDurationField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .realNumberOnly)
        tf.placeholder = "0~65535"
        tf.maxLength = 5
        tf.font = MKFont.font(12)
        tf.textColor = MKColor.defaultText
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKLine.color.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_triggerSlotParam_advDurationChanged(text)
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
        delegate?.bxs_triggerSlotParam_rssiChanged(Int(value) ?? 0)
    }

    @objc private func txPowerSliderValueChanged() {
        let sliderIndex = Int(txPowerSlider.value)
        let enumValue = txPowerEnumValueFromSliderIndex(sliderIndex)
        txPowerValueLabel.text = txPowerValueText(enumValue)
        delegate?.bxs_triggerSlotParam_txPowerChanged(enumValue)
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
        intervalUnitLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(50)
            make.centerY.equalTo(intervalField)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        intervalField.snp.remakeConstraints { make in
            make.right.equalTo(intervalUnitLabel.snp.left).offset(-5)
            make.width.equalTo(60)
            make.top.equalTo(leftIcon.snp.bottom).offset(10)
            make.height.equalTo(25)
        }
        intervalLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon)
            make.right.equalTo(intervalField.snp.left).offset(-10)
            make.centerY.equalTo(intervalField)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
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

        if model.cellType == .tlm {
            txPowerLabel.snp.remakeConstraints { make in
                make.left.equalTo(15)
                make.top.equalTo(advDurationField.snp.bottom).offset(15)
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
            rssiLabel.snp.remakeConstraints { make in
                make.left.equalTo(15)
                make.top.equalTo(advDurationField.snp.bottom).offset(15)
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

        if model.needChangeAdvDurationRange {
            advDurationField.placeholder = "0 ~ \(model.advDurationMaxValue)"
            if model.advDurationMaxValue < 10 { advDurationField.maxLength = 1 }
            else if model.advDurationMaxValue < 100 { advDurationField.maxLength = 2 }
            else if model.advDurationMaxValue < 1000 { advDurationField.maxLength = 3 }
            else if model.advDurationMaxValue < 10000 { advDurationField.maxLength = 4 }
            else { advDurationField.maxLength = 5 }
        } else {
            advDurationField.placeholder = "0~65535"
            advDurationField.maxLength = 5
        }

        setupTxPowerParams()

        if model.cellType == .tlm {
            addTLMSubViews()
        } else {
            addNormalSubViews()
        }

        intervalField.text = model.interval
        advDurationField.text = model.advDuration
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
        backView.addSubview(intervalLabel)
        backView.addSubview(intervalField)
        backView.addSubview(intervalUnitLabel)
        backView.addSubview(advDurationLabel)
        backView.addSubview(advDurationField)
        backView.addSubview(advDurationUnitLabel)
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
        backView.addSubview(intervalLabel)
        backView.addSubview(intervalField)
        backView.addSubview(intervalUnitLabel)
        backView.addSubview(advDurationLabel)
        backView.addSubview(advDurationField)
        backView.addSubview(advDurationUnitLabel)
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
