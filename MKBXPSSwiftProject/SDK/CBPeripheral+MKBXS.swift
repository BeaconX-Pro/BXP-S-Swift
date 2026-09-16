//
//  CBPeripheral+MKBXS.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import CoreBluetooth
import ObjectiveC

private var bxsCustomKey: UInt8 = 0
private var bxsDisconnectTypeKey: UInt8 = 0
private var bxsThreeSensorKey: UInt8 = 0
private var bxsPasswordKey: UInt8 = 0
private var bxsHallSensorKey: UInt8 = 0
private var bxsTemperatureHumidityKey: UInt8 = 0
private var bxsRecordTHKey: UInt8 = 0
private var bxsRecordVoltageKey: UInt8 = 0
private var bxsAbnormalPointIntervalKey: UInt8 = 0
private var bxsOtaControlKey: UInt8 = 0
private var bxsOtaDataKey: UInt8 = 0
private var bxsPasswordNotifySuccessKey: UInt8 = 0
private var bxsDisconnectTypeNotifySuccessKey: UInt8 = 0
private var bxsCustomNotifySuccessKey: UInt8 = 0

public let kMKBXSOtaServerUUIDString = "1d14d6ee-fd63-4fa1-bfa4-8f47b42119f0"
public let kMKBXSOtaControlUUIDString = "f7bf3564-fb6d-4e53-88a4-5e37e0326063"
public let kMKBXSOtaDataUUIDString = "984227f3-34fc-4045-a5d0-2c581f81a153"

public extension CBPeripheral {

    // MARK: - 属性

    var bxs_custom: CBCharacteristic? {
        get { objc_getAssociatedObject(self, &bxsCustomKey) as? CBCharacteristic }
        set { objc_setAssociatedObject(self, &bxsCustomKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var bxs_disconnectType: CBCharacteristic? {
        get { objc_getAssociatedObject(self, &bxsDisconnectTypeKey) as? CBCharacteristic }
        set { objc_setAssociatedObject(self, &bxsDisconnectTypeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var bxs_threeSensor: CBCharacteristic? {
        get { objc_getAssociatedObject(self, &bxsThreeSensorKey) as? CBCharacteristic }
        set { objc_setAssociatedObject(self, &bxsThreeSensorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var bxs_password: CBCharacteristic? {
        get { objc_getAssociatedObject(self, &bxsPasswordKey) as? CBCharacteristic }
        set { objc_setAssociatedObject(self, &bxsPasswordKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var bxs_hallSensor: CBCharacteristic? {
        get { objc_getAssociatedObject(self, &bxsHallSensorKey) as? CBCharacteristic }
        set { objc_setAssociatedObject(self, &bxsHallSensorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var bxs_temperatureHumidity: CBCharacteristic? {
        get { objc_getAssociatedObject(self, &bxsTemperatureHumidityKey) as? CBCharacteristic }
        set { objc_setAssociatedObject(self, &bxsTemperatureHumidityKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var bxs_recordTH: CBCharacteristic? {
        get { objc_getAssociatedObject(self, &bxsRecordTHKey) as? CBCharacteristic }
        set { objc_setAssociatedObject(self, &bxsRecordTHKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var bxs_recordVoltage: CBCharacteristic? {
        get { objc_getAssociatedObject(self, &bxsRecordVoltageKey) as? CBCharacteristic }
        set { objc_setAssociatedObject(self, &bxsRecordVoltageKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var bxs_abnormalPointInterval: CBCharacteristic? {
        get { objc_getAssociatedObject(self, &bxsAbnormalPointIntervalKey) as? CBCharacteristic }
        set { objc_setAssociatedObject(self, &bxsAbnormalPointIntervalKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var bxs_otaControl: CBCharacteristic? {
        get { objc_getAssociatedObject(self, &bxsOtaControlKey) as? CBCharacteristic }
        set { objc_setAssociatedObject(self, &bxsOtaControlKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var bxs_otaData: CBCharacteristic? {
        get { objc_getAssociatedObject(self, &bxsOtaDataKey) as? CBCharacteristic }
        set { objc_setAssociatedObject(self, &bxsOtaDataKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    // MARK: - 更新特征

    func bxs_updateCharacterWithService(_ service: CBService) {
        let characteristicList = service.characteristics ?? []
        if service.uuid == CBUUID(string: "AA00") {
            for characteristic in characteristicList {
                let uuid = characteristic.uuid.uuidString.uppercased()
                switch uuid {
                case "AA01":
                    bxs_custom = characteristic
                    setNotifyValue(true, for: characteristic)
                case "AA02":
                    bxs_disconnectType = characteristic
                    setNotifyValue(true, for: characteristic)
                case "AA03":
                    bxs_threeSensor = characteristic
                case "AA04":
                    setNotifyValue(true, for: characteristic)
                    bxs_password = characteristic
                case "AA05":
                    bxs_hallSensor = characteristic
                case "AA06":
                    bxs_temperatureHumidity = characteristic
                case "AA08":
                    bxs_recordVoltage = characteristic
                case "AA09":
                    bxs_recordTH = characteristic
                case "AA0B":
                    bxs_abnormalPointInterval = characteristic
                default:
                    break
                }
            }
            return
        }
        if service.uuid == CBUUID(string: kMKBXSOtaServerUUIDString) {
            for characteristic in characteristicList {
                let uuid = characteristic.uuid.uuidString.uppercased()
                if uuid == kMKBXSOtaControlUUIDString.uppercased() {
                    bxs_otaControl = characteristic
                } else if uuid == kMKBXSOtaDataUUIDString.uppercased() {
                    bxs_otaData = characteristic
                }
            }
        }
    }

    func bxs_updateCurrentNotifySuccess(_ characteristic: CBCharacteristic) {
        let uuid = characteristic.uuid.uuidString.uppercased()
        switch uuid {
        case "AA01":
            objc_setAssociatedObject(self, &bxsCustomNotifySuccessKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        case "AA02":
            objc_setAssociatedObject(self, &bxsDisconnectTypeNotifySuccessKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        case "AA04":
            objc_setAssociatedObject(self, &bxsPasswordNotifySuccessKey, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        default:
            break
        }
    }

    func bxs_connectSuccess(dfu: Bool) -> Bool {
        if dfu {
            return bxs_otaData != nil && bxs_otaControl != nil
        }
        let customSuccess = objc_getAssociatedObject(self, &bxsCustomNotifySuccessKey) as? Bool ?? false
        let passwordSuccess = objc_getAssociatedObject(self, &bxsPasswordNotifySuccessKey) as? Bool ?? false
        let disconnectSuccess = objc_getAssociatedObject(self, &bxsDisconnectTypeNotifySuccessKey) as? Bool ?? false
        guard customSuccess, passwordSuccess, disconnectSuccess else { return false }
        guard bxs_password != nil,
              bxs_disconnectType != nil,
              bxs_custom != nil,
              bxs_threeSensor != nil,
              bxs_temperatureHumidity != nil,
              bxs_recordTH != nil,
              bxs_recordVoltage != nil else { return false }
        return true
    }

    func bxs_setNil() {
        bxs_password = nil
        bxs_disconnectType = nil
        bxs_custom = nil
        bxs_threeSensor = nil
        bxs_hallSensor = nil
        bxs_temperatureHumidity = nil
        bxs_recordTH = nil
        bxs_recordVoltage = nil
        bxs_abnormalPointInterval = nil
        bxs_otaControl = nil
        bxs_otaData = nil
        objc_setAssociatedObject(self, &bxsPasswordNotifySuccessKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxsDisconnectTypeNotifySuccessKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxsCustomNotifySuccessKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
