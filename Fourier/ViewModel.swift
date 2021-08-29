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
            for i in 0..<points.count {
                newPath.addLine(to: CGPoint(x: points[i][0], y: points[i][1]))
            }
            newPath.addLine(to: CGPoint(x: points[0][0], y: points[0][1]))
            newPath.addLine(to: CGPoint(x: points[1][0], y: points[1][1]))
        }
    }
    
    func oldGetTransform(points: [[Double]]) {
        N = [N, Double(points.count)].min()!
        
        let headers = ["Content-Type": "application/json"]
        let json: [String: Any] = ["N": Int(N), "path": points]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        let url = URL(string: "https://fourier.finnisjack.repl.co")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.allHTTPHeaderFields = headers
        
        loading = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let response = try? JSONDecoder().decode(Response.self, from: data) {
                    let newPath = Path { newPath in
                        newPath.move(to: CGPoint(x: response.x[0], y: response.y[0]))
                        for i in 0..<response.x.count {
                            newPath.addLine(to: CGPoint(x: response.x[i], y: response.y[i]))
                        }
                        newPath.addLine(to: CGPoint(x: response.x[0], y: response.y[0]))
                    }
                    DispatchQueue.main.async {
                        self.loading = false
                        self.fourierPath = newPath
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                self.loading = false
                self.fail()
            }
        }.resume()
    }
}
