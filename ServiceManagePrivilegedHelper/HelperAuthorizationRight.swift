//
// Created by tianshui on 2018-12-01.
// Copyright (c) 2018 tianshui. All rights reserved.
//
import Foundation

struct HelperAuthorizationRight {

    let command: Selector
    let name: String
    let description: String
    let ruleCustom: [String: Any]?
    let ruleConstant: String?

    init(command: Selector, name: String? = nil, description: String, ruleCustom: [String: Any]? = nil, ruleConstant: String? = nil) {
        self.command = command
        self.name = name ?? Constant.helperAppIdentifier + "." + command.description
        self.description = description
        self.ruleCustom = ruleCustom
        self.ruleConstant = ruleConstant
    }

    func rule() -> CFTypeRef {
        let rule: CFTypeRef
        if let ruleCustom = ruleCustom as CFDictionary? {
            rule = ruleCustom
        } else if let ruleConstant = ruleConstant as CFString? {
            rule = ruleConstant
        } else {
            rule = kAuthorizationRuleAuthenticateAsAdmin as CFString
        }
        return rule
    }
}

