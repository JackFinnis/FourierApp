//
//  DrawView.swift
//  Fourier
//
//  Created by Jack Finnis on 24/08/2021.
//

import SwiftUI
import Vision

struct DrawView: View {
    @State var path: Path?
    @State var fourierPath: Path?
    
    @State var drawing: Bool = false
    @State var loading: Bool = false
    @State var recentlyFailed: Bool = false
    
    @State var N: Double = 2
    @State var pathPoints = [[CGFloat]]()
    
    @State var selectedImage: UIImage?
    @State var showImagePicker: Bool = false
    
    var body: some View {
        ZStack {
            ZStack {
                Color(UIColor.systemBackground)
                
                if uiImage != nil {
                    Image(uiImage: uiImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.vertical, 100)
                } else if path.isEmpty {
                    Text("Upload a picture of a silhouette or draw a shape with your finger in a closed loop and I will transform it into a Fourier epicycle drawing!")
                        .padding(.horizontal)
                } else {
                    path.stroke(Color.accentColor, lineWidth: 4)
                }
            }
            .gesture(drawGesture)
            
            VStack {
                HStack {
                    if uiImage != nil {
                        Button {
                            recentlySaved = true
                            UIImageWriteToSavedPhotosAlbum(uiImage!, nil, nil, nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                self.recentlySaved = false
                            }
                        } label: {
                            Image(systemName: recentlySaved ? "checkmark" : "square.and.arrow.down")
                                .font(.system(size: 25))
                                .frame(width: 60, height: 60)
                                .background(Color(UIColor.systemBackground))
                                .clipShape(Circle())
                                .compositingGroup()
                                .shadow(color: Color(UIColor.systemFill), radius: 5)
                                .padding()
                        }
                    }
                    
                    Spacer()
                    Button {
                        showImagePicker = true
                    } label: {
                        if loading {
                            ProgressView()
                                .font(.system(size: 25))
                                .frame(width: 60, height: 60)
                        } else {
                            Image(systemName: recentlyFailed ? "xmark" : "photo")
                                .font(.system(size: 25))
                                .frame(width: 60, height: 60)
                        }
                    }
                    .background(Color(UIColor.systemBackground))
                    .clipShape(Circle())
                    .compositingGroup()
                    .shadow(color: Color(UIColor.systemFill), radius: 5)
                    .padding()
                }
                Spacer()
                
                if uiImage != nil {
                    VStack {
                        HStack {
                            Text("\(Int(N)-1) Epicycles")
                            Spacer()
                            Stepper("", value: $N, in: 2...200, onEditingChanged: { stepping in
                                if !stepping {
                                    if selectedImage == nil {
                                        transformPath()
                                    } else {
                                        transformImage()
                                    }
                                }
                            })
                        }
                        
                        Slider(value: $N, in: 2...200, step: 1, onEditingChanged: { sliding in
                            if !sliding {
                                if selectedImage == nil {
                                    transformPath()
                                } else {
                                    transformImage()
                                }
                            }
                        })
                    }
                    .frame(maxWidth: 500)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(20)
                    .compositingGroup()
                    .shadow(color: Color(UIColor.systemFill), radius: 5)
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showImagePicker, onDismiss: transformImage) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let newPoint = [value.location.x, value.location.y]
                
                if drawing {
                    pathPoints.append(newPoint)
                } else {
                    drawing = true
                    uiImage = nil
                    selectedImage = nil
                    
                    path = Path()
                    path.move(to: value.startLocation)
                    pathPoints = [newPoint]
                }
                
                path.addLine(to: value.location)
            }
            .onEnded { _ in
                transformPath()
                drawing = false
            }
    }
    
    func transformPath() {
        if !pathPoints.isEmpty {
            getTransform(points: pathPoints)
        }
    }
    
    func transformImage() {
        if let points = detectContour() {
            getTransform(points: points)
        }
    }
    
    func detectContour() -> [[CGFloat]]? {
        if let image = selectedImage {
            let scale = image.size.width / UIScreen.main.bounds.width
            let scaledWidth = image.size.width * scale
            let scaledHeight = image.size.height * scale
            let scaledSize = CGSize(width: scaledWidth, height: scaledHeight)
            let scaledImage = image.scaleImage(toSize: scaledSize)
            
            if let cgImage = scaledImage?.cgImage {
                let ciImage = CIImage(cgImage: cgImage)
                let contourRequest = VNDetectContoursRequest()
                let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
                
                try! requestHandler.perform([contourRequest])
                let contoursObservation = contourRequest.results?.first as! VNContoursObservation
                
                if let contour = contoursObservation.topLevelContours.max(by: { $0.pointCount < $1.pointCount }) {
                    return contour.normalizedPoints.map { point in
                        let width = CGFloat(point.x) * image.size.width
                        let height = CGFloat(point.y) * image.size.height
                        
                        return [width, height]
                    }
                }
            }
        }
        return nil
    }
    
    func getTransform(points: [[CGFloat]]) {
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
            loading = false
            if let data = data {
                if let response = try? JSONDecoder().decode(Response.self, from: data) {
                    path = Path { newPath in
                        newPath.move(to: CGPoint(x: response.x[0], y: response.y[0]))
                        for i in 0..<response.x.count {
                            newPath.addLine(to: CGPoint(x: response.x[i], y: response.y[i]))
                        }
                    }
                    loading = false
                }
            }
            recentlyFailed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.recentlyFailed = false
            }
        }.resume()
    }
    
    
//    func oldFourierPathTransform() {
//        if !pathPoints.isEmpty {
//            let json: [String: Any] = ["N": Int(N), "path": pathPoints]
//            getTransform(json: json, urlExtension: "path")
//        }
//    }
//
//    func oldFourierImgTransform() {
//        if let selectedImage = selectedImage {
////            let contourPoints = detectContour(image: selectedImage)
////            let json: [String: Any] = ["N": Int(N), "path": contourPoints]
////            getTransform(json: json, urlExtension: "")
//
//            if let imageData = selectedImage.jpegData(compressionQuality: 0) {
//                let json: [String: Any] = ["N": Int(N), "imageData": imageData.base64EncodedString()]
//                getTransform(json: json, urlExtension: "img")
//            }
//        }
//    }
}
