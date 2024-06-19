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
        VStack(spacing: 0) {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                    .gesture(drawGesture)
                if let path = model.path {
                    PathRenderer(path: path)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                if model.isDrawing {
                    Rectangle()
                        .foregroundStyle(.background)
                } else if model.path != nil {
                    HStack(spacing: 15) {
                        Text(Int(model.epicycles-1).formatted(singular: "Epicycle"))
                            .fixedSize()
                        Spacer()
                        Stepper("", value: $model.epicycles, in: model.nRange) { stepping in
                            if !stepping { model.update() }
                        }
                        .labelsHidden()
                        Menu {
                            Button(role: .destructive) {
                                model.reset()
                            } label: {
                                Label("Reset", systemImage: "xmark")
                            }
                            Button {
                                //todo
                                Haptics.tap()
                            } label: {
                                Label("Save to Photos", systemImage: "square.and.arrow.down")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                        }
                    }
                    Slider(value: $model.epicycles, in: model.nRange, step: 1) { sliding in
                        if !sliding { model.update() }
                    }
                } else {
                    HStack(alignment: .top, spacing: 10) {
                        Text("Draw a shape in the space above with your finger or stylus or upload a picture of a silhouette or an svg file and I will squigglify it!")
                            .font(.subheadline)
                        Spacer(minLength: 0)
                        Menu {
                            Button {
                                showFileImporter = true
                            } label: {
                                Label("Import SVG File", systemImage: "doc")
                            }
                            Button {
                                model.showExampleSquiggle()
                            } label: {
                                Label("Joseph Fourier", systemImage: "person.fill")
                            }
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                        }
                    }
                }
            }
            .frame(height: 100)
            .padding(.horizontal)
            .background(.background)
            .shadow(color: .black.opacity(0.1), radius: 10)
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.svg], onCompletion: model.importSVG)
        }
        .environmentObject(model)
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
