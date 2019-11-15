//
//  Arrow.swift
//  Core Motion Test
//
//  Created by Christopher Louie on 2019-10-03.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import UIKit

class Arrow: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.beginPath()
        context.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.addLine(to: CGPoint(x: (rect.maxX / 2.0), y: rect.minY))
        context.closePath()
        
        if traitCollection.userInterfaceStyle == .light {
            context.setFillColor(UIColor.black.cgColor)
        } else if traitCollection.userInterfaceStyle == .dark {
            context.setFillColor(UIColor.white.cgColor)
        }
        
        context.fillPath()
    }
    
}
