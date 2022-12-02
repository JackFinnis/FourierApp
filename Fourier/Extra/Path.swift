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
        copy(dashingWithPhase: 0, lengths: [10]).points
    }
}
