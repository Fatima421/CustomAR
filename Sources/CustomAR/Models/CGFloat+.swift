//
//  CGFloat.swift
//
//
//  Created by Fatima Syed on 19/6/24.
//

import UIKit

extension CGFloat {
    static func randomGaussian(mean: CGFloat = 0.0, standardDeviation: CGFloat = 1.0) -> CGFloat {
        let x1 = CGFloat(arc4random()) / CGFloat(UInt32.max)
        let x2 = CGFloat(arc4random()) / CGFloat(UInt32.max)
        
        let z = sqrt(-2.0 * log(x1)) * cos(2.0 * .pi * x2)
        
        return z * standardDeviation + mean
    }
}
