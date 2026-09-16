//
//  MKBXSRemoteReminderModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

import MKBaseSwiftModule

@MainActor
public final class MKBXSRemoteReminderModel: NSObject {

    // MARK: - Properties

    public var ledBlinkingTime: String = ""
    public var ledBlinkingInterval: String = ""
    public var buzzerRingingTime: String = ""
    public var buzzerRingingInterval: String = ""
    /// 0:4000Hz 1:4500Hz
    public var ringingFre: Int = 0

    // MARK: - Public

    /// 读取设备数据（当前只读蜂鸣器频率）
    public func readData(sucBlock: @escaping () -> Void,
                         failedBlock: @escaping (Error) -> Void) {
        MKBXSInterface.readRemoteReminderBuzzerFrequency(sucBlock: { [weak self] data in
            guard let self = self else { return }
            // ✅ 修复：frequency 是 String "0" / "1"
            let freqStr = (data["frequency"] as? String) ?? "0"
            self.ringingFre = Int(freqStr) ?? 0
            sucBlock()
        }, failedBlock: { error in
            failedBlock(error)
        })
    }

    /// 配置蜂鸣器（先配 ringing time/interval，再配频率）
    public func configBuzzerData(sucBlock: @escaping () -> Void,
                                 failedBlock: @escaping (Error) -> Void) {
        configRemoteReminderBuzzer(sucBlock: { [weak self] in
            guard let self = self else { return }
            self.configRingingFre(sucBlock: sucBlock, failedBlock: failedBlock)
        }, failedBlock: { error in
            failedBlock(error)
        })
    }

    // MARK: - Private
    
    /// Buzzer io 值
    private func buzzerIO() -> String {
        let manager = MKBXSConnectManager.shared
        if manager.deviceType == .slathfDL002 { return "06" }   // S06 (DL002)
        
        return "03"   // 兜底：用 03，反正已经弹窗警告
    }

    private func configRemoteReminderBuzzer(sucBlock: @escaping () -> Void,
                                            failedBlock: @escaping (Error) -> Void) {
        let ringTime = Int(buzzerRingingTime) ?? 0
        let ringInterval = Int(buzzerRingingInterval) ?? 0
        MKBXSInterface.configRemoteReminderBuzzerNotiParams(ringTime: ringTime,
                                                            ringInterval: ringInterval,
                                                            pinNo:buzzerIO(),
                                                            sucBlock: {
            sucBlock()
        }, failedBlock: { error in
            failedBlock(error)
        })
    }

    private func configRingingFre(sucBlock: @escaping () -> Void,
                                  failedBlock: @escaping (Error) -> Void) {
        let freq = MKBXSBuzzerRingingFrequencyType(rawValue: ringingFre) ?? .normal
        MKBXSInterface.configRemoteReminderBuzzerFrequency(freq, sucBlock: {
            sucBlock()
        }, failedBlock: { error in
            failedBlock(error)
        })
    }
}
