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
    case tower
}

public struct ARType {
    let title: String
    let subtitle: String
    let image: UIImage?
    
    public init(title: String, subtitle: String, image: UIImage?) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }
}

public struct Action {
    let type: ActionType
    let media: Any?
    
    public init(type: ActionType, media: Any?) {
        self.type = type
        self.media = media
    }
}

public struct CustomARConfig {
    let model: MLModel
    let objectLabelsWithActions: [String: [Action]]
    let shouldDetect: Bool
    let arSpotID: String?
    public var arType: ARType?

    public init(model: MLModel, objectLabelsWithActions: [String: [Action]], shouldDetect: Bool, arSpotID: String? = nil, arType: ARType? = nil) {
        self.model = model
        self.objectLabelsWithActions = objectLabelsWithActions
        self.shouldDetect = shouldDetect
        self.arSpotID = arSpotID
        self.arType = arType
    }
}
