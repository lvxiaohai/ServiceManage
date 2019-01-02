//
//  const.swift
//  ServiceManage
//
//  Created by tianshui on 2018/11/27.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Foundation

private let appName = "ServiceManage"
private let appIdentifier = "com.github.lvxiaohai.\(appName)"

struct Constant {
    static let mainAppName = appName
    static let mainAppIdentifier = appIdentifier

    static let launcherAppName = "\(appName)Launcher"
    static let launcherAppIdentifier = "\(appIdentifier)Launcher"

    static let helperAppName = "\(appIdentifier)PrivilegedHelper"
    static let helperAppIdentifier = helperAppName
}

struct UserDefaultsKey {
    static let statusViewControllerSplitView = "NSSplitView Subview Frames StatusViewControllerSplitView"
    static let autoLauncher = "autoLauncher"
    static let launcherService = "launcherService"
    static let lastOpenApp = "lastOpenApp"
}
