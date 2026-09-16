//
//  MKBXSQuickSwitchController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBeaconXCustomUI

public final class MKBXSQuickSwitchController: MKSwiftBaseViewController {

    private lazy var collectionView: UICollectionView = {
        let layout = MKBXQuickSwitchCellLayout()
        layout.sectionInset = UIEdgeInsets(top: 11, left: 11, bottom: 0, right: 11)
        layout.scrollDirection = .vertical
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor(red: 246/255.0, green: 247/255.0, blue: 251/255.0, alpha: 1)
        cv.delegate = self
        cv.dataSource = self
        cv.alwaysBounceVertical = true
        cv.register(MKBXQuickSwitchCell.self, forCellWithReuseIdentifier: "MKBXQuickSwitchCellIdenty")
        return cv
    }()

    private lazy var dataList: [MKBXQuickSwitchCellModel] = []
    private let dataModel = MKBXSQuickSwitchModel()

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        readDataFromDevice()
    }

    private func readDataFromDevice() {
        MKSwiftHudManager.shared.showHUD(with: "Reading...", in: view, isPenetration: false)
        dataModel.read(sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.loadSectionData()
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
        })
    }

    private func loadSectionData() {
        dataList.removeAll()
        let items: [(Int, String, Bool)] = [
            (0, "Connectable status", dataModel.connectable),
            (1, "Trigger LED indicator", dataModel.trigger),
            (2, "Password verification", dataModel.passwordVerification),
            (3, "Tag ID Autofill", dataModel.autoFill),
            (4, "Reset Beacon by button", dataModel.resetByButton),
            (5, "Turn off Beacon by button", dataModel.turnOffByButton)
        ]
        for (index, title, isOn) in items {
            let model = MKBXQuickSwitchCellModel()
            model.index = index
            model.titleMsg = title
            model.isOn = isOn
            dataList.append(model)
        }
        collectionView.reloadData()
    }

    private func loadSubViews() {
        defaultTitle = "Quick switch"
        view.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }
}

// MARK: - CollectionView

extension MKBXSQuickSwitchController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { dataList.count }
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MKBXQuickSwitchCellIdenty", for: indexPath) as! MKBXQuickSwitchCell
        cell.dataModel = dataList[indexPath.row]
        cell.delegate = self
        return cell
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (MKScreen.width - 3 * 11) / 2, height: 85)
    }
}

// MARK: - Cell Delegate

extension MKBXSQuickSwitchController: MKBXQuickSwitchCellDelegate {
    public func mk_swift_bx_quickSwitchStatusChanged(_ isOn: Bool, index: Int) {
        switch index {
        case 0: configConnectEnable(isOn)
        case 1: configTriggerLEDIndicator(isOn)
        case 2: configPasswordVerification(isOn)
        case 3: configTagIDAutofill(isOn)
        case 4: configResetByButton(isOn)
        case 5: configTurnOffByButton(isOn)
        default: break
        }
    }

    private func configConnectEnable(_ connect: Bool) {
        if connect {
            setConnectStatusToDevice(connect)
            return
        }
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") { [weak self] in
            self?.collectionView.reloadData()
        })
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.setConnectStatusToDevice(connect)
        })
        alert.showAlert(title: "Warning!", message: "Are you sure to set the Beacon non-connectable？")
    }

    private func setConnectStatusToDevice(_ connect: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXSInterface.configConnectable(connect, sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.dataModel.connectable = connect
            self?.dataList[0].isOn = connect
            self?.view.showCentralToast("Success!")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
            self?.collectionView.reloadData()
        })
    }

    private func configTriggerLEDIndicator(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXSInterface.configTriggerLEDIndicatorStatus(isOn: isOn, sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.dataModel.trigger = isOn
            self?.dataList[1].isOn = isOn
            self?.view.showCentralToast("Success!")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
            self?.collectionView.reloadData()
        })
    }

    private func configPasswordVerification(_ isOn: Bool) {
        if isOn {
            commandForPasswordVerification(isOn)
            return
        }
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") { [weak self] in
            self?.collectionView.reloadData()
        })
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.commandForPasswordVerification(isOn)
        })
        alert.showAlert(title: "Warning!", message: "If Password verification is disabled, it will not need password to connect the Beacon.")
    }

    private func commandForPasswordVerification(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXSInterface.configPasswordVerification(isOn: isOn, sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.dataList[2].isOn = isOn
            MKBXSConnectManager.shared.needPassword = isOn
            self?.view.showCentralToast("Success!")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
            self?.collectionView.reloadData()
        })
    }

    private func configTagIDAutofill(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXSInterface.configTagIDAutofillStatus(isOn: isOn, sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            MKBXSConnectManager.shared.tagIdAutoFill = isOn
            self?.dataModel.autoFill = isOn
            self?.dataList[3].isOn = isOn
            self?.view.showCentralToast("Success!")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
            self?.collectionView.reloadData()
        })
    }

    private func configResetByButton(_ isOn: Bool) {
        if isOn {
            commandResetByButton(isOn)
            return
        }
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") { [weak self] in
            self?.collectionView.reloadData()
        })
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.commandResetByButton(isOn)
        })
        alert.showAlert(title: "Warning!", message: "If Button reset is disabled, you cannot reset the Beacon by button operation.")
    }

    private func commandResetByButton(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXSInterface.configResetDeviceByButtonStatus(isOn: isOn, sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.dataModel.resetByButton = isOn
            self?.dataList[4].isOn = isOn
            MKBXSConnectManager.shared.resetByButton = isOn
            self?.view.showCentralToast("Success!")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
            self?.collectionView.reloadData()
        })
    }

    private func configTurnOffByButton(_ isOn: Bool) {
        if isOn {
            commandTurnOffByButton(isOn)
            return
        }
        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "Cancel") { [weak self] in
            self?.collectionView.reloadData()
        })
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.commandTurnOffByButton(isOn)
        })
        alert.showAlert(title: "Warning!", message: "If this function is disabled, you cannot power off the Beacon by button.")
    }

    private func commandTurnOffByButton(_ isOn: Bool) {
        MKSwiftHudManager.shared.showHUD(with: "Setting...", in: view, isPenetration: false)
        MKBXSInterface.configHallSensorStatus(isOn: isOn, sucBlock: { [weak self] in
            MKSwiftHudManager.shared.hide()
            self?.dataModel.turnOffByButton = isOn
            self?.dataList[5].isOn = isOn
            MKBXSConnectManager.shared.hallStatus = isOn
            self?.view.showCentralToast("Success!")
        }, failedBlock: { [weak self] error in
            MKSwiftHudManager.shared.hide()
            self?.view.showCentralToast((error as NSError).userInfo["errorInfo"] as? String ?? "")
            self?.collectionView.reloadData()
        })
    }
}
