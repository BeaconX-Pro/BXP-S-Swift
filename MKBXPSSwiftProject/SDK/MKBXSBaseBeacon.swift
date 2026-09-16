//
//  MKBXSBaseBeacon.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import CoreBluetooth

import MKSwiftBleModule

// MARK: - 广播帧类型

public enum MKBXSDataFrameType: Int, Sendable {
    case uid = 0
    case url = 1
    case tlm = 2
    case sensorInfo = 3
    case beacon = 4
    case productionTest = 5
    case ota = 6
    case unknown = 7
}

// MARK: - 基类

open class MKBXSBaseBeacon: NSObject, @unchecked Sendable {

    public var frameType: MKBXSDataFrameType = .unknown
    public var rssi: NSNumber = 0
    public var connectEnable: Bool = false
    public var identifier: String = ""
    public var peripheral: CBPeripheral?
    public var advertiseData: Data?
    public var deviceName: String?

    public override init() {
        super.init()
    }

    // MARK: - 解析广播数据

    public static func parseAdvData(_ advData: [String: Any]) -> [MKBXSBaseBeacon] {
        guard !advData.isEmpty else { return [] }
        guard let serviceData = advData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] else {
            return []
        }

        var beaconList: [MKBXSBaseBeacon] = []

        for (key, value) in serviceData {
            if key == CBUUID(string: "FEAA") {
                guard !value.isEmpty else { continue }
                let frameType = fetchFEAAFrameType(value)
                if let beacon = fetchBaseBeacon(frameType: frameType, advData: value) {
                    beaconList.append(beacon)
                }
            } else if key == CBUUID(string: "FEAB") {
                guard !value.isEmpty else { continue }
                let frameType = fetchFEABFrameType(value)
                if let beacon = fetchBaseBeacon(frameType: frameType, advData: value) {
                    if let iBeacon = beacon as? MKBXSiBeacon {
                        iBeacon.txPower = (advData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber) ?? 0
                    }
                    beaconList.append(beacon)
                }
            } else if key == CBUUID(string: "EA01") {
                guard !value.isEmpty else { continue }
                let frameType = fetchEA01FrameType(value)
                if let beacon = fetchBaseBeacon(frameType: frameType, advData: value) {
                    beaconList.append(beacon)
                }
            } else if key == CBUUID(string: "EB01") {
                guard !value.isEmpty else { continue }
                let frameType = fetchEB01FrameType(value)
                if let beacon = fetchBaseBeacon(frameType: frameType, advData: value) {
                    beaconList.append(beacon)
                }
            }
        }

        return beaconList
    }

    // MARK: - Slot 数据类型

    public static func parseDataTypeWithSlotData(_ slotData: Data) -> MKBXSDataFrameType {
        guard !slotData.isEmpty else { return .unknown }
        switch slotData[0] {
        case 0x00: return .uid
        case 0x10: return .url
        case 0x20: return .tlm
        case 0x80: return .sensorInfo
        case 0x50: return .beacon
        default:   return .unknown
        }
    }

    // MARK: - Private

    private static func fetchBaseBeacon(frameType: MKBXSDataFrameType, advData: Data) -> MKBXSBaseBeacon? {
        var beacon: MKBXSBaseBeacon?
        switch frameType {
        case .uid:
            beacon = MKBXSUIDBeacon(advData: advData)
        case .url:
            beacon = MKBXSURLBeacon(advData: advData)
        case .tlm:
            beacon = MKBXSTLMBeacon(advData: advData)
        case .sensorInfo:
            beacon = MKBXSSensorInfoBeacon(advData: advData)
        case .beacon:
            beacon = MKBXSiBeacon(advData: advData)
        case .productionTest:
            beacon = MKBXSProductionTestBeacon(advData: advData)
        case .ota:
            beacon = MKBXSOTABeacon(advData: advData)
        default:
            return nil
        }
        beacon?.frameType = frameType
        beacon?.advertiseData = advData
        return beacon
    }

    private static func fetchFEAAFrameType(_ data: Data) -> MKBXSDataFrameType {
        guard !data.isEmpty else { return .unknown }
        switch data[0] {
        case 0x00: return .uid
        case 0x10: return .url
        case 0x20: return .tlm
        default:   return .unknown
        }
    }

    private static func fetchFEABFrameType(_ data: Data) -> MKBXSDataFrameType {
        guard !data.isEmpty else { return .unknown }
        switch data[0] {
        case 0x50: return .beacon
        default:   return .unknown
        }
    }

    private static func fetchEA01FrameType(_ data: Data) -> MKBXSDataFrameType {
        guard !data.isEmpty else { return .unknown }
        switch data[0] {
        case 0x80: return .sensorInfo
        default:   return .unknown
        }
    }

    private static func fetchEB01FrameType(_ data: Data) -> MKBXSDataFrameType {
        guard !data.isEmpty else { return .unknown }
        switch data[0] {
        case 0x90: return .productionTest
        default:   return .unknown
        }
    }
}

// MARK: - UID Beacon

public final class MKBXSUIDBeacon: MKBXSBaseBeacon, @unchecked Sendable {

    /// RSSI@0m
    public var txPower: NSNumber = 0
    public var namespaceId: String = ""
    public var instanceId: String = ""

    public init?(advData: Data) {
        super.init()
        // On the spec, its 20 bytes. But some beacons doesn't advertise the last 2 RFU bytes.
        guard advData.count >= 18 else { return nil }
        let bytes = [UInt8](advData)

        let txPowerChar = bytes[1]
        if txPowerChar & 0x80 != 0 {
            txPower = NSNumber(value: -0x100 + Int(txPowerChar))
        } else {
            txPower = NSNumber(value: Int(txPowerChar))
        }

        namespaceId = bytes[2...11].map { String(format: "%02x", $0) }.joined()
        instanceId  = bytes[12...17].map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - URL Beacon

public final class MKBXSURLBeacon: MKBXSBaseBeacon, @unchecked Sendable {

    /// RSSI@0m
    public var txPower: NSNumber = 0
    /// URL Content
    public var shortUrl: String = ""

    public init?(advData: Data) {
        super.init()
        guard advData.count >= 3 else { return nil }
        let bytes = [UInt8](advData)

        let txPowerChar = bytes[1]
        if txPowerChar & 0x80 != 0 {
            txPower = NSNumber(value: -0x100 + Int(txPowerChar))
        } else {
            txPower = NSNumber(value: Int(txPowerChar))
        }

        let urlScheme = MKBXSSDKDataAdopter.getUrlscheme(CChar(bitPattern: bytes[2]))
        var url = urlScheme
        for i in 0..<(advData.count - 3) {
            url += MKBXSSDKDataAdopter.getEncodedString(CChar(bitPattern: bytes[i + 3]))
        }
        shortUrl = url
    }
}

// MARK: - TLM Beacon

public final class MKBXSTLMBeacon: MKBXSBaseBeacon, @unchecked Sendable {

    public var version: NSNumber = 0
    public var mvPerbit: NSNumber = 0
    public var temperature: NSNumber = 0
    public var advertiseCount: NSNumber = 0
    public var deciSecondsSinceBoot: NSNumber = 0

    public init?(advData: Data) {
        super.init()
        guard advData.count >= 14 else { return nil }
        let bytes = [UInt8](advData)

        version = NSNumber(value: Int(bytes[1]))
        mvPerbit = NSNumber(value: (Int(bytes[2]) << 8) + Int(bytes[3]))

        let temperatureInt = bytes[4]
        if temperatureInt & 0x80 != 0 {
            temperature = NSNumber(value: Float(-0x100 + Int(temperatureInt)) + Float(bytes[5]) / 256.0)
        } else {
            temperature = NSNumber(value: Float(temperatureInt) + Float(bytes[5]) / 256.0)
        }

        let advCount = (Int(bytes[6]) * 16777216) + (Int(bytes[7]) * 65536) + (Int(bytes[8]) * 256) + Int(bytes[9])
        advertiseCount = NSNumber(value: advCount)

        let deciSec = (Double(Int(bytes[10]) * 16777216)
                       + Double(Int(bytes[11]) * 65536)
                       + Double(Int(bytes[12]) * 256)
                       + Double(bytes[13])) / 10.0
        deciSecondsSinceBoot = NSNumber(value: deciSec)
    }
}

// MARK: - Sensor Info Beacon

public final class MKBXSSensorInfoBeacon: MKBXSBaseBeacon, @unchecked Sendable {

    /// Hall sensor status. 1: The magnet is away (absent); 0: The magnet is close (present).
    public var magnetStatus: Bool = false

    /// Triaxial sensor status. 1: In progress; 0: Still (No mvt)
    public var moved: Bool = false

    /// Whether the device has a triaxial sensor.
    public var triaxialSensor: Bool = false

    /// Whether the device has a temperature sensor.
    public var tempSensor: Bool = false

    /// Whether the device has a humidity sensor.
    public var humiditySensor: Bool = false

    /// Whether the device has a flash.
    public var flash: Bool = false

    /// Hall 触发计数
    public var hallSensorCount: String = ""

    /// 移动触发计数
    public var movedCount: String = ""

    /// X-axis data.(mg)
    public var xData: String = ""

    /// Y-axis data.(mg)
    public var yData: String = ""

    /// Z-axis data.(mg)
    public var zData: String = ""

    public var temperature: String = ""
    public var humidity: String = ""

    /// mV
    public var battery: String = ""
    public var tagID: String = ""

    public init?(advData: Data) {
        super.init()
        guard advData.count >= 16 else { return nil }

        var content = MKSwiftBleSDKAdopter.hexStringFromData(advData)
        content = String(content.dropFirst(2))

        let state = content.bleSubstring(from: 0, length: 2)
        let binary = MKSwiftBleSDKAdopter.binaryByhex(state)

        magnetStatus    = binary.bleSubstring(from: 7, length: 1) == "1"
        moved           = binary.bleSubstring(from: 6, length: 1) == "1"
        triaxialSensor  = binary.bleSubstring(from: 5, length: 1) == "1"
        tempSensor      = binary.bleSubstring(from: 4, length: 1) == "1"
        humiditySensor  = binary.bleSubstring(from: 3, length: 1) == "1"
        flash           = binary.bleSubstring(from: 2, length: 1) == "1"

        hallSensorCount = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 2, length: 4))
        movedCount      = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 6, length: 4))

        let xValue = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 10, length: 4))
        xData = "\(xValue)"
        let yValue = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 14, length: 4))
        yData = "\(yValue)"
        let zValue = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 18, length: 4))
        zData = "\(zValue)"

        let tempValue = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 22, length: 4))
        temperature = String(format: "%.f", Double(tempValue) * 0.1)

        let humidityValue = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 26, length: 4))
        humidity = String(format: "%.f", Double(humidityValue) * 0.1)

        battery = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 30, length: 4))
        tagID = content.bleSubstring(from: 34, length: content.count - 34)
    }
}

// MARK: - iBeacon

public final class MKBXSiBeacon: MKBXSBaseBeacon, @unchecked Sendable {

    /// RSSI@1m
    public var rssi1M: NSNumber = 0
    public var txPower: NSNumber = 0
    /// Advertising Interval
    public var interval: String = ""
    public var major: String = ""
    public var minor: String = ""
    public var uuid: String = ""

    public init?(advData: Data) {
        super.init()
        guard advData.count >= 7 else { return nil }
        let bytes = [UInt8](advData)

        let txPowerChar = bytes[1]
        if txPowerChar & 0x80 != 0 {
            rssi1M = NSNumber(value: -0x100 + Int(txPowerChar))
        } else {
            rssi1M = NSNumber(value: Int(txPowerChar))
        }

        let content = MKSwiftBleSDKAdopter.hexStringFromData(advData)
        let temp = content.bleSubstring(from: 4, length: content.count - 4)
        interval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(temp, range: NSRange(location: 0, length: 2))

        var array: [String] = [
            temp.bleSubstring(from: 2, length: 8),
            temp.bleSubstring(from: 10, length: 4),
            temp.bleSubstring(from: 14, length: 4),
            temp.bleSubstring(from: 18, length: 4),
            temp.bleSubstring(from: 22, length: 12)
        ]
        array.insert("-", at: 1)
        array.insert("-", at: 3)
        array.insert("-", at: 5)
        array.insert("-", at: 7)
        uuid = array.joined().uppercased()

        let majorStr = temp.bleSubstring(from: 34, length: 4)
        major = "\(strtoul(majorStr, nil, 16))"
        let minorStr = temp.bleSubstring(from: 38, length: 4)
        minor = "\(strtoul(minorStr, nil, 16))"
    }
}

// MARK: - Production Test Beacon

public final class MKBXSProductionTestBeacon: MKBXSBaseBeacon, @unchecked Sendable {

    /// mV
    public var battery: String = ""
    public var macAddress: String = ""

    public init?(advData: Data) {
        super.init()
        guard advData.count >= 8 else { return nil }

        let content = MKSwiftBleSDKAdopter.hexStringFromData(advData)
        battery = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 2, length: 4))

        let tempMac = content.bleSubstring(from: 6, length: 12).uppercased()
        macAddress = [
            tempMac.bleSubstring(from: 0, length: 2),
            tempMac.bleSubstring(from: 2, length: 2),
            tempMac.bleSubstring(from: 4, length: 2),
            tempMac.bleSubstring(from: 6, length: 2),
            tempMac.bleSubstring(from: 8, length: 2),
            tempMac.bleSubstring(from: 10, length: 2)
        ].joined(separator: ":")
    }
}

// MARK: - OTA Beacon

public final class MKBXSOTABeacon: MKBXSBaseBeacon, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public convenience init?(advData: Data) {
        self.init()
    }
}
