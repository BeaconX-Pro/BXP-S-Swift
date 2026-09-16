//
//  MKBXSTriggerStepOneModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

public final class MKBXSTriggerTypeModel: NSObject {
    public var triggerType: Int = 0
    public var triggerIndex: Int = 0
    public var triggerMsg: String = ""
    public override init() { super.init() }
}

public final class MKBXSTriggerStepOneModel: NSObject, @unchecked Sendable {

    public var trigger: Bool = false
    public var triggerIndex: Int = 0

    // 温度
    public var tempEvent: Int = 0
    public var temperature: Int = 0

    // 湿度
    public var humidityEvent: Int = 0
    public var humidity: Int = 0

    // 移动
    public var motionEvent: Int = 0
    public var motionVerificationPeriod: String = "30"

    // 霍尔
    public var hallEvent: Int = 0

    public var lockedAdvIsOn: Bool = false

    private let index: Int
    private let readQueue = DispatchQueue(label: "triggerParamsQueue")
    private let semaphore = DispatchSemaphore(value: 0)
    private var triggerTypeList: [MKBXSTriggerTypeModel] = []
    private var currentTriggerType: Int = 0

    public init(slotIndex: Int) {
        self.index = slotIndex
        super.init()
        loadTriggerTypeList()
    }

    // MARK: - Public

    public func fetchTriggerTypeList() -> [String] {
        triggerTypeList.map { $0.triggerMsg }
    }

    public func fetchTriggerType() -> Int {
        for model in triggerTypeList {
            if model.triggerIndex == triggerIndex {
                return model.triggerType
            }
        }
        return 0
    }

    public func read(sucBlock: @escaping () -> Void, failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readTriggerDatas() else {
                self.operationFailed("Read Trigger Datas Error", failedBlock: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    public func config(sucBlock: @escaping () -> Void, failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.validParams() else {
                self.operationFailed("Params Error", failedBlock: failedBlock)
                return
            }
            if !self.trigger {
                guard self.closeTrigger() else {
                    self.operationFailed("Close Trigger Error", failedBlock: failedBlock)
                    return
                }
                DispatchQueue.main.async { sucBlock() }
                return
            }
            let success: Bool
            switch self.fetchTriggerType() {
            case 0: success = self.configTemperatureTriggerParams()
            case 1: success = self.configHumidityTriggerParams()
            case 2: success = self.configMotionDetectionTriggerParams()
            case 3: success = self.configHallTriggerParams()
            default: success = true
            }
            guard success else {
                self.operationFailed("Config Trigger Params Error", failedBlock: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    // MARK: - Private

    private func readTriggerDatas() -> Bool {
        var success = false
        MKBXSInterface.readSlotTriggerData(index: index, sucBlock: { data in
            success = true
            self.updateParams(data)
            self.updateTriggerIndex()
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func updateParams(_ returnData: [String: Any]) {
        guard !returnData.isEmpty else { return }

        // triggerType: MKBXSSDKDataAdopter.parseSlotTriggerParam 返回的是 String
        let triggerTypeStr = (returnData["triggerType"] as? String) ?? "00"
        let triggerTypeValue = Int(triggerTypeStr) ?? 0
        trigger = triggerTypeValue > 0

        if !trigger {
            let manager = MKBXSConnectManager.shared
            if manager.accStatus > 0 {
                currentTriggerType = 2
                motionEvent = 0
                motionVerificationPeriod = "30"
                return
            }
            if manager.thSensorType != .none {
                currentTriggerType = 0
                temperature = 0
                tempEvent = 0
                return
            }
            if !manager.hallStatus && !manager.resetByButton {
                currentTriggerType = 3
                hallEvent = 0
            }
            return
        }

        currentTriggerType = triggerTypeValue - 1
        lockedAdvIsOn = (returnData["lockedAdv"] as? Bool) ?? false

        switch currentTriggerType {
        case 0:
            // temperature: String
            let tempStr = (returnData["temperature"] as? String) ?? "0"
            temperature = Int(tempStr) ?? 0
            // event: String
            let eventStr = (returnData["event"] as? String) ?? "0"
            tempEvent = Int(eventStr) ?? 0
        case 1:
            let humidityStr = (returnData["humidity"] as? String) ?? "0"
            humidity = Int(humidityStr) ?? 0
            let eventStr = (returnData["event"] as? String) ?? "0"
            humidityEvent = Int(eventStr) ?? 0
        case 2:
            let eventStr = (returnData["event"] as? String) ?? "0"
            motionEvent = Int(eventStr) ?? 0
            motionVerificationPeriod = (returnData["period"] as? String) ?? "30"
        case 3:
            let eventStr = (returnData["event"] as? String) ?? "0"
            hallEvent = Int(eventStr) ?? 0
        default:
            break
        }
    }

    private func updateTriggerIndex() {
        for model in triggerTypeList {
            if model.triggerType == currentTriggerType {
                triggerIndex = model.triggerIndex
                break
            }
        }
    }

    private func closeTrigger() -> Bool {
        var success = false
        MKBXSInterface.closeSlotTrigger(index: index, sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configTemperatureTriggerParams() -> Bool {
        var success = false
        MKBXSInterface.configTemperatureTriggerParams(slotIndex: index,
                                                       triggerEvent: tempEvent,
                                                       temperature: temperature,
                                                       lockedADV: lockedAdvIsOn,
                                                       sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configHumidityTriggerParams() -> Bool {
        var success = false
        MKBXSInterface.configHumidityTriggerParams(slotIndex: index,
                                                    triggerEvent: humidityEvent,
                                                    humidity: humidity,
                                                    lockedADV: lockedAdvIsOn,
                                                    sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configMotionDetectionTriggerParams() -> Bool {
        var success = false
        MKBXSInterface.configMotionDetectionTriggerParams(slotIndex: index,
                                                           triggerEvent: motionEvent,
                                                           period: Int(motionVerificationPeriod) ?? 0,
                                                           lockedADV: lockedAdvIsOn,
                                                           sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configHallTriggerParams() -> Bool {
        var success = false
        MKBXSInterface.configHallTriggerParams(slotIndex: index,
                                                triggerEvent: hallEvent,
                                                lockedADV: lockedAdvIsOn,
                                                sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func validParams() -> Bool {
        if fetchTriggerType() == 2 {
            if motionEvent < 0 || motionEvent > 1 || motionVerificationPeriod.isEmpty
                || (Int(motionVerificationPeriod) ?? 0) < 1
                || (Int(motionVerificationPeriod) ?? 0) > 65535 {
                return false
            }
        }
        return true
    }

    private func loadTriggerTypeList() {
        let manager = MKBXSConnectManager.shared
        if manager.thSensorType != .none {
            let temperatureModel = MKBXSTriggerTypeModel()
            temperatureModel.triggerMsg = "Temperature detect"
            temperatureModel.triggerType = 0
            triggerTypeList.append(temperatureModel)

            if manager.thSensorType == .th {
                let humidityModel = MKBXSTriggerTypeModel()
                humidityModel.triggerMsg = "Humidity detect"
                humidityModel.triggerType = 1
                triggerTypeList.append(humidityModel)
            }
        }
        if manager.accStatus > 0 {
            let motionModel = MKBXSTriggerTypeModel()
            motionModel.triggerMsg = "Motion detect"
            motionModel.triggerType = 2
            triggerTypeList.append(motionModel)
        }
        if !manager.hallStatus && !manager.resetByButton {
            let magneticModel = MKBXSTriggerTypeModel()
            magneticModel.triggerMsg = "magnetic detect"
            magneticModel.triggerType = 3
            triggerTypeList.append(magneticModel)
        }
        for (i, model) in triggerTypeList.enumerated() {
            model.triggerIndex = i
        }
    }

    private func operationFailed(_ msg: String, failedBlock: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "triggrtParams", code: -999, userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}
