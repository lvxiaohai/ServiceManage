//
//  StatusEditCell.swift
//  ServiceManage
//
//  Created by tianshui on 2018/12/20.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Cocoa

class StatusEditCell: NSTableCellView {
    @IBOutlet var editButton: NSButton!
    @IBOutlet var deleteButton: NSButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        editButton.image?.isTemplate = true
        deleteButton.image?.isTemplate = true
    }
}
