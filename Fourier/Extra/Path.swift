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
}

extension Path {
    func getPoints() -> [(Double, Double)] {
        let dashed = cgPath.copy(dashingWithPhase: 0, lengths: [5])
        return dashed.points.map { ($0.x, $0.y) }
    }
}
