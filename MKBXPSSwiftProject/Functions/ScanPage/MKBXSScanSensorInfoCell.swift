//
//  MKBXSScanSensorInfoCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBeaconXCustomUI

public final class MKBXSScanSensorInfoCellModel: MKSwiftBXScanBaseModel {
    public var magneticStatus: Bool = false
    public var magneticCount: String = ""
    public var triaxialSensor: Bool = false
    public var motionStatus: Bool = false
    public var motionCount: String = ""
    public var xData: String = ""
    public var yData: String = ""
    public var zData: String = ""
    public var supportTemp: Bool = false
    public var temperature: String = ""
    public var supportHumidity: Bool = false
    public var humidity: String = ""

    public nonisolated override init() { super.init() }

    public func fetchCellHeight() -> CGFloat {
        if triaxialSensor {
            if supportTemp && supportHumidity { return 170 }
            if (supportTemp && !supportHumidity) || (!supportTemp && supportHumidity) { return 155 }
            return 130
        }
        if supportTemp && supportHumidity { return 110 }
        if (supportTemp && !supportHumidity) || (!supportTemp && supportHumidity) { return 115 }
        return 70
    }
}

public final class MKBXSScanSensorInfoCell: MKSwiftBaseCell {

    public var dataModel: MKBXSScanSensorInfoCellModel? {
        didSet { updateContent() }
    }

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSScanSensorInfoCell {
        let identifier = "MKBXSScanSensorInfoCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSScanSensorInfoCell {
            return cell
        }
        return MKBXSScanSensorInfoCell(style: .default, reuseIdentifier: identifier)
    }

    private lazy var icon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_littleBluePoint.png")
        return iv
    }()

    private lazy var msgLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(15)
        label.text = "Sensor info"
        return label
    }()

    private lazy var msLabel: UILabel = { let l = createLabel(); l.text = "Door magnetic status"; return l }()
    private lazy var msValueLabel: UILabel = createLabel()
    private lazy var mtcLabel: UILabel = { let l = createLabel(); l.text = "Magnetic trigger count"; return l }()
    private lazy var mtcValueLabel: UILabel = createLabel()
    private lazy var mosLabel: UILabel = { let l = createLabel(); l.text = "Motion status"; return l }()
    private lazy var mosValueLabel: UILabel = createLabel()
    private lazy var motcLabel: UILabel = { let l = createLabel(); l.text = "Motion trigger count"; return l }()
    private lazy var motcValueLabel: UILabel = createLabel()
    private lazy var accLabel: UILabel = { let l = createLabel(); l.text = "Acceleration"; return l }()
    private lazy var accValueLabel: UILabel = createLabel()
    private lazy var tempLabel: UILabel = { let l = createLabel(); l.text = "Temperature"; return l }()
    private lazy var tempValueLabel: UILabel = createLabel()
    private lazy var humidityLabel: UILabel = { let l = createLabel(); l.text = "Humidity"; return l }()
    private lazy var humidityValueLabel: UILabel = createLabel()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(icon)
        contentView.addSubview(msgLabel)
        contentView.addSubview(msLabel)
        contentView.addSubview(msValueLabel)
        contentView.addSubview(mtcLabel)
        contentView.addSubview(mtcValueLabel)
        contentView.addSubview(humidityLabel)
        contentView.addSubview(humidityValueLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        icon.snp.remakeConstraints { make in
            make.left.equalTo(15)
            make.width.height.equalTo(7)
            make.centerY.equalTo(msgLabel)
        }
        msgLabel.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(2)
            make.right.equalTo(-10)
            make.top.equalTo(10)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        msLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(msgLabel.snp.bottom).offset(5)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        msValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalTo(-15)
            make.centerY.equalTo(msLabel)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        mtcLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(msLabel.snp.bottom).offset(5)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        mtcValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalTo(-15)
            make.centerY.equalTo(mtcLabel)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }

    private func updateContent() {
        guard let model = dataModel else { return }
        msValueLabel.text = model.magneticStatus ? "Open" : "Closed"
        mtcValueLabel.text = model.magneticCount
        setupTriaxialSensor()
        setupTemperatureSensor()
        setupHumiditySensor()
    }

    private func setupTriaxialSensor() {
        [mosLabel, mosValueLabel, motcLabel, motcValueLabel, accLabel, accValueLabel].forEach { $0.removeFromSuperview() }
        guard dataModel?.triaxialSensor == true else { return }
        contentView.addSubview(mosLabel)
        contentView.addSubview(mosValueLabel)
        contentView.addSubview(motcLabel)
        contentView.addSubview(motcValueLabel)
        contentView.addSubview(accLabel)
        contentView.addSubview(accValueLabel)

        mosLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(mtcLabel.snp.bottom).offset(5)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        mosValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalTo(-15)
            make.centerY.equalTo(mosLabel)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        motcLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(mosLabel.snp.bottom).offset(5)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        motcValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalTo(-15)
            make.centerY.equalTo(motcLabel)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        accLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(motcLabel.snp.bottom).offset(5)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        accValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalTo(-15)
            make.centerY.equalTo(accLabel)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        mosValueLabel.text = (dataModel?.motionStatus == true) ? "Moving" : "Stationary"
        motcValueLabel.text = dataModel?.motionCount
        accValueLabel.text = "X: \(dataModel?.xData ?? "")mg;Y: \(dataModel?.yData ?? "")mg;Z: \(dataModel?.zData ?? "")mg"
    }

    private func setupTemperatureSensor() {
        [tempLabel, tempValueLabel].forEach { $0.removeFromSuperview() }
        guard dataModel?.supportTemp == true else { return }
        contentView.addSubview(tempLabel)
        contentView.addSubview(tempValueLabel)
        tempValueLabel.text = "\(dataModel?.temperature ?? "")℃"

        let topAnchor = (dataModel?.triaxialSensor == true) ? accLabel.snp.bottom : mtcLabel.snp.bottom
        tempLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(topAnchor).offset(5)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        tempValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalTo(-15)
            make.centerY.equalTo(tempLabel)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }

    private func setupHumiditySensor() {
        [humidityLabel, humidityValueLabel].forEach { $0.removeFromSuperview() }
        guard dataModel?.supportHumidity == true else { return }
        contentView.addSubview(humidityLabel)
        contentView.addSubview(humidityValueLabel)
        humidityValueLabel.text = "\(dataModel?.humidity ?? "")%RH"

        let topAnchor: ConstraintItem
        if dataModel?.supportTemp == true {
            topAnchor = tempLabel.snp.bottom
        } else if dataModel?.triaxialSensor == true {
            topAnchor = accLabel.snp.bottom
        } else {
            topAnchor = mtcLabel.snp.bottom
        }
        humidityLabel.snp.remakeConstraints { make in
            make.left.equalTo(msgLabel)
            make.right.equalTo(contentView.snp.centerX).offset(-2)
            make.top.equalTo(topAnchor).offset(5)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        humidityValueLabel.snp.remakeConstraints { make in
            make.left.equalTo(contentView.snp.centerX)
            make.right.equalTo(-15)
            make.centerY.equalTo(humidityLabel)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }

    private func createLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor(red: 184/255.0, green: 184/255.0, blue: 184/255.0, alpha: 1)
        label.textAlignment = .left
        label.font = MKFont.font(10)
        return label
    }
}
