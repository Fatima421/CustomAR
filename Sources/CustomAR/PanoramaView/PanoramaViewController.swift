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
    
    // MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rescaleOrientation(with: .landscape)
        
        guard let image = image else { return }
        panoramaView = CTPanoramaView(frame: view.bounds, image: image)
        panoramaView?.controlMethod = .both
        
        view.addSubview(panoramaView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        rescaleOrientation(with: .landscape)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        view.addSubview(closeButton)
        setupView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        rescaleOrientation(with: .portrait)
    }
    
    private func setupView() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }
    
    private func rescaleOrientation(with orientation: UIInterfaceOrientationMask) {
        var appDelegate = UIApplication.shared.delegate as! RotationRestrictable
        appDelegate.restrictRotation = orientation
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
        if let recognitionVC = self.presentingViewController as? RecognitionViewController {
            recognitionVC.viewWillAppear(false)
        }
        self.dismiss(animated: true)
    }
}
