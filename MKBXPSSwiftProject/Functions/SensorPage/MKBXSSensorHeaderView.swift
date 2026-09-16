//
//  MKBXSSensorHeaderView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSSensorHeaderViewModel: NSObject {
    public var temperature: String = ""
    public var humidity: String = ""
    public var interval: String = ""
    public override init() { super.init() }
}

public protocol MKBXSSensorHeaderViewDelegate: AnyObject {
    func bxs_sensorHeaderView_samplingIntervalChanged(_ interval: String)
}

// MARK: - 内部视图

private final class MKBXSSensorConfigValueView: UIView {

    lazy var leftIcon: UIImageView = UIImageView()
    lazy var msgLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .left
        l.textColor = MKColor.defaultText
        l.font = MKFont.font(15)
        return l
    }()
    lazy var valueLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .left
        l.textColor = MKColor.defaultText
        l.font = MKFont.font(28)
        return l
    }()
    lazy var unitLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .left
        l.textColor = MKColor.defaultText
        l.font = MKFont.font(12)
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(leftIcon)
        addSubview(msgLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        leftIcon.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.width.height.equalTo(25)
            make.centerY.equalToSuperview()
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(5)
            make.right.equalTo(valueLabel.snp.left).offset(-5)
            make.centerY.equalToSuperview()
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        valueLabel.snp.remakeConstraints { make in
            make.right.equalTo(unitLabel.snp.left).offset(-10)
            make.width.equalTo(85)
            make.centerY.equalToSuperview()
            make.height.equalTo(MKFont.font(28).lineHeight)
        }
        unitLabel.snp.remakeConstraints { make in
            make.right.equalTo(-5)
            make.width.equalTo(30)
            make.bottom.equalTo(valueLabel)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }
}

// MARK: - Public

public final class MKBXSSensorHeaderView: UIView {

    public var dataModel: MKBXSSensorHeaderViewModel? {
        didSet { updateContent() }
    }
    public weak var delegate: MKBXSSensorHeaderViewDelegate?

    public var hasHumidity: Bool = false {
        didSet {
            if hasHumidity {
                if humidityView.superview == nil { backView.addSubview(humidityView) }
            } else {
                humidityView.removeFromSuperview()
            }
            setNeedsLayout()
        }
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
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.textColor = MKColor.defaultText
        label.text = "Real-time data"
        return label
    }()

    private lazy var tempView: MKBXSSensorConfigValueView = {
        let v = MKBXSSensorConfigValueView()
        v.leftIcon.image = UIImage(named: "bxs_slotConfig_temperatureIcon.png")
        v.msgLabel.text = "Temperature"
        v.valueLabel.text = "0.0"
        v.unitLabel.text = "℃"
        return v
    }()

    private lazy var humidityView: MKBXSSensorConfigValueView = {
        let v = MKBXSSensorConfigValueView()
        v.leftIcon.image = UIImage(named: "bxs_slotConfig_humidityIcon.png")
        v.msgLabel.text = "Humidity"
        v.valueLabel.text = "0.0"
        v.unitLabel.text = "%RH"
        return v
    }()

    private lazy var samplingLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "Sampling interval"
        return label
    }()

    private lazy var textField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .realNumberOnly)
        tf.textColor = MKColor.defaultText
        tf.textAlignment = .center
        tf.font = MKFont.font(12)
        tf.borderStyle = .none
        tf.text = "1"
        tf.maxLength = 5
        tf.placeholder = "1~65535"
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_sensorHeaderView_samplingIntervalChanged(text)
        }
        let lineView = UIView()
        lineView.backgroundColor = MKColor.defaultText
        tf.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        return tf
    }()

    private lazy var unitLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.attributedText = MKSwiftUIAdaptor.createAttributedString(strings: ["sec", "   (1 ~ 65535)"],
                                                                       fonts: [MKFont.font(13), MKFont.font(12)],
                                                                       colors: [MKColor.defaultText, UIColor(red: 223/255.0, green: 223/255.0, blue: 223/255.0, alpha: 1)])
        return label
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        addSubview(backView)
        backView.addSubview(msgLabel)
        backView.addSubview(tempView)
        backView.addSubview(samplingLabel)
        backView.addSubview(textField)
        backView.addSubview(unitLabel)
    }

    required init?(coder: NSCoder) { fatalError() }

    public override func layoutSubviews() {
        super.layoutSubviews()
        backView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(20)
            make.bottom.equalTo(-10)
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(10)
            make.height.equalTo(30)
        }
        tempView.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(msgLabel.snp.bottom).offset(10)
            make.height.equalTo(30)
        }

        let samplingTopAnchor: ConstraintItem
        if hasHumidity {
            humidityView.snp.remakeConstraints { make in
                make.left.equalTo(10)
                make.right.equalTo(-10)
                make.top.equalTo(tempView.snp.bottom).offset(10)
                make.height.equalTo(30)
            }
            samplingTopAnchor = humidityView.snp.bottom
        } else {
            samplingTopAnchor = tempView.snp.bottom
        }

        textField.snp.remakeConstraints { make in
            make.left.equalTo(samplingLabel.snp.right).offset(5)
            make.width.equalTo(65)
            make.top.equalTo(samplingTopAnchor).offset(10)
            make.height.equalTo(20)
        }
        samplingLabel.snp.remakeConstraints { make in
            make.left.equalTo(45)
            make.width.equalTo(110)
            make.centerY.equalTo(textField)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        unitLabel.snp.remakeConstraints { make in
            make.right.equalTo(-10)
            make.left.equalTo(textField.snp.right).offset(3)
            make.centerY.equalTo(textField)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
    }

    private func updateContent() {
        guard let model = dataModel else { return }
        tempView.valueLabel.text = model.temperature
        if hasHumidity {
            humidityView.valueLabel.text = model.humidity
        }
        textField.text = model.interval
    }
}
