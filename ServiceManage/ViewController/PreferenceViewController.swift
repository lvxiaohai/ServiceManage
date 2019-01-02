//
//  PreferenceViewController.swift
//  ServiceManage
//
//  Created by tianshui on 2018/12/14.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Cocoa
import ServiceManagement

// 设置
class PreferenceViewController: NSViewController, ViewControllerOriginalSize {

    @IBOutlet weak var autoLauncherCheckBox: NSButton!
    @IBOutlet weak var launcherServiceCheckBox: NSButton!

    var originalSize = CGSize(width: 600, height: 300)


    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

    @IBAction func autoLauncherClicked(_ sender: NSButton) {
        let autoLauncher = sender.state == .on
        startupAppWhenLogin(startup: autoLauncher)
        launcherServiceCheckBox.isEnabled = autoLauncher
        UserDefaults.standard.set(autoLauncher, forKey: UserDefaultsKey.autoLauncher)
        UserDefaults.standard.synchronize()
    }


    @IBAction func launcherServiceClicked(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: UserDefaultsKey.launcherService)
        UserDefaults.standard.synchronize()
    }
}

extension PreferenceViewController {
    private func initView() {
        let autoLauncher = UserDefaults.standard.bool(forKey: UserDefaultsKey.autoLauncher)
        let launcherService = UserDefaults.standard.bool(forKey: UserDefaultsKey.launcherService)
        autoLauncherCheckBox.state = autoLauncher ? .on : .off
        launcherServiceCheckBox.state = launcherService ? .on : .off

        launcherServiceCheckBox.isEnabled = autoLauncher
    }

    // 注册/取消启动项
    func startupAppWhenLogin(startup: Bool) {
        let status = SMLoginItemSetEnabled(Constant.launcherAppIdentifier as CFString, startup)
        if status {
            NSLog("自启动设置成功 \(startup)")
        } else {
            NSLog("自启动设置失败 \(startup)")
        }
    }
}
