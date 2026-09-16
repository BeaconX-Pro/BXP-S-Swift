//
//  MKBXSExcelManager.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import Foundation
import libxlsxwriter

public enum MKBXSExcelManager {

    /// 导出温湿度历史数据到 Excel
    /// - Parameters:
    ///   - list: 数据列表，每项含 `date` / `temperature`，可选 `humidity`
    ///   - hasHumidity: 是否带湿度，决定文件名
    ///   - sucBlock: 成功回调
    ///   - failedBlock: 失败回调
    public static func exportExcelWithTHDataList(_ list: [[String: Any]],
                                                 hasHumidity: Bool,
                                                 sucBlock: (() -> Void)?,
                                                 failedBlock: @escaping (Error) -> Void) {
        guard !list.isEmpty else {
            DispatchQueue.main.async {
                sucBlock?()
            }
            return
        }

        // 设置 excel 文件名和路径（跟 OC 一致：根据 hasHumidity 决定）
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let fileName = hasHumidity ? "Temperature&HumidityDatas.xlsx" : "Temperature.xlsx"
        let path = (documentPath as NSString).appendingPathComponent(fileName)

        // ✅ 关键修复：用 strdup 保证 C 字符串生命周期覆盖整个 workbook 使用过程
        guard let cPath = strdup(path) else {
            let error = NSError(domain: "excelOperation",
                                code: -999,
                                userInfo: ["errorInfo": "Export Failed"])
            DispatchQueue.main.async {
                failedBlock(error)
            }
            return
        }
        defer { free(cPath) }

        // 创建新 xlsx 文件
        guard let workbook = workbook_new(cPath) else {
            let error = NSError(domain: "excelOperation",
                                code: -999,
                                userInfo: ["errorInfo": "Export Failed"])
            DispatchQueue.main.async {
                failedBlock(error)
            }
            return
        }

        // 创建 sheet
        guard let worksheet = workbook_add_worksheet(workbook, nil) else {
            workbook_close(workbook)
            let error = NSError(domain: "excelOperation",
                                code: -999,
                                userInfo: ["errorInfo": "Export Failed"])
            DispatchQueue.main.async {
                failedBlock(error)
            }
            return
        }

        // 设置列宽
        worksheet_set_column(worksheet, 0, 2, 50, nil)

        // 添加格式
        let format = workbook_add_format(workbook)
        format_set_bold(format)
        format_set_align(format, UInt8(LXW_ALIGN_VERTICAL_CENTER.rawValue))

        // 写入表头
        worksheet_write_string(worksheet, 0, 0, "Date", nil)
        worksheet_write_string(worksheet, 0, 1, "Temperature", nil)
        worksheet_write_string(worksheet, 0, 2, "Humidity", nil)

        // 写入数据
        for (index, dic) in list.enumerated() {
            let row = UInt32(index + 1)
            worksheet_write_string(worksheet, row, 0, (dic["date"] as? String) ?? "", nil)
            worksheet_write_string(worksheet, row, 1, (dic["temperature"] as? String) ?? "", nil)
            worksheet_write_string(worksheet, row, 2, (dic["humidity"] as? String) ?? "", nil)
        }

        // 关闭并保存
        let errorCode = workbook_close(workbook)
        if errorCode != LXW_NO_ERROR {
            let error = NSError(domain: "excelOperation",
                                code: -999,
                                userInfo: ["errorInfo": "Export Failed"])
            DispatchQueue.main.async {
                failedBlock(error)
            }
            return
        }

        DispatchQueue.main.async {
            sucBlock?()
        }
    }
}
