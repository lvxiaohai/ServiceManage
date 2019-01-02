//
//  StatusViewController.swift
//  ServiceManage
//
//  Created by tianshui on 2018/12/14.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Cocoa

fileprivate enum CellIdentifier: String {
    case name, command, edit, enabled

    var cellIdentifier: NSUserInterfaceItemIdentifier {
        let first = String(rawValue.first!).uppercased()
        return NSUserInterfaceItemIdentifier(first + rawValue.dropFirst() + "Cell")
    }
}

// 状态
class StatusViewController: NSViewController, ViewControllerOriginalSize {
    @IBOutlet var splitView: NSSplitView!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var textView: NSTextView!

    var originalSize = CGSize(width: 700, height: 512)

    private let serviceManage = ServiceManage.shared
    private var serviceList = [ServiceModel]()
    /// 可用服务
    private var availableServiceList: [ServiceModel] {
        return serviceList.filter {
            $0.isEnabled
        }
    }

    /// 服务状态
    private var serviceStatus = [Int: ServiceManage.Status]() {
        didSet {
            tableView.reloadData()
        }
    }

    private var isSetSplitViewHeight = false

    lazy var window: NSWindow = {
        let w = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 430, height: 300),
                styleMask: [.closable, .titled],
                backing: .buffered,
                defer: true
        )
        w.isReleasedWhenClosed = false
        return w
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        initListener()
        reloadData()
        checkAllStatus()
    }

    @IBAction func checkAll(_ sender: NSButton) {
        run(tips: "检测所有可用服务", serviceList: availableServiceList, operate: .checkStatus)
    }

    @IBAction func startAll(_ sender: NSButton) {
        run(tips: "启动所有可用服务", serviceList: availableServiceList, operate: .start)
    }

    @IBAction func stopAll(_ sender: NSButton) {
        run(tips: "停止所有可用服务", serviceList: availableServiceList, operate: .stop)
    }

    @IBAction func restartAll(_ sender: NSButton) {
        run(tips: "重启所有可用服务", serviceList: availableServiceList, operate: .restart)
    }

    @IBAction func clearLog(_ sender: NSButton) {
        textView.string = ""
    }

    @IBAction func add(_ sender: NSButton) {
        if !window.isVisible {
            let ctrl = ServiceViewController()
            window.title = "添加服务"
            window.contentViewController = ctrl
            window.center()
        }
        window.makeKeyAndOrderFront(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension StatusViewController {
    private func initView() {
        splitView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self

        let arr = UserDefaults.standard.stringArray(forKey: UserDefaultsKey.statusViewControllerSplitView)
        isSetSplitViewHeight = arr == nil ? false : arr!.count > 0
    }

    private func initListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(serviceDidEdited), name: TSNotification.serviceDidEdited.notification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(menuServiceOperate), name: TSNotification.menuServiceOperate.notification, object: nil)
    }

    /// 菜单操作了服务
    @objc private func menuServiceOperate() {
        checkAllStatus()
    }

    /// 服务编辑成功
    @objc private func serviceDidEdited() {
        reloadData()
        checkAllStatus()
    }

    @objc private func reloadData() {
        serviceList = ServiceDB.shared.allServiceList()
        tableView.reloadData()
    }

    @objc private func edit(_ sender: NSButton) {
        let service = serviceList[sender.tag]
        let ctrl = ServiceViewController()
        ctrl.service = service
        window.title = "编辑服务"
        window.contentViewController = ctrl
        window.center()
        window.makeKeyAndOrderFront(self)
    }

    @objc private func enable(_ sender: NSButton) {
        serviceList[sender.tag].isEnabled = sender.state == .on
        ServiceDB.shared.save(service: serviceList[sender.tag])
    }

    @objc private func delete(_ sender: NSButton) {
        let row = sender.tag
        let service = serviceList[row]
        let alert = NSAlert()
        alert.messageText = "确定要删除服务【\(service.name)】？"
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")

        alert.beginSheetModal(for: view.window!, completionHandler: {
            response in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                ServiceDB.shared.deleteService(by: service.id ?? 0)
                NotificationCenter.default.post(name: TSNotification.serviceDidDeleted.notification, object: nil)
                self.reloadData()
            }
        })
    }

    private func textViewAppendText(_ text: String, foregroundColor: NSColor = NSColor.labelColor) {
        let defaultAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: foregroundColor,
        ]
        let attr = NSAttributedString(string: text, attributes: defaultAttr)
        textView.textStorage?.append(attr)
        let loc = textView.string.lengthOfBytes(using: .utf8)
        let range = NSRange(location: loc, length: 0)
        textView.scrollRangeToVisible(range)
    }

    /// 检测所有服务状态
    private func checkAllStatus() {
        run(tips: "检测服务状态", serviceList: availableServiceList, operate: .checkStatus)
    }

    private func run(tips: String, serviceList: [ServiceModel], operate: ServiceModel.Operate) {
        var tips = tips
        if serviceList.isEmpty {
            tips = "无可用服务"
        }

        let count = 40
        let repeating = (count - 2 - tips.count) / 2
        let repeatStr = String(repeating: "＝", count: repeating)
        textViewAppendText("\(repeatStr)　\(tips)　\(repeatStr)\n")

        for service in serviceList {
            serviceManage.run(service: service, operate: operate, completion: {
                group in

                self.serviceStatus[service.id ?? 0] = group.serviceStatus
                if serviceList.first?.id != service.id {
                    self.textViewAppendText("\(String(repeating: "－", count: count))\n")
                }
                self.textViewAppendText("◈◈◈　\(operate.name)【\(service.name)】　◈◈◈\n")
                for command in group.commands {
                    self.textViewAppendText("＊＊＊　执行　＊＊＊\n")
                    self.textViewAppendText("\(command.command)\n")
                    if !command.output.isEmpty {
                        self.textViewAppendText("＊＊＊　输出　＊＊＊\n")
                        self.textViewAppendText("\(command.output)")
                    }
                    if !command.error.isEmpty {
                        self.textViewAppendText("＊＊＊　错误　＊＊＊\n", foregroundColor: NSColor.systemRed)
                        self.textViewAppendText("\(command.error)", foregroundColor: NSColor.systemRed)
                    }
                }
                if serviceList.last?.id == service.id {
                    tips = "\(tips)完成"
                    let repeating = (count - 2 - tips.count) / 2
                    let repeatStr = String(repeating: "＝", count: repeating)
                    self.textViewAppendText("\(repeatStr)　\(tips)　\(repeatStr)\n\n")
                }
            })
        }
    }
}

extension StatusViewController: NSTableViewDelegate, NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 48
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return serviceList.count
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let service = serviceList[row]
        let status = serviceStatus[service.id ?? 0] ?? .none

        if tableView.tableColumns[0] == tableColumn {
            guard let cell = tableView.makeView(withIdentifier: CellIdentifier.name.cellIdentifier, owner: nil) as? NSTableCellView else {
                return nil
            }
            switch status {
            case .none: cell.imageView?.image = NSImage(named: NSImage.statusNoneName)
            case .running: cell.imageView?.image = NSImage(named: NSImage.statusAvailableName)
            case .stopped: cell.imageView?.image = NSImage(named: NSImage.statusUnavailableName)
            }
            cell.textField?.stringValue = service.name
            return cell
        } else if tableView.tableColumns[1] == tableColumn {
            guard let cell = tableView.makeView(withIdentifier: CellIdentifier.command.cellIdentifier, owner: nil) as? StatusCommandCell else {
                return nil
            }
            cell.configView(service: service)
            cell.startClickedBlock = {
                _ in
                self.run(tips: "启动【\(service.name)】", serviceList: [service], operate: .start)
            }
            cell.stopClickedBlock = {
                _ in
                self.run(tips: "停止【\(service.name)】", serviceList: [service], operate: .stop)
            }
            return cell
        } else if tableView.tableColumns[2] == tableColumn {
            guard let cell = tableView.makeView(withIdentifier: CellIdentifier.enabled.cellIdentifier, owner: nil) as? StatusEnableCell else {
                return nil
            }
            cell.enableCheckBox.state = service.isEnabled ? .on : .off
            cell.enableCheckBox.tag = row
            cell.enableCheckBox.action = #selector(enable(_:))
            return cell
        } else if tableView.tableColumns[3] == tableColumn {
            guard let cell = tableView.makeView(withIdentifier: CellIdentifier.edit.cellIdentifier, owner: nil) as? StatusEditCell else {
                return nil
            }
            cell.editButton.tag = row
            cell.editButton.action = #selector(edit(_:))
            cell.deleteButton.tag = row
            cell.deleteButton.action = #selector(delete(_:))
            return cell
        }
        return nil
    }
}

extension StatusViewController: NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 172
    }

    func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if !isSetSplitViewHeight {
            isSetSplitViewHeight = true
            return 272
        }
        return proposedPosition
    }
}
