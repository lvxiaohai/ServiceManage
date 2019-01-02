//
// Created by tianshui on 2018-12-18.
// Copyright (c) 2018 tianshui. All rights reserved.
//

import Foundation
import SQLite

class ServiceDB {

    static let shared = ServiceDB()

    private var db: Connection {
        return DB.shared.client
    }


    private init() {
    }

    /// 获取指定服务
    ///
    /// - Parameter id: 主键
    /// - Returns:
    func getService(by id: Int) -> ServiceModel? {
        let table = Table("service")
        let idExpression = Expression<Int>("id")

        guard let r = try? db.pluck(table.filter(idExpression == id)), let row = r else {
            return nil
        }
        let result: ServiceModel? = try? row.decode()
        return result
    }


    /// 删除指定服务
    ///
    /// - Parameter id: 主键
    /// - Returns: 删除是否成功
    @discardableResult
    func deleteService(by id: Int) -> Bool {
        let table = Table("service")
        let idExpression = Expression<Int>("id")

        guard let r = try? db.run(table.filter(idExpression == id).delete()) else {
            return false
        }
        return r > 0
    }

    /// 获取所有服务
    ///
    /// - Returns: 
    func allServiceList() -> [ServiceModel] {
        let table = Table("service")
        let isEnabledExpression = Expression<Bool>("isEnabled")

        guard let rows = try? db.prepare(table.order(isEnabledExpression.desc)) else {
            return []
        }
        let results: [ServiceModel] = rows.compactMap({ try? $0.decode() })
        return results
    }

    /// 保存服务
    ///
    /// - Parameter service: 服务
    /// - Returns: 保存结果
    @discardableResult
    func save(service: ServiceModel) -> Bool {
        let table = Table("service")
        if service.id == nil {
            // 插入
            guard let id = try? db.run(table.insert(service)) else {
                return false
            }
            if id > 0 {
                return true
            }
        } else {
            // 更新
            let idExpression = Expression<Int>("id")
            guard let num = try? db.run(table.filter(idExpression == service.id!).update(service)) else {
                return false
            }
            if num > 0 {
                return true
            }
        }
        return false
    }
}
