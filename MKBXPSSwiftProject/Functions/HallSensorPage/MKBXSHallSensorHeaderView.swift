//
//  MKBXSHallSensorHeaderView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSHallSensorHeaderViewModel: NSObject {
    public var count: String = ""
    public override init() { super.init() }
}

public protocol MKBXSHallSensorHeaderViewDelegate: AnyObject {
    func bxs_hallSensorHeaderView_clearPressed()
}

public final class MKBXSHallSensorHeaderView: UIView {

    public weak var delegate: MKBXSHallSensorHeaderViewDelegate?

    // ✅ 对齐 OC：count 为空时显示 ""，不是 "0"
    public var dataModel: MKBXSHallSensorHeaderViewModel? {
        didSet { mtCountValueLabel.text = dataModel?.count ?? "" }
    }

    private lazy var backView: UIView = {
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
        backView.addSubview(mtCountLabel)
        backView.addSubview(mtCountValueLabel)
        backView.addSubview(clearButton)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 保持跟 OC 一致：在 layoutSubviews 里用 remakeConstraints
    public override func layoutSubviews() {
        super.layoutSubviews()
        backView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(15)
            make.height.equalTo(44)
        }
        clearButton.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(45)
            make.centerY.equalTo(backView)
            make.height.equalTo(30)
        }
        mtCountLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.equalTo(150)
            make.centerY.equalTo(backView)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        mtCountValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(mtCountLabel.snp.right).offset(10)
            make.right.equalTo(clearButton.snp.left).offset(-5)
            make.centerY.equalTo(backView)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }

    @objc private func clearButtonPressed() {
        delegate?.bxs_hallSensorHeaderView_clearPressed()
    }
}
