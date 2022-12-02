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
    @AppStorage("boldLines") var boldLines = true
    @State var firstLaunch = false
    @StateObject var vm = ViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                ZStack {
                    Color(.quaternarySystemFill)
                        .ignoresSafeArea()
                    
                    if let path = vm.drawingPath ?? vm.fourierPath {
                        path.stroke(vm.strokeColour, lineWidth: boldLines ? 3 : 2)
                    }
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
                .fileImporter(isPresented: $vm.showSVGImporter, allowedContentTypes: [.svg], onCompletion: vm.importSVG)
        }
        .sheet(isPresented: $vm.showImagePicker) {
            ImagePicker(completion: vm.importImage)
        }
        .alert(isPresented: $vm.showErrorAlert) {
            Alert(title: Text("Squigglification Failed"), message: Text(vm.error.rawValue))
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
        .environmentObject(vm)
    }
    
    var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let newPoint = (Double(value.location.x), Double(value.location.y))
                
                if vm.drawing {
                    vm.drawingPoints.append(newPoint)
                    vm.drawingPath?.addLine(to: value.location)
                } else {
                    vm.drawing = true
                    vm.drawingPath = Path()
                    vm.drawingPath?.move(to: value.startLocation)
                    vm.drawingPoints = [newPoint]
                }
            }
            .onEnded { _ in
                vm.drawing = false
                vm.drawingPath = nil
                vm.newPoints(vm.drawingPoints)
            }
    }
}
