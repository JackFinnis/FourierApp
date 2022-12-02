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
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                ZStack {
                    Color(.quaternarySystemFill)
                        .ignoresSafeArea()
                    
                    (vm.fourierPath ?? vm.drawingPath).stroke(Color.accentColor, lineWidth: 3)
                }
                .gesture(drawGesture)
                
                Group {
                    if !vm.drawing, let message = vm.infoMessage {
                        HStack {
                            Text(message)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                        .background(Color(.systemBackground))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.default, value: vm.N)
            }
            ActionBar()
        }
        .fileImporter(isPresented: $vm.showSVGImporter, allowedContentTypes: [.svg], onCompletion: vm.loadSVG)
        .environmentObject(vm)
        .sheet(isPresented: $vm.showImagePicker) {
            ImagePicker() { image in
                vm.detectContour(in: image)
            }
            .alert(isPresented: $vm.showImageFailedAlert) {
                Alert(title: Text("Import Failed"), message: Text("I was unable to find a contour in this image. Please select a different silhouette."))
            }
        }
        .alert(isPresented: $vm.showSVGFailedAlert) {
            Alert(title: Text("Import Failed"), message: Text("I was unable to import this svg file. Please select a different file."))
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
                let newPoint = (Double(value.location.x), Double(value.location.y))
                
                if vm.drawing {
                    vm.points.append(newPoint)
                } else {
                    vm.drawing = true
                    
                    vm.reset()
                    vm.drawingPath.move(to: value.startLocation)
                    vm.points = [newPoint]
                    Haptics.tap()
                }
                
                vm.drawingPath.addLine(to: value.location)
            }
            .onEnded { _ in
                vm.drawing = false
                
                if vm.points.count > 1 {
                    vm.getTransform()
                } else {
                    vm.fail()
                }
            }
    }
}
