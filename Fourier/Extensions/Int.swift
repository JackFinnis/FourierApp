//
//  Int.swift
//  Change
//
//  Created by Jack Finnis on 17/10/2022.
//

import Foundation

extension Int {
    func formatted(singular word: String) -> String {
        "\(self == 0 ? "No" : String(self)) \(word)\(self == 1 ? "" : "s")"
    }
}
