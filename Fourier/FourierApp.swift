//
//  FourierApp.swift
//  Fourier
//
//  Created by Jack Finnis on 24/08/2021.
//

import SwiftUI

let NAME = "Fourier"
let APP_URL = URL(string: "https://apps.apple.com/app/id1582827502")!
let SAMPLE_URL = Bundle.main.url(forResource: "fourier", withExtension: "svg")!

@main
struct FourierApp: App {
    var body: some Scene {
        WindowGroup {
            DrawView()
        }
    }
}
