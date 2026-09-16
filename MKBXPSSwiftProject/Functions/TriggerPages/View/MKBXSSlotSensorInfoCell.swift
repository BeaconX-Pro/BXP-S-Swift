//
//  MKBXSSlotSensorInfoCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSSlotSensorInfoCellModel: NSObject {
    public var deviceName: String = ""
    public var tagID: String = ""
    public var tagEnable: Bool = true
    public override init() { super.init() }
}

public protocol MKBXSSlotSensorInfoCellDelegate: AnyObject {
    func bxs_advContent_tagInfo_deviceNameChanged(_ text: String)
    func bxs_advContent_tagInfo_tagIDChanged(_ text: String)
}

public final class MKBXSSlotSensorInfoCell: MKSwiftBaseCell {

    public var dataModel: MKBXSSlotSensorInfoCellModel? {
        didSet { updateContent() }
    }
    public weak var delegate: MKBXSSlotSensorInfoCellDelegate?

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSSlotSensorInfoCell {
        let identifier = "MKBXSSlotSensorInfoCellIdenth"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSSlotSensorInfoCell {
            return cell
        }
        return MKBXSSlotSensorInfoCell(style: .default, reuseIdentifier: identifier)
    }

    private let offsetX: CGFloat = 10
    private let iconWidth: CGFloat = 22
    private let iconHeight: CGFloat = 22

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var icon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_slotAdvContent.png")
        return iv
    }()

    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Adv content"
        return label
    }()

    private lazy var deviceNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "Device name"
        return label
    }()

    private lazy var nameTextField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .normal)
        tf.placeholder = "1 - 20 characters."
        tf.maxLength = 20
        tf.textColor = MKColor.defaultText
        tf.font = MKFont.font(15)
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKLine.color.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_advContent_tagInfo_deviceNameChanged(text)
        }
        return tf
    }()

    private lazy var tagIDLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "Tag ID"
        return label
    }()

    private lazy var xLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .right
        label.font = MKFont.font(11)
        label.text = "0x"
        return label
    }()

    private lazy var tagIDTextField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .hexCharOnly)
        tf.placeholder = "1-6 bytes"
        tf.maxLength = 12
        tf.textColor = MKColor.defaultText
        tf.font = MKFont.font(15)
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKLine.color.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_advContent_tagInfo_tagIDChanged(text)
        }
        return tf
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(backView)
        backView.addSubview(icon)
        backView.addSubview(msgLabel)
        backView.addSubview(deviceNameLabel)
        backView.addSubview(nameTextField)
        backView.addSubview(tagIDLabel)
        backView.addSubview(xLabel)
        backView.addSubview(tagIDTextField)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        backView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(5)
            make.bottom.equalTo(-5)
        }
        icon.snp.remakeConstraints { make in
            make.left.equalTo(offsetX)
            make.width.equalTo(iconWidth)
            make.top.equalTo(5)
            make.height.equalTo(iconHeight)
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(10)
            make.right.equalTo(-offsetX)
            make.centerY.equalTo(icon)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        deviceNameLabel.snp.remakeConstraints { make in
            make.left.equalTo(offsetX)
            make.width.equalTo(110)
            make.centerY.equalTo(nameTextField)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        nameTextField.snp.remakeConstraints { make in
            make.left.equalTo(deviceNameLabel.snp.right).offset(30)
            make.right.equalTo(-offsetX)
            make.top.equalTo(icon.snp.bottom).offset(10)
            make.height.equalTo(25)
        }
        tagIDLabel.snp.remakeConstraints { make in
            make.left.equalTo(offsetX)
            make.width.equalTo(110)
            make.centerY.equalTo(tagIDTextField)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        xLabel.snp.remakeConstraints { make in
            make.left.equalTo(tagIDLabel.snp.right).offset(10)
            make.width.equalTo(15)
            make.centerY.equalTo(tagIDTextField)
            make.height.equalTo(MKFont.font(11).lineHeight)
        }
        tagIDTextField.snp.remakeConstraints { make in
            make.left.equalTo(xLabel.snp.right).offset(5)
            make.right.equalTo(-offsetX)
            make.top.equalTo(nameTextField.snp.bottom).offset(10)
            make.height.equalTo(25)
        }
    }

    private func updateContent() {
        guard let model = dataModel else { return }
        nameTextField.text = model.deviceName
        tagIDTextField.text = model.tagID
        tagIDTextField.isEnabled = model.tagEnable
    }
}
