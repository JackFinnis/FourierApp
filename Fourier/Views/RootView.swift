//
//  DrawView.swift
//  Fourier
//
//  Created by Jack Finnis on 24/08/2021.
//

import SwiftUI
import Vision

struct RootView: View {
    @StateObject var model = Model()
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                    .gesture(drawGesture)
                if let path = model.path {
                    PathRenderer(path: path)
                }
            }
            ActionBar()
        }
        .environmentObject(model)
    }
    
    var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = value.location
                
                if model.isDrawing {
                    model.drawingPath?.addLine(to: point)
                } else {
                    model.isDrawing = true
                    model.drawingPath = Path()
                    model.drawingPath?.move(to: point)
                }
            }
            .onEnded { _ in
                model.isDrawing = false
                let points = model.drawingPath?.cgPath.equallySpacedPoints ?? []
                model.newPoints(points)
                model.drawingPath = nil
            }
    }
}

#Preview {
    RootView()
}
