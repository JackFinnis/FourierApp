//
//  Collection.swift
//  Fourier
//
//  Created by Jack Finnis on 04/12/2022.
//

import Foundation

extension Collection {
    var isNotEmpty: Bool { !isEmpty }
}

extension Array {
    func getEveryNthElement(n: Int) -> Self {
        if n >= 2 {
            return enumerated().compactMap { i, element in
                i % n == 0 ? element : nil
            }
        } else {
            return self
        }
    }
}
