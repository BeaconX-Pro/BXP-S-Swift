//
//  MKBXSSlotConfigDefines.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

public enum MKBXSSlotType: Int, Sendable, CaseIterable {
    case tlm = 0
    case uid = 1
    case url = 2
    case beacon = 3
    case sensorInfo = 4
    case null = 5

    public var displayName: String {
        switch self {
        case .tlm:        return "TLM"
        case .uid:        return "UID"
        case .url:        return "URL"
        case .beacon:     return "iBeacon"
        case .sensorInfo: return "Sensor info"
        case .null:       return "No Data"
        }
    }

    public static func fromHex(_ hex: String) -> MKBXSSlotType {
        switch hex.lowercased() {
        case "00": return .uid
        case "10": return .url
        case "20": return .tlm
        case "50": return .beacon
        case "80": return .sensorInfo
        case "ff": return .null
        default:   return .null
        }
    }
}
