//
//  PanoramaViewController.swift
//  AugmentedReality
//
//  Created by Fatima Syed on 27/3/23.
//

import UIKit

class PanoramaViewController: UIViewController {
    
    // MARK: Properties
    var image: UIImage?
    var panoramaView: CTPanoramaView!

    // MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let image = image else { return }
        panoramaView = CTPanoramaView(frame: view.bounds, image: image)
        panoramaView?.controlMethod = .both

        view.addSubview(panoramaView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}
