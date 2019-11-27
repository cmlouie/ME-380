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
     
     var orientation: UIInterfaceOrientation = .landscapeRight
     
     let motionManager = CMMotionManager()
     let stewart = Stewart()
     
     let circleDiameter: CGFloat = 50.0
     let circleMidDiameter: CGFloat = 60.0
     let circleBorderDiameter: CGFloat = 75.0
     let arrowWidth: CGFloat = 70.0
     let arrowHeight: CGFloat = 70.0
     let arrowOffset: CGFloat = 110.0
     
     let sensorUpdateFrequency: TimeInterval = 1.0 / 100.0 // Seconds
     
     let maxTiltRadius: Double = 10.0
     
     // MARK: Variables
     
     var platformXAngle: Double = 0
     var platformYAngle: Double = 0
     var phoneXAngle: Double = 0
     var phoneYAngle: Double = 0
     
     var showDPAD = true
     var centred = false
     var hitTopWall = false
     var hitLeftWall = false
     var hitRightWall = false
     var hitBottomWall = false
     
     var screenWidth: CGFloat?
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
     let tiltHapticGenerator = UINotificationFeedbackGenerator()
     let buttonHapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
     let centredGenerator = UIImpactFeedbackGenerator(style: .light)
     
     // MARK: Functions
     
     override func viewDidLoad() {
          super.viewDidLoad()
          
          serial.delegate = self
          
          setupCircles(shouldShow: !showDPAD)
          setupArrows(shouldShow: showDPAD)
          xAngleLabel.isHidden = showDPAD
          yAngleLabel.isHidden = showDPAD
          
          screenWidth = self.view.frame.size.width
          screenHeight = self.view.frame.size.height
          
     }
     
     override func viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated)
          checkCurrentOrientationOfUI()
          toggleControlType()
     }
     
     override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
          super.viewWillTransition(to: size, with: coordinator)
          checkFutureOrientationOfUI()
     }
     
     func checkCurrentOrientationOfUI() {
          if UIApplication.shared.statusBarOrientation == .landscapeLeft  {
               orientation = .landscapeLeft
          } else if UIApplication.shared.statusBarOrientation == .landscapeRight {
               orientation = .landscapeRight
          }
     }
     
     func checkFutureOrientationOfUI() {
          if UIApplication.shared.statusBarOrientation == .landscapeLeft  {
               orientation = .landscapeRight
          } else if UIApplication.shared.statusBarOrientation == .landscapeRight {
               orientation = .landscapeLeft
          }
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
               if #available(iOS 13.0, *) {
                    view.backgroundColor = .systemBackground
               } else {
                    view.backgroundColor = .white
               }
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
                         
                         var pitch: Double = 0
                         var roll: Double = 0
                         
                         if self.orientation == .landscapeLeft {
                              pitch = -attitude.roll * 180.0/Double.pi
                              roll = -attitude.pitch * 180.0/Double.pi
                         } else if self.orientation == .landscapeRight {
                              pitch = attitude.roll * 180.0/Double.pi
                              roll = attitude.pitch * 180.0/Double.pi
                         }
                         
                         var cleanedPitch: Double = 0.0
                         var cleanedRoll: Double = 0.0
                         
                         let currentTiltRadius = self.getTiltRadius(pitch: pitch, roll: roll)
                         let currentTiltAngle = self.getTiltAngle(pitch: pitch, roll: roll)
                         
                         // Cleaning radius angle values
                         if currentTiltRadius > self.maxTiltRadius {
                              print("REACHED MAX")
                              
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
                         
                         print("PITCH: \(cleanedPitch)")
                         print("ROLL: \(cleanedRoll)")
                         
                         // lance -- going to switch these two around to match platform gyroscope and processing,
                         // changing from "x: \(Int(-cleanedPitch))°" -> "x: \(Int(-cleanedRoll))°"
                         // changing from "y: \(Int(-cleanedRoll))°" -> "y: \(Int(-cleanedPitch))°"
                         
                         // lancey ruining things again
                         self.serialDidReceiveString()
                         
                         self.xAngleLabel.text = "x: \(Int(round(cleanedPitch)))°"
                         self.yAngleLabel.text = "y: \(Int(round(cleanedRoll)))°"
                         
                         self.phoneXAngle = cleanedPitch
                         self.phoneYAngle = cleanedRoll
                         
                         let roundedPitch = round(cleanedPitch)
                         let roundedRoll = round(cleanedRoll)
                         
                         if roundedRoll == 0 && roundedPitch == 0 {
                              self.view.backgroundColor = UIColor(red: 15/255, green: 227/255, blue: 111/255, alpha: 1.0)
                              if !self.centred {
                                   UIView.animate(withDuration: 0.2) {
                                        self.view.backgroundColor = UIColor(red: 15/255, green: 227/255, blue: 111/255, alpha: 1.0)
                                   }
                                   self.centredGenerator.prepare()
                                   self.centredGenerator.impactOccurred()
                                   self.centred = true
                              }
                         } else {
                              self.centred = false
                              UIView.animate(withDuration: 0.2) {
                                   if #available(iOS 13.0, *) {
                                        self.view.backgroundColor = .systemBackground
                                   } else {
                                        self.view.backgroundColor = .white
                                   }
                              }
                         }
                         
                         let circlePitchDisplacement = Utilities.map(minRange: -self.maxTiltRadius, maxRange: self.maxTiltRadius, minDomain: -Double(self.screenHeight!/2 - 50), maxDomain: Double(self.screenHeight!/2 - 50), value: cleanedPitch)
                         
                         let circleRollDisplacement = Utilities.map(minRange: -self.maxTiltRadius, maxRange: self.maxTiltRadius, minDomain: -Double(self.screenHeight!/2 - 50), maxDomain: Double(self.screenHeight!/2 - 50), value: cleanedRoll)
                         
                         // Move the red circle according to the attitude pitch and roll
                         self.circleView?.frame.origin = CGPoint(x: self.screenWidth!/2 - self.circleDiameter/2 - CGFloat(-circleRollDisplacement), y: self.screenHeight!/2 - self.circleDiameter/2 + CGFloat(-circlePitchDisplacement))
                    }
               }
          }
          else {
               motionManager.stopDeviceMotionUpdates()
          }
     }
     
     func returnToHome() {
          motionManager.stopDeviceMotionUpdates()
          navigationController?.popViewController(animated: true)
     }
     
     
     func getTiltRadius(pitch: Double, roll: Double) -> Double {
          let radius = sqrt(pow(pitch, 2) + pow(roll, 2))
          print("TILT RADIUS: \(radius)")
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
          
          print("TILT ANGLE: \(angle.toDegrees())")
          return angle
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
     
     func serialDidReceiveString() {
          
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
}
