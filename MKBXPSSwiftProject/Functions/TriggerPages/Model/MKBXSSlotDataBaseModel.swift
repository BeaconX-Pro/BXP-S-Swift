//
//  MKBXSSlotDataBaseModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

public final class MKBXSSlotParamsDataModel: NSObject, MKBXSSlotAdvContentParam {
    public var advInterval: Int = 0
    public var advDuration: Int = 0
    public var standbyDuration: Int = 0
    public var rssi: Int = 0
    public var txPower: MKBXSTxPower = .neg20dBm
}

public final class MKBXSSlotTriggerParamsDataModel: NSObject, MKBXSSlotTriggeredAdvContentParam {
    public var advInterval: Int = 0
    public var advDuration: Int = 0
    public var rssi: Int = 0
    public var txPower: MKBXSTxPower = .neg20dBm
}

open class MKBXSSlotDataBaseModel: NSObject, @unchecked Sendable {

    public private(set) var index: Int = 0
    public var slotType: MKBXSSlotType = .null

    // MARK: - AdvContent Param
    public var advInterval: String = ""
    public var powerModeIsOn: Bool = false
    public var advDuration: String = ""
    public var standbyDuration: String = ""
    public var rssi: Int = 0
    public var txPower: MKBXSTxPower = .neg20dBm

    // MARK: - UID
    public var namespaceID: String = ""
    public var instanceID: String = ""

    // MARK: - iBeacon
    public var major: String = ""
    public var minor: String = ""
    public var uuid: String = ""

    // MARK: - Sensor Info
    public var deviceName: String = ""
    public var tagID: String = ""

    // MARK: - URL
    public var urlType: Int = 0
    public var urlContent: String = ""

    public init(slotIndex: Int) {
        super.init()
        self.index = slotIndex
    }

    // MARK: - Public

    open func read(sucBlock: @escaping () -> Void, failedBlock: @escaping (Error) -> Void) {}
    open func config(sucBlock: @escaping () -> Void, failedBlock: @escaping (Error) -> Void) {}

    public func updateSlotDatas(_ dic: [String: Any]) {
        guard !dic.isEmpty else { return }

        // advInterval: String → Int → /100
        let advIntervalStr = (dic["advInterval"] as? String) ?? "0"
        let advIntervalValue = (Int(advIntervalStr) ?? 0) / 100
        advInterval = "\(advIntervalValue)"

        // advDuration: String
        advDuration = (dic["advDuration"] as? String) ?? ""

        // standbyDuration: String
        let standbyStr = (dic["standbyDuration"] as? String) ?? "0"
        let standby = Int(standbyStr) ?? 0
        standbyDuration = standby == 0 ? "" : "\(standby)"
        powerModeIsOn = standby > 0

        // rssi: String → Int
        let rssiStr = (dic["rssi"] as? String) ?? "0"
        rssi = Int(rssiStr) ?? 0

        // txPower: String → 枚举
        txPower = getTxPowerValue((dic["txPower"] as? String) ?? "")

        // slotType
        let slotTypeStr = (dic["slotType"] as? String) ?? "ff"
        switch slotTypeStr {
        case "ff":
            slotType = .null
        case "00":
            slotType = .uid
            if let advContent = dic["advContent"] as? [String: Any] {
                namespaceID = (advContent["namespaceID"] as? String) ?? ""
                instanceID = (advContent["instanceID"] as? String) ?? ""
            }
        case "10":
            slotType = .url
            if let advContent = dic["advContent"] as? [String: Any] {
                // urlType: String → Int
                let urlTypeStr = (advContent["urlType"] as? String) ?? "0"
                urlType = Int(urlTypeStr) ?? 0
                urlContent = (advContent["urlContent"] as? String) ?? ""
            }
        case "20":
            slotType = .tlm
        case "50":
            slotType = .beacon
            if let advContent = dic["advContent"] as? [String: Any] {
                major = (advContent["major"] as? String) ?? ""
                minor = (advContent["minor"] as? String) ?? ""
                uuid = (advContent["uuid"] as? String) ?? ""
            }
        case "80":
            slotType = .sensorInfo
            if let advContent = dic["advContent"] as? [String: Any] {
                deviceName = (advContent["deviceName"] as? String) ?? ""
                if MKBXSConnectManager.shared.tagIdAutoFill {
                    let mac = MKBXSConnectManager.shared.macAddress
                    tagID = mac.replacingOccurrences(of: ":", with: "")
                } else {
                    tagID = (advContent["tagID"] as? String) ?? ""
                }
            }
        default:
            break
        }
    }

    public func getTxPowerValue(_ power: String) -> MKBXSTxPower {
        switch power {
        case "-20dBm": return .neg20dBm
        case "-16dBm": return .neg16dBm
        case "-12dBm": return .neg12dBm
        case "-10dBm": return .neg10dBm
        case "-8dBm":  return .neg8dBm
        case "-6dBm":  return .neg6dBm
        case "-4dBm":  return .neg4dBm
        case "-2dBm":  return .neg2dBm
        case "0dBm":   return .dBm0
        case "2dBm":   return .dBm2
        case "3dBm":   return .dBm3
        case "4dBm":   return .dBm4
        case "6dBm":   return .dBm6
        case "8dBm":   return .dBm8
        default:       return .neg20dBm
        }
    }

    public func validParams() -> Bool {
        if slotType == .null { return true }

        guard !advInterval.isEmpty, let intervalValue = Int(advInterval), intervalValue >= 1, intervalValue <= 100 else {
            return false
        }
        guard !advDuration.isEmpty, let durationValue = Int(advDuration), durationValue >= 1, durationValue <= 65535 else {
            return false
        }
        if powerModeIsOn {
            guard !standbyDuration.isEmpty, let standbyValue = Int(standbyDuration), standbyValue >= 1, standbyValue <= 65535 else {
                return false
            }
        }
        if slotType != .tlm {
            if rssi < -127 || rssi > 0 { return false }
        }
        switch slotType {
        case .uid:
            guard !namespaceID.isEmpty, namespaceID.count == 20,
                  !instanceID.isEmpty, instanceID.count == 12 else { return false }
        case .url:
            let result = MKBXSSDKDataAdopter.fetchUrlString(
                MKBXSURLHeaderType(rawValue: urlType) ?? .httpWWW,
                urlContent: urlContent
            )
            if result.isEmpty { return false }
        case .beacon:
            guard !major.isEmpty, let majorValue = Int(major), majorValue >= 0, majorValue <= 65535 else { return false }
            guard !minor.isEmpty, let minorValue = Int(minor), minorValue >= 0, minorValue <= 65535 else { return false }
            guard !uuid.isEmpty, uuid.count == 32 else { return false }
        case .sensorInfo:
            guard !deviceName.isEmpty, deviceName.count <= 20 else { return false }
            guard !tagID.isEmpty, tagID.count <= 12, tagID.count % 2 == 0 else { return false }
        default:
            break
        }
        return true
    }

    public func currentContentParam() -> MKBXSSlotParamsDataModel {
        let param = MKBXSSlotParamsDataModel()
        param.advInterval = (Int(advInterval) ?? 0) * 100
        param.advDuration = Int(advDuration) ?? 0
        param.standbyDuration = powerModeIsOn ? (Int(standbyDuration) ?? 0) : 0
        param.rssi = rssi
        param.txPower = txPower
        return param
    }

    public func currentTriggerContentParam() -> MKBXSSlotTriggerParamsDataModel {
        let param = MKBXSSlotTriggerParamsDataModel()
        param.advInterval = (Int(advInterval) ?? 0) * 100
        param.advDuration = Int(advDuration) ?? 0
        param.rssi = rssi
        param.txPower = txPower
        return param
    }

    public func operationFailed(msg: String, block: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "slotParams", code: -999, userInfo: ["errorInfo": msg])
            block(error)
        }
    }
}
