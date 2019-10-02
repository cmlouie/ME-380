//
//  Stewart.swift
//  Labyrinth Maze Controller
//
//  Created by Lance Gomes on 2019-09-30.
//  Copyright © 2019 Christopher Louie. All rights reserved.
//

import Foundation
import Accelerate
import simd

class Stewart {
    
    // platform Joint Angles measured with axis parallel to bottom edge (bottom edge has 2 motors)
    
    let baseRadius = Double(65.43) // 7.82 // 8.285 when shrey measured it with the motors
    let platformRadius = Double(76.35) // 6.523 // cm
    let baseToPlatformDistance = Double(120) // 17.0 // 15.0 cm
    let rodLength = Double(125) // 15.24 // 18.24 cm // 17.3
    let hornRadius = Double(36) // 1.8 cm

    let motorHornWidth = Double(0.0) // 0.6
    let rubberBearingWidth = Double(0.0) // 0.4

    let baseMotorAngles : [Double] = [314.9, 345.1, 74.9, 105.1, 194.9, 225.1]
    let platformMotorAngles : [Double] = [322.9, 337.1, 82.9, 97.1, 202.9, 217.1]
    let motorOrientation : [Double] = [-2 * Double.pi/3, Double.pi/3, 0, -Double.pi, -4 * Double.pi/3, -Double.pi/3]

    var platformTotalLength : Double
    var baseTotalLength : Double

    var baseLocation: [SIMD3<Double>] = []
    var platformLocation : [SIMD3<Double>] = []

    init() {
        
        let baseMotorRads = baseMotorAngles.map({$0 * Double.pi/180.0})
        let platformMotorRads = platformMotorAngles.map({$0 * Double.pi/180.0})

        platformTotalLength = platformRadius + rubberBearingWidth
        baseTotalLength = baseRadius + motorHornWidth + rubberBearingWidth

        for i in 0...5 {
            baseLocation.append(simd_double3(
                cos(baseMotorRads[i]) * baseTotalLength,
                sin(baseMotorRads[i]) * baseTotalLength,
                0
            ))

            platformLocation.append(simd_double3(
                cos(platformMotorRads[i]) * platformTotalLength,
                sin(platformMotorRads[i]) * platformTotalLength,
                0
            ))
        }
    }
    
    func motorAngles(xAngle: Double, yAngle: Double) -> [Double] {
        
        let (legLengths, legVectors) = self.legLengths(xAngle: xAngle, yAngle: yAngle)
        
        var motorAngles : [Double] = []
        
        for i in 0...5 {
            let L = length_squared(legLengths[i]) + (hornRadius * hornRadius) - ( rodLength * rodLength)
            let M = hornRadius * 2 * (legVectors[i].z)
            let N = hornRadius * 2 * (
                cos(motorOrientation[i]) * (legVectors[i].x - baseLocation[i].x)
                + sin(motorOrientation[i]) * (legVectors[i].y - baseLocation[i].y)
            );
            
            motorAngles.append(asin(L/(sqrt(M*M + N*N))) - atan(N/M))
            
            if motorAngles[i] <= 0.0 {
                motorAngles[i] = 2 * Double.pi + motorAngles[i]
            }
//            print(String(format: "Motor %d : %f", i + 1, motorAngles[i] * (180.0 / Double.pi)))
            
        }
        return motorAngles
    }

    func legLengths(xAngle: Double, yAngle: Double) -> (legLengths :[SIMD3<Double>], legVectors: [SIMD3<Double>]) {

        let rotationMatrix = self.rotationMatrix(xAngle: xAngle, yAngle: yAngle)
        let translationVector = simd_double3(0 , 0 , baseToPlatformDistance)

        var legLengths : [SIMD3<Double>] = []
        var legVectors : [SIMD3<Double>] = []

        for i in 0...5 {
            legVectors.append(translationVector + rotationMatrix * platformLocation[i])
            legLengths.append(legVectors[i] - baseLocation[i])
        }
        return (legLengths , legVectors)
    }

    func rotationMatrix(xAngle: Double, yAngle: Double) -> double3x3 {

        let yRows = [
            simd_double3(cos(yAngle), 0, sin(yAngle)),
            simd_double3(0,           1,           0),
            simd_double3(-sin(yAngle),0, cos(yAngle))
        ]

        let xRows = [
            simd_double3(1,           0,            0),
            simd_double3(0, cos(xAngle), -sin(xAngle)),
            simd_double3(0, sin(xAngle),  cos(xAngle))
        ]

        let yRotation = double3x3(rows: yRows)
        let xRotation = double3x3(rows: xRows)

        return yRotation * xRotation

    }
}
