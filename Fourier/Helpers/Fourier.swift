//
//  Fourier.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import Foundation
import ComplexModule
import SwiftUI

struct Fourier {
    static func integrand(path: [Complex<Double>], t: Int, n: Int) -> Complex<Double> {
        Complex.exp(Complex(Double(n)) * Complex(imaginary: -2) * Complex(Double.pi) * Complex(Double(t)/Double(path.count))) * path[t]
    }
    
    static func integral(path: [Complex<Double>], n: Int) -> Complex<Double> {
        var integral: Complex<Double> = 0
        for t in 0..<path.count {
            integral += integrand(path: path, t: t, n: n) * Complex(1/Double(path.count))
        }
        return integral
    }

    static func getCs(N: Int, path: [Complex<Double>]) -> [Int: Complex<Double>] {
        var cs: [Int: Complex<Double>] = [:]
        for n in nRange(N: N) {
            cs[n] = integral(path: path, n: n)
        }
        return cs
    }

    static func nRange(N: Int) -> Range<Int> {
        Int((Double(-N)/2).rounded(.up))..<Int((Double(N)/2).rounded(.up))
    }

    static func vector(cn: Complex<Double>, t: Double, n: Int) -> Complex<Double> {
        cn * Complex.exp(Complex(Double(n)) * Complex(imaginary: 2) * Complex(Double.pi) * Complex(t))
    }

    static func getApprox(N: Int, path: [Complex<Double>], cs: [Int: Complex<Double>]) -> [Complex<Double>] {
        var approx = [Complex<Double>]()
        for t in 0..<path.count {
            var vectorSum: Complex<Double> = 0
            for n in nRange(N: N) {
                vectorSum += vector(cn: cs[n]!, t: Double(t)/Double(path.count), n: n)
            }
            approx.append(vectorSum)
        }
        return approx
    }
    
    static func transform(N: Int, points: [CGPoint]) -> [CGPoint] {
        let path = points.map { Complex(Double($0.x), Double($0.y)) }
        let cs = getCs(N: N, path: path)
        let approx = getApprox(N: N, path: path, cs: cs)
        return approx.map { CGPointMake($0.real, $0.imaginary) }
    }
}
