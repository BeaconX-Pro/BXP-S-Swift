//
//  MKBXSDFUModule.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import CoreBluetooth

import MKBaseSwiftModule

private enum MKBXSOTAProcess {
    case start
    case reconnect
    case updating
    case complete
}

public final class MKBXSDFUModule: NSObject, @unchecked Sendable {

    // MARK: - Constants

    private static let byteAlignment = 4
    private static let padding: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF]
    private static let initiateDFUData: UInt8 = 0x00
    private static let terminateFirmwareUpdateData: UInt8 = 0x03
    private static let maxMTULen = 100

    // MARK: - Properties

    private var peripheral: CBPeripheral?
    private var sucBlock: (() -> Void)?
    private var failedBlock: ((Error) -> Void)?
    private var location: Int = 0
    private var length: Int = MKBXSDFUModule.maxMTULen
    private var fileData: Data?
    private var otaProcess: MKBXSOTAProcess = .start

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notification

    @objc private func deviceConnectTypeChanged() {
        if MKBXSCentralManager.shared.connectStatus != .connected && otaProcess != .complete {
            operationFailed("Dfu Failed!", failedBlock: failedBlock)
        }
    }

    // MARK: - Public

    public func updateWithFileUrl(_ url: String,
                                  sucBlock: @escaping () -> Void,
                                  failedBlock: @escaping (Error) -> Void) {
        guard !url.isEmpty else {
            operationFailed("The url is invalid!", failedBlock: failedBlock)
            return
        }
        guard let zipData = try? Data(contentsOf: URL(fileURLWithPath: url)), !zipData.isEmpty else {
            operationFailed("Dfu upgrade failure!", failedBlock: failedBlock)
            return
        }
        guard MKBXSCentralManager.shared.connectStatus == .connected else {
            operationFailed("Device is disconnected!", failedBlock: failedBlock)
            return
        }
        // ⬇️ otaContralCharacteristic 是方法，带 ()
        guard let otaControl = MKBXSCentralManager.shared.otaContralCharacteristic() else {
            operationFailed("The current device does not support OTA", failedBlock: failedBlock)
            return
        }

        self.fileData = zipData
        self.sucBlock = sucBlock
        self.failedBlock = failedBlock
        // ⬇️ peripheral 是方法，带 ()
        self.peripheral = MKBXSCentralManager.shared.peripheral()
        self.location = 0
        self.length = MKBXSDFUModule.maxMTULen

        // ⬇️ addCharacteristicWriteBlock 参数非 optional，不能传 nil
        // 用空闭包先清空（或后面覆盖）
        MKBXSCentralManager.shared.addCharacteristicWriteBlock { _, _, _ in }

        otaProcess = .reconnect
        writeSingleByteValue(MKBXSDFUModule.initiateDFUData, to: otaControl)

        MKBXSCentralManager.shared.addCharacteristicWriteBlock { [weak self] peripheral, characteristic, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.failedBlock?(error)
                }
                return
            }
            self.peripheral(peripheral, didWriteValueForCharacteristic: characteristic)
        }
    }

    // MARK: - DFU

    private func peripheral(_ peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic) {
        // ⬇️ 每次调用都获取当前特征（方法，带 ()）
        let otaControl = MKBXSCentralManager.shared.otaContralCharacteristic()
        let otaData = MKBXSCentralManager.shared.otaDataCharacteristic()

        if characteristic == otaControl {
            if otaProcess == .reconnect {
                if let otaData = otaData {
                    // 当前设备不需要重连
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(deviceConnectTypeChanged),
                                                           name: .mk_bxs_peripheralConnectStateChanged,
                                                           object: nil)
                    writeFileDataToCharacteristic(otaData)
                    return
                }
                reconnectDevice()
                return
            }

            if otaProcess == .updating {
                if let otaData = otaData {
                    writeFileDataToCharacteristic(otaData)
                }
                return
            }

            if otaProcess == .complete {
                DispatchQueue.main.async {
                    self.sucBlock?()
                }
                return
            }
            return
        }

        if characteristic == otaData {
            guard let fileData = fileData else { return }
            if location < fileData.count {
                writeFileDataToCharacteristic(characteristic)
                return
            }
            // 需要发送结束标志
            otaProcess = .complete
            if let otaControl = otaControl {
                writeSingleByteValue(MKBXSDFUModule.terminateFirmwareUpdateData, to: otaControl)
            }
            return
        }
    }

    private func startDFUProcess() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceConnectTypeChanged),
                                               name: .mk_bxs_peripheralConnectStateChanged,
                                               object: nil)
        if let otaControl = MKBXSCentralManager.shared.otaContralCharacteristic() {
            writeSingleByteValue(MKBXSDFUModule.initiateDFUData, to: otaControl)
        }
    }

    private func reconnectDevice() {
        // 重连设备（OC 里 disconnect 被注释掉，Swift 也保持不 disconnect）
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self = self, let peripheral = self.peripheral else { return }
            MKBXSCentralManager.shared.dfuConnect(peripheral: peripheral) { [weak self] _ in
                guard let self = self else { return }
                self.otaProcess = .updating
                self.startDFUProcess()
            } failedBlock: { [weak self] error in
                self?.failedBlock?(error)
            }
        }
    }

    // MARK: - Private

    private func writeFileDataToCharacteristic(_ characteristic: CBCharacteristic) {
        guard let fileData = fileData else { return }
        let data: Data
        if location + length > fileData.count {
            let currentLength = fileData.count - location
            var mutableData = fileData.subdata(in: location..<(location + currentLength))
            let remainder = currentLength % MKBXSDFUModule.byteAlignment
            if remainder > 0 {
                let additional = MKBXSDFUModule.byteAlignment - remainder
                mutableData.append(contentsOf: MKBXSDFUModule.padding.prefix(additional))
            }
            data = mutableData
            location += currentLength
        } else {
            data = fileData.subdata(in: location..<(location + length))
            location += length
        }
        // ⬇️ peripheral 是方法，带 ()
        MKBXSCentralManager.shared.peripheral()?.writeValue(data,
                                                            for: characteristic,
                                                            type: .withResponse)
    }

    private func writeSingleByteValue(_ value: UInt8, to characteristic: CBCharacteristic) {
        let data = Data([value])
        // ⬇️ peripheral 是方法，带 ()
        MKBXSCentralManager.shared.peripheral()?.writeValue(data,
                                                            for: characteristic,
                                                            type: .withResponse)
    }

    private func operationFailed(_ msg: String, failedBlock: ((Error) -> Void)?) {
        DispatchQueue.main.async {
            let error = NSError(domain: "com.moko.ota", code: -999, userInfo: ["errorInfo": msg])
            failedBlock?(error)
        }
    }
}
