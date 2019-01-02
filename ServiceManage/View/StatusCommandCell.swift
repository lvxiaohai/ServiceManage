//
//  StatusCommandCell.swift
//  ServiceManage
//
//  Created by tianshui on 2018/12/20.
//  Copyright © 2018 tianshui. All rights reserved.
//

import Cocoa

class StatusCommandCell: NSTableCellView {
    @IBOutlet var startTextField: NSTextField!
    @IBOutlet var stopTextField: NSTextField!
    
    @IBOutlet var startButton: NSButton!
    @IBOutlet var stopButton: NSButton!

    typealias ButtonClickedBlock = (_ sender: NSButton) -> Void
    var startClickedBlock:  ButtonClickedBlock?
    var stopClickedBlock:  ButtonClickedBlock?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        startButton.target = self
        stopButton.target = self
        
        startButton.action = #selector(start(sender:))
        stopButton.action = #selector(stop(sender:))
    }
    
    @objc func start(sender: NSButton) {
        startClickedBlock?(sender)
    }
    
    @objc func stop(sender: NSButton) {
        stopClickedBlock?(sender)
    }
    
    func configView(service: ServiceModel) {
        startTextField.stringValue = service.startCommand
        stopTextField.stringValue = service.stopCommand
    }
}
