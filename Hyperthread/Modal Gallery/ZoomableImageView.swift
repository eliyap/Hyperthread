//
//  ZoomableImageView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/3/22.
//

import UIKit
import SDWebImage
import Vision
import BlackBox

final class ZoomableImageView: UIScrollView {
    
    private let imageView: SelectableImageView
    
    private var aspectConstraint: NSLayoutConstraint? = nil

    @MainActor
    init() {
        self.imageView = .init()
        super.init(frame: .zero)
        
        /// Configure `self`.
        alwaysBounceVertical = false
        alwaysBounceHorizontal = false
        minimumZoomScale = 1
        maximumZoomScale = 5
        clipsToBounds = false
        self.delegate = self
        
        /// Match iOS's Photos app.
        decelerationRate = .fast
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        
        /// Configure `imageView`.
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        NSLayoutConstraint.activate([
            /// Use `≤`, not `=`, to keep small images at their intrinsic size.
            imageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor),
        ])
        
        /// Set up double tap to zoom.
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap))
        doubleTap.cancelsTouchesInView = false
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }
    
    public func configure(image: UIImage?, frame: CGRect) -> Void {
        guard let image = image else {
            TableLog.warning("Received nil image in modal!")
            return
        }

        imageView.image = image
        
        /// Constrain to exact aspect ratio.
        let aspectRatio: CGFloat
        aspectRatio = image.size.width / image.size.height
        let newAspectConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspectRatio)
        replace(object: self, on: \.aspectConstraint, with: newAspectConstraint)
        
        predictInsets(image: image, size: frame.size)
    }
    
    /// Convenience method.
    public func predictInsets(size: CGSize) -> Void {
        guard let image = imageView.image else {
            assert(false, "No image to predict with!")
            return
        }
        predictInsets(image: image, size: size)
    }
    
    /// Goal: predict layout insets to center the image, without requiring a layout pass.
    /// Since image size and layout rules are known, we can predict insets.
    public func predictInsets(image: UIImage, size: CGSize) -> Void {
        /// Predict `imageView` height.
        let tooTall = image.size.height > size.height
        let tooWide = image.size.width > size.width
        let prediction: CGSize
        switch (tooTall, tooWide) {
        case (false, false):
            prediction = image.size
            
        case (false, true):
            prediction = CGSize(
                width: size.width,
                height: image.size.height * (size.width / image.size.width)
            )
            
        case (true, false):
            prediction = CGSize(
                width: image.size.width * (size.height / image.size.height),
                height: size.height
            )
            
        case (true, true):
            if (image.size.height / image.size.width) > (size.height / size.width) {
                /// Image is proportionally taller than frame, will be height constrained.
                prediction = CGSize(
                    width: image.size.width * (size.height / image.size.height),
                    height: size.height
                )
            } else {
                /// Image is proportionally shorter than frame, will be width constrained.
                prediction = CGSize(
                    width: size.width,
                    height: image.size.height * (size.width / image.size.width)
                )
            }
        }
        
        let excessHeight = size.height - prediction.height
        let yInset = max(0, excessHeight / 2)
        
        let excessWidth = size.width - prediction.width
        let xInset = max(0, excessWidth / 2)
        
        /// 22.03.18
        /// Observed issue where edge insets interfere with dismissal gesture recognizer.
        /// Theory: view becomes imperceptibly "scrollable" due to floating point errors.
        /// Solution: reduce insets slightly so view is not scrollable.
        /// – Note: `UIScrollViewDelegate` methods did not fire, so theory may be incorrect.
        contentInset = UIEdgeInsets(
            top: yInset - 1,
            left: xInset - 1,
            bottom: yInset - 1,
            right: xInset - 1
        )
        
        /// Explicitly set content size to predicted value, as this does not update upon device rotation.
        contentSize = prediction
    }
    
    @objc
    private func didDoubleTap(recognizer: UITapGestureRecognizer) -> Void {
        if zoomScale == 1 {
            /// Zoom into tapped area.
            let rect = zoomRectForScale(scale: maximumZoomScale, center: recognizer.location(in: recognizer.view))
            zoom(to: rect, animated: true)
        } else {
            /// Zoom back out.
            setZoomScale(1, animated: true)
        }
    }
    
    /// Adapted from: https://stackoverflow.com/questions/3967971/how-to-zoom-in-out-photo-on-double-tap-in-the-iphone-wwdc-2010-104-photoscroll/46143499#46143499
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        let newCenter = imageView.convert(center, from: self)
        let width = imageView.frame.size.width  / scale
        let height = imageView.frame.size.height / scale
        return CGRect(
            origin: CGPoint(
                x: newCenter.x - (width / 2.0),
                y: newCenter.y - (height / 2.0)
            ),
            size: CGSize(width: width, height: height)
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ZoomableImageView: UIScrollViewDelegate {
    /// Required to enable zoom.
    /// Source: https://www.hackingwithswift.com/example-code/uikit/how-to-support-pinch-to-zoom-in-a-uiscrollview
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) -> Void {
        updateFloatCenter()
    }
    
    /// Abuses `contentInset` to cause undersized content to be centered,
    /// both horizontally and vertically.
    func updateFloatCenter(frame: CGRect? = nil) {
        /// Use own frame if none provided.
        let frame = frame ?? self.frame
        
        let excessHeight = frame.height - imageView.frame.height
        let yInset = max(0, excessHeight / 2)
        
        let excessWidth = frame.width - imageView.frame.width
        let xInset = max(0, excessWidth / 2)
        
        contentInset = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
    }
}

extension ZoomableImageView: GeometryTargetProvider {
    var targetView: UIView {
        imageView
    }
}

final class SelectableImageView: UIImageView {
    
    override var image: UIImage? {
        didSet {
            if let image = image {
                performRecognition(with: image)
            }
        }
    }
    
    let shadeView: UIView
    let fillLayer: CAShapeLayer
    let maskLayer: CAShapeLayer
    
    @MainActor
    init() {
        self.shadeView = .init()
        self.fillLayer = .init()
        self.maskLayer = .init()
        super.init(frame: .zero)
        
        addSubview(shadeView)
        shadeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            shadeView.topAnchor.constraint(equalTo: topAnchor),
            shadeView.bottomAnchor.constraint(equalTo: bottomAnchor),
            shadeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadeView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        shadeView.backgroundColor = .black.withAlphaComponent(0.7)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        renderRecognizedText()
    }
    
    /// Adapted from: https://medium.com/swlh/ios-secrets-see-behind-your-views-fe8afe9072a5
    private func setShadeMask(path: CGPath) -> Void {
        /// Shapes drawn in this layer are "cut out" of the shade view.
        let negativeLayer: CAShapeLayer = .init()
        
        let viewToRender: UIView = .init(frame: frame)
        viewToRender.layer.addSublayer(negativeLayer)
        viewToRender.backgroundColor = .white /// `CIMaskToAlpha` sets white pixels opaque.
        
        negativeLayer.path = path
        
        let renderer = UIGraphicsImageRenderer(bounds: frame)
        let image = renderer.image(actions: { context in
            viewToRender.layer.render(in: context.cgContext)
        })
        guard let unmasked = CIImage(image: image) else {
            assert(false, "Could not convert UIImage to CGImage")
            BlackBox.Logger.general.error("Could not convert UIImage to CGImage")
            return
        }
        
        let maskView = UIImageView(image: UIImage(ciImage: unmasked.applyingFilter("CIMaskToAlpha")))
        maskView.frame = frame
        shadeView.mask = maskView
    }
    
    private func performRecognition(with image: UIImage) {
        /// 22.03.21 without `Task` wrapper, `DispatchQueue` call caused UI hitches and concurrency runtime warnings.
        Task { @MainActor in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let cgImage = image.cgImage else {
                    assert(false, "Could not obtain CGImage from UIImage")
                    BlackBox.Logger.general.warning("Could not obtain CGImage from UIImage")
                    return
                }
                
                let request = VNRecognizeTextRequest(completionHandler: { [weak self] (request: VNRequest?, error: Error?) in
                    if let error = error {
                        assert(false, "Error \(error)")
                        BlackBox.Logger.general.error("Vision Reqest Error: \(error)")
                        return
                    }
                    guard let results = request?.results else {
                        assert(false, "Request returned no results")
                        return
                    }
                    
                    /// Only look at the best candidate.
                    /// We have _absolutely no idea_ what's coming through twitter, so we have no way to rank candidates.
                    let maxCandidates = 1
                    let textResults = results.compactMap { (result) -> VisionTextResult? in
                        guard let observation = result as? VNRecognizedTextObservation else {
                            return nil
                        }
                        guard let candidate: VNRecognizedText = observation.topCandidates(maxCandidates).first else {
                            return nil
                        }
                        return VisionTextResult(candidate)
                    }
                    
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        self.results = textResults
                    }
                })
                request.customWords = [] /// None, for now.
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.progressHandler = { (request: VNRequest, progress: Double, error: Error?) in
                    #warning("TODO: show request progress")
                }

                /// Dispatch request.
                let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage)
                do {
                    try imageRequestHandler.perform([request])
                } catch let error {
                    assert(false, "Vision request failed with error \(error)")
                    BlackBox.Logger.general.error("Vision request failed with error \(error)")
                    return
                }
            }
        }
    }
    
    var results: [VisionTextResult] = []
    private func renderRecognizedText() -> Void {
        for result in results {
            #warning("TODO: use string")
            print("Recognized string: \(result.text)")
            print("got box \(result.box)")
        }
        
        setShadeMask(path: UIBezierPath(roundedRect: frame, cornerRadius: 20).cgPath)
        print("mask set.")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Simplified representation of `VNRecognizedText`.
struct VisionTextResult: Sendable {
    let text: String
    let box: Self.Box?
    
    init(_ vn: VNRecognizedText) {
        text = vn.string
        
        let textRange: Range<String.Index> = text.startIndex..<text.endIndex
        if let rect = try? vn.boundingBox(for: textRange) {
            box = .init(topLeft: rect.topLeft, topRight: rect.topRight, bottomLeft: rect.bottomLeft, bottomRight: rect.bottomRight)
        } else {
            box = nil
        }
    }
}

extension VisionTextResult {
    struct Box: Sendable {
        let topLeft: CGPoint
        let topRight: CGPoint
        let bottomLeft: CGPoint
        let bottomRight: CGPoint
    }
}
