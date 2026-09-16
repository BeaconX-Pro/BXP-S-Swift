//
//  MKBXSAtmosicSlotConfigModel.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation

public final class MKBXSAtmosicSlotConfigModel: MKBXSSlotDataBaseModel, @unchecked Sendable {

    private let readQueue = DispatchQueue(label: "atmosicSlotParamsQueue")
    private let semaphore = DispatchSemaphore(value: 0)

    public override func read(sucBlock: @escaping () -> Void, failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readSlotDatas() else {
                self.operationFailed(msg: "Read Slot Datas Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    public override func config(sucBlock: @escaping () -> Void, failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.validParams() else {
                self.operationFailed(msg: "Params Error", block: failedBlock)
                return
            }
            guard self.configSensorInfo() else {
                self.operationFailed(msg: "Config Slot Data Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async { sucBlock() }
        }
    }

    private func readSlotDatas() -> Bool {
        var success = false
        MKBXSInterface.readSlotData(index: index, sucBlock: { data in
            success = true
            self.updateSlotDatas(data)
            self.slotType = .sensorInfo
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }

    private func configSensorInfo() -> Bool {
        var success = false
        MKBXSInterface.configSlotSensorInfo(index: index,
                                            type: .slotData,
                                            advParams: currentContentParam(),
                                            deviceName: deviceName,
                                            tagID: tagID,
                                            sucBlock: {
            success = true
            self.semaphore.signal()
        }, failedBlock: { _ in self.semaphore.signal() })
        semaphore.wait()
        return success
    }
}
