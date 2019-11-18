//
//  BluetoothSerial.swift
//  Stewart Platform Controller
//
//  Created by Christopher Louie on 2019-11-17.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import UIKit
import CoreBluetooth

var serial: BluetoothSerial!

protocol BluetoothSerialDelegate: class {
    // ** Required **
    
    /// Called when the state of the CBCentralManager changes (e.g. when bluetooth is turned on/off)
    func serialDidChangeState()
    
    /// Called when the peripheral is disconnected
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?)
    
    // ** Optional **
    
    /// Called when a string is received
    func serialDidReceiveString(_ string: String)
    
    /// Called when bytes are received
    func serialDidReceiveBytes(_ bytes: [UInt8])
    
    /// Called when data is received
    func serialDidReceiveData(_ data: Data)
    
    /// Called when the received signal strength indication (RSSI) of the connected peripheral is read
    func serialDidReadRSSI(_ rssi: NSNumber)
    
    /// Called when a new peripheral is discovered while scanning, and also gives the RSSI
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?)
    
    /// Called when a peripheral is connected (but not yet ready for communication)
    func serialDidConnect(_ peripheral: CBPeripheral)
    
    /// Called when a pending connection failed
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?)
    
    /// Called when a peripheral is ready for communication
    func serialIsReady(_ peripheral: CBPeripheral)
}

// Make some of the delegate functions optional
extension BluetoothSerialDelegate {
    func serialDidReceiveString(_ string: String) {}
    func serialDidReceiveBytes(_ bytes: [UInt8]) {}
    func serialDidReceiveData(_ data: Data) {}
    func serialDidReadRSSI(_ rssi: NSNumber) {}
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {}
    func serialDidConnect(_ peripheral: CBPeripheral) {}
    func serialDidFailToConnect(_ peripheral: CBPeripheral, error: NSError?) {}
    func serialIsReady(_ peripheral: CBPeripheral) {}
}


final class BluetoothSerial: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: Variables
    
    /// The delegate object the BluetoothDelegate methods will be called upon
    weak var delegate: BluetoothSerialDelegate?
    
    /// The CBCentralManager this bluetooth serial handler uses
    var centralManager: CBCentralManager!
    
    /// The peripheral we're trying to connect to (nil if none)
    var pendingPeripheral: CBPeripheral?
    
    /// The connected peripheral (nil if none is connected)
    var connectedPeripheral: CBPeripheral?
    
    /// The characteristic 0xFFE1 we need to write to, of the connectedPeripheral
    weak var writeCharacteristic: CBCharacteristic?
    
    /// Whether this serial is ready to send and receive data
    var isReady: Bool {
        get {
            return centralManager.state == .poweredOn &&
                   connectedPeripheral != nil &&
                   writeCharacteristic != nil
        }
    }
    
    /// Whether this serial is looking for advertising peripherals
    var isScanning: Bool {
        return centralManager.isScanning
    }
    
    /// Whether the state of the centralManager is .poweredOn
    var isPoweredOn: Bool {
        return centralManager.state == .poweredOn
    }
    
    /// UUID of the service to look for
    var serviceUUID = CBUUID(string: "FFE0")
    
    /// UUID of the characteristic to look for
    var characteristicUUID = CBUUID(string: "FFE1")
    
    /// Whether to write to the HM10 with or without response
    private var writeType: CBCharacteristicWriteType = .withoutResponse
    
    
    // MARK: Functions
    
    /// Always use this to initialize an instance
    init(delegate: BluetoothSerialDelegate) {
        super.init()
        self.delegate = delegate
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// Start scanning for peripherals
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        
        // Start scanning for peripherals with correct service UUID
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        
        // Retrieve peripherals that are already connected
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        for peripheral in peripherals {
            delegate?.serialDidDiscoverPeripheral(peripheral, RSSI: nil)
        }
    }
    
    /// Stop scanning for peripherals
    func stopScan() {
        centralManager.stopScan()
    }
    
    /// Try to connect to the given peripheral
    func connectToPeripheral(_ peripheral: CBPeripheral) {
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    /// Disconnect from the connected peripheral or stop connecting to it
    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        } else if let peripheral = pendingPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    /// Read the RSSI of the connected peripheral
    /// The didReadRSSI delegate function will be called after calling this function
    func readRSSI() {
        guard isReady else { return }
        connectedPeripheral!.readRSSI()
    }
    
    /// Send a string to the BLE device
    func sendStringToDevice(_ string: String) {
        guard isReady else { return }
        
        if let data = string.data(using: .utf8) {
            connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
        }
    }
    
    /// Send an array of bytes to the BLE device
    func sendBytesToDevice(_ bytes: [UInt8]) {
        guard isReady else { return }
        
        let data = Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
        connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
    
    /// Send data to the BLE device
    func sendDataToDevice(_ data: Data) {
        guard isReady else { return }
        
        connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
    
    
    // MARK: CBCentralManagerDelegate Functions
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Send it to the delegate
        delegate?.serialDidDiscoverPeripheral(peripheral, RSSI: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        
        // Send it to the delegate
        delegate?.serialDidConnect(peripheral)
        
        // Okay, the peripheral is connected but we're not ready yet!
        // First get the 0xFFE0 service
        // Then get the 0xFFE1 characteristic of this service
        // Subscribe to it & create a weak reference to it (for writing later on),
        // and find out the writeType by looking at characteristic.properties.
        // Only then we're ready for communication
        
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        pendingPeripheral = nil
        
        // Send it to the delegate
        delegate?.serialDidFailToConnect(peripheral, error: error as NSError?)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        pendingPeripheral = nil
        connectedPeripheral = nil
        
        // Send it to the delegate
        delegate?.serialDidDisconnect(peripheral, error: error as NSError?)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Note that didDisconnectPeripheral won't be called if the BLE device is turned off while connected
        pendingPeripheral = nil
        connectedPeripheral = nil
        
        // Send it to the delegate
        delegate?.serialDidChangeState()
    }
    
    
    // MARK: CBPeripheralDelegate Functions
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        // Discover the 0xFFE1 characteristic for all services (though there should only be one)
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Check whether the characteristic we're looking for (0xFFE1) is present - just to be sure
        for characteristic in service.characteristics! {
            if characteristic.uuid == characteristicUUID {
                // Subscribe to this value (so we'll get notified when there is serial data being sent to us)
                peripheral.setNotifyValue(true, for: characteristic)
                
                // Keep a reference to this characteristic so we can write to it
                writeCharacteristic = characteristic
                
                // Find out the writeType
                writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                
                // Notify the delegate we're ready for communication
                delegate?.serialIsReady(peripheral)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Notify the delegate in different ways (uncomment the methods not used)
        let data = characteristic.value
        guard data != nil else { return }
        
        // Method 1: Data
        delegate?.serialDidReceiveData(data!)
        
        // Method 2: String
        if let str = String(data: data!, encoding: String.Encoding.utf8) {
            delegate?.serialDidReceiveString(str)
        } else {
            //print("Received an invalid string!")
        }
        
        // Method 3: Bytes array
        var bytes = [UInt8](repeating: 0, count: data!.count / MemoryLayout<UInt8>.size)
        (data! as NSData).getBytes(&bytes, length: data!.count)
        delegate?.serialDidReceiveBytes(bytes)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        delegate?.serialDidReadRSSI(RSSI)
    }
}

