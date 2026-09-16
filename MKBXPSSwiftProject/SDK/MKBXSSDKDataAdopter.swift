//
//  MKBXSSDKDataAdopter.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/14.
//

import Foundation

import MKSwiftBleModule

public enum MKBXSSDKDataAdopter {

    // MARK: - URL 编解码

    public static func getUrlscheme(_ hexChar: CChar) -> String {
        switch hexChar {
        case 0x00: return "http://www."
        case 0x01: return "https://www."
        case 0x02: return "http://"
        case 0x03: return "https://"
        default:   return ""
        }
    }

    public static func getEncodedString(_ hexChar: CChar) -> String {
        switch hexChar {
        case 0x00: return ".com/"
        case 0x01: return ".org/"
        case 0x02: return ".edu/"
        case 0x03: return ".net/"
        case 0x04: return ".info/"
        case 0x05: return ".biz/"
        case 0x06: return ".gov/"
        case 0x07: return ".com"
        case 0x08: return ".org"
        case 0x09: return ".edu"
        case 0x0a: return ".net"
        case 0x0b: return ".info"
        case 0x0c: return ".biz"
        case 0x0d: return ".gov"
        default:   return String(format: "%c", hexChar)
        }
    }

    // MARK: - 三轴传感器

    public static func fetchThreeAxisDataRate(_ dataRate: MKBXSThreeAxisDataRate) -> String {
        switch dataRate {
        case .hz1:   return "00"
        case .hz10:  return "01"
        case .hz25:  return "02"
        case .hz50:  return "03"
        case .hz100: return "04"
        }
    }

    public static func fetchThreeAxisDataAG(_ ag: MKBXSThreeAxisDataAG) -> String {
        switch ag {
        case .g2:  return "00"
        case .g4:  return "01"
        case .g8:  return "02"
        case .g16: return "03"
        }
    }

    // MARK: - 发射功率

    /// 发射功率枚举 → hex
    /// - Note: rawValue 与 OC 的 `mk_bxs_txPower` 一一对应
    public static func fetchTxPower(_ txPower: MKBXSTxPower) -> String {
        switch txPower {
        case .neg20dBm: return "ec"
        case .neg16dBm: return "f0"
        case .neg12dBm: return "f4"
        case .neg10dBm: return "f6"
        case .neg8dBm:  return "f8"
        case .neg6dBm:  return "fa"
        case .neg4dBm:  return "fc"
        case .neg2dBm:  return "fe"
        case .dBm0:     return "00"
        case .dBm2:     return "02"
        case .dBm3:     return "03"
        case .dBm4:     return "04"
        case .dBm6:     return "06"
        case .dBm8:     return "08"
        }
    }

    public static func fetchTxPowerValueString(_ content: String) -> String {
        let map: [String: String] = [
            "08": "8dBm", "06": "6dBm", "04": "4dBm", "03": "3dBm",
            "02": "2dBm", "00": "0dBm", "fe": "-2dBm", "fc": "-4dBm",
            "fa": "-6dBm", "f8": "-8dBm", "f6": "-10dBm", "f4": "-12dBm",
            "f0": "-16dBm", "ec": "-20dBm"
        ]
        return map[content.lowercased()] ?? "0dBm"
    }

    // MARK: - Slot Data 解析

    public static func parseSlotData(_ content: String,
                                     advData: Data,
                                     hasStandbyDuration: Bool) -> [String: Any] {
        guard content.count >= 4, advData.count >= 6 else { return [:] }

        var resultDic: [String: Any] = [:]
        var contentIndex = 0
        var dataIndex = hasStandbyDuration ? 14 : 12

        resultDic["slotIndex"] = MKSwiftBleSDKAdopter.getDecimalStringWithHex(
            content, range: NSRange(location: contentIndex, length: 2))
        contentIndex += 2

        resultDic["advInterval"] = MKSwiftBleSDKAdopter.getDecimalStringWithHex(
            content, range: NSRange(location: contentIndex, length: 4))
        contentIndex += 4

        resultDic["advDuration"] = MKSwiftBleSDKAdopter.getDecimalStringWithHex(
            content, range: NSRange(location: contentIndex, length: 4))
        contentIndex += 4

        if hasStandbyDuration {
            resultDic["standbyDuration"] = MKSwiftBleSDKAdopter.getDecimalStringWithHex(
                content, range: NSRange(location: contentIndex, length: 4))
            contentIndex += 4
        }

        let rssi = MKSwiftBleSDKAdopter.signedHexTurnToInt(
            content.bleSubstring(from: contentIndex, length: 2))
        resultDic["rssi"] = "\(rssi)"
        contentIndex += 2

        let txPowerHex = content.bleSubstring(from: contentIndex, length: 2)
        resultDic["txPower"] = fetchTxPowerValueString(txPowerHex)
        contentIndex += 2

        let slotType = content.bleSubstring(from: contentIndex, length: 2)
        resultDic["slotType"] = slotType
        contentIndex += 2

        var advDic: [String: Any] = [:]
        let slotTypeUpper = slotType.uppercased()

        if slotTypeUpper == "FF" {
            // No Data
        } else if slotType == "00" {
            // UID
            let namespaceID = content.bleSubstring(from: contentIndex, length: 20)
            contentIndex += 20
            let instanceID = content.bleSubstring(from: contentIndex, length: 12)
            contentIndex += 12
            advDic = ["namespaceID": namespaceID, "instanceID": instanceID]
        } else if slotType == "10" {
            // URL
            let urlType = MKSwiftBleSDKAdopter.getDecimalStringWithHex(
                content, range: NSRange(location: contentIndex, length: 2))
            contentIndex += 2
            dataIndex += 1
            let subData = advData.subdata(in: dataIndex..<advData.count)
            var urlContent = ""
            for byte in [UInt8](subData) {
                urlContent += getEncodedString(CChar(bitPattern: byte))
            }
            advDic = ["urlType": urlType, "urlContent": urlContent, "advData": advData]
        } else if slotType == "20" {
            // TLM
        } else if slotType == "50" {
            // iBeacon
            let uuid = content.bleSubstring(from: contentIndex, length: 32)
            contentIndex += 32
            let major = MKSwiftBleSDKAdopter.getDecimalStringWithHex(
                content, range: NSRange(location: contentIndex, length: 4))
            contentIndex += 4
            let minor = MKSwiftBleSDKAdopter.getDecimalStringWithHex(
                content, range: NSRange(location: contentIndex, length: 4))
            contentIndex += 4
            advDic = ["major": major, "minor": minor, "uuid": uuid]
        } else if slotType == "80" {
            // Sensor Info
            let nameLen = MKSwiftBleSDKAdopter.getDecimalWithHex(
                content, range: NSRange(location: contentIndex, length: 2))
            contentIndex += 2
            dataIndex += 1
            let deviceNameData = advData.subdata(in: dataIndex..<(dataIndex + nameLen))
            let deviceName = String(data: deviceNameData, encoding: .utf8) ?? ""
            contentIndex += nameLen * 2
            dataIndex += nameLen
            _ = MKSwiftBleSDKAdopter.getDecimalWithHex(
                content, range: NSRange(location: contentIndex, length: 2))
            contentIndex += 2
            let tagID = content.bleSubstring(from: contentIndex, length: content.count - contentIndex)
            advDic = ["deviceName": deviceName, "tagID": tagID]
        }

        resultDic["advContent"] = advDic
        return resultDic
    }

    // MARK: - Slot Trigger Param 解析

    public static func parseSlotTriggerParam(_ content: String) -> [String: Any] {
        guard !content.isEmpty, content.count >= 4 else { return [:] }

        let slotIndex = MKSwiftBleSDKAdopter.getDecimalStringWithHex(
            content, range: NSRange(location: 0, length: 2))
        let triggerType = content.bleSubstring(from: 2, length: 2)

        if triggerType == "00" {
            return ["slotIndex": slotIndex, "triggerType": triggerType]
        }
        if triggerType == "01" {
            let event = content.bleSubstring(from: 4, length: 2) == "10" ? "0" : "1"
            let temperature = "\(MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 6, length: 4)))"
            let lockedAdv = content.bleSubstring(from: 10, length: 2) == "01"
            return [
                "slotIndex": slotIndex,
                "triggerType": triggerType,
                "event": event,
                "temperature": temperature,
                "lockedAdv": lockedAdv
            ]
        }
        if triggerType == "02" {
            let event = content.bleSubstring(from: 4, length: 2) == "20" ? "0" : "1"
            let humidity = MKSwiftBleSDKAdopter.getDecimalStringWithHex(
                content, range: NSRange(location: 6, length: 4))
            let lockedAdv = content.bleSubstring(from: 10, length: 2) == "01"
            return [
                "slotIndex": slotIndex,
                "triggerType": triggerType,
                "event": event,
                "humidity": humidity,
                "lockedAdv": lockedAdv
            ]
        }
        if triggerType == "03" {
            let event = content.bleSubstring(from: 4, length: 2) == "30" ? "0" : "1"
            let lockedAdv = content.bleSubstring(from: 10, length: 2) == "01"
            let period = MKSwiftBleSDKAdopter.getDecimalStringWithHex(
                content, range: NSRange(location: 12, length: 4))
            return [
                "slotIndex": slotIndex,
                "triggerType": triggerType,
                "event": event,
                "lockedAdv": lockedAdv,
                "period": period
            ]
        }
        if triggerType == "04" {
            let event = content.bleSubstring(from: 4, length: 2) == "40" ? "0" : "1"
            let lockedAdv = content.bleSubstring(from: 10, length: 2) == "01"
            return [
                "slotIndex": slotIndex,
                "triggerType": triggerType,
                "event": event,
                "lockedAdv": lockedAdv
            ]
        }

        return [:]
    }

    // MARK: - Hall 数据解析

    public static func parseHallData(_ list: [String]) -> [[String: Any]] {
        guard !list.isEmpty else { return [] }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"

        var tempList: [[String: Any]] = []
        for content in list {
            let totalNumber = content.count / 10
            for j in 0..<totalNumber {
                let subContent = content.bleSubstring(from: j * 10, length: 10)
                let time = MKSwiftBleSDKAdopter.getDecimalWithHex(
                    subContent, range: NSRange(location: 0, length: 8))
                let date = Date(timeIntervalSince1970: TimeInterval(time))
                let timestamp = dateFormatter.string(from: date)
                let moved = subContent.bleSubstring(from: 8, length: 2) == "01"
                tempList.append(["timestamp": timestamp, "moved": moved])
            }
        }
        return tempList
    }

    // MARK: - 温湿度数据解析

    public static func parseTemperatureHumidityData(_ content: String) -> [[String: Any]] {
        guard !content.isEmpty else { return [] }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"

        let total = content.count / 16
        var tempList: [[String: Any]] = []
        for i in 0..<total {
            let subContent = content.bleSubstring(from: i * 16, length: 16)
            let time = MKSwiftBleSDKAdopter.getDecimalWithHex(
                subContent, range: NSRange(location: 0, length: 8))
            let date = Date(timeIntervalSince1970: TimeInterval(time))
            let timestamp = dateFormatter.string(from: date)

            let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnToInt(
                subContent.bleSubstring(from: 8, length: 4))
            let tempHui = MKSwiftBleSDKAdopter.getDecimalWithHex(
                subContent, range: NSRange(location: 12, length: 4))
            let temperature = String(format: "%.1f", Double(tempTemp) * 0.1)
            let humidity = String(format: "%.1f", Double(tempHui) * 0.1)

            tempList.append([
                "temperature": temperature,
                "humidity": humidity,
                "date": timestamp
            ])
        }
        return tempList
    }

    // MARK: - ADV 信道

    public static func fetchAdvChannelCmd(_ channel: MKBXSADVChannel) -> String {
        switch channel {
        case .ch37:      return "01"
        case .ch38:      return "02"
        case .ch37And38: return "03"
        case .ch39:      return "04"
        case .ch37And39: return "05"
        case .ch38And39: return "06"
        case .all:       return "07"
        }
    }

    // MARK: - Slot 广播参数命令

    public static func fetchSlotAdvParamsCmd(_ param: any MKBXSSlotAdvContentParam) -> String {
        guard param.advInterval >= 20, param.advInterval <= 65535,
              param.advDuration >= 1, param.advDuration <= 65535,
              param.standbyDuration >= 0, param.standbyDuration <= 65535,
              param.rssi >= -100, param.rssi <= 0 else {
            return ""
        }

        let advInterval     = MKSwiftBleSDKAdopter.fetchHexValue(UInt(param.advInterval), byteLen: 2)
        let advDuration     = MKSwiftBleSDKAdopter.fetchHexValue(UInt(param.advDuration), byteLen: 2)
        let standbyDuration = MKSwiftBleSDKAdopter.fetchHexValue(UInt(param.standbyDuration), byteLen: 2)
        let rssi            = MKSwiftBleSDKAdopter.hexStringFromSignedNumber(param.rssi)
        let txPower         = fetchTxPower(param.txPower)

        return advInterval + advDuration + standbyDuration + rssi + txPower
    }

    public static func fetchSlotTriggerdAdvParamsCmd(_ param: any MKBXSSlotTriggeredAdvContentParam) -> String {
        guard param.advInterval >= 20, param.advInterval <= 65535,
              param.advDuration >= 0, param.advDuration <= 65535,
              param.rssi >= -100, param.rssi <= 0 else {
            return ""
        }

        let advInterval = MKSwiftBleSDKAdopter.fetchHexValue(UInt(param.advInterval), byteLen: 2)
        let advDuration = MKSwiftBleSDKAdopter.fetchHexValue(UInt(param.advDuration), byteLen: 2)
        let rssi        = MKSwiftBleSDKAdopter.hexStringFromSignedNumber(param.rssi)
        let txPower     = fetchTxPower(param.txPower)

        return advInterval + advDuration + rssi + txPower
    }

    // MARK: - 温度转换

    public static func temperatureToHexString(_ temperature: Int) -> String {
        var highByte: UInt8 = 0x00
        var lowByte: UInt8

        if temperature >= -128 && temperature <= 127 {
            lowByte = UInt8(bitPattern: Int8(temperature))
            highByte = temperature < 0 ? 0xFF : 0x00
        } else if temperature >= 128 && temperature <= 150 {
            lowByte = UInt8(temperature)
            highByte = 0x00
        } else {
            lowByte = temperature < 0 ? 0x80 : 0x7F
            highByte = temperature < 0 ? 0xFF : 0x00
        }

        return String(format: "%02X%02X", highByte, lowByte)
    }

    public static func temperatureValueToHexString(_ temperature: Int) -> String {
        guard temperature >= -1280, temperature <= 1270 else { return "0000" }
        let value: Int = temperature >= 0 ? temperature : (0x10000 + temperature)
        return String(format: "%04X", value)
    }

    // MARK: - URL 编码

    public static func fetchUrlString(_ urlType: MKBXSURLHeaderType, urlContent: String) -> String {
        guard !urlContent.isEmpty else { return "" }

        let header: String
        switch urlType {
        case .httpWWW:  header = "http://www."
        case .httpsWWW: header = "https://www."
        case .http:     header = "http://"
        case .https:    header = "https://"
        }

        let url = header + urlContent
        if regularUrl(url) {
            let content = getUrlIllegalContent(urlContent)
            return fetchUrlTypeString(urlType) + content
        }

        guard urlContent.count <= 17, urlContent.count >= 2 else { return "" }
        var content = fetchUrlTypeString(urlType)
        for char in urlContent.utf8 {
            content += String(format: "%1x", char)
        }
        return content
    }

    // MARK: - Private

    private static func regularUrl(_ url: String) -> Bool {
        url.range(of: "[a-zA-z]+://[^\\s]*", options: .regularExpression) != nil
    }

    private static func fetchUrlTypeString(_ urlType: MKBXSURLHeaderType) -> String {
        switch urlType {
        case .httpWWW:  return "00"
        case .httpsWWW: return "01"
        case .http:     return "02"
        case .https:    return "03"
        }
    }

    private static func getUrlIllegalContent(_ urlContent: String) -> String {
        guard !urlContent.isEmpty else { return "" }
        let components = urlContent.components(separatedBy: ".")
        guard !components.isEmpty else { return "" }

        var content = ""
        let expansion = getExpansionHex("." + (components.last ?? ""))

        if expansion.isEmpty {
            guard urlContent.count <= 17, urlContent.count >= 2 else { return "" }
            for char in urlContent.utf8 {
                content += String(format: "%1x", char)
            }
        } else {
            var tempString = ""
            for i in 0..<(components.count - 1) {
                tempString += ".\(components[i])"
            }
            tempString = String(tempString.dropFirst())
            guard tempString.count <= 16, tempString.count >= 1 else { return "" }
            for char in tempString.utf8 {
                content += String(format: "%1x", char)
            }
            content += expansion
        }
        return content
    }

    private static func getExpansionHex(_ expansion: String) -> String {
        guard !expansion.isEmpty else { return "" }

        switch expansion {
        case ".com/":  return "00"
        case ".org/":  return "01"
        case ".edu/":  return "02"
        case ".net/":  return "03"
        case ".info/": return "04"
        case ".biz/":  return "05"
        case ".gov/":  return "06"
        case ".com":   return "07"
        case ".org":   return "08"
        case ".edu":   return "09"
        case ".net":   return "0a"   
        case ".info":  return "0b"
        case ".biz":   return "0c"
        case ".gov":   return "0d"
        default:       return ""
        }
    }
}
