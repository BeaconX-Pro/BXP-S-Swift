//
//  MKBXSHallSensorConfigModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

import MKBaseSwiftModule

public final class MKBXSHallSensorConfigModel: NSObject, @unchecked Sendable {

    public var count: String = ""

    private let readQueue = DispatchQueue(label: "hallSensorQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    public func read(sucBlock: @escaping () -> Void,
                     failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.readTriggerCount() {
                self.operationFailed("Read Motion trigger count Error", failedBlock: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    private func readTriggerCount() -> Bool {
        var success = false
        // ⚠️ 这里用强引用 self：保证 semaphore.wait() 期间 self 不被释放，
        //    从而 signal 一定会被调用，避免死锁
        MKBXSInterface.readHallTriggerCount(sucBlock: { data in
            success = true
            self.count = (data["count"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in
            self.semaphore.signal()
        })
        semaphore.wait()
        return success
    }

    private func operationFailed(_ msg: String, failedBlock: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "hallSensor", code: -999, userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}
