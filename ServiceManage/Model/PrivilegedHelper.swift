//
//  PrivilegedHelper.swift
//  ServiceManage
//
//  Created by tianshui on 2018/12/10.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Foundation
import ServiceManagement

class PrivilegedHelper: NSObject {
    private var currentHelperConnection: NSXPCConnection?

    weak var delegate: AppProtocol?

    override init() {
    }

    /// 检查更新并安装
    func checkUpdateAndInstall() {

        // 检查helper是否已安装
        let exists = FileManager.default.fileExists(atPath: "/Library/PrivilegedHelperTools/\(Constant.helperAppIdentifier)")
        if !exists {
            delegate?.log(output: "helper not exists")
            install()
        }

        helperStatus(completion: {
            installed in

            if installed {
                self.delegate?.log(output: "helper installed")
                return
            }
            self.delegate?.log(output: "helper not installed")
            self.install()
        })
    }

    /// 运行shell脚本
    func runShell(withIdentifier identifier: String, command: String, asRoot: Bool = false, completion: @escaping ((_ exitCode: Int) -> Void)) {
        let launchPath = "/bin/sh"
        let arguments = ["-c", command]

        func completionFunc(exitCode: Int) {
            if exitCode == kAuthorizationFailedExitCode {
                delegate?.log(error: "Authentication Failed")
            }
            completion(exitCode)
        }

        if !asRoot {
            helper()?.run(withIdentifier: identifier, launchPath: launchPath, arguments: arguments, completion: completionFunc)
            return
        }

        do {
            guard let authData = try HelperAuthorization.emptyAuthorizationExternalFormData() else {
                delegate?.log(error: "Failed to get the empty authorization external form")
                return
            }
            helper()?.run(withIdentifier: identifier, launchPath: launchPath, arguments: arguments, authData: authData, completion: completionFunc)
        } catch {
            log(error: error)
        }
    }

    // 获取helper
    private func helper() -> HelperProtocol? {
        return helper(completion: nil)
    }

    private func install() {
        do {
            let result = try helperInstall()
            if result {
                delegate?.log(output: "helper installed successfully")
            } else {
                delegate?.log(error: "Failed install helper with unknown error.")
            }

        } catch {
            log(error: error)
        }
    }

    private func helper(completion: ((Bool) -> Void)? = nil) -> HelperProtocol? {
        // Get the current helper connection and return the remote object (Helper.swift) as a proxy object to call functions on.
        let h = helperConnection()?.remoteObjectProxyWithErrorHandler {
            error in
            self.log(error: error)
            completion?(false)
        }
        guard let helper = h as? HelperProtocol else {
            return nil
        }
        return helper
    }

    private func helperStatus(completion: @escaping ((Bool) -> Void)) {
        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LaunchServices/\(Constant.helperAppIdentifier)") as CFURL
        guard let info = CFBundleCopyInfoDictionaryForURL(helperURL) as? [String: Any],
              let version = info[kCFBundleVersionKey as String] as? String,
              let helper = helper(completion: completion) else {
            completion(false)
            return
        }

        delegate?.log(output: "current version -- \(version)")
        helper.getVersion(completion: {
            installedVersion in
            self.delegate?.log(output: "installed version -- \(installedVersion)")
            completion(installedVersion == version)
        })
    }

    private func helperConnection() -> NSXPCConnection? {
        guard currentHelperConnection == nil else {
            return currentHelperConnection
        }

        let connection = NSXPCConnection(machServiceName: Constant.helperAppIdentifier, options: .privileged)
        connection.exportedInterface = NSXPCInterface(with: AppProtocol.self)
        connection.exportedObject = delegate
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.invalidationHandler = {
            self.currentHelperConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self.currentHelperConnection = nil
            }
        }

        currentHelperConnection = connection
        currentHelperConnection?.resume()
        return currentHelperConnection
    }

    private func helperInstall() throws -> Bool {
        // Install and activate the helper inside our application bundle to disk.

        var cfError: Unmanaged<CFError>?
        var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: UnsafeMutableRawPointer(bitPattern: 0), flags: 0)
        var authRights = AuthorizationRights(count: 1, items: &authItem)

        guard let authRef = try HelperAuthorization.authorizationRef(&authRights, nil, [.interactionAllowed, .extendRights, .preAuthorize]),
              SMJobBless(kSMDomainSystemLaunchd, Constant.helperAppIdentifier as CFString, authRef, &cfError) else {
            if let error = cfError?.takeRetainedValue() {
                throw error
            }
            return false
        }

        currentHelperConnection?.invalidate()
        currentHelperConnection = nil
        return true
    }

    private func log(error: Error) {
        var text = error.localizedDescription
        switch error as? HelperAuthorizationError {
        case let .message(msg)?:
            text = msg
        default:
            break
        }
        delegate?.log(error: text)
    }
}
