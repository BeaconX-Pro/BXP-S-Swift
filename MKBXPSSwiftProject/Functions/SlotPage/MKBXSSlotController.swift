//
//  MKBXSSlotController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSSlotController: MKSwiftBaseViewController {

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        return tv
    }()

    private lazy var dataList: [MKSwiftNormalTextCellModel] = []
    private let dataModel = MKBXSSlotModel()

    private lazy var startButton: UIButton = {
        return MKSwiftUIAdaptor.createRoundedButton(title: "Start",
                                                    target: self,
                                                    action: #selector(startButtonPressed))
    }()

    private var slotCount: Int = 3

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        readDatasFromDevice()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let deviceType = MKBXSConnectManager.shared.deviceType
        slotCount = (deviceType == .atmosic) ? 1 : 3
        loadSubViews()
        loadSectionDatas()
    }

    public override func leftButtonMethod() {
        NotificationCenter.default.post(name: Notification.Name("mk_bxs_popToRootViewControllerNotification"), object: nil)
    }

    @objc private func startButtonPressed() {
        startButton.isSelected.toggle()
        startButton.setTitle(startButton.isSelected ? "Stop" : "Start", for: .normal)
        MKBXSCentralManager.shared.notifyRecordTHData(startButton.isSelected)
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
        if slotCount == 1 {
            dataList[0].rightMsg = dataModel.slot1
        } else {
            dataList[0].rightMsg = dataModel.slot1
            dataList[1].rightMsg = dataModel.slot2
            dataList[2].rightMsg = dataModel.slot3
        }
        tableView.reloadData()
    }

    private func loadSectionDatas() {
        dataList.removeAll()
        let titles = slotCount == 1 ? ["SLOT1"] : ["SLOT1", "SLOT2", "SLOT3"]
        for title in titles {
            let model = MKSwiftNormalTextCellModel()
            model.leftMsg = title
            model.showRightIcon = true
            dataList.append(model)
        }
        tableView.reloadData()
    }

    private func loadSubViews() {
        defaultTitle = "SLOT"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-(MKLayout.safeAreaBottom + 49))
        }
    }

    private func tableFooterView() -> UIView {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: MKScreen.width, height: 80))
        footer.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        startButton.frame = CGRect(x: 30, y: 20, width: MKScreen.width - 60, height: 40)
        footer.addSubview(startButton)
        return footer
    }
}

extension MKBXSSlotController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int { 1 }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { dataList.count }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 44 }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if MKBXSConnectManager.shared.deviceType == .atmosic {
            let vc = MKBXSAtmosicSlotConfigController()
            vc.slotIndex = indexPath.row
            navigationController?.pushViewController(vc, animated: true)
            return
        }
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        MKBXSInterface.readSlotTriggerData(index: indexPath.row, sucBlock: { [weak self] returnData in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            let triggerType = (returnData["triggerType"] as? String) ?? "00"
            let trigger = triggerType != "00"
            if trigger {
                let manager = MKBXSConnectManager.shared
                if manager.accStatus == 0 && manager.thSensorType == .none && (manager.resetByButton || manager.hallStatus) {
                    self.view.showCentralToast("Current device doesn't has sensor!")
                    return
                }
                let vc = MKBXSTriggerStepOneController()
                vc.slotIndex = indexPath.row
                self.navigationController?.pushViewController(vc, animated: true)
                return
            }
            let vc = MKBXSSlotConfigController()
            vc.slotIndex = indexPath.row
            self.navigationController?.pushViewController(vc, animated: true)
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }
}
