//
//  ViewModel.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import SwiftUI
import Vision
import PocketSVG

class Model: ObservableObject {
    @Published var isDrawing = false
    @Published var path: Path?
    @Published var epicycles = 10.0
    private var points = [CGPoint]()
    
    var nRange: ClosedRange<Double> {
        1...min(Double(max(points.count, 1)), 500)
    }
    
    func reset() {
        epicycles = 10.0
        path = nil
        points = []
    }
    
    func importSVG(result: Result<URL, Error>, size: CGSize) {
        switch result {
        case .failure(_): break
        case .success(let url):
            _ = url.startAccessingSecurityScopedResource()
            let svgPaths = SVGBezierPath.pathsFromSVG(at: url)
            url.stopAccessingSecurityScopedResource()
            
            guard let svgPath = svgPaths.first else { return }
            let points = scale(points: svgPath.cgPath.equallySpacedPoints, size: size)
            transform(points: points)
        }
    }
    
    func scale(points: [CGPoint], size: CGSize) -> [CGPoint] {
        let xs = points.compactMap { $0.x }
        let ys = points.compactMap { $0.y }

        let minx = xs.min() ?? 0
        let miny = ys.min() ?? 0
        let maxx = xs.max() ?? 0
        let maxy = ys.max() ?? 0

        let transform = CGAffineTransform(translationX: -minx, y: -miny)
        let shifted = points.map { point in
            point.applying(transform)
        }

        let oldWidth = maxx - minx
        let oldHeight = maxy - miny

        let targetWidth = size.width
        var targetHeight = size.height
        targetHeight -= Constants.actionBarHeight

        let padding: CGFloat = 50
        let widthScale = (targetWidth - padding) / oldWidth
        let heightScale = (targetHeight - padding) / oldHeight
        let scale = widthScale < heightScale ? widthScale : heightScale

        let newWidth = oldWidth * scale
        let newHeight = oldHeight * scale
        let widthOffset = (targetWidth - newWidth)/2
        let heightOffset = (targetHeight - newHeight)/2

        return shifted.map { point in
            CGPointMake(point.x * scale + widthOffset, point.y * scale + heightOffset)
        }
    }
    
    func transform(points: [CGPoint]) {
        reset()
        guard points.count > 1 else { return }
        self.points = points
        update()
    }
    
    func update() {
        Haptics.tap()
        epicycles = min(epicycles, Double(points.count))
        let points = Fourier.transform(N: Int(epicycles), points: points)
        path = Path { path in
            path.move(to: CGPoint(x: points[0].x, y: points[0].y))
            for i in 1..<points.count {
                path.addLine(to: CGPoint(x: points[i].x, y: points[i].y))
            }
            path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
            path.closeSubpath()
        }
    }
}

#Preview {
    RootView()
}
