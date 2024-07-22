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
            #if os(visionOS)
                .frame(minWidth: 600, minHeight: 600)
            #endif
        }
        .defaultSize(width: 800, height: 800)
        .windowResizability(.contentMinSize)
    }
}
