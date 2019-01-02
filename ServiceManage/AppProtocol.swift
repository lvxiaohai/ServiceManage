//
//  AppProtocol.swift
//  ServiceManage
//
//  Created by tianshui on 2018/11/29.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Foundation

@objc protocol AppProtocol: class {
    func log(error: String)
    func log(output: String)

    func execute(error: String, identifier: String)
    func execute(output: String, identifier: String)
}

