//
//  MKBXSTriggerStepTwoModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

import Foundation

public final class MKBXSTriggerStepTwoModel: MKBXSSlotDataBaseModel, @unchecked Sendable {

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
            guard self.validParams() else {
                self.operationFailed(msg: "Params Error", block: failedBlock)
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

    // MARK: - Override validParams（advDuration 范围是 0~65535）

    public override func validParams() -> Bool {
        if slotType == .null { return true }

        guard !advInterval.isEmpty, let intervalValue = Int(advInterval), intervalValue >= 1, intervalValue <= 100 else {
            return false
        }
        guard !advDuration.isEmpty, let durationValue = Int(advDuration), durationValue >= 0, durationValue <= 65535 else {
            return false
        }
        if powerModeIsOn {
            guard !standbyDuration.isEmpty, let standbyValue = Int(standbyDuration), standbyValue >= 1, standbyValue <= 65535 else {
                return false
            }
        }
        if slotType != .tlm, rssi < -127 || rssi > 0 { return false }

        switch slotType {
        case .uid:
            guard !namespaceID.isEmpty, namespaceID.count == 20,
                  !instanceID.isEmpty, instanceID.count == 12 else { return false }
        case .url:
            let result = MKBXSSDKDataAdopter.fetchUrlString(
                MKBXSURLHeaderType(rawValue: urlType) ?? .httpWWW,
                urlContent: urlContent
            )
            if result.isEmpty { return false }
        case .beacon:
            guard !major.isEmpty, let majorValue = Int(major), majorValue >= 0, majorValue <= 65535 else { return false }
            guard !minor.isEmpty, let minorValue = Int(minor), minorValue >= 0, minorValue <= 65535 else { return false }
            guard !uuid.isEmpty, uuid.count == 32 else { return false }
        case .sensorInfo:
            guard !deviceName.isEmpty, deviceName.count <= 20 else { return false }
            guard !tagID.isEmpty, tagID.count <= 12, tagID.count % 2 == 0 else { return false }
        default: break
        }
        return true
    }

    // MARK: - Private Interfaces

    private func readSlotDatas() -> Bool {
        var success = false
        MKBXSInterface.readTriggerSlotData(index: index, sucBlock: { data in
            success = true
            self.updateSlotDatas(data)
            if self.slotType == .null {
                self.slotType = .sensorInfo
            }
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configTLM() -> Bool {
        var success = false
        MKBXSInterface.configSlotTriggeredTLM(index: index,
                                               advParams: currentTriggerContentParam(),
                                               sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configUID() -> Bool {
        var success = false
        MKBXSInterface.configSlotTriggeredUID(index: index,
                                               advParams: currentTriggerContentParam(),
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
        MKBXSInterface.configSlotTriggeredURL(index: index,
                                               advParams: currentTriggerContentParam(),
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
        MKBXSInterface.configSlotTriggeredBeacon(index: index,
                                                  advParams: currentTriggerContentParam(),
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
        MKBXSInterface.configSlotTriggeredSensorInfo(index: index,
                                                      advParams: currentTriggerContentParam(),
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
        MKBXSInterface.configSlotTriggeredNoData(index: index,
                                                  advParams: currentTriggerContentParam(),
                                                  sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }
}
