//
//  MKBXSScanDeviceInfoCell.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import CoreBluetooth

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public protocol MKBXSScanDeviceInfoCellDelegate: AnyObject {
    func mk_bxs_connectPeripheral(_ dataModel: MKBXSScanInfoCellModel)
}

public final class MKBXSScanDeviceInfoCell: MKSwiftBaseCell {

    public var dataModel: MKBXSScanInfoCellModel? {
        didSet { updateContent() }
    }
    public weak var delegate: MKBXSScanDeviceInfoCellDelegate?

    public class func initCellWithTableView(_ tableView: UITableView) -> MKBXSScanDeviceInfoCell {
        let identifier = "MKBXSScanDeviceInfoCellIdenty"
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MKBXSScanDeviceInfoCell {
            return cell
        }
        return MKBXSScanDeviceInfoCell(style: .default, reuseIdentifier: identifier)
    }

    private let offsetX: CGFloat = 15
    private let rssiIconWidth: CGFloat = 22
    private let rssiIconHeight: CGFloat = 11
    private let connectButtonWidth: CGFloat = 80
    private let connectButtonHeight: CGFloat = 30
    private let batteryIconWidth: CGFloat = 25
    private let batteryIconHeight: CGFloat = 25

    private lazy var rssiIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_signalIcon.png")
        return iv
    }()

    private lazy var rssiLabel: UILabel = {
        let l = createLabel(font: MKFont.font(10))
        l.textAlignment = .center
        return l
    }()

    private lazy var nameLabel: UILabel = {
        let l = createLabel(font: MKFont.font(15))
        l.textColor = MKColor.defaultText
        l.numberOfLines = 0
        return l
    }()

    private lazy var connectButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = MKColor.navBar
        btn.setTitle("CONNECT", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = MKFont.font(15)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(connectButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var batteryIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_batteryHighest.png")
        return iv
    }()

    private lazy var batteryLabel: UILabel = {
        let l = createLabel(font: MKFont.font(10))
        l.textAlignment = .center
        return l
    }()

    private lazy var devieIDLabel: UILabel = createLabel(font: MKFont.font(12))
    private lazy var macLabel: UILabel = createLabel(font: MKFont.font(12))

    private lazy var timeLabel: UILabel = {
        let l = createLabel(font: MKFont.font(10))
        l.textAlignment = .center
        return l
    }()

    private lazy var topBackView = UIView()
    private lazy var centerBackView = UIView()
    private lazy var bottomBackView = UIView()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(topBackView)
        contentView.addSubview(centerBackView)
        contentView.addSubview(bottomBackView)

        topBackView.addSubview(rssiIcon)
        topBackView.addSubview(rssiLabel)
        topBackView.addSubview(nameLabel)
        topBackView.addSubview(connectButton)

        centerBackView.addSubview(batteryIcon)

        bottomBackView.addSubview(devieIDLabel)
        bottomBackView.addSubview(macLabel)
        bottomBackView.addSubview(batteryLabel)
        bottomBackView.addSubview(timeLabel)

        layer.masksToBounds = true
        layer.cornerRadius = 4
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        topBackView.snp.remakeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(40)
        }
        rssiIcon.snp.remakeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(10)
            make.width.equalTo(rssiIconWidth)
            make.height.equalTo(rssiIconHeight)
        }
        rssiLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(rssiIcon)
            make.width.equalTo(40)
            make.top.equalTo(rssiIcon.snp.bottom).offset(5)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        let nameWidth = contentView.frame.width - 2 * offsetX - rssiIconWidth - 10 - 8 - connectButtonWidth
        let nameSize = (nameLabel.text ?? "").size(withFont: nameLabel.font, maxSize: CGSize(width: nameWidth, height: .greatestFiniteMagnitude))
        nameLabel.snp.remakeConstraints { make in
            make.left.equalTo(rssiIcon.snp.right).offset(20)
            make.centerY.equalTo(rssiIcon)
            make.right.equalTo(connectButton.snp.left).offset(-8)
            make.height.equalTo(nameSize.height)
        }
        connectButton.snp.remakeConstraints { make in
            make.right.equalTo(-offsetX)
            make.width.equalTo(connectButtonWidth)
            make.centerY.equalTo(topBackView)
            make.height.equalTo(connectButtonHeight)
        }
        centerBackView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topBackView.snp.bottom)
            make.height.equalTo(batteryIconHeight)
        }
        batteryIcon.snp.remakeConstraints { make in
            make.left.equalTo(offsetX)
            make.width.equalTo(batteryIconWidth)
            make.centerY.equalTo(centerBackView)
            make.height.equalTo(batteryIconHeight)
        }
        macLabel.snp.remakeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalTo(timeLabel.snp.left).offset(-5)
            make.bottom.equalTo(batteryIcon.snp.centerY).offset(2)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        devieIDLabel.snp.remakeConstraints { make in
            make.left.equalTo(nameLabel)
            make.right.equalTo(timeLabel.snp.left).offset(-5)
            make.top.equalTo(batteryIcon.snp.centerY).offset(2)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
        timeLabel.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(70)
            make.centerY.equalTo(devieIDLabel)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        bottomBackView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(centerBackView.snp.bottom)
            make.bottom.equalToSuperview()
        }
        batteryLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(batteryIcon)
            make.width.equalTo(45)
            make.top.equalTo(3)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
    }

    @objc private func connectButtonPressed() {
        guard (dataModel?.peripheral) != nil else { return }
        if let model = dataModel {
            delegate?.mk_bxs_connectPeripheral(model)
        }
    }

    private func updateContent() {
        guard let model = dataModel else { return }
        connectButton.isHidden = !model.connectEnable
        timeLabel.text = model.displayTime
        rssiLabel.text = "\(model.rssi)dBm"
        nameLabel.text = model.deviceName.isEmpty ? "N/A" : model.deviceName

        if model.battery.isEmpty {
            batteryLabel.text = "N/A"
        } else {
            let battery = Int(model.battery) ?? 0
            if battery <= 100 {
                batteryLabel.text = "\(model.battery)%"
            } else {
                batteryLabel.text = "\(model.battery)mV"
            }
        }
        devieIDLabel.text = model.tagID.isEmpty ? "" : "Tag ID:0x\(model.tagID)"
        macLabel.text = model.macAddress.isEmpty ? "" : "MAC: \(model.macAddress)"
        setNeedsLayout()
    }

    private func createLabel(font: UIFont) -> UILabel {
        let label = UILabel()
        label.textColor = UIColor(red: 184/255.0, green: 184/255.0, blue: 184/255.0, alpha: 1)
        label.textAlignment = .left
        label.font = font
        return label
    }
}
