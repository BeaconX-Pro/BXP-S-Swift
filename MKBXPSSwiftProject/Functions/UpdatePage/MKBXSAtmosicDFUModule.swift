//
//  MKBXSAtmosicDFUModule.swift
//  MKSwiftBeaconXModule
//

import Foundation
import CoreBluetooth
import blelib

import MKBaseSwiftModule

private let atmosicDfuDomain = "com.moko.atmosicDfuDomain"

public final class MKBXSAtmosicDFUModule: NSObject, @unchecked Sendable {

    // MARK: - Properties

    private let bleManager: BleManager = .shared
    private var otaManager: OtaTaskManager?
    private var fileUrl: URL?
    private var targetIdentifier: String?
    private var targetPeripheral: CBPeripheral?
    private var isOTAStarted = false
    private var isConnected = false
    private var isScanning = false
    private var isCallbackCalled = false
    private var isCleanedUp = false

    private var progressBlock: ((CGFloat) -> Void)?
    private var sucBlock: (() -> Void)?
    private var failedBlock: ((Error) -> Void)?

    private let observerName = "MKBXSAtmosicDFUModule"
    private let scanTimeout: TimeInterval = 30.0
    private var originalStdout: Int32 = -1

    // MARK: - Lifecycle

    public override init() {
        super.init()
    }

    deinit {
        restoreConsoleLog()
        bleManager.unregisterBleManagerDelegate(observerName)
        bleManager.shutdown()
    }

    // MARK: - Public

    public func updateWithFileUrl(_ url: String,
                                  progressBlock: ((CGFloat) -> Void)?,
                                  sucBlock: @escaping () -> Void,
                                  failedBlock: @escaping (Error) -> Void) {
        guard !url.isEmpty else {
            operationFailed(failedBlock, msg: "The url is invalid!")
            return
        }

        guard FileManager.default.fileExists(atPath: url) else {
            operationFailed(failedBlock, msg: "The firmware file does not exist!")
            return
        }

        guard MKBXSCentralManager.shared.connectStatus == .connected,
              let peripheral = MKBXSCentralManager.shared.peripheral() else {
            operationFailed(failedBlock, msg: "Device is disconnected!")
            return
        }

        let deviceIdentifier = peripheral.identifier.uuidString

        MKBXSCentralManager.sharedDealloc()

        startOTA(filePath: url,
                 deviceIdentifier: deviceIdentifier,
                 progressBlock: progressBlock,
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    public func cancel() {
        cleanup()
    }

    // MARK: - Private

    private func suppressConsoleLog() {
        guard originalStdout < 0 else { return }
        originalStdout = dup(STDOUT_FILENO)
        freopen("/dev/null", "w", stdout)
    }

    private func restoreConsoleLog() {
        guard originalStdout >= 0 else { return }
        fflush(stdout)
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)
        originalStdout = -1
    }

    private func startOTA(filePath: String,
                          deviceIdentifier: String,
                          progressBlock: ((CGFloat) -> Void)?,
                          sucBlock: @escaping () -> Void,
                          failedBlock: @escaping (Error) -> Void) {
        self.targetIdentifier = deviceIdentifier
        self.fileUrl = URL(fileURLWithPath: filePath)
        self.isOTAStarted = false
        self.isConnected = false
        self.isScanning = false
        self.isCallbackCalled = false
        self.isCleanedUp = false
        self.progressBlock = progressBlock
        self.sucBlock = sucBlock
        self.failedBlock = failedBlock

        suppressConsoleLog()

        otaManager = OtaTaskManager(bleManager: bleManager)
        otaManager?.registerObserver(observerName: observerName, observer: self)
        otaManager?.registerOtaInfoObserver(observerName: observerName, observer: self)
        otaManager?.setForceNoTestBoot(true)

        bleManager.unregisterBleManagerDelegate(observerName)
        bleManager.shutdown()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, !self.isConnected else { return }
            self.bleManager.invoke()
            self.bleManager.setFileLoggingEnabled(false)
            self.bleManager.registerBleManagerDelegate(self.observerName, self)
            self.isScanning = true
            self.bleManager.scanPeripherals()

            DispatchQueue.main.asyncAfter(deadline: .now() + self.scanTimeout) { [weak self] in
                guard let self = self, self.isScanning, !self.isConnected else { return }
                self.isScanning = false
                self.bleManager.stopScan()
                self.handleFailure("Device not found, please try again")
            }
        }
    }

    private func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isScanning {
                self.bleManager.stopScan()
            }
            self.otaManager = nil
            self.bleManager.unregisterBleManagerDelegate(self.observerName)
            self.bleManager.shutdown()
            self.restoreConsoleLog()
        }
    }

    private func handleFailure(_ msg: String) {
        guard !isCallbackCalled else { return }
        isCallbackCalled = true
        DispatchQueue.main.async {
            let error = NSError(domain: atmosicDfuDomain,
                                code: -999,
                                userInfo: ["errorInfo": msg])
            self.failedBlock?(error)
        }
        cleanup()
    }

    private func operationFailed(_ failedBlock: @escaping (Error) -> Void, msg: String) {
        DispatchQueue.main.async {
            let error = NSError(domain: atmosicDfuDomain,
                                code: -999,
                                userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}

// MARK: - BleManagerDelegate
extension MKBXSAtmosicDFUModule: BleManagerDelegate {

    public func OnFoundPeripheral(wrapPeripheral: WrapScanResult) {
        guard isScanning, !isConnected,
              let peripheral = wrapPeripheral.peripheral,
              let target = targetIdentifier else { return }

        if peripheral.identifier.uuidString == target {
            isScanning = false
            targetPeripheral = peripheral
            bleManager.stopScan()
            bleManager.connect(peripheral: peripheral)
        }
    }

    public func UpdateFoundPeripheralList(wrapPeripherals: [WrapScanResult]) {}

    public func OnConnected(wrapPeripheral: WrapScanResult, mtu: Int) {
        isConnected = true
        targetPeripheral = wrapPeripheral.peripheral
    }

    public func OnDisconnected() {
        isConnected = false
        if !isOTAStarted && !isScanning && !isCleanedUp {
            handleFailure("Device disconnected before OTA started")
        } else if isOTAStarted && !isCallbackCalled && !isCleanedUp {
            isCallbackCalled = true
            DispatchQueue.main.async {
                self.sucBlock?()
            }
            cleanup()
        }
    }

    public func OnFoundServices(services: [CBService]) {}

    public func OnFounCharacteristics(charcs: [CBCharacteristic]) {}

    public func OnCharcteristicChanged(charc: CBCharacteristic) {}

    public func OnCharacNotifyEnabled(charc: CBCharacteristic) {}

    public func OnCharacWrote(charc: CBCharacteristic) {}

    public func OnOtaCharcSetupDone() {
        otaManager?.queryInfo()
    }
}

// MARK: - OnATTaskObserver
extension MKBXSAtmosicDFUModule: OnATTaskObserver {

    public func OnTaskCompleted(completedTask: ATTask) {}

    public func OnTaskProgress(progressTask: ATTask, percentage: Float) {
        let progress = CGFloat(percentage)
        DispatchQueue.main.async {
            self.progressBlock?(progress)
        }
    }

    public func OnTaskError(errorTask: ATTask, errorMsg: String) {
        handleFailure(errorMsg)
    }

    public func OnOverAllProgress(percentage: Float) {
        let progress = CGFloat(percentage)
        DispatchQueue.main.async {
            self.progressBlock?(progress)
        }
    }

    public func OnReconnecting() {}

    public func OnFirmwareUpdatedSuccess() {
        guard !isCallbackCalled else { return }
        isCallbackCalled = true
        DispatchQueue.main.async {
            self.sucBlock?()
        }
        cleanup()
    }

    public func OnUserDataUpdated() {}

    public func OnBankSwitchError() {
        handleFailure("Bank switch failure")
    }
}

// MARK: - OnATOTAInfoObserver
extension MKBXSAtmosicDFUModule: OnATOTAInfoObserver {

    public func OnFwVersionQueried(fwVersion: String) {}

    public func OnOtaProtocolVersion(protocolVersion: UInt8) {
        guard let url = fileUrl else {
            handleFailure("Firmware file URL is invalid")
            return
        }
        do {
            try otaManager?.checkArchive(selectedFileUri: url)
            try otaManager?.startFota(upgradeBin: true, upgradeNvds: false)
            isOTAStarted = true
        } catch OtaError.runtimeError(let msg) {
            handleFailure(msg)
        } catch {
            handleFailure("Failed to start OTA")
        }
    }
}
