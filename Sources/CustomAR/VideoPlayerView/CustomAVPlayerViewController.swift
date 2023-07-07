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
            view.addSubview(orientationView)
            
            NSLayoutConstraint.activate([
                orientationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                orientationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                orientationView.widthAnchor.constraint(equalToConstant: 100),
                orientationView.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
    }
}