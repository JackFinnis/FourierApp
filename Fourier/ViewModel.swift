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
    
    @Published var selectedImage: UIImage?
    @Published var contourPoints: [[Double]]?
    
    @Published var N: Double = 10
    @Published var fourierPath: Path?
    
    @Published var drawing: Bool = false
    @Published var loading: Bool = false
    @Published var recentlyFailed: Bool = false
    @Published var showImagePicker: Bool = false
    
    let fourier = Fourier()
    var nRange: ClosedRange<Double> {
        if contourPoints == nil {
            if pathPoints.count > 2 {
                return 2...Double(pathPoints.count)
            } else {
                return 2...3
            }
        } else {
            if contourPoints!.count > 2 {
                return 2...[Double(contourPoints!.count), 201].min()!
            } else {
                return 2...3
            }
        }
    }
    
    // MARK: - Functions
    func fail() {
        reset()
        recentlyFailed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.recentlyFailed = false
        }
    }
    
    func reset() {
        fourierPath = nil
        selectedImage = nil
        contourPoints = nil
        path = Path()
    }
    
    func updatePath() {
        if contourPoints == nil {
            getTransform(points: pathPoints)
        } else {
            getTransform(points: contourPoints!)
        }
    }
    
    func detectContour() {
        if let cgImage = selectedImage?.cgImage {
            let ciImage = CIImage(cgImage: cgImage)
            
            let contourRequest = VNDetectContoursRequest()
            let requestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: .downMirrored)
            try! requestHandler.perform([contourRequest])
            let contoursObservation = contourRequest.results?.first as! VNContoursObservation
            
            if let contour = contoursObservation.topLevelContours.max(by: { $0.pointCount < $1.pointCount }) {
                let newWidth = UIScreen.main.bounds.width
                let scale = newWidth / selectedImage!.size.width
                let newHeight = selectedImage!.size.height * scale
                let screenHeight = UIScreen.main.bounds.height
                let heightOffset = (screenHeight - newHeight )/2
                
                contourPoints = contour.normalizedPoints.map { point in
                    let width = Double(CGFloat(point.x) * newWidth)
                    let height = Double(CGFloat(point.y) * newHeight + heightOffset)
                    
                    return [width, height]
                }
            }
        }
        
        if contourPoints != nil && contourPoints!.count > 1 {
            getTransform(points: contourPoints!)
        } else {
            fail()
        }
    }
    
    func getTransform(points: [[Double]]) {
        N = [N, Double(points.count)].min()!
        let points = fourier.transform(N: Int(N), points: points)
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
