//
//  MKBXSPeripheral.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import CoreBluetooth

import MKSwiftBleModule

public final class MKBXSPeripheral: NSObject, MKSwiftBlePeripheralProtocol, @unchecked Sendable {

    public let peripheral: CBPeripheral
    public let dfu: Bool

    public init(peripheral: CBPeripheral, dfu: Bool) {
        self.peripheral = peripheral
        self.dfu = dfu
        super.init()
    }

    public func discoverServices() {
        let services: [CBUUID] = [
            CBUUID(string: "180A"),
            CBUUID(string: "AA00"),
            CBUUID(string: kMKBXSOtaServerUUIDString)
        ]
        peripheral.discoverServices(services)
    }

    public func discoverCharacteristics() {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    public func updateCharacter(with service: CBService) {
        peripheral.bxs_updateCharacterWithService(service)
    }

    public func updateCurrentNotifySuccess(_ characteristic: CBCharacteristic) {
        peripheral.bxs_updateCurrentNotifySuccess(characteristic)
    }

    public var connectSuccess: Bool {
        peripheral.bxs_connectSuccess(dfu: dfu)
    }

    public func setNil() {
        peripheral.bxs_setNil()
    }
}
