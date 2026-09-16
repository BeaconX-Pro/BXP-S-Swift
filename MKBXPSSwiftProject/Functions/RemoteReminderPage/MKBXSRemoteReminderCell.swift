//
//  MKBXSRemoteReminderCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSRemoteReminderCellModel: NSObject {
    public var msg: String = ""
    public var index: Int = 0
    public override init() { super.init() }
}

public protocol MKBXSRemoteReminderCellDelegate: AnyObject {
    func bxs_remindButtonPressed(_ index: Int)
}

public final class MKBXSRemoteReminderCell: MKSwiftBaseCell {

    public var dataModel: MKBXSRemoteReminderCellModel? {
        didSet { msgLabel.text = dataModel?.msg }
    }
    public weak var delegate: MKBXSRemoteReminderCellDelegate?

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSRemoteReminderCell {
        let identifier = "MKBXSRemoteReminderCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSRemoteReminderCell {
            return cell
        }
        return MKBXSRemoteReminderCell(style: .default, reuseIdentifier: identifier)
    }

    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(15)
        return label
    }()

    private lazy var remindButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Remind",
                                                    target: self,
                                                    action: #selector(remindButtonPressed))
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(msgLabel)
        contentView.addSubview(remindButton)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        remindButton.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(60)
            make.centerY.equalTo(contentView)
            make.height.equalTo(35)
        }
        msgLabel.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(remindButton.snp.left).offset(-15)
            make.centerY.equalTo(contentView)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
    }

    @objc private func remindButtonPressed() {
        delegate?.bxs_remindButtonPressed(dataModel?.index ?? 0)
    }
}
