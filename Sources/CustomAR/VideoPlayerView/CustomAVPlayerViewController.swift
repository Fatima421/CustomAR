//
//  CustomAVPlayerViewController.swift
//  
//
//  Created by Fatima Syed on 7/7/23.
//

import UIKit
import AVKit

class CustomAVPlayerViewController: AVPlayerViewController {
    var orientationView: UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupOrientationView()
    }
    
    private func setupOrientationView() {
        if let orientationView = orientationView {
            contentOverlayView?.addSubview(orientationView)

            NSLayoutConstraint.activate([
                orientationView.centerXAnchor.constraint(equalTo: contentOverlayView!.centerXAnchor),
                orientationView.centerYAnchor.constraint(equalTo: contentOverlayView!.centerYAnchor),
                orientationView.widthAnchor.constraint(equalToConstant: 100),
                orientationView.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
    }
    
    func isOrientationPortrait() -> Bool {
        guard let videoTrack = player?.currentItem?.asset.tracks(withMediaType: .video).first else { return true }
        let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        return abs(size.width) < abs(size.height)
    }
}
