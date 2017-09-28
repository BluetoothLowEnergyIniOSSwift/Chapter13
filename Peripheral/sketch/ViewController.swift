import UIKit
import CoreBluetooth
import AVFoundation

class ViewController: UIViewController, RemoteLedPeripheralDelegate {
    
    // MARK: UI Elements
    @IBOutlet weak var advertisingLabel: UILabel!
    @IBOutlet weak var advertisingSwitch: UISwitch!
    @IBOutlet weak var ledStateSwitch: UISwitch!
    
    // MARK: BlePeripheral
    
    // BlePeripheral
    var remoteLed:RemoteLedPeripheral!
    
    /**
     UIView loaded
     */
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /**
     View appeared.  Start the Peripheral
     */
    override func viewDidAppear(_ animated: Bool) {
        remoteLed = RemoteLedPeripheral(delegate: self)
        advertisingLabel.text = remoteLed.advertisingName
    }
    
    /**
     View will appear.  Stop transmitting random data
     */
    override func viewWillDisappear(_ animated: Bool) {
        remoteLed.stop()
    }
    
    /**
     View disappeared.  Stop advertising
     */
    override func viewDidDisappear(_ animated: Bool) {
        advertisingSwitch.setOn(false, animated: true)
    }
    
    // MARK: BlePeripheralDelegate
    
    /**
     RemoteLed state changed
     
     - Parameters:
     - state: the CBManagerState representing the new state
     */
    func remoteLedPeripheral(stateChanged state: CBManagerState) {
        switch (state) {
        case CBManagerState.poweredOn:
            print("Bluetooth on")
        case CBManagerState.poweredOff:
            print("Bluetooth off")
        default:
            print("Bluetooth not ready yet...")
        }
    }
    
    /**
     RemoteLed statrted adertising
     
     - Parameters:
     - error: the error message, if any
     */
    func remoteLedPeripheral(startedAdvertising error: Error?) {
        if error != nil {
            print("Problem starting advertising: " + error.debugDescription)
        } else {
            print("adertising started")
            advertisingSwitch.setOn(true, animated: true)
        }
    }
    
    /**
     Led State Changed
     
     - Parameters:
     - stringValue: the value read from the Charactersitic
     - characteristic: the Characteristic that was written to
     */
    func remoteLedPeripheral(ledStateChangedTo ledState: Bool) {
        if let device = AVCaptureDevice.defaultDevice(
            withMediaType: AVMediaTypeVideo)
        {
            if (device.hasTorch) {
                do {
                    try device.lockForConfiguration()
                    try device.setTorchModeOnWithLevel(1.0)
                    if ledState {
                        print("Led turned on")
                        device.torchMode = AVCaptureTorchMode.on
                        ledStateSwitch.setOn(true, animated: true)
                    } else {
                        print("Led turned off")
                        device.torchMode = AVCaptureTorchMode.off
                        ledStateSwitch.setOn(false, animated: true)
                    }
                    device.unlockForConfiguration()
                } catch let error as NSError {
                    print("problem locking camera: "+error.debugDescription)
                }
            }
        }
    }
}
