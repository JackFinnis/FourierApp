//
//  PathRenderer.swift
//  Fourier
//
//  Created by Jack Finnis on 19/06/2024.
//

import SwiftUI

struct PathRenderer: View {
    let path: Path
    
    var body: some View {
        path.stroke(Color.accentColor, style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }
}

#Preview {
    RootView()
}
