//
//  MKBXSSlotURLCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSSlotURLCellModel: NSObject {
    public var urlType: Int = 0
    public var urlContent: String = ""
    public override init() { super.init() }
}

public protocol MKBXSSlotURLCellDelegate: AnyObject {
    func bxs_advContent_urlTypeChanged(_ urlType: Int)
    func bxs_advContent_urlContentChanged(_ content: String)
}

public final class MKBXSSlotURLCell: MKSwiftBaseCell {

    public var dataModel: MKBXSSlotURLCellModel? {
        didSet { updateContent() }
    }
    public weak var delegate: MKBXSSlotURLCellDelegate?

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSSlotURLCell {
        let identifier = "MKBXSSlotURLCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSSlotURLCell {
            return cell
        }
        return MKBXSSlotURLCell(style: .default, reuseIdentifier: identifier)
    }

    private let urlTypeList = ["http://www.", "https://www.", "http://", "https://"]

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

    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(14)
        label.textAlignment = .left
        label.text = "URL"
        return label
    }()

    private lazy var urlTypeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor(red: 111/255.0, green: 111/255.0, blue: 111/255.0, alpha: 1)
        label.font = MKFont.font(12)
        label.text = "http://www."
        label.layer.masksToBounds = true
        label.layer.borderWidth = 0.5
        label.layer.borderColor = MKColor.line.cgColor
        label.layer.cornerRadius = 2
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(urlTypeLabelPressed)))
        return label
    }()

    private lazy var textField: MKSwiftTextField = {
        let tf = MKSwiftTextField(textFieldType: .normal)
        tf.placeholder = "mokoblue.com/"
        tf.maxLength = 17
        tf.textColor = MKColor.defaultText
        tf.font = MKFont.font(15)
        tf.layer.masksToBounds = true
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = MKColor.line.cgColor
        tf.layer.cornerRadius = 3
        tf.textChangedBlock = { [weak self] text in
            self?.delegate?.bxs_advContent_urlContentChanged(text)
        }
        return tf
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(backView)
        backView.addSubview(leftIcon)
        backView.addSubview(typeLabel)
        backView.addSubview(msgLabel)
        backView.addSubview(urlTypeLabel)
        backView.addSubview(textField)
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
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(40)
            make.centerY.equalTo(textField)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        urlTypeLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel.snp.right).offset(15)
            make.width.equalTo(80)
            make.centerY.equalTo(textField)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        textField.snp.remakeConstraints { make in
            make.left.equalTo(urlTypeLabel.snp.right).offset(5)
            make.right.equalTo(-15)
            make.top.equalTo(leftIcon.snp.bottom).offset(15)
            make.height.equalTo(30)
        }
    }

    @objc private func urlTypeLabelPressed() {
        let current = urlTypeLabel.text ?? ""
        let index = urlTypeList.firstIndex(of: current) ?? 0
        let picker = MKSwiftPickerView()
        picker.showPickView(with: urlTypeList, selectedRow: index) { [weak self] row in
            self?.urlTypeLabel.text = self?.urlTypeList[row]
            self?.delegate?.bxs_advContent_urlTypeChanged(row)
        }
    }

    private func updateContent() {
        guard let model = dataModel else { return }
        if model.urlType < urlTypeList.count {
            urlTypeLabel.text = urlTypeList[model.urlType]
        }
        textField.text = model.urlContent
    }
}
