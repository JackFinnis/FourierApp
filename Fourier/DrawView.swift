//
//  DrawView.swift
//  Fourier
//
//  Created by Jack Finnis on 24/08/2021.
//

import SwiftUI
import Vision

struct Line: View {
    @AppStorage("boldLines") var boldLines = true
    @EnvironmentObject var vm: ViewModel
    
    var body: some View {
        if let path = vm.drawingPath ?? vm.fourierPath {
            path.stroke(vm.strokeColour, style: StrokeStyle(lineWidth: boldLines ? 3 : 2, lineCap: .round, lineJoin: .round))
        }
    }
}

struct DrawView: View {
    @AppStorage("launchedBefore") var launchedBefore = false
    @State var firstLaunch = false
    @StateObject var vm = ViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ZStack {
                    Color(.quaternarySystemFill)
                        .ignoresSafeArea()
                    Line()
                }
                .gesture(drawGesture)
                
                VStack {
                    Spacer()
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
                
                Text("")
                    .sheet(isPresented: $vm.showInfoView, onDismiss: {
                        firstLaunch = false
                    }) {
                        InfoView(firstLaunch: firstLaunch)
                    }
                Text("")
                    .sheet(isPresented: $vm.showImagePicker) {
                        ImagePicker(completion: vm.importImage)
                    }
            }
            ActionBar()
        }
        .fileImporter(isPresented: $vm.showSVGImporter, allowedContentTypes: [.svg], onCompletion: vm.importSVG)
        .alert(isPresented: $vm.showErrorAlert) {
            Alert(title: Text(vm.error == .multiplePaths ? "SVG Loaded" : "Import Failed"), message: Text(vm.error.rawValue))
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
                let point = value.location
                
                if vm.drawing {
                    vm.drawingPath?.addLine(to: point)
                } else {
                    vm.drawing = true
                    vm.drawingPath = Path()
                    vm.drawingPath?.move(to: point)
                }
            }
            .onEnded { _ in
                vm.drawing = false
                let points = vm.drawingPath?.cgPath.equallySpacedPoints ?? []
                vm.newPoints(points)
                vm.drawingPath = nil
            }
    }
}
