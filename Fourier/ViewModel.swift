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
    @Published var drawing = false
    
    @Published var fourierPath: Path?
    @Published var points = [CGPoint]()
    @Published var N = 11.0
    
    @Defaults(key: "components", defaultValue: [CGFloat]()) var components
    @Published var strokeColour: Color { didSet {
        components = strokeColour.cgColor?.components ?? []
    }}
    
    @Published var showInfoView = false
    @Published var showSVGImporter = false
    @Published var showImagePicker = false
    
    @Published var showErrorAlert = false
    @Published var error = FourierError.image
    
    @Published var savedImage = false
    @Published var copiedCoefficients = false
    @Published var showingExample = false
    
    var nRange: ClosedRange<Double> {
        2...[[3, Double(points.count)].max()!, 501].min()!
    }
    var infoMessage: String? {
        switch N {
        case 501:
            return points.isEmpty ? nil : "Using more than 500 epicycles makes calculations quite slow!"
        case Double(points.count):
            return "A curve with n points is perfectly approximated using n epicycles."
        default:
            return nil
        }
    }
    
    init() {
        let components = UserDefaults.standard.object(forKey: "components") as? [CGFloat] ?? [0, 0.5, 1, 1]
        strokeColour = Color(UIColor(cgColor: CGColor(colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!, components: components) ?? CGColor(red: 0, green: 0.5, blue: 1, alpha: 1)))
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
        showingExample = false
    }
    
    func showExampleSquiggle() {
        if let url = Bundle.main.url(forResource: "fourier", withExtension: "svg") {
            showingExample = true
            importSVG(result: .success(url))
            showingExample = true
        }
    }
    
    func importSVG(result: Result<URL, Error>) {
        switch result {
        case .failure(_):
            fail(error: .downloadSvg)
        case .success(let url):
            if !showingExample {
                guard url.startAccessingSecurityScopedResource()
                else { fail(error: .accessSvg); return }
            }
            
            let svgPaths = SVGBezierPath.pathsFromSVG(at: url)
            url.stopAccessingSecurityScopedResource()
            
            guard let svgPath = svgPaths.first
            else { fail(error: .parseSvg); return }
            
            if svgPaths.count > 1 {
                error = .multiplePaths
                showErrorAlert = true
            }
            
            let points = scale(svgPath.cgPath.equallySpacedPoints)
            newPoints(points, error: .svg)
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
        
        let points = contour.normalizedPoints.map { CGPointMake(CGFloat($0.x), CGFloat($0.y)) }
        newPoints(scale(points), error: .image)
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
        let targetWidth = UIScreen.main.bounds.width
        let targetHeight = UIScreen.main.bounds.height - 140
        
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
    
    func newPoints(_ points: [CGPoint], error: FourierError? = nil) {
        guard points.count >= 2
        else { fail(error: error); return }
        
        reset()
        self.points = points
        transform()
        Haptics.tap()
        showingExample = false
    }
    
    func transform() {
        N = [N, Double(points.count)].min()!
        savedImage = false
        copiedCoefficients = false
        
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
