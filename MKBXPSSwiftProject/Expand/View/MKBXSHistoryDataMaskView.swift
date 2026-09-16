//
//  MKBXSHistoryDataMaskView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSHistoryDataMaskView: UIView {

    // MARK: - UI

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 44/255.0, green: 44/255.0, blue: 44/255.0, alpha: 1)
        view.layer.masksToBounds = true
        view.layer.borderColor = MKLine.color.cgColor
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 5
        return view
    }()

    private lazy var totalLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = MKFont.font(15)
        label.textAlignment = .center
        return label
    }()

    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = MKFont.font(15)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Reading data ... , update 0 records"
        return label
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(backView)
        backView.addSubview(totalLabel)
        backView.addSubview(numberLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        backView.snp.remakeConstraints { make in
            make.left.equalTo(30)
            make.right.equalTo(-30)
            make.centerY.equalToSuperview()
            make.height.equalTo(80)
        }
        totalLabel.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(10)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }

        let width = frame.width - 2 * 30 - 2 * 10
        let numberSize = (numberLabel.text ?? "").size(withFont: numberLabel.font,
                                                       maxSize: CGSize(width: width - 30,
                                                                       height: .greatestFiniteMagnitude))
        numberLabel.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(totalLabel.snp.bottom).offset(10)
            make.height.equalTo(numberSize.height)
        }
    }

    // MARK: - Public

    public func show(with view: UIView) {
        if superview != nil {
            removeFromSuperview()
        }
        // ⬇️ 关键：设置 frame 为父视图的 bounds，否则只显示左上角一个点
        self.frame = view.bounds
        view.addSubview(self)
        // ⬇️ 触发一次布局，让 backView 的子视图约束生效
        setNeedsLayout()
        layoutIfNeeded()
    }

    public func dismiss() {
        if superview != nil {
            removeFromSuperview()
        }
    }

    public func updateTotalNumber(_ totalNumber: String) {
        totalLabel.text = "Total records: \(totalNumber)"
    }

    public func updateCurrentNumber(_ number: String) {
        numberLabel.text = "Reading data ... , update \(number) records"
        setNeedsLayout()
    }
}
