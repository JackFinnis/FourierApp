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
    
    @State var N: Double = 10.0
    @State var pathPoints = []
    
    var body: some View {
        ZStack {
            ZStack {
                Color(UIColor.systemBackground)
                
                if path.isEmpty {
                    Text("Draw a shape with your finger in a closed loop and I will Fourierify it!")
                } else if uiImage != nil {
                    Image(uiImage: uiImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
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
                            if !sliding { getFourierTransform() }
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
                    
                    path = Path()
                    path.move(to: value.startLocation)
                    pathPoints = [newPoint]
                }
                
                path.addLine(to: value.location)
            }
            .onEnded { _ in
                getFourierTransform()
                drawing = false
            }
    }
    
    func getFourierTransform() {
        let headers = ["Content-Type": "application/json"]
        let json: [String: Any] = ["N": Int(N), "path": pathPoints]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        let url = URL(string: "https://FourierTransform.finnisjack.repl.co")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.allHTTPHeaderFields = headers
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                uiImage = UIImage(data: data)
                return
            }
            print(error?.localizedDescription ?? "No data")
        }.resume()
    }
}
