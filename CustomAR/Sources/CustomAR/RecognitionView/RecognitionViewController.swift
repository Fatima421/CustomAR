//
//  RecognitionViewController.swift
//  AugmentedReality
//
//  Created by Fatima Syed on 27/3/23.
//

import UIKit
import AVFoundation
import Vision

open class RecognitionViewController: ARViewController {
    
    private var detectionOverlay: CALayer! = nil
    private var requests = [VNRequest]()
    private var hasNavigatedToPanoramaView: Bool = false
    private var detectionTimer: Timer?
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasNavigatedToPanoramaView = false
        resetZoom()
        if detectionOverlay.superlayer == nil {
            rootLayer.addSublayer(detectionOverlay)
        }
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
        let config = MLModelConfiguration()
        guard let model = try? SafaCruzModel(configuration: config) else { return }
        guard let objectDetectionModel = try? VNCoreMLModel(for: model.model) else { return }
        
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
    
    func drawVisionRequestResults(_ results: [Any]) {
        detectionOverlay.sublayers = nil
        
        if let objectObservation = results.compactMap({ $0 as? VNRecognizedObjectObservation })
            .filter({ $0.confidence > 0.5 })
            .max(by: { $0.confidence < $1.confidence }) {
            
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))

            if detectionTimer == nil {
                detectionTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                    self?.detectionOverlay.removeFromSuperlayer()
                    self?.detectionTimerExpired(objectBounds)
                }
            }
                                    
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            detectionOverlay.addSublayer(shapeLayer)
        } else {
            detectionTimer?.invalidate()
            detectionTimer = nil
        }
        self.updateLayerGeometry()
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

    
    func detectionTimerExpired(_ objectBounds: CGRect) {
        if !hasNavigatedToPanoramaView {
            hasNavigatedToPanoramaView = true
            zoomAnimation(duration: 0.5, scale: 8, objectBounds: objectBounds) {
                self.navigateToPanoramaView()
            }
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
    
    // MARK: Navigation
    func navigateToPanoramaView() {
        DispatchQueue.main.async {
            let panoramaViewController = PanoramaViewController()
            panoramaViewController.image = UIImage(named: "sagrada", in: Bundle.module, compatibleWith: nil) // Replace with your desired panorama image
            self.navigationController?.pushViewController(panoramaViewController, animated: true)
        }
    }
}
