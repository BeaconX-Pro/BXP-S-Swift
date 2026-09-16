//
//  MKBXSNordicDFUModule.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import CoreBluetooth
import NordicDFU

import MKBaseSwiftModule

private let dfuUpdateDomain = "com.moko.dfuUpdateDomain"

public final class MKBXSNordicDFUModule: NSObject, @unchecked Sendable {

    private var progressBlock: ((CGFloat) -> Void)?
    private var updateSucBlock: (() -> Void)?
    private var updateFailedBlock: ((Error) -> Void)?
    private var dfuController: DFUServiceController?

    deinit {
        _ = dfuController?.abort()
        dfuController = nil
    }

    public func updateWithFileUrl(_ url: String,
                                  progressBlock: ((CGFloat) -> Void)?,
                                  sucBlock: @escaping () -> Void,
                                  failedBlock: @escaping (Error) -> Void) {
        guard !url.isEmpty else {
            operationFailed(failedBlock, msg: "The url is invalid!")
            return
        }

        let fileUrl = URL(fileURLWithPath: url)
        guard let zipData = try? Data(contentsOf: fileUrl), !zipData.isEmpty else {
            operationFailed(failedBlock, msg: "Dfu upgrade failure!")
            return
        }

        let firmware: DFUFirmware
        do {
            firmware = try DFUFirmware(urlToZipFile: fileUrl)
        } catch {
            operationFailed(failedBlock, msg: "Dfu upgrade failure!")
            return
        }

        guard MKBXSCentralManager.shared.connectStatus == .connected,
              let peripheral = MKBXSCentralManager.shared.peripheral() else {
            operationFailed(failedBlock, msg: "Device is disconnected!")
            return
        }

        self.progressBlock = progressBlock
        self.updateSucBlock = sucBlock
        self.updateFailedBlock = failedBlock

        let initiator = DFUServiceInitiator(
            queue: DispatchQueue.global(qos: .default),
            delegateQueue: DispatchQueue.global(qos: .default),
            progressQueue: DispatchQueue.global(qos: .default),
            loggerQueue: DispatchQueue.global(qos: .default)
        )
        initiator.logger = self
        initiator.delegate = self
        initiator.progressDelegate = self
        let configuredInitiator = initiator.with(firmware: firmware)

        MKBXSCentralManager.sharedDealloc()

        dfuController = configuredInitiator.start(target: peripheral)
    }

    // MARK: - Private

    private func operationFailed(_ failedBlock: ((Error) -> Void)?, msg: String) {
        DispatchQueue.main.async {
            guard let failedBlock = failedBlock else { return }
            let error = NSError(domain: dfuUpdateDomain,
                                code: -999,
                                userInfo: ["errorInfo": msg])
            failedBlock(error)
        }
    }
}

// MARK: - DFUServiceDelegate

extension MKBXSNordicDFUModule: DFUServiceDelegate {

    public func dfuStateDidChange(to state: DFUState) {
        if state == .completed {
            DispatchQueue.main.async {
                self.updateSucBlock?()
            }
        }
    }

    public func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        operationFailed(updateFailedBlock, msg: message)
    }
}

// MARK: - DFUProgressDelegate

extension MKBXSNordicDFUModule: DFUProgressDelegate {

    public func dfuProgressDidChange(for part: Int,
                                     outOf totalParts: Int,
                                     to progress: Int,
                                     currentSpeedBytesPerSecond: Double,
                                     avgSpeedBytesPerSecond: Double) {
        let currentProgress = Float(progress) / Float(totalParts)
        DispatchQueue.main.async {
            self.progressBlock?(CGFloat(currentProgress))
        }
    }
}

// MARK: - LoggerDelegate

extension MKBXSNordicDFUModule: LoggerDelegate {

    public func logWith(_ level: LogLevel, message: String) {
        print("[NordicDFU] \(level): \(message)")
    }
}
