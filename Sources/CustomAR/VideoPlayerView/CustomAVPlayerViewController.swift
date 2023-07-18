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

            self.showsPlaybackControls = false
            NSLayoutConstraint.activate([
                orientationView.centerXAnchor.constraint(equalTo: contentOverlayView!.centerXAnchor),
                orientationView.topAnchor.constraint(equalTo: contentOverlayView!.safeAreaLayoutGuide.bottomAnchor, constant: -120),
                orientationView.widthAnchor.constraint(equalToConstant: 100),
                orientationView.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
    }
    
    func isOrientationPortrait() -> Bool {
        UIDevice.current.orientation.isPortrait
    }
    
    var _firstTap = true
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if _firstTap {
            showsPlaybackControls = true
            _firstTap = false
            return
        }
        super.touchesBegan(touches, with: event)
    }
}
