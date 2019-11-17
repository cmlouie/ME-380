//
//  Utilities.swift
//  Stewart Platform Controller
//
//  Created by Christopher Louie on 2019-09-30.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import Foundation
import UIKit

class Utilities {
    
    /// Maps a value from one range to another range
    static func map(minRange: Double, maxRange: Double, minDomain: Double, maxDomain: Double, value: Double) -> Double {
        return minDomain + (maxDomain - minDomain) * (value - minRange) / (maxRange - minRange)
    }
    
}
