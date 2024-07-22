//
//  ViewModel.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import SwiftUI
import Vision
import VectorPlus
import SwiftSVG

@Observable
class Model {
    var isSaved = false
    var showFileImporter = false
    var isDrawing = false
    var path: SwiftUI.Path?
    var epicycles = 10.0
    private var points = [CGPoint]()
    
    var nRange: ClosedRange<Double> {
        1...min(Double(max(points.count, 1)), 500)
    }
    
    func reset() {
        epicycles = 10.0
        path = nil
        points = []
    }
    
    @MainActor
    func save(path: SwiftUI.Path, size: CGSize) {
        let renderer = ImageRenderer(content: PathRenderer(path: path))
        renderer.proposedSize = .init(size)
        renderer.scale = 3
        guard let uiImage = renderer.uiImage else { return }
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        Haptics.tap()
    }
    
    func importSVG(result: Result<URL, Error>, size: CGSize) {
        switch result {
        case .failure(_): break
        case .success(let url):
            do {
                _ = url.startAccessingSecurityScopedResource()
                let svg = try SVG.make(from: url)
                url.stopAccessingSecurityScopedResource()
                
                let cgPath = svg.path(size: .init(size))
                let points = cgPath.copy(dashingWithPhase: 0, lengths: [2]).points
                let scaledPoints = scale(points: points, size: size)
                transform(points: scaledPoints)
            } catch {
                print(error)
                return
            }
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
        #if os(iOS)
        targetHeight -= Constants.actionBarHeight
        #endif

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
        isSaved = false
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
