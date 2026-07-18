//
//  ContentView.swift
//  Fourier
//
//  Created by Jack Finnis on 07/03/2026.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    @Environment(\.requestReview) var requestReview
    @AppStorage("featuresUsed") var featuresUsed = 0
    @State var model = Model()
    @State var progressiveStartDate = Date.now
    @State var showShareSheet = false

    init() {
        UINavigationBar.appearance().titleTextAttributes = [.font : UIFont.headline]
    }

    var title: String {
        if model.path == nil || model.isDrawing {
            return "Fourier"
        } else {
            return Int(model.epicycles).formatted(singular: "Epicycle")
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let insets = geo.safeAreaInsets
                let size = CGSize(
                    width: geo.size.width + insets.leading + insets.trailing,
                    height: geo.size.height + insets.top + insets.bottom
                )

                ZStack {
                    Rectangle()
                        .fill(.background)

                    if let path = model.path {
                        if model.isAnimating {
                            EpicycleView(model: model)
                        } else {
                            path.stroke(.accent, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        }
                    } else {
                        Image(systemName: "hand.draw.fill")
                            .font(.largeTitle)
                            .imageScale(.large)
                            .foregroundStyle(.secondary)
                    }
                }
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            if value.location == value.startLocation {
                                model.isDrawing = true
                                model.isAnimating = false
                                model.isProgressive = false
                                model.points = []
                                model.epicycles = 2
                                model.path = Path()
                                model.path?.move(to: value.location)
                            } else {
                                model.path?.addLine(to: value.location)
                            }
                        }
                        .onEnded { _ in
                            model.isDrawing = false
                            guard let path = model.path else { return }
                            let points = path.cgPath.samplePoints()
                            model.analyze(points: points, size: size)
                        }
                )
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarTitleMenu {
                    Link(destination: URL(string: "https://youtu.be/r6sGWTCMz2k")!) {
                        Text("But what is a Fourier series?")
                        Text("3Blue1Brown, YouTube")
                        Image(systemName: "play.rectangle.fill")
                    }
                    Section("Fourier") {
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Link(destination: URL(string: "https://jackfinnis.com/apps/fourier")!) {
                            Label("Get Help", systemImage: "questionmark.circle")
                        }
                        Link(destination: URL(string: "mailto:jack@jackfinnis.com?subject=Fourier%20Feedback")!) {
                            Label("Send Feedback", systemImage: "envelope")
                        }
                        Link(destination: URL(string: "https://apps.apple.com/app/id1582827502?action=write-review")!) {
                            Label("Write a Review", systemImage: "star")
                        }
                        Link(destination: URL(string: "https://apps.apple.com/developer/1633101066")!) {
                            Label("More Apps", systemImage: "square.grid.2x2")
                        }
                    }
                }
                .toolbar {
                    if model.path == nil {
                        ToolbarItem(placement: .bottomBar) {
                            Menu("Examples") {
                                ForEach(ExampleFile.allCases, id: \.self) { file in
                                    Button(file.name) {
                                        model.importSVG(url: file.url, size: size, insets: insets)
                                    }
                                }
                            }
                        }
                    } else if !model.isDrawing {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                model.reset()
                            } label: {
                                Label("Reset", systemImage: "xmark")
                            }
                        }
                        ToolbarItemGroup(placement: .primaryAction) {
                            Button {
                                model.isAnimating.toggle()
                            } label: {
                                Label(model.isAnimating ? "Stop" : "Play", systemImage: model.isAnimating ? "stop.fill" : "play.fill")
                            }
                        }
                        ToolbarItemGroup(placement: .bottomBar) {
                            Button {
                                model.isProgressive.toggle()
                                progressiveStartDate = .now
                            } label: {
                                Label("Progressive", systemImage: model.isProgressive ? "stop.fill" : "play.fill")
                            }
                            Slider(value: $model.epicycles, in: model.nRange, step: 1) { isSliding in
                                model.isProgressive = false
                            }
                            Stepper("Epicycles", value: $model.epicycles, in: model.nRange) { isStepping in
                                model.isProgressive = false
                            }
                            .labelsHidden()
                            .padding(.trailing, 4)
                        }
                    }
                }
            }
        }
        .monospacedDigit()
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [URL(string: "https://apps.apple.com/app/id1582827502")!])
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
        }
        .onReceive(Timer.publish(every: 1.0/30, on: .main, in: .common).autoconnect()) { _ in
            guard model.isProgressive else { return }
            let upperBound = model.nRange.upperBound
            let elapsed = Date.now.timeIntervalSince(progressiveStartDate)
            let cycle = fmod(elapsed / 30, 2)
            let t = cycle < 1 ? cycle : 2 - cycle
            model.epicycles = max(1, round(1 + t * t * (upperBound - 1)))
        }
        .onChange(of: model.epicycles) {
            model.updatePath()
        }
        .onChange(of: model.path) { _, _ in
            if model.path == nil {
                featuresUsed += 1
            }
        }
        .onChange(of: featuresUsed) { _, _ in
            if featuresUsed.isMultiple(of: 10) {
                requestReview()
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
