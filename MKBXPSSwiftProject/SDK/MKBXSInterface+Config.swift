//
//  MKBXSInterface+Config.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import CoreBluetooth

import MKSwiftBleModule

@MainActor
public extension MKBXSInterface {

    // MARK: - 私有工具

    private static func makeError(_ message: String) -> NSError {
        NSError(domain: "com.moko.BXSInterface", code: -999, userInfo: ["errorInfo": message])
    }

    private static func configData(taskID: MKBXSTaskOperationID,
                                   data: String,
                                   sucBlock: (() -> Void)?,
                                   failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXSCentralManager.shared.peripheral()?.bxs_custom else {
            failedBlock(makeError("Characteristic error"))
            return
        }
        MKBXSCentralManager.shared.addTask(taskID: taskID,
                                           characteristic: characteristic,
                                           commandData: data,
                                           successBlock: { returnData in
            let success = (returnData["success"] as? Bool) ?? false
            if !success {
                failedBlock(makeError("Set parameter error"))
                return
            }
            sucBlock?()
        }, failureBlock: failedBlock)
    }

    private static func configPasswordData(taskID: MKBXSTaskOperationID,
                                           data: String,
                                           sucBlock: (() -> Void)?,
                                           failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXSCentralManager.shared.peripheral()?.bxs_password else {
            failedBlock(makeError("Characteristic error"))
            return
        }
        MKBXSCentralManager.shared.addTask(taskID: taskID,
                                           characteristic: characteristic,
                                           commandData: data,
                                           successBlock: { returnData in
            let success = (returnData["success"] as? Bool) ?? false
            if !success {
                failedBlock(makeError("Set parameter error"))
                return
            }
            sucBlock?()
        }, failureBlock: failedBlock)
    }

    // MARK: - 0x21 三轴传感器配置

    static func configThreeAxisDataParams(dataRate: MKBXSThreeAxisDataRate,
                                          acceleration: MKBXSThreeAxisDataAG,
                                          motionThreshold: Int,
                                          sucBlock: (() -> Void)?,
                                          failedBlock: @escaping (Error) -> Void) {
        guard motionThreshold >= 1, motionThreshold <= 255 else {
            failedBlock(makeError("Params error"))
            return
        }
        let rate = MKBXSSDKDataAdopter.fetchThreeAxisDataRate(dataRate)
        let ag = MKBXSSDKDataAdopter.fetchThreeAxisDataAG(acceleration)
        let threshold = MKSwiftBleSDKAdopter.fetchHexValue(UInt(motionThreshold), byteLen: 1)
        let commandString = "ea012103" + rate + ag + threshold
        configData(taskID: .configThreeAxisDataParams, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x23 按键复位配置

    static func configResetDeviceByButtonStatus(isOn: Bool,
                                                sucBlock: (() -> Void)?,
                                                failedBlock: @escaping (Error) -> Void) {
        let commandString = isOn ? "ea01230101" : "ea01230100"
        configData(taskID: .configResetDeviceByButtonStatus, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x24 触发后通道广播参数配置

    static func configTriggeredSlotParam(index: Int,
                                         advInterval: Int,
                                         advDuration: Int,
                                         rssi: Int,
                                         txPower: MKBXSTxPower,
                                         sucBlock: (() -> Void)?,
                                         failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2,
              advInterval >= 1, advInterval <= 100,
              advDuration >= 1, advDuration <= 65535,
              rssi >= -127, rssi <= 0 else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index + 3), byteLen: 1)
        let advIntervalValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(advInterval * 100), byteLen: 2)
        let advDurationValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(advDuration), byteLen: 2)
        let rssiValue = MKSwiftBleSDKAdopter.hexStringFromSignedNumber(rssi)
        let txPowerValue = MKBXSSDKDataAdopter.fetchTxPower(txPower)
        let commandString = "ea012407" + indexValue + advIntervalValue + advDurationValue + rssiValue + txPowerValue
        configData(taskID: .configTriggeredSlotParam, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x25 霍尔开关机配置

    static func configHallSensorStatus(isOn: Bool,
                                       sucBlock: (() -> Void)?,
                                       failedBlock: @escaping (Error) -> Void) {
        let commandString = isOn ? "ea01250101" : "ea01250100"
        configData(taskID: .configHallSensorStatus, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x26 关机

    static func configPowerOff(sucBlock: (() -> Void)?,
                               failedBlock: @escaping (Error) -> Void) {
        configData(taskID: .powerOff, data: "ea012600", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x28 恢复出厂设置

    static func factoryReset(sucBlock: (() -> Void)?,
                             failedBlock: @escaping (Error) -> Void) {
        configData(taskID: .factoryReset, data: "ea012800", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x31 触发参数配置

    static func closeSlotTrigger(index: Int,
                                 sucBlock: (() -> Void)?,
                                 failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2 else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let commandString = "ea013108" + indexValue + "00000000000000"
        configData(taskID: .configSlotTriggerParams, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configTemperatureTriggerParams(slotIndex: Int,
                                               triggerEvent: Int,
                                               temperature: Int,
                                               lockedADV: Bool,
                                               sucBlock: (() -> Void)?,
                                               failedBlock: @escaping (Error) -> Void) {
        guard slotIndex >= 0, slotIndex <= 2,
              temperature >= -40, temperature <= 150,
              triggerEvent >= 0, triggerEvent <= 1 else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(slotIndex), byteLen: 1)
        let eventHex = triggerEvent == 0 ? "10" : "11"
        let tempHex = MKBXSSDKDataAdopter.temperatureToHexString(temperature)
        let lockState = lockedADV ? "01" : "00"
        let staticPeriod = MKSwiftBleSDKAdopter.fetchHexValue(0, byteLen: 2)
        let commandString = "ea013108" + indexValue + "01" + eventHex + tempHex + lockState + staticPeriod
        configData(taskID: .configSlotTriggerParams, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configHumidityTriggerParams(slotIndex: Int,
                                            triggerEvent: Int,
                                            humidity: Int,
                                            lockedADV: Bool,
                                            sucBlock: (() -> Void)?,
                                            failedBlock: @escaping (Error) -> Void) {
        guard slotIndex >= 0, slotIndex <= 2,
              humidity >= 0, humidity <= 100,
              triggerEvent >= 0, triggerEvent <= 1 else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(slotIndex), byteLen: 1)
        let eventHex = triggerEvent == 0 ? "20" : "21"
        let humidityValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(humidity), byteLen: 2)
        let lockState = lockedADV ? "01" : "00"
        let staticPeriod = MKSwiftBleSDKAdopter.fetchHexValue(0, byteLen: 2)
        let commandString = "ea013108" + indexValue + "02" + eventHex + humidityValue + lockState + staticPeriod
        configData(taskID: .configSlotTriggerParams, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configMotionDetectionTriggerParams(slotIndex: Int,
                                                   triggerEvent: Int,
                                                   period: Int,
                                                   lockedADV: Bool,
                                                   sucBlock: (() -> Void)?,
                                                   failedBlock: @escaping (Error) -> Void) {
        guard slotIndex >= 0, slotIndex <= 2,
              period >= 1, period <= 65535,
              triggerEvent >= 0, triggerEvent <= 1 else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(slotIndex), byteLen: 1)
        let eventHex = triggerEvent == 0 ? "30" : "31"
        let lockState = lockedADV ? "01" : "00"
        let staticPeriod = MKSwiftBleSDKAdopter.fetchHexValue(UInt(period), byteLen: 2)
        let commandString = "ea013108" + indexValue + "03" + eventHex + "0000" + lockState + staticPeriod
        configData(taskID: .configSlotTriggerParams, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configHallTriggerParams(slotIndex: Int,
                                        triggerEvent: Int,
                                        lockedADV: Bool,
                                        sucBlock: (() -> Void)?,
                                        failedBlock: @escaping (Error) -> Void) {
        guard slotIndex >= 0, slotIndex <= 2,
              triggerEvent >= 0, triggerEvent <= 1 else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(slotIndex), byteLen: 1)
        let eventHex = triggerEvent == 0 ? "40" : "41"
        let lockState = lockedADV ? "01" : "00"
        let staticPeriod = MKSwiftBleSDKAdopter.fetchHexValue(0, byteLen: 2)
        let commandString = "ea013108" + indexValue + "04" + eventHex + "0000" + lockState + staticPeriod
        configData(taskID: .configSlotTriggerParams, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x32 触发前广播参数配置

    static func configSlotNoData(index: Int,
                                 type: MKBXSSlotDataType,
                                 advParams: any MKBXSSlotAdvContentParam,
                                 sucBlock: (() -> Void)?,
                                 failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2 else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let taskID: MKBXSTaskOperationID = type == .beforeTriggerData ? .configBeforeTriggerSlotData : .configSlotData
        let typeString = type == .beforeTriggerData ? "32" : "34"
        let len = 1 + paramsCmd.count / 2 + 1
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "ff"
        configData(taskID: taskID, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configSlotUID(index: Int,
                              type: MKBXSSlotDataType,
                              advParams: any MKBXSSlotAdvContentParam,
                              namespaceID: String,
                              instanceID: String,
                              sucBlock: (() -> Void)?,
                              failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2,
              namespaceID.count == 20, MKSwiftBleSDKAdopter.checkHexCharacter(namespaceID),
              instanceID.count == 12, MKSwiftBleSDKAdopter.checkHexCharacter(instanceID) else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let taskID: MKBXSTaskOperationID = type == .beforeTriggerData ? .configBeforeTriggerSlotData : .configSlotData
        let typeString = type == .beforeTriggerData ? "32" : "34"
        let len = 1 + paramsCmd.count / 2 + 1 + 10 + 6
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "00" + namespaceID + instanceID
        configData(taskID: taskID, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configSlotURL(index: Int,
                              type: MKBXSSlotDataType,
                              advParams: any MKBXSSlotAdvContentParam,
                              urlType: MKBXSURLHeaderType,
                              urlContent: String,
                              sucBlock: (() -> Void)?,
                              failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2 else {
            failedBlock(makeError("Params error"))
            return
        }
        let urlString = MKBXSSDKDataAdopter.fetchUrlString(urlType, urlContent: urlContent)
        guard !urlString.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let taskID: MKBXSTaskOperationID = type == .beforeTriggerData ? .configBeforeTriggerSlotData : .configSlotData
        let typeString = type == .beforeTriggerData ? "32" : "34"
        let len = 1 + paramsCmd.count / 2 + 1 + urlString.count / 2
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "10" + urlString
        configData(taskID: taskID, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configSlotTLM(index: Int,
                              type: MKBXSSlotDataType,
                              advParams: any MKBXSSlotAdvContentParam,
                              sucBlock: (() -> Void)?,
                              failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2 else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let taskID: MKBXSTaskOperationID = type == .beforeTriggerData ? .configBeforeTriggerSlotData : .configSlotData
        let typeString = type == .beforeTriggerData ? "32" : "34"
        let len = 1 + paramsCmd.count / 2 + 1
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "20"
        configData(taskID: taskID, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configSlotBeacon(index: Int,
                                 type: MKBXSSlotDataType,
                                 advParams: any MKBXSSlotAdvContentParam,
                                 major: Int,
                                 minor: Int,
                                 uuid: String,
                                 sucBlock: (() -> Void)?,
                                 failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2,
              major >= 0, major <= 65535,
              minor >= 0, minor <= 65535,
              uuid.count == 32, MKSwiftBleSDKAdopter.checkHexCharacter(uuid) else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let taskID: MKBXSTaskOperationID = type == .beforeTriggerData ? .configBeforeTriggerSlotData : .configSlotData
        let typeString = type == .beforeTriggerData ? "32" : "34"
        let len = 1 + paramsCmd.count / 2 + 1 + 20
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let majorValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(major), byteLen: 2)
        let minorValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(minor), byteLen: 2)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "50" + uuid + majorValue + minorValue
        configData(taskID: taskID, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configSlotSensorInfo(index: Int,
                                     type: MKBXSSlotDataType,
                                     advParams: any MKBXSSlotAdvContentParam,
                                     deviceName: String,
                                     tagID: String,
                                     sucBlock: (() -> Void)?,
                                     failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2,
              !deviceName.isEmpty, deviceName.count <= 20,
              !tagID.isEmpty, tagID.count <= 12, tagID.count % 2 == 0 else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let taskID: MKBXSTaskOperationID = type == .beforeTriggerData ? .configBeforeTriggerSlotData : .configSlotData
        let typeString = type == .beforeTriggerData ? "32" : "34"
        var tempString = ""
        for char in deviceName.utf8 {
            tempString += String(format: "%1x", char)
        }
        let nameLen = MKSwiftBleSDKAdopter.fetchHexValue(UInt(deviceName.count), byteLen: 1)
        let tagIDLen = MKSwiftBleSDKAdopter.fetchHexValue(UInt(tagID.count / 2), byteLen: 1)
        let len = 1 + paramsCmd.count / 2 + 1 + deviceName.count + tagID.count / 2 + 2
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let commandString = "ea01" + typeString + lenString + indexValue + paramsCmd + "80" + nameLen + tempString + tagIDLen + tagID
        configData(taskID: taskID, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x33 触发广播参数配置

    static func configSlotTriggeredNoData(index: Int,
                                          advParams: any MKBXSSlotTriggeredAdvContentParam,
                                          sucBlock: (() -> Void)?,
                                          failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2 else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let len = 1 + paramsCmd.count / 2 + 1
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "ff"
        configData(taskID: .configTriggerSlotData, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configSlotTriggeredUID(index: Int,
                                       advParams: any MKBXSSlotTriggeredAdvContentParam,
                                       namespaceID: String,
                                       instanceID: String,
                                       sucBlock: (() -> Void)?,
                                       failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2,
              namespaceID.count == 20, MKSwiftBleSDKAdopter.checkHexCharacter(namespaceID),
              instanceID.count == 12, MKSwiftBleSDKAdopter.checkHexCharacter(instanceID) else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let len = 1 + paramsCmd.count / 2 + 1 + 10 + 6
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "00" + namespaceID + instanceID
        configData(taskID: .configTriggerSlotData, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configSlotTriggeredURL(index: Int,
                                       advParams: any MKBXSSlotTriggeredAdvContentParam,
                                       urlType: MKBXSURLHeaderType,
                                       urlContent: String,
                                       sucBlock: (() -> Void)?,
                                       failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2 else {
            failedBlock(makeError("Params error"))
            return
        }
        let urlString = MKBXSSDKDataAdopter.fetchUrlString(urlType, urlContent: urlContent)
        guard !urlString.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let len = 1 + paramsCmd.count / 2 + 1 + urlString.count / 2
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "10" + urlString
        configData(taskID: .configTriggerSlotData, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configSlotTriggeredTLM(index: Int,
                                       advParams: any MKBXSSlotTriggeredAdvContentParam,
                                       sucBlock: (() -> Void)?,
                                       failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2 else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let len = 1 + paramsCmd.count / 2 + 1
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "20"
        configData(taskID: .configTriggerSlotData, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configSlotTriggeredBeacon(index: Int,
                                          advParams: any MKBXSSlotTriggeredAdvContentParam,
                                          major: Int,
                                          minor: Int,
                                          uuid: String,
                                          sucBlock: (() -> Void)?,
                                          failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2,
              major >= 0, major <= 65535,
              minor >= 0, minor <= 65535,
              uuid.count == 32, MKSwiftBleSDKAdopter.checkHexCharacter(uuid) else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        let len = 1 + paramsCmd.count / 2 + 1 + 20
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let majorValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(major), byteLen: 2)
        let minorValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(minor), byteLen: 2)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "50" + uuid + majorValue + minorValue
        configData(taskID: .configTriggerSlotData, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configSlotTriggeredSensorInfo(index: Int,
                                              advParams: any MKBXSSlotTriggeredAdvContentParam,
                                              deviceName: String,
                                              tagID: String,
                                              sucBlock: (() -> Void)?,
                                              failedBlock: @escaping (Error) -> Void) {
        guard index >= 0, index <= 2,
              !deviceName.isEmpty, deviceName.count <= 20,
              !tagID.isEmpty, tagID.count <= 12, tagID.count % 2 == 0 else {
            failedBlock(makeError("Params error"))
            return
        }
        let paramsCmd = MKBXSSDKDataAdopter.fetchSlotTriggerdAdvParamsCmd(advParams)
        guard !paramsCmd.isEmpty else {
            failedBlock(makeError("Params error"))
            return
        }
        let indexValue = MKSwiftBleSDKAdopter.fetchHexValue(UInt(index), byteLen: 1)
        var tempString = ""
        for char in deviceName.utf8 {
            tempString += String(format: "%1x", char)
        }
        let nameLen = MKSwiftBleSDKAdopter.fetchHexValue(UInt(deviceName.count), byteLen: 1)
        let tagIDLen = MKSwiftBleSDKAdopter.fetchHexValue(UInt(tagID.count / 2), byteLen: 1)
        let len = 1 + paramsCmd.count / 2 + 1 + deviceName.count + tagID.count / 2 + 2
        let lenString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(len), byteLen: 1)
        let commandString = "ea0133" + lenString + indexValue + paramsCmd + "80" + nameLen + tempString + tagIDLen + tagID
        configData(taskID: .configTriggerSlotData, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x35 ADV 信道配置

    static func configADVChannel(channel: MKBXSADVChannel,
                                 sucBlock: (() -> Void)?,
                                 failedBlock: @escaping (Error) -> Void) {
        let rateString = MKBXSSDKDataAdopter.fetchAdvChannelCmd(channel)
        let commandString = "ea013501" + rateString
        configData(taskID: .configADVChannel, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x36 AOA CTE 配置

    static func configDirectionFindingStatus(isOn: Bool,
                                             sucBlock: (() -> Void)?,
                                             failedBlock: @escaping (Error) -> Void) {
        let commandString = isOn ? "ea01360101" : "ea01360100"
        configData(taskID: .configDirectionFindingStatus, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x37 可连接状态配置

    static func configConnectable(_ connectable: Bool,
                                  sucBlock: (() -> Void)?,
                                  failedBlock: @escaping (Error) -> Void) {
        let commandString = connectable ? "ea01370101" : "ea01370100"
        configData(taskID: .configConnectable, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x3c Tag ID 自动填充配置

    static func configTagIDAutofillStatus(isOn: Bool,
                                          sucBlock: (() -> Void)?,
                                          failedBlock: @escaping (Error) -> Void) {
        let commandString = isOn ? "ea013c0101" : "ea013c0100"
        configData(taskID: .configTagIDAutofillStatus, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x3f 设备时间同步

    static func configDeviceTime(timestamp: UInt,
                                 sucBlock: (() -> Void)?,
                                 failedBlock: @escaping (Error) -> Void) {
        let value = String(format: "%1lx", timestamp)
        let commandString = "ea013f04" + value
        configData(taskID: .configDeviceTime, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x40 温湿度存储配置

    static func configTHDataStoreStatus(isOn: Bool,
                                        interval: Int,
                                        sucBlock: (() -> Void)?,
                                        failedBlock: @escaping (Error) -> Void) {
        guard interval >= 0, interval <= 65535 else {
            failedBlock(makeError("Params error"))
            return
        }
        let status = isOn ? "01" : "00"
        let intervalString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(interval), byteLen: 2)
        let commandString = "ea014003" + status + intervalString
        configData(taskID: .configTHDataStoreStatus, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x41 温湿度采样率配置

    static func configTHSamplingRate(_ rate: Int,
                                     sucBlock: (() -> Void)?,
                                     failedBlock: @escaping (Error) -> Void) {
        guard rate >= 1, rate <= 65535 else {
            failedBlock(makeError("Params error"))
            return
        }
        let rateString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(rate), byteLen: 2)
        let commandString = "ea014102" + rateString
        configData(taskID: .configTHSamplingRate, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x42 删除温湿度历史数据

    static func deleteBXPRecordHTDatas(sucBlock: (() -> Void)?,
                                       failedBlock: @escaping (Error) -> Void) {
        configData(taskID: .deleteBXPRecordHTDatas, data: "ea014200", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x61 远程 LED 提醒配置

    static func configRemoteReminderLEDNotiParams(blinkingTime: Int,
                                                  blinkingInterval: Int,
                                                  color: String,
                                                  sucBlock: (() -> Void)?,
                                                  failedBlock: @escaping (Error) -> Void) {
        guard blinkingTime >= 1, blinkingTime <= 600,
              blinkingInterval >= 1, blinkingInterval <= 100 else {
            failedBlock(makeError("Params error"))
            return
        }
        let time = MKSwiftBleSDKAdopter.fetchHexValue(UInt(blinkingTime * 10), byteLen: 2)
        let interval = MKSwiftBleSDKAdopter.fetchHexValue(UInt(blinkingInterval * 100), byteLen: 2)
        let commandString = "ea016105" + color + interval + time
        configData(taskID: .configRemoteReminderLEDNotiParams, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x62 远程蜂鸣器提醒配置

    static func configRemoteReminderBuzzerNotiParams(ringTime: Int,
                                                     ringInterval: Int,
                                                     pinNo: String,
                                                     sucBlock: (() -> Void)?,
                                                     failedBlock: @escaping (Error) -> Void) {
        guard ringTime >= 1, ringTime <= 600,
              ringInterval >= 1, ringInterval <= 100 else {
            failedBlock(makeError("Params error"))
            return
        }
        let time = MKSwiftBleSDKAdopter.fetchHexValue(UInt(ringTime * 10), byteLen: 2)
        let interval = MKSwiftBleSDKAdopter.fetchHexValue(UInt(ringInterval * 100), byteLen: 2)
        let commandString = "ea016205" + pinNo + interval + time
        configData(taskID: .configRemoteReminderBuzzerNotiParams, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x63 蜂鸣器频率配置

    static func configRemoteReminderBuzzerFrequency(_ frequency: MKBXSBuzzerRingingFrequencyType,
                                                    sucBlock: (() -> Void)?,
                                                    failedBlock: @escaping (Error) -> Void) {
        let commandString = frequency == .higher ? "ea0163021194" : "ea0163020fa0"
        configData(taskID: .configRemoteReminderBuzzerFrequency, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x65 触发 LED 提醒状态配置

    static func configTriggerLEDIndicatorStatus(isOn: Bool,
                                                sucBlock: (() -> Void)?,
                                                failedBlock: @escaping (Error) -> Void) {
        let commandString = isOn ? "ea01650101" : "ea01650100"
        configData(taskID: .configTriggerLEDIndicatorStatus, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x68 清除霍尔触发次数

    static func clearHallTriggerCount(sucBlock: (() -> Void)?,
                                      failedBlock: @escaping (Error) -> Void) {
        configData(taskID: .clearHallTriggerCount, data: "ea016800", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x69 清除移动触发次数

    static func clearMotionTriggerCount(sucBlock: (() -> Void)?,
                                        failedBlock: @escaping (Error) -> Void) {
        configData(taskID: .clearMotionTriggerCount, data: "ea016900", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x6b 电池重置

    static func batteryReset(sucBlock: (() -> Void)?,
                             failedBlock: @escaping (Error) -> Void) {
        configData(taskID: .configBatteryReset, data: "ea016b0101", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x6c 电池广播模式配置

    static func configBatteryADVMode(_ mode: MKBXSBatteryADVMode,
                                     sucBlock: (() -> Void)?,
                                     failedBlock: @escaping (Error) -> Void) {
        let valueString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(mode.rawValue + 1), byteLen: 1)
        let commandString = "ea016c01" + valueString
        configData(taskID: .configBatteryADVMode, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x6d 霍尔记录开关配置

    static func configHallDataStoreStatus(isOn: Bool,
                                          sucBlock: (() -> Void)?,
                                          failedBlock: @escaping (Error) -> Void) {
        let commandString = isOn ? "ea016d0101" : "ea016d0100"
        configData(taskID: .configHallDataStoreStatus, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x6f 清除霍尔历史数据

    static func clearHallHistoryData(sucBlock: (() -> Void)?,
                                     failedBlock: @escaping (Error) -> Void) {
        configData(taskID: .clearHallHistoryData, data: "ea016f0100", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x71 温度异常检测触发参数

    static func configTemperatureTrigger(isOn: Bool,
                                         maxTemperature: Float,
                                         minTemperature: Float,
                                         sucBlock: (() -> Void)?,
                                         failedBlock: @escaping (Error) -> Void) {
        guard maxTemperature <= 127, maxTemperature > minTemperature, minTemperature >= -128 else {
            failedBlock(makeError("Params error"))
            return
        }
        let maxInt = Int(maxTemperature * 10)
        let minInt = Int(minTemperature * 10)
        let maxValue = MKBXSSDKDataAdopter.temperatureValueToHexString(maxInt)
        let minValue = MKBXSSDKDataAdopter.temperatureValueToHexString(minInt)
        let commandString = "ea017105" + (isOn ? "01" : "00") + maxValue + minValue
        configData(taskID: .configTempTriggerParams, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x72 清除温度异常检测触发次数

    static func clearTemperatureTriggerCount(sucBlock: (() -> Void)?,
                                             failedBlock: @escaping (Error) -> Void) {
        configData(taskID: .clearTemperatureTriggerCount, data: "ea017200", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x74 温度存储 & 温度异常检测延时功能

    static func configStorageStartDelay(_ delay: Int,
                                        sucBlock: (() -> Void)?,
                                        failedBlock: @escaping (Error) -> Void) {
        guard delay >= 0, delay <= 1440 else {
            failedBlock(makeError("Params error"))
            return
        }
        let value = MKSwiftBleSDKAdopter.fetchHexValue(UInt(delay), byteLen: 2)
        let commandString = "ea017402" + value
        configData(taskID: .configStorageStartDelay, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - 0x76 清除 mark 数据

    static func clearMarkData(sucBlock: (() -> Void)?,
                              failedBlock: @escaping (Error) -> Void) {
        configData(taskID: .clearMarkData, data: "ea017600", sucBlock: sucBlock, failedBlock: failedBlock)
    }

    // MARK: - AA07 密码相关 (0x51, 0x52, 0x53)

    static func verifyConnectPassword(_ password: String,
                                      sucBlock: (() -> Void)?,
                                      failedBlock: @escaping (Error) -> Void) {
        guard !password.isEmpty, password.count <= 16 else {
            failedBlock(makeError("Params error"))
            return
        }
        var commandData = ""
        for char in password.utf8 {
            commandData += String(format: "%1x", char)
        }
        var lenString = String(password.count, radix: 16)
        if lenString.count == 1 { lenString = "0" + lenString }
        let commandString = "ea0151" + lenString + commandData
        configPasswordData(taskID: .connectPassword, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configConnectPassword(_ password: String,
                                      sucBlock: (() -> Void)?,
                                      failedBlock: @escaping (Error) -> Void) {
        guard !password.isEmpty, password.count <= 16 else {
            failedBlock(makeError("Params error"))
            return
        }
        var commandData = ""
        for char in password.utf8 {
            commandData += String(format: "%1x", char)
        }
        var lenString = String(password.count, radix: 16)
        if lenString.count == 1 { lenString = "0" + lenString }
        let commandString = "ea0152" + lenString + commandData
        configPasswordData(taskID: .configConnectPassword, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }

    static func configPasswordVerification(isOn: Bool,
                                           sucBlock: (() -> Void)?,
                                           failedBlock: @escaping (Error) -> Void) {
        let commandString = isOn ? "ea01530101" : "ea01530100"
        configPasswordData(taskID: .configPasswordVerification, data: commandString, sucBlock: sucBlock, failedBlock: failedBlock)
    }
}
