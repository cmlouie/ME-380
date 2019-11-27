//
//  StartViewController.swift
//  Stewart Platform Controller
//
//  Created by Christopher Louie on 2019-10-01.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import UIKit
import CoreBluetooth

class StartViewController: UIViewController, BluetoothSerialDelegate {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var bluetoothStatusLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    // MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize serial
        serial = BluetoothSerial(delegate: self)
        
        bluetoothStatusLabel.text = "SEARCHING FOR STEWART PLATFORM..."
        
        // Setup UI
        view.backgroundColor = .black
        playButton.setImage(UIImage(named: "PlayOff"), for: .normal)
        playButton.isEnabled = false
    }
    
    // MARK: BluetoothSerialDelegate
    
    func serialDidChangeState() {
        if serial.isPoweredOn {
            serial.startScan()
            bluetoothStatusLabel.text = "SEARCHING FOR STEWART PLATFORM..."
        } else {
            bluetoothStatusLabel.text = "TURN ON BLUETOOTH TO CONNECT."
        }
    }
    
    func serialDidDiscoverPeripheral(_ peripheral: CBPeripheral, RSSI: NSNumber?) {
        serial.stopScan()
        serial.connectToPeripheral(peripheral)
        print("Connected to \(peripheral)")
    }
    
    func serialDidConnect(_ peripheral: CBPeripheral) {
        bluetoothStatusLabel.text = "CONNECTED TO GROUP 22 STEWART PLATFORM."
        playButton.setImage(UIImage(named: "PlayOn"), for: .normal)
        playButton.isEnabled = true
    }
    
    func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
        serial.startScan()
        playButton.setImage(UIImage(named: "PlayOff"), for: .normal)
        playButton.isEnabled = false
        bluetoothStatusLabel.text = "SEARCHING FOR STEWART PLATFORM..."
        print("The \(peripheral) peripheral disconnected")
    }
    
    func serialIsReady(_ peripheral: CBPeripheral) {
        print("Serial is ready!")
    }
}
