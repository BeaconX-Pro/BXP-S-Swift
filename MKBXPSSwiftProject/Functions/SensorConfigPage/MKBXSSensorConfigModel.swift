//
//  MKBXSSensorConfigModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

import MKBaseSwiftModule

public final class MKBXSSensorConfigModel: NSObject, @unchecked Sendable {

    public var hallStatus: Bool = false
    public var resetByButton: Bool = false
    public var asix: Int = 0
    public var th: Int = 0

    private let readQueue = DispatchQueue(label: "sensorConfigQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    public func readData(sucBlock: @escaping () -> Void,
                         failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readHallSensorState() else {
                self.operationFailed("Read Hall Error", failedBlock: failedBlock)
                return
            }
            guard self.readResetByButton() else {
                self.operationFailed("Read Reset By Button Error", failedBlock: failedBlock)
                return
            }
            guard self.readSensorType() else {
                self.operationFailed("Read Sensor Type Error", failedBlock: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    private func readHallSensorState() -> Bool {
        var success = false
        MKBXSInterface.readHallSensorStatus(sucBlock: { data in
            success = true
            self.hallStatus = (data["isOn"] as? Bool) ?? false
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

    private func readSensorType() -> Bool {
        var success = false
        MKBXSInterface.readSensorType(sucBlock: { data in
            success = true
            self.asix = (data["axis"] as? Int) ?? 0
            self.th = (data["tempHumidity"] as? Int) ?? 0
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func operationFailed(_ msg: String, failedBlock: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "sensorConfigPage", code: -999, userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}
