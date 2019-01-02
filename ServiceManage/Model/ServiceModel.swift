//
// Created by tianshui on 2018-12-18.
// Copyright (c) 2018 tianshui. All rights reserved.
//

import Foundation

struct ServiceModel: Codable {

    private (set) var id: Int?
    /// 服务名
    var name = ""
    /// 启动命令
    var startCommand = ""
    /// 停止命令
    var stopCommand = ""
    /// 重启命令
    var restartCommand = ""
    /// 检测命令
    var statusCommand = ""

    /// 启动使用root
    var startUseRoot = false
    /// 停止使用root
    var stopUseRoot = false
    /// 重启使用root
    var restartUseRoot = false

    /// 重启使用[停止,启动]组合
    var restartUseShortcut = true

    /// 启用此服务
    var isEnabled = true

    /// 检测命令
    var statusFullCommand: String {
        return "pgrep \(statusCommand)"
    }

    init() {}
}

extension ServiceModel {
    /// 操作
    enum Operate {
        case start, stop, restart, checkStatus
        var name: String {
            switch self {
            case .start: return "启动"
            case .stop: return "停止"
            case .restart: return "重启"
            case .checkStatus: return "检测"
            }
        }
    }

}
