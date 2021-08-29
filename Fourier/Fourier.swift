//
//  Fourier.swift
//  Fourier
//
//  Created by Jack Finnis on 29/08/2021.
//

import Foundation
import ComplexModule

struct Fourier {
    func integrand(path: [Complex<Double>], t: Int, n: Int) -> Complex<Double> {
        Complex.exp(Complex(Double(n)) * Complex(imaginary: -2) * Complex(Double.pi) * Complex(Double(t)/Double(path.count))) * path[t]
    }

    func integral(path: [Complex<Double>], n: Int) -> Complex<Double> {
        var integral: Complex<Double> = 0
        for t in 0..<path.count {
            integral += integrand(path: path, t: t, n: n) * Complex(1/Double(path.count))
        }
        return integral
    }

    func getCn(N: Int, path: [Complex<Double>]) -> [Int: Complex<Double>] {
        var c: [Int: Complex<Double>] = [:]
        for n in nRange(N: N) {
            c[n] = integral(path: path, n: n)
        }
        return c
    }

    func nRange(N: Int) -> Range<Int> {
        Int((Double(-N)/2).rounded(.up))..<Int((Double(N)/2).rounded(.up))
    }

    func vector(cn: Complex<Double>, t: Double, n: Int) -> Complex<Double> {
        cn * Complex.exp(Complex(Double(n)) * Complex(imaginary: 2) * Complex(Double.pi) * Complex(t))
    }

    func getApprox(N: Int, path: [Complex<Double>], c: [Int: Complex<Double>]) -> [Complex<Double>] {
        var approx = [Complex<Double>]()
        for t in 0..<path.count {
            var vectorSum: Complex<Double> = 0
            for n in nRange(N: N) {
                vectorSum += vector(cn: c[n]!, t: Double(t)/Double(path.count), n: n)
            }
            approx.append(vectorSum)
        }
        return approx
    }
    
    func transform(N: Int, points: [[Double]]) -> [[Double]] {
        let path = points.map { Complex($0[0], $0[1]) }
        let c = getCn(N: N, path: path)
        let approx = getApprox(N: N, path: path, c: c)
        return approx.map { [$0.real, $0.imaginary] }
    }
}
