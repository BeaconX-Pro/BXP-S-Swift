//
//  MKBXSExportMarkDataHeaderView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public protocol MKBXSExportMarkDataHeaderViewDelegate: AnyObject {
    func bxs_markSyncButtonPressed()
    func bxs_markDeleteButtonPressed()
    func bxs_markExportButtonPressed()
}

public final class MKBXSExportMarkDataHeaderView: UIView {

    public weak var delegate: MKBXSExportMarkDataHeaderViewDelegate?

    // MARK: - Subviews

    private lazy var syncButton: UIButton = {
        let btn = MKSwiftUIAdaptor.createRoundedButton(title: "Sync",
                                                       target: self,
                                                       action: #selector(syncButtonPressed))
        return btn
    }()

    private lazy var syncLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(10)
        label.text = "Sync"
        return label
    }()

    private lazy var deleteButton: UIButton = {
        let btn = UIButton(type: .custom)
        // ⚠️ 图片加载方式需按工程实际 API 调整
        btn.setImage(UIImage(named: "bxs_slotExportDeleteIcon.png"), for: .normal)
        btn.addTarget(self, action: #selector(deleteButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var deleteLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(10)
        label.text = "Erase all"
        return label
    }()

    private lazy var exportButton: UIButton = {
        let btn = UIButton(type: .custom)
        // ⚠️ 图片加载方式需按工程实际 API 调整
        btn.setImage(UIImage(named: "bxs_slotExportEnableIcon.png"), for: .normal)
        btn.addTarget(self, action: #selector(exportButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var exportLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(10)
        label.text = "Export"
        return label
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addSubview(syncButton)
        addSubview(syncLabel)
        addSubview(deleteButton)
        addSubview(deleteLabel)
        addSubview(exportButton)
        addSubview(exportLabel)

        // ✅ 修复：约束放在 init 里，只添加一次
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Constraints

    private func setupConstraints() {
        syncButton.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(40)
            make.top.equalTo(5)
            make.height.equalTo(30)
        }
        syncLabel.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(40)
            make.top.equalTo(syncButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        deleteButton.snp.makeConstraints { make in
            make.right.equalTo(exportButton.snp.left).offset(-35)
            make.width.equalTo(40)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(30)
        }
        deleteLabel.snp.makeConstraints { make in
            make.centerX.equalTo(deleteButton)
            make.width.equalTo(60)
            make.top.equalTo(deleteButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        exportButton.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(40)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(30)
        }
        exportLabel.snp.makeConstraints { make in
            make.left.right.equalTo(exportButton)
            make.top.equalTo(exportButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
    }

    // MARK: - Actions

    @objc private func syncButtonPressed() {
        delegate?.bxs_markSyncButtonPressed()
    }

    @objc private func deleteButtonPressed() {
        delegate?.bxs_markDeleteButtonPressed()
    }

    @objc private func exportButtonPressed() {
        delegate?.bxs_markExportButtonPressed()
    }
}
