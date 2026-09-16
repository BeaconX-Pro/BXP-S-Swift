//
//  MKBXSScanInfoCellModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import CoreBluetooth

import MKBaseSwiftModule

public final class MKBXSScanInfoCellModel: NSObject, @unchecked Sendable {

    public var advertiseList: [Any] = []
    public var rssi: String = ""
    public var connectEnable: Bool = false
    public var otaMode: Bool = false
    public var identifier: String = ""
    public var peripheral: CBPeripheral?
    public var deviceName: String = ""
    public var battery: String = ""
    public var macAddress: String = ""
    public var tagID: String = ""
    public var displayTime: String = ""
    public var lastScanDate: TimeInterval = 0

    public override init() { super.init() }
}
