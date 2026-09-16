//
//  MKBXSTempAlertThresholdCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSTempAlertThresholdCellModel: NSObject {
    public var isOn: Bool = false
    public var maxTemperature: String = ""
    public var minTemperature: String = ""
    public var count: String = ""
    public override init() { super.init() }
}

public protocol MKBXSTempAlertThresholdCellDelegate: AnyObject {
    func bxs_tempAlertThresholdCell_thresholdStatusChanged(_ isOn: Bool)
    func bxs_tempAlertThresholdCell_temperatureChanged(_ maxTemperature: String, minTemperature: String)
    func bxs_tempAlertThresholdCell_tempAlertStatusClear()
}

public final class MKBXSTempAlertThresholdCell: MKSwiftBaseCell {

    public var dataModel: MKBXSTempAlertThresholdCellModel? {
        didSet { updateContent() }
    }

    public weak var delegate: MKBXSTempAlertThresholdCellDelegate?

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSTempAlertThresholdCell {
        let identifier = "MKBXSTempAlertThresholdCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSTempAlertThresholdCell {
            return cell
        }
        return MKBXSTempAlertThresholdCell(style: .default, reuseIdentifier: identifier)
    }

    // MARK: - UI

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()

    private lazy var thresholdLabel: UILabel = {
        let label = MKSwiftUIAdaptor.createNormalLabel(text: "Temp alert threshold")
        label.font = MKFont.font(15)
        label.textColor = MKColor.defaultText
        return label
    }()

    private lazy var thresholdBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "bxs_calbxs_switchUnselectedIconendar.png"), for: .normal)
        btn.addTarget(self, action: #selector(thresholdBtnPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var temperatureLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(13)
        label.text = "0.0℃ ~ 0.0℃"
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(temperatureLabelPressed)))
        return label
    }()

    private lazy var statusMsgLabel: UILabel = {
        let label = MKSwiftUIAdaptor.createNormalLabel(text: "Temp alert status")
        label.font = MKFont.font(15)
        label.textColor = MKColor.defaultText
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = .green
        label.textAlignment = .left
        label.font = MKFont.font(13)
        label.text = "Normal"
        return label
    }()

    private lazy var clearBtn: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Clear",
                                                    target: self,
                                                    action: #selector(clearBtnPressed))
    }()

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(backView)
        backView.addSubview(thresholdLabel)
        backView.addSubview(thresholdBtn)
        backView.addSubview(temperatureLabel)
        backView.addSubview(statusMsgLabel)
        backView.addSubview(statusLabel)
        backView.addSubview(clearBtn)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        backView.snp.remakeConstraints { make in
            make.edges.equalTo(contentView)
        }
        thresholdLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(thresholdBtn.snp.left).offset(-15)
            make.centerY.equalTo(thresholdBtn)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        thresholdBtn.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.top.equalTo(10)
            make.width.equalTo(40)
            make.height.equalTo(30)
        }
        temperatureLabel.snp.remakeConstraints { make in
            make.left.equalTo(thresholdLabel).offset(10)
            make.right.equalTo(thresholdLabel).offset(-10)
            make.top.equalTo(thresholdBtn.snp.bottom).offset(10)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
        statusMsgLabel.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.right.equalTo(statusLabel.snp.left).offset(-10)
            make.centerY.equalTo(clearBtn)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        clearBtn.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(40)
            make.top.equalTo(temperatureLabel.snp.bottom).offset(10)
            make.height.equalTo(30)
        }
        statusLabel.snp.remakeConstraints { make in
            make.right.equalTo(clearBtn.snp.left).offset(-10)
            make.width.equalTo(70)
            make.centerY.equalTo(clearBtn)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }
    }

    // MARK: - Content

    private func updateContent() {
        guard let model = dataModel else { return }
        thresholdBtn.isSelected = model.isOn
        let iconName = thresholdBtn.isSelected ? "bxs_switchSelectedIcon.png" : "bxs_switchUnselectedIcon.png"
        thresholdBtn.setImage(UIImage(named: iconName), for: .normal)

        let minTemp = model.minTemperature.isEmpty ? "0.0" : model.minTemperature
        let maxTemp = model.maxTemperature.isEmpty ? "0.0" : model.maxTemperature
        temperatureLabel.text = "\(minTemp)℃ ~ \(maxTemp)℃"

        if !model.count.isEmpty, (Int(model.count) ?? 0) > 0 {
            statusLabel.text = "Alert"
            statusLabel.textColor = .red
        } else {
            statusLabel.text = "Normal"
            statusLabel.textColor = .green
        }
    }

    // MARK: - Events

    @objc private func thresholdBtnPressed() {
        thresholdBtn.isSelected.toggle()
        let iconName = thresholdBtn.isSelected ? "bxs_switchSelectedIcon.png" : "bxs_switchUnselectedIcon.png"
        thresholdBtn.setImage(UIImage(named: iconName), for: .normal)
        delegate?.bxs_tempAlertThresholdCell_thresholdStatusChanged(thresholdBtn.isSelected)
    }

    @objc private func temperatureLabelPressed() {
        showTemperaturePicker()
    }

    @objc private func clearBtnPressed() {
        delegate?.bxs_tempAlertThresholdCell_tempAlertStatusClear()
    }

    // MARK: - Picker

    private func showTemperaturePicker() {
        // 1. 解析当前 min/max 温度
        var minInteger = 0
        var minDecimal = 0
        var maxInteger = 0
        var maxDecimal = 0

        if let minTempStr = dataModel?.minTemperature, !minTempStr.isEmpty,
           let minTemp = Float(minTempStr) {
            minInteger = Int(minTemp)
            minDecimal = Int((abs(minTemp - Float(minInteger)) * 10 + 0.5).rounded())
            if minDecimal == 10 {
                minDecimal = 0
                minInteger += (minInteger >= 0 ? 1 : -1)
            }
        }

        if let maxTempStr = dataModel?.maxTemperature, !maxTempStr.isEmpty,
           let maxTemp = Float(maxTempStr) {
            maxInteger = Int(maxTemp)
            maxDecimal = Int((abs(maxTemp - Float(maxInteger)) * 10 + 0.5).rounded())
            if maxDecimal == 10 {
                maxDecimal = 0
                maxInteger += (maxInteger >= 0 ? 1 : -1)
            }
        }

        // 2. 数据源
        var integerValues: [String] = []
        for i in -40...85 { integerValues.append("\(i)") }

        var decimalValues: [String] = []
        for i in 0...9 { decimalValues.append("\(i)") }

        // 3. 初始选中索引
        let minIntegerIndex = integerValues.firstIndex(of: "\(minInteger)") ?? 40
        let maxIntegerIndex = integerValues.firstIndex(of: "\(maxInteger)") ?? 40

        // 4. 自定义 header
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: MKScreen.width, height: 40))
        headerView.backgroundColor = .white

        let lineView = UIView(frame: CGRect(x: 0, y: 39, width: MKScreen.width, height: 1))
        lineView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        headerView.addSubview(lineView)

        let lowLabel = UILabel(frame: CGRect(x: 0, y: 0, width: MKScreen.width / 2, height: 39))
        lowLabel.text = "Low temp threshold"
        lowLabel.textColor = .darkGray
        lowLabel.font = .systemFont(ofSize: 14)
        lowLabel.textAlignment = .center
        headerView.addSubview(lowLabel)

        let highLabel = UILabel(frame: CGRect(x: MKScreen.width / 2, y: 0, width: MKScreen.width / 2, height: 39))
        highLabel.text = "High temp threshold"
        highLabel.textColor = .darkGray
        highLabel.font = .systemFont(ofSize: 14)
        highLabel.textAlignment = .center
        headerView.addSubview(highLabel)

        // 5. 显示多列选择器
        MKSwiftDatePickerView.showMultiColumn(
            title: "Temperature Threshold",
            dataSource: [integerValues, decimalValues, integerValues, decimalValues],
            selectedIndexes: [minIntegerIndex, minDecimal, maxIntegerIndex, maxDecimal],
            headerView: headerView
        ) { [weak self] selectedValues in
            guard let self = self, selectedValues.count >= 4 else { return }

            let minIntegerStr = selectedValues[0]
            let minDecimalStr = selectedValues[1]
            let maxIntegerStr = selectedValues[2]
            let maxDecimalStr = selectedValues[3]

            // 负数时小数部分取负
            let minIntegerValue = Float(minIntegerStr) ?? 0
            var minDecimalValue = (Float(minDecimalStr) ?? 0) / 10.0
            if minIntegerValue < 0 { minDecimalValue = -minDecimalValue }
            var minTemp = minIntegerValue + minDecimalValue

            let maxIntegerValue = Float(maxIntegerStr) ?? 0
            var maxDecimalValue = (Float(maxDecimalStr) ?? 0) / 10.0
            if maxIntegerValue < 0 { maxDecimalValue = -maxDecimalValue }
            var maxTemp = maxIntegerValue + maxDecimalValue

            // 确保 min <= max
            if minTemp > maxTemp {
                swap(&minTemp, &maxTemp)
            }

            let minTempStr = String(format: "%.1f", minTemp)
            let maxTempStr = String(format: "%.1f", maxTemp)

            self.temperatureLabel.text = "\(minTempStr)℃ ~ \(maxTempStr)℃"
            self.dataModel?.minTemperature = minTempStr
            self.dataModel?.maxTemperature = maxTempStr

            self.delegate?.bxs_tempAlertThresholdCell_temperatureChanged(maxTempStr,
                                                                         minTemperature: minTempStr)
        }
    }
}
