//
//  FourierApp.swift
//  Fourier
//
//  Created by Jack Finnis on 24/08/2021.
//

import SwiftUI

let NAME = "Fourier"
let EMAIL = "mailto:jack.finnis@icloud.com"
let APP_URL = URL(string: "https://apps.apple.com/app/id1582827502")!

@main
struct FourierApp: App {
    var body: some Scene {
        WindowGroup {
            DrawView()
        }
    }
}
