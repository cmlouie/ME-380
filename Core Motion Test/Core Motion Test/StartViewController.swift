//
//  StartViewController.swift
//  Core Motion Test
//
//  Created by Christopher Louie on 2019-10-01.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import UIKit
import CoreBluetooth

var arduinoPeripheral: CBPeripheral?
var txCharacteristic: CBCharacteristic?

class StartViewController: UIViewController {
    
    @IBOutlet weak var bluetoothStatusLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    private let hm10ServiceCBUUID = CBUUID(string: "FFE0")
    private let hm10ServiceCBUUIDRx = CBUUID(string: "FFE1")
    private let hm10ServiceCBUUIDTx = CBUUID(string: "FFE1")
    
    var centralManager: CBCentralManager!
    var rxCharacteristic: CBCharacteristic!
    var characteristicASCIIValue = NSString()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bluetoothStatusLabel.text = "Searching for bluetooth device..."
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        startButton.setBackgroundColor(color: .systemGreen, forState: .normal)
        startButton.setBackgroundColor(color: .systemGray, forState: .disabled)
        startButton.setTitle("Start", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 30
        startButton.isEnabled = false
    }
    
    
}

extension StartViewController: CBCentralManagerDelegate {
    
    func scanForBLEDevice() {
        // Look for our specific bluetooth device
        centralManager.scanForPeripherals(withServices: [hm10ServiceCBUUID], options: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            bluetoothStatusLabel.text = "Searching for bluetooth device..."
            
            scanForBLEDevice()
        }
        else {
            bluetoothStatusLabel.text = "Turn on bluetooth to connect to devices."
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Save the bluetooth peripheral as the arduinoPeripheral object
        arduinoPeripheral = peripheral
        arduinoPeripheral!.delegate = self
        
        // Stop scanning once discovered
        centralManager.stopScan()
        print("Scan stopped")
        
        // Connect to our bluetooth device
        centralManager.connect(arduinoPeripheral!)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "HM-10")) peripheral!")
        bluetoothStatusLabel.text = "Connected to Stewart Platform."
        arduinoPeripheral!.discoverServices(nil)
        startButton.isEnabled = true
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "HM-10") peripheral.")
        bluetoothStatusLabel.text = "Searching for bluetooth device..."
        startButton.isEnabled = false
        scanForBLEDevice()
    }
    
}

extension StartViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("Error discovering peripheral's services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        print("Discovered services: \(services)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("Error discovering peripheral's characteristics: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            if characteristic.uuid.isEqual(hm10ServiceCBUUIDRx) {
                rxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                peripheral.readValue(for: characteristic)
                print("Rx characteristic: \(characteristic.uuid)")
            }
            
            if characteristic.uuid.isEqual(hm10ServiceCBUUIDTx) {
                txCharacteristic = characteristic
                print("Tx characteristic: \(characteristic.uuid)")
            }
            
            print("Characteristic: \(characteristic)")
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        peripheral.discoverDescriptors(for: characteristic)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            if characteristic == rxCharacteristic {
                if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
                    characteristicASCIIValue = ASCIIstring
                    print(ASCIIstring)
                }
            }
        }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(String(describing: error))")
            return
        }
        print("Message was sent to Arduino!")
    }
    
}

extension UIButton {
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        self.clipsToBounds = true  // add this to maintain corner radius
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            let colorImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.setBackgroundImage(colorImage, for: forState)
        }
    }
}
