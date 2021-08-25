//
//  DrawView.swift
//  Fourier
//
//  Created by Jack Finnis on 24/08/2021.
//

import SwiftUI

struct DrawView: View {
    @State var uiImage: UIImage?
    @State var path = Path()
    @State var drawing: Bool = false
    @State var loading: Bool = false
    
    @State var N: Double = 10.0
    @State var pathPoints = []
    
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
                } else if path.isEmpty {
                    Text("Upload a picture of a silhouette or draw a shape with your finger in a closed loop and I will Fourierify it!")
                } else {
                    path.stroke(Color.accentColor, lineWidth: 4)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
            .gesture(drawGesture)
            
            if uiImage != nil {
                VStack {
                    Spacer()
                    HStack {
                        Text("\(Int(N)*2+1) Epicycles")
                        Slider(value: $N, in: 1...20, step: 1, onEditingChanged: { sliding in
                            if !sliding {
                                if selectedImage == nil {
                                    fourierPathTransform()
                                } else {
                                    fourierImgTransform()
                                }
                            }
                        })
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(Capsule())
                    .compositingGroup()
                    .shadow(color: Color(UIColor.systemFill), radius: 5)
                    .padding()
                    .frame(maxWidth: 500)
                }
            }
            
            VStack {
                HStack {
                    if uiImage != nil {
                        Button {
                            UIImageWriteToSavedPhotosAlbum(uiImage!, nil, nil, nil)
                        } label: {
                            Image(systemName: "square.and.arrow.down")
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
                            Image(systemName: "photo")
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
            }
        }
        .sheet(isPresented: $showImagePicker, onDismiss: fourierImgTransform) {
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
                fourierPathTransform()
                drawing = false
            }
    }
    
    func fourierPathTransform() {
        if !pathPoints.isEmpty {
            let json: [String: Any] = ["N": Int(N), "path": pathPoints]
            getTransform(json: json, urlExtension: "path")
        }
    }
    
    func fourierImgTransform() {
        if let selectedImage = selectedImage {
            if let imageData = selectedImage.jpegData(compressionQuality: 0) {
                let json: [String: Any] = ["N": Int(N), "imageData": imageData.base64EncodedString()]
                getTransform(json: json, urlExtension: "img")
            }
        }
    }
    
    func getTransform(json: [String: Any], urlExtension: String) {
        let headers = ["Content-Type": "application/json"]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        let url = URL(string: "https://fourier.finnisjack.repl.co/" + urlExtension)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.allHTTPHeaderFields = headers
        
        loading = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            loading = false
            if let data = data {
                uiImage = UIImage(data: data)
                return
            }
            print(error?.localizedDescription ?? "No data")
        }.resume()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
