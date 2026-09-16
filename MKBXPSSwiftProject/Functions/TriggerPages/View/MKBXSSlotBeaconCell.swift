//
//  MKBXSSlotBeaconCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSSlotBeaconCellModel: NSObject {
    public var major: String = ""
    public var minor: String = ""
    public var uuid: String = ""
    public override init() { super.init() }
}

public protocol MKBXSSlotBeaconCellDelegate: AnyObject {
    func bxs_advContent_majorChanged(_ major: String)
    func bxs_advContent_minorChanged(_ minor: String)
    func bxs_advContent_uuidChanged(_ uuid: String)
}

public final class MKBXSSlotBeaconCell: MKSwiftBaseCell {

    public var dataModel: MKBXSSlotBeaconCellModel? {
        didSet { updateContent() }
    }
    public weak var delegate: MKBXSSlotBeaconCellDelegate?

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSSlotBeaconCell {
        let identifier = "MKBXSSlotBeaconCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSSlotBeaconCell {
            return cell
        }
        return MKBXSSlotBeaconCell(style: .default, reuseIdentifier: identifier)
    }

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var leftIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_slotAdvContent.png")
        return iv
    }()

    private lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Adv content"
        return label
    }()

    private lazy var majorLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Major"
        return label
    }()

    private lazy var majorTextField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .realNumberOnly)
        tf.placeholder = "0~65535"
        tf.maxLength = 5
        tf.textColor = MKColor.defaultText
        tf.font = MKFont.font(15)
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKLine.color.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_advContent_majorChanged(text)
        }
        return tf
    }()

    private lazy var minorLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Minor"
        return label
    }()

    private lazy var minorTextField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .realNumberOnly)
        tf.placeholder = "0~65535"
        tf.maxLength = 5
        tf.textColor = MKColor.defaultText
        tf.font = MKFont.font(15)
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKLine.color.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_advContent_minorChanged(text)
        }
        return tf
    }()

    private lazy var uuidLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "UUID"
        return label
    }()

    private lazy var hexLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(12)
        label.textAlignment = .right
        label.text = "0x"
        return label
    }()

    private lazy var uuidTextField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .hexCharOnly)
        tf.placeholder = "16bytes"
        tf.maxLength = 32
        tf.textColor = MKColor.defaultText
        tf.font = MKFont.font(15)
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKLine.color.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_advContent_uuidChanged(text)
        }
        return tf
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(backView)
        backView.addSubview(leftIcon)
        backView.addSubview(typeLabel)
        backView.addSubview(majorLabel)
        backView.addSubview(majorTextField)
        backView.addSubview(minorLabel)
        backView.addSubview(minorTextField)
        backView.addSubview(uuidLabel)
        backView.addSubview(hexLabel)
        backView.addSubview(uuidTextField)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        backView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        leftIcon.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.height.equalTo(22)
            make.top.equalTo(10)
        }
        typeLabel.snp.remakeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(15)
            make.right.equalTo(-15)
            make.centerY.equalTo(leftIcon)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        majorLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(80)
            make.centerY.equalTo(majorTextField)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        majorTextField.snp.remakeConstraints { make in
            make.left.equalTo(majorLabel.snp.right).offset(40)
            make.right.equalTo(-15)
            make.top.equalTo(leftIcon.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        minorLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(80)
            make.centerY.equalTo(minorTextField)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        minorTextField.snp.remakeConstraints { make in
            make.left.equalTo(minorLabel.snp.right).offset(40)
            make.right.equalTo(-15)
            make.top.equalTo(majorTextField.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        uuidLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(80)
            make.centerY.equalTo(uuidTextField)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        hexLabel.snp.remakeConstraints { make in
            make.right.equalTo(uuidTextField.snp.left).offset(-2)
            make.width.equalTo(30)
            make.centerY.equalTo(uuidTextField)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        uuidTextField.snp.remakeConstraints { make in
            make.left.equalTo(uuidLabel.snp.right).offset(40)
            make.right.equalTo(-15)
            make.top.equalTo(minorTextField.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
    }

    private func updateContent() {
        guard let model = dataModel else { return }
        majorTextField.text = model.major
        minorTextField.text = model.minor
        uuidTextField.text = model.uuid
    }
}
