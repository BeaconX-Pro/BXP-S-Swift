//
//  MKSwiftDatePickerView.swift（扩展版）
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

@MainActor
public class MKSwiftDatePickerView: UIView {

    // MARK: - Public Types

    public enum DatePickerMode {
        case date
        case time
        case dateTime
        case dateTimeWithSecond
    }

    // MARK: - Public Methods

    /// 日期选择器
    public static func show(mode: DatePickerMode = .dateTime,
                            minDate: Date? = nil,
                            maxDate: Date? = nil,
                            initialDate: Date = Date(),
                            confirmHandler: @escaping (Date) -> Void) {
        let view = MKSwiftDatePickerView(mode: mode,
                                         minDate: minDate,
                                         maxDate: maxDate,
                                         initialDate: initialDate)
        view.confirmHandler = confirmHandler
        view.show()
    }

    /// 多列文本选择器（新增）
    /// - Parameters:
    ///   - title: 标题（可选，目前未使用，可保留）
    ///   - dataSource: 每列的字符串数组
    ///   - selectedIndexes: 每列初始选中项
    ///   - headerView: 顶部自定义 view（可选）
    ///   - confirmHandler: 点击确定回调，参数为当前每列选中的字符串
    public static func showMultiColumn(
        title: String? = nil,
        dataSource: [[String]],
        selectedIndexes: [Int],
        headerView: UIView? = nil,
        confirmHandler: @escaping ([String]) -> Void
    ) {
        let view = MKSwiftDatePickerView(dataSource: dataSource,
                                         selectedIndexes: selectedIndexes,
                                         headerView: headerView)
        view.multiConfirmHandler = confirmHandler
        view.show()
    }

    @objc public func dismiss() {
        UIView.animate(withDuration: animationDuration, animations: {
            self.bottomView.transform = .identity
        }) { _ in
            self.removeFromSuperview()
        }
    }

    // MARK: - Constants

    private let animationDuration: TimeInterval = 0.3
    private let bottomHeight: CGFloat = 270
    private let topBarHeight: CGFloat = 50

    // MARK: - Properties

    private let mode: DatePickerMode?
    private var confirmHandler: ((Date) -> Void)?
    private var multiConfirmHandler: (([String]) -> Void)?
    private var secondValue: Int = 0

    // 多列模式
    private var multiDataSource: [[String]] = []
    private var multiSelectedIndexes: [Int] = []

    // MARK: - UI Components

    private lazy var bottomView: UIView = {
        let view = UIView(frame: CGRect(x: 0,
                                        y: UIScreen.main.bounds.height,
                                        width: UIScreen.main.bounds.width,
                                        height: bottomHeight))
        view.backgroundColor = MKColor.rgb(244, 244, 244)
        view.layer.cornerRadius = 10
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let topView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: topBarHeight))
        topView.backgroundColor = .white
        view.addSubview(topView)

        let cancelButton = UIButton(type: .custom)
        cancelButton.frame = CGRect(x: 15, y: 10, width: 60, height: 30)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(MKColor.defaultText, for: .normal)
        cancelButton.titleLabel?.font = MKFont.font(16)
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        topView.addSubview(cancelButton)

        let confirmButton = UIButton(type: .custom)
        confirmButton.frame = CGRect(x: UIScreen.main.bounds.width - 80, y: 10, width: 70, height: 30)
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.setTitleColor(MKColor.navBar, for: .normal)
        confirmButton.titleLabel?.font = MKFont.font(16)
        confirmButton.addTarget(self, action: #selector(confirmButtonPressed), for: .touchUpInside)
        topView.addSubview(confirmButton)

        let separator = UIView(frame: CGRect(x: 0, y: topBarHeight - 0.5, width: UIScreen.main.bounds.width, height: 0.5))
        separator.backgroundColor = MKColor.fromHex(0xe8e8e8)
        topView.addSubview(separator)

        return view
    }()

    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.preferredDatePickerStyle = .wheels
        picker.locale = Locale(identifier: "zh_CN")
        picker.backgroundColor = .clear
        return picker
    }()

    private lazy var secondPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.backgroundColor = .clear
        return picker
    }()

    /// 多列选择器（新增）
    private lazy var multiPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self
        picker.delegate = self
        picker.backgroundColor = .clear
        return picker
    }()

    /// 自定义 headerView（新增）
    private var customHeaderView: UIView?

    /// 是否是多列模式
    private var isMultiMode: Bool { !multiDataSource.isEmpty }

    // MARK: - Initialization

    private init(mode: DatePickerMode, minDate: Date?, maxDate: Date?, initialDate: Date) {
        self.mode = mode
        super.init(frame: UIScreen.main.bounds)

        switch mode {
        case .date:
            datePicker.datePickerMode = .date
        case .time:
            datePicker.datePickerMode = .time
        case .dateTime:
            datePicker.datePickerMode = .dateAndTime
        case .dateTimeWithSecond:
            datePicker.datePickerMode = .dateAndTime
        }

        datePicker.minimumDate = minDate
        datePicker.maximumDate = maxDate
        datePicker.date = initialDate
        secondValue = Calendar.current.component(.second, from: initialDate)

        setupView()
    }

    /// 多列模式 init（新增）
    private init(dataSource: [[String]], selectedIndexes: [Int], headerView: UIView?) {
        self.mode = nil
        self.multiDataSource = dataSource
        self.multiSelectedIndexes = selectedIndexes
        self.customHeaderView = headerView
        super.init(frame: UIScreen.main.bounds)
        setupMultiView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Private Methods

    private func setupView() {
        backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(bottomView)
        bottomView.addSubview(datePicker)

        if mode == .dateTimeWithSecond {
            bottomView.addSubview(secondPicker)
            datePicker.frame = CGRect(x: 0,
                                      y: topBarHeight,
                                      width: UIScreen.main.bounds.width - 60,
                                      height: bottomHeight - topBarHeight)
            secondPicker.frame = CGRect(x: UIScreen.main.bounds.width - 60,
                                        y: topBarHeight,
                                        width: 60,
                                        height: bottomHeight - topBarHeight)
            secondPicker.selectRow(secondValue, inComponent: 0, animated: false)
        } else {
            datePicker.frame = CGRect(x: 10,
                                      y: topBarHeight,
                                      width: UIScreen.main.bounds.width - 20,
                                      height: bottomHeight - topBarHeight)
        }

        addTapGesture()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(dismiss),
                                               name: Notification.Name("mk_swift_dismissDatePickerView"),
                                               object: nil)
    }

    /// 多列模式布局（新增）
    private func setupMultiView() {
        backgroundColor = UIColor(white: 0, alpha: 0.5)
        addSubview(bottomView)

        // 自定义 headerView（放在 topBar 下面）
        var pickerTopY = topBarHeight
        if let headerView = customHeaderView {
            headerView.frame = CGRect(x: 0,
                                      y: topBarHeight,
                                      width: UIScreen.main.bounds.width,
                                      height: headerView.frame.height)
            bottomView.addSubview(headerView)
            pickerTopY += headerView.frame.height
        }

        bottomView.addSubview(multiPicker)
        multiPicker.frame = CGRect(x: 0,
                                   y: pickerTopY,
                                   width: UIScreen.main.bounds.width,
                                   height: bottomHeight - pickerTopY)

        // 设置初始选中项
        for (component, index) in multiSelectedIndexes.enumerated() where component < multiDataSource.count {
            let maxRow = max(0, multiDataSource[component].count - 1)
            let safeIndex = min(max(0, index), maxRow)
            multiPicker.selectRow(safeIndex, inComponent: component, animated: false)
        }

        addTapGesture()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(dismiss),
                                               name: Notification.Name("mk_swift_dismissDatePickerView"),
                                               object: nil)
    }

    private func addTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    private func show() {
        MKApp.window?.addSubview(self)
        layoutIfNeeded()
        UIView.animate(withDuration: animationDuration) {
            self.bottomView.transform = CGAffineTransform(translationX: 0, y: -self.bottomHeight)
        }
    }

    @objc private func cancelButtonPressed() {
        dismiss()
    }

    @objc private func confirmButtonPressed() {
        // 多列模式
        if isMultiMode {
            var selectedValues: [String] = []
            for component in 0..<multiDataSource.count {
                let row = multiPicker.selectedRow(inComponent: component)
                let value = multiDataSource[component][row]
                selectedValues.append(value)
            }
            multiConfirmHandler?(selectedValues)
            dismiss()
            return
        }

        // 日期模式
        var finalDate = datePicker.date
        if mode == .dateTimeWithSecond {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)
            components.second = secondValue
            if let composed = calendar.date(from: components) {
                finalDate = composed
            }
        }
        confirmHandler?(finalDate)
        dismiss()
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension MKSwiftDatePickerView: UIPickerViewDataSource, UIPickerViewDelegate {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView === multiPicker {
            return multiDataSource.count
        }
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView === multiPicker {
            guard component < multiDataSource.count else { return 0 }
            return multiDataSource[component].count
        }
        return 60   // 0 ~ 59
    }

    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        32
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === multiPicker {
            guard component < multiDataSource.count,
                  row < multiDataSource[component].count else { return nil }
            return multiDataSource[component][row]
        }
        return String(format: "%02d", row)
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === multiPicker {
            if component < multiSelectedIndexes.count {
                multiSelectedIndexes[component] = row
            }
            return
        }
        secondValue = row
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? {
            let l = UILabel()
            l.textAlignment = .center
            l.font = MKFont.font(21)
            l.textColor = MKColor.defaultText
            return l
        }()

        if pickerView === multiPicker {
            if component < multiDataSource.count,
               row < multiDataSource[component].count {
                label.text = multiDataSource[component][row]
            } else {
                label.text = ""
            }
        } else {
            label.text = String(format: "%02d", row)
        }
        return label
    }

    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if pickerView === multiPicker {
            return UIScreen.main.bounds.width / CGFloat(max(1, multiDataSource.count))
        }
        return 60
    }
}
