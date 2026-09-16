//
//  MKBXSFilterHistoryDataView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public protocol MKBXSFilterHistoryDataViewDelegate: AnyObject {
    func bxs_dateSelectedView_startPressed(_ startDate: String, endDate: String)
}

public final class MKBXSFilterHistoryDataView: UIView {

    public weak var delegate: MKBXSFilterHistoryDataViewDelegate?

    // MARK: - UI Components

    private lazy var topLine: UIView = {
        let view = UIView()
        view.backgroundColor = MKColor.defaultText
        return view
    }()

    private lazy var startLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(13)
        label.text = "Start Date:"
        return label
    }()

    private lazy var startDateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(11)
        return label
    }()

    private lazy var startDateButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "bxs_calendar.png"), for: .normal)
        btn.addTarget(self, action: #selector(startDateButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var endLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(13)
        label.text = "End Date:"
        return label
    }()

    private lazy var endDateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(11)
        return label
    }()

    private lazy var endDateButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "bxs_calendar.png"), for: .normal)
        btn.addTarget(self, action: #selector(endDateButtonPressed), for: .touchUpInside)
        return btn
    }()

    private lazy var startButton: UIButton = {
        let btn = MKSwiftUIAdaptor.createRoundedButton(title: "Start",
                                                       target: self,
                                                       action: #selector(startButtonPressed))
        btn.titleLabel?.font = MKFont.font(12)
        return btn
    }()

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return f
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(topLine)
        addSubview(startLabel)
        addSubview(startDateLabel)
        addSubview(startDateButton)
        addSubview(endLabel)
        addSubview(endDateLabel)
        addSubview(endDateButton)
        addSubview(startButton)

        let date = dateFormatter.string(from: Date())
        startDateLabel.text = date
        endDateLabel.text = date
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        topLine.snp.remakeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(MKLine.height)
        }

        startButton.snp.remakeConstraints { make in
            make.right.equalTo(-15)
            make.width.equalTo(80)
            make.centerY.equalToSuperview()
            make.height.equalTo(35)
        }

        startDateButton.snp.remakeConstraints { make in
            make.right.equalTo(startButton.snp.left).offset(-10)
            make.width.equalTo(25)
            make.top.equalTo(5)
            make.height.equalTo(25)
        }

        startLabel.snp.remakeConstraints { make in
            make.left.equalTo(0)
            make.width.equalTo(70)
            make.centerY.equalTo(startDateButton)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }

        startDateLabel.snp.remakeConstraints { make in
            make.left.equalTo(startLabel.snp.right).offset(2)
            make.right.equalTo(startDateButton.snp.left).offset(-2)
            make.centerY.equalTo(startDateButton)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }

        endDateButton.snp.remakeConstraints { make in
            make.right.equalTo(startButton.snp.left).offset(-10)
            make.width.equalTo(25)
            make.top.equalTo(startDateButton.snp.bottom).offset(10)
            make.height.equalTo(25)
        }

        endLabel.snp.remakeConstraints { make in
            make.left.equalTo(0)
            make.width.equalTo(70)
            make.centerY.equalTo(endDateButton)
            make.height.equalTo(MKFont.font(13).lineHeight)
        }

        endDateLabel.snp.remakeConstraints { make in
            make.left.equalTo(endLabel.snp.right).offset(2)
            make.right.equalTo(endDateButton.snp.left).offset(-2)
            make.centerY.equalTo(endDateButton)
            make.height.equalTo(MKFont.font(12).lineHeight)
        }
    }

    // MARK: - Events

    @objc private func startDateButtonPressed() {
        let date = dateFormatter.date(from: startDateLabel.text ?? "") ?? Date()
        MKSwiftDatePickerView.show(mode: .dateTimeWithSecond,
                                   maxDate: Date(),
                                   initialDate: date) { [weak self] selectDate in
            guard let self = self else { return }
            let value = self.dateFormatter.string(from: selectDate)
            self.startDateLabel.text = value
        }
    }

    @objc private func endDateButtonPressed() {
        let date = dateFormatter.date(from: endDateLabel.text ?? "") ?? Date()
        MKSwiftDatePickerView.show(mode: .dateTimeWithSecond,
                                   maxDate: Date(),
                                   initialDate: date) { [weak self] selectDate in
            guard let self = self else { return }
            let value = self.dateFormatter.string(from: selectDate)
            self.endDateLabel.text = value
        }
    }

    @objc private func startButtonPressed() {
        delegate?.bxs_dateSelectedView_startPressed(startDateLabel.text ?? "",
                                                    endDate: endDateLabel.text ?? "")
    }
}
