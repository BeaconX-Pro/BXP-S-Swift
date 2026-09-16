//
//  MKBXSSlotUIDCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSSlotUIDCellModel: NSObject {
    public var namespaceID: String = ""
    public var instanceID: String = ""
    public override init() { super.init() }
}

public protocol MKBXSSlotUIDCellDelegate: AnyObject {
    func bxs_advContent_namespaceIDChanged(_ text: String)
    func bxs_advContent_instanceIDChanged(_ text: String)
}

public final class MKBXSSlotUIDCell: MKSwiftBaseCell {

    public var dataModel: MKBXSSlotUIDCellModel? {
        didSet { updateContent() }
    }
    public weak var delegate: MKBXSSlotUIDCellDelegate?

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSSlotUIDCell {
        let identifier = "MKBXSSlotUIDCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSSlotUIDCell {
            return cell
        }
        return MKBXSSlotUIDCell(style: .default, reuseIdentifier: identifier)
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

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Namespace ID"
        return label
    }()

    private lazy var hexNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(12)
        label.textAlignment = .right
        label.text = "0x"
        return label
    }()

    private lazy var nameTextField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .hexCharOnly)
        tf.placeholder = "10bytes"
        tf.maxLength = 20
        tf.textColor = MKColor.defaultText
        tf.font = MKFont.font(15)
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKLine.color.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_advContent_namespaceIDChanged(text)
        }
        return tf
    }()

    private lazy var instanceLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Instance ID"
        return label
    }()

    private lazy var hexInstanceLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(12)
        label.textAlignment = .right
        label.text = "0x"
        return label
    }()

    private lazy var instanceTextField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .hexCharOnly)
        tf.placeholder = "6bytes"
        tf.maxLength = 12
        tf.textColor = MKColor.defaultText
        tf.font = MKFont.font(15)
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKLine.color.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_advContent_instanceIDChanged(text)
        }
        return tf
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(backView)
        backView.addSubview(leftIcon)
        backView.addSubview(typeLabel)
        backView.addSubview(nameLabel)
        backView.addSubview(nameTextField)
        backView.addSubview(hexNameLabel)
        backView.addSubview(instanceLabel)
        backView.addSubview(instanceTextField)
        backView.addSubview(hexInstanceLabel)
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
        nameLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(120)
            make.centerY.equalTo(nameTextField)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        hexNameLabel.snp.remakeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(5)
            make.width.equalTo(30)
            make.centerY.equalTo(nameTextField)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        nameTextField.snp.remakeConstraints { make in
            make.left.equalTo(hexNameLabel.snp.right).offset(5)
            make.right.equalTo(-15)
            make.top.equalTo(leftIcon.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        instanceLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(120)
            make.centerY.equalTo(instanceTextField)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        hexInstanceLabel.snp.remakeConstraints { make in
            make.left.equalTo(instanceLabel.snp.right).offset(5)
            make.width.equalTo(30)
            make.centerY.equalTo(instanceTextField)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        instanceTextField.snp.remakeConstraints { make in
            make.left.equalTo(hexInstanceLabel.snp.right).offset(5)
            make.right.equalTo(-15)
            make.top.equalTo(nameTextField.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
    }

    private func updateContent() {
        guard let model = dataModel else { return }
        nameTextField.text = model.namespaceID
        instanceTextField.text = model.instanceID
    }
}
