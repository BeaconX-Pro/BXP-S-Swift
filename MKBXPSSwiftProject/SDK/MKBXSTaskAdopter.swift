//
//  MKBXSTaskAdopter.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/14.
//

import Foundation
import CoreBluetooth

import MKSwiftBleModule

// MARK: - 分帧数据 Key

public let mk_bxs_totalNumKey   = "mk_bxs_totalNumKey"
public let mk_bxs_totalIndexKey = "mk_bxs_totalIndexKey"
public let mk_bxs_contentKey    = "mk_bxs_contentKey"

// MARK: - Task Adopter

public enum MKBXSTaskAdopter {

    // MARK: - Public

    public static func parseReadDataWithCharacteristic(_ characteristic: CBCharacteristic) -> [String: Any] {
        guard let readData = characteristic.value else { return [:] }
        let uuidString = characteristic.uuid.uuidString.uppercased()

        switch uuidString {
        case "AA01":
            return parseCustomData(readData)
        case "AA04":
            return parsePasswordData(readData)
        case "AA06":
            return parseHTData(readData)
        case "AA08":
            return parseHallSensorData(readData)
        default:
            return [:]
        }
    }

    public static func parseWriteDataWithCharacteristic(_ characteristic: CBCharacteristic) -> [String: Any] {
        return [:]
    }

    // MARK: - HT Data

    private static func parseHTData(_ readData: Data) -> [String: Any] {
        let readString = MKSwiftBleSDKAdopter.hexStringFromData(readData)
        guard readString.bleSubstring(from: 0, length: 2) == "eb" else { return [:] }

        let dataLen = MKSwiftBleSDKAdopter.getDecimalWithHex(readString, range: NSRange(location: 6, length: 2))
        guard readData.count == dataLen + 4 else { return [:] }

        let flag    = readString.bleSubstring(from: 2, length: 2)
        let cmd     = readString.bleSubstring(from: 4, length: 2)
        let content = readString.bleSubstring(from: 8, length: dataLen * 2)

        if flag == "00" {
            return parseHTReadData(content, cmd: cmd, data: readData)
        }
        if flag == "01" {
            return parseHTConfigData(content, cmd: cmd)
        }
        return [:]
    }

    private static func parseHTReadData(_ content: String, cmd: String, data: Data) -> [String: Any] {
        var operationID: MKBXSTaskOperationID = .defaultTask
        var resultDic: [String: Any] = [:]

        if cmd == "70" {
            operationID = .readTemperatureHumidityData
            let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 0, length: 4))
            let tempHui  = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 4, length: 4))
            resultDic = [
                "temperature": String(format: "%.1f", Double(tempTemp) * 0.1),
                "humidity":    String(format: "%.1f", Double(tempHui) * 0.1)
            ]
        }
        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }

    private static func parseHTConfigData(_ content: String, cmd: String) -> [String: Any] {
        var operationID: MKBXSTaskOperationID = .defaultTask
        let success = content == "aa"

        if cmd == "51" {
            operationID = .connectPassword
        } else if cmd == "52" {
            operationID = .configConnectPassword
        } else if cmd == "53" {
            operationID = .configPasswordVerification
        }
        return dataParserGetDataSuccess(["success": success], operationID: operationID)
    }

    // MARK: - Password Data

    private static func parsePasswordData(_ readData: Data) -> [String: Any] {
        let readString = MKSwiftBleSDKAdopter.hexStringFromData(readData)
        guard readString.bleSubstring(from: 0, length: 2) == "eb" else { return [:] }

        let dataLen = MKSwiftBleSDKAdopter.getDecimalWithHex(readString, range: NSRange(location: 6, length: 2))
        guard readData.count == dataLen + 4 else { return [:] }

        let flag    = readString.bleSubstring(from: 2, length: 2)
        let cmd     = readString.bleSubstring(from: 4, length: 2)
        let content = readString.bleSubstring(from: 8, length: dataLen * 2)

        if flag == "00" {
            return parsePasswordReadData(content, cmd: cmd, data: readData)
        }
        if flag == "01" {
            return parsePasswordConfigData(content, cmd: cmd)
        }
        return [:]
    }

    private static func parsePasswordReadData(_ content: String, cmd: String, data: Data) -> [String: Any] {
        var operationID: MKBXSTaskOperationID = .defaultTask
        var resultDic: [String: Any] = [:]

        if cmd == "53" {
            operationID = .readNeedPassword
            resultDic = ["state": content]
        }
        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }

    private static func parsePasswordConfigData(_ content: String, cmd: String) -> [String: Any] {
        var operationID: MKBXSTaskOperationID = .defaultTask
        let success = content == "aa"

        if cmd == "51" {
            operationID = .connectPassword
        } else if cmd == "52" {
            operationID = .configConnectPassword
        } else if cmd == "53" {
            operationID = .configPasswordVerification
        }
        return dataParserGetDataSuccess(["success": success], operationID: operationID)
    }

    // MARK: - Custom Data

    private static func parseCustomData(_ readData: Data) -> [String: Any] {
        let readString = MKSwiftBleSDKAdopter.hexStringFromData(readData)
        let headerString = readString.bleSubstring(from: 0, length: 2)

        if headerString == "ec" {
            return parseMultiPacketData(readString)
        }
        guard headerString == "eb" else { return [:] }

        let dataLen = MKSwiftBleSDKAdopter.getDecimalWithHex(readString, range: NSRange(location: 6, length: 2))
        guard readData.count == dataLen + 4 else { return [:] }

        let flag    = readString.bleSubstring(from: 2, length: 2)
        let cmd     = readString.bleSubstring(from: 4, length: 2)
        let content = readString.bleSubstring(from: 8, length: dataLen * 2)

        if flag == "00" {
            return parseCustomReadData(content, cmd: cmd, data: readData)
        }
        if flag == "01" {
            return parseCustomConfigData(content, cmd: cmd)
        }
        return [:]
    }

    private static func parseCustomReadData(_ content: String, cmd: String, data: Data) -> [String: Any] {
        var operationID: MKBXSTaskOperationID = .defaultTask
        var resultDic: [String: Any] = [:]

        switch cmd {
        // ==================== 0x20 - 0x2F ====================
        case "20":
            operationID = .readMacAddress
            let macAddress = [
                content.bleSubstring(from: 0, length: 2),
                content.bleSubstring(from: 2, length: 2),
                content.bleSubstring(from: 4, length: 2),
                content.bleSubstring(from: 6, length: 2),
                content.bleSubstring(from: 8, length: 2),
                content.bleSubstring(from: 10, length: 2)
            ].joined(separator: ":").uppercased()
            resultDic = ["macAddress": macAddress]

        case "21":
            operationID = .readThreeAxisDataParams
            resultDic = [
                "samplingRate": content.bleSubstring(from: 0, length: 2),
                "gravityReference": content.bleSubstring(from: 2, length: 2),
                "motionThreshold": MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 4, length: 2))
            ]

        case "23":
            operationID = .readResetDeviceByButtonStatus
            resultDic = ["isOn": content == "01"]

        case "24":
            operationID = .readTriggeredSlotParams
            let slotIndex   = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: 2))
            let advInterval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 2, length: 4))
            let advDuration = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 6, length: 4))
            let rssi        = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 10, length: 2))
            let txPower     = MKBXSSDKDataAdopter.fetchTxPowerValueString(content.bleSubstring(from: 12, length: 2))
            resultDic = [
                "slotIndex": slotIndex,
                "advInterval": advInterval,
                "advDuration": advDuration,
                "rssi": "\(rssi)",
                "txPower": txPower
            ]

        case "25":
            operationID = .readHallSensorStatus
            resultDic = ["isOn": content == "01"]

        case "29":
            operationID = .readFirmware
            let tempString = String(data: data.subdata(in: 4..<data.count), encoding: .utf8) ?? ""
            resultDic = ["firmware": tempString]

        case "2a":
            operationID = .readManufacturer
            let tempString = String(data: data.subdata(in: 4..<data.count), encoding: .utf8) ?? ""
            resultDic = ["manufacturer": tempString]

        case "2b":
            operationID = .readProductDate
            let year  = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: 4))
            var month = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 4, length: 2))
            if month.count == 1 { month = "0" + month }
            var day   = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 6, length: 2))
            if day.count == 1 { day = "0" + day }
            resultDic = ["productionDate": "\(year)/\(month)/\(day)"]

        case "2c":
            operationID = .readSoftware
            let tempString = String(data: data.subdata(in: 4..<data.count), encoding: .utf8) ?? ""
            resultDic = ["software": tempString]

        case "2d":
            operationID = .readHardware
            let tempString = String(data: data.subdata(in: 4..<data.count), encoding: .utf8) ?? ""
            resultDic = ["hardware": tempString]

        case "2e":
            operationID = .readDeviceModel
            let tempString = String(data: data.subdata(in: 4..<data.count), encoding: .utf8) ?? ""
            resultDic = ["modeID": tempString]

        case "2f":
            operationID = .readDeviceType
            let chipType = content.bleSubstring(from: 0, length: 2)
            let binary = MKSwiftBleSDKAdopter.binaryByhex(content.bleSubstring(from: 2, length: 2))
            resultDic = [
                "chipType": chipType,
                "threeAxis":    binary.bleSubstring(from: 7, length: 1) == "1",
                "tempHumidity": binary.bleSubstring(from: 6, length: 1) == "1",
                "hall":         binary.bleSubstring(from: 5, length: 1) == "1",
                "infrared":     binary.bleSubstring(from: 4, length: 1) == "1",
                "sixAxis":      binary.bleSubstring(from: 3, length: 1) == "1",
                "flash":        binary.bleSubstring(from: 2, length: 1) == "1",
                "pir":          binary.bleSubstring(from: 1, length: 1) == "1"
            ]

        // ==================== 0x30 - 0x3F ====================
        case "30":
            operationID = .readSlotType
            resultDic = ["slotList": [
                content.bleSubstring(from: 0, length: 2),
                content.bleSubstring(from: 2, length: 2),
                content.bleSubstring(from: 4, length: 2)
            ]]

        case "31":
            operationID = .readSlotTriggerData
            resultDic = MKBXSSDKDataAdopter.parseSlotTriggerParam(content)

        case "32":
            operationID = .readBeforeTriggerSlotData
            resultDic = MKBXSSDKDataAdopter.parseSlotData(content, advData: data, hasStandbyDuration: true)

        case "33":
            operationID = .readTriggerSlotData
            resultDic = MKBXSSDKDataAdopter.parseSlotData(content, advData: data, hasStandbyDuration: false)

        case "34":
            operationID = .readSlotData
            resultDic = MKBXSSDKDataAdopter.parseSlotData(content, advData: data, hasStandbyDuration: true)

        case "35":
            operationID = .readADVChannel
            let channel = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["channel": channel]

        case "36":
            operationID = .readDirectionFindingStatus
            resultDic = ["isOn": content == "01"]

        case "37":
            operationID = .readConnectable
            resultDic = ["connectable": content == "01"]

        case "3c":
            operationID = .readTagIDAutofillStatus
            resultDic = ["isOn": content == "01"]

        case "3e":
            operationID = .readDeviceRuntime
            let time = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["time": time]

        case "3f":
            operationID = .readDeviceUTCTime
            let timestamp = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["timestamp": timestamp]

        // ==================== 0x40 - 0x4F ====================
        case "40":
            operationID = .readTHDataStoreStatus
            let isOn = content.bleSubstring(from: 0, length: 2) == "01"
            let interval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 2, length: 4))
            resultDic = ["isOn": isOn, "interval": interval]

        case "41":
            operationID = .readTHSamplingRate
            let count = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["samplingRate": count]

        case "43":
            operationID = .readHTRecordTotalNumbers
            let count = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["count": count]

        case "4a":
            operationID = .readSensorType
            resultDic = [
                "axis":         MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: 2)),
                "tempHumidity": MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 2, length: 2)),
                "lightSensor":  MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 4, length: 2)),
                "pir":          MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 6, length: 2)),
                "tof":          MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 8, length: 2))
            ]

        // ==================== 0x60 - 0x6F ====================
        case "63":
            operationID = .readRemoteReminderBuzzerFrequency
            let frequency = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["frequency": frequency == 4500 ? "1" : "0"]

        case "65":
            operationID = .readTriggerLEDIndicatorStatus
            resultDic = ["isOn": content == "01"]

        case "68":
            operationID = .readHallTriggerCount
            let count = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["count": count]

        case "69":
            operationID = .readMotionTriggerCount
            let count = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["count": count]

        case "6a":
            operationID = .readBatteryVoltage
            let voltage = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["voltage": voltage]

        case "6b":
            operationID = .readBatteryPercentage
            let percentage = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["percentage": percentage]

        case "6c":
            operationID = .readBatteryADVMode
            let mode = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["mode": "\(mode - 1)"]

        case "6d":
            operationID = .readHallDataStoreStatus
            resultDic = ["isOn": content == "01"]

        case "71":
            operationID = .readTemperatureTriggerParams
            let isOn = content.bleSubstring(from: 0, length: 2) == "01"
            let max  = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 2, length: 4))
            let min  = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 6, length: 4))
            resultDic = [
                "isOn": isOn,
                "maxTemperature": String(format: "%.1f", Double(max) * 0.1),
                "minTemperature": String(format: "%.1f", Double(min) * 0.1)
            ]

        case "72":
            operationID = .readTempTriggerCount
            let count = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["count": count]

        case "74":
            operationID = .readStorageStartDelay
            let delay = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["delay": delay]

        case "75":
            operationID = .readDeviceBoardType
            let board = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 0, length: content.count))
            resultDic = ["board": board]

        case "76":
            operationID = .readDeviceMarkData
            resultDic = ["content": content]

        default:
            break
        }

        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }

    private static func parseCustomConfigData(_ content: String, cmd: String) -> [String: Any] {
        var operationID: MKBXSTaskOperationID = .defaultTask
        let success = content == "aa"

        switch cmd {
        // ==================== 0x20 - 0x2F ====================
        case "21": operationID = .configThreeAxisDataParams
        case "23": operationID = .configResetDeviceByButtonStatus
        case "24": operationID = .configTriggeredSlotParam
        case "25": operationID = .configHallSensorStatus
        case "26": operationID = .powerOff
        case "28": operationID = .factoryReset

        // ==================== 0x30 - 0x3F ====================
        case "31": operationID = .configSlotTriggerParams
        case "32": operationID = .configBeforeTriggerSlotData
        case "33": operationID = .configTriggerSlotData
        case "34": operationID = .configSlotData
        case "35": operationID = .configADVChannel
        case "36": operationID = .configDirectionFindingStatus
        case "37": operationID = .configConnectable
        case "3c": operationID = .configTagIDAutofillStatus
        case "3f": operationID = .configDeviceTime

        // ==================== 0x40 - 0x4F ====================
        case "40": operationID = .configTHDataStoreStatus
        case "41": operationID = .configTHSamplingRate
        case "42": operationID = .deleteBXPRecordHTDatas

        // ==================== 0x60 - 0x6F ====================
        case "61": operationID = .configRemoteReminderLEDNotiParams
        case "62": operationID = .configRemoteReminderBuzzerNotiParams
        case "63": operationID = .configRemoteReminderBuzzerFrequency
        case "65": operationID = .configTriggerLEDIndicatorStatus
        case "68": operationID = .clearHallTriggerCount
        case "69": operationID = .clearMotionTriggerCount
        case "6b": operationID = .configBatteryReset
        case "6c": operationID = .configBatteryADVMode
        case "6d": operationID = .configHallDataStoreStatus
        case "6f": operationID = .clearHallHistoryData
        case "71": operationID = .configTempTriggerParams
        case "72": operationID = .clearTemperatureTriggerCount
        case "74": operationID = .configStorageStartDelay
        case "76": operationID = .clearMarkData

        default: break
        }

        return dataParserGetDataSuccess(["success": success], operationID: operationID)
    }

    // MARK: - Hall Sensor Data

    private static func parseHallSensorData(_ readData: Data) -> [String: Any] {
        let readString = MKSwiftBleSDKAdopter.hexStringFromData(readData)
        let headerString = readString.bleSubstring(from: 0, length: 2)

        guard headerString == "eb" else { return [:] }

        let dataLen = MKSwiftBleSDKAdopter.getDecimalWithHex(readString, range: NSRange(location: 6, length: 2))
        guard readData.count == dataLen + 4 else { return [:] }

        let flag    = readString.bleSubstring(from: 2, length: 2)
        let cmd     = readString.bleSubstring(from: 4, length: 2)
        let content = readString.bleSubstring(from: 8, length: dataLen * 2)

        guard flag == "00" else { return [:] }

        var operationID: MKBXSTaskOperationID = .defaultTask
        var resultDic: [String: Any] = [:]

        if cmd == "90" {
            operationID = .readMagnetStatus
            resultDic = ["moved": content == "01"]
        }

        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }

    // MARK: - Multi Packet Data

    private static func parseMultiPacketData(_ content: String) -> [String: Any] {
        let flag = content.bleSubstring(from: 2, length: 2)
        let cmd  = content.bleSubstring(from: 4, length: 2)

        guard flag == "00" else { return [:] }

        let totalNum = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 6, length: 4))
        let index    = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content, range: NSRange(location: 10, length: 4))
        _ = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 14, length: 2))

        var operationID: MKBXSTaskOperationID = .defaultTask

        let resultDic: [String: Any] = [
            mk_bxs_totalNumKey:   totalNum,
            mk_bxs_totalIndexKey: index,
            mk_bxs_contentKey:    content.bleSubstring(from: 16, length: content.count - 16)
        ]
        if cmd == "6e" {
            operationID = .readHallHistoryData
        }
        return dataParserGetDataSuccess(resultDic, operationID: operationID)
    }

    // MARK: - Private Helper

    private static func dataParserGetDataSuccess(_ returnData: [String: Any]?,
                                                 operationID: MKBXSTaskOperationID) -> [String: Any] {
        guard let returnData = returnData else { return [:] }
        return [
            "returnData": returnData,
            "operationID": operationID.rawValue
        ]
    }
}
