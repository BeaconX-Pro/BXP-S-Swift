//
//  MKBXSSensorModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

import MKBaseSwiftModule

public final class MKBXSSensorModel: NSObject, @unchecked Sendable {

    /// 采样间隔 (Unit: s)
    public var samplingInterval: String = ""
    /// 设备时间
    public var deviceTime: String = ""
    /// 是否存储数据
    public var dataStore: Bool = false
    /// 存储间隔 (Unit: s)
    public var interval: String = ""

    // MARK: - 高级功能 (仅特定设备支持)

    /// 温度存储启动延时 (Unit: Minutes)
    public var storageStartDelay: String = ""
    /// 温度异常检测开关
    public var temperatureTriggerOn: Bool = false
    /// 最大温度阈值 (Unit: ℃)
    public var maxTemperature: String = ""
    /// 最小温度阈值 (Unit: ℃)
    public var minTemperature: String = ""
    /// 温度异常检测触发次数
    public var temperatureTriggerCount: String = ""

    /// 是否支持高级功能
    public private(set) var supportAdvancedFeatures: Bool = false

    private let readQueue = DispatchQueue(label: "THSensorQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    public override init() {
        super.init()
        supportAdvancedFeatures = checkAdvancedFeaturesSupport()
    }

    // MARK: - Public

    public func read(sucBlock: @escaping () -> Void,
                     failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readSamplingInterval() else {
                self.operationFailed("Read Sampling Interval Error", failedBlock: failedBlock); return
            }
            guard self.readStoreParams() else {
                self.operationFailed("Read T&H Data Store Error", failedBlock: failedBlock); return
            }
            guard self.readDeviceTime() else {
                self.operationFailed("Read Device Time Error", failedBlock: failedBlock); return
            }
            if self.supportAdvancedFeatures {
                guard self.readTemperatureTrigger() else {
                    self.operationFailed("Read Temperature Trigger Error", failedBlock: failedBlock); return
                }
                guard self.readTemperatureTriggerCount() else {
                    self.operationFailed("Read Temperature Trigger Count Error", failedBlock: failedBlock); return
                }
                guard self.readStorageStartDelay() else {
                    self.operationFailed("Read Storage Start Delay Error", failedBlock: failedBlock); return
                }
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    public func config(sucBlock: @escaping () -> Void,
                       failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.configSamplingInterval() else {
                self.operationFailed("Config Sampling Interval Error", failedBlock: failedBlock); return
            }
            guard self.configStoreParams() else {
                self.operationFailed("Config T&H Data Store Error", failedBlock: failedBlock); return
            }
            if self.supportAdvancedFeatures {
                guard self.configTemperatureTrigger() else {
                    self.operationFailed("Config Temperature Trigger Error", failedBlock: failedBlock); return
                }
                guard self.configStorageStartDelay() else {
                    self.operationFailed("Config Storage Start Delay Error", failedBlock: failedBlock); return
                }
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    public func clearTemperatureTriggerCount(sucBlock: @escaping () -> Void,
                                             failedBlock: @escaping (Error) -> Void) {
        guard supportAdvancedFeatures else {
            operationFailed("Device does not support this feature", failedBlock: failedBlock)
            return
        }
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.clearTriggerCount() else {
                self.operationFailed("Clear Temperature Trigger Count Error", failedBlock: failedBlock); return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    // MARK: - Private Interfaces

    private func readSamplingInterval() -> Bool {
        var success = false
        MKBXSInterface.readHTSamplingRate(sucBlock: { data in
            success = true
            self.samplingInterval = (data["samplingRate"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configSamplingInterval() -> Bool {
        var success = false
        MKBXSInterface.configTHSamplingRate(Int(samplingInterval) ?? 0, sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readStoreParams() -> Bool {
        var success = false
        MKBXSInterface.readTHDataStoreParams(sucBlock: { data in
            success = true
            self.dataStore = (data["isOn"] as? Bool) ?? false
            self.interval = (data["interval"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configStoreParams() -> Bool {
        var success = false
        MKBXSInterface.configTHDataStoreStatus(isOn: dataStore, interval: Int(interval) ?? 0, sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readDeviceTime() -> Bool {
        var success = false
        MKBXSInterface.readDeviceUTCTime(sucBlock: { data in
            success = true
            if let timestamp = data["timestamp"] as? String, let time = TimeInterval(timestamp) {
                let date = Date(timeIntervalSince1970: time)
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
                self.deviceTime = formatter.string(from: date)
            }
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    // MARK: - Advanced

    private func checkAdvancedFeaturesSupport() -> Bool {
        let deviceType = MKBXSConnectManager.shared.deviceType
        return deviceType == .atmosic || deviceType == .nordic || deviceType == .slathfS05T || deviceType == .slathfDL002
    }

    private func readTemperatureTrigger() -> Bool {
        var success = false
        MKBXSInterface.readTemperatureTrigger(sucBlock: { data in
            success = true
            self.temperatureTriggerOn = (data["isOn"] as? Bool) ?? false
            self.maxTemperature = (data["maxTemperature"] as? String) ?? ""
            self.minTemperature = (data["minTemperature"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configTemperatureTrigger() -> Bool {
        var success = false
        MKBXSInterface.configTemperatureTrigger(isOn: temperatureTriggerOn,
                                                maxTemperature: Float(maxTemperature) ?? 0,
                                                minTemperature: Float(minTemperature) ?? 0,
                                                sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readTemperatureTriggerCount() -> Bool {
        var success = false
        MKBXSInterface.readTemperatureTriggerCount(sucBlock: { data in
            success = true
            self.temperatureTriggerCount = (data["count"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readStorageStartDelay() -> Bool {
        var success = false
        MKBXSInterface.readStorageStartDelay(sucBlock: { data in
            success = true
            self.storageStartDelay = (data["delay"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configStorageStartDelay() -> Bool {
        var success = false
        MKBXSInterface.configStorageStartDelay(Int(storageStartDelay) ?? 0, sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func clearTriggerCount() -> Bool {
        var success = false
        MKBXSInterface.clearTemperatureTriggerCount(sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func operationFailed(_ msg: String, failedBlock: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "THSensor", code: -999, userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}
