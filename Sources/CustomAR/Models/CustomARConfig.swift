//
//  CustomARConfig.swift
//  
//
//  Created by Fatima Syed on 12/5/23.
//

import UIKit
import CoreML
import Vision

public enum ActionType {
    case panoramaView
    case videoPlayer
}

public struct Action {
    let type: ActionType
    let media: Any
}

public struct CustomARConfig {
    let model: MLModel
    let objectLabelsWithActions: [String: [Action]]

    public init(model: MLModel, objectLabelsWithActions: [String: [Action]]) {
        self.model = model
        self.objectLabelsWithActions = objectLabelsWithActions
    }
}
