//
//  DrawView.swift
//  Fourier
//
//  Created by Jack Finnis on 24/08/2021.
//

import SwiftUI
import Vision

struct DrawView: View {
    @StateObject var vm = ViewModel()
    
    var body: some View {
        ZStack {
            ZStack {
                Color(.quaternarySystemFill)
                    .ignoresSafeArea()
                
                if vm.fourierPath != nil {
                    vm.fourierPath!.stroke(Color.accentColor, lineWidth: 3)
                } else if vm.path.isEmpty {
                    Text("Draw a closed loop over this text with your finger or upload a picture of a silhouette and I will transform it into a Fourier epicycle drawing!")
                        .padding(.horizontal)
                } else {
                    vm.path.stroke(Color.accentColor, lineWidth: 3)
                }
            }
            .gesture(drawGesture)
            
            VStack {
                HStack {
                    Spacer()
                    PhotoButton()
                }
                Spacer()
                if vm.fourierPath != nil {
                    HStack {
                        Spacer(minLength: 16)
                        UpdateNBar()
                            .frame(maxWidth: 450)
                    }
                }
            }
        }
        .environmentObject(vm)
        .sheet(isPresented: $vm.showImagePicker, onDismiss: vm.detectContour) {
            ImagePicker(image: $vm.selectedImage)
        }
    }
    
    var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let newPoint = [Double(value.location.x), Double(value.location.y)]
                
                if vm.drawing {
                    vm.pathPoints.append(newPoint)
                } else {
                    vm.drawing = true
                    
                    vm.reset()
                    vm.path.move(to: value.startLocation)
                    vm.pathPoints = [newPoint]
                }
                
                vm.path.addLine(to: value.location)
            }
            .onEnded { _ in
                vm.drawing = false
                
                if vm.pathPoints.count > 1 {
                    vm.getTransform(points: vm.pathPoints)
                } else {
                    vm.fail()
                }
            }
    }
}
