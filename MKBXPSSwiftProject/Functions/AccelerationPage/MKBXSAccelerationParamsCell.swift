//
//  MKBXSAccelerationParamsCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSAccelerationParamsCellModel: NSObject {
    public var samplingRate: Int = 0
    public var scale: Int = 0
    public var threshold: String = ""
    public override init() { super.init() }
}

public protocol MKBXSAccelerationParamsCellDelegate: AnyObject {
    func bxs_accelerationParamsScaleChanged(_ scale: Int)
    func bxs_accelerationParamsSamplingRateChanged(_ samplingRate: Int)
    func bxs_accelerationMotionThresholdChanged(_ threshold: String)
}

public final class MKBXSAccelerationParamsCell: MKSwiftBaseCell {

    public weak var delegate: MKBXSAccelerationParamsCellDelegate?
    public var dataModel: MKBXSAccelerationParamsCellModel? {
        didSet { updateContent() }
    }

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSAccelerationParamsCell {
        let identifier = "MKBXSAccelerationParamsCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSAccelerationParamsCell {
            return cell
        }
        return MKBXSAccelerationParamsCell(style: .default, reuseIdentifier: identifier)
    }

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Sensor parameters"
        return label
    }()

    private lazy var scaleLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "Full-scale"
        return label
    }()

    private lazy var scaleButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = MKFont.font(12)
        btn.setTitleColor(MKColor.defaultText, for: .normal)
        btn.addTarget(self, action: #selector(scaleButtonPressed), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.borderColor = MKColor.navBar.cgColor
        btn.layer.borderWidth = 0.5
        btn.layer.cornerRadius = 6
        return btn
    }()

    private lazy var sampleRateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(13)
        label.text = "Sampling rate"
        return label
    }()

    private lazy var sampleRateButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = MKFont.font(12)
        btn.setTitleColor(MKColor.defaultText, for: .normal)
        btn.addTarget(self, action: #selector(sampleRateButtonPressed), for: .touchUpInside)
        btn.layer.masksToBounds = true
        btn.layer.borderColor = MKColor.navBar.cgColor
        btn.layer.borderWidth = 0.5
        btn.layer.cornerRadius = 6
        return btn
    }()

    private lazy var thresholdLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(13)
        label.text = "Motion threshold"
        return label
    }()

    private lazy var textField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .realNumberOnly)
        tf.layer.borderColor = MKColor.navBar.cgColor
        tf.layer.borderWidth = 0.5
        tf.layer.cornerRadius = 6
        tf.layer.masksToBounds = true
        tf.maxLength = 3
        tf.placeholder = "1~255"
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_accelerationMotionThresholdChanged(text)
        }
        return tf
    }()

    private lazy var thresholdUnitLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(12)
        label.textAlignment = .left
        label.text = "x3.91mg"
        return label
    }()

    private let scaleList = ["±2g", "±4g", "±8g", "±16g"]
    private let sampleRateList = ["1hz", "10hz", "25hz", "50hz", "100hz"]
    private var currentScale: Int = 0

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(backView)
        backView.addSubview(msgLabel)
        backView.addSubview(scaleLabel)
        backView.addSubview(scaleButton)
        backView.addSubview(sampleRateLabel)
        backView.addSubview(sampleRateButton)
        backView.addSubview(thresholdLabel)
        backView.addSubview(textField)
        backView.addSubview(thresholdUnitLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        backView.snp.remakeConstraints { make in
            make.edges.equalTo(contentView)
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(-15)
            make.top.equalTo(5)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        scaleLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(120)
            make.centerY.equalTo(scaleButton)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        scaleButton.snp.remakeConstraints { make in
            make.right.equalTo(textField)
            make.width.equalTo(50)
            make.top.equalTo(msgLabel.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        sampleRateLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(120)
            make.centerY.equalTo(sampleRateButton)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        sampleRateButton.snp.remakeConstraints { make in
            make.right.equalTo(textField)
            make.width.equalTo(50)
            make.top.equalTo(scaleButton.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        thresholdLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(120)
            make.centerY.equalTo(textField)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        textField.snp.remakeConstraints { make in
            make.right.equalTo(thresholdUnitLabel.snp.left).offset(-5)
            make.width.equalTo(50)
            make.top.equalTo(sampleRateButton.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        thresholdUnitLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(70)
            make.centerY.equalTo(textField)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }

    @objc private func scaleButtonPressed() {
        let current = scaleButton.title(for: .normal) ?? ""
        let index = scaleList.firstIndex(of: current) ?? 0
        let picker = MKSwiftPickerView()
        picker.showPickView(with: scaleList, selectedRow: index) { [weak self] row in
            guard let self = self else { return }
            self.currentScale = row
            self.scaleButton.setTitle(self.scaleList[row], for: .normal)
            self.updateThresholdUnit()
            self.delegate?.bxs_accelerationParamsScaleChanged(row)
        }
    }

    @objc private func sampleRateButtonPressed() {
        let current = sampleRateButton.title(for: .normal) ?? ""
        let index = sampleRateList.firstIndex(of: current) ?? 0
        let picker = MKSwiftPickerView()
        picker.showPickView(with: sampleRateList, selectedRow: index) { [weak self] row in
            self?.sampleRateButton.setTitle(self?.sampleRateList[row], for: .normal)
            self?.delegate?.bxs_accelerationParamsSamplingRateChanged(row)
        }
    }

    private func updateContent() {
        guard let model = dataModel else { return }
        if model.scale < scaleList.count {
            scaleButton.setTitle(scaleList[model.scale], for: .normal)
        }
        if model.samplingRate < sampleRateList.count {
            sampleRateButton.setTitle(sampleRateList[model.samplingRate], for: .normal)
        }
        currentScale = model.scale
        textField.text = model.threshold
        updateThresholdUnit()
    }

    private func updateThresholdUnit() {
        switch currentScale {
        case 0: thresholdUnitLabel.text = "x16mg"
        case 1: thresholdUnitLabel.text = "x32mg"
        case 2: thresholdUnitLabel.text = "x62mg"
        case 3: thresholdUnitLabel.text = "x186mg"
        default: break
        }
    }
}
