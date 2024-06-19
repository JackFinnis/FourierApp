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
    var path: Path? { drawingPath ?? fourierPath }
    
    @Published var drawingPath: Path?
    @Published var isDrawing = false
    
    @Published var fourierPath: Path?
    @Published var points = [CGPoint]()
    @Published var N = 11.0
    
    @Published var showingExample = false
    
    var nRange: ClosedRange<Double> {
        2...[[3, Double(points.count)].max()!, 501].min()!
    }
    
    func reset() {
        points = []
        fourierPath = nil
        drawingPath = nil
        showingExample = false
    }
    
    func showExampleSquiggle() {
        let url = Bundle.main.url(forResource: "fourier", withExtension: "svg")!
        showingExample = true
        importSVG(result: .success(url))
        showingExample = true
    }
    
    func importSVG(result: Result<URL, Error>) {
        switch result {
        case .failure(_): break
        case .success(let url):
            if !showingExample {
                guard url.startAccessingSecurityScopedResource() else { return }
            }
            
            let svgPaths = SVGBezierPath.pathsFromSVG(at: url)
            url.stopAccessingSecurityScopedResource()
            
            guard let svgPath = svgPaths.first else { return }
            
            let points = svgPath.cgPath.equallySpacedPoints
            newPoints(scale(points))
        }
    }
    
    func importImage(image: UIImage?) {
        guard let cgImage = image?.cgImage else { return }
        
        let contourRequest = VNDetectContoursRequest()
        let requestHandler = VNImageRequestHandler(ciImage: CIImage(cgImage: cgImage), orientation: .downMirrored)
        try? requestHandler.perform([contourRequest])
        
        guard let contours = contourRequest.results?.first,
              let contour = contours.topLevelContours.max(by: { $0.pointCount < $1.pointCount })
        else { return }
        
        let points = contour.normalizedPoints.map { CGPointMake(CGFloat($0.x), CGFloat($0.y)) }
        
        let n = points.count / 500
        let shortened = points.getEveryNthElement(n: n)
        
        newPoints(scale(shortened))
    }
    
    func scale(_ points: [CGPoint]) -> [CGPoint] {
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

        let targetWidth: CGFloat
        var targetHeight: CGFloat
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            let frame = window.safeAreaLayoutGuide.layoutFrame
            targetWidth = frame.width
            targetHeight = frame.height
        } else {
            targetWidth = UIScreen.main.bounds.width
            targetHeight = UIScreen.main.bounds.height
        }
        // Height of ActionBar
        targetHeight -= 90

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
    
    func newPoints(_ points: [CGPoint]) {
        guard points.count >= 2 else { return }
        
        reset()
        self.points = points
        transform()
        Haptics.tap()
        showingExample = false
    }
    
    func transform() {
        N = [N, Double(points.count)].min()!
        
        let points = Fourier.transform(N: Int(N), points: points)
        fourierPath = Path { path in
            path.move(to: CGPoint(x: points[0].x, y: points[0].y))
            for i in 1..<points.count {
                path.addLine(to: CGPoint(x: points[i].x, y: points[i].y))
            }
            path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
            path.closeSubpath()
        }
    }
}
