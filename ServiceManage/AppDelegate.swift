//
//  AppDelegate.swift
//  ServiceManage
//
//  Created by tianshui on 2018/11/27.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Cocoa

var mainWindowNumber: Int?

class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    lazy var serviceManage = ServiceManage.shared
    let statusMenu = StatusMenu()
    let privilegedHelper = PrivilegedHelper()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupDB()
        setupUserDefaults()
        setupPrivilegeHelper()
        setupStatusMenu()
        setupLauncherService()
        setupEntryWindow()
        autoLauncherSuccess()
    }

    /// 状态栏菜单
    func setupStatusMenu() {
        let icon = NSImage(named: "status-menu")
        icon?.isTemplate = true

        if #available(OSX 10.14, *) {
            statusItem.button?.image = icon
        } else {
            statusItem.image = icon
        }

        statusItem.menu = statusMenu.mainMenu
    }

    /// 入口window
    func setupEntryWindow() {
        let lastOpenApp = UserDefaults.standard.integer(forKey: UserDefaultsKey.lastOpenApp)
        if lastOpenApp > 0 {
            // app已经打开过则不再显示入口页
            return
        }
        let sb = NSStoryboard(name: "Main", bundle: nil)
        let ctrl = sb.instantiateInitialController() as! NSWindowController
        ctrl.showWindow(self)
        mainWindowNumber = ctrl.window?.windowNumber
    }

    /// helper install
    func setupPrivilegeHelper() {
        // Update the current authorization database right
        // This will prmpt the user for authentication if something needs updating.
        do {
            try HelperAuthorization.authorizationRightsUpdateDatabase()
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }

        privilegedHelper.delegate = self
        privilegedHelper.checkUpdateAndInstall()
    }

    /// 自启动服务
    func setupLauncherService() {
        let autoLauncher = UserDefaults.standard.bool(forKey: UserDefaultsKey.autoLauncher)
        let launcherService = UserDefaults.standard.bool(forKey: UserDefaultsKey.launcherService)
        if !autoLauncher || !launcherService {
            return
        }

        let started = NSWorkspace.shared.runningApplications.contains(where: {
            $0.bundleIdentifier == Constant.launcherAppIdentifier
        })
        // 只有自动启动才自动执行下面的内容
        if !started {
            return
        }

        let serviceList = ServiceDB.shared.allServiceList().filter {
            $0.isEnabled
        }
        for service in serviceList {
            serviceManage.run(service: service, operate: .start) {
                group in
                NSLog("自启动服务成功")
            }
        }
    }

    /// 查看自启动程序是否在运行 如果在运行则发送通知
    func autoLauncherSuccess() {
        let started = NSWorkspace.shared.runningApplications.contains(where: {
            $0.bundleIdentifier == Constant.launcherAppIdentifier
        })

        if started {
            DistributedNotificationCenter.default().postNotificationName(TSNotification.autoLauncherSuccess.notification, object: Bundle.main.bundleIdentifier!)
        }
    }

    /// 配置数据库
    func setupDB() {
        DB.shared.setup()
    }

    /// 默认设置
    func setupUserDefaults() {
        UserDefaults.standard.register(defaults: [
            UserDefaultsKey.autoLauncher: false,
            UserDefaultsKey.launcherService: true,
            UserDefaultsKey.lastOpenApp: Date().timeIntervalSince1970
        ])
        UserDefaults.standard.synchronize()
    }

    /// 检测有多少个与此app相同的包
    /// 自动启动时只能有一个包
    func checkAvailableExist() {
        let paths = LSCopyApplicationURLsForBundleIdentifier(Constant.mainAppIdentifier as CFString, nil)
        print(String(describing: paths))
    }
}

extension AppDelegate: AppProtocol {
    func log(error: String) {
        let alert = NSAlert()
        alert.messageText = error
        alert.runModal()
    }

    func log(output: String) {
        print(output)
    }

    func execute(error: String, identifier: String) {

    }

    func execute(output: String, identifier: String) {

    }
}
