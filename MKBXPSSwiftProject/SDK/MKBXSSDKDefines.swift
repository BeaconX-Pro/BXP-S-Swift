//
//  MKBXSSDKDefines.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/14.
//

import Foundation
import CoreBluetooth

// MARK: - OTA UUID

public let kBXTOtaServerUUIDString  = "1d14d6ee-fd63-4fa1-bfa4-8f47b42119f0"
public let kBXTOtaControlUUIDString = "f7bf3564-fb6d-4e53-88a4-5e37e0326063"
public let kBXTOtaDataUUIDString    = "984227f3-34fc-4045-a5d0-2c581f81a153"

// MARK: - 中心连接状态

public enum MKBXSCentralConnectStatus: Int, Sendable {
    case unknown = 0            // 未知状态
    case connecting = 1         // 正在连接
    case connected = 2          // 连接成功
    case connectedFailed = 3    // 连接失败
    case disconnect = 4         // 断开连接
}

// MARK: - 中心管理器状态

public enum MKBXSCentralManagerStatus: Int, Sendable {
    case unable = 0             // 不可用
    case enable = 1             // 可用状态
}

// MARK: - 三轴传感器采样率

public enum MKBXSThreeAxisDataRate: Int, Sendable, CaseIterable {
    case hz1 = 0
    case hz10 = 1
    case hz25 = 2
    case hz50 = 3
    case hz100 = 4
}

// MARK: - 三轴传感器量程

public enum MKBXSThreeAxisDataAG: Int, Sendable, CaseIterable {
    case g2 = 0                 // ±2g
    case g4 = 1                 // ±4g
    case g8 = 2                 // ±8g
    case g16 = 3                // ±16g
}

// MARK: - 发射功率
/// rawValue 必须与 OC `mk_bxs_txPower` 完全一致，协议命令依赖它

public enum MKBXSTxPower: Int, Sendable, CaseIterable {
    case neg20dBm = 0   // -20dBm
    case neg16dBm = 1   // -16dBm（BXP-S-A 不支持）
    case neg12dBm = 2   // -12dBm（BXP-S-A 不支持）
    case neg10dBm = 3   // -10dBm（仅 BXP-S-A）
    case neg8dBm  = 4   // -8dBm（BXP-S-A 不支持）
    case neg6dBm  = 5   // -6dBm（仅 BXP-S-A）
    case neg4dBm  = 6   // -4dBm（BXP-S-A 不支持）
    case neg2dBm  = 7   // -2dBm（仅 BXP-S-A）
    case dBm0     = 8   // 0dBm
    case dBm2     = 9   // 2dBm（仅 BXP-S-A）
    case dBm3     = 10  // 3dBm（BXP-S-A 不支持）
    case dBm4     = 11  // 4dBm
    case dBm6     = 12  // 6dBm（BXP-S-A 不支持）
    case dBm8     = 13  // 8dBm（仅 DL001）

    /// 显示文案（用于 UI 展示）
    public var displayName: String {
        switch self {
        case .neg20dBm: return "-20dBm"
        case .neg16dBm: return "-16dBm"
        case .neg12dBm: return "-12dBm"
        case .neg10dBm: return "-10dBm"
        case .neg8dBm:  return "-8dBm"
        case .neg6dBm:  return "-6dBm"
        case .neg4dBm:  return "-4dBm"
        case .neg2dBm:  return "-2dBm"
        case .dBm0:     return "0dBm"
        case .dBm2:     return "2dBm"
        case .dBm3:     return "3dBm"
        case .dBm4:     return "4dBm"
        case .dBm6:     return "6dBm"
        case .dBm8:     return "8dBm"
        }
    }
}

// MARK: - URL 头类型

public enum MKBXSURLHeaderType: Int, Sendable, CaseIterable {
    case httpWWW  = 0   // http://www.
    case httpsWWW = 1   // https://www.
    case http     = 2   // http://
    case https    = 3   // https://
}

// MARK: - 触发类型

public enum MKBXSTriggerType: Int, Sendable {
    case null = 0
    case temperature = 1
    case humidity = 2
    case motionDetection = 3
    case hall = 4
}

// MARK: - 电池广播模式

public enum MKBXSBatteryADVMode: Int, Sendable {
    case percentage = 0
    case voltage = 1
}

// MARK: - ADV 信道

public enum MKBXSADVChannel: Int, Sendable, CaseIterable {
    case ch37 = 0
    case ch38 = 1
    case ch37And38 = 2
    case ch39 = 3
    case ch37And39 = 4
    case ch38And39 = 5
    case all = 6        // CH37&38&39
}

// MARK: - Slot 广播类型

public enum MKBXSSlotAdvType: Int, Sendable {
    case tlm = 0
    case uid = 1
    case url = 2
    case iBeacon = 3
    case noData = 4
}

// MARK: - Slot 数据类型

public enum MKBXSSlotDataType: Int, Sendable {
    case beforeTriggerData = 0
    case slotData = 1
}

// MARK: - 蜂鸣器频率

public enum MKBXSBuzzerRingingFrequencyType: Int, Sendable {
    case normal = 0     // 4000Hz
    case higher = 1     // 4500Hz
}

// MARK: - 广播参数协议

public protocol MKBXSSlotAdvContentParam: Sendable {
    /// 20ms ~ 65535ms
    var advInterval: Int { get }
    /// 1s ~ 65535s
    var advDuration: Int { get }
    /// 0s ~ 65535s
    var standbyDuration: Int { get }
    /// -100dBm ~ 0dBm
    var rssi: Int { get }
    /// 发射功率
    var txPower: MKBXSTxPower { get }
}

public protocol MKBXSSlotTriggeredAdvContentParam: Sendable {
    /// 20ms ~ 65535ms
    var advInterval: Int { get }
    /// 0s ~ 65535s
    var advDuration: Int { get }
    /// -100dBm ~ 0dBm
    var rssi: Int { get }
    /// 发射功率
    var txPower: MKBXSTxPower { get }
}

// MARK: - 扫描代理

public protocol MKBXSCentralManagerScanDelegate: AnyObject {
    /// 扫描到新设备
    func mk_bxs_receiveBeacon(_ beaconList: [MKBXSBaseBeacon])

    /// 开始扫描
    func mk_bxs_startScan()

    /// 停止扫描
    func mk_bxs_stopScan()
}

public extension MKBXSCentralManagerScanDelegate {
    func mk_bxs_startScan() {}
    func mk_bxs_stopScan() {}
}
