//
// Created by tianshui on 2018-12-19.
// Copyright (c) 2018 tianshui. All rights reserved.
//

import Foundation
import SQLite

class DB {

    lazy var client: Connection = {
        var path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first! + "/\(Constant.mainAppName)"
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        let c = try! Connection("\(path)/db.sqlite3")
        return c
    }()

    static let shared = DB()

    private init() {
    }

    func setup() {
        let service = Table("service")

        let _ = try? client.run(service.create {
            t in
            t.column(Expression<Int>("id"), primaryKey: .autoincrement)
            t.column(Expression<String>("name"))
            t.column(Expression<Bool>("restartUseShortcut"))

            t.column(Expression<String>("startCommand"))
            t.column(Expression<String>("stopCommand"))
            t.column(Expression<String>("restartCommand"))
            t.column(Expression<String>("statusCommand"))

            t.column(Expression<Bool>("startUseRoot"))
            t.column(Expression<Bool>("stopUseRoot"))
            t.column(Expression<Bool>("restartUseRoot"))

            t.column(Expression<Bool>("isEnabled"))
        })
    }
}
