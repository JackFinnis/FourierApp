//
//  ViewModel.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import SwiftUI
import Vision

class ViewModel: ObservableObject {
    // MARK: - Properties
    @Published var path = Path()
    @Published var pathPoints = [[Double]]()
    @Published var contourPoints: [[Double]]?
    
    @Published var N = 11.0
    @Published var fourierPath: Path?
    @Published var drawing = false
    
    @Published var showInfoView = false
    @Published var showFailedAlert = false
    @Published var showImagePicker = false
    
    var nRange: ClosedRange<Double> {
        var points: [[Double]] {
            if contourPoints == nil {
                return pathPoints
            } else {
                return contourPoints!
            }
        }
        if points.count > 2 {
            return 2...[Double(points.count), 201].min()!
        } else {
            return 2...3
        }
    }
    
    // MARK: - Functions
    func fail() {
        reset()
        showFailedAlert = true
        Haptics.error()
    }
    
    func reset() {
        fourierPath = nil
        contourPoints = nil
        path = Path()
    }
    
    func updatePath() {
        if let contourPoints {
            getTransform(points: contourPoints)
        } else {
            getTransform(points: pathPoints)
        }
    }
    
    func detectContour(image: UIImage) {
        reset()
        if let cgImage = image.cgImage {
            let ciImage = CIImage(cgImage: cgImage)
            
            let contourRequest = VNDetectContoursRequest()
            let requestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: .downMirrored)
            try! requestHandler.perform([contourRequest])
            let contoursObservation = contourRequest.results!.first!
            
            if let contour = contoursObservation.topLevelContours.max(by: { $0.pointCount < $1.pointCount }) {
                let oldWidth = image.size.width
                let oldHeight = image.size.height
                let targetWidth = UIScreen.main.bounds.width
                let targetHeight = UIScreen.main.bounds.height
                
                let padding: CGFloat = 50
                let widthScale = (targetWidth - padding) / oldWidth
                let heightScale = (targetHeight - padding) / oldHeight
                let scale = widthScale < heightScale ? widthScale : heightScale
                
                let newWidth = oldWidth * scale
                let newHeight = oldHeight * scale
                
                let widthOffset = (targetWidth - newWidth)/2
                let heightOffset = (targetHeight - newHeight)/2
                
                contourPoints = contour.normalizedPoints.map { point in
                    let x = Double(CGFloat(point.x) * newWidth + widthOffset)
                    let y = Double(CGFloat(point.y) * newHeight + heightOffset)
                    return [x, y]
                }
            }
        }
        
        if let contourPoints, contourPoints.count > 1 {
            getTransform(points: contourPoints)
            showImagePicker = false
            Haptics.tap()
        } else {
            fail()
        }
    }
    
    func getTransform(points: [[Double]]) {
        N = [N, Double(points.count)].min()!
        let points = Fourier.transform(N: Int(N), points: points)
        fourierPath = Path { newPath in
            newPath.move(to: CGPoint(x: points[0][0], y: points[0][1]))
            for i in 1..<points.count {
                newPath.addLine(to: CGPoint(x: points[i][0], y: points[i][1]))
            }
            newPath.addLine(to: CGPoint(x: points[0][0], y: points[0][1]))
            newPath.addLine(to: CGPoint(x: points[1][0], y: points[1][1]))
        }
    }
}
