import UIKit
import CoreBluetooth

class RemoteLedPeripheral : NSObject, CBPeripheralManagerDelegate {
    
    // MARK: Peripheral properties
    
    // Advertized name
    let advertisingName = "LedRemote"
    // Device identifier
    let peripheralIdentifier = "8f68d89b-448c-4b14-aa9a-f8de6d8a4753"
    
    // MARK: GATT Profile
    
    // Service UUID
    let serviceUuid = CBUUID(string: "00001815-0000-1000-8000-00805f9b34fb")
    // Characteristic UUIDs
    let commandCharacteristicUuid =
        CBUUID(string: "00002a56-0000-1000-8000-00805f9b34fb")
    let responseCharacteristicUuid =
        CBUUID(string: "00002a57-0000-1000-8000-00805f9b34fb")
    // Command Characteristic
    var commandCharacteristic:CBMutableCharacteristic!
    // Response Characteristic
    var responseCharacteristic:CBMutableCharacteristic!
    // the size of a Characteristic
    let commandCharacteristicLength = 2
    let responseCharacteristicLength = 2
    
    // MARK: Commands
    
    // Data Positions
    let bleCommandFooterPosition = 1;
    let bleCommandDataPosition = 0;
    // Command flag
    let bleCommandFooter:UInt8 = 1;
    // LED State
    let bleCommandLedOn:UInt8 = 1;
    let bleCommandLedOff:UInt8 = 2;
    
    // MARK: Response
    
    // Data Positions
    let bleResponseFooterPosition = 1;
    let bleResponseDataPosition = 0;
    // Response Types
    let bleResponseErrorFooter:UInt8 = 0;
    let bleResponseConfirmationFooter:UInt8 = 1;
    // LED States
    let bleResponseLedError:UInt8 = 0;
    let bleResponseLedOn:UInt8 = 1;
    let bleResponseLedOff:UInt8 = 2
    
    // MARK: Peripheral State
    
    // Peripheral Manager
    var peripheralManager:CBPeripheralManager!
    // Connected Central
    var central:CBCentral!
    // delegate
    var delegate:RemoteLedPeripheralDelegate!
    
    /**
     Initialize BlePeripheral with a corresponding Peripheral
     
     - Parameters:
     - delegate: The BlePeripheralDelegate
     - peripheral: The discovered Peripheral
     */
    init(delegate: RemoteLedPeripheralDelegate?) {
        super.init()
        // empty dispatch queue
        let dispatchQueue:DispatchQueue! = nil
        // Build Advertising options
        let options:[String : Any] = [
            CBPeripheralManagerOptionShowPowerAlertKey: true,
            // Peripheral unique identifier
            CBPeripheralManagerOptionRestoreIdentifierKey:
            peripheralIdentifier
        ]
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: dispatchQueue,
            options: options)
        self.delegate = delegate
    }
    
    /**
     Stop advertising, shut down the Peripheral
     */
    func stop() {
        peripheralManager.stopAdvertising()
    }
    
    /**
     Start Bluetooth Advertising.
     This must be after building the GATT profile
     */
    func startAdvertising() {
        let serviceUuids = [serviceUuid]
        let advertisementData:[String: Any] = [
            CBAdvertisementDataLocalNameKey: advertisingName,
            CBAdvertisementDataServiceUUIDsKey: serviceUuids
        ]
        peripheralManager.startAdvertising(advertisementData)
    }
    
    /**
     Build Gatt Profile.
     This must be done after Bluetooth Radio has turned on
     */
    func buildGattProfile() {
        let service = CBMutableService(type: serviceUuid, primary: true)
        var rProperties = CBCharacteristicProperties.read
        rProperties.formUnion(CBCharacteristicProperties.notify)
        var rPermissions = CBAttributePermissions.writeable
        rPermissions.formUnion(CBAttributePermissions.readable)
        responseCharacteristic = CBMutableCharacteristic(
            type: responseCharacteristicUuid,
            properties: rProperties,
            value: nil,
            permissions: rPermissions)
        let cProperties = CBCharacteristicProperties.write
        let cPermissions = CBAttributePermissions.writeable
        commandCharacteristic = CBMutableCharacteristic(
            type: commandCharacteristicUuid,
            properties: cProperties,
            value: nil,
            permissions: cPermissions)
        service.characteristics = [
            responseCharacteristic,
            commandCharacteristic
        ]
        peripheralManager.add(service)
    }
    
    /**
     Make sense of the incoming byte array as a command
     */
    func processCommand(bleCommandValue: [UInt8]) {
        if bleCommandValue[bleCommandFooterPosition] == bleCommandFooter {
            print ("Command found")
            switch (bleCommandValue[bleCommandDataPosition]) {
            case bleCommandLedOn:
                print("Turning LED on")
                setLedState(ledState: true)
            case bleCommandLedOff:
                print("Turning LED off")
                setLedState(ledState: false)
            default:
                print("Unknown command value")
            }
        }
    }
    
    /**
     Turn Camera Flash on as an LED
     
     - Parameters:
     - ledState: *true* for on, *false* for off
     */
    func setLedState(ledState: Bool) {
        if ledState {
            sendBleResponse(ledState: bleResponseLedOn)
        } else {
            sendBleResponse(ledState: bleResponseLedOff)
        }
        delegate?.remoteLedPeripheral?(ledStateChangedTo: ledState)
    }
    
    
    /**
     Send a formatted response out via a Bluetooth Characteristic
     
     - Parameters
     - ledState: one of bleResponseLedOn or bleResponseLedOff
     */
    func sendBleResponse(ledState: UInt8) {
        var responseArray = [UInt8](
            repeating: 0,
            count: responseCharacteristicLength)
        responseArray[bleResponseFooterPosition] =
            bleResponseConfirmationFooter
        responseArray[bleResponseDataPosition] = ledState
        let value = Data(bytes: responseArray)
        responseCharacteristic.value = value
        peripheralManager.updateValue(
            value,
            for: responseCharacteristic,
            onSubscribedCentrals: nil)
    }
    
    // MARK: CBPeripheralManagerDelegate
    
    /**
     Peripheral will become active
     */
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        willRestoreState dict: [String : Any])
    {
        print("restoring peripheral state")
    }
    
    /**
     Peripheral added a new Service
     */
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didAdd service: CBService,
        error: Error?)
    {
        print("added service to peripheral")
        if error != nil {
            print(error.debugDescription)
        }
    }
    
    /**
     Peripheral started advertising
     */
    func peripheralManagerDidStartAdvertising(
        _ peripheral: CBPeripheralManager,
        error: Error?)
    {
        if error != nil {
            print ("Error advertising peripheral")
            print(error.debugDescription)
        }
        self.peripheralManager = peripheral
        
        delegate?.remoteLedPeripheral?(startedAdvertising: error)
    }
    
    /**
     Connected Central requested to read from a Characteristic
     */
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveRead request: CBATTRequest)
    {
        let characteristic = request.characteristic
        if (characteristic.uuid == responseCharacteristic.uuid) {
            if let value = characteristic.value {
                //let stringValue = String(data: value, encoding: .utf8)!
                if request.offset > value.count {
                    peripheralManager.respond(
                        to: request,
                        withResult: CBATTError.invalidOffset)
                    return
                }
                let range = Range(uncheckedBounds: (
                    lower: request.offset,
                    upper: value.count - request.offset))
                request.value = value.subdata(in: range)
                peripheral.respond(
                    to: request,
                    withResult: CBATTError.success)
            }
        }
    }
    
    /**
     Connected Central requested to write to a Characteristic
     */
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest])
    {
        for request in requests {
            peripheral.respond(to: request, withResult: CBATTError.success)
            print("new request")
            if let value = request.value {
                let bleCommandValue = [UInt8](value)
                processCommand(bleCommandValue: bleCommandValue)
            }
        }
    }
    
    /**
     Connected Central subscribed to a Characteristic
     */
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic)
    {
        self.central = central
    }
    
    /**
     Connected Central unsubscribed from a Characteristic
     */
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic)
    {
        self.central = central
    }
    
    /**
     Peripheral is about to notify subscribers of changes to a Characteristic
     */
    func peripheralManagerIsReady(
        toUpdateSubscribers peripheral: CBPeripheralManager)
    {
        print("Peripheral about to update subscribers")
    }
    
    /**
     Bluetooth Radio state changed
     */
    func peripheralManagerDidUpdateState(
        _ peripheral: CBPeripheralManager)
    {
        peripheralManager = peripheral
        switch peripheral.state {
        case CBManagerState.poweredOn:
            buildGattProfile()
            startAdvertising()
        default: break
        }
        delegate?.remoteLedPeripheral?(stateChanged: peripheral.state)
        
    }
}
