//
// Created by tianshui on 2018-12-01.
// Copyright (c) 2018 tianshui. All rights reserved.
//

import Foundation

class Helper: NSObject, NSXPCListenerDelegate {

    // MARK: -
    // MARK: Private Constant Variables

    private let listener: NSXPCListener

    // MARK: -
    // MARK: Private Variables

    private var connections = [NSXPCConnection]()
    private var shouldQuit = false
    private var shouldQuitCheckInterval = 1.0

    // MARK: -
    // MARK: Initialization

    override init() {
        listener = NSXPCListener(machServiceName: Constant.helperAppIdentifier)
        super.init()
        listener.delegate = self
    }

    public func run() {
        listener.resume()

        // Keep the helper tool running until the variable shouldQuit is set to true.
        // The variable should be changed in the "listener(_ listener:shoudlAcceptNewConnection:)" function.

        while !shouldQuit {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: shouldQuitCheckInterval))
        }
    }

    // MARK: -
    // MARK: NSXPCListenerDelegate Methods

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {

        // Verify that the calling application is signed using the same code signing certificate as the helper
        guard isValid(connection: connection) else {
            return false
        }

        // Set the protocol that the calling application conforms to.
        connection.remoteObjectInterface = NSXPCInterface(with: AppProtocol.self)

        // Set the protocol that the helper conforms to.
        connection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedObject = self

        // Set the invalidation handler to remove this connection when it's work is completed.
        connection.invalidationHandler = {
            if let connectionIndex = self.connections.firstIndex(of: connection) {
                self.connections.remove(at: connectionIndex)
            }

            if self.connections.isEmpty {
                self.shouldQuit = true
            }
        }

        connections.append(connection)
        connection.resume()

        return true
    }

    // MARK: -
    // MARK: Private Helper Methods

    private func isValid(connection: NSXPCConnection) -> Bool {
        do {
            return try CodeSignCheck.codeSigningMatches(pid: connection.processIdentifier)
        } catch {
            NSLog("Code signing check failed with error: \(error)")
            return false
        }
    }

    private func verifyAuthorization(_ authData: NSData?, forCommand command: Selector) -> Bool {
        do {
            try HelperAuthorization.verifyAuthorization(authData, forCommand: command)
        } catch {
            if let remoteObject = connection()?.remoteObjectProxy as? AppProtocol {
                remoteObject.log(error: "Authentication Error: \(error)")
            }
            return false
        }
        return true
    }

    private func connection() -> NSXPCConnection? {
        return connections.last
    }

    private func runTask(withIdentifier identifier: String, launchPath: String, arguments: [String], completion: @escaping (Int) -> Void) {
        let task = Process()

        let stdOut = Pipe()
        stdOut.fileHandleForReading.readabilityHandler = {
            file in
            let data = file.availableData
            guard let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                return
            }
            guard output.length > 0 else {
                return
            }
            if let remoteObject = self.connection()?.remoteObjectProxy as? AppProtocol {
                remoteObject.execute(output: output as String, identifier: identifier)
            }
        }

        let stdErr = Pipe()
        stdErr.fileHandleForReading.readabilityHandler = {
            file in
            let data = file.availableData
            guard let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                return
            }
            guard output.length > 0 else {
                return
            }
            if let remoteObject = self.connection()?.remoteObjectProxy as? AppProtocol {
                remoteObject.execute(error: output as String, identifier: identifier)
            }
        }

        task.launchPath = launchPath
        task.arguments = arguments
        task.standardOutput = stdOut
        task.standardError = stdErr

        task.terminationHandler = {
            task in
            completion(Int(task.terminationStatus))
        }

        task.launch()
    }
}

extension Helper: HelperProtocol {

    // MARK: -
    // MARK: HelperProtocol Methods

    func getVersion(completion: @escaping (String) -> Void) {
        let version = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
        completion(version ?? "0")
    }

    func run(withIdentifier identifier: String, launchPath: String, arguments: [String], authData: NSData?, completion: @escaping (Int) -> Void) {
        // Check the passed authorization, if the user need to authenticate to use this command the user might be prompted depending on the settings and/or cached authentication.
        guard verifyAuthorization(authData, forCommand: #selector(HelperProtocol.run(withIdentifier:launchPath:arguments:authData:completion:))) else {
            completion(kAuthorizationFailedExitCode)
            return
        }
        runTask(withIdentifier: identifier, launchPath: launchPath, arguments: arguments, completion: completion)
    }

    func run(withIdentifier identifier: String, launchPath: String, arguments: [String], completion: @escaping (Int) -> Void) {
        runTask(withIdentifier: identifier, launchPath: launchPath, arguments: arguments, completion: completion)
    }
}
