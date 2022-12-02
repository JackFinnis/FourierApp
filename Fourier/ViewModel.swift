//
//  ViewModel.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import SwiftUI
import Vision
import PocketSVG

class ViewModel: ObservableObject {
    // MARK: - Properties
    @Published var drawingPath = Path()
    @Published var points = [(Double, Double)]()
    
    @Published var N = 11.0
    @Published var fourierPath: Path?
    @Published var drawing = false
    
    @Published var showInfoView = false
    @Published var showSVGFailedAlert = false
    @Published var showSVGImporter = false
    @Published var showImageFailedAlert = false
    @Published var showImagePicker = false
    
    @Published var savedImage = false
    @Published var copiedCoefficients = false
    @Published var infoMessage: String?
    
    var nRange: ClosedRange<Double> {
        if points.count > 2 {
            return 2...[Double(points.count), 501].min()!
        } else {
            return 2...3
        }
    }
    
    // MARK: - Functions
    func fail() {
        reset()
        Haptics.error()
    }
    
    func reset() {
        points = []
        fourierPath = nil
        drawingPath = Path()
    }
    
    func loadSVG(result: Result<URL, Error>) {
        func failSVG() {
            showSVGFailedAlert = true
            fail()
        }
        
        switch result {
        case .failure(_):
            failSVG()
        case .success(let url):
            guard url.startAccessingSecurityScopedResource()
            else { failSVG(); return }
            
            let svgPaths = SVGBezierPath.pathsFromSVG(at: url)
            url.stopAccessingSecurityScopedResource()
            
            if let svgPath = svgPaths.first {
                let points = Path(svgPath.cgPath).getPoints()
                self.points = scale(points)
                print(self.points[100])
                print(self.points[200])
                print(self.points[300])
                getTransform()
            } else {
                failSVG()
            }
        }
    }
    
    func scale(_ points: [(Double, Double)]) -> [(Double, Double)] {
        let xs = points.compactMap { $0.0 }
        let ys = points.compactMap { $0.1 }
        
        let minx = xs.min() ?? 0
        let miny = ys.min() ?? 0
        let maxx = xs.max() ?? 0
        let maxy = ys.max() ?? 0
        
        let shifted = points.map { x, y in
            (x-minx, y-miny)
        }
        
        let oldWidth = maxx - minx
        let oldHeight = maxy - miny
        let targetWidth = UIScreen.main.bounds.width
        let targetHeight = UIScreen.main.bounds.height - 80
        
        let padding: CGFloat = 50
        let widthScale = (targetWidth - padding) / oldWidth
        let heightScale = (targetHeight - padding) / oldHeight
        let scale = widthScale < heightScale ? widthScale : heightScale
        
        let newWidth = oldWidth * scale
        let newHeight = oldHeight * scale
        let widthOffset = (targetWidth - newWidth)/2
        let heightOffset = (targetHeight - newHeight)/2
        
        return shifted.map { x, y in
            (x * scale + widthOffset, y * scale + heightOffset)
        }
    }
    
    func detectContour(in image: UIImage) {
        reset()
        if let cgImage = image.cgImage {
            let ciImage = CIImage(cgImage: cgImage)
            
            let contourRequest = VNDetectContoursRequest()
            let requestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: .downMirrored)
            try! requestHandler.perform([contourRequest])
            let contoursObservation = contourRequest.results!.first!
            
            if let contour = contoursObservation.topLevelContours.max(by: { $0.pointCount < $1.pointCount }) {
                let points = contour.normalizedPoints.map { (Double($0.x), Double($0.y)) }
                self.points = scale(points)
                print(points.count)
                getTransform()
            }
        }
        
        if points.count > 1 {
            getTransform()
            showImagePicker = false
            Haptics.tap()
        } else {
            fail()
            showImageFailedAlert = true
        }
    }
    
    func getTransform() {
        savedImage = false
        copiedCoefficients = false
        switch N {
        case 501:
            infoMessage = "Using any more than 500 epicycles makes calculations quite slow!"
        case Double(points.count):
            infoMessage = "A curve with n points is perfectly approximated using n epicycles."
        default:
            infoMessage = nil
        }
        
        N = [N, Double(points.count)].min()!
        let points = Fourier.transform(N: Int(N), points: points)
        fourierPath = Path { newPath in
            newPath.move(to: CGPoint(x: points[0].0, y: points[0].1))
            for i in 1..<points.count {
                newPath.addLine(to: CGPoint(x: points[i].0, y: points[i].1))
            }
            newPath.addLine(to: CGPoint(x: points[0].0, y: points[0].1))
            newPath.addLine(to: CGPoint(x: points[1].0, y: points[1].1))
        }
    }
    
    func copyCoefficients() {
        let coefficients = Fourier.getCoefficients(N: Int(N), points: points)
        var string = "rotations per second (anticlockwise),radius,initial angle (radians)\n"
        string += coefficients.map { n, r, a in
            "\(n),\(r),\(a)"
        }.joined(separator: "\n")
        
        UIPasteboard.general.string = string
        Haptics.success()
        copiedCoefficients = true
    }
}

// tab: \u{9}
// new line: \u{A}
