//
//  ExampleFile.swift
//  Fourier
//
//  Created by Jack Finnis on 22/07/2024.
//

import Foundation

enum ExampleFile: String, CaseIterable {
    case fourier
    case pi
    
    var name: String {
        switch self {
        case .fourier:      return "Joseph Fourier"
        case .pi:           return "Pi"
        }
    }
    
    var url: URL {
        Bundle.main.url(forResource: rawValue, withExtension: "svg")!
    }
}
