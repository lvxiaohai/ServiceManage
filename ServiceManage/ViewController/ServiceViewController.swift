//
//  ServiceViewController.swift
//  ServiceManage
//
//  Created by tianshui on 2018/12/14.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Cocoa

// 服务
class ServiceViewController: NSViewController {
    @IBOutlet var nameTextField: NSTextField!
    @IBOutlet var startTextField: NSTextField!
    @IBOutlet var stopTextField: NSTextField!
    @IBOutlet var restartTextField: NSTextField!
    @IBOutlet var statusTextField: NSTextField!

    @IBOutlet var startRootCheckBox: NSButton!
    @IBOutlet var stopRootCheckBox: NSButton!
    @IBOutlet var restartRootCheckBox: NSButton!

    @IBOutlet var restartShortcutCheckBox: NSButton!

    var service = ServiceModel()

    override var nibName: NSNib.Name? {
        return "ServiceViewController"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        initData()
    }

    @IBAction func save(_ sender: NSButton) {
        let (isValid, msg) = check()
        let alert = NSAlert()
        if !isValid {
            alert.messageText = msg
            alert.beginSheetModal(for: view.window!)
            return
        }
        let success = ServiceDB.shared.save(service: service)
        if success {
            NotificationCenter.default.post(name: TSNotification.serviceDidEdited.notification, object: nil)
            view.window?.close()
            return
        }
        alert.messageText = "保存失败"
        alert.beginSheetModal(for: view.window!)
    }

    @IBAction func close(_ sender: NSButton) {
        view.window?.close()
    }
}

extension ServiceViewController {
    private func initView() {
        nameTextField.delegate = self
        startTextField.delegate = self
        stopTextField.delegate = self
        restartTextField.delegate = self
        statusTextField.delegate = self

        let action = #selector(checkboxChanged(sender:))
        startRootCheckBox.action = action
        stopRootCheckBox.action = action
        restartRootCheckBox.action = action
        restartShortcutCheckBox.action = action
    }

    private func initData() {
        nameTextField.stringValue = service.name
        startTextField.stringValue = service.startCommand
        stopTextField.stringValue = service.stopCommand
        restartTextField.stringValue = service.restartCommand
        statusTextField.stringValue = service.statusCommand

        startRootCheckBox.state = service.startUseRoot ? .on : .off
        stopRootCheckBox.state = service.stopUseRoot ? .on : .off
        restartRootCheckBox.state = service.restartUseRoot ? .on : .off
        restartShortcutCheckBox.state = service.restartUseShortcut ? .on : .off

        restartTextField.isEnabled = !service.restartUseShortcut
        restartRootCheckBox.isEnabled = !service.restartUseShortcut
    }

    @objc private func checkboxChanged(sender: NSButton) {
        let checked = sender.state == .on
        switch sender {
        case restartShortcutCheckBox:
            service.restartUseShortcut = checked
            restartTextField.isEnabled = !checked
            restartRootCheckBox.isEnabled = !checked
        case startRootCheckBox:
            service.startUseRoot = checked
        case stopRootCheckBox:
            service.stopUseRoot = checked
        case restartRootCheckBox:
            service.restartUseRoot = checked
        default:
            break
        }
    }

    private func check() -> (isValid: Bool, msg: String) {
        var msgs = [String]()
        if service.name.isEmpty {
            msgs.append("请输入服务名称")
        }
        if service.startCommand.isEmpty {
            msgs.append("请输入启动服务命令")
        }
        if service.stopCommand.isEmpty {
            msgs.append("请输入停止服务命令")
        }
        if !service.restartUseShortcut && service.restartCommand.isEmpty {
            msgs.append("请输入重启服务命令")
        }
        if service.statusCommand.isEmpty {
            msgs.append("请输入检测服务已启动命令")
        }
        if msgs.isEmpty {
            return (true, "")
        }
        return (false, msgs.joined(separator: "\n"))
    }
}

extension ServiceViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else {
            return
        }
        let text = textField.stringValue
        switch textField {
        case nameTextField:
            service.name = text
        case startTextField:
            service.startCommand = text
        case stopTextField:
            service.stopCommand = text
        case restartTextField:
            service.restartCommand = text
        case statusTextField:
            service.statusCommand = text
        default:
            break
        }
    }
}
