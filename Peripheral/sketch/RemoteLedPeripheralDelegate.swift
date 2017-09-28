import UIKit
import CoreBluetooth

@objc protocol RemoteLedPeripheralDelegate : class {
    
    /**
     RemoteLed State Changed
     
     - Parameters:
     - rssi: the RSSI
     - blePeripheral: the BlePeripheral
     */
    @objc optional func remoteLedPeripheral(
        stateChanged state: CBManagerState)
    
    /**
     RemoteLed statrted advertising
     
     - Parameters:
     - error: the error message, if any
     */
    @objc optional func remoteLedPeripheral(
        startedAdvertising error: Error?)
    
    
    /**
     LED turned on or off
     
     - Parameters:
     - ledState: *true* for on, *false* for off
     */
    @objc optional func remoteLedPeripheral(
        ledStateChangedTo ledState: Bool)
}
