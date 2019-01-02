//
//  TSNotification.swift
//  ServiceManage
//
//  Created by tianshui on 2018/11/27.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Foundation

/// 用户自定义通知 Notification
enum TSNotification: String {

    /// 开机启动成功
    case autoLauncherSuccess

    /// 服务已编辑
    case serviceDidEdited

    /// 服务已删除
    case serviceDidDeleted

    /// 菜单操作服务
    case menuServiceOperate

    var notification: Notification.Name {
        return Notification.Name(rawValue: rawValue)
    }
}
