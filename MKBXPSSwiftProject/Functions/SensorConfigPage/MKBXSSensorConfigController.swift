//
//  MKBXSSensorConfigController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSSensorConfigController: MKSwiftBaseViewController {

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.delegate = self
        tv.dataSource = self
        return tv
    }()

    private lazy var dataList: [MKSwiftNormalTextCellModel] = []

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        loadSectionDatas()
    }

    @objc private func pushAxisSensor() {
        let vc = MKBXSAccelerationController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func pushHallSensor() {
        let vc = MKBXSHallSensorConfigController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func pushSensor() {
        let manager = MKBXSConnectManager.shared
        let isSLATHF = (manager.deviceType == .slathf)
        if isSLATHF {
            let vc = MKBXSSensorController()
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = MKBXSSensorAdvancedController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func loadSectionDatas() {
        let manager = MKBXSConnectManager.shared

        if manager.accStatus > 0 {
            let model = MKSwiftNormalTextCellModel()
            model.leftMsg = "3-axis accelerometer"
            model.showRightIcon = true
            model.methodName = "pushAxisSensor"
            dataList.append(model)
        }

        if manager.deviceType != .nordic && !manager.hallStatus && !manager.resetByButton {
            let model = MKSwiftNormalTextCellModel()
            model.leftMsg = "Hall sensor"
            model.showRightIcon = true
            model.methodName = "pushHallSensor"
            dataList.append(model)
        }

        if manager.thSensorType == .temperature {
            let model = MKSwiftNormalTextCellModel()
            model.leftMsg = "Temperature"
            model.showRightIcon = true
            model.methodName = "pushSensor"
            dataList.append(model)
        } else if manager.thSensorType == .th {
            let model = MKSwiftNormalTextCellModel()
            model.leftMsg = "Temperature & Humidity"
            model.showRightIcon = true
            model.methodName = "pushSensor"
            dataList.append(model)
        }

        tableView.reloadData()
    }

    private func loadSubViews() {
        defaultTitle = "Sensor configurations"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }
}

extension MKBXSSensorConfigController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 44 }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { dataList.count }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellModel = dataList[indexPath.row]
        let methodName = cellModel.methodName
        guard !methodName.isEmpty else { return }
        let selector = NSSelectorFromString(methodName)
        if responds(to: selector) {
            perform(selector, with: nil)
        }
    }
}
