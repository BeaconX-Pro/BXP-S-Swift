//
//  MKBXSDeviceInfoModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

import MKBaseSwiftModule

public final class MKBXSDeviceInfoModel: NSObject, @unchecked Sendable {

    public var software: String = ""
    public var firmware: String = ""
    public var hardware: String = ""
    public var voltage: String = ""
    public var batteryPercent: String = ""
    public var macAddress: String = ""
    public var productMode: String = ""
    public var manu: String = ""
    public var manuDate: String = ""

    private let readQueue = DispatchQueue(label: "deviceInfoParamsQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    public func readData(sucBlock: @escaping () -> Void,
                         failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readMacAddress() else { self.operationFailed("Read mac address error", failedBlock: failedBlock); return }
            guard self.readBatteryVoltage() else { self.operationFailed("Read battery voltage error", failedBlock: failedBlock); return }
            guard self.readBatteryPercent() else { self.operationFailed("Read battery percent error", failedBlock: failedBlock); return }
            guard self.readDeviceModel() else { self.operationFailed("Read device model error", failedBlock: failedBlock); return }
            guard self.readSoftware() else { self.operationFailed("Read software error", failedBlock: failedBlock); return }
            guard self.readHardware() else { self.operationFailed("Read hardware error", failedBlock: failedBlock); return }
            guard self.readFirmware() else { self.operationFailed("Read firmware error", failedBlock: failedBlock); return }
            guard self.readManu() else { self.operationFailed("Read manu error", failedBlock: failedBlock); return }
            guard self.readManuDate() else { self.operationFailed("Read manu date error", failedBlock: failedBlock); return }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    private func readMacAddress() -> Bool {
        var success = false
        MKBXSInterface.readMacAddress(sucBlock: { data in
            success = true
            self.macAddress = (data["macAddress"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readBatteryVoltage() -> Bool {
        var success = false
        MKBXSInterface.readBatteryVoltage(sucBlock: { data in
            success = true
            self.voltage = (data["voltage"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readBatteryPercent() -> Bool {
        var success = false
        MKBXSInterface.readBatteryPercentage(sucBlock: { data in
            success = true
            self.batteryPercent = (data["percentage"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readDeviceModel() -> Bool {
        var success = false
        MKBXSInterface.readDeviceModel(sucBlock: { data in
            success = true
            self.productMode = (data["modeID"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readSoftware() -> Bool {
        var success = false
        MKBXSInterface.readSoftware(sucBlock: { data in
            success = true
            self.software = (data["software"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readFirmware() -> Bool {
        var success = false
        MKBXSInterface.readFirmware(sucBlock: { data in
            success = true
            self.firmware = (data["firmware"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readHardware() -> Bool {
        var success = false
        MKBXSInterface.readHardware(sucBlock: { data in
            success = true
            self.hardware = (data["hardware"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readManu() -> Bool {
        var success = false
        MKBXSInterface.readManufacturer(sucBlock: { data in
            success = true
            self.manu = (data["manufacturer"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func readManuDate() -> Bool {
        var success = false
        MKBXSInterface.readProductionDate(sucBlock: { data in
            success = true
            self.manuDate = (data["productionDate"] as? String) ?? ""
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func operationFailed(_ msg: String, failedBlock: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "deviceInformation", code: -999, userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}
