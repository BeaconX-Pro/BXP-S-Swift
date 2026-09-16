//
//  MKBXSSlotParam.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

public struct MKBXSSlotAdvParam: MKBXSSlotAdvContentParam {
    public var advInterval: Int
    public var advDuration: Int
    public var standbyDuration: Int
    public var rssi: Int
    public var txPower: MKBXSTxPower   // ⬅️ 改成枚举

    public init(advInterval: Int,
                advDuration: Int,
                standbyDuration: Int,
                rssi: Int,
                txPower: MKBXSTxPower) {
        self.advInterval = advInterval
        self.advDuration = advDuration
        self.standbyDuration = standbyDuration
        self.rssi = rssi
        self.txPower = txPower
    }
}

public struct MKBXSSlotTriggeredAdvParam: MKBXSSlotTriggeredAdvContentParam {
    public var advInterval: Int
    public var advDuration: Int
    public var rssi: Int
    public var txPower: MKBXSTxPower   // ⬅️ 改成枚举

    public init(advInterval: Int,
                advDuration: Int,
                rssi: Int,
                txPower: MKBXSTxPower) {
        self.advInterval = advInterval
        self.advDuration = advDuration
        self.rssi = rssi
        self.txPower = txPower
    }
}
