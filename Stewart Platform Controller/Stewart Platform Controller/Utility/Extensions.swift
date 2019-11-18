//
//  Extensions.swift
//  Stewart Platform Controller
//
//  Created by Christopher Louie on 2019-11-17.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import UIKit

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

extension UIView {
     func rotateBy(_ angle: CGFloat) {
          let radians = angle / 180.0 * CGFloat.pi
          let rotation = self.transform.rotated(by: radians);
          self.transform = rotation
     }
}

extension Double {
    func toRadians() -> Double {
        return self * Double.pi / 180.0
    }
    
    func toDegrees() -> Double {
        return self * 180.0 / Double.pi
    }
}
