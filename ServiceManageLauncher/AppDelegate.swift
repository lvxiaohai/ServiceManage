//
//  AppDelegate.swift
//  ServiceManageLauncher
//
//  Created by tianshui on 2018/11/27.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // 注意自动启动生效必须放在/Applications文件夹下
        // 并且相同的.app只能有一个可以通过主app的AppDelegate.checkAvailableExist方法查看
        // 查看主app是否运行
        let alreadyRunning = NSWorkspace.shared.runningApplications.contains(where: {
            $0.bundleIdentifier == Constant.mainAppIdentifier
        })

        if alreadyRunning {
            // 主app已运行 终止自启动app
            terminate()
            return
        }

        // 监听主app运行成功通知
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(terminate), name: TSNotification.autoLauncherSuccess.notification, object: Constant.mainAppIdentifier)

        var components = (Bundle.main.bundlePath as NSString).pathComponents
        components.removeLast(4)
        let path = NSString.path(withComponents: components)
        NSWorkspace.shared.launchApplication(path)
    }

    @objc func terminate() {
        NSApp.terminate(nil)
    }
}

