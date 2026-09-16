//
//  MKBXSScanFilterView.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSScanFilterView: UIView {

    // MARK: - Constants

    private let offsetX: CGFloat = 10
    private let backViewHeight: CGFloat = 370
    private let signalIconWidth: CGFloat = 17
    private let signalIconHeight: CGFloat = 15
    private let noteMsg1 = "* RSSI filtering is the highest priority filtering condition. BLE Name filtering must first meet the RSSI filtering condition."

    // MARK: - Properties

    private var searchBlock: ((String, String, Int) -> Void)?

    // MARK: - UI

    private lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var nameLabel: UILabel = createLabel(text: "BLE Name")
    private lazy var nameTextField: MKSwiftTextField = createTextField(placeholder: "1-20 characters", maxLength: 20)
    private lazy var tagLabel: UILabel = createLabel(text: "Tag ID")
    private lazy var tagTextField: MKSwiftTextField = createTextField(placeholder: "1-6 Bytes", maxLength: 12)
    private lazy var minRssiLabel: UILabel = createLabel(text: "Min. RSSI")

    private lazy var rssiValueLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(14)
        label.text = "-100dBm"
        return label
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = MKColor.defaultText
        return view
    }()

    private lazy var signalIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_wifiSignalIcon.png")
        return iv
    }()

    private lazy var graySignalIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_wifiGraySignalIcon.png")
        return iv
    }()

    private lazy var slider: UISlider = {
        let slider = UISlider()
        slider.maximumValue = 0
        slider.minimumValue = -100
        slider.value = -100
        slider.addTarget(self, action: #selector(rssiValueChanged), for: .valueChanged)
        return slider
    }()

    private lazy var maxLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 15/255.0, green: 131/255.0, blue: 255/255.0, alpha: 1)
        label.textAlignment = .left
        label.font = MKFont.font(11)
        label.text = "0dBm"
        return label
    }()

    private lazy var minLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.textAlignment = .left
        label.font = MKFont.font(11)
        label.text = "-100dBm"
        return label
    }()

    private lazy var noteLabel1: UILabel = {
        let label = UILabel()
        label.textColor = .orange
        label.font = MKFont.font(11)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.text = noteMsg1
        return label
    }()

    private lazy var doneButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Apply",
                                                    target: self,
                                                    action: #selector(doneButtonPressed))
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0, alpha: 0.1)
        addSubview(backView)
        backView.addSubview(nameLabel)
        backView.addSubview(nameTextField)
        backView.addSubview(tagLabel)
        backView.addSubview(tagTextField)
        backView.addSubview(minRssiLabel)
        backView.addSubview(rssiValueLabel)
        rssiValueLabel.addSubview(lineView)
        backView.addSubview(signalIcon)
        backView.addSubview(graySignalIcon)
        backView.addSubview(slider)
        backView.addSubview(minLabel)
        backView.addSubview(maxLabel)
        backView.addSubview(noteLabel1)
        backView.addSubview(doneButton)
        addTapGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let backViewWidth = backView.frame.width > 0 ? backView.frame.width : (MKScreen.width - 2 * offsetX)
        let textFieldPostionX = offsetX + 100 + 5
        let textFieldWidth = backViewWidth - textFieldPostionX - offsetX
        let nameLabelPostionY: CGFloat = 10
        let tagLabelPostionY = nameLabelPostionY + 30 + 10
        let textSpaceY: CGFloat = 40
        let singalIconPostionY = tagLabelPostionY + textSpaceY + 25 + 30

        nameLabel.frame = CGRect(x: offsetX, y: nameLabelPostionY, width: 100, height: 30)
        nameTextField.frame = CGRect(x: textFieldPostionX, y: nameLabelPostionY, width: textFieldWidth, height: 30)
        tagLabel.frame = CGRect(x: offsetX, y: tagLabelPostionY, width: 100, height: 30)
        tagTextField.frame = CGRect(x: textFieldPostionX, y: tagLabelPostionY, width: textFieldWidth, height: 30)
        minRssiLabel.frame = CGRect(x: offsetX, y: tagLabelPostionY + textSpaceY, width: 100, height: 25)
        rssiValueLabel.frame = CGRect(x: textFieldPostionX, y: tagLabelPostionY + textSpaceY, width: textFieldWidth, height: 25)
        lineView.frame = CGRect(x: 0, y: 24.5, width: textFieldWidth, height: 0.5)
        signalIcon.frame = CGRect(x: offsetX, y: singalIconPostionY, width: signalIconWidth, height: signalIconHeight)
        let sliderX = offsetX + signalIconWidth + 10
        slider.frame = CGRect(x: sliderX, y: singalIconPostionY, width: backViewWidth - 2 * sliderX, height: signalIconHeight)
        graySignalIcon.frame = CGRect(x: backViewWidth - offsetX - signalIconWidth, y: singalIconPostionY, width: signalIconWidth, height: signalIconHeight)
        maxLabel.frame = CGRect(x: offsetX, y: singalIconPostionY + signalIconHeight + 2, width: 50, height: MKFont.font(11).lineHeight)
        minLabel.frame = CGRect(x: backViewWidth - offsetX - 50, y: singalIconPostionY + signalIconHeight + 2, width: 50, height: MKFont.font(11).lineHeight)

        let noteSize = noteMsg1.size(withFont: MKFont.font(11), maxSize: CGSize(width: backViewWidth - 2 * offsetX, height: .greatestFiniteMagnitude))
        noteLabel1.frame = CGRect(x: offsetX, y: singalIconPostionY + signalIconHeight + offsetX + 20, width: backViewWidth - 2 * offsetX, height: noteSize.height)
        doneButton.frame = CGRect(x: offsetX, y: backViewHeight - 40 - 45, width: backViewWidth - 2 * offsetX, height: 45)
    }

    // MARK: - Public

    public static func showSearchName(_ name: String?,
                                      tagID: String?,
                                      rssi: Int,
                                      searchBlock: @escaping (String, String, Int) -> Void) {
        let view = MKBXSScanFilterView()
        view.showSearchName(name, tagID: tagID, rssi: rssi, searchBlock: searchBlock)
    }

    private func showSearchName(_ name: String?, tagID: String?, rssi: Int, searchBlock: @escaping (String, String, Int) -> Void) {
        // 拿到 window（兼容性更好）
        let window = MKApp.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        guard let window = window else { return }

        let backViewWidth = window.bounds.width - 2 * offsetX
        self.frame = window.bounds
        // 初始位置：屏幕顶部上方
        self.backView.frame = CGRect(x: offsetX, y: -backViewHeight, width: backViewWidth, height: backViewHeight)
        window.addSubview(self)

        self.searchBlock = searchBlock
        nameTextField.text = name ?? ""
        tagTextField.text = tagID ?? ""
        slider.value = Float(-100 - rssi)
        rssiValueLabel.text = "\(rssi)dBm"

        // 目标位置：状态栏下方（键盘绝对遮挡不到）
        let safeAreaTop = window.safeAreaInsets.top
        UIView.animate(withDuration: 0.25) {
            self.backView.frame = CGRect(x: self.offsetX,
                                         y: safeAreaTop,
                                         width: backViewWidth,
                                         height: self.backViewHeight)
        } completion: { _ in
            self.nameTextField.becomeFirstResponder()
        }
    }

    // MARK: - Events

    @objc private func rssiValueChanged() {
        rssiValueLabel.text = String(format: "%.fdBm", -100 - slider.value)
    }

    @objc private func dismiss() {
        nameTextField.resignFirstResponder()
        tagTextField.resignFirstResponder()
        guard let window = self.superview else {
            self.removeFromSuperview()
            return
        }
        let backViewWidth = window.bounds.width - 2 * offsetX
        UIView.animate(withDuration: 0.25) {
            self.backView.frame = CGRect(x: self.offsetX,
                                         y: -self.backViewHeight,
                                         width: backViewWidth,
                                         height: self.backViewHeight)
        } completion: { _ in
            if self.superview != nil { self.removeFromSuperview() }
        }
    }

    @objc private func doneButtonPressed() {
        nameTextField.resignFirstResponder()
        tagTextField.resignFirstResponder()
        guard let window = self.superview else {
            self.removeFromSuperview()
            return
        }
        let backViewWidth = window.bounds.width - 2 * offsetX
        UIView.animate(withDuration: 0.25) {
            self.backView.frame = CGRect(x: self.offsetX,
                                         y: -self.backViewHeight,
                                         width: backViewWidth,
                                         height: self.backViewHeight)
        } completion: { _ in
            let value = String(format: "%.f", self.slider.value)
            self.searchBlock?(self.nameTextField.text ?? "",
                              self.tagTextField.text ?? "",
                              -100 - (Int(value) ?? 0))
            if self.superview != nil { self.removeFromSuperview() }
        }
    }

    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        tap.delegate = self
        addGestureRecognizer(tap)
    }

    // MARK: - Helpers

    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .left
        label.font = MKFont.font(14)
        label.text = text
        return label
    }

    private func createTextField(placeholder: String, maxLength: Int) -> MKSwiftTextField {
        let tf = MKSwiftTextField(textFieldType: .normal)
        tf.maxLength = maxLength
        tf.textColor = MKColor.defaultText
        tf.font = MKFont.font(13)
        tf.placeholder = placeholder
        tf.clearButtonMode = .whileEditing
        tf.layer.masksToBounds = true
        tf.layer.borderColor = MKColor.navBar.cgColor
        tf.layer.borderWidth = 0.5
        tf.layer.cornerRadius = 4
        return tf
    }
}

extension MKBXSScanFilterView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touch.view == self
    }
}
