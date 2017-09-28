//
//  RemoteLedDelegate.swift
//  RemoteLed
//
//  Created by Adonis Gaitatzis on 12/2/16.
//  Copyright © 2016 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 RemoteLedDelegate relays connection and state information
 */
protocol RemoteLedDelegate {
    
    /**
     Characteristic was connected on the Remote LED
     
     - Parameters:
        - characteristic: the connected Characteristic
     */
    func remoteLed(connectedToCharacteristics characteristics: [CBCharacteristic])
    
    /**
     Error received from Remote
     
     - Parameters
        - messageValue: an error response
     */
    func remoteLed(errorReceived messageValue: String)
    
    /**
     Remote command was successful and a response was issued
     
     - Parameters:
        - ledState: one of RemoteLed.ledOn or RemoteLed.ledOff
     */
    func remoteLed(confirmationReceived ledState: UInt8)
    
}
