//
// Created by tianshui on 2018-12-24.
// Copyright (c) 2018 tianshui. All rights reserved.
//

import Foundation

/// 服务管理
class ServiceManage {

    typealias Completion = ((Group) -> Void)

    lazy var privilegedHelper = PrivilegedHelper()

    static let shared = ServiceManage()

    /// 命令队列
    private var serviceGroups = [Group]()

    private init() {
        privilegedHelper.delegate = self
    }

    /// 运行服务
    func run(service: ServiceModel, operate: ServiceModel.Operate, completion: @escaping Completion) {

        var commands = [Command]()
        switch operate {
        case .start:
            commands.append(Command(operate: .start, command: service.startCommand, useRoot: service.startUseRoot))
        case .stop:
            commands.append(Command(operate: .stop, command: service.stopCommand, useRoot: service.stopUseRoot))
        case .restart:
            if service.restartUseShortcut {
                commands.append(Command(operate: .stop, command: service.stopCommand, useRoot: service.stopUseRoot))
                commands.append(Command(operate: .start, command: service.startCommand, useRoot: service.startUseRoot))
            } else {
                commands.append(Command(operate: .restart, command: service.restartCommand, useRoot: service.restartUseRoot))
            }
        case .checkStatus:
            break
        }
        // 所有操作统一添加检测命令
        commands.append(Command(operate: .checkStatus, command: service.statusFullCommand))

        let group = Group(operate: operate, commands: commands, completion: completion)
        serviceGroups.append(group)
        doRun()
    }

    private func doRun() {
        guard let group = serviceGroups.first else {
            return
        }

        // 同时只运行一个命令
        if group.hasRunning {
            return
        }

        // 所有子命令执行完成 则删除
        if group.allDone {
            DispatchQueue.main.async {
                group.completion(group)
            }
            serviceGroups = Array(serviceGroups.dropFirst())
            doRun()
            return
        }

        guard let index = group.commands.firstIndex(where: { !$0.done && !$0.isRunning }) else {
            return
        }
        let command = group.commands[index]
        let uuid = command.uuid
        // 每个命令执行sleep n秒
        let cmd = command.command
        serviceGroups[0].commands[index].isRunning = true

        privilegedHelper.runShell(withIdentifier: uuid.uuidString, command: cmd, asRoot: command.useRoot) {
            exitCode in
            let index = self.serviceGroups[0].commands.firstIndex(where: { $0.uuid == uuid })!
            self.serviceGroups[0].commands[index].done = true
            self.serviceGroups[0].commands[index].isRunning = false
            usleep(100 * 1000)
            self.doRun()
        }
    }

    /// 通过id搜索命令在serviceGroups中的位置
    private func search(identifier: String) -> (i: Int, j: Int)? {
        for (i, group) in serviceGroups.enumerated() {
            if let j = group.commands.firstIndex(where: { $0.uuid.uuidString == identifier }) {
                return (i, j)
            }
        }
        return nil
    }
}

extension ServiceManage {
    /// 服务当前状态
    enum Status {
        case running, stopped, none
    }
}

extension ServiceManage {
    /// 命令
    struct Command {
        private(set) var uuid = UUID()
        /// 操作
        var operate: ServiceModel.Operate
        var command: String
        var useRoot: Bool
        /// 已运行完成
        var done = false
        /// 错误信息
        var error = ""
        /// 输出信息
        var output = ""
        /// 正在运行状态
        var isRunning = false

        init(operate: ServiceModel.Operate, command: String, useRoot: Bool = false) {
            self.operate = operate
            self.command = command
            self.useRoot = useRoot
        }
    }

    /// 一组命令
    struct Group {
        /// 操作
        var operate: ServiceModel.Operate
        /// 子命令
        var commands: [Command]
        /// 完成回调
        var completion: Completion
        /// 是否全部完成子命令
        var allDone: Bool {
            return commands.allSatisfy {
                $0.done
            }
        }
        /// 是否有正在运行子命令
        var hasRunning: Bool {
            return commands.contains(where: { $0.isRunning })
        }

        /// 服务状态
        var serviceStatus: Status {
            if !allDone {
                return .none
            }

            guard let checkCommand = commands.first(where: { $0.operate == .checkStatus }) else {
                return .none
            }

            let pids = checkCommand.output.split(separator: "\n").compactMap {
                Int($0)
            }
            if pids.isEmpty {
                return .stopped
            } else {
                return .running
            }
        }

        init(operate: ServiceModel.Operate, commands: [Command], completion: @escaping Completion) {
            self.operate = operate
            self.commands = commands
            self.completion = completion
        }
    }
}


extension ServiceManage: AppProtocol {

    func execute(error: String, identifier: String) {
        guard let (i, j) = search(identifier: identifier) else {
            return
        }
        serviceGroups[i].commands[j].error += error
    }

    func execute(output: String, identifier: String) {
        guard let (i, j) = search(identifier: identifier) else {
            return
        }
        serviceGroups[i].commands[j].output += output
    }

    func log(error: String) {
        print("error: \(error)")
    }

    func log(output: String) {
        print("output: \(output)")
    }
}
