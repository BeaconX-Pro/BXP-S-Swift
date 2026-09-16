//
//  MKBXSConnectManager.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import CoreBluetooth

import MKBaseSwiftModule
import MKSwiftBleModule

// MARK: - 设备类型

public enum MKBXSDeviceType: Int, Sendable {
    case slathf = 0             // 主线/0x02(L03)/0x03(M1P)/0x05(M5) — 基线功能
    case slathfS05T = 1         // 板类型0x04 (S05T泡沫棉)
    case slathfDL002 = 2        //板类型0x06 / BXP-S06-SLATHF (EM4)(DL002)
    case atmosic = 3            //BXP-S-A
    case nordic = 4             //BXP-S-E(DL001)
}

// MARK: - 温湿度传感器类型

public enum MKBXSTHSensorType: Int, Sendable {
    case none = 0
    case temperature = 1
    case th = 2
}

// MARK: - Connect Manager

public final class MKBXSConnectManager: @unchecked Sendable {

    // MARK: - Singleton

    public static let shared = MKBXSConnectManager()
    private init() {}

    // MARK: - Properties

    public var password: String = ""
    public var needPassword: Bool = false
    public private(set) var macAddress: String = ""
    public var tagIdAutoFill: Bool = false
    public var hallStatus: Bool = false
    public var resetByButton: Bool = false
    public var accStatus: Int = 0
    public private(set) var thSensorType: MKBXSTHSensorType = .none
    public private(set) var deviceType: MKBXSDeviceType = .slathf

    // MARK: - Private

    private let connectQueue = DispatchQueue(label: "com.moko.connectQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    private var thStatus: Int = 0
    private var software: String = ""

    // MARK: - 连接设备

    public func connectDevice(peripheral: CBPeripheral,
                              password: String,
                              sucBlock: (() -> Void)?,
                              failedBlock: @escaping (Error) -> Void) {
        connectQueue.async { [weak self] in
            guard let self = self else { return }

            let connectResult: [String: Any]
            if !password.isEmpty && password.count <= 16 {
                connectResult = self.connect(peripheral: peripheral, password: password)
                self.needPassword = true
                self.password = password
            } else {
                connectResult = self.connect(peripheral: peripheral)
                self.needPassword = false
                self.password = ""
            }

            guard (connectResult["success"] as? Bool) == true else {
                self.operationFailedMsg(connectResult["msg"] as? String ?? "Connect Error",
                                        failedBlock: failedBlock)
                return
            }

            guard self.readSoftware() else {
                self.operationFailedMsg("Read Software Error", failedBlock: failedBlock)
                return
            }

            guard self.determineDeviceType() else {
                self.operationFailedMsg("Unknown Device Type", failedBlock: failedBlock)
                return
            }

            guard self.readMacAddress() else {
                self.operationFailedMsg("Read Mac Address Error", failedBlock: failedBlock)
                return
            }

            guard self.readTagIDFill() else {
                self.operationFailedMsg("Read Tag ID Auto Fill Error", failedBlock: failedBlock)
                return
            }

            guard self.readHallSensorStatus() else {
                self.operationFailedMsg("Read Hall Sensor Error", failedBlock: failedBlock)
                return
            }

            guard self.readResetByButton() else {
                self.operationFailedMsg("Read Reset By Button Error", failedBlock: failedBlock)
                return
            }

            guard self.readSensorType() else {
                self.operationFailedMsg("Read sensor type Error", failedBlock: failedBlock)
                return
            }

            guard self.configDate() else {
                self.operationFailedMsg("Config Date Error", failedBlock: failedBlock)
                return
            }

            self.convertTHSensorType()

            DispatchQueue.main.async {
                sucBlock?()
            }
        }
    }

    // MARK: - Interface

    private func connect(peripheral: CBPeripheral, password: String) -> [String: Any] {
        var connectResult: [String: Any] = [:]
        Task { @MainActor in
            MKBXSCentralManager.shared.connect(peripheral: peripheral, password: password) { _ in
                connectResult = ["success": true]
                self.semaphore.signal()
            } failedBlock: { error in
                connectResult = [
                    "success": false,
                    "msg": (error as NSError).userInfo["errorInfo"] as? String ?? error.localizedDescription
                ]
                self.semaphore.signal()
            }
        }
        semaphore.wait()
        return connectResult
    }

    private func connect(peripheral: CBPeripheral) -> [String: Any] {
        var connectResult: [String: Any] = [:]
        Task { @MainActor in
            MKBXSCentralManager.shared.connect(peripheral: peripheral) { _ in
                connectResult = ["success": true]
                self.semaphore.signal()
            } failedBlock: { error in
                connectResult = [
                    "success": false,
                    "msg": (error as NSError).userInfo["errorInfo"] as? String ?? error.localizedDescription
                ]
                self.semaphore.signal()
            }
        }
        semaphore.wait()
        return connectResult
    }

    private func configDate() -> Bool {
        var success = false
        let timestamp = UInt(Date().timeIntervalSince1970)
        Task { @MainActor in
            MKBXSInterface.configDeviceTime(timestamp: timestamp, sucBlock: {
                success = true
                self.semaphore.signal()
            }, failedBlock: { _ in
                self.semaphore.signal()
            })
        }
        semaphore.wait()
        return success
    }

    private func readSoftware() -> Bool {
        var success = false
        Task { @MainActor in
            MKBXSInterface.readSoftware(sucBlock: { returnData in
                success = true
                self.software = (returnData["software"] as? String) ?? ""
                self.semaphore.signal()
            }, failedBlock: { _ in
                self.semaphore.signal()
            })
        }
        semaphore.wait()
        return success
    }

    private func readMacAddress() -> Bool {
        var success = false
        Task { @MainActor in
            MKBXSInterface.readMacAddress(sucBlock: { returnData in
                success = true
                self.macAddress = (returnData["macAddress"] as? String) ?? ""
                self.semaphore.signal()
            }, failedBlock: { _ in
                self.semaphore.signal()
            })
        }
        semaphore.wait()
        return success
    }

    private func readTagIDFill() -> Bool {
        var success = false
        Task { @MainActor in
            MKBXSInterface.readTagIDAutofillStatus(sucBlock: { returnData in
                success = true
                self.tagIdAutoFill = (returnData["isOn"] as? Bool) ?? false
                self.semaphore.signal()
            }, failedBlock: { _ in
                self.semaphore.signal()
            })
        }
        semaphore.wait()
        return success
    }

    private func readHallSensorStatus() -> Bool {
        var success = false
        Task { @MainActor in
            MKBXSInterface.readHallSensorStatus(sucBlock: { returnData in
                success = true
                self.hallStatus = (returnData["isOn"] as? Bool) ?? false
                self.semaphore.signal()
            }, failedBlock: { _ in
                self.semaphore.signal()
            })
        }
        semaphore.wait()
        return success
    }

    private func readResetByButton() -> Bool {
        var success = false
        Task { @MainActor in
            MKBXSInterface.readResetDeviceByButtonStatus(sucBlock: { returnData in
                success = true
                self.resetByButton = (returnData["isOn"] as? Bool) ?? false
                self.semaphore.signal()
            }, failedBlock: { _ in
                self.semaphore.signal()
            })
        }
        semaphore.wait()
        return success
    }

    // ⬇️ 关键修复：axis / tempHumidity 是 String，不是 Int
    private func readSensorType() -> Bool {
        var success = false
        Task { @MainActor in
            MKBXSInterface.readSensorType(sucBlock: { returnData in
                success = true
                let axisStr = (returnData["axis"] as? String) ?? "0"
                self.accStatus = Int(axisStr) ?? 0
                let tempHumidityStr = (returnData["tempHumidity"] as? String) ?? "0"
                self.thStatus = Int(tempHumidityStr) ?? 0
                self.semaphore.signal()
            }, failedBlock: { _ in
                self.semaphore.signal()
            })
        }
        semaphore.wait()
        return success
    }

    // ⬇️ 关键修复：board 是 String，不是 Int
    private func readBoardType() -> Int {
        var type = 0
        Task { @MainActor in
            MKBXSInterface.readDeviceBoardType(sucBlock: { returnData in
                let boardStr = (returnData["board"] as? String) ?? "0"
                type = Int(boardStr) ?? 0
                self.semaphore.signal()
            }, failedBlock: { _ in
                self.semaphore.signal()
            })
        }
        semaphore.wait()
        return type
    }

    // MARK: - 设备类型判断

    private func determineDeviceType() -> Bool {
        guard !software.isEmpty else { return false }

        if software.hasSuffix("-A") {
            deviceType = .atmosic
            return true
        }

        if software.hasSuffix("-E") {
            deviceType = .nordic
            return true
        }

        if software.contains("SLATHF") {
            let boardType = readBoardType()
            if boardType == 4 {
                deviceType = .slathfS05T
            } else if boardType == 6 {
                deviceType = .slathfDL002
            } else {
                deviceType = .slathf
            }
            return true
        }

        return false
    }

    // MARK: - 温湿度类型转换

    private func convertTHSensorType() {
        if thStatus == 1 || thStatus == 2 || thStatus == 4 || thStatus == 5 {
            thSensorType = .th
            return
        }
        if thStatus == 3 || thStatus == 6 || thStatus == 7 {
            thSensorType = .temperature
            return
        }
        thSensorType = .none
    }

    // MARK: - 错误处理

    private func operationFailedMsg(_ msg: String, failedBlock: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            Task { @MainActor in
                MKBXSCentralManager.shared.disconnect()
            }
            let error = NSError(domain: "connectDevice",
                                code: -999,
                                userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}
