//
//  MKBXSScanPageAdopter.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/14.
//

import Foundation
import CoreBluetooth
import UIKit

import MKBaseSwiftModule
import MKSwiftBeaconXCustomUI

public enum MKBXSScanPageAdopter {

    // MARK: - Beacon → CellModel

    /// 将扫描到的 beacon 数据转换成对应的 cellModel
    public static func parseBeaconDatas(_ beacon: MKBXSBaseBeacon) -> MKSwiftBXScanBaseModel? {

        // iBeacon → MKSwiftBXScanBeaconCellModel
        if let tempModel = beacon as? MKBXSiBeacon {
            let cellModel = MKSwiftBXScanBeaconCellModel()
            cellModel.rssi = "\(tempModel.rssi.intValue)"
            cellModel.rssi1M = "\(tempModel.rssi1M.intValue)"
            cellModel.txPower = "\(tempModel.txPower.intValue)"
            cellModel.interval = tempModel.interval
            cellModel.major = tempModel.major
            cellModel.minor = tempModel.minor
            cellModel.uuid = tempModel.uuid.lowercased()
            return cellModel
        }

        // TLM → MKBXSScanTLMCellModel
        if let tempModel = beacon as? MKBXSTLMBeacon {
            let cellModel = MKBXSScanTLMCellModel()
            cellModel.version = "\(tempModel.version)"
            cellModel.mvPerbit = tempModel.mvPerbit.intValue
            cellModel.temperature = "\(tempModel.temperature)"
            cellModel.advertiseCount = "\(tempModel.advertiseCount)"
            cellModel.deciSecondsSinceBoot = "\(tempModel.deciSecondsSinceBoot)"
            return cellModel
        }

        // UID → MKSwiftBXScanUIDCellModel
        if let tempModel = beacon as? MKBXSUIDBeacon {
            let cellModel = MKSwiftBXScanUIDCellModel()
            cellModel.txPower = "\(tempModel.txPower.intValue)"
            cellModel.namespaceId = tempModel.namespaceId
            cellModel.instanceId = tempModel.instanceId
            return cellModel
        }

        // URL → MKSwiftBXScanURLCellModel
        if let tempModel = beacon as? MKBXSURLBeacon {
            let cellModel = MKSwiftBXScanURLCellModel()
            cellModel.txPower = "\(tempModel.txPower.intValue)"
            cellModel.shortUrl = tempModel.shortUrl
            return cellModel
        }

        // Sensor Info → MKBXSScanSensorInfoCellModel
        if let tempModel = beacon as? MKBXSSensorInfoBeacon {
            let cellModel = MKBXSScanSensorInfoCellModel()
            cellModel.magneticStatus = tempModel.magnetStatus
            cellModel.magneticCount = tempModel.hallSensorCount
            cellModel.triaxialSensor = tempModel.triaxialSensor
            cellModel.motionStatus = tempModel.moved
            cellModel.motionCount = tempModel.movedCount
            cellModel.xData = tempModel.xData
            cellModel.yData = tempModel.yData
            cellModel.zData = tempModel.zData
            cellModel.temperature = tempModel.temperature
            cellModel.humidity = tempModel.humidity
            cellModel.supportTemp = tempModel.tempSensor
            cellModel.supportHumidity = tempModel.humiditySensor
            return cellModel
        }

        return nil
    }

    // MARK: - Beacon → InfoModel

    public static func parseBaseBeaconToInfoModel(_ beacon: MKBXSBaseBeacon) -> MKBXSScanInfoCellModel {
        let deviceModel = MKBXSScanInfoCellModel()

        deviceModel.identifier = beacon.peripheral?.identifier.uuidString ?? ""
        deviceModel.rssi = "\(beacon.rssi.intValue)"
        deviceModel.deviceName = beacon.deviceName ?? ""
        deviceModel.displayTime = "N/A"
        deviceModel.lastScanDate = Date().timeIntervalSince1970 * 1000
        deviceModel.connectEnable = beacon.connectEnable
        deviceModel.peripheral = beacon.peripheral
        deviceModel.otaMode = (beacon.frameType == .ota)

        if beacon.frameType == .sensorInfo, let sensorBeacon = beacon as? MKBXSSensorInfoBeacon {
            deviceModel.battery = sensorBeacon.battery
            deviceModel.tagID = sensorBeacon.tagID
        } else if beacon.frameType == .productionTest, let productionBeacon = beacon as? MKBXSProductionTestBeacon {
            deviceModel.battery = productionBeacon.battery
            deviceModel.macAddress = productionBeacon.macAddress
        }

        guard let obj = parseBeaconDatas(beacon) else {
            return deviceModel
        }
        let frameType = fetchFrameIndex(obj)
        obj.advertiseData = beacon.advertiseData
        obj.index = 0
        obj.frameIndex = frameType
        deviceModel.advertiseList.append(obj)

        return deviceModel
    }

    // MARK: - Update InfoModel

    public static func updateInfoCellModel(_ exsitModel: MKBXSScanInfoCellModel,
                                           beaconData beacon: MKBXSBaseBeacon) {
        exsitModel.connectEnable = beacon.connectEnable
        exsitModel.peripheral = beacon.peripheral
        exsitModel.otaMode = (beacon.frameType == .ota)
        exsitModel.rssi = "\(beacon.rssi.intValue)"

        if exsitModel.lastScanDate > 0 {
            let space = Date().timeIntervalSince1970 * 1000 - exsitModel.lastScanDate
            if space > 10 {
                exsitModel.displayTime = "<->\(Int(space))ms"
                exsitModel.lastScanDate = Date().timeIntervalSince1970 * 1000
            }
        }

        if beacon.frameType == .sensorInfo, let sensorBeacon = beacon as? MKBXSSensorInfoBeacon {
            exsitModel.battery = sensorBeacon.battery
            exsitModel.tagID = sensorBeacon.tagID
            if let deviceName = sensorBeacon.deviceName, !deviceName.isEmpty {
                exsitModel.deviceName = deviceName
            }
        } else if beacon.frameType == .productionTest, let productionBeacon = beacon as? MKBXSProductionTestBeacon {
            exsitModel.battery = productionBeacon.battery
            exsitModel.macAddress = productionBeacon.macAddress
        }

        guard let tempModel = parseBeaconDatas(beacon) else { return }
        let frameType = fetchFrameIndex(tempModel)
        tempModel.advertiseData = beacon.advertiseData
        tempModel.frameIndex = frameType

        // 核心修改：同类型就替换，不依赖 advertiseData 对比
        for (index, model) in exsitModel.advertiseList.enumerated() {
            guard let existModel = model as? MKSwiftBXScanBaseModel else { continue }
            if type(of: tempModel) == type(of: existModel) {
                tempModel.index = existModel.index
                exsitModel.advertiseList[index] = tempModel
                return
            }
        }

        // 新类型 → append
        exsitModel.advertiseList.append(tempModel)
        tempModel.index = exsitModel.advertiseList.count - 1

        // 排序
        let sorted = exsitModel.advertiseList
            .compactMap { $0 as? MKSwiftBXScanBaseModel }
            .sorted { $0.frameIndex < $1.frameIndex }
        exsitModel.advertiseList.removeAll()
        for (i, model) in sorted.enumerated() {
            model.index = i
            exsitModel.advertiseList.append(model)
        }
    }

    // MARK: - Cell 加载

    @MainActor
    public static func loadCellWithTableView(_ tableView: UITableView,
                                             dataModel: MKSwiftBXScanBaseModel) -> UITableViewCell {
        if let model = dataModel as? MKSwiftBXScanUIDCellModel {
            let cell = MKSwiftBXScanUIDCell.initCell(with: tableView)
            cell.dataModel = model
            return cell
        }
        if let model = dataModel as? MKSwiftBXScanURLCellModel {
            let cell = MKSwiftBXScanURLCell.initCell(with: tableView)
            cell.dataModel = model
            return cell
        }
        if let model = dataModel as? MKSwiftBXScanTLMCellModel {
            let cell = MKSwiftBXScanTLMCell.initCell(with: tableView)
            cell.dataModel = model
            return cell
        }
        if let model = dataModel as? MKSwiftBXScanBeaconCellModel {
            let cell = MKSwiftBXScanBeaconCell.initCell(with: tableView)
            cell.dataModel = model
            return cell
        }
        if let model = dataModel as? MKSwiftBXScanHTCellModel {
            let cell = MKSwiftBXScanHTCell.initCell(with: tableView)
            cell.dataModel = model
            return cell
        }
        if let model = dataModel as? MKSwiftBXScanThreeASensorCellModel {
            let cell = MKSwiftBXScanThreeASensorCell.initCell(with: tableView)
            cell.dataModel = model
            return cell
        }
        if let model = dataModel as? MKBXSScanTLMCellModel {
            let cell = MKBXSScanTLMCell.initCellWithTableView(tableView)
            cell.dataModel = model
            return cell
        }
        if let model = dataModel as? MKBXSScanSensorInfoCellModel {
            let cell = MKBXSScanSensorInfoCell.initCellWithTableView(tableView)
            cell.dataModel = model
            return cell
        }
        return UITableViewCell(style: .default,
                               reuseIdentifier: "MKBXSScanPageAdopterIdenty")
    }

    // MARK: - Cell 高度

    @MainActor
    public static func loadCellHeightWithDataModel(_ dataModel: MKSwiftBXScanBaseModel) -> CGFloat {
        if dataModel is MKSwiftBXScanUIDCellModel { return 85 }
        if dataModel is MKSwiftBXScanURLCellModel { return 70 }
        if dataModel is MKSwiftBXScanTLMCellModel { return 110 }
        if let model = dataModel as? MKSwiftBXScanBeaconCellModel {
            return MKSwiftBXScanBeaconCell.getCellHeight(with: model.uuid)
        }
        if dataModel is MKSwiftBXScanHTCellModel { return 105 }
        if dataModel is MKSwiftBXScanThreeASensorCellModel { return 140 }
        if dataModel is MKBXSScanTLMCellModel { return 110 }
        if let model = dataModel as? MKBXSScanSensorInfoCellModel {
            return model.fetchCellHeight()
        }
        return 0
    }

    // MARK: - Frame Index

    public static func fetchFrameIndex(_ dataModel: MKSwiftBXScanBaseModel) -> Int {
        if dataModel is MKSwiftBXScanUIDCellModel { return 0 }
        if dataModel is MKSwiftBXScanURLCellModel { return 1 }
        if dataModel is MKSwiftBXScanTLMCellModel { return 2 }
        if dataModel is MKBXSScanTLMCellModel { return 2 }
        if dataModel is MKSwiftBXScanBeaconCellModel { return 3 }
        if dataModel is MKSwiftBXScanThreeASensorCellModel { return 4 }
        if dataModel is MKSwiftBXScanHTCellModel { return 5 }
        if dataModel is MKBXSScanSensorInfoCellModel { return 6 }
        return 7
    }
}
