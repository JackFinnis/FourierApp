//
//  UpdateNBar.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import SwiftUI
import PhotosUI

struct ActionBar: View {
    @EnvironmentObject var model: Model
    @State var showFileImporter = false
    @State var showPhotosPicker = false
    @State var selectedPhoto: PhotosPickerItem?
    
    var pathShowing: Bool { !model.isDrawing && model.fourierPath != nil }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if pathShowing {
                HStack(spacing: 15) {
                    Text(Int(model.N-1).formatted(singular: "Epicycle"))
                        .fixedSize()
                    Spacer()
                    Stepper("", value: $model.N, in: model.nRange) { stepping in
                        if !stepping { model.transform() }
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
                .padding(.top, 10)
                
                Slider(value: $model.N, in: model.nRange, step: 1) { sliding in
                    if !sliding { model.transform() }
                }
                .padding(.bottom, 10)
            } else if !model.isDrawing {
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
                            showPhotosPicker = true
                        } label: {
                            Label("Import Silhouette", systemImage: "photo")
                        }
                        
                        if !model.showingExample {
                            Button {
                                model.showExampleSquiggle()
                            } label: {
                                Label("Joseph Fourier", systemImage: "person.fill")
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                    }
                }
            } else {
                Rectangle()
                    .foregroundStyle(.background)
            }
        }
        .frame(height: 100)
        .padding(.horizontal)
        .background(.background)
        .shadow(color: .black.opacity(0.1), radius: 10)
        .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhoto)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.svg], onCompletion: model.importSVG)
    }
}

#Preview {
    RootView()
}
