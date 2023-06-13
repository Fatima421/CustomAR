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
import Combine

open class RecognitionViewController: ARViewController, UIViewControllerTransitioningDelegate {
    
    // MARK: - Properties
    
    private var detectionOverlay: CALayer! = nil
    private var requests = [VNRequest]()
    private var hasNavigatedToPanoramaView: Bool = false
    private var detectionTimer: Timer?
    private var detectionRestartTimer: Timer?
    private var currentActionIndex: Int?
    
    public var detectionTime: Double?
    public var detectionInterval: Double?
    public var customARConfig: CustomARConfig?
    public let objectDetectedSubject = PassthroughSubject<DetectedObject, Never>()
    
    public var customBackButton: UIButton?
    public var customHelpButton: UIButton?
    public var backButtonTapped: (() -> Void)?
    public var helpIconTapped: (() -> Void)?
    public var capturedBuffer: CMSampleBuffer?
    
    // MARK: - Life Cycle
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restartCaptureSession()
        initialParameters()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCaptureSession()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        restartCaptureSession()
        initialParameters()
    }
    
    func initialParameters() {
        hasNavigatedToPanoramaView = false
        resetZoom()
        if detectionOverlay.superlayer == nil {
            rootLayer.addSublayer(detectionOverlay)
        }
        setupView()
    }
    
    // MARK: - Capture Session
    
    public override func startCaptureSession() {
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
    }
    
    func resetZoom() {
        DispatchQueue.main.async {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.25)
            
            self.previewLayer?.transform = CATransform3DIdentity
            self.previewLayer?.anchorPoint = CGPoint(x: 0.5, y: 0.5) // Reset anchorPoint
            self.previewLayer?.position = CGPoint(x: self.rootLayer.bounds.midX, y: self.rootLayer.bounds.midY) // Reset position
            
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
    
    private func setupView() {
        if let backButton = customBackButton, let helpButton = customHelpButton {
            view.addSubview(backButton)
            view.addSubview(helpButton)
            
            backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
            helpButton.addTarget(self, action: #selector(didTapHelpIcon), for: .touchUpInside)
            
            backButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                backButton.widthAnchor.constraint(equalToConstant: 44),
                backButton.heightAnchor.constraint(equalToConstant: 44),
                backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
            ])
            
            helpButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                helpButton.widthAnchor.constraint(equalToConstant: 44),
                helpButton.heightAnchor.constraint(equalToConstant: 44),
                helpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                helpButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
            ])
        }
    }
    
    @objc func didTapBackButton() {
        backButtonTapped?()
    }
    
    @objc func didTapHelpIcon() {
        helpIconTapped?()
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        detectionOverlay.sublayers = nil
        
        if let objectObservation = results.compactMap({ $0 as? VNRecognizedObjectObservation })
            .filter({ $0.confidence > 0.5 })
            .max(by: { $0.confidence < $1.confidence }) {
            
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            if detectionTimer == nil {
                detectionTimer = Timer.scheduledTimer(withTimeInterval: detectionTime ?? 2.0, repeats: false) { [weak self] _ in
                    self?.detectionOverlay.removeFromSuperlayer()
                    let labelName = objectObservation.labels.first?.identifier
                    if let labelName = labelName {
                        self?.detectionTimerExpired(objectBounds, identifier: labelName)
                    }
                }
            } else {
                detectionRestartTimer?.invalidate()
            }
            
            detectionRestartTimer = Timer.scheduledTimer(withTimeInterval: detectionInterval ?? 0.5, repeats: false) { [weak self] _ in
                self?.detectionTimer?.invalidate()
                self?.detectionTimer = nil
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
        
        let path = UIBezierPath()
        
        let numberOfDots = Int(bounds.width * bounds.height * density)
        
        for _ in 0..<numberOfDots {
            let x = bounds.origin.x + CGFloat.random(in: 0..<bounds.width)
            let y = bounds.origin.y + CGFloat.random(in: 0..<bounds.height)
            path.move(to: CGPoint(x: x, y: y))
            path.addArc(withCenter: CGPoint(x: x, y: y), radius: dotRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        shape.fillColor = UIColor.yellow.cgColor
        shapeLayer.addSublayer(shape)
        
        let maskLayer = CAShapeLayer()
        let maskPath = UIBezierPath(roundedRect: bounds, cornerRadius: 10)
        maskLayer.path = maskPath.cgPath
        shapeLayer.mask = maskLayer
        
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
    
    
    func detectionTimerExpired(_ objectBounds: CGRect, identifier: String) {
        if !hasNavigatedToPanoramaView {
            hasNavigatedToPanoramaView = true
            objectDetected(identifier)
            if let actions = self.customARConfig?.objectLabelsWithActions[identifier] {
                self.currentActionIndex = 0
                self.executeCurrentAction(actions: actions)
            }
        }
    }
    
    func convert(cmage: CIImage) -> UIImage {
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(cmage, from: cmage.extent)!
        let image = UIImage(cgImage: cgImage)
        return image
    }
    
    func objectDetected(_ identifier: String) {
        DispatchQueue.main.async {
            guard
                let capturedBuffer = self.capturedBuffer,
                let imageBuffer = CMSampleBufferGetImageBuffer(capturedBuffer)
            else { return }
            
            let ciimage = CIImage(cvPixelBuffer: imageBuffer)
            let image = self.convert(cmage: ciimage)
            let detectedObject = DetectedObject(identifier: identifier, image: image)
            self.objectDetectedSubject.send(detectedObject)
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
            if let videoURL = action.media as? URL {
                self.navigateToVideoPlayer(media: videoURL)
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
        
        DispatchQueue.main.async {
            self.capturedBuffer = sampleBuffer
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
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
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
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
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
    
    // MARK: Navigation
    func navigateToPanoramaView(media: UIImage) {
        DispatchQueue.main.async {
            let panoramaViewController = PanoramaViewController()
            panoramaViewController.image = media
            panoramaViewController.modalPresentationStyle = .overCurrentContext
            panoramaViewController.transitioningDelegate = self
            self.present(panoramaViewController, animated: true, completion: nil)
        }
    }
    
    func navigateToVideoPlayer(media: URL) {
        // TODO: ADD VIDEO PLAYER
    }
    
    @objc func didTapClose() {
        self.dismiss(animated: true)
    }
}
