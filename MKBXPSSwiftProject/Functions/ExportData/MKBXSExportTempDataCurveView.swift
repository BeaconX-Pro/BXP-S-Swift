//
//  MKBXSExportTempDataCurveView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSExportTempDataCurveView: UIView {

    private lazy var totalLabel: UILabel = {
        let label = UILabel()
        label.textColor = .blue
        label.textAlignment = .right
        label.font = MKFont.font(10)
        label.text = "Total Data Points: 0"
        return label
    }()

    private lazy var displayLabel: UILabel = {
        let label = UILabel()
        label.textColor = .blue
        label.textAlignment = .right
        label.font = MKFont.font(10)
        label.text = "Window Display Points: 0"
        return label
    }()

    private lazy var tempView: MKBXSTHCurveView = MKBXSTHCurveView()

    private lazy var tempModel: MKBXSTHCurveViewModel = {
        let m = MKBXSTHCurveViewModel()
        m.curveTitle = "Temperature(℃)"
        m.curveViewBackgroundColor = .white
        m.lineWidth = 3
        m.labelColor = UIColor(red: 136/255.0, green: 136/255.0, blue: 136/255.0, alpha: 1)
        return m
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addSubview(tempView)
        addSubview(totalLabel)
        addSubview(displayLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        totalLabel.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(5)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        displayLabel.snp.remakeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(totalLabel.snp.bottom).offset(3)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        tempView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(20)
            make.bottom.equalTo(snp.centerY).offset(-5)
        }
    }

    public func updateTemperatureDatas(_ temperatureList: [String],
                                       temperatureMax: CGFloat,
                                       temperatureMin: CGFloat,
                                       completeBlock: (() -> Void)?) {
        guard !temperatureList.isEmpty else {
            completeBlock?()
            return
        }
        totalLabel.text = "Total Data Points: \(temperatureList.count)"
        var displayText = "\(temperatureList.count)"
        if temperatureList.count > 1000 {
            displayText = "1000"
        }
        displayLabel.text = "Window Display Points: \(displayText)"
        tempView.drawCurve(with: tempModel,
                           pointList: temperatureList,
                           maxValue: temperatureMax,
                           minValue: temperatureMin)
        completeBlock?()
    }
}
