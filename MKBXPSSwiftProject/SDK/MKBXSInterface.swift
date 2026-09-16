//
//  MKBXSInterface.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import CoreBluetooth

import MKSwiftBleModule

@MainActor
public enum MKBXSInterface {

    // MARK: - Private

    private static func makeError(_ message: String) -> NSError {
        NSError(domain: "com.moko.BXSInterface", code: -999, userInfo: ["errorInfo": message])
    }

    private static func readData(taskID: MKBXSTaskOperationID,
                                 cmdFlag: String,
                                 sucBlock: @escaping ([String: Any]) -> Void,
                                 failedBlock: @escaping (Error) -> Void) {
        let commandString = "ea00" + cmdFlag + "00"
        guard let characteristic = MKBXSCentralManager.shared.peripheral()?.bxs_custom else {
            failedBlock(makeError("Characteristic error"))
            return
        }
        MKBXSCentralManager.shared.addTask(taskID: taskID,
                                           characteristic: characteristic,
                                           commandData: commandString,
                                           successBlock: sucBlock,
                                           failureBlock: failedBlock)
    }

    private static func readPasswordData(taskID: MKBXSTaskOperationID,
                                         cmdFlag: String,
                                         sucBlock: @escaping ([String: Any]) -> Void,
                                         failedBlock: @escaping (Error) -> Void) {
        let commandString = "ea00" + cmdFlag + "00"
        guard let characteristic = MKBXSCentralManager.shared.peripheral()?.bxs_password else {
            failedBlock(makeError("Characteristic error"))
            return
        }
        MKBXSCentralManager.shared.addTask(taskID: taskID,
                                           characteristic: characteristic,
                                           commandData: commandString,
                                           successBlock: sucBlock,
                                           failureBlock: failedBlock)
    }

    // MARK: - 0x20 - 0x2F

    public static func readMacAddress(sucBlock: @escaping ([String: Any]) -> Void,
                                      failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readMacAddress, cmdFlag: "20", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readThreeAxisDataParams(sucBlock: @escaping ([String: Any]) -> Void,
                                               failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readThreeAxisDataParams, cmdFlag: "21", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readResetDeviceByButtonStatus(sucBlock: @escaping ([String: Any]) -> Void,
                                                     failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readResetDeviceByButtonStatus, cmdFlag: "23", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readTriggeredSlotParams(index: Int,
                                               sucBlock: @escaping ([String: Any]) -> Void,
                                               failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2 else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index + 3), byteLen: 1)
        let commandString = "ea002401" + indexString
        guard let characteristic = MKBXSCentralManager.shared.peripheral()?.bxs_custom else {
            failedBlock(makeError("Characteristic error"))
            return
        }
        MKBXSCentralManager.shared.addTask(taskID: .readTriggeredSlotParams,
                                           characteristic: characteristic,
                                           commandData: commandString,
                                           successBlock: sucBlock,
                                           failureBlock: failedBlock)
    }

    public static func readHallSensorStatus(sucBlock: @escaping ([String: Any]) -> Void,
                                            failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readHallSensorStatus, cmdFlag: "25", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readFirmware(sucBlock: @escaping ([String: Any]) -> Void,
                                    failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readFirmware, cmdFlag: "29", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readManufacturer(sucBlock: @escaping ([String: Any]) -> Void,
                                        failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readManufacturer, cmdFlag: "2a", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readProductionDate(sucBlock: @escaping ([String: Any]) -> Void,
                                          failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readProductDate, cmdFlag: "2b", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readSoftware(sucBlock: @escaping ([String: Any]) -> Void,
                                    failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readSoftware, cmdFlag: "2c", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readHardware(sucBlock: @escaping ([String: Any]) -> Void,
                                    failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readHardware, cmdFlag: "2d", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readDeviceModel(sucBlock: @escaping ([String: Any]) -> Void,
                                       failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readDeviceModel, cmdFlag: "2e", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readDeviceType(sucBlock: @escaping ([String: Any]) -> Void,
                                      failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readDeviceType, cmdFlag: "2f", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x30 - 0x3F

    public static func readSlotType(sucBlock: @escaping ([String: Any]) -> Void,
                                    failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readSlotType, cmdFlag: "30", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readSlotTriggerData(index: Int,
                                           sucBlock: @escaping ([String: Any]) -> Void,
                                           failedBlock: @escaping (Error) -> Void) {
        let commandString = "ea003101" + MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        guard let characteristic = MKBXSCentralManager.shared.peripheral()?.bxs_custom else {
            failedBlock(makeError("Characteristic error"))
            return
        }
        MKBXSCentralManager.shared.addTask(taskID: .readSlotTriggerData,
                                           characteristic: characteristic,
                                           commandData: commandString,
                                           successBlock: sucBlock,
                                           failureBlock: failedBlock)
    }

    public static func readBeforeTriggerSlotData(index: Int,
                                                 sucBlock: @escaping ([String: Any]) -> Void,
                                                 failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2 else {
            failedBlock(makeError("Params error"))
            return
        }
        let commandString = "ea003201" + MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        guard let characteristic = MKBXSCentralManager.shared.peripheral()?.bxs_custom else {
            failedBlock(makeError("Characteristic error"))
            return
        }
        MKBXSCentralManager.shared.addTask(taskID: .readBeforeTriggerSlotData,
                                           characteristic: characteristic,
                                           commandData: commandString,
                                           successBlock: sucBlock,
                                           failureBlock: failedBlock)
    }

    public static func readTriggerSlotData(index: Int,
                                           sucBlock: @escaping ([String: Any]) -> Void,
                                           failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2 else {
            failedBlock(makeError("Params error"))
            return
        }
        let commandString = "ea003301" + MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        guard let characteristic = MKBXSCentralManager.shared.peripheral()?.bxs_custom else {
            failedBlock(makeError("Characteristic error"))
            return
        }
        MKBXSCentralManager.shared.addTask(taskID: .readTriggerSlotData,
                                           characteristic: characteristic,
                                           commandData: commandString,
                                           successBlock: sucBlock,
                                           failureBlock: failedBlock)
    }

    public static func readSlotData(index: Int,
                                    sucBlock: @escaping ([String: Any]) -> Void,
                                    failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2 else {
            failedBlock(makeError("Params error"))
            return
        }
        let commandString = "ea003401" + MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        guard let characteristic = MKBXSCentralManager.shared.peripheral()?.bxs_custom else {
            failedBlock(makeError("Characteristic error"))
            return
        }
        MKBXSCentralManager.shared.addTask(taskID: .readSlotData,
                                           characteristic: characteristic,
                                           commandData: commandString,
                                           successBlock: sucBlock,
                                           failureBlock: failedBlock)
    }

    public static func readADVChannel(sucBlock: @escaping ([String: Any]) -> Void,
                                      failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readADVChannel, cmdFlag: "35", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readDirectionFindingStatus(sucBlock: @escaping ([String: Any]) -> Void,
                                                  failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readDirectionFindingStatus, cmdFlag: "36", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readConnectable(sucBlock: @escaping ([String: Any]) -> Void,
                                       failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readConnectable, cmdFlag: "37", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readTagIDAutofillStatus(sucBlock: @escaping ([String: Any]) -> Void,
                                               failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readTagIDAutofillStatus, cmdFlag: "3c", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readDeviceRuntime(sucBlock: @escaping ([String: Any]) -> Void,
                                         failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readDeviceRuntime, cmdFlag: "3e", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readDeviceUTCTime(sucBlock: @escaping ([String: Any]) -> Void,
                                         failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readDeviceUTCTime, cmdFlag: "3f", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x40 - 0x4F

    public static func readTHDataStoreParams(sucBlock: @escaping ([String: Any]) -> Void,
                                             failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readTHDataStoreStatus, cmdFlag: "40", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readHTSamplingRate(sucBlock: @escaping ([String: Any]) -> Void,
                                          failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readTHSamplingRate, cmdFlag: "41", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readHTRecordTotalNumbers(sucBlock: @escaping ([String: Any]) -> Void,
                                                failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readHTRecordTotalNumbers, cmdFlag: "43", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readSensorType(sucBlock: @escaping ([String: Any]) -> Void,
                                      failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readSensorType, cmdFlag: "4a", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x60 - 0x6F

    public static func readRemoteReminderBuzzerFrequency(sucBlock: @escaping ([String: Any]) -> Void,
                                                         failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readRemoteReminderBuzzerFrequency, cmdFlag: "63", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readTriggerLEDIndicatorStatus(sucBlock: @escaping ([String: Any]) -> Void,
                                                     failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readTriggerLEDIndicatorStatus, cmdFlag: "65", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readHallTriggerCount(sucBlock: @escaping ([String: Any]) -> Void,
                                            failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readHallTriggerCount, cmdFlag: "68", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readMotionTriggerCount(sucBlock: @escaping ([String: Any]) -> Void,
                                              failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readMotionTriggerCount, cmdFlag: "69", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readBatteryVoltage(sucBlock: @escaping ([String: Any]) -> Void,
                                          failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readBatteryVoltage, cmdFlag: "6a", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readBatteryPercentage(sucBlock: @escaping ([String: Any]) -> Void,
                                             failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readBatteryPercentage, cmdFlag: "6b", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readBatteryADVMode(sucBlock: @escaping ([String: Any]) -> Void,
                                          failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readBatteryADVMode, cmdFlag: "6c", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readHallDataStoreStatus(sucBlock: @escaping ([String: Any]) -> Void,
                                               failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readHallDataStoreStatus, cmdFlag: "6d", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readHallHistoryData(sucBlock: @escaping ([String: Any]) -> Void,
                                           failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readHallHistoryData, cmdFlag: "6e", sucBlock: { returnData in
            let list = MKBXSSDKDataAdopter.parseHallData(returnData["result"] as? [String] ?? [])
            sucBlock(["msg": "success", "code": "1", "result": ["list": list]])
        }, failedBlock: failedBlock)
    }

    public static func readTemperatureTrigger(sucBlock: @escaping ([String: Any]) -> Void,
                                              failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readTemperatureTriggerParams, cmdFlag: "71", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readTemperatureTriggerCount(sucBlock: @escaping ([String: Any]) -> Void,
                                                   failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readTempTriggerCount, cmdFlag: "72", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readStorageStartDelay(sucBlock: @escaping ([String: Any]) -> Void,
                                             failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readStorageStartDelay, cmdFlag: "74", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readDeviceBoardType(sucBlock: @escaping ([String: Any]) -> Void,
                                           failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readDeviceBoardType, cmdFlag: "75", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    public static func readDeviceMarkData(sucBlock: @escaping ([String: Any]) -> Void,
                                          failedBlock: @escaping (Error) -> Void) {
        readData(taskID: .readDeviceMarkData, cmdFlag: "76", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - AA06 温湿度 (0x70)

    public static func readTemperatureHumidityData(sucBlock: @escaping ([String: Any]) -> Void,
                                                   failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXSCentralManager.shared.peripheral()?.bxs_temperatureHumidity else {
            failedBlock(makeError("Characteristic error"))
            return
        }
        MKBXSCentralManager.shared.addReadTask(taskID: .readTemperatureHumidityData,
                                               characteristic: characteristic,
                                               successBlock: sucBlock,
                                               failureBlock: failedBlock)
    }

    // MARK: - AA07 密码 (0x53)

    public static func readPasswordVerification(sucBlock: @escaping ([String: Any]) -> Void,
                                                failedBlock: @escaping (Error) -> Void) {
        readPasswordData(taskID: .readNeedPassword, cmdFlag: "53", sucBlock: { returnData in
            let isOn = (returnData["state"] as? String) == "01"
            sucBlock(["msg": "success", "code": "1", "result": ["isOn": isOn]])
        }, failedBlock: failedBlock)
    }

    // MARK: - AA08 霍尔传感器 (0x90)

    public static func readMagnetStatus(sucBlock: @escaping ([String: Any]) -> Void,
                                        failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXSCentralManager.shared.peripheral()?.bxs_hallSensor else {
            failedBlock(makeError("Characteristic error"))
            return
        }
        MKBXSCentralManager.shared.addReadTask(taskID: .readMagnetStatus,
                                               characteristic: characteristic,
                                               successBlock: sucBlock,
                                               failureBlock: failedBlock)
    }
}
