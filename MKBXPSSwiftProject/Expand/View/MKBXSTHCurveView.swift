//
//  MKBXSTHCurveView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

// MARK: - ViewModel

public final class MKBXSTHCurveViewModel: NSObject {
    public var lineColor: UIColor = .blue
    public var lineWidth: CGFloat = 1.0
    public var curveViewBackgroundColor: UIColor = UIColor(red: 224/255.0, green: 245/255.0, blue: 254/255.0, alpha: 1)
    public var curveTitle: String = ""
    public var titleColor: UIColor = MKColor.defaultText
    public var titleFont: UIFont = MKFont.font(12)
    public var yPostionColor: UIColor = MKColor.defaultText
    public var yPostionWidth: CGFloat = MKLine.height
    public var labelColor: UIColor = MKColor.defaultText
    public var labelFont: UIFont = MKFont.font(10)

    public override init() { super.init() }
}

// MARK: - Internal Curve View

private final class MKBXSCurveView: UIView {

    var pointList: [CGFloat] = []
    var lineColor: UIColor = .blue
    var lineWidth: CGFloat = 1.0

    func updatePointValues(_ pointList: [String], maxValue: CGFloat, minValue: CGFloat) {
        guard !pointList.isEmpty else { return }
        self.pointList.removeAll()
        let totalValue = maxValue - minValue
        if totalValue == 0 {
            for _ in 0..<pointList.count {
                self.pointList.append(frame.height - 13)
            }
        } else {
            for value in pointList {
                let v = (frame.height - 13) * (maxValue - (CGFloat(Float(value) ?? 0))) / totalValue
                self.pointList.append(v)
            }
        }
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard !pointList.isEmpty else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(lineWidth > 0 ? lineWidth : 1)
        context.setStrokeColor(lineColor.cgColor)
        context.move(to: CGPoint(x: 0, y: pointList[0]))
        let width = frame.width / CGFloat(pointList.count)
        for i in 1..<pointList.count {
            context.addLine(to: CGPoint(x: CGFloat(i) * width, y: pointList[i]))
        }
        context.strokePath()
    }
}

// MARK: - Public View

public final class MKBXSTHCurveView: UIView, UIScrollViewDelegate {

    private let valueLabelWidth: CGFloat = 35
    private let maxPointCount: Int = 1000

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(12)
        label.textAlignment = .center
        label.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        return label
    }()

    private lazy var horizontalLine: UIView = {
        let view = UIView()
        view.backgroundColor = MKColor.defaultText
        return view
    }()

    private lazy var maxLabel: UILabel = loadLabel()
    private lazy var maxLine: UIView = loadLine()
    private lazy var valueMaxLabel: UILabel = loadLabel()
    private lazy var valueMaxLine: UIView = loadLine()
    private lazy var minLabel: UILabel = loadLabel()
    private lazy var minLine: UIView = loadLine()
    private lazy var valueMinLabel: UILabel = loadLabel()
    private lazy var valueMinLine: UIView = loadLine()
    private lazy var aveLabel: UILabel = loadLabel()
    private lazy var aveLine: UIView = loadLine()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.delegate = self
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    private lazy var curveView: MKBXSCurveView = MKBXSCurveView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(horizontalLine)
        addSubview(maxLabel)
        addSubview(maxLine)
        addSubview(valueMaxLabel)
        addSubview(valueMaxLine)
        addSubview(valueMinLabel)
        addSubview(valueMinLine)
        addSubview(minLabel)
        addSubview(minLine)
        addSubview(aveLabel)
        addSubview(aveLine)
        addSubview(scrollView)
        scrollView.addSubview(curveView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let labelSpace = (frame.height - 10 - 5 * MKFont.font(10).lineHeight) / 4
        let curveViewWidth = frame.width - 60
        let curveViewHeight = frame.height - 10 - 2 * MKFont.font(10).lineHeight - 2 * labelSpace

        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(-40)
            make.width.equalTo(120)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
        maxLabel.snp.remakeConstraints { make in
            make.left.equalTo(30)
            make.width.equalTo(valueLabelWidth)
            make.top.equalTo(5)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        valueMaxLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(maxLabel)
            make.top.equalTo(maxLabel.snp.bottom).offset(labelSpace)
            make.height.equalTo(maxLabel.snp.height)
        }
        aveLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(maxLabel)
            make.top.equalTo(valueMaxLabel.snp.bottom).offset(labelSpace)
            make.height.equalTo(maxLabel.snp.height)
        }
        valueMinLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(maxLabel)
            make.top.equalTo(aveLabel.snp.bottom).offset(labelSpace)
            make.height.equalTo(maxLabel.snp.height)
        }
        minLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(maxLabel)
            make.bottom.equalTo(-5)
            make.height.equalTo(maxLabel.snp.height)
        }
        horizontalLine.snp.remakeConstraints { make in
            make.left.equalTo(maxLabel.snp.right).offset(3)
            make.width.equalTo(MKLine.height)
            make.top.equalTo(5)
            make.bottom.equalTo(-5)
        }
        maxLine.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.width.equalTo(3)
            make.centerY.equalTo(maxLabel)
            make.height.equalTo(0.5)
        }
        minLine.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.width.equalTo(3)
            make.centerY.equalTo(minLabel)
            make.height.equalTo(0.5)
        }
        aveLine.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.width.equalTo(3)
            make.centerY.equalTo(aveLabel)
            make.height.equalTo(0.5)
        }
        valueMaxLine.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.width.equalTo(3)
            make.centerY.equalTo(valueMaxLabel)
            make.height.equalTo(0.5)
        }
        valueMinLine.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.width.equalTo(3)
            make.centerY.equalTo(valueMinLabel)
            make.height.equalTo(0.5)
        }
        scrollView.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.right.equalTo(-5)
            make.top.equalTo(valueMaxLabel.snp.centerY)
            make.bottom.equalTo(valueMinLabel.snp.centerY)
        }
        curveView.frame = CGRect(x: 0, y: 0, width: curveViewWidth, height: curveViewHeight)
    }

    // MARK: - ScrollView

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x <= 0 {
            var offset = scrollView.contentOffset
            offset.x = 0
            scrollView.contentOffset = offset
        }
    }

    // MARK: - Public

    public func drawCurve(with dataModel: MKBXSTHCurveViewModel,
                          pointList: [String],
                          maxValue: CGFloat,
                          minValue: CGFloat) {
        guard !pointList.isEmpty else { return }
        configParams(with: dataModel)

        let labelSpace = (frame.height - 10 - 5 * MKFont.font(10).lineHeight) / 4
        let curveViewWidth = frame.width - 60
        let curveViewHeight = frame.height - 10 - 2 * MKFont.font(10).lineHeight - 2 * labelSpace

        horizontalLine.snp.remakeConstraints { make in
            make.left.equalTo(maxLabel.snp.right).offset(3)
            make.width.equalTo(dataModel.yPostionWidth > 0 ? dataModel.yPostionWidth : MKLine.height)
            make.top.equalTo(5)
            make.bottom.equalTo(-5)
        }
        let tempValue = (maxValue - minValue) / 2
        valueMaxLabel.text = String(format: "%.1f", maxValue)
        valueMinLabel.text = String(format: "%.1f", minValue)
        maxLabel.text = String(format: "%.1f", maxValue + tempValue)
        minLabel.text = String(format: "%.1f", minValue - tempValue)
        aveLabel.text = String(format: "%.1f", minValue + tempValue)

        var tempViewWidth = curveViewWidth
        if pointList.count > maxPointCount {
            let space = curveViewWidth / CGFloat(maxPointCount)
            tempViewWidth = CGFloat(pointList.count / maxPointCount) * curveViewWidth
                + CGFloat(pointList.count % maxPointCount) * space
        }
        curveView.frame = CGRect(x: 0, y: 0, width: tempViewWidth, height: curveViewHeight)
        curveView.updatePointValues(pointList, maxValue: maxValue, minValue: minValue)
        if pointList.count <= maxPointCount {
            scrollView.contentSize = .zero
        } else {
            scrollView.contentSize = CGSize(width: tempViewWidth, height: 0)
        }
    }

    public func drawCurve(with pointList: [String], maxValue: CGFloat, minValue: CGFloat) {
        drawCurve(with: MKBXSTHCurveViewModel(),
                  pointList: pointList,
                  maxValue: maxValue,
                  minValue: minValue)
    }

    // MARK: - Private

    private func configParams(with model: MKBXSTHCurveViewModel) {
        backgroundColor = model.curveViewBackgroundColor
        curveView.lineColor = model.lineColor
        curveView.lineWidth = model.lineWidth > 0 ? model.lineWidth : 1
        curveView.backgroundColor = model.curveViewBackgroundColor
        titleLabel.textColor = model.titleColor
        titleLabel.font = model.titleFont
        titleLabel.text = model.curveTitle
        horizontalLine.backgroundColor = model.yPostionColor
        maxLabel.textColor = model.labelColor
        maxLabel.font = model.labelFont
        valueMaxLabel.textColor = model.labelColor
        valueMaxLabel.font = model.labelFont
        aveLabel.textColor = model.labelColor
        aveLabel.font = model.labelFont
        valueMinLabel.textColor = model.labelColor
        valueMinLabel.font = model.labelFont
        minLabel.textColor = model.labelColor
        minLabel.font = model.labelFont
    }

    private func loadLabel() -> UILabel {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .right
        label.font = MKFont.font(10)
        return label
    }

    private func loadLine() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(red: 136/255.0, green: 136/255.0, blue: 136/255.0, alpha: 1)
        return view
    }
}
