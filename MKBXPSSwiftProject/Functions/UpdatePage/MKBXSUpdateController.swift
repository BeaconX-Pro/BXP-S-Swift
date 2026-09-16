//
//  MKBXSUpdateController.swift
//  MKBXPSSwiftProject
//
//  Created by aa on 2026/9/12.
//

import UIKit
import UniformTypeIdentifiers

import SnapKit

import MKBaseSwiftModule
import MKSwiftCustomUI

public final class MKBXSUpdateController: MKSwiftBaseViewController {

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .white
        tv.delegate = self
        tv.dataSource = self
        tv.tableHeaderView = tableHeader()
        return tv
    }()

    private lazy var dataList: [MKSwiftNormalTextCellModel] = []
    private lazy var dfuModule = MKBXSDFUModule()
    private lazy var nordicDFUModule = MKBXSNordicDFUModule()
    private lazy var atmosicDFUModule = MKBXSAtmosicDFUModule()

    private var monitorQueue: DispatchQueue?
    private var monitorSource: DispatchSourceFileSystemObject?

    deinit {
        if let source = monitorSource {
            source.cancel()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        loadSubViews()
        loadFileList()
        startMonitoringDFUFiles()
    }

    @objc private func selectBtnPressed() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: false)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func startDFUWithFilePath(_ filePath: String) {
        guard !filePath.isEmpty else {
            view.showCentralToast("Firmware cannot be empty!")
            return
        }
        NotificationCenter.default.post(name: Notification.Name("mk_bxs_startDfuProcessNotification"), object: nil)
        leftButton.isEnabled = false
        MKSwiftHudManager.shared.showHUD(with: "Waiting...", in: view, isPenetration: false)

        let deviceType = MKBXSConnectManager.shared.deviceType

        if deviceType == .nordic {
            nordicDFUModule.updateWithFileUrl(filePath, progressBlock: { _ in
            }, sucBlock: { [weak self] in
                MKSwiftHudManager.shared.showHUD(with: "Update firmware successfully!", in: self?.view, isPenetration: false)
                self?.perform(#selector(self?.updateComplete), with: nil, afterDelay: 3.0)
            }, failedBlock: { [weak self] _ in
                MKSwiftHudManager.shared.showHUD(with: "Opps!DFU Failed. Please try again!", in: self?.view, isPenetration: false)
                self?.perform(#selector(self?.updateComplete), with: nil, afterDelay: 1.0)
            })
            return
        }

        if deviceType == .atmosic {
            atmosicDFUModule.updateWithFileUrl(filePath, progressBlock: { _ in
            }, sucBlock: { [weak self] in
                MKSwiftHudManager.shared.showHUD(with: "Update firmware successfully!", in: self?.view, isPenetration: false)
                self?.perform(#selector(self?.updateComplete), with: nil, afterDelay: 3.0)
            }, failedBlock: { [weak self] _ in
                MKSwiftHudManager.shared.showHUD(with: "Opps!DFU Failed. Please try again!", in: self?.view, isPenetration: false)
                self?.perform(#selector(self?.updateComplete), with: nil, afterDelay: 1.0)
            })
            return
        }

        dfuModule.updateWithFileUrl(filePath, sucBlock: { [weak self] in
            MKSwiftHudManager.shared.showHUD(with: "Update firmware successfully!", in: self?.view, isPenetration: false)
            self?.perform(#selector(self?.updateComplete), with: nil, afterDelay: 3.0)
        }, failedBlock: { [weak self] _ in
            MKSwiftHudManager.shared.showHUD(with: "Opps!DFU Failed. Please try again!", in: self?.view, isPenetration: false)
            self?.perform(#selector(self?.updateComplete), with: nil, afterDelay: 1.0)
        })
    }

    @objc private func updateComplete() {
        leftButton.isEnabled = true
        MKSwiftHudManager.shared.hide()
        MKBXSCentralManager.sharedDealloc()
        NotificationCenter.default.post(name: Notification.Name("mk_bxs_centralDeallocNotification"), object: nil)
        popToViewController(withClassName: "MKBXSScanController")
    }

    // MARK: - 文件监控

    private func startMonitoringDFUFiles() {
        let directoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? ""
        let filedes = open(directoryPath, O_EVTONLY)
        guard filedes >= 0 else { return }
        monitorQueue = DispatchQueue(label: "ZFileMonitorQueue")
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: filedes, eventMask: .write, queue: monitorQueue!)
        source.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.loadFileList()
            }
        }
        source.setCancelHandler {
            close(filedes)
        }
        monitorSource = source
        source.resume()
    }

    private func currentFileList() -> [String] {
        let document = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? ""
        return (try? FileManager.default.contentsOfDirectory(atPath: document)) ?? []
    }

    private func loadFileList() {
        let list = currentFileList()
        guard !list.isEmpty else { return }
        dataList.removeAll()
        for name in list {
            let model = MKSwiftNormalTextCellModel()
            model.leftMsg = name
            dataList.append(model)
        }
        tableView.reloadData()
    }

    private func loadSubViews() {
        defaultTitle = "OTA"
        rightButton.isHidden = true
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view).offset(MKLayout.topBarHeight)
            make.bottom.equalTo(view).offset(-MKLayout.safeAreaBottom)
        }
    }

    private func tableHeader() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: MKScreen.width, height: 60))
        header.backgroundColor = .white
        let selectBtn = MKSwiftUIAdaptor.createRoundedButton(title: "Select Firmware",
                                                             target: self,
                                                             action: #selector(selectBtnPressed))
        selectBtn.frame = CGRect(x: (MKScreen.width - 200) / 2, y: 10, width: 200, height: 40)
        header.addSubview(selectBtn)
        return header
    }
}

// MARK: - TableView

extension MKBXSUpdateController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { dataList.count }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        dataList[indexPath.row].cellHeightWithContentWidth(MKScreen.width)
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = MKSwiftNormalTextCell.initCellWithTableView(tableView)
        cell.dataModel = dataList[indexPath.row]
        return cell
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = dataList[indexPath.row]
        guard !model.leftMsg.isEmpty else {
            view.showCentralToast("Firmware cannot be empty!")
            return
        }
        let document = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? ""
        let filePath = (document as NSString).appendingPathComponent(model.leftMsg)
        startDFUWithFilePath(filePath)
    }
}

// MARK: - UIDocumentPickerDelegate

extension MKBXSUpdateController: UIDocumentPickerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let sourceURL = urls.first else { return }
        let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? ""
        let fileName = sourceURL.lastPathComponent
        let destPath = (documentDir as NSString).appendingPathComponent(fileName)

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destPath) {
            try? fileManager.removeItem(atPath: destPath)
        }
        var success = false
        if sourceURL.startAccessingSecurityScopedResource() {
            do {
                try fileManager.copyItem(at: sourceURL, to: URL(fileURLWithPath: destPath))
                success = true
            } catch {
                success = false
            }
            sourceURL.stopAccessingSecurityScopedResource()
        }
        if success {
            startDFUWithFilePath(destPath)
        } else {
            view.showCentralToast("Failed to import firmware file!")
        }
    }
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
}
