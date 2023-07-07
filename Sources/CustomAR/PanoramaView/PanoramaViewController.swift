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
    var doDetection: Bool?
    
    // MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let image = image else { return }
        panoramaView = CTPanoramaView(frame: view.bounds, image: image)
        panoramaView?.controlMethod = .both
        
        view.addSubview(panoramaView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        view.addSubview(closeButton)
        setupView()
    }
    
    private func setupView() {
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }
    
    // MARK: Style
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "close"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        return button
    }()
    
    // MARK: Actions
    @objc func didTapClose() {
        doDetection = true
        self.dismiss(animated: true)
    }
}
