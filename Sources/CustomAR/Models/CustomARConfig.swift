//
//  CustomARConfig.swift
//  
//
//  Created by Fatima Syed on 12/5/23.
//

import Foundation
import CoreML
import Vision

public struct CustomARConfig {
    let model: MLModel
    let labels: [String]
    let actions: [(VNRecognizedObjectObservation) -> Void]
    
    public init(model: MLModel, labels: [String], actions: [(VNRecognizedObjectObservation) -> Void]) {
        self.model = model
        self.labels = labels
        self.actions = actions
    }
}
