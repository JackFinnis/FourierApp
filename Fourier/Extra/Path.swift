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
        let dashed = cgPath.copy(dashingWithPhase: 0, lengths: [1])
        return dashed.points.map { ($0.x, $0.y) }
    }
}




//        var points = [CGPoint]()
//        self.trimmedPath(from: 0, to: 0.5).forEach { element in
//            switch element {
//            case .move(to: let p1):
//                points.append(p1)
//            case .curve(to: let p1, control1: let p2, control2: let p3):
//                points.append(p1)
//                points.append(p2)
//                points.append(p3)
//            case .line(to: let p1):
//                points.append(p1)
//            case .quadCurve(to: let p1, control: let p2):
//                points.append(p1)
//                points.append(p2)
//            case .closeSubpath:
//                print("closed")
//            }
//        }
//        return points.map { point in
//            (point.x, point.y)
//        }
//        let samples = 1000
//        var points = [(Double, Double)]()
//        for i in 0...samples {
//            let subpath = self.trimmedPath(from: 0, to: CGFloat(i/1000)).path(in: CGRect(x: 0, y: 0, width: 300, height: 300))
//            print(subpath.boundingRect)
//            var cgPoints = [CGPoint]()
//            subpath.forEach { element in
//                switch element {
//                case .move(to: let cgPoint):
//                    cgPoints.append(cgPoint)
//                case .curve(to: let p1, control1: let p2, control2: let p3):
//                    cgPoints.append(p1)
//                    cgPoints.append(p2)
//                    cgPoints.append(p3)
//                case .line(to: let p1):
//                    cgPoints.append(p1)
//                case .quadCurve(to: let p1, control: let p2):
//                    cgPoints.append(p1)
//                    cgPoints.append(p2)
//                case .closeSubpath:
////                    print("closed")
//                    break
//                }
////                if element.pointee.type == .mo {
////                    let cgPoint = element.pointee.points.pointee
////                    if cgPoint.x.isFinite {
////                        cgPoints.append(cgPoint)
////                    }
////                }
//            }
//            if let cgPoint = cgPoints.last {
//                points.append((Double(cgPoint.x), Double(cgPoint.y)))
//            } else {
//                print("oh dear 2.0")
//            }
//        }
//        return points

extension UIBezierPath {
    func forEachPoint(interval: CGFloat, block: (_ point: CGPoint, _ vector: CGVector) -> Void) {
        let path = dashedPath(pattern: [interval * 0.5, interval * 0.5])
        path.forEachPoint { point, vector in
            block(point, vector)
        }
    }
    
    private func dashedPath(pattern: [CGFloat]) -> UIBezierPath {
        let dashedPath = cgPath.copy(dashingWithPhase: 0, lengths: pattern)
        return UIBezierPath(cgPath: dashedPath)
    }
    
    private var elements: [PathElement] {
        var pathElements = [PathElement]()
        cgPath.applyWithBlock { elementsPointer in
            let element = PathElement(element: elementsPointer.pointee)
            pathElements.append(element)
        }
        return pathElements
    }
    
    private func forEachPoint(_ block: (_ point: CGPoint, _ vector: CGVector) -> Void) {
        var hasPendingSegment: Bool = false
        var pendingControlPoint = CGPoint.zero
        var pendingPoint = CGPoint.zero
        for pathElement in elements {
            switch pathElement {
            case let .moveToPoint(destinationPoint):
                if hasPendingSegment {
                    block(pendingPoint, vector(from: pendingControlPoint, to: pendingPoint))
                    hasPendingSegment = false
                }
                pendingPoint = destinationPoint
            case let .addLineToPoint(destinationPoint):
                pendingControlPoint = pendingPoint
                pendingPoint = destinationPoint
                hasPendingSegment = true
            case let .addQuadCurveToPoint(controlPoint, destinationPoint):
                pendingControlPoint = controlPoint
                pendingPoint = destinationPoint
                hasPendingSegment = true
            case let .addCurveToPoint(controlPoint1, _, destinationPoint):
                pendingControlPoint = controlPoint1
                pendingPoint = destinationPoint
                hasPendingSegment = true
            case .closeSubpath:
                break
            }
        }
        if hasPendingSegment {
            block(pendingPoint, vector(from: pendingControlPoint, to: pendingPoint))
        }
    }
    
    private func vector(from point1: CGPoint, to point2: CGPoint) -> CGVector {
        let length = hypot(point2.x - point1.x, point2.y - point1.y)
        return CGVector(dx: (point2.x - point1.x) / length, dy: (point2.y - point1.y) / length)
    }
}

enum PathElement {
    case moveToPoint(CGPoint)
    case addLineToPoint(CGPoint)
    case addQuadCurveToPoint(CGPoint, CGPoint)
    case addCurveToPoint(CGPoint, CGPoint, CGPoint)
    case closeSubpath
    
    init(element: CGPathElement) {
        switch element.type {
        case .moveToPoint: self = .moveToPoint(element.points[0])
        case .addLineToPoint: self = .addLineToPoint(element.points[0])
        case .addQuadCurveToPoint: self = .addQuadCurveToPoint(element.points[0], element.points[1])
        case .addCurveToPoint: self = .addCurveToPoint(element.points[0], element.points[1], element.points[2])
        case .closeSubpath: self = .closeSubpath
        @unknown default:
            fatalError("Unknown CGPathElement type")
        }
    }
}
