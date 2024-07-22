//
//  RootView.swift
//  Fourier
//
//  Created by Jack Finnis on 22/07/2024.
//

import SwiftUI

struct RootView: View {
    @State var model = Model()
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
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
                    .fileImporter(isPresented: $model.showFileImporter, allowedContentTypes: [.svg]) { result in
                        model.importSVG(result: result, size: geo.size)
                    }
#if os(iOS)
                ActionBar(model: model, geo: geo)
                    .frame(height: Constants.actionBarHeight, alignment: .bottom)
                    .frame(maxWidth: .infinity)
                    .background(.background)
                    .shadow(color: .black.opacity(0.1), radius: 10)
#endif
            }
#if os(visionOS)
            .ornament(attachmentAnchor: .scene(.bottom)) {
                ActionBar(model: model, geo: geo)
                    .frame(width: 500, height: 115)
                    .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 30))
            }
#endif
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
                let points = path.cgPath.copy(dashingWithPhase: 0, lengths: [10]).points
                model.transform(points: points)
            }
    }
}

#Preview {
    RootView()
}
