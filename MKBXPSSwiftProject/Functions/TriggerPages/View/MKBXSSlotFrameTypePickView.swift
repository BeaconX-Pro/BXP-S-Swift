//
//  MKBXSSlotFrameTypePickView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public protocol MKBXSSlotFrameTypePickViewDelegate: AnyObject {
    func bxs_slotFrameTypeChanged(_ frameType: MKBXSSlotType)
}

public final class MKBXSSlotFrameTypePickView: UIView {

    public weak var delegate: MKBXSSlotFrameTypePickViewDelegate?

    private var dataList = ["TLM", "UID", "URL", "iBeacon", "Sensor info", "No Data"]
    private var frameType: MKBXSSlotType = .tlm

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var leftIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_slotFrameType.png")
        return iv
    }()

    private lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(15)
        label.text = "Frame type"
        return label
    }()

    private lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.layer.masksToBounds = true
        picker.layer.borderColor = MKColor.navBar.cgColor
        picker.layer.borderWidth = 0.5
        picker.layer.cornerRadius = 4
        return picker
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(backView)
        backView.addSubview(leftIcon)
        backView.addSubview(typeLabel)
        backView.addSubview(pickerView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()
        backView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        leftIcon.snp.makeConstraints { make in
            make.left.equalTo(15)
            make.width.height.equalTo(22)
            make.centerY.equalTo(backView)
        }
        typeLabel.snp.makeConstraints { make in
            make.left.equalTo(leftIcon.snp.right).offset(15)
            make.width.equalTo(100)
            make.centerY.equalTo(backView)
            make.height.equalTo(MKFont.font(15).lineHeight)
        }
        pickerView.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(100)
            make.top.equalTo(10)
            make.bottom.equalTo(-10)
        }
    }

    public func updateFrameType(_ frameType: MKBXSSlotType) {
        guard !dataList.isEmpty else { return }
        pickerView.reloadAllComponents()
        self.frameType = frameType
        pickerView.selectRow(frameType.rawValue, inComponent: 0, animated: true)
    }
}

extension MKBXSSlotFrameTypePickView: UIPickerViewDataSource, UIPickerViewDelegate {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { dataList.count }
    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 30 }
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let titleLabel = (view as? UILabel) ?? {
            let label = UILabel()
            label.textColor = MKColor.defaultText
            label.adjustsFontSizeToFitWidth = true
            label.textAlignment = .center
            label.font = MKFont.font(12)
            return label
        }()
        if row == frameType.rawValue {
            titleLabel.attributedText = MKSwiftUIAdaptor.createAttributedString(
                strings: [dataList[row]],
                fonts: [MKFont.font(13)],
                colors: [MKColor.navBar]
            )
        } else {
            titleLabel.text = dataList[row]
        }
        return titleLabel
    }
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        frameType = MKBXSSlotType(rawValue: row) ?? .tlm
        pickerView.reloadAllComponents()
        delegate?.bxs_slotFrameTypeChanged(frameType)
    }
}
