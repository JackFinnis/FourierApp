//
//  ActionBar.swift
//  Fourier
//
//  Created by Jack Finnis on 22/07/2024.
//

import SwiftUI

struct ActionBar: View {
    @Bindable var model: Model
    let geo: GeometryProxy
    
    var body: some View {
        ZStack {
            if model.isDrawing {
            } else if let path = model.path {
#if os(iOS)
                let spacing = 5.0
#elseif os(visionOS)
                let spacing = 10.0
#endif
                VStack(spacing: spacing) {
                    HStack(spacing: 15) {
                        Button {
                            model.reset()
                        } label: {
                            Label("Reset", systemImage: "xmark")
                        }
                        #if os(iOS)
                        .tint(.secondary)
                        #endif
                        .font(.headline)
                        Text(Int(model.epicycles).formatted(singular: "Epicycle"))
                            .monospacedDigit()
                        Spacer()
                        Stepper("", value: $model.epicycles, in: model.nRange) { isStepping in
                            if !isStepping { model.update() }
                        }
                        .labelsHidden()
                        Toggle(isOn: $model.isSaved) {
                            if model.isSaved {
                                Label("Saved to Photos", systemImage: "checkmark.circle.fill")
                            } else {
                                Label("Save to Photos", systemImage: "plus.circle")
                            }
                        }
                        .font(.headline)
                        .toggleStyle(.button)
                        .onChange(of: model.isSaved) { _, isSaved in
                            if isSaved {
                                model.save(path: path, size: geo.size)
                            }
                        }
                    }
                    .labelStyle(.iconOnly)
                    .buttonBorderShape(.circle)
                    .buttonStyle(.bordered)
                    
                    Slider(value: $model.epicycles, in: model.nRange, step: 1) { isSliding in
                        if !isSliding { model.update() }
                    }
                }
            } else {
                HStack(spacing: 15) {
                    Button("Import SVG File") {
                        model.showFileImporter = true
                    }
                    .buttonStyle(.borderedProminent)
                    Menu("View Examples") {
                        ForEach(ExampleFile.allCases, id: \.self) { file in
                            Button(file.name) {
                                model.importSVG(result: .success(file.url), size: geo.size)
                            }
                        }
                    }
                    .menuStyle(.button)
                    .buttonStyle(.bordered)
                }
                .buttonBorderShape(.capsule)
                .font(.headline)
                #if os(iOS)
                .padding(.bottom)
                #endif
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    RootView()
}
