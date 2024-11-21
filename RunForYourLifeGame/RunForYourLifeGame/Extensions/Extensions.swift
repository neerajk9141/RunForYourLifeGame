//
//  Extensions.swift
//  RunForYourLifeGame
//
//  Created by Quidich on 21/11/24.
//

import RealityKit
import SwiftUI

extension SIMD3 where Scalar == Float {
    func distance(to other: SIMD3<Float>) -> Float {
        return sqrt(pow(self.x - other.x, 2) + pow(self.y - other.y, 2) + pow(self.z - other.z, 2))
    }
}

extension Float {
    static func lerp(from start: Float, to end: Float, t: Float) -> Float {
        return (1 - t) * start + t * end
    }
}
