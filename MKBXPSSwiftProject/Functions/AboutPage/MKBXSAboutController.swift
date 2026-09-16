//
//  MKBXSAboutController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSAboutController: MKSwiftBaseViewController {

    private lazy var aboutIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "bxs_about_logo.png")
        return iv
    }()

    private lazy var appNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(20)
        label.text = "MK Sensor"
        return label
    }()

    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 189/255.0, green: 189/255.0, blue: 189/255.0, alpha: 1)
        label.textAlignment = .center
        label.font = MKFont.font(16)
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        label.text = "Version: V\(version)"
        return label
    }()

    private lazy var companyNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .center
        label.font = MKFont.font(16)
        label.text = "MOKO TECHNOLOGY LTD."
        return label
    }()

    private lazy var companyNetLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = MKColor.navBar
        label.font = MKFont.font(16)
        label.text = "www.mokoblue.com"
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openWebBrowser)))

        let lineView = UIView()
        lineView.backgroundColor = UIColor(red: 3/255.0, green: 191/255.0, blue: 234/255.0, alpha: 1)
        label.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(155)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        return label
    }()

    private lazy var bottomIcon: UIImageView = {
        let iv = UIImageView()
        iv.isUserInteractionEnabled = true
        iv.image = UIImage(named: "bxs_aboutBottomIcon.png")
        return iv
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
    }

    @objc private func openWebBrowser() {
        guard let url = URL(string: "https://www.mokoblue.com") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func loadSubViews() {
        defaultTitle = "ABOUT"
        rightButton.isHidden = true
        view.addSubview(aboutIcon)
        view.addSubview(appNameLabel)
        view.addSubview(versionLabel)
        view.addSubview(bottomIcon)
        view.addSubview(companyNameLabel)
        view.addSubview(companyNetLabel)

        aboutIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(110)
            make.top.equalTo(view).offset(MKLayout.topBarHeight + 40)
        }
        appNameLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(aboutIcon.snp.bottom).offset(17)
            make.height.equalTo(MKFont.font(20).lineHeight)
        }
        versionLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(appNameLabel.snp.bottom).offset(17)
            make.height.equalTo(MKFont.font(16).lineHeight)
        }
        companyNetLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(-60)
            make.height.equalTo(MKFont.font(16).lineHeight)
        }
        companyNameLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(companyNetLabel.snp.top).offset(-17)
            make.height.equalTo(MKFont.font(17).lineHeight)
        }
        let image = UIImage(named: "bxs_aboutBottomIcon.png") ?? UIImage()
        bottomIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(image.size.width)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
            make.height.equalTo(image.size.height)
        }
    }
}
