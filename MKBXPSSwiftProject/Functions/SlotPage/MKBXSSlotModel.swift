//
//  MKBXSSlotModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

import MKBaseSwiftModule

public final class MKBXSSlotModel: NSObject, @unchecked Sendable {

    public var slot1: String = ""
    public var slot2: String = ""
    public var slot3: String = ""

    public private(set) var slot0Trigger: Bool = false
    public private(set) var slot1Trigger: Bool = false
    public private(set) var slot2Trigger: Bool = false

    private let readQueue = DispatchQueue(label: "slotTypeQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    public func readData(sucBlock: @escaping () -> Void,
                         failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readSlotType() else {
                self.operationFailed("Read Slot Type Error", failedBlock: failedBlock); return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    private func readSlotType() -> Bool {
        var success = false
        MKBXSInterface.readSlotType(sucBlock: { data in
            success = true
            if let slotList = data["slotList"] as? [String], slotList.count == 3 {
                self.slot1 = self.fetchSlotType(slotList[0])
                self.slot2 = self.fetchSlotType(slotList[1])
                self.slot3 = self.fetchSlotType(slotList[2])
            }
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func fetchSlotType(_ type: String) -> String {
        switch type {
        case "00": return "UID"
        case "10": return "URL"
        case "20": return "TLM"
        case "50": return "iBeacon"
        case "70": return "T&H_INFOR"
        case "80": return "Sensor info"
        case "ff": return "No data"
        default: return ""
        }
    }

    private func operationFailed(_ msg: String, failedBlock: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "slotType", code: -999, userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}
