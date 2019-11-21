//
//  StartViewController.swift
//  Stewart Platform Controller
//
//  Created by Christopher Louie on 2019-10-01.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import UIKit
import CoreBluetooth

var arduinoPeripheral: CBPeripheral?
var txCharacteristic: CBCharacteristic?

class StartViewController: UIViewController, BluetoothSerialDelegate {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var bluetoothStatusLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    // MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize serial
        serial = BluetoothSerial(delegate: self)
        
        bluetoothStatusLabel.text = "Searching for bluetooth device..."
        
        // Setup UI
        startButton.setBackgroundColor(color: .systemGreen, forState: .normal)
        startButton.setBackgroundColor(color: .systemGray, forState: .disabled)
        startButton.setTitle("Start", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 30
        startButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    } 
    
    // MARK: BluetoothSerialDelegate
    
    func serialDidChangeState() {
        if serial.isPoweredOn {
            serial.startScan()
            bluetoothStatusLabel.text = "Searching for bluetooth device..."
        } else {
            bluetoothStatusLabel.text = "Turn on bluetooth to connect to devices."
        }
    }
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        serial.stopScan()
        serial.connectToPeripheral(peripheral)
        print("Connected to \(peripheral)")
    }
    
    func serialDidConnect(_ peripheral: CBPeripheral) {
        bluetoothStatusLabel.text = "Connected to Stewart Platform."
        startButton.isEnabled = true
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        serial.startScan()
        startButton.isEnabled = false
        bluetoothStatusLabel.text = "Searching for bluetooth device..."
        print("The \(peripheral) peripheral disconnected")
    }
    
    func serialIsReady(_ peripheral: CBPeripheral) {
        print("Serial is ready!")
    }
}
