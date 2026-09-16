//
//  MKBXSQuickSwitchModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

import MKBaseSwiftModule

public final class MKBXSQuickSwitchModel: NSObject, @unchecked Sendable {

    public var connectable: Bool = false
    public var trigger: Bool = false
    public var passwordVerification: Bool = false
    public var autoFill: Bool = false
    public var resetByButton: Bool = false
    public var turnOffByButton: Bool = false
    public var direction: Bool = false

    private let readQueue = DispatchQueue(label: "quickSwitchQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    public func read(sucBlock: @escaping () -> Void,
                     failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readConnectable() else { self.operationFailed("Read Connectable Error", failedBlock: failedBlock); return }
            guard self.readTriggerLEDIndicator() else { self.operationFailed("Read Trigger LED indicator Error", failedBlock: failedBlock); return }
            guard self.readPasswordVerification() else { self.operationFailed("Read Password verification Error", failedBlock: failedBlock); return }
            guard self.readTagIDFill() else { self.operationFailed("Read Tag ID Autofill Error", failedBlock: failedBlock); return }
            guard self.readResetByButton() else { self.operationFailed("Read Reset Beacon by button Error", failedBlock: failedBlock); return }
            guard self.readPowerOffByButton() else { self.operationFailed("Read Turn off Beacon by button Error", failedBlock: failedBlock); return }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    private func readConnectable() -> Bool {
        var success = false
        MKBXSInterface.readConnectable(sucBlock: { data in
            success = true
            self.connectable = (data["connectable"] as? Bool) ?? false
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readTriggerLEDIndicator() -> Bool {
        var success = false
        MKBXSInterface.readTriggerLEDIndicatorStatus(sucBlock: { data in
            success = true
            self.trigger = (data["isOn"] as? Bool) ?? false
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readPasswordVerification() -> Bool {
        var success = false
        MKBXSInterface.readPasswordVerification(sucBlock: { data in
            success = true
            self.passwordVerification = (data["isOn"] as? Bool) ?? false
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readTagIDFill() -> Bool {
        var success = false
        MKBXSInterface.readTagIDAutofillStatus(sucBlock: { data in
            success = true
            self.autoFill = (data["isOn"] as? Bool) ?? false
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readResetByButton() -> Bool {
        var success = false
        MKBXSInterface.readResetDeviceByButtonStatus(sucBlock: { data in
            success = true
            self.resetByButton = (data["isOn"] as? Bool) ?? false
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readPowerOffByButton() -> Bool {
        var success = false
        MKBXSInterface.readHallSensorStatus(sucBlock: { data in
            success = true
            self.turnOffByButton = (data["isOn"] as? Bool) ?? false
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func operationFailed(_ msg: String, failedBlock: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "quickSwitchParams", code: -999, userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}
