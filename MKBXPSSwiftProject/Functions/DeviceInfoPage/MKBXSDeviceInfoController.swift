//
//  MKBXSDeviceInfoController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSDeviceInfoController: MKSwiftBaseViewController {

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        return tv
    }()

    private lazy var dataList: [MKSwiftNormalTextCellModel] = []
    private let dataModel = MKBXSDeviceInfoModel()

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        readDatasFromDevice()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        loadSectionDatas()
    }

    public override func leftButtonMethod() {
        NotificationCenter.default.post(name: Notification.Name("mk_bxs_popToRootViewControllerNotification"), object: nil)
    }

    private func readDatasFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.readData(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.updateCellModels()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    private func updateCellModels() {
        guard dataList.count >= 9 else { return }
        dataList[0].rightMsg = "\(dataModel.voltage)mV"
        dataList[1].rightMsg = "\(dataModel.batteryPercent)%"
        dataList[2].rightMsg = dataModel.macAddress
        dataList[3].rightMsg = dataModel.productMode
        dataList[4].rightMsg = dataModel.software
        dataList[5].rightMsg = dataModel.firmware
        dataList[6].rightMsg = dataModel.hardware
        dataList[7].rightMsg = dataModel.manuDate
        dataList[8].rightMsg = dataModel.manu
        tableView.reloadData()
    }

    private func loadSectionDatas() {
        let titles = ["Battery voltage", "Battery Percentage", "MAC address",
                      "Product model", "Software version", "Firmware version",
                      "Hardware version", "Manufacture date", "Manufacturer"]
        for title in titles {
            let model = MKSwiftNormalTextCellModel()
            model.leftMsg = title
            dataList.append(model)
        }
        tableView.reloadData()
    }

    private func loadSubViews() {
        defaultTitle = "DEVICE"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 49))
        }
    }
}

extension MKBXSDeviceInfoController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 44 }
    public func numberOfSections(in tableView: UITableView) -> Int { 1 }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { dataList.count }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }
}
