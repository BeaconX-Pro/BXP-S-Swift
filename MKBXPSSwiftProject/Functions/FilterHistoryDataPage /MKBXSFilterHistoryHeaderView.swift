//
//  MKBXSFilterHistoryHeaderView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public protocol MKBXSFilterHistoryHeaderViewDelegate: AnyObject {
    func bxs_filterHistoryHeaderView_switchButtonPressed(_ selected: Bool)
    func bxs_filterHistoryHeaderView_exportButtonPressed()
}

public final class MKBXSFilterHistoryHeaderView: UIView {

    public weak var delegate: MKBXSFilterHistoryHeaderViewDelegate?

    // MARK: - Subviews

    private lazy var switchButton: UIButton = {
        let btn = UIButton(type: .custom)
        // ⚠️ 图标加载方式按工程实际 API 调整
        btn.setImage(UIImage(named: "bxs_exportHT_tableSelected.png"), for: .normal)
        btn.addTarget(self, action: #selector(switchButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var switchLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(10)
        label.text = "Display"
        return label
    }()

    private lazy var exportButton: UIButton = {
        let btn = UIButton(type: .custom)
        // ⚠️ 图标加载方式按工程实际 API 调整
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

    private lazy var sumLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "Records: N/A"
        return label
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addSubview(switchButton)
        addSubview(switchLabel)
        addSubview(exportButton)
        addSubview(exportLabel)
        addSubview(sumLabel)

        // ✅ 修复：约束放在 init 里，只添加一次
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Constraints

    private func setupConstraints() {
        switchButton.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(40)
            make.top.equalTo(5)
            make.height.equalTo(30)
        }
        switchLabel.snp.makeConstraints { make in
            make.left.right.equalTo(switchButton)
            make.top.equalTo(switchButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        exportButton.snp.makeConstraints { make in
            make.left.equalTo(switchButton.snp.right).offset(30)
            make.width.equalTo(40)
            make.centerY.equalTo(switchButton)
            make.height.equalTo(30)
        }
        exportLabel.snp.makeConstraints { make in
            make.left.right.equalTo(exportButton)
            make.top.equalTo(exportButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        sumLabel.snp.makeConstraints { make in
            make.left.equalTo(exportButton.snp.right).offset(30)
            make.right.equalTo(-15)
            make.centerY.equalTo(switchButton)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
    }

    // MARK: - Actions

    @objc private func switchButtonPressed() {
        switchButton.isSelected.toggle()
        // ⚠️ 图标加载方式按工程实际 API 调整
        let iconName = switchButton.isSelected
            ? "bxs_exportHT_curveSelected.png"
            : "bxs_exportHT_tableSelected.png"
        switchButton.setImage(UIImage(named: iconName), for: .normal)
        delegate?.bxs_filterHistoryHeaderView_switchButtonPressed(switchButton.isSelected)
    }

    @objc private func exportButtonPressed() {
        delegate?.bxs_filterHistoryHeaderView_exportButtonPressed()
    }

    // MARK: - Public

    public func updateSumRecord(_ record: String) {
        sumLabel.text = "Filtered records: \(record)"
    }
}
