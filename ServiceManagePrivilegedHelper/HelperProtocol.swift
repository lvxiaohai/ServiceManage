//
// Created by tianshui on 2018-12-01.
// Copyright (c) 2018 tianshui. All rights reserved.
//

import Foundation

@objc protocol HelperProtocol {
    func getVersion(completion: @escaping (_ version: String) -> Void)
    func run(withIdentifier identifier: String, launchPath: String, arguments: [String], authData: NSData?, completion: @escaping (Int) -> Void)
    func run(withIdentifier identifier: String, launchPath: String, arguments: [String], completion: @escaping (Int) -> Void)
}
