//
//  CharacteristicViewController.swift
//  ReadCharacteristic
//
//  Created by Adonis Gaitatzis on 11/22/16.
//  Copyright © 2016 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 Controls the View Controller
 */
class CharacteristicViewController: UIViewController, CBCentralManagerDelegate, RemoteLedDelegate {
    
    // MARK: UI Components
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var ledStateSwitch: UISwitch!
    
    
    // MARK: Bluetooth stuff
    
    // Bluetooth Radio
    var centralManager:CBCentralManager!
    
    // the remote Peripheral
    var remoteLed:RemoteLed!
    
    
    /**
     View loaded
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    /**
     LED switch toggled
     */
    @IBAction func onLedStateSwitchTouchUp(_ sender: UISwitch) {
        // prevent user interaction during update
        sender.isEnabled = false
        
        if sender.isOn {
            print("led switched on")
            remoteLed.turnLedOn()
        } else {
            print("led switched off")
            remoteLed.turnLedOff()
        }
    }
    
    
    // MARK: RemoteLedDelegate
    
    /**
     Characteristic was connected on the Remote LED. Update UI
     */
    func remoteLed(connectedToCharacteristics characteristics: [CBCharacteristic]) {
        ledStateSwitch.isEnabled = true
        remoteLed.turnLedOn()
    }
    
    
    /**
     Error received from Remote.  Update UI
     */
    func remoteLed(errorReceived messageValue: String) {
        // There was a problem.  flip the switch back
        ledStateSwitch.isOn = !ledStateSwitch.isOn
        ledStateSwitch.isEnabled = true
    }
    
    
    /**
     Remote command was successful and a response was issued. Update UI
     */
    func remoteLed(confirmationReceived ledState: UInt8) {
        if ledState == RemoteLed.bleResponseLedOn {
            print("led turned on")
            ledStateSwitch.isOn = true
        } else {
            print("led turned off")
            ledStateSwitch.isOn = false
        }
        
        ledStateSwitch.isEnabled = true
    }
    
    
    // MARK: CBCentralManagerDelegate
    
    /**
    centralManager is called each time a new Peripheral is discovered
 
    - parameters
        - central: the CentralManager for this UIView
        - peripheral: A discovered Peripheral
        - advertisementData: The Bluetooth advertisement data discevered with the Peripheral
        - rssi: the radio signal strength indicator for this Peripheral
    */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("Discovered \(peripheral.name)")
        print("Discovered \(peripheral.identifier.uuidString) (\(peripheral.name))")
        
        remoteLed = RemoteLed(delegate: self, peripheral: peripheral)
        
        
        // find the advertised name
        if let advertisedName = RemoteLed.getNameFromAdvertisementData(advertisementData: advertisementData) {
            if advertisedName == RemoteLed.advertisedName {
                print("connecting to peripheral...")
                centralManager.connect(peripheral, options: nil)
            }
        }
        
    }
    
    /**
     Peripheral connected.
     
     - Parameters:
        - central: the reference to the central
        - peripheral: the connected Peripheral
     */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected Peripheral: \(peripheral.name)")
        
        remoteLed.connected(peripheral: peripheral)
        
        // Do any additional setup after loading the view.
        identifierLabel.text = remoteLed.peripheral.identifier.uuidString
    }

    /**
     Peripheral disconnected
     
     - Parameters:
     - central: the reference to the central
     - peripheral: the connected Peripheral
     */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // disconnected.  Leave
        print("disconnected")
    }
    
    /**
     Bluetooth radio state changed
     
     - Parameters:
     - central: the reference to the central
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Manager updated: checking state")
        
        switch (central.state) {
        case .poweredOn:
            print("bluetooth on")
            centralManager.scanForPeripherals(withServices: [RemoteLed.serviceUuid], options: nil)
        default:
            print("bluetooth unavailable")
        }
    }
    

}
