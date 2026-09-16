//
//  MKBXSHallSensorConfigController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSHallSensorConfigController: MKSwiftBaseViewController {

    private lazy var headerViewModel = MKBXSHallSensorHeaderViewModel()

    private lazy var headerView: MKBXSHallSensorHeaderView = {
        let header = MKBXSHallSensorHeaderView()
        header.delegate = self
        return header
    }()

    private let dataModel = MKBXSHallSensorConfigModel()

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        readDataFromDevice()
    }

    private func clearTriggerCount() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        MKBXSInterface.clearHallTriggerCount(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.readDataFromDevice()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.read(sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.headerViewModel.count = self.dataModel.count
            self.headerView.dataModel = self.headerViewModel
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    private func loadSubViews() {
        defaultTitle = "Hall sensor"
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.height.equalTo(60)
        }
    }
}

extension MKBXSHallSensorConfigController: MKBXSHallSensorHeaderViewDelegate {
    public func bxs_hallSensorHeaderView_clearPressed() {
        clearTriggerCount()
    }
}
