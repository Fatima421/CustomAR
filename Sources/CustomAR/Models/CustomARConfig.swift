//
//  CustomARConfig.swift
//  
//
//  Created by Fatima Syed on 12/5/23.
//

import UIKit
import CoreML
import Vision

public struct CustomARConfig {
    let model: MLModel
    let objectLabelsWithImages: [String: UIImage]

    public init(model: MLModel, objectLabelsWithImages: [String: UIImage]) {
        self.model = model
        self.objectLabelsWithImages = objectLabelsWithImages
    }
}
