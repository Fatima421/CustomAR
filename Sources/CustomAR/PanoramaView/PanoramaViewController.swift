//
//  PanoramaViewController.swift
//  AugmentedReality
//
//  Created by Fatima Syed on 27/3/23.
//

import UIKit

public protocol RotationRestrictable {
    var restrictRotation: UIInterfaceOrientationMask { get set }
}

class PanoramaViewController: UIViewController {
    
    // MARK: Properties
    var image: UIImage?
    var panoramaView: CTPanoramaView!
    var closeButton: UIButton?
    
    // MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let image = image else { return }
        panoramaView = CTPanoramaView(frame: view.bounds, image: image)
        panoramaView?.controlMethod = .both
        
        view.addSubview(panoramaView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let closeButton = closeButton {
            view.addSubview(closeButton)
            setupView(closeButton)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func setupView(_ closeButton: UIButton) {
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }
    
    // MARK: Actions
    @objc func didTapClose() {
        if let recognitionVC = self.presentingViewController as? RecognitionViewController {
            recognitionVC.viewWillAppear(false)
        }
        self.dismiss(animated: true)
    }
}
