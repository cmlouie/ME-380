//
//  Circle.swift
//  Core Motion Test
//
//  Created by Christopher Louie on 2019-09-30.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import UIKit

class Circle: UIView {
    
    var lightModeColor: UIColor?
    var darkModeColor: UIColor?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(circleFrame: CGRect, lightModeColor: UIColor, darkModeColor: UIColor) {
        self.lightModeColor = lightModeColor
        self.darkModeColor = darkModeColor
        super.init(frame: circleFrame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let circlePath = UIBezierPath(ovalIn: self.bounds)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        
        if traitCollection.userInterfaceStyle == .light {
            shapeLayer.fillColor = lightModeColor?.cgColor
        } else if traitCollection.userInterfaceStyle == .dark {
            shapeLayer.fillColor = darkModeColor?.cgColor
        }

        layer.addSublayer(shapeLayer)
    }
    

}
