//
//  MKBXSTriggerStepThreeModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

import Foundation

public final class MKBXSTriggerStepThreeModel: MKBXSSlotDataBaseModel, @unchecked Sendable {

    public var trigger: Bool = false

    private let readQueue = DispatchQueue(label: "slotParamsQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    public override func read(sucBlock: @escaping () -> Void, failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readSlotDatas() else {
                self.operationFailed(msg: "Read Slot Datas Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    public override func config(sucBlock: @escaping () -> Void, failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            if self.trigger && !self.validParams() {
                self.operationFailed(msg: "Params Error", block: failedBlock)
                return
            }
            if !self.trigger {
                guard self.configNoData() else {
                    self.operationFailed(msg: "Config Slot Data Error", block: failedBlock)
                    return
                }
                DispatchQueue.main.async { sucBlock() }
                return
            }
            let success: Bool
            switch self.slotType {
            case .tlm:        success = self.configTLM()
            case .uid:        success = self.configUID()
            case .url:        success = self.configURL()
            case .beacon:     success = self.configBeacon()
            case .sensorInfo: success = self.configSensorInfo()
            case .null:       success = self.configNoData()
            }
            guard success else {
                self.operationFailed(msg: "Config Slot Data Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    private func readSlotDatas() -> Bool {
        var success = false
        MKBXSInterface.readBeforeTriggerSlotData(index: index, sucBlock: { data in
            success = true
            self.updateSlotDatas(data)
            self.trigger = (self.slotType != .null)
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configTLM() -> Bool {
        var success = false
        MKBXSInterface.configSlotTLM(index: index,
                                     type: .beforeTriggerData,
                                     advParams: currentContentParam(),
                                     sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configUID() -> Bool {
        var success = false
        MKBXSInterface.configSlotUID(index: index,
                                     type: .beforeTriggerData,
                                     advParams: currentContentParam(),
                                     namespaceID: namespaceID,
                                     instanceID: instanceID,
                                     sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configURL() -> Bool {
        var success = false
        MKBXSInterface.configSlotURL(index: index,
                                     type: .beforeTriggerData,
                                     advParams: currentContentParam(),
                                     urlType: MKBXSURLHeaderType(rawValue: urlType) ?? .httpWWW,
                                     urlContent: urlContent,
                                     sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configBeacon() -> Bool {
        var success = false
        MKBXSInterface.configSlotBeacon(index: index,
                                        type: .beforeTriggerData,
                                        advParams: currentContentParam(),
                                        major: Int(major) ?? 0,
                                        minor: Int(minor) ?? 0,
                                        uuid: uuid,
                                        sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configSensorInfo() -> Bool {
        var success = false
        MKBXSInterface.configSlotSensorInfo(index: index,
                                            type: .beforeTriggerData,
                                            advParams: currentContentParam(),
                                            deviceName: deviceName,
                                            tagID: tagID,
                                            sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configNoData() -> Bool {
        var success = false
        MKBXSInterface.configSlotNoData(index: index,
                                        type: .beforeTriggerData,
                                        advParams: currentContentParam(),
                                        sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }
}
