//
//  MainViewController.swift
//  ServiceManage
//
//  Created by tianshui on 2018/12/12.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Cocoa

protocol ViewControllerOriginalSize {
    var originalSize: CGSize { get set }
}

// 主入口
class MainViewController: NSViewController {
    @IBOutlet var tabView: NSTabView!

    let preferenceCtrl = PreferenceViewController()
    let statusCtrl = StatusViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
    }

    private func initView() {
        tabView.delegate = self

        let statusItem = NSTabViewItem(viewController: statusCtrl)
        statusItem.label = "状态"
        tabView.addTabViewItem(statusItem)

        let preferenceItem = NSTabViewItem(viewController: preferenceCtrl)
        preferenceItem.label = "设置"
        tabView.addTabViewItem(preferenceItem)
    }
}

extension MainViewController: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        guard let ctrl = tabViewItem?.viewController as? ViewControllerOriginalSize else {
            return
        }

        guard let window = view.window else {
            return
        }
        let size = window.frameRect(forContentRect: CGRect(origin: .zero, size: ctrl.originalSize)).size

        var frame = window.frame
        frame.origin.y += frame.height - size.height
        frame.size = size
        window.setFrame(frame, display: true, animate: true)
    }
}
