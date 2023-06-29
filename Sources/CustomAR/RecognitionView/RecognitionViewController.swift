//
//  RecognitionViewController.swift
//  AugmentedReality
//
//  Created by Fatima Syed on 27/3/23.
//

import UIKit
import AVFoundation
import Vision
import CoreML
import CoreMotion
import AVKit

open class RecognitionViewController: ARViewController, UIViewControllerTransitioningDelegate {
    
    // MARK: - Properties
    
    public var detectionTime: Double?
    public var detectionInterval: Double?
    public var customARConfig: CustomARConfig?
    public var infoLabel: UILabel?
    public var infoIcon: UIImageView?
    public var infoLabelInitialText: String?
    public var showCameraMovementAlert: (() -> Void)?
    public var detectionButton: UIButton?
    public var arDetailScreen: String?
    
    private var detectionOverlay: CALayer! = nil
    private var requests = [VNRequest]()
    private var hasNavigatedToPanoramaView: Bool = false
    private var detectionTimer: Timer?
    private var detectionRestartTimer: Timer?
    private var currentActionIndex: Int?
    private let infoContainer = UIView()
    private let motionManager = CMMotionManager()
    private var lastMotionTime: Date?
    private let movementTimeout: TimeInterval = 5.0
    private var movementTimeoutTimer: Timer?
    private var currentIdentifier: String?
    private var hasShownCameraMovementAlert: Bool = false
    private var panoramaViewController: PanoramaViewController?
    private lazy var playerViewController = CustomAVPlayerViewController()
    private var noDetectionTimer: Timer?
    
    // MARK: - Life Cycle
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restartCaptureSession()
        initialParameters()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        restartCaptureSession()
        initialParameters()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func initialParameters() {
        detectionButton?.isHidden = true
        hasNavigatedToPanoramaView = false
        hasShownCameraMovementAlert = false
        resetZoom()
        if detectionOverlay.superlayer == nil {
            rootLayer.addSublayer(detectionOverlay)
        }
        setupView()
        startNoDetectionTimer()
        setupMotionDetection()
    }
    
    func resetDetectionLabel() {
        self.infoLabel?.text = infoLabelInitialText
        infoLabel?.isHidden = true
        infoIcon?.isHidden = true
        infoContainer.isHidden = true
    }
    
    func startNoDetectionTimer() {
        noDetectionTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.detectionButton?.isHidden = false
        }
    }
    
    // MARK: - Capture Session
    
    public func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    public func stopCaptureSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    private func restartCaptureSession() {
        stopCaptureSession()
        setupAVCapture()
        startCaptureSession()
    }
    
    func resetZoom() {
        DispatchQueue.main.async {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.25)
            
            self.previewLayer?.transform = CATransform3DIdentity
            self.previewLayer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            self.previewLayer?.position = CGPoint(x: self.rootLayer.bounds.midX, y: self.rootLayer.bounds.midY)
            
            CATransaction.commit()
        }
    }
    
    func setupVision() {
        if let model = customARConfig?.model {
            guard let objectDetectionModel = try? VNCoreMLModel(for: model) else { return }
            
            let objectRecognition = VNCoreMLRequest(model: objectDetectionModel) { [weak self] request, error in
                if let error = error {
                    print("Object detection error: \(error)")
                    return
                }
                
                guard let results = request.results as? [VNRecognizedObjectObservation] else { return }
                
                DispatchQueue.main.async {
                    self?.drawVisionRequestResults(results)
                }
            }
            self.requests = [objectRecognition]
        }
    }
    
    private func setupMotionDetection() {
//        if !hasShownCameraMovementAlert {
//            motionManager.deviceMotionUpdateInterval = 0.1
//            motionManager.startDeviceMotionUpdates(to: .main) { (deviceMotion, error) in
//                guard let deviceMotion = deviceMotion else { return }
//
//                if abs(deviceMotion.userAcceleration.x) > 0.05 ||
//                    abs(deviceMotion.userAcceleration.y) > 0.05 ||
//                    abs(deviceMotion.userAcceleration.z) > 0.05 {
//
//                    self.lastMotionTime = Date()
//                    self.resetMovementTimeoutTimer()
//                }
//
//                if let lastMotionTime = self.lastMotionTime,
//                   Date().timeIntervalSince(lastMotionTime) > self.movementTimeout {
//                    self.showCameraMovementAlert?()
//                    self.lastMotionTime = Date()
//                    self.hasShownCameraMovementAlert = true
//                    self.motionManager.stopDeviceMotionUpdates()
//                }
//            }
//        }
    }
    
    private func resetMovementTimeoutTimer() {
        movementTimeoutTimer?.invalidate()
        
        movementTimeoutTimer = Timer.scheduledTimer(withTimeInterval: movementTimeout, repeats: false) { [weak self] timer in
            DispatchQueue.main.async {
                self?.showCameraMovementAlert?()
            }
        }
    }
    
    private func setupView() {
        view.addSubview(closeButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
        
        guard let infoIcon = infoIcon, let infoLabel = infoLabel else { return }
        
        let infoStackView = UIStackView(arrangedSubviews: [infoIcon, infoLabel])
        infoStackView.axis = .horizontal
        infoStackView.spacing = 10
        
        infoContainer.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        infoContainer.layer.cornerRadius = 10
        infoContainer.layer.masksToBounds = true
        infoContainer.isHidden = true
        infoContainer.addSubview(infoStackView)
        
        view.addSubview(infoContainer)
        
        infoContainer.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoIcon.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            infoContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            infoContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            infoContainer.heightAnchor.constraint(equalToConstant: 40),
            
            infoStackView.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor, constant: 8),
            infoStackView.topAnchor.constraint(equalTo: infoContainer.topAnchor, constant: 8),
            infoStackView.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor, constant: -8),
            
            infoIcon.widthAnchor.constraint(equalToConstant: 24),
            infoIcon.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        if var detectionButton = self.detectionButton {
            detectionButton = UIButton(type: .system)
            detectionButton.addTarget(self, action: #selector(detectionButtonTapped), for: .touchUpInside)
            view.addSubview(detectionButton)
            
            detectionButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                detectionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
                detectionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
                detectionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                detectionButton.widthAnchor.constraint(equalToConstant: 52),
                detectionButton.heightAnchor.constraint(equalToConstant: 52)
            ])
        }
    }
    
    
    func drawVisionRequestResults(_ results: [Any]) {
        detectionOverlay.sublayers = nil
        var remainingTime = detectionTime ?? 2.0
        
        if let objectObservation = results.compactMap({ $0 as? VNRecognizedObjectObservation })
            .filter({ $0.confidence > 0.5 })
            .max(by: { $0.confidence < $1.confidence }) {
            
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            if detectionTimer == nil {
                self.fireHaptic()
                let labelName = objectObservation.labels.first?.identifier
                if let infoLabel = self.infoLabel, infoLabel.isHidden {
                    DispatchQueue.main.async {
                        infoLabel.text = "\(self.infoLabelInitialText ?? "") \(labelName ?? "")"
                        infoLabel.isHidden = false
                        self.infoIcon?.isHidden = false
                        self.infoContainer.isHidden = false
                    }
                }
                detectionTimer = Timer.scheduledTimer(withTimeInterval: remainingTime, repeats: false) { [weak self] _ in
                    self?.detectionOverlay.removeFromSuperlayer()
                    if let labelName = labelName {
                        self?.detectionTimerExpired(objectBounds, identifier: labelName)
                    }
                }
            } else {
                detectionRestartTimer?.invalidate()
            }
            
            detectionRestartTimer = Timer.scheduledTimer(withTimeInterval: detectionInterval ?? 0.5, repeats: false) { [weak self] _ in
                if let remainingTimeInterval = self?.detectionTimer?.fireDate.timeIntervalSince(Date()) {
                    remainingTime = remainingTimeInterval
                }
                self?.detectionTimer?.invalidate()
                self?.detectionTimer = nil
                self?.resetDetectionLabel()
            }
            
            let shapeLayer = self.createRandomDottedRectLayerWithBounds(objectBounds)
            
            detectionOverlay.addSublayer(shapeLayer)
        }
        self.updateLayerGeometry()
    }
    
    func createRandomDottedRectLayerWithBounds(_ bounds: CGRect, dotRadius: CGFloat = 1.0, density: CGFloat = 0.015) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        let numberOfDots = Int(bounds.width * bounds.height * density)
        
        let shadowPath = UIBezierPath()
        let actualPath = UIBezierPath()
        
        for _ in 0..<numberOfDots {
            let x = CGFloat.randomGaussian() * bounds.width/4 + bounds.midX
            let y = CGFloat.randomGaussian() * bounds.height/4 + bounds.midY
            let actualDotRadius = CGFloat.random(in: 0.5 * dotRadius...1.5 * dotRadius)
            let shadowDotRadius = actualDotRadius * 3
            
            shadowPath.move(to: CGPoint(x: x, y: y))
            shadowPath.addArc(withCenter: CGPoint(x: x, y: y), radius: shadowDotRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            
            actualPath.move(to: CGPoint(x: x, y: y))
            actualPath.addArc(withCenter: CGPoint(x: x, y: y), radius: actualDotRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        
        let shadowLayer = CAShapeLayer()
        shadowLayer.path = shadowPath.cgPath
        shadowLayer.fillColor = UIColor.white.cgColor
        shadowLayer.opacity = 0.2
        shapeLayer.addSublayer(shadowLayer)
        
        let dotLayer = CAShapeLayer()
        dotLayer.path = actualPath.cgPath
        dotLayer.fillColor = UIColor.white.cgColor
        shapeLayer.addSublayer(dotLayer)
        
        return shapeLayer
    }
    
    func zoomAnimation(duration: TimeInterval, scale: CGFloat, objectBounds: CGRect, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            CATransaction.begin()
            CATransaction.setAnimationDuration(duration)
            CATransaction.setCompletionBlock {
                completion?()
            }
            
            let newX = objectBounds.midX / self.detectionOverlay!.bounds.width
            let newY = objectBounds.midY / self.detectionOverlay!.bounds.height
            
            self.previewLayer?.anchorPoint = CGPoint(x: newX, y: newY)
            
            let zoom = CABasicAnimation(keyPath: "transform.scale")
            zoom.fromValue = 1.0
            zoom.toValue = scale
            zoom.duration = duration
            
            self.previewLayer?.add(zoom, forKey: nil)
            self.previewLayer?.transform = CATransform3DScale(self.previewLayer!.transform, scale, scale, 1)
            
            CATransaction.commit()
        }
    }
    
    func fireHaptic() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.impactOccurred()
    }
    
    func detectionTimerExpired(_ objectBounds: CGRect, identifier: String) {
        resetDetectionLabel()
        if !hasNavigatedToPanoramaView {
            hasNavigatedToPanoramaView = true
            if let actions = self.customARConfig?.objectLabelsWithActions[identifier] {
                self.currentIdentifier = identifier
                self.currentActionIndex = 0
                self.executeCurrentAction(actions: actions)
            }
        }
    }
    
    func executeCurrentAction(actions: [Action]) {
        guard let currentActionIndex = currentActionIndex, currentActionIndex < actions.count else { return }
        
        let action = actions[currentActionIndex]
        
        switch action.type {
        case .panoramaView:
            if let image = action.media as? UIImage {
                self.navigateToPanoramaView(media: image)
            }
        case .videoPlayer:
            if let player = action.media as? AVPlayer {
                self.navigateToVideoPlayer(with: player)
            }
        }
        
        if let index = self.currentActionIndex {
            self.currentActionIndex = index + 1
        }
    }
    
    public override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        setupVision()
        
        // start the capture
        startCaptureSession()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer()
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "close"), for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        return button
    }()
    
    func preLoadPanoramaView(media: UIImage) {
        panoramaViewController = PanoramaViewController()
        panoramaViewController?.image = media
        panoramaViewController?.loadViewIfNeeded()
    }
    
    // MARK: Navigation
    func navigateToPanoramaView() {
        guard let panoramaViewController = self.panoramaViewController else { return }
        DispatchQueue.main.async {
            panoramaViewController.modalPresentationStyle = .overCurrentContext
            panoramaViewController.transitioningDelegate = self
            self.present(panoramaViewController, animated: true, completion: nil)
        }
    }
    
    func navigateToPanoramaView(media: UIImage) {
        DispatchQueue.main.async {
            let panoramaViewController = PanoramaViewController()
            panoramaViewController.image = media
            panoramaViewController.modalPresentationStyle = .overCurrentContext
            panoramaViewController.transitioningDelegate = self
            self.present(panoramaViewController, animated: true, completion: nil)
        }
    }
    
    func navigateToVideoPlayer(with player: AVPlayer) {
        playerViewController.player = player
        playerViewController.modalPresentationStyle = .fullScreen
        playerViewController.modalPresentationCapturesStatusBarAppearance = true
        
        self.present(playerViewController, animated: true) {
            if let player = self.playerViewController.player {
                player.play()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    // MARK: Actions
    @objc func didTapClose() {
        self.dismiss(animated: true) {
            self.resetDetectionLabel()
        }
    }
    
    @objc func detectionButtonTapped() {
        guard let identifier = arDetailScreen else { return }
        if let actions = self.customARConfig?.objectLabelsWithActions[identifier] {
            self.currentIdentifier = identifier
            self.currentActionIndex = 0
            self.executeCurrentAction(actions: actions)
        }
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
        if let player = playerViewController.player {
            player.seek(to: .zero)
        }
        
        self.dismiss(animated: true) { [weak self] in
            guard let self = self, let identifier = self.currentIdentifier else { return }
            if let actions = self.customARConfig?.objectLabelsWithActions[identifier], let currentActionIndex = self.currentActionIndex, currentActionIndex < actions.count {
                let nextAction = actions[currentActionIndex]
                if nextAction.type == .panoramaView, let media = nextAction.media as? UIImage {
                    self.preLoadPanoramaView(media: media)
                    self.executeCurrentAction(actions: actions)
                } else {
                    self.executeCurrentAction(actions: actions)
                }
            }
        }
    }
}

extension CGFloat {
    static func randomGaussian(mean: CGFloat = 0.0, standardDeviation: CGFloat = 1.0) -> CGFloat {
        let x1 = CGFloat(arc4random()) / CGFloat(UInt32.max)
        let x2 = CGFloat(arc4random()) / CGFloat(UInt32.max)
        
        let z = sqrt(-2.0 * log(x1)) * cos(2.0 * .pi * x2)
        
        return z * standardDeviation + mean
    }
}

class CustomAVPlayerViewController: AVPlayerViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}
