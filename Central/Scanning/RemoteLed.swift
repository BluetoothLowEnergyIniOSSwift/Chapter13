//
//  EchoServer.swift
//  RemoteLed
//
//  Created by Adonis Gaitatzis on 11/26/16.
//  Copyright © 2016 Adonis Gaitatzis. All rights reserved.
//

import UIKit
import CoreBluetooth

/**
 RemoteLed turns an LED on and off over Bluetooth
 */
class RemoteLed:NSObject, CBPeripheralDelegate {
    
    // MARK: Peripheral properties
    
    // The Broadcast name of the Perihperal
    static let advertisedName = "LedRemote"
    
    // the Service UUID
    static let serviceUuid = CBUUID(string: "1815")
    
    // The Characteristic UUID used to write commands to the Peripheral
    static let commandCharacteristicUuid = CBUUID(string: "2A56")
    
    // The Characteristic UUID used to write commands to the Peripheral
    static let responseCharacteristicUuid = CBUUID(string: "2A57")
    
    // the size of the characteristic
    let characteristicLength = 2
    
    
    // MARK: Command Data Format
    
    
    // Footer data position
    let bleCommandFooterPosition:Int = 1
    
    // Message data position
    let bleCommandDataPosition:Int = 0
    
    // Command
    let bleCommandFooter:UInt8 = 1
    
    // Turn the LED on
    let bleCommandLedOn:UInt8 = 1
    
    // Turn the LED off
    let bleCommandLedOff:UInt8 = 2
    
    
    // MARK: Response Data Format
    
    // Footer data position
    let bleResponseFooterPosition:Int = 1
    
    // Message data position
    let bleResponseDataPosition:Int = 0
    
    // Error response
    let bleResponseErrorFooter = 0
    
    // Confirmation response
    let bleResponseConfirmationFooter:UInt8 = 1
    
    // Error Response
    static let bleResponseLedError:UInt8 = 0
    
    // Confirmation response
    static let bleResponseLedOn:UInt8 = 1
    
    // Command
    static let bleResponseLedOff:UInt8 = 2
    
    
    
    // MARK: connected device
    
    // RemateLedDelegate
    var delegate:RemoteLedDelegate!

    // connected Peripheral
    var peripheral:CBPeripheral!
    
    // connected Characteristic
    var commandCharacteristic:CBCharacteristic!
    var responseCharacteristic:CBCharacteristic!
    
    
    /**
     Initialize EchoServer with a corresponding Peripheral
     
     - Parameters:
        - delegate: The RemoteLEDPeripheral
        - peripheral: The discovered Peripheral
     */
    init(delegate: RemoteLedDelegate, peripheral: CBPeripheral) {
        super.init()
        self.delegate = delegate
        self.peripheral = peripheral
        self.peripheral.delegate = self
        
    }
    
    
    /**
     Notify the RemoteLed that the peripheral has been connected
     */
    func connected(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.peripheral.discoverServices([RemoteLed.serviceUuid])
    }
    
    
    /**
     Get a advertised name from an advertisementData packet.  This may be different than the actual Peripheral name
     */
    static func getNameFromAdvertisementData(advertisementData: [String : Any]) -> String? {
        // grab thekCBAdvDataLocalName from the advertisementData to see if there's an alternate broadcast name
        if advertisementData["kCBAdvDataLocalName"] != nil {
            return (advertisementData["kCBAdvDataLocalName"] as! String)
        }
        return nil
    }

    
    /**
    Turn the remote LED on
    */
    func turnLedOn() {
        writeCommand(ledCommandState: bleCommandLedOn)
    }
    
    /**
    Turn the remote LED off
    */
    func turnLedOff() {
        writeCommand(ledCommandState: bleCommandLedOff)
    }
    
    /**
     Write a command to the remote
     */
    func writeCommand(ledCommandState: UInt8) {
        if peripheral != nil {
            var command = [UInt8](repeating: 0, count: characteristicLength)
            command[bleCommandDataPosition] = ledCommandState
            command[bleCommandFooterPosition] = bleCommandFooter
            
            let value = Data(command)
            
            print("writing value: \(value)")
            
            var writeType = CBCharacteristicWriteType.withResponse
            if RemoteLed.isCharacteristic(isWriteableWithoutResponse: commandCharacteristic) {
                writeType = CBCharacteristicWriteType.withoutResponse
            }
            peripheral.writeValue(value, for: commandCharacteristic, type: writeType)
        }
        
    }
    
    
    
    
    /**
     Check if Characteristic is readable
     
     - Parameters: 
        - characteristic: The Characteristic to test
     
     - returns: True if characteristic is readable
     */
    static func isCharacteristic(isReadable characteristic: CBCharacteristic) -> Bool {
        if (characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            print("readable")
            return true
        }
        return false
    }
    
    
    /**
     Check if Characteristic is writeable
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is writeable
     */
    static func isCharacteristic(isWriteable characteristic: CBCharacteristic) -> Bool {
        print("testing if characteristic is writeable")
        if (characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0 ||
            (characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 {
            print("characteristic is writeable")
            return true
        }
        print("characetiristic is not writeable")
        return false
    }
    
    
    /**
     Check if Characteristic is writeable with response
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is writeable with response
     */
    static func isCharacteristic(isWriteableWithResponse characteristic: CBCharacteristic) -> Bool {
        if (characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0 {
            return true
        }
        return false
    }
    
    
    /**
     Check if Characteristic is writeable without response
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is writeable without response
     */
    static func isCharacteristic(isWriteableWithoutResponse characteristic: CBCharacteristic) -> Bool {
        if (characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 {
            return true
        }
        return false
    }
    
    
    /**
     Check if Characteristic is notifiable
     
     - Parameters:
     - characteristic: The Characteristic to test
     
     - returns: True if characteristic is notifiable
     */
    static func isCharacteristic(isNotifiable characteristic: CBCharacteristic) -> Bool {
        if (characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0 {
            return true
        }
        return false
    }
    
    
    
    // MARK: CBPeripheralDelegate
    
    /**
     Characteristic has been subscribed to or unsubscribed from
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Notification state updated for: \(characteristic.uuid.uuidString)")
        print("New state: \(characteristic.isNotifying)")
        
        
        if let errorMessage = error {
            print("error subscribing to notification: ")
            print(errorMessage.localizedDescription as String)
        }
    }
    
    
    /**
     Value downloaded from Characteristic on connected Peripheral
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            print(value.debugDescription)
            print(value.description as String)
            
            let responseValue = [UInt8](value)
            
            
            // decode message
            let responseType = responseValue[bleResponseFooterPosition]
            switch responseType {
            case bleResponseConfirmationFooter:
                print("ble device responded")
                let response = responseValue[bleResponseDataPosition]
                
                delegate.remoteLed(confirmationReceived: response)
                
            default:
                print("ble response unknown")
            }
            
        }
        
    }
    
    /**
     Servicess were discovered on the connected Peripheral
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("services discovered")
        
        if error != nil {
            print("Discover service Error: \(error)")
        } else {
            print("Discovered Service")
            for service in peripheral.services!{
                if service.uuid == RemoteLed.serviceUuid {
                    self.peripheral.discoverCharacteristics([RemoteLed.commandCharacteristicUuid, RemoteLed.responseCharacteristicUuid], for: service)
                }
            }
            print(peripheral.services!)
            print("DONE")
        }
        
    }
    
    
    /**
     Characteristics were discovered for a Service on the connected Peripheral
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("characteristics discovered")
        
        // grab the service
        let serviceIdentifier = service.uuid.uuidString
        
        print("service: \(serviceIdentifier)")
        
        if let characteristics = service.characteristics {
            print("characteristics found: \(characteristics.count)")
            
            for characteristic in characteristics {
                if characteristic.uuid == RemoteLed.commandCharacteristicUuid {
                    commandCharacteristic = characteristic
                    
                } else if characteristic.uuid == RemoteLed.responseCharacteristicUuid {
                    responseCharacteristic = characteristic
                    
                    
                    print(" -> \(characteristic.uuid.uuidString): \(characteristic.properties.rawValue)")
                    
                    if RemoteLed.isCharacteristic(isNotifiable: responseCharacteristic) {
                        self.peripheral.setNotifyValue(true, for: responseCharacteristic)
                    }
                    
                    
                }
                
            }
            
            delegate.remoteLed(connectedToCharacteristics: [responseCharacteristic, commandCharacteristic])
            
            
        }
        
    }
    
    

    
    
    
}
