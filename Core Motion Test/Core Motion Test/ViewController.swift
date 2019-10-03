//
//  ViewController.swift
//  Core Motion Test
//
//  Created by Christopher Louie on 2019-09-30.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import UIKit
import CoreMotion
import CoreBluetooth

class ViewController: UIViewController {
     
     @IBOutlet weak var backButton: UIButton!
     @IBOutlet weak var xAngleLabel: UILabel!
     @IBOutlet weak var yAngleLabel: UILabel!
     
     let motionManager = CMMotionManager()
     
     let circleDiameter: CGFloat = 50.0
     let circleMidDiameter: CGFloat = 60.0
     let circleBorderDiameter: CGFloat = 75.0
     let sensorUpdateFrequency: TimeInterval = 1 // Seconds
     
     let maxPitchAngle: Double = 13.0
     let maxRollAngle: Double = 10.0
     
     var screenHeight: CGFloat?
     var circleView: UIView?
     let stewart = Stewart()
     
     let hapticGenerator = UISelectionFeedbackGenerator()
     
     override func viewDidLoad() {
          super.viewDidLoad()
          
          readMotionData()
          screenHeight = self.view.frame.size.height
//          setupCircles()
     }
     
     @IBAction func backButtonPressed(_ sender: UIButton) {
          navigationController?.popViewController(animated: true)
          motionManager.stopDeviceMotionUpdates()
     }
     
     func writeCharacteristic(value: String) {
          if let peripheral = arduinoPeripheral {
               if let txCharacteristic = txCharacteristic {
                    let data = value.data(using: .utf8)!
                    peripheral.writeValue(data, for: txCharacteristic, type: .withoutResponse)
               }
          }
     }
     
     @IBAction func middleClick(_ sender: Any) {
          self.writeCharacteristic(value: "0")
     }
     
     @IBAction func leftClick(_ sender: Any) {
          self.writeCharacteristic(value: "1")
     }
     
     @IBAction func rightClick(_ sender: Any) {
          self.writeCharacteristic(value: "2")
     }
     
     @IBAction func upClick(_ sender: Any) {
          self.writeCharacteristic(value: "3")
     }
     
     @IBAction func downClick(_ sender: Any) {
          self.writeCharacteristic(value: "4")
     }
     
     func setupCircles() {
          let circleFrame: CGRect = CGRect(x: self.view.frame.size.width/2 - circleDiameter/2, y: self.view.frame.size.height/2 - circleDiameter/2, width: circleDiameter, height: circleDiameter)
          let circleMidFrame: CGRect = CGRect(x: self.view.frame.size.width/2 - circleMidDiameter/2, y: self.view.frame.size.height/2 - circleMidDiameter/2, width: circleMidDiameter, height: circleMidDiameter)
          let circleBorderFrame: CGRect = CGRect(x: self.view.frame.size.width/2 - circleBorderDiameter/2, y: self.view.frame.size.height/2 - circleBorderDiameter/2, width: circleBorderDiameter, height: circleBorderDiameter)
          
          // Static circles
          drawCircle(circleBorderFrame, .black)
          drawCircle(circleMidFrame, .white)
          
          // Dynamic circle
          circleView = Circle(frame: circleFrame)
          view.addSubview(circleView!)
     }
     
     func drawCircle(_ rect: CGRect, _ color: UIColor) {
          let circlePath = UIBezierPath(ovalIn: rect)
          let shapeLayer = CAShapeLayer()
          shapeLayer.path = circlePath.cgPath
          shapeLayer.fillColor = color.cgColor
          
          view.layer.addSublayer(shapeLayer)
     }
     
     func readMotionData() {
          if motionManager.isDeviceMotionAvailable {
               motionManager.deviceMotionUpdateInterval = sensorUpdateFrequency
               motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
                    
                    guard let data = data, error == nil else {
                         return
                    }
                    
                    let attitude = data.attitude
                    let pitch = attitude.pitch * 180.0/Double.pi
                    let roll = attitude.roll * 180.0/Double.pi
                    
                    var cleanedPitch: Double = 0.0
                    var cleanedRoll: Double = 0.0
                    
                    // Cleaning pitch values
                    if abs(pitch) <= self.maxPitchAngle {
                         cleanedPitch = pitch
                    }
                    else if pitch > self.maxPitchAngle {
                         cleanedPitch = self.maxPitchAngle
                         self.hapticGenerator.prepare()
                         self.hapticGenerator.selectionChanged()
                    }
                    else {
                         cleanedPitch = -self.maxPitchAngle
                         self.hapticGenerator.prepare()
                         self.hapticGenerator.selectionChanged()
                    }
                    
                    // Cleaning roll values
                    if abs(roll) <= self.maxRollAngle {
                         cleanedRoll = roll
                    }
                    else if roll > self.maxRollAngle {
                         cleanedRoll = self.maxRollAngle
                         self.hapticGenerator.prepare()
                         self.hapticGenerator.selectionChanged()
                    }
                    else {
                         cleanedRoll = -self.maxRollAngle
                         self.hapticGenerator.prepare()
                         self.hapticGenerator.selectionChanged()
                    }
                    
//                    print("x: \(-cleanedPitch), y: \(-cleanedRoll)")
                    self.xAngleLabel.text = "x: \(Int(-cleanedPitch))°"
                    self.yAngleLabel.text = "y: \(Int(-cleanedRoll))°"
                    
                    let motorRadianAngles = self.stewart.motorAngles(xAngle: (Double(-cleanedPitch) * Double.pi/180.0), yAngle: Double(-cleanedRoll) * Double.pi/180.0)
                    
                    /// Convert motor angles to ble readable format
                    let motorDegreeAngles = motorRadianAngles.map({$0 * (180.0 / Double.pi)})
                    let cleanedMotorAngles = motorDegreeAngles.map({Int(Double($0).rounded())})
                    
                    let stringMotorAngles = cleanedMotorAngles.map({String(format: "%03d", $0)})
                    let combinedMotorAngles = stringMotorAngles.joined(separator: "")
                    let formattedMotorAngles = "<" + combinedMotorAngles + ">"
                    
                    // self.writeCharacteristic(value: formattedMotorAngles)
                    print(stringMotorAngles)
                    print(formattedMotorAngles)
                    
//                    let circlePitchDisplacement = Utilities.map(minRange: -self.maxPitchAngle, maxRange: self.maxPitchAngle, minDomain: -Double(self.screenHeight!/2), maxDomain: Double(self.screenHeight!/2), value: cleanedPitch)
//                    
//                    let circleRollDisplacement = Utilities.map(minRange: -self.maxRollAngle, maxRange: self.maxRollAngle, minDomain: -Double(self.screenHeight!/2), maxDomain: Double(self.screenHeight!/2), value: cleanedRoll)
//
//                    // Move the red circle according to the attitude pitch and roll
//                    self.circleView?.frame.origin = CGPoint(x: self.view.frame.size.width/2 - self.circleDiameter/2 - CGFloat(circlePitchDisplacement), y: self.view.frame.size.height/2 - self.circleDiameter/2 + CGFloat(circleRollDisplacement))
               }
          }
     }
     
     
}
