//
//  ViewController.swift
//  Stewart Platform Controller
//
//  Created by Christopher Louie on 2019-09-30.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import UIKit
import CoreMotion
import CoreBluetooth

class ViewController: UIViewController, BluetoothSerialDelegate {
     
     // MARK: IBOutlets
     
     @IBOutlet weak var backButton: UIButton!
     @IBOutlet weak var pitchLabel: UILabel!
     @IBOutlet weak var rollLabel: UILabel!
     @IBOutlet weak var controlTypeButton: UIButton!
     @IBOutlet weak var chillButton: UIButton!
     @IBOutlet weak var normalButton: UIButton!
     @IBOutlet weak var sportButton: UIButton!
     @IBOutlet weak var boundaryRing: UIImageView!
     @IBOutlet weak var tiltCircle: UIImageView!
     @IBOutlet weak var crosshair: UIImageView!
     
     // MARK: Constants
     
     let motionManager = CMMotionManager()
     let stewart = Stewart()
     
     let slowSensitivityFactor = 0.3
     let normalSensitivityFactor = 1.0
     let fastSensitivityFactor = 2.0
     
     let sensorUpdateFrequency: TimeInterval = 1.0 / 100 // Seconds
     let bluetoothSendFrequency: TimeInterval = 1.0 / 40.0 // Seconds
     
     let maxTiltRadius: Double = 15.0
     
     // MARK: Variables
     
     var bluetoothTimer: Timer?
     
     var currentSensitivityFactor = 1.0
     
     var platformXAngle: Double = 0
     var platformYAngle: Double = 0
     var phoneXAngle: Double = 0
     var phoneYAngle: Double = 0
     
     var centred = false
     var hitBorder = false
     
     var screenWidth: CGFloat!
     var screenHeight: CGFloat!
     
     // Haptic feedback
     let centredGenerator = UIImpactFeedbackGenerator(style: .medium)
     
     // MARK: Functions
     
     override func viewDidLoad() {
          super.viewDidLoad()
          
          serial.delegate = self
          
          startTimer()
          
          view.backgroundColor = .black
          screenWidth = self.view.frame.size.width
          screenHeight = self.view.frame.size.height
          
          readMotionData()
     }
     
     override func viewWillDisappear(_ animated: Bool) {
          super.viewWillDisappear(animated)
          
          stopTimer()
     }
     
     func startTimer() {
          if bluetoothTimer == nil {
              bluetoothTimer = Timer.scheduledTimer(timeInterval: bluetoothSendFrequency, target: self, selector: #selector(sendAnglesToArduino), userInfo: nil, repeats: true)
          }
     }
     
     func stopTimer() {
          if bluetoothTimer != nil {
               bluetoothTimer?.invalidate()
               bluetoothTimer = nil
          }
     }
     
     @IBAction func backButtonPressed(_ sender: UIButton) {
          returnToHome()
     }
     
     @IBAction func controlTypeButtonPressed(_ sender: UIButton) {
     }
     
     @IBAction func chillButtonPressed(_ sender: UIButton) {
          print("Slow")
          chillButton.setImage(UIImage(named: "ChillOn"), for: .normal)
          normalButton.setImage(UIImage(named: "NormalOff"), for: .normal)
          sportButton.setImage(UIImage(named: "SportOff"), for: .normal)
          boundaryRing.image = UIImage(named: "ChillCircle")
          crosshair.image = UIImage(named: "ChillCross")
          currentSensitivityFactor = slowSensitivityFactor
     }
     
     @IBAction func normalButtonPressed(_ sender: UIButton) {
          print("Normal")
          chillButton.setImage(UIImage(named: "ChillOff"), for: .normal)
          normalButton.setImage(UIImage(named: "NormalOn"), for: .normal)
          sportButton.setImage(UIImage(named: "SportOff"), for: .normal)
          boundaryRing.image = UIImage(named: "NormalCircle")
          crosshair.image = UIImage(named: "NormalCross")
          currentSensitivityFactor = normalSensitivityFactor
     }
     
     @IBAction func sportButtonPressed(_ sender: UIButton) {
          print("Fast")
          chillButton.setImage(UIImage(named: "ChillOff"), for: .normal)
          normalButton.setImage(UIImage(named: "NormalOff"), for: .normal)
          sportButton.setImage(UIImage(named: "SportOn"), for: .normal)
          boundaryRing.image = UIImage(named: "SportCircle")
          crosshair.image = UIImage(named: "SportCross")
          currentSensitivityFactor = fastSensitivityFactor
     }
     
     func readMotionData() {
          if motionManager.isDeviceMotionAvailable {
               motionManager.deviceMotionUpdateInterval = sensorUpdateFrequency
               motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
                    
                    guard let data = data, error == nil else {
                         return
                    }
                    
                    let attitude = data.attitude
                    
                    var pitch: Double = 0
                    var roll: Double = 0
                    
                    pitch = -attitude.roll * 180.0/Double.pi * self.currentSensitivityFactor
                    roll = -attitude.pitch * 180.0/Double.pi * self.currentSensitivityFactor
                    
                    var cleanedPitch: Double = 0.0
                    var cleanedRoll: Double = 0.0
                    
                    let currentTiltRadius = self.getTiltRadius(pitch: pitch, roll: roll)
                    let currentTiltAngle = self.getTiltAngle(pitch: pitch, roll: roll)
                    
                    // Cleaning radius angle values
                    if currentTiltRadius > self.maxTiltRadius {
                         
                         if pitch >= 0 && roll >= 0 {
                              // Q1
                              cleanedPitch = self.maxTiltRadius * sin(currentTiltAngle)
                              cleanedRoll = self.maxTiltRadius * cos(currentTiltAngle)
                         } else if pitch >= 0 && roll <= 0 {
                              // Q2
                              cleanedPitch = self.maxTiltRadius * sin(Double.pi - currentTiltAngle)
                              cleanedRoll = -self.maxTiltRadius * cos(Double.pi - currentTiltAngle)
                         } else if pitch <= 0 && roll <= 0 {
                              // Q3
                              cleanedPitch = -self.maxTiltRadius * sin(currentTiltAngle - Double.pi)
                              cleanedRoll = -self.maxTiltRadius * cos(currentTiltAngle - Double.pi)
                         } else {
                              // Q4
                              cleanedPitch = -self.maxTiltRadius * sin((2 * Double.pi) - currentTiltAngle)
                              cleanedRoll = self.maxTiltRadius * cos((2 * Double.pi) - currentTiltAngle)
                         }
                    } else {
                         cleanedPitch = pitch
                         cleanedRoll = roll
                    }
                    
                    self.pitchLabel.text = "PITCH˸  \(Int(round(cleanedPitch)))°"
                    self.rollLabel.text = "ROLL˸  \(Int(round(cleanedRoll)))°"
                    
                    self.phoneXAngle = cleanedPitch
                    self.phoneYAngle = cleanedRoll
                    
                    let roundedPitch = round(cleanedPitch)
                    let roundedRoll = round(cleanedRoll)
                    
                    if roundedRoll == 0 && roundedPitch == 0 {
                         if !self.centred {
                              self.centredGenerator.prepare()
                              self.centredGenerator.impactOccurred()
                              self.centred = true
                         }
                    } else {
                         self.centred = false
                    }
                    
                    if currentTiltRadius >= self.maxTiltRadius {
                         if !self.hitBorder {
                              self.centredGenerator.prepare()
                              self.centredGenerator.impactOccurred()
                              self.hitBorder = true
                         }
                    } else {
                         self.hitBorder = false
                    }
                    
//                    self.boundaryRing.alpha = CGFloat(Utilities.map(minRange: 0, maxRange: self.maxTiltRadius, minDomain: 0.0, maxDomain: 1.0, value: currentTiltRadius))
                    
                    // Move the indicators when tilted
                    let circlePitchDisplacement = Utilities.map(minRange: -self.maxTiltRadius, maxRange: self.maxTiltRadius, minDomain: -Double(self.screenHeight/2 - 100), maxDomain: Double(self.screenHeight/2 - 100), value: cleanedPitch)
                    
                    let circleRollDisplacement = Utilities.map(minRange: -self.maxTiltRadius, maxRange: self.maxTiltRadius, minDomain: -Double(self.screenHeight/2 - 100), maxDomain: Double(self.screenHeight/2 - 100), value: cleanedRoll)
                    
                    self.tiltCircle.frame.origin = CGPoint(x: self.screenWidth!/2 - 75/2 - CGFloat(-circleRollDisplacement), y: self.screenHeight!/2 - 75/2 + CGFloat(-circlePitchDisplacement))
                    
                    self.crosshair.frame.origin = CGPoint(x: self.screenWidth!/2 - 20/2 - CGFloat(circleRollDisplacement), y: self.screenHeight!/2 - 20/2 + CGFloat(circlePitchDisplacement))
               }
          }
     }
     
     func getTiltRadius(pitch: Double, roll: Double) -> Double {
          let radius = sqrt(pow(pitch, 2) + pow(roll, 2))
          return radius
     }
     
     func getTiltAngle(pitch: Double, roll: Double) -> Double {
          let theta = atan(abs(pitch) / abs(roll))
          var angle: Double = 0.0
          
          if pitch >= 0 && roll >= 0 {
               // Q1
               angle = theta
          } else if pitch >= 0 && roll <= 0 {
              // Q2
               angle = Double.pi - theta
          } else if pitch <= 0 && roll <= 0 {
               // Q3
               angle = Double.pi + theta
          } else {
               // Q4
               angle = (2 * Double.pi) - theta
          }
          return angle
     }
     
     func returnToHome() {
          returnPlatformToHome()
          motionManager.stopDeviceMotionUpdates()
          navigationController?.popViewController(animated: true)
     }
     
     // MARK: BluetoothSerialDelegate
     
     func serialDidChangeState() {
          if !serial.isPoweredOn {
               print("Serial did change state.")
               returnToHome()
          }
     }
     
     func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
          print("Disconnected from BLE device.")
          serial.startScan()
          returnToHome()
     }
     
     @objc func sendAnglesToArduino() {
          
          print("phoneX: \(phoneXAngle), phoneY: \(phoneYAngle)")
          
          let phoneMotorRadians = self.stewart.motorAngles(xAngle: phoneXAngle.toRadians(), yAngle: phoneYAngle.toRadians())
          
          let cleanedSubtractedMotorAngles = phoneMotorRadians.map({$0.toDegrees()})
               .map({Int(Double($0).rounded())})
          
          var positiveCleanedSubtractedMotorAngles = [Int]()
          
          for i in cleanedSubtractedMotorAngles {
               var positiveAngle = 0
               if i < 0 {
                    positiveAngle = 360 + i
               } else {
                    positiveAngle = i
               }
               positiveCleanedSubtractedMotorAngles.append(positiveAngle)
          }
          
          let stringSubtractedMotorAngles = positiveCleanedSubtractedMotorAngles.map({String(format: "%03d", $0)})
          print(stringSubtractedMotorAngles)
          let combinedMotorAngles = stringSubtractedMotorAngles.joined(separator: "")
          let formattedMotorAngles = "<" + combinedMotorAngles + ">"
          
          serial.sendStringToDevice(formattedMotorAngles)
          
          print(formattedMotorAngles)
          
          print("----------")
     }
     
     func returnPlatformToHome() {
          serial.sendStringToDevice("<000000000000000000>")
     }
     
}
