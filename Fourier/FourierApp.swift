//
//  FourierApp.swift
//  Fourier
//
//  Created by Jack Finnis on 24/08/2021.
//

import SwiftUI

@main
struct FourierApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @StateObject var model = Model()
    @State var showFileImporter = false
    
    var body: some View {
        GeometryReader { geo in
            Color(.systemGray6)
                .ignoresSafeArea()
                .gesture(drawGesture)
                .overlay {
                    if let path = model.path {
                        PathRenderer(path: path)
                    } else {
                        Image(systemName: "hand.draw")
                            .font(.largeTitle)
                            .imageScale(.large)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 50)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(alignment: .bottom) {
                    ZStack {
                        if model.isDrawing {
                        } else if let path = model.path {
                            VStack(spacing: 5) {
                                HStack(spacing: 15) {
                                    Text(Int(model.epicycles).formatted(singular: "Epicycle"))
                                        .monospacedDigit()
                                    Spacer()
                                    Stepper("", value: $model.epicycles, in: model.nRange) { isStepping in
                                        if !isStepping { model.update() }
                                    }
                                    .labelsHidden()
                                    Menu {
                                        Button(role: .destructive) {
                                            model.reset()
                                        } label: {
                                            Label("Reset", systemImage: "xmark")
                                        }
                                        Button {
                                            let renderer = ImageRenderer(content: PathRenderer(path: path))
                                            renderer.proposedSize = .init(geo.size)
                                            renderer.scale = 3
                                            guard let uiImage = renderer.uiImage else { return }
                                            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                                            Haptics.tap()
                                        } label: {
                                            Label("Save to Photos", systemImage: "square.and.arrow.down")
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.title2)
                                    }
                                }
                                Slider(value: $model.epicycles, in: model.nRange, step: 1) { isSliding in
                                    if !isSliding { model.update() }
                                }
                            }
                        } else {
                            HStack(spacing: 15) {
                                Button("Import SVG File") {
                                    showFileImporter = true
                                }
                                .buttonStyle(.borderedProminent)
                                Button("See Example") {
                                    model.importSVG(result: .success(Constants.fourierURL), size: geo.size)
                                }
                                .buttonStyle(.bordered)
                            }
                            .menuStyle(.button)
                            .buttonBorderShape(.capsule)
                            .font(.headline)
                            .padding(.bottom)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: Constants.actionBarHeight, alignment: .bottom)
                    .padding(.horizontal)
                    .background(.background)
                    .shadow(color: .black.opacity(0.1), radius: 10)
                }
                .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.svg]) { result in
                    model.importSVG(result: result, size: geo.size)
                }
        }
    }
    
    var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if value.location == value.startLocation {
                    model.isDrawing = true
                    model.path = Path()
                    model.path?.move(to: value.location)
                } else {
                    model.path?.addLine(to: value.location)
                }
            }
            .onEnded { _ in
                model.isDrawing = false
                guard let path = model.path else { return }
                let points = path.cgPath.equallySpacedPoints
                model.transform(points: points)
            }
    }
}

#Preview {
    RootView()
}

struct PathRenderer: View {
    let path: Path
    
    var body: some View {
        path.stroke(Color.accentColor, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }
}
