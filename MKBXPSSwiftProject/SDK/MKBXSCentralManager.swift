//
//  MKBXSCentralManager.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import CoreBluetooth

import MKBaseSwiftModule
import MKSwiftBleModule

// MARK: - 通知名称

public extension Notification.Name {
    /// 设备连接状态变化
    nonisolated static let mk_bxs_peripheralConnectStateChanged = Notification.Name("mk_bxs_peripheralConnectStateChangedNotification")
    /// 蓝牙中心状态变化
    nonisolated static let mk_bxs_centralManagerStateChanged = Notification.Name("mk_bxs_centralManagerStateChangedNotification")
    /// 设备断开连接类型
    nonisolated static let mk_bxs_deviceDisconnectType = Notification.Name("mk_bxs_deviceDisconnectTypeNotification")
    /// 三轴数据
    nonisolated static let mk_bxs_receiveThreeAxisData = Notification.Name("mk_bxs_receiveThreeAxisDataNotification")
    /// Hall 传感器状态变化
    nonisolated static let mk_bxs_receiveHallSensorStatusChanged = Notification.Name("mk_bxs_receiveHallSensorStatusChangedNotification")
    /// 温湿度数据
    nonisolated static let mk_bxs_receiveHTData = Notification.Name("mk_bxs_receiveHTDataNotification")
    /// 记录的温湿度数据
    nonisolated static let mk_bxs_receiveRecordHTData = Notification.Name("mk_bxs_receiveRecordHTDataNotification")
    /// 异常断点间隔
    nonisolated static let mk_bxs_receiveAbnormalCheckpointInterval = Notification.Name("mk_bxs_receiveAbnormalCheckpointIntervalNotification")
}

// MARK: - MKBXSCentralManager

public final class MKBXSCentralManager: NSObject, @unchecked Sendable {
    
    // MARK: - Singleton
    
    private nonisolated(unsafe) static var _shared: MKBXSCentralManager?
    private static let sharedLock = NSLock()
    
    public static var shared: MKBXSCentralManager {
        sharedLock.lock()
        defer { sharedLock.unlock() }
        if let s = _shared { return s }
        let s = MKBXSCentralManager()
        _shared = s
        return s
    }
    
    /// 销毁单例和底层 CentralManager（DFU 升级后需要重新初始化）
    public static func sharedDealloc() {
        MKSwiftBleBaseCentralManager.singleDealloc()
        sharedLock.lock()
        defer { sharedLock.unlock() }
        _shared = nil
    }
    
    /// 从底层 CentralManager 的 manager 列表中移除
    public static func removeFromCentralList() {
        MKSwiftBleBaseCentralManager.shared.removeCentralManager()
        sharedLock.lock()
        defer { sharedLock.unlock() }
        _shared = nil
    }
    
    // MARK: - Properties
    
    public weak var delegate: MKBXSCentralManagerScanDelegate?
    
    public private(set) var connectStatus: MKBXSCentralConnectStatus = .unknown
    
    // 回调与状态
    private var needPasswordBlock: (([String: Any]) -> Void)?
    private var sucBlock: ((CBPeripheral) -> Void)?
    private var failedBlock: ((NSError) -> Void)?
    private var password: String = ""
    private var readingNeedPassword = false
    private var characteristicWriteBlock: ((CBPeripheral, CBCharacteristic, Error?) -> Void)?
    
    // MARK: - Init
    
    private override init() {
        super.init()
        MKSwiftBleBaseCentralManager.shared.configCentralManager(self)
    }
    
    // MARK: - Public - Basic Info
    
    public func centralManager() -> CBCentralManager {
        return MKSwiftBleBaseCentralManager.shared.centralManager
    }
    
    public func peripheral() -> CBPeripheral? {
        return MKSwiftBleBaseCentralManager.shared.peripheral()
    }
    
    public func centralStatus() -> MKBXSCentralManagerStatus {
        return MKSwiftBleBaseCentralManager.shared.centralStatus == .enable ? .enable : .unable
    }
    
    public func otaContralCharacteristic() -> CBCharacteristic? {
        guard connectStatus == .connected, let peripheral = peripheral() else { return nil }
        return peripheral.bxs_otaControl
    }
    
    public func otaDataCharacteristic() -> CBCharacteristic? {
        guard connectStatus == .connected, let peripheral = peripheral() else { return nil }
        return peripheral.bxs_otaData
    }
    
    // MARK: - Public - Scan
    
    public func startScan() {
        MKSwiftBleBaseCentralManager.shared.scanForPeripherals(
            withServices: [
                CBUUID(string: "FEAA"),
                CBUUID(string: "FEAB"),
                CBUUID(string: "EA01"),
                CBUUID(string: "EB01"),
                CBUUID(string: "EAFF"),
            ],
            options: nil
        )
    }
    
    public func stopScan() {
        MKSwiftBleBaseCentralManager.shared.stopScan()
    }
    
    // MARK: - Public - Connect
    
    /// 读取是否需要密码
    public func readNeedPassword(
        peripheral: CBPeripheral,
        sucBlock: @escaping ([String: Any]) -> Void,
        failedBlock: @escaping (NSError) -> Void
    ) {
        if readingNeedPassword {
            operationFailedBlock(message: "Device is busy now", failedBlock: failedBlock)
            return
        }
        readingNeedPassword = true
        needPasswordBlock = nil
        self.failedBlock = nil
        self.failedBlock = failedBlock
        
        needPasswordBlock = { [weak self] result in
            guard let self = self else { return }
            guard MKValidator.isValidDictionary(result) else {
                self.clearAllParams()
                self.operationFailedBlock(message: "Read Error", failedBlock: failedBlock)
                return
            }
            self.clearAllParams()
            sucBlock(result)
        }
        
        let bxbPeripheral = MKBXSPeripheral(peripheral: peripheral, dfu: false)
        Task { @MainActor in
            do {
                _ = try await MKSwiftBleBaseCentralManager.shared.connectDevice(bxbPeripheral)
                self.confirmNeedPassword()
            } catch {
                self.clearAllParams()
                failedBlock(self.wrapError(error))
            }
        }
    }
    
    /// 带密码连接
    public func connect(
        peripheral: CBPeripheral,
        password: String,
        sucBlock: @escaping (CBPeripheral) -> Void,
        failedBlock: @escaping (NSError) -> Void
    ) {
        guard MKValidator.isValidString(password),
              password.count <= 16,
              MKSwiftBleSDKAdopter.asciiString(password) else {
            operationFailedBlock(message: "The password should be no more than 16 characters.", failedBlock: failedBlock)
            return
        }
        self.password = password
        connect(peripheral: peripheral, dfu: false, sucBlock: sucBlock, failedBlock: failedBlock)
    }
    
    /// 免密连接
    public func connect(
        peripheral: CBPeripheral,
        sucBlock: @escaping (CBPeripheral) -> Void,
        failedBlock: @escaping (NSError) -> Void
    ) {
        self.password = ""
        connect(peripheral: peripheral, dfu: false, sucBlock: sucBlock, failedBlock: failedBlock)
    }
    
    /// DFU 连接
    public func dfuConnect(
        peripheral: CBPeripheral,
        sucBlock: @escaping (CBPeripheral) -> Void,
        failedBlock: @escaping (NSError) -> Void
    ) {
        self.password = ""
        connect(peripheral: peripheral, dfu: true, sucBlock: sucBlock, failedBlock: failedBlock)
    }
    
    public func disconnect() {
        MKSwiftBleBaseCentralManager.shared.disconnect()
    }
    
    // MARK: - Public - Task
    
    public func addTask(
        taskID: MKBXSTaskOperationID,
        characteristic: CBCharacteristic,
        commandData: String,
        successBlock: @escaping ([String: Any]) -> Void,
        failureBlock: @escaping (NSError) -> Void
    ) {
        guard let operation = generateOperation(
            operationID: taskID,
            characteristic: characteristic,
            commandData: commandData,
            successBlock: successBlock,
            failureBlock: failureBlock
        ) else { return }
        MKSwiftBleBaseCentralManager.shared.addOperation(operation)
    }
    
    public func addReadTask(
        taskID: MKBXSTaskOperationID,
        characteristic: CBCharacteristic,
        successBlock: @escaping ([String: Any]) -> Void,
        failureBlock: @escaping (NSError) -> Void
    ) {
        guard let operation = generateReadOperation(
            operationID: taskID,
            characteristic: characteristic,
            successBlock: successBlock,
            failureBlock: failureBlock
        ) else { return }
        MKSwiftBleBaseCentralManager.shared.addOperation(operation)
    }
    
    public func addCharacteristicWriteBlock(_ block: ((CBPeripheral, CBCharacteristic, Error?) -> Void)?) {
        characteristicWriteBlock = block
    }
    
    // MARK: - Public - Notify
    
    @discardableResult
    public func notifyThreeAxisData(_ notify: Bool) -> Bool {
        guard connectStatus == .connected,
              let peripheral = peripheral(),
              let characteristic = peripheral.bxs_threeSensor else {
            return false
        }
        peripheral.setNotifyValue(notify, for: characteristic)
        return true
    }
    
    @discardableResult
    public func notifyHallSensorData(_ notify: Bool) -> Bool {
        guard connectStatus == .connected,
              let peripheral = peripheral(),
              let characteristic = peripheral.bxs_hallSensor else {
            return false
        }
        peripheral.setNotifyValue(notify, for: characteristic)
        return true
    }
    
    @discardableResult
    public func notifyTHSensorData(_ notify: Bool) -> Bool {
        guard connectStatus == .connected,
              let peripheral = peripheral(),
              let characteristic = peripheral.bxs_temperatureHumidity else {
            return false
        }
        peripheral.setNotifyValue(notify, for: characteristic)
        return true
    }
    
    @discardableResult
    public func notifyRecordTHData(_ notify: Bool) -> Bool {
        guard connectStatus == .connected,
              let peripheral = peripheral(),
              let characteristic = peripheral.bxs_recordTH else {
            return false
        }
        peripheral.setNotifyValue(notify, for: characteristic)
        return true
    }
    
    @discardableResult
    public func notifyAbnormalPointInterval(_ notify: Bool) -> Bool {
        guard connectStatus == .connected,
              let peripheral = peripheral(),
              let characteristic = peripheral.bxs_abnormalPointInterval else {
            return false
        }
        peripheral.setNotifyValue(notify, for: characteristic)
        return true
    }
    
    // MARK: - Private - Connection
    
    private func connect(
        peripheral: CBPeripheral,
        dfu: Bool,
        sucBlock: @escaping (CBPeripheral) -> Void,
        failedBlock: @escaping (NSError) -> Void
    ) {
        self.sucBlock = sucBlock
        self.failedBlock = failedBlock
        
        let bxbPeripheral = MKBXSPeripheral(peripheral: peripheral, dfu: dfu)
        Task { @MainActor in
            do {
                let connectedPeripheral = try await MKSwiftBleBaseCentralManager.shared.connectDevice(bxbPeripheral)
                
                if MKValidator.isValidString(self.password), self.password.count <= 16 {
                    self.sendPasswordToDevice()
                    return
                }
                self.connectStatus = .connected
                NotificationCenter.default.post(name: .mk_bxs_peripheralConnectStateChanged, object: nil)
                self.sucBlock?(connectedPeripheral)
                self.sucBlock = nil
                self.failedBlock = nil
            } catch {
                self.sucBlock = nil
                self.failedBlock = nil
                failedBlock(self.wrapError(error))
            }
        }
    }
    
    private func sendPasswordToDevice() {
        var lenString = String(format: "%1lx", password.count)
        if lenString.count == 1 {
            lenString = "0" + lenString
        }
        var commandData = "ea0151" + lenString
        for i in 0..<password.count {
            let index = password.index(password.startIndex, offsetBy: i)
            let asciiCode = password[index].unicodeScalars.first?.value ?? 0
            commandData += String(format: "%1lx", asciiCode)
        }
        
        guard let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral(),
              let characteristic = peripheral.bxs_password else {
            operationFailedBlock(message: "Password characteristic error", failedBlock: self.failedBlock)
            return
        }
        
        let operation = MKBXSOperation(operationID: .connectPassword) {
            _ = MKSwiftBleBaseCentralManager.shared.sendDataToPeripheral(
                commandData,
                characteristic: characteristic,
                type: .withResponse
            )
        } completeBlock: { [weak self] error, returnData in
            guard let self = self else { return }
            if error != nil || !MKValidator.isValidDictionary(returnData) ||
                !((returnData as? [String: Any])?["success"] as? Bool ?? false) {
                self.operationFailedBlock(message: "Incorrect password!", failedBlock: self.failedBlock)
                return
            }
            Task { @MainActor in
                self.connectStatus = .connected
                NotificationCenter.default.post(name: .mk_bxs_peripheralConnectStateChanged, object: nil)
                if let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral() {
                    self.sucBlock?(peripheral)
                }
                self.sucBlock = nil
                self.failedBlock = nil
            }
        }
        MKSwiftBleBaseCentralManager.shared.addOperation(operation)
    }
    
    private func confirmNeedPassword() {
        let commandData = "ea005300"
        guard let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral(),
              let characteristic = peripheral.bxs_password else {
            return
        }
        
        let operation = MKBXSOperation(operationID: .readNeedPassword) {
            _ = MKSwiftBleBaseCentralManager.shared.sendDataToPeripheral(
                commandData,
                characteristic: characteristic,
                type: .withResponse
            )
        } completeBlock: { [weak self] error, returnData in
            guard let self = self else { return }
            Task { @MainActor in
                self.needPasswordBlock?(returnData as? [String: Any] ?? [:])
            }
        }
        MKSwiftBleBaseCentralManager.shared.addOperation(operation)
    }
    
    // MARK: - Private - Task Generation
    
    private func generateOperation(
        operationID: MKBXSTaskOperationID,
        characteristic: CBCharacteristic,
        commandData: String,
        successBlock: @escaping ([String: Any]) -> Void,
        failureBlock: @escaping (NSError) -> Void
    ) -> MKBXSOperation? {
        guard MKSwiftBleBaseCentralManager.shared.readyToCommunication else {
            operationFailedBlock(message: "The current connection device is in disconnect", failedBlock: failureBlock)
            return nil
        }
        guard MKValidator.isValidString(commandData) else {
            operationFailedBlock(message: "The data sent to the device cannot be empty", failedBlock: failureBlock)
            return nil
        }
        
        let operation = MKBXSOperation(operationID: operationID) {
            _ = MKSwiftBleBaseCentralManager.shared.sendDataToPeripheral(
                commandData,
                characteristic: characteristic,
                type: .withResponse
            )
        } completeBlock: { [weak self] error, returnData in
            guard let self = self else { return }
            if let error = error {
                let wrappedError = self.wrapError(error)
                Task { @MainActor in failureBlock(wrappedError) }
                return
            }
            let result = (returnData as? [String: Any]) ?? [:]
            Task { @MainActor in successBlock(result) }
        }
        return operation
    }
    
    private func generateReadOperation(
        operationID: MKBXSTaskOperationID,
        characteristic: CBCharacteristic,
        successBlock: @escaping ([String: Any]) -> Void,
        failureBlock: @escaping (NSError) -> Void
    ) -> MKBXSOperation? {
        guard MKSwiftBleBaseCentralManager.shared.readyToCommunication else {
            operationFailedBlock(message: "The current connection device is in disconnect", failedBlock: failureBlock)
            return nil
        }
        
        let operation = MKBXSOperation(operationID: operationID) {
            if let peripheral = MKSwiftBleBaseCentralManager.shared.peripheral() {
                peripheral.readValue(for: characteristic)
            }
        } completeBlock: { [weak self] error, returnData in
            guard let self = self else { return }
            if let error = error {
                let wrappedError = self.wrapError(error)
                Task { @MainActor in failureBlock(wrappedError) }
                return
            }
            let result = (returnData as? [String: Any]) ?? [:]
            Task { @MainActor in successBlock(result) }
        }
        return operation
    }
    
    // MARK: - Private - Helpers
    
    private func clearAllParams() {
        sucBlock = nil
        failedBlock = nil
        if needPasswordBlock == nil { return }
        disconnect()
        needPasswordBlock = nil
        readingNeedPassword = false
    }
    
    private func operationFailedBlock(message: String, failedBlock: ((NSError) -> Void)?) {
        let error = NSError(
            domain: "com.moko.BXBCentralManager",
            code: -999,
            userInfo: ["errorInfo": message]
        )
        MKThreadUtils.runOnMain {
            failedBlock?(error)
        }
    }

    private func wrapError(_ error: Error) -> NSError {
        let nsError = error as NSError
        // 已经有 errorInfo，直接用
        if let info = nsError.userInfo["errorInfo"] as? String, !info.isEmpty {
            return nsError
        }
        // 否则用 localizedDescription（MKSwiftBleError 的 errorDescription 会桥接过来）
        let msg = error.localizedDescription
        return NSError(
            domain: "com.moko.BXBCentralManager",
            code: -999,
            userInfo: ["errorInfo": msg.isEmpty ? "Unknown error" : msg]
        )
    }
    
    private func convertAdvInfoToDict(_ info: MKBleAdvInfo) -> [String: Any] {
        var dict: [String: Any] = [:]
        if let localName = info.localName {
            dict[CBAdvertisementDataLocalNameKey] = localName
        }
        if let serviceUUIDs = info.serviceUUIDs {
            dict[CBAdvertisementDataServiceUUIDsKey] = serviceUUIDs
        }
        if let serviceData = info.serviceData {
            dict[CBAdvertisementDataServiceDataKey] = serviceData
        }
        if let manufacturerData = info.manufacturerData {
            dict[CBAdvertisementDataManufacturerDataKey] = manufacturerData
        }
        if let txPowerLevel = info.txPowerLevel {
            dict[CBAdvertisementDataTxPowerLevelKey] = txPowerLevel
        }
        if let isConnectable = info.isConnectable {
            dict[CBAdvertisementDataIsConnectable] = isConnectable
        }
        return dict
    }
}

// MARK: - MKSwiftBleCentralManagerProtocol

extension MKBXSCentralManager: MKSwiftBleCentralManagerProtocol {
    
    // MARK: Scan
    
    public func centralManagerDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: MKBleAdvInfo) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            print("\(advertisementData)")
            
            if advertisementData.localName == "MK_OTA" {
                let beaconModel = MKBXSOTABeacon()
                beaconModel.frameType = .ota
                beaconModel.identifier = peripheral.identifier.uuidString
                beaconModel.rssi = advertisementData.rssi
                beaconModel.peripheral = peripheral
                beaconModel.deviceName = advertisementData.localName ?? ""
                beaconModel.connectEnable = advertisementData.isConnectable ?? false
                
                DispatchQueue.main.async {
                    self.delegate?.mk_bxs_receiveBeacon([beaconModel])
                }
                return
            }
            
            let advDict = self.convertAdvInfoToDict(advertisementData)
            let deviceList = MKBXSBaseBeacon.parseAdvData(advDict)
            for beacon in deviceList {
                beacon.identifier = peripheral.identifier.uuidString
                beacon.rssi = advertisementData.rssi
                beacon.peripheral = peripheral
                beacon.deviceName = advertisementData.localName ?? ""
                beacon.connectEnable = advertisementData.isConnectable ?? false
            }
            
            DispatchQueue.main.async {
                self.delegate?.mk_bxs_receiveBeacon(deviceList)
            }
        }
    }
    
    public func centralManagerStartScan() {
        delegate?.mk_bxs_startScan()
    }
    
    public func centralManagerStopScan() {
        delegate?.mk_bxs_stopScan()
    }
    
    // MARK: State
    
    public func centralManagerStateChanged(_ state: MKSwiftCentralManagerState) {
        NotificationCenter.default.post(name: .mk_bxs_centralManagerStateChanged, object: nil)
    }
    
    public func peripheralConnectStateChanged(_ state: MKSwiftPeripheralConnectState) {
        if readingNeedPassword {
            return
        }
        switch state {
        case .unknown:
            connectStatus = .unknown
        case .connecting:
            connectStatus = .connecting
        case .disconnect:
            connectStatus = .disconnect
        case .connectedFailed:
            connectStatus = .connectedFailed
        case .connected:
            connectStatus = .connected
        }
        NotificationCenter.default.post(name: .mk_bxs_peripheralConnectStateChanged, object: nil)
    }
    
    // MARK: Data
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("+++++++++++++++++接收数据出错")
            return
        }
        
        guard let value = characteristic.value else { return }
        let uuid = characteristic.uuid.uuidString
        
        switch uuid {
        case "AA02":
            let content = MKSwiftBleSDKAdopter.hexStringFromData(value)
            let type = (content as NSString).substring(with: NSRange(location: 8, length: 2))
            NotificationCenter.default.post(
                name: .mk_bxs_deviceDisconnectType,
                object: nil,
                userInfo: ["type": type]
            )
            
        case "AA03":
            let content = MKSwiftBleSDKAdopter.hexStringFromData(value)
            let x = MKSwiftBleSDKAdopter.signedHexTurnToInt((content as NSString).substring(with: NSRange(location: 8, length: 4)))
            let y = MKSwiftBleSDKAdopter.signedHexTurnToInt((content as NSString).substring(with: NSRange(location: 12, length: 4)))
            let z = MKSwiftBleSDKAdopter.signedHexTurnToInt((content as NSString).substring(with: NSRange(location: 16, length: 4)))
            NotificationCenter.default.post(
                name: .mk_bxs_receiveThreeAxisData,
                object: nil,
                userInfo: ["xData": "\(x)", "yData": "\(y)", "zData": "\(z)"]
            )
            
        case "AA05":
            NotificationCenter.default.post(
                name: .mk_bxs_receiveHallSensorStatusChanged,
                object: nil,
                userInfo: ["content": value]
            )
            
        case "AA06":
            let content = MKSwiftBleSDKAdopter.hexStringFromData(value)
            let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnToInt((content as NSString).substring(with: NSRange(location: 8, length: 4)))
            let tempHui = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 12, length: 4))
            let temperature = String(format: "%.1f", Double(tempTemp) * 0.1)
            let humidity = String(format: "%.1f", Double(tempHui) * 0.1)
            MKThreadUtils.runOnMain {
                NotificationCenter.default.post(
                    name: .mk_bxs_receiveHTData,
                    object: nil,
                    userInfo: ["temperature": temperature, "humidity": humidity]
                )
            }
            
        case "AA09":
            let content = MKSwiftBleSDKAdopter.hexStringFromData(value)
            print("\(content)")
            MKThreadUtils.runOnMain {
                NotificationCenter.default.post(
                    name: .mk_bxs_receiveRecordHTData,
                    object: nil,
                    userInfo: ["content": content]
                )
            }
            
        case "AA0B":
            let content = MKSwiftBleSDKAdopter.hexStringFromData(value)
            print("\(content)")
            MKThreadUtils.runOnMain {
                NotificationCenter.default.post(
                    name: .mk_bxs_receiveAbnormalCheckpointInterval,
                    object: nil,
                    userInfo: ["content": content]
                )
            }
            
        default:
            break
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        characteristicWriteBlock?(peripheral, characteristic, error)
        if error != nil {
            print("+++++++++++++++++发送数据出错")
            return
        }
    }
}
