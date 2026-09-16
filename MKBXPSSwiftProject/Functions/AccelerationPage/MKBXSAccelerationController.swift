//
//  MKBXSAccelerationController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSAccelerationController: MKSwiftBaseViewController {

    // MARK: - UI

    private lazy var headerView: MKBXSAccelerationHeaderView = {
        let header = MKBXSAccelerationHeaderView(frame: CGRect(x: 0, y: 0, width: MKScreen.width, height: 165))
        header.delegate = self
        return header
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        tv.delegate = self
        tv.dataSource = self
        tv.tableHeaderView = headerView
        tv.separatorStyle = .none
        if #available(iOS 15.0, *) {
            tv.sectionHeaderTopPadding = 0
        }
        return tv
    }()

    // MARK: - Data

    private lazy var dataList: [MKBXSAccelerationParamsCellModel] = []
    private let dataModel = MKBXSAccelerationModel()

    deinit {
        MKBXSCentralManager.shared.notifyThreeAxisData(false)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        readDataFromDevice()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receiveAxisDatas(_:)),
                                               name: .mk_bxs_receiveThreeAxisData,
                                               object: nil)
    }

    // MARK: - Super Method

    public override func rightButtonMethod() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        dataModel.config(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast("Success")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    // MARK: - Notification

    @objc private func receiveAxisDatas(_ note: Notification) {
        guard let dic = note.userInfo as? [String: Any] else { return }
        let x = dic["xData"] as? String ?? ""
        let y = dic["yData"] as? String ?? ""
        let z = dic["zData"] as? String ?? ""
        headerView.updateData(xData: x, yData: y, zData: z)
    }

    // MARK: - Interface

    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.read(sucBlock: { [weak self] in
            guard let self = self else { return }
            MKSwiftHudManager.shared.hide()
            self.loadSectionDatas()
            self.headerView.updateTriggerCount(self.dataModel.triggerCount)
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    private func loadSectionDatas() {
        // ⬇️ 先清空，避免重复添加
        dataList.removeAll()

        let cellModel = MKBXSAccelerationParamsCellModel()
        cellModel.scale = dataModel.scale
        cellModel.samplingRate = dataModel.samplingRate
        cellModel.threshold = dataModel.threshold
        dataList.append(cellModel)

        tableView.reloadData()
    }

    // MARK: - UI

    private func loadSubViews() {
        defaultTitle = "3-axis accelerometer"
        rightButton.setImage(UIImage(named: "bxs_slotSaveIcon.png"), for: .normal)
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }
}

// MARK: - TableView

extension MKBXSAccelerationController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        160
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataList.count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKBXSAccelerationParamsCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        cell.delegate = self
        return cell
    }
}

// MARK: - MKBXSAccelerationHeaderViewDelegate

extension MKBXSAccelerationController: MKBXSAccelerationHeaderViewDelegate {
    public func bxs_updateThreeAxisNotifyStatus(_ notify: Bool) {
        MKBXSCentralManager.shared.notifyThreeAxisData(notify)
    }
    public func bxs_clearMotionTriggerCountButtonPressed() {
        MKSwiftHudManager.shared.showHUD(with: "Config...", in: view, isPenetration: false)
        MKBXSInterface.clearMotionTriggerCount(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.dataModel.triggerCount = "0"
            self?.headerView.updateTriggerCount("0")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }
}

// MARK: - MKBXSAccelerationParamsCellDelegate

extension MKBXSAccelerationController: MKBXSAccelerationParamsCellDelegate {
    public func bxs_accelerationParamsScaleChanged(_ scale: Int) {
        dataModel.scale = scale
        dataList[0].scale = scale
    }
    public func bxs_accelerationParamsSamplingRateChanged(_ samplingRate: Int) {
        dataModel.samplingRate = samplingRate
        dataList[0].samplingRate = samplingRate
    }
    public func bxs_accelerationMotionThresholdChanged(_ threshold: String) {
        dataModel.threshold = threshold
        dataList[0].threshold = threshold
    }
}
