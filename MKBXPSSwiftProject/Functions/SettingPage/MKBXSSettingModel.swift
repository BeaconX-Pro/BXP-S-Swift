//
//  MKBXSSettingModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

import MKBaseSwiftModule

public final class MKBXSSettingModel: NSObject, @unchecked Sendable {

    /// 霍尔开关机状态
    public var hallStatus: Bool = false
    /// 是否支持三轴
    public var supportThreeAcc: Bool = false
    /// 是否支持温湿度
    public var supportTH: Bool = false
    /// 0:Voltage   1:Percentage
    public var batteryAdvMode: Int = 0
    /// 0:CH37&38&39    1:CH37  2:CH38  3:CH39
    public var advChannel: Int = 0

    private let readQueue = DispatchQueue(label: "settingsQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    public func readData(sucBlock: @escaping () -> Void,
                         failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readHallSensorState() else {
                self.operationFailed("Read Hall Error", failedBlock: failedBlock); return
            }
            guard self.readSensorType() else {
                self.operationFailed("Read Sensor Type Error", failedBlock: failedBlock); return
            }
            guard self.readBatteryADVMode() else {
                self.operationFailed("Read Battery ADV mode Error", failedBlock: failedBlock); return
            }
            guard self.readAdvChannel() else {
                self.operationFailed("Read ADV Channel Error", failedBlock: failedBlock); return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    // MARK: - Private

    private func readHallSensorState() -> Bool {
        var success = false
        MKBXSInterface.readHallSensorStatus(sucBlock: { data in
            success = true
            // isOn 是 Bool
            self.hallStatus = (data["isOn"] as? Bool) ?? false
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readSensorType() -> Bool {
        var success = false
        MKBXSInterface.readSensorType(sucBlock: { data in
            success = true
            // axis / tempHumidity 都是 String
            let axisStr = (data["axis"] as? String) ?? "0"
            let tempHumidityStr = (data["tempHumidity"] as? String) ?? "0"
            self.supportThreeAcc = (Int(axisStr) ?? 0) > 0
            self.supportTH = (Int(tempHumidityStr) ?? 0) > 0
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readBatteryADVMode() -> Bool {
        var success = false
        MKBXSInterface.readBatteryADVMode(sucBlock: { data in
            success = true
            // mode 是 String，值："0"=百分比，"1"=电压？看 MKBXSTaskAdopter 里
            // 实际 MKBXSTaskAdopter 里 case "6c" resultDic = ["mode": "\(mode - 1)"]
            // mode-1 == 0 表示电压，mode-1 == 1 表示百分比
            let modeStr = (data["mode"] as? String) ?? "0"
            let mode = Int(modeStr) ?? 0
            // mode == 0 → 百分比（UI 索引 1）；mode == 1 → 电压（UI 索引 0）
            // 但看 OC 逻辑：mode == 0 → batteryAdvMode = 1（百分比）；mode != 0 → batteryAdvMode = 0（电压）
            if mode == 0 {
                // 百分比
                self.batteryAdvMode = 1
            } else {
                // 电池电压
                self.batteryAdvMode = 0
            }
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readAdvChannel() -> Bool {
        var success = false
        MKBXSInterface.readADVChannel(sucBlock: { data in
            success = true
            // channel 是 String
            let channelStr = (data["channel"] as? String) ?? "0"
            let channel = Int(channelStr) ?? 0
            if channel == 7 {
                self.advChannel = 0
            } else if channel == 1 {
                self.advChannel = 1
            } else if channel == 2 {
                self.advChannel = 2
            } else if channel == 4 {
                self.advChannel = 3
            }
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func operationFailed(_ msg: String, failedBlock: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "settingPage", code: -999, userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}
