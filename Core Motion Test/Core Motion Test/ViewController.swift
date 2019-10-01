//
//  ViewController.swift
//  Core Motion Test
//
//  Created by Christopher Louie on 2019-09-30.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
     
     @IBOutlet weak var xAngleLabel: UILabel!
     @IBOutlet weak var yAngleLabel: UILabel!
     
     let motionManager = CMMotionManager()
     
     let circleDiameter: CGFloat = 50.0
     let circleMidDiameter: CGFloat = 60.0
     let circleBorderDiameter: CGFloat = 75.0
     
     let maxPitchAngle: Double = 45.0
     let maxRollAngle: Double = 45.0
     
     var screenHeight: CGFloat?
     var circleView: UIView?
     
     override func viewDidLoad() {
          super.viewDidLoad()
          
          readMotionData()
          screenHeight = self.view.frame.size.height
          setupCircles()
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
               motionManager.deviceMotionUpdateInterval = 1.0 / 100.0 // 60 Hz
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
                         let generator = UIImpactFeedbackGenerator(style: .heavy)
                         generator.prepare()
                         generator.impactOccurred()
                         print("BUZZ")
                    }
                    else {
                         cleanedPitch = -self.maxPitchAngle
                         let generator = UIImpactFeedbackGenerator(style: .heavy)
                         generator.prepare()
                         generator.impactOccurred()
                         print("BUZZ")
                    }
                    
                    // Cleaning roll values
                    if abs(roll) <= self.maxRollAngle {
                         cleanedRoll = roll
                    }
                    else if roll > self.maxRollAngle {
                         cleanedRoll = self.maxRollAngle
                         let generator = UIImpactFeedbackGenerator(style: .heavy)
                         generator.prepare()
                         generator.impactOccurred()
                         print("BUZZ")
                    }
                    else {
                         cleanedRoll = -self.maxRollAngle
                         let generator = UIImpactFeedbackGenerator(style: .heavy)
                         generator.prepare()
                         generator.impactOccurred()
                         print("BUZZ")
                    }
                    
                    self.xAngleLabel.text = "x: \(Int(-cleanedPitch))°"
                    self.yAngleLabel.text = "y: \(Int(-cleanedRoll))°"
                    
                    let circlePitchDisplacement = Utilities.map(minRange: -self.maxPitchAngle, maxRange: self.maxPitchAngle, minDomain: -Double(self.screenHeight!/2), maxDomain: Double(self.screenHeight!/2), value: cleanedPitch)
                    
                    let circleRollDisplacement = Utilities.map(minRange: -self.maxRollAngle, maxRange: self.maxRollAngle, minDomain: -Double(self.screenHeight!/2), maxDomain: Double(self.screenHeight!/2), value: cleanedRoll)
                    
                    // Move the red circle according to the attitude pitch and roll
                    self.circleView?.frame.origin = CGPoint(x: self.view.frame.size.width/2 - self.circleDiameter/2 - CGFloat(circlePitchDisplacement), y: self.view.frame.size.height/2 - self.circleDiameter/2 + CGFloat(circleRollDisplacement))
               }
          }
     }
     
     
}
