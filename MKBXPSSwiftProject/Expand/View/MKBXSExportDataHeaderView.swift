//
//  MKBXSExportDataHeaderView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public protocol MKBXSExportDataHeaderViewDelegate: AnyObject {
    func bxs_syncButtonPressed(_ selected: Bool)
    func bxs_switchButtonPressed(_ selected: Bool)
    func bxs_deleteButtonPressed()
    func bxs_exportButtonPressed()
}

public final class MKBXSExportDataHeaderView: UIView {

    public weak var delegate: MKBXSExportDataHeaderViewDelegate?

    // MARK: - UI

    private lazy var syncButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(syncButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var synIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_threeAxisAcceLoadingIcon.png")
        return iv
    }()

    private lazy var syncLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(10)
        label.text = "Sync"
        return label
    }()

    private lazy var switchButton: UIButton = {
        let btn = UIButton(type: .custom)
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

    private lazy var deleteButton: UIButton = {
        let btn = UIButton(type: .custom)
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
        syncButton.addSubview(synIcon)
        addSubview(syncLabel)
        addSubview(switchButton)
        addSubview(switchLabel)
        addSubview(deleteButton)
        addSubview(deleteLabel)
        addSubview(exportButton)
        addSubview(exportLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        syncButton.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(30)
            make.top.equalTo(5)
            make.height.equalTo(30)
        }
        synIcon.snp.remakeConstraints { make in
            make.centerX.equalTo(syncButton)
            make.centerY.equalTo(syncButton)
            make.width.height.equalTo(25)
        }
        syncLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(25)
            make.top.equalTo(syncButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        switchButton.snp.remakeConstraints { make in
            make.left.equalTo(syncButton.snp.right).offset(20)
            make.width.equalTo(40)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(30)
        }
        switchLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(switchButton)
            make.top.equalTo(switchButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        deleteButton.snp.remakeConstraints { make in
            make.right.equalTo(exportButton.snp.left).offset(-35)
            make.width.equalTo(40)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(30)
        }
        deleteLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(deleteButton)
            make.width.equalTo(60)
            make.top.equalTo(deleteButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        exportButton.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(40)
            make.centerY.equalTo(syncButton)
            make.height.equalTo(30)
        }
        exportLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(exportButton)
            make.top.equalTo(exportButton.snp.bottom).offset(2)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
    }

    // MARK: - Events

    @objc private func syncButtonPressed() {
        syncButton.isSelected.toggle()
        synIcon.layer.removeAnimation(forKey: "synIconAnimationKey")
        switchButton.isEnabled = !syncButton.isSelected
        exportButton.isEnabled = !syncButton.isSelected
        deleteButton.isEnabled = !syncButton.isSelected
        if syncButton.isSelected {
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            animation.duration = 2.0
            animation.fromValue = 0
            animation.toValue = 2 * Double.pi
            animation.autoreverses = false
            animation.repeatCount = MAXFLOAT
            animation.isRemovedOnCompletion = false
            synIcon.layer.add(animation, forKey: "synIconAnimationKey")
            syncLabel.text = "Stop"
            if switchButton.isSelected {
                switchButtonPressed()
            }
        } else {
            syncLabel.text = "Sync"
        }
        delegate?.bxs_syncButtonPressed(syncButton.isSelected)
    }

    @objc private func switchButtonPressed() {
        switchButton.isSelected.toggle()
        let iconName = switchButton.isSelected ? "bxs_exportHT_curveSelected.png" : "bxs_exportHT_tableSelected.png"
        switchButton.setImage(UIImage(named: iconName), for: .normal)
        delegate?.bxs_switchButtonPressed(switchButton.isSelected)
    }

    @objc private func deleteButtonPressed() {
        delegate?.bxs_deleteButtonPressed()
    }

    @objc private func exportButtonPressed() {
        delegate?.bxs_exportButtonPressed()
    }

    // MARK: - Public

    public func resetAllStatus() {
        syncButton.isSelected = false
        synIcon.layer.removeAnimation(forKey: "synIconAnimationKey")
        syncLabel.text = "Sync"
        switchButton.isEnabled = true
        switchButton.isSelected = false
        exportButton.isEnabled = true
        deleteButton.isEnabled = true
    }
}
