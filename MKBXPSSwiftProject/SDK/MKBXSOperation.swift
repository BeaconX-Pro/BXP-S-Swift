//
//  MKBXSOperation.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import CoreBluetooth

import MKSwiftBleModule

public typealias MKBXSOperationCompleteBlock = (Error?, Any?) -> Void

public final class MKBXSOperation: Operation, MKSwiftBleOperationProtocol, @unchecked Sendable {
    
    // MARK: - Public
    
    public let operationID: MKBXSTaskOperationID
    
    // MARK: - Private
    
    private let commandBlock: () -> Void
    private let completeBlock: MKBXSOperationCompleteBlock
    
    private var receiveTimer: DispatchSourceTimer?
    private var timeout: Bool = false
    private var receiveTimerCount: Int = 0
    private var dataList: [String] = []   // 分帧数据是 Hex String
    
    // 状态保护
    private let lock = NSLock()
    private var _executing: Bool = false
    private var _finished: Bool = false
    
    // MARK: - Init
    
    public init(operationID: MKBXSTaskOperationID,
                commandBlock: @escaping () -> Void,
                completeBlock: @escaping MKBXSOperationCompleteBlock) {
        self.operationID = operationID
        self.commandBlock = commandBlock
        self.completeBlock = completeBlock
        super.init()
    }
    
    deinit {
        cancelTimer()
    }
    
    // MARK: - Operation
    
    public override var isAsynchronous: Bool { true }
    
    public override var isExecuting: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _executing
    }
    
    public override var isFinished: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _finished
    }
    
    public override func start() {
        if isFinished || isCancelled {
            willChangeValue(forKey: "isFinished")
            lock.lock()
            _finished = true
            lock.unlock()
            didChangeValue(forKey: "isFinished")
            return
        }
        willChangeValue(forKey: "isExecuting")
        lock.lock()
        _executing = true
        lock.unlock()
        didChangeValue(forKey: "isExecuting")
        startCommunication()
    }
    
    public override func cancel() {
        super.cancel()
        cancelTimer()
        lock.lock()
        let wasExecuting = _executing
        lock.unlock()
        if wasExecuting {
            finishOperation()
        }
    }
    
    // MARK: - MKSwiftBleOperationProtocol
    // ⚠️ 签名必须与协议完全一致（无 error 参数）
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic) {
        let dic = MKBXSTaskAdopter.parseReadDataWithCharacteristic(characteristic)
        dataParserReceivedData(dic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didWriteValueFor characteristic: CBCharacteristic) {
        let dic = MKBXSTaskAdopter.parseWriteDataWithCharacteristic(characteristic)
        dataParserReceivedData(dic)
    }
    
    // MARK: - Private - Communication
    
    private func startCommunication() {
        if isCancelled { return }
        commandBlock()
        startReceiveTimer()
    }
    
    private func startReceiveTimer() {
        let queue = DispatchQueue.global(qos: .default)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        // 0.1s 间隔，累计 5s 超时
        timer.schedule(deadline: .now(), repeating: 0.1)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            if self.timeout || self.receiveTimerCount >= 50 {
                self.receiveTimerCount = 0
                self.communicationTimeout()
                return
            }
            self.receiveTimerCount += 1
        }
        self.receiveTimer = timer
        if isCancelled { return }
        timer.resume()
    }
    
    private func cancelTimer() {
        receiveTimer?.cancel()
        receiveTimer = nil
    }
    
    private func finishOperation() {
        lock.lock()
        if _finished {
            lock.unlock()
            return
        }
        _finished = true
        _executing = false
        lock.unlock()
        
        willChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        didChangeValue(forKey: "isFinished")
    }
    
    private func communicationTimeout() {
        timeout = true
        cancelTimer()
        finishOperation()
        
        let error = NSError(
            domain: "com.moko.operationError",
            code: -999,
            userInfo: ["errorInfo": "Communication timeout"]
        )
        completeBlock(error, nil)
    }
    
    // MARK: - Data Parser
    
    private func dataParserReceivedData(_ dataDic: [String: Any]) {
        if isCancelled { return }
        
        lock.lock()
        let executing = _executing
        lock.unlock()
        
        guard executing, !timeout, !dataDic.isEmpty else { return }
        
        // 1. 解析 operationID（是 Int）
        guard let opIDRaw = dataDic["operationID"] as? Int,
              let opID = MKBXSTaskOperationID(rawValue: opIDRaw) else {
            return
        }
        // 默认任务或不是当前任务则忽略
        if opID == .defaultTask || opID != self.operationID {
            return
        }
        
        // 2. 解析 returnData
        guard let returnData = dataDic["returnData"] as? [String: Any],
              !returnData.isEmpty else {
            return
        }
        
        // 3. 分帧数据判断
        if let totalNumStr = returnData[mk_bxs_totalNumKey] as? String, !totalNumStr.isEmpty {
            receiveTimerCount = 0
            
            // 分帧数据 content 是十六进制 String
            if let content = returnData[mk_bxs_contentKey] as? String {
                dataList.append(content)
            }
            
            if let totalNum = Int(totalNumStr), dataList.count == totalNum {
                cancelTimer()
                finishOperation()
                completeBlock(nil, dataList)
            }
            return
        }
        
        // 4. 单帧数据
        cancelTimer()
        finishOperation()
        completeBlock(nil, returnData)
    }
}
