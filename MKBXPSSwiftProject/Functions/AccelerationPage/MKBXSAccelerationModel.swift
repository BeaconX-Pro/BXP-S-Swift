//
//  MKBXSAccelerationModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

import MKBaseSwiftModule

public final class MKBXSAccelerationModel: NSObject, @unchecked Sendable {

    /// 0:1hz,1:10hz,2:25hz,3:50hz,4:100hz
    public var samplingRate: Int = 0
    /// 0:±2g,1:±4g,2:±8g,3:±16g
    public var scale: Int = 0
    public var threshold: String = ""
    public var triggerCount: String = ""

    private let readQueue = DispatchQueue(label: "accelerationQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    public func read(sucBlock: @escaping () -> Void,
                     failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readTriggerParams() else {
                self.operationFailed("Read Params Error", failedBlock: failedBlock)
                return
            }
            guard self.readTriggerCount() else {
                self.operationFailed("Read Motion trigger count Error", failedBlock: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    public func config(sucBlock: @escaping () -> Void,
                       failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.configTriggerParams() else {
                self.operationFailed("Config Params Error", failedBlock: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    // MARK: - Private

    private func readTriggerParams() -> Bool {
        var success = false
        MKBXSInterface.readThreeAxisDataParams(sucBlock: { returnData in
            success = true
            // ⬇️ samplingRate / gravityReference / motionThreshold 都是 String
            let samplingRateStr = (returnData["samplingRate"] as? String) ?? "0"
            let gravityRefStr = (returnData["gravityReference"] as? String) ?? "0"
            self.samplingRate = Int(samplingRateStr) ?? 0
            self.scale = Int(gravityRefStr) ?? 0
            self.threshold = (returnData["motionThreshold"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in
            self.semaphore.signal()
        })
        semaphore.wait()
        return success
    }

    private func readTriggerCount() -> Bool {
        var success = false
        MKBXSInterface.readMotionTriggerCount(sucBlock: { returnData in
            success = true
            self.triggerCount = (returnData["count"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in
            self.semaphore.signal()
        })
        semaphore.wait()
        return success
    }

    private func configTriggerParams() -> Bool {
        var success = false
        let rate = MKBXSThreeAxisDataRate(rawValue: samplingRate) ?? .hz1
        let ag = MKBXSThreeAxisDataAG(rawValue: scale) ?? .g2
        MKBXSInterface.configThreeAxisDataParams(dataRate: rate,
                                                 acceleration: ag,
                                                 motionThreshold: Int(threshold) ?? 0,
                                                 sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in
            self.semaphore.signal()
        })
        semaphore.wait()
        return success
    }

    private func operationFailed(_ msg: String, failedBlock: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "acceleration", code: -999, userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}
