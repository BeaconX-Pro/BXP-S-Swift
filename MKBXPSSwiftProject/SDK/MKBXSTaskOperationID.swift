//
//  MKBXSTaskOperationID.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

public enum MKBXSTaskOperationID: Int, Sendable {
    case defaultTask = 0

    // MARK: 读取 0x20 - 0x2F
    case readMacAddress = 1
    case readThreeAxisDataParams = 2
    case readResetDeviceByButtonStatus = 3
    case readTriggeredSlotParams = 4
    case readHallSensorStatus = 5
    case readFirmware = 6
    case readManufacturer = 7
    case readProductDate = 8
    case readSoftware = 9
    case readHardware = 10
    case readDeviceModel = 11
    case readDeviceType = 12

    // MARK: 读取 0x30 - 0x3F
    case readSlotType = 13
    case readSlotTriggerData = 14
    case readBeforeTriggerSlotData = 15
    case readTriggerSlotData = 16
    case readSlotData = 17
    case readADVChannel = 18
    case readDirectionFindingStatus = 19
    case readConnectable = 20
    case readTagIDAutofillStatus = 21
    case readDeviceRuntime = 22
    case readDeviceUTCTime = 23

    // MARK: 读取 0x40 - 0x4F
    case readTHDataStoreStatus = 24
    case readTHSamplingRate = 25
    case readHTRecordTotalNumbers = 26
    case readSensorType = 27

    // MARK: 读取 0x60 - 0x6F
    case readRemoteReminderBuzzerFrequency = 28
    case readTriggerLEDIndicatorStatus = 29
    case readHallTriggerCount = 30
    case readMotionTriggerCount = 31
    case readBatteryVoltage = 32
    case readBatteryPercentage = 33
    case readBatteryADVMode = 34
    case readHallDataStoreStatus = 35
    case readHallHistoryData = 36
    case readTemperatureTriggerParams = 37
    case readTempTriggerCount = 38
    case readStorageStartDelay = 39
    case readDeviceBoardType = 40
    case readDeviceMarkData = 41

    // MARK: 读取 AA06 / AA07 / AA08
    case readTemperatureHumidityData = 42
    case readNeedPassword = 43
    case readMagnetStatus = 44

    // MARK: 配置 0x21 - 0x2F
    case configThreeAxisDataParams = 50
    case configResetDeviceByButtonStatus = 51
    case configTriggeredSlotParam = 52
    case configHallSensorStatus = 53
    case powerOff = 54
    case factoryReset = 55

    // MARK: 配置 0x30 - 0x3F
    case configSlotTriggerParams = 56
    case configBeforeTriggerSlotData = 57
    case configTriggerSlotData = 58
    case configSlotData = 59
    case configADVChannel = 60
    case configDirectionFindingStatus = 61
    case configConnectable = 62
    case configTagIDAutofillStatus = 63
    case configDeviceTime = 64

    // MARK: 配置 0x40 - 0x4F
    case configTHDataStoreStatus = 65
    case configTHSamplingRate = 66
    case deleteBXPRecordHTDatas = 67

    // MARK: 配置 0x60 - 0x6F
    case configRemoteReminderLEDNotiParams = 68
    case configRemoteReminderBuzzerNotiParams = 69
    case configRemoteReminderBuzzerFrequency = 70
    case configTriggerLEDIndicatorStatus = 71
    case clearHallTriggerCount = 72
    case clearMotionTriggerCount = 73
    case configBatteryReset = 74
    case configBatteryADVMode = 75
    case configHallDataStoreStatus = 76
    case clearHallHistoryData = 77
    case configTempTriggerParams = 78
    case clearTemperatureTriggerCount = 79
    case configStorageStartDelay = 80
    case clearMarkData = 81

    // MARK: 密码 0x51 - 0x53
    case connectPassword = 90
    case configConnectPassword = 91
    case configPasswordVerification = 92
}
