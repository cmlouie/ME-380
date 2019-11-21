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
     @IBOutlet weak var xAngleLabel: UILabel!
     @IBOutlet weak var yAngleLabel: UILabel!
     @IBOutlet weak var controlTypeButton: UIButton!
     
     // MARK: Constants
     
     let motionManager = CMMotionManager()
     let stewart = Stewart()
     
     let circleDiameter: CGFloat = 50.0
     let circleMidDiameter: CGFloat = 60.0
     let circleBorderDiameter: CGFloat = 75.0
     let arrowWidth: CGFloat = 70.0
     let arrowHeight: CGFloat = 70.0
     let arrowOffset: CGFloat = 110.0
     
     let sensorUpdateFrequency: TimeInterval = 1.0 / 100.0 // Seconds
     
     // 20 degrees max before unsuported platform angles for current design
     let maxPitchAngle: Double = 20.0
     let maxRollAngle: Double = 20.0
     
     // MARK: Variables
     
     var platformXAngle: Double = 0
     var platformYAngle: Double = 0
     var phoneXAngle: Double = 0
     var phoneYAngle: Double = 0
     
     var showDPAD = true
     
     var screenHeight: CGFloat?
     var circleView: UIView?
     var circleBorderView: UIView?
     var circleMidView: UIView?
     
     var upArrowView: UIView?
     var leftArrowView: UIView?
     var downArrowView: UIView?
     var rightArrowView: UIView?
     
     var centerTap: UILongPressGestureRecognizer?
     var upTap: UILongPressGestureRecognizer?
     var leftTap: UILongPressGestureRecognizer?
     var downTap: UILongPressGestureRecognizer?
     var rightTap: UILongPressGestureRecognizer?
     
     // Haptic feedback
     let tiltHapticGenerator = UISelectionFeedbackGenerator()
     let buttonHapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
     
     // MARK: Functions
     
     override func viewDidLoad() {
          super.viewDidLoad()
          
          serial.delegate = self
          
          setupCircles(shouldShow: !showDPAD)
          setupArrows(shouldShow: showDPAD)
          xAngleLabel.isHidden = showDPAD
          yAngleLabel.isHidden = showDPAD
          
          screenHeight = self.view.frame.size.height
     }
     
     @IBAction func backButtonPressed(_ sender: UIButton) {
          returnToHome()
     }
     
     @IBAction func controlTypeButtonPressed(_ sender: UIButton) {
          toggleControlType()
     }
     
     func toggleControlType() {
          showDPAD = !showDPAD
          
          if showDPAD {
               controlTypeButton.setTitle("Switch to gyro controller", for: .normal)
          } else {
               controlTypeButton.setTitle("Switch to DPAD controller", for: .normal)
          }
          
          // DPAD view
          setupArrows(shouldShow: showDPAD)
          
          // Gyro view
          readMotionData(gyroView: !showDPAD)
          setupCircles(shouldShow: !showDPAD)
          
          // Angle labels
          xAngleLabel.isHidden = showDPAD
          yAngleLabel.isHidden = showDPAD
     }
     
     func setupCircles(shouldShow: Bool) {
          let circleFrame: CGRect = CGRect(x: self.view.frame.size.width/2 - circleDiameter/2, y: self.view.frame.size.height/2 - circleDiameter/2, width: circleDiameter, height: circleDiameter)
          let circleMidFrame: CGRect = CGRect(x: self.view.frame.size.width/2 - circleMidDiameter/2, y: self.view.frame.size.height/2 - circleMidDiameter/2, width: circleMidDiameter, height: circleMidDiameter)
          let circleBorderFrame: CGRect = CGRect(x: self.view.frame.size.width/2 - circleBorderDiameter/2, y: self.view.frame.size.height/2 - circleBorderDiameter/2, width: circleBorderDiameter, height: circleBorderDiameter)
          
          if let _ = circleBorderView, let _ = circleMidView {
               // View already exist, don't create it
          } else {
               // Create it
               circleBorderView = Circle(circleFrame: circleBorderFrame, lightModeColor: .black, darkModeColor: .white)
               view.addSubview(circleBorderView!)
               
               circleMidView = Circle(circleFrame: circleMidFrame, lightModeColor: .white, darkModeColor: .black)
               view.addSubview(circleMidView!)
          }
          
          if shouldShow {
               circleMidView?.removeGestureRecognizer(centerTap!)
               circleView = Circle(circleFrame: circleFrame, lightModeColor: .red, darkModeColor: .red)
               view.addSubview(circleView!)
               
          } else {
               centerTap = UILongPressGestureRecognizer(target: self, action: #selector(homeTapped(gesture:)))
               centerTap?.minimumPressDuration = 0
               circleMidView?.addGestureRecognizer(centerTap!)
               circleView?.removeFromSuperview()
          }
     }
     
     func setupArrows(shouldShow: Bool) {
          let upArrowFrame: CGRect = CGRect(origin: CGPoint(x: self.view.center.x - arrowWidth/2, y: self.view.center.y - arrowHeight/2 - arrowOffset), size: CGSize(width: arrowWidth, height: arrowHeight))
          let leftArrowFrame: CGRect = CGRect(origin: CGPoint(x: self.view.center.x - arrowWidth/2 - arrowOffset, y: self.view.center.y - arrowHeight/2), size: CGSize(width: arrowWidth, height: arrowHeight))
          let downArrowFrame: CGRect = CGRect(origin: CGPoint(x: self.view.center.x - arrowWidth/2, y: self.view.center.y - arrowHeight/2 + arrowOffset), size: CGSize(width: arrowWidth, height: arrowHeight))
          let rightArrowFrame: CGRect = CGRect(origin: CGPoint(x: self.view.center.x - arrowWidth/2 + arrowOffset, y: self.view.center.y - arrowHeight/2), size: CGSize(width: arrowWidth, height: arrowHeight))
          
          if shouldShow {
               upArrowView = Arrow(frame: upArrowFrame)
               leftArrowView = Arrow(frame: leftArrowFrame)
               downArrowView = Arrow(frame: downArrowFrame)
               rightArrowView = Arrow(frame: rightArrowFrame)
               
               leftArrowView?.rotateBy(-90)
               downArrowView?.rotateBy(180)
               rightArrowView?.rotateBy(90)
               
               upTap = UILongPressGestureRecognizer(target: self, action: #selector(upArrowTapped(gesture:)))
               upTap?.minimumPressDuration = 0
               upArrowView?.addGestureRecognizer(upTap!)
               
               leftTap = UILongPressGestureRecognizer(target: self, action: #selector(leftArrowTapped(gesture:)))
               leftTap?.minimumPressDuration = 0
               leftArrowView?.addGestureRecognizer(leftTap!)
               
               downTap = UILongPressGestureRecognizer(target: self, action: #selector(downArrowTapped(gesture:)))
               downTap?.minimumPressDuration = 0
               downArrowView?.addGestureRecognizer(downTap!)
               
               rightTap = UILongPressGestureRecognizer(target: self, action: #selector(rightArrowTapped(gesture:)))
               rightTap?.minimumPressDuration = 0
               rightArrowView?.addGestureRecognizer(rightTap!)
               
               view.addSubview(upArrowView!)
               view.addSubview(leftArrowView!)
               view.addSubview(downArrowView!)
               view.addSubview(rightArrowView!)
          }
          else {
               upArrowView?.removeFromSuperview()
               leftArrowView?.removeFromSuperview()
               downArrowView?.removeFromSuperview()
               rightArrowView?.removeFromSuperview()
          }
     }
     
     // MARK: D-Pad
     
     @objc func homeTapped(gesture: UILongPressGestureRecognizer) {
          if gesture.state == .began {
               print("Home tapped")
               self.buttonHapticGenerator.prepare()
               self.buttonHapticGenerator.impactOccurred()
               serial.sendStringToDevice("0")
          }
     }
     
     @objc func upArrowTapped(gesture: UILongPressGestureRecognizer) {
          if gesture.state == .began {
               print("Up arrow tapped")
               self.buttonHapticGenerator.prepare()
               self.buttonHapticGenerator.impactOccurred()
               serial.sendStringToDevice("4")
          }
     }
     
     @objc func leftArrowTapped(gesture: UILongPressGestureRecognizer) {
          if gesture.state == .began {
               print("Left arrow tapped")
               self.buttonHapticGenerator.prepare()
               self.buttonHapticGenerator.impactOccurred()
               serial.sendStringToDevice("2")
          }
     }
     
     @objc func downArrowTapped(gesture: UILongPressGestureRecognizer) {
          if gesture.state == .began {
               print("Down arrow tapped")
               self.buttonHapticGenerator.prepare()
               self.buttonHapticGenerator.impactOccurred()
               serial.sendStringToDevice("3")
          }
     }
     
     @objc func rightArrowTapped(gesture: UILongPressGestureRecognizer) {
          if gesture.state == .began {
               print("Right arrow tapped")
               self.buttonHapticGenerator.prepare()
               self.buttonHapticGenerator.impactOccurred()
               serial.sendStringToDevice("1")
          }
     }
     
     func readMotionData(gyroView: Bool) {
          if gyroView {
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
                              self.tiltHapticGenerator.prepare()
                              self.tiltHapticGenerator.selectionChanged()
                         }
                         else {
                              cleanedPitch = -self.maxPitchAngle
                              self.tiltHapticGenerator.prepare()
                              self.tiltHapticGenerator.selectionChanged()
                         }
                         
                         // Cleaning roll values
                         if abs(roll) <= self.maxRollAngle {
                              cleanedRoll = roll
                         }
                         else if roll > self.maxRollAngle {
                              cleanedRoll = self.maxRollAngle
                              self.tiltHapticGenerator.prepare()
                              self.tiltHapticGenerator.selectionChanged()
                         }
                         else {
                              cleanedRoll = -self.maxRollAngle
                              self.tiltHapticGenerator.prepare()
                              self.tiltHapticGenerator.selectionChanged()
                         }
                         
                         // lance -- going to switch these two around to match platform gyroscope and processing,
                         // changing from "x: \(Int(-cleanedPitch))°" -> "x: \(Int(-cleanedRoll))°"
                         // changing from "y: \(Int(-cleanedRoll))°" -> "y: \(Int(-cleanedPitch))°"
                         
                         self.xAngleLabel.text = "x: \(Int(-cleanedRoll))°"
                         self.yAngleLabel.text = "y: \(Int(-cleanedPitch))°"
                         
                         
                         self.phoneXAngle = -cleanedRoll
                         self.phoneYAngle = -cleanedPitch
                         
                         let circlePitchDisplacement = Utilities.map(minRange: -self.maxPitchAngle, maxRange: self.maxPitchAngle, minDomain: -Double(self.screenHeight!/2), maxDomain: Double(self.screenHeight!/2), value: cleanedPitch)
                         
                         let circleRollDisplacement = Utilities.map(minRange: -self.maxRollAngle, maxRange: self.maxRollAngle, minDomain: -Double(self.screenHeight!/2), maxDomain: Double(self.screenHeight!/2), value: cleanedRoll)
                         
                         // Move the red circle according to the attitude pitch and roll
                         self.circleView?.frame.origin = CGPoint(x: self.view.frame.size.width/2 - self.circleDiameter/2 - CGFloat(circlePitchDisplacement), y: self.view.frame.size.height/2 - self.circleDiameter/2 + CGFloat(circleRollDisplacement))
                    }
               }
          }
          else {
               motionManager.stopDeviceMotionUpdates()
          }
     }
     
     func extractPlatformAngles(from BLEString: String) -> (x: Double, y: Double) {
          var platformXAngle: Double = 0
          var platformYAngle: Double = 0
          
          var stringArray = [String]()
          stringArray = BLEString.components(separatedBy: ",")
          let platformAngles = stringArray.map({ Double($0) ?? 0 })
          
          if platformAngles.count == 2 {
               platformXAngle = platformAngles[0]
               platformYAngle = platformAngles[1]
          }
          
          var cleanedPitch: Double = 0.0
          var cleanedRoll: Double = 0.0
          
          // Cleaning pitch values
          if abs(platformXAngle) <= self.maxPitchAngle {
               cleanedPitch = platformXAngle
          }
          else if platformXAngle > self.maxPitchAngle {
               cleanedPitch = self.maxPitchAngle
          }
          else {
               cleanedPitch = -self.maxPitchAngle
          }
          
          // Cleaning roll values
          if abs(platformYAngle) <= self.maxRollAngle {
               cleanedRoll = platformYAngle
          }
          else if platformYAngle > self.maxRollAngle {
               cleanedRoll = self.maxRollAngle
          }
          else {
               cleanedRoll = -self.maxRollAngle
          }
          
          // lance -- going to switch these two around to match platform gyroscope and processing,
          // changing from (cleanedPitch, cleanedRoll) -> (cleanedRoll, cleanedPitch)
          return (cleanedRoll, cleanedPitch)
     }
     
     func returnToHome() {
          motionManager.stopDeviceMotionUpdates()
          navigationController?.popViewController(animated: true)
     }
     
     
     // MARK: BluetoothSerialDelegate
     
     func serialDidChangeState() {
          if !serial.isPoweredOn {
               print("Serial did change state.")
               returnToHome()
               // TODO: disable button and start scanning again
          }
     }
     
     func serialDidDisconnect(_ peripheral: CBPeripheral, error: NSError?) {
          print("Disconnected from BLE device.")
          serial.startScan()
          returnToHome()
          // TODO: disable button and start scanning again
     }
     
     func serialDidReceiveString(_ string: String) {
          platformXAngle = extractPlatformAngles(from: string).x
          platformYAngle = extractPlatformAngles(from: string).y
          
          print("platformX: \(platformXAngle), platformY: \(platformYAngle)")
          print("phoneX: \(phoneXAngle), phoneY: \(phoneYAngle)")
          
          let phoneMotorRadians = self.stewart.motorAngles(xAngle: phoneXAngle.toRadians(), yAngle: phoneYAngle.toRadians())
          let platformMotorRadians = self.stewart.motorAngles(xAngle: platformXAngle.toRadians(), yAngle: platformYAngle.toRadians())
          var subtractedMotorDegreeAngles = [Double]()
          
          for i in 0..<6 {
               subtractedMotorDegreeAngles.append(phoneMotorRadians[i] - platformMotorRadians[i])
          }
          
          let cleanedSubtractedMotorAngles = subtractedMotorDegreeAngles.map({$0.toDegrees()})
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
}
