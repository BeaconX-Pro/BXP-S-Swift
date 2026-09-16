//
//  MKBXSSyncTimeCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSSyncTimeCellModel: NSObject {
    public var date: String = ""
    public override init() { super.init() }
}

public protocol MKBXSSyncTimeCellDelegate: AnyObject {
    func bxs_syncTimeCell_syncTimePressed()
}

public final class MKBXSSyncTimeCell: MKSwiftBaseCell {

    public var dataModel: MKBXSSyncTimeCellModel? {
        didSet {
            guard let model = dataModel else { return }
            dateLabel.text = model.date
        }
    }

    public weak var delegate: MKBXSSyncTimeCellDelegate?

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSSyncTimeCell {
        let identifier = "MKBXSSyncTimeCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSSyncTimeCell {
            return cell
        }
        return MKBXSSyncTimeCell(style: .default, reuseIdentifier: identifier)
    }

    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Sync Beacon time"
        return label
    }()

    private lazy var syncButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Sync",
                                                    target: self,
                                                    action: #selector(syncButtonPressed))
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(14)
        return label
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(msgLabel)
        contentView.addSubview(syncButton)
        contentView.addSubview(dateLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        syncButton.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(50)
            make.top.equalTo(10)
            make.height.equalTo(30)
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(syncButton.snp.left).offset(-10)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        dateLabel.snp.remakeConstraints { make in
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.top.equalTo(syncButton.snp.bottom).offset(10)
            make.height.equalTo(MKFont.font(14).lineHeight)
        }
    }

    @objc private func syncButtonPressed() {
        delegate?.bxs_syncTimeCell_syncTimePressed()
    }
}
