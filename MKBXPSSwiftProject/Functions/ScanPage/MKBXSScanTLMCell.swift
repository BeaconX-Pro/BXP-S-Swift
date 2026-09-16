//
//  MKBXSScanTLMCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBeaconXCustomUI

public final class MKBXSScanTLMCellModel: MKSwiftBXScanBaseModel {
    public var version: String = ""
    public var mvPerbit: Int = 0
    public var temperature: String = ""
    public var advertiseCount: String = ""
    public var deciSecondsSinceBoot: String = ""
    
    public nonisolated override init() { super.init() }
}

public final class MKBXSScanTLMCell: MKSwiftBaseCell {

    public var dataModel: MKBXSScanTLMCellModel? {
        didSet { updateContent() }
    }

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSScanTLMCell {
        let identifier = "MKBXSScanTLMCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSScanTLMCell {
            return cell
        }
        return MKBXSScanTLMCell(style: .default, reuseIdentifier: identifier)
    }

    private let offsetX: CGFloat = 10
    private let offsetY: CGFloat = 10
    private let leftIconWidth: CGFloat = 7
    private let leftIconHeight: CGFloat = 7
    private let msgFont = MKFont.font(12)

    private lazy var leftIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_littleBluePoint.png")
        return iv
    }()

    private lazy var typeLabel: UILabel = {
        let label = createLabel(font: MKFont.font(15), text: "Unencrypted TLM")
        label.textColor = MKColor.defaultText
        return label
    }()

    private lazy var batteryMsgLabel: UILabel = createLabel(font: msgFont, text: "Battery level")
    private lazy var batteryLabel: UILabel = createLabel(font: msgFont, text: "0mV")
    private lazy var temperMsgLabel: UILabel = createLabel(font: msgFont, text: "Chip temperature")
    private lazy var temperatureLabel: UILabel = createLabel(font: msgFont, text: "0°C")
    private lazy var advLabel: UILabel = createLabel(font: msgFont, text: "ADV count")
    private lazy var advValueLabel: UILabel = createLabel(font: msgFont, text: "0")
    private lazy var timeSinceLabel: UILabel = createLabel(font: msgFont, text: "Running time")
    private lazy var timeLabel: UILabel = createLabel(font: msgFont, text: "0s")

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(leftIcon)
        contentView.addSubview(typeLabel)
        contentView.addSubview(batteryMsgLabel)
        contentView.addSubview(batteryLabel)
        contentView.addSubview(temperMsgLabel)
        contentView.addSubview(temperatureLabel)
        contentView.addSubview(advLabel)
        contentView.addSubview(advValueLabel)
        contentView.addSubview(timeSinceLabel)
        contentView.addSubview(timeLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        leftIcon.snp.makeConstraints { make in
            make.left.equalTo(offsetX)
            make.width.equalTo(leftIconWidth)
            make.top.equalTo(offsetY)
            make.height.equalTo(leftIconHeight)
        }
        typeLabel.snp.makeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(5)
            make.right.equalTo(-offsetX)
            make.centerY.equalTo(leftIcon)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        batteryMsgLabel.snp.makeConstraints { make in
            make.left.equalTo(typeLabel)
            make.width.equalTo(120)
            make.top.equalTo(typeLabel.snp.bottom).offset(5)
            make.height.equalTo(msgFont.lineHeight)
        }
        batteryLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryMsgLabel.snp.right).offset(10)
            make.right.equalTo(-offsetX)
            make.centerY.equalTo(batteryMsgLabel)
            make.height.equalTo(msgFont.lineHeight)
        }
        temperMsgLabel.snp.makeConstraints { make in
            make.left.width.equalTo(batteryMsgLabel)
            make.top.equalTo(batteryMsgLabel.snp.bottom).offset(5)
            make.height.equalTo(msgFont.lineHeight)
        }
        temperatureLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryLabel)
            make.right.equalTo(-offsetX)
            make.centerY.equalTo(temperMsgLabel)
            make.height.equalTo(msgFont.lineHeight)
        }
        advLabel.snp.makeConstraints { make in
            make.left.width.equalTo(batteryMsgLabel)
            make.top.equalTo(temperMsgLabel.snp.bottom).offset(5)
            make.height.equalTo(msgFont.lineHeight)
        }
        advValueLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryLabel)
            make.right.equalTo(-offsetX)
            make.centerY.equalTo(advLabel)
            make.height.equalTo(msgFont.lineHeight)
        }
        timeSinceLabel.snp.makeConstraints { make in
            make.left.width.equalTo(batteryMsgLabel)
            make.top.equalTo(advLabel.snp.bottom).offset(5)
            make.height.equalTo(msgFont.lineHeight)
        }
        timeLabel.snp.makeConstraints { make in
            make.left.equalTo(batteryLabel)
            make.right.equalTo(-offsetX)
            make.centerY.equalTo(timeSinceLabel)
            make.height.equalTo(msgFont.lineHeight)
        }
    }

    private func updateContent() {
        guard let model = dataModel else { return }
        if model.mvPerbit <= 100 {
            batteryLabel.text = "\(model.mvPerbit)%"
        } else {
            batteryLabel.text = "\(model.mvPerbit)mV"
        }
        let temp = String(format: "%.1f", Float(model.temperature) ?? 0)
        temperatureLabel.text = "\(temp)°C"
        advValueLabel.text = model.advertiseCount
        timeLabel.text = getTimeWithSec(Float(model.deciSecondsSinceBoot) ?? 0)
    }

    private func getTimeWithSec(_ second: Float) -> String {
        var minutes = floor(second / 60)
        let sec = second - minutes * 60
        var hours1 = floor(second / (60 * 60))
        minutes -= hours1 * 60
        let day = floor(hours1 / 24)
        hours1 -= 24 * day
        return String(format: "%dd%dh%dm%.1fs", Int(day), Int(hours1), Int(minutes), sec)
    }

    private func createLabel(font: UIFont, text: String? = nil) -> UILabel {
        let label = UILabel()
        label.textColor = UIColor(red: 184/255.0, green: 184/255.0, blue: 184/255.0, alpha: 1)
        label.textAlignment = .left
        label.font = font
        label.text = text
        return label
    }
}
