//
//  NSTextFieldExt.swift
//  ServiceManage
//
//  Created by tianshui on 2018/12/18.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Foundation
import Cocoa

extension NSTextField {

    open override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == .keyDown && event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers! {
            case "x":
                if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) {
                    return true
                }
            case "c":
                if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) {
                    return true
                }
            case "v":
                if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) {
                    return true
                }
            case "z":
                if NSApp.sendAction(Selector(("undo:")), to: nil, from: self) {
                    return true
                }
            case "a":
                if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: self) {
                    return true
                }
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
