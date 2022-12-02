//
//  ViewModel.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import SwiftUI
import Vision
import PocketSVG

enum FourierError: String {
    case downloadSvg = "I was unable to import this svg file. Please ensure it is downloaded from iCloud and try again."
    case accessSvg = "I was unable to access this svg file. Please ensure you have sufficient permission and try again."
    case parseSvg = "I was unable to parse this svg file. Please ensure it is in a valid format and try again."
    case svg = "I was unable to squigglify this svg file. Please try using a different file."
    case multiplePaths = "This svg file has multiple paths. Only the first will be displayed."
    case image = "I was unable to squigglify this silhouette. Please try using a different image."
    case contour = "I was unable to find a contour in this silhouette. Please try using a different image."
    case loadImage = "I was unable to import this image. Please ensure it is downloaded from iCloud and try again."
}

class ViewModel: ObservableObject {
    // MARK: - Properties
    @Published var drawingPath: Path?
    @Published var drawingPoints = [(Double, Double)]()
    
    @Published var fourierPath: Path?
    @Published var points = [(Double, Double)]()
    
    @Published var N = 11.0
    @Published var drawing = false
    @Published var strokeColour = Color.accentColor
    
    @Published var showInfoView = false
    @Published var showSVGImporter = false
    @Published var showImagePicker = false
    
    @Published var showErrorAlert = false
    @Published var error = FourierError.image
    
    @Published var savedImage = false
    @Published var copiedCoefficients = false
    
    var nRange: ClosedRange<Double> {
        2...[[3, Double(points.count)].max()!, 501].min()!
    }
    var infoMessage: String? {
        switch N {
        case 501:
            return "Using any more than 500 epicycles makes calculations quite slow!"
        case Double(points.count):
            return "A curve with n points is perfectly approximated using n epicycles."
        default:
            return nil
        }
    }
    
    // MARK: - Functions
    func fail(error: FourierError? = nil) {
        if let error {
            Haptics.error()
            self.error = error
            showErrorAlert = true
        }
    }
    
    func reset() {
        points = []
        fourierPath = nil
        drawingPath = nil
        savedImage = false
        copiedCoefficients = false
    }
    
    func showExampleSquiggle() {
        importSVG(result: Result<URL, Error>.success(SAMPLE_URL))
    }
    
    func importSVG(result: Result<URL, Error>) {
        switch result {
        case .failure(_):
            fail(error: .downloadSvg)
        case .success(let url):
            guard url.startAccessingSecurityScopedResource()
            else { fail(error: .accessSvg); return }
            
            let svgPaths = SVGBezierPath.pathsFromSVG(at: url)
            url.stopAccessingSecurityScopedResource()
            
            guard let svgPath = svgPaths.first
            else { fail(error: .parseSvg); return }
            
            if svgPaths.count > 1 {
                error = .multiplePaths
                showErrorAlert = true
            }
            
            let points = Path(svgPath.cgPath).getPoints()
            newPoints(scale(points), error: .svg)
        }
    }
    
    func importImage(image: UIImage?) {
        guard let cgImage = image?.cgImage
        else { fail(error: .loadImage); return }
        
        let contourRequest = VNDetectContoursRequest()
        let requestHandler = VNImageRequestHandler(ciImage: CIImage(cgImage: cgImage), orientation: .downMirrored)
        try? requestHandler.perform([contourRequest])
        
        guard let contours = contourRequest.results?.first,
              let contour = contours.topLevelContours.max(by: { $0.pointCount < $1.pointCount })
        else { fail(error: .contour); return }
        
        let points = contour.normalizedPoints.map { (Double($0.x), Double($0.y)) }
        newPoints(scale(points), error: .image)
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
        let targetHeight = UIScreen.main.bounds.height - 150
        
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
    
    func newPoints(_ points: [(Double, Double)], error: FourierError? = nil) {
        guard points.count >= 2
        else { fail(error: error); return }
        
        reset()
        self.points = points
        transform()
        Haptics.tap()
    }
    
    func transform() {
        N = [N, Double(points.count)].min()!
        savedImage = false
        copiedCoefficients = false
        
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
