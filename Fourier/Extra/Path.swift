//
//  Path.swift
//  Fourier
//
//  Created by Jack Finnis on 01/12/2022.
//

import SwiftUI

extension CGPath {
    var points: [CGPoint] {
        var points = [CGPoint]()
        applyWithBlock { pointer in
            points.append(pointer.pointee.points.pointee)
        }
        return points
    }
    
    var equallySpacedPoints: [CGPoint] {
        var n = 10.0
        var points = [CGPoint]()
        while points.count < 500 {
            points = copy(dashingWithPhase: 0, lengths: [n]).points
            n /= 2
        }
        return points
    }
}
