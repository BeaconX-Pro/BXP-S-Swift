//
//  MKBXSAccelerationHeaderView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public protocol MKBXSAccelerationHeaderViewDelegate: AnyObject {
    func bxs_updateThreeAxisNotifyStatus(_ notify: Bool)
    func bxs_clearMotionTriggerCountButtonPressed()
}

public final class MKBXSAccelerationHeaderView: UIView {

    public weak var delegate: MKBXSAccelerationHeaderViewDelegate?

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

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

    private lazy var dataLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(12)
        label.text = "X-axis:N/A;Y-axis:N/A;Z-axis:N/A"
        return label
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var mtCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Motion trigger count"
        return label
    }()

    private lazy var mtCountValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(12)
        label.text = "0"
        return label
    }()

    private lazy var clearButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Clear",
                                                    target: self,
                                                    action: #selector(clearButtonPressed))
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        addSubview(backView)
        backView.addSubview(syncButton)
        syncButton.addSubview(synIcon)
        backView.addSubview(syncLabel)
        backView.addSubview(dataLabel)
        addSubview(bottomView)
        bottomView.addSubview(mtCountLabel)
        bottomView.addSubview(mtCountValueLabel)
        bottomView.addSubview(clearButton)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        backView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(15)
            make.height.equalTo(60)
        }
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
        dataLabel.snp.remakeConstraints { make in
            make.left.equalTo(syncButton.snp.right).offset(5)
            make.right.equalTo(-15)
            make.centerY.equalTo(syncButton).offset(2)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        bottomView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(backView.snp.bottom).offset(15)
            make.bottom.equalTo(-20)
        }
        clearButton.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(45)
            make.centerY.equalTo(bottomView)
            make.height.equalTo(30)
        }
        mtCountLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(150)
            make.centerY.equalTo(bottomView)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        mtCountValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(mtCountLabel.snp.right).offset(10)
            make.right.equalTo(clearButton.snp.left).offset(-5)
            make.centerY.equalTo(bottomView)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }

    @objc private func syncButtonPressed() {
        syncButton.isSelected.toggle()
        synIcon.layer.removeAnimation(forKey: "bxs_synIconAnimationKey")
        delegate?.bxs_updateThreeAxisNotifyStatus(syncButton.isSelected)
        if syncButton.isSelected {
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            animation.duration = 2.0
            animation.fromValue = 0
            animation.toValue = 2 * Double.pi
            animation.autoreverses = false
            animation.repeatCount = MAXFLOAT
            animation.isRemovedOnCompletion = false
            synIcon.layer.add(animation, forKey: "bxs_synIconAnimationKey")
            syncLabel.text = "Stop"
            return
        }
        syncLabel.text = "Sync"
    }

    @objc private func clearButtonPressed() {
        delegate?.bxs_clearMotionTriggerCountButtonPressed()
    }

    public func updateTriggerCount(_ count: String) {
        mtCountValueLabel.text = count
    }

    public func updateData(xData: String, yData: String, zData: String) {
        let x = "X-axis:\(xData)mg"
        let y = "Y-axis:\(yData)mg"
        let z = "Z-axis:\(zData)mg"
        dataLabel.text = "\(x);\(y);\(z)"
    }
}
