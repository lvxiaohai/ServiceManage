//
//  StatusMenu.swift
//  ServiceManage
//
//  Created by tianshui on 2018/12/6.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

/// 状态栏菜单
class StatusMenu: NSObject {

    var mainMenu = NSMenu(title: "main")
    var aboutMenuItem = NSMenuItem(title: "关于", action: nil, keyEquivalent: "")
    var windowMenuItem = NSMenuItem(title: "主界面", action: nil, keyEquivalent: "")
    var quitMenuItem = NSMenuItem(title: "退出", action: nil, keyEquivalent: "q")

    private lazy var serviceManage = ServiceManage.shared
    /// 服务状态
    private var serviceStatus = [Int: ServiceManage.Status]() {
        didSet {
            updateMenu()
        }
    }

    override init() {
        super.init()
        initView()
        initListener()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension StatusMenu {
    @objc func start(_ sender: NSMenuItem) {
        menuOperate(tag: sender.tag, operate: .start)
    }

    @objc func stop(_ sender: NSMenuItem) {
        menuOperate(tag: sender.tag, operate: .stop)
    }

    @objc func restart(_ sender: NSMenuItem) {
        menuOperate(tag: sender.tag, operate: .restart)
    }

    private func menuOperate(tag: Int, operate: ServiceModel.Operate) {
        var serviceList = [ServiceModel]()
        if let service = ServiceDB.shared.getService(by: tag) {
            serviceList = [service]
        } else {
            serviceList = ServiceDB.shared.allServiceList().filter {
                $0.isEnabled
            }
        }
        run(serviceList: serviceList, operate: operate, needNotification: true)
    }

    @objc func aboutClicked(_ sender: NSMenuItem) {
        NSApplication.shared.orderFrontStandardAboutPanel(nil)
        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
    }

    @objc func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }

    @objc func windowClicked(_ sender: NSMenuItem) {

        if let num = mainWindowNumber, let window = NSApplication.shared.window(withWindowNumber: num) {
            window.orderFront(self)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let sb = NSStoryboard(name: "Main", bundle: nil)
        let ctrl = sb.instantiateInitialController() as! NSWindowController
        ctrl.showWindow(self)
        mainWindowNumber = ctrl.window?.windowNumber
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension StatusMenu {

    private func initView() {

        mainMenu.delegate = self

        aboutMenuItem.target = self
        aboutMenuItem.action = #selector(aboutClicked(_:))
        windowMenuItem.target = self
        windowMenuItem.action = #selector(windowClicked(_:))
        quitMenuItem.target = self
        quitMenuItem.action = #selector(quitClicked(_:))

        let menuItems = allMenuItems()
        menuItems.forEach {
            mainMenu.addItem($0)
        }
    }

    private func initListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(serviceDidEdited), name: TSNotification.serviceDidEdited.notification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(serviceDidEdited), name: TSNotification.serviceDidDeleted.notification, object: nil)
    }

    @objc private func serviceDidEdited() {
        mainMenu.removeAllItems()
        let menuItems = allMenuItems()
        menuItems.forEach {
            mainMenu.addItem($0)
        }
    }

    /// 所有菜单
    private func allMenuItems() -> [NSMenuItem] {
        let part1 = [
            aboutMenuItem,
            NSMenuItem.separator(),
            windowMenuItem,
            NSMenuItem.separator(),
        ]
        let serviceMenuItems = getServiceMenuItems()
        let part2 = [
            NSMenuItem.separator(),
            quitMenuItem,
        ]
        return part1 + serviceMenuItems + part2
    }

    /// 服务菜单
    private func getServiceMenuItems() -> [NSMenuItem] {
        var serviceList = ServiceDB.shared.allServiceList().filter {
            $0.isEnabled
        }
        if serviceList.isEmpty {
            return []
        }
        if serviceList.count > 15 {
            serviceList = Array(serviceList[0..<15])
        }

        var menuItems = [NSMenuItem]()
        var all = ServiceModel()
        all.name = "所有服务"

        serviceList.insert(all, at: 0)
        for service in serviceList {
            let menuItem = NSMenuItem(title: service.name, action: nil, keyEquivalent: "")
            let subMenu = NSMenu()
            menuItem.tag = service.id ?? 0

            if service.id != nil {
                menuItem.state = .mixed
                menuItem.mixedStateImage = NSImage(named: NSImage.statusNoneName)
                menuItem.onStateImage = NSImage(named: NSImage.statusAvailableName)
                menuItem.offStateImage = NSImage(named: NSImage.statusUnavailableName)
            }

            for operate in [ServiceModel.Operate.start, .stop, .restart] {
                let subMenItem = NSMenuItem(title: operate.name, action: nil, keyEquivalent: "")
                subMenItem.target = self
                subMenItem.tag = service.id ?? 0

                switch operate {
                case .start: subMenItem.action = #selector(start(_:))
                case .stop: subMenItem.action = #selector(stop(_:))
                case .restart: subMenItem.action = #selector(restart(_:))
                default: break
                }
                subMenu.addItem(subMenItem)
            }
            menuItem.submenu = subMenu
            menuItems.append(menuItem)
        }
        return menuItems
    }

    /// 更新菜单
    private func updateMenu() {

        for menuItem in mainMenu.items {
            guard let status = serviceStatus[menuItem.tag] else {
                continue
            }
            let index = mainMenu.index(of: menuItem)
            mainMenu.removeItem(menuItem)
            mainMenu.insertItem(menuItem, at: index)
            switch status {
            case .running: menuItem.state = .on
            case .stopped: menuItem.state = .off
            case .none: menuItem.state = .mixed
            }
        }
    }

    /// 检测所有服务状态
    private func checkAllStatus() {
        let serviceList = ServiceDB.shared.allServiceList().filter {
            $0.isEnabled
        }
        run(serviceList: serviceList, operate: .checkStatus)
    }

    private func run(serviceList: [ServiceModel], operate: ServiceModel.Operate, needNotification: Bool = false) {
        for service in serviceList {
            serviceManage.run(service: service, operate: operate) {
                group in
                self.serviceStatus[service.id ?? 0] = group.serviceStatus
                if needNotification && service.id == serviceList.last?.id {
                    NotificationCenter.default.post(name: TSNotification.menuServiceOperate.notification, object: nil)
                }
            }
        }
    }
}

extension StatusMenu: NSMenuDelegate {
    public func menuWillOpen(_ menu: NSMenu) {
        checkAllStatus()
    }
}
