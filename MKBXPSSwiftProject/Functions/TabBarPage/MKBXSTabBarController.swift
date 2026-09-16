//
//  MKBXSTabBarController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public protocol MKBXSTabBarControllerDelegate: AnyObject {
    /// 返回到扫描页面，肯定需要开启扫描，当 dfu 升级之后返回扫描页面，则需要重新设置扫描代理
    /// - Parameter need: YES: DFU 升级情况下返回，需要设置扫描代理；NO: 不需要重设代理
    func mk_bxs_needResetScanDelegate(_ need: Bool)
}

public final class MKBXSTabBarController: UITabBarController {

    // ⬇️ 改名成 mkDelegate，避免和 UITabBarController.delegate 冲突
    public weak var mkDelegate: MKBXSTabBarControllerDelegate?

    /// 当触发
    /// 01: 表示连接成功后，1 分钟内没有通过密码验证（未输入密码，或者连续输入密码错误）认为超时，返回结果，然后断开连接
    /// 02: 修改密码成功后，返回结果，断开连接
    /// 03: 恢复出厂设置
    /// 04: 关机
    private var disconnectType: Bool = false

    /// 设备如果正在进行 dfu，会出现断开连接让设备进入升级模式的现象
    private var dfu: Bool = false

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !(navigationController?.viewControllers.contains(self) ?? false) {
            MKBXSCentralManager.shared.disconnect()
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubPages()
        addNotifications()
    }

    // MARK: - Notifications

    private func addNotifications() {
        let center = NotificationCenter.default
        center.addObserver(self,
                           selector: #selector(gotoScanPage),
                           name: Notification.Name("mk_bxs_popToRootViewControllerNotification"),
                           object: nil)
        center.addObserver(self,
                           selector: #selector(dfuUpdateComplete),
                           name: Notification.Name("mk_bxs_centralDeallocNotification"),
                           object: nil)
        center.addObserver(self,
                           selector: #selector(centralManagerStateChanged),
                           name: .mk_bxs_centralManagerStateChanged,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(disconnectTypeNotification(_:)),
                           name: .mk_bxs_deviceDisconnectType,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(deviceConnectStateChanged),
                           name: .mk_bxs_peripheralConnectStateChanged,
                           object: nil)
        center.addObserver(self,
                           selector: #selector(deviceStartDFUProcess),
                           name: Notification.Name("mk_bxs_startDfuProcessNotification"),
                           object: nil)
    }

    // MARK: - Notes

    @objc private func gotoScanPage() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.mkDelegate?.mk_bxs_needResetScanDelegate(false)
        }
    }

    @objc private func dfuUpdateComplete() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.mkDelegate?.mk_bxs_needResetScanDelegate(true)
        }
    }

    @objc private func disconnectTypeNotification(_ note: Notification) {
        let type = (note.userInfo?["type"] as? String) ?? ""
        // 02: 修改密码成功后，返回结果，断开连接
        // 03: 恢复出厂设置
        // 04: 关机
        disconnectType = true

        if type == "02" {
            showAlertWithMsg("Modify password success! Please reconnect the Device.", title: "")
            return
        }
        if type == "03" {
            showAlertWithMsg("Beacon is disconnected.", title: "Reset success!")
            return
        }
        if type == "04" {
            gotoScanPage()
            return
        }
    }

    @objc private func centralManagerStateChanged() {
        if disconnectType || dfu { return }

        // centralStatus 是方法，带 ()
        if MKBXSCentralManager.shared.centralStatus() != .enable {
            showAlertWithMsg("The current system of bluetooth is not available!", title: "Dismiss")
        }
    }

    @objc private func deviceConnectStateChanged() {
        if disconnectType || dfu { return }
        showAlertWithMsg("The device is disconnected.", title: "Dismiss")
    }

    @objc private func deviceStartDFUProcess() {
        dfu = true
    }

    // MARK: - Private

    private func showAlertWithMsg(_ msg: String, title: String) {
        // 让 setting 页面推出的 alert 消失
        NotificationCenter.default.post(name: Notification.Name("mk_bxs_needDismissAlert"), object: nil)
        // 让所有 MKPickView 消失
        NotificationCenter.default.post(name: Notification.Name("mk_customUIModule_dismissPickView"), object: nil)

        let alert = MKSwiftAlertView()
        alert.addAction(MKSwiftAlertViewAction(title: "OK") { [weak self] in
            self?.gotoScanPage()
        })
        alert.showAlert(title: title, message: msg)
    }

    private func loadSubPages() {
        // SLOT
        let slotPage = MKBXSSlotController()
        slotPage.tabBarItem.title = "SLOT"
        slotPage.tabBarItem.image = UIImage(named: "bxs_slotTabBarItemUnselected.png")
        slotPage.tabBarItem.selectedImage = UIImage(named: "bxs_slotTabBarItemSelected.png")
        let slotNav = MKSwiftBaseNavigationController(rootViewController: slotPage)

        // SETTING
        let settingPage = MKBXSSettingController()
        settingPage.tabBarItem.title = "SETTING"
        settingPage.tabBarItem.image = UIImage(named: "bxs_settingTabBarItemUnselected.png")
        settingPage.tabBarItem.selectedImage = UIImage(named: "bxs_settingTabBarItemSelected.png")
        let settingNav = MKSwiftBaseNavigationController(rootViewController: settingPage)

        // DEVICE
        let devicePage = MKBXSDeviceInfoController()
        devicePage.tabBarItem.title = "DEVICE"
        devicePage.tabBarItem.image = UIImage(named: "bxs_deviceTabBarItemUnselected.png")
        devicePage.tabBarItem.selectedImage = UIImage(named: "bxs_deviceTabBarItemSelected.png")
        let deviceNav = MKSwiftBaseNavigationController(rootViewController: devicePage)

        viewControllers = [slotNav, settingNav, deviceNav]
    }
}
