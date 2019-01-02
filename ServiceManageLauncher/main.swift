//
//  main.swift
//  ServiceManageLauncher
//
//  Created by tianshui on 2018/12/6.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Cocoa

autoreleasepool {
    let delegate = AppDelegate()
    let app = NSApplication.shared
    app.delegate = delegate
    app.run()
}
