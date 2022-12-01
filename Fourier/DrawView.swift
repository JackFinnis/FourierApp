//
//  DrawView.swift
//  Fourier
//
//  Created by Jack Finnis on 24/08/2021.
//

import SwiftUI
import Vision

struct DrawView: View {
    @AppStorage("launchedBefore") var launchedBefore = false
    @State var firstLaunch = false
    @StateObject var vm = ViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                Color(.quaternarySystemFill)
                    .ignoresSafeArea()
                
                if let path = vm.fourierPath {
                    path.stroke(Color.accentColor, lineWidth: 3)
                } else {
                    vm.path.stroke(Color.accentColor, lineWidth: 3)
                }
            }
            .gesture(drawGesture)
            
            ActionBar()
        }
        .environmentObject(vm)
        .sheet(isPresented: $vm.showImagePicker) {
            ImagePicker() { image in
                vm.detectContour(image: image)
            }
            .alert(isPresented: $vm.showFailedAlert) {
                Alert(title: Text("Oops"), message: Text("I was unable to find a contour in this image. Please select a different silhouette"))
            }
        }
        .sheet(isPresented: $vm.showInfoView, onDismiss: {
            firstLaunch = false
        }) {
            InfoView(firstLaunch: firstLaunch)
        }
        .onAppear {
            if !launchedBefore {
                launchedBefore = true
                firstLaunch = true
                vm.showInfoView = true
            }
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
                    Haptics.tap()
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
