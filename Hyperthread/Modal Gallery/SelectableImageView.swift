//
//  SelectableImageView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 26/3/22.
//

import UIKit
import Vision
import BlackBox

final class SelectableImageView: UIImageView {
    
    override var image: UIImage? {
        didSet {
            if let image = image {
                performRecognition(with: image)
            }
        }
    }
    
    private let shadeView: UIView
    private var isShadeShowing = false
    
    /// Progress value for the vision request on the image.
    /// 0 when image is nil.
    public private(set) var visionRequestProgress: Double = 0
    
    /// Delegates.
    public weak var imageVisionDelegate: ImageVisionDelegate? = nil
    
    private let tokenizer: UITextInputStringTokenizer
    
    @MainActor
    init() {
        self.tokenizer = .init()
        self.shadeView = .init()
        super.init(frame: .zero)
        
        /// Add view to darken non-text areas when the user activates "live text mode".
        addSubview(shadeView)
        shadeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            shadeView.topAnchor.constraint(equalTo: topAnchor),
            shadeView.bottomAnchor.constraint(equalTo: bottomAnchor),
            shadeView.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadeView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        shadeView.backgroundColor = .black.withAlphaComponent(0.7)
        shadeView.layer.opacity = .zero
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
                        self.renderRecognizedText(results: textResults)
                        
                        /// Report completion, which sometimes does not happen with the progress handler.
                        self.imageVisionDelegate?.didReport(progress: 1.0)
                        self.visionRequestProgress = 1.0
                    }
                })
                request.customWords = [] /// None, for now.
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.progressHandler = { [weak self] (request: VNRequest, progress: Double, error: Error?) in
                    guard let self = self else { return }
                    Task { @MainActor in
                        self.imageVisionDelegate?.didReport(progress: progress)
                        self.visionRequestProgress = progress
                    }
                    
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
    
    private func renderRecognizedText(results: [VisionTextResult]) -> Void {
        let path = CGMutablePath()
        for result in results {
            guard let box = result.box else { continue }
            path.addPath(box.cgPath(in: frame))
            
            #warning("TODO: use string")
//            print("Recognized string: \(result.text)")
//            print("got box \(result.box)")
        }
        setShadeMask(path: path)
        print("mask set.")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A class that receives or forwards information about a `Vision` request through the application.
protocol ImageVisionDelegate: AnyObject {
    /// Handle information from `VNRecognizeTextRequest.progressHandler`, or the request's completion.
    @MainActor
    func didReport(progress: Double) -> Void
    
    /// Handle updates about the highlighting state of the view.
    @MainActor
    func didChangeHighlightState(to highlighting: Bool) -> Void
}

protocol TextRequestDelegate: AnyObject {
    /// Indicates a request to show or hide live text.
    /// If no state is specified, consider this a toggle request.
    @MainActor
    func didRequestText(show: Bool?) -> Void
}

extension SelectableImageView: TextRequestDelegate {
    func didRequestText(show: Bool?) {
        let animationDuration = 0.15
        UIView.animate(withDuration: animationDuration, delay: .zero, options: [], animations: { [weak self] in
            guard let self = self else { return }
            switch (show, self.isShadeShowing) {
            case (.some(true), _), (nil, false):
                self.isShadeShowing = true
                self.shadeView.layer.opacity = 1
                self.imageVisionDelegate?.didChangeHighlightState(to: true)
            
            case (.some(false), _), (nil, true):
                self.isShadeShowing = false
                self.shadeView.layer.opacity = .zero
                self.imageVisionDelegate?.didChangeHighlightState(to: false)
            }
        }, completion: nil)
    }
}

extension SelectableImageView: ActiveCellDelegate {
    func didBecomeActiveCell() {
        /// Report progress when cell becomes active, so that button may be updated.
        imageVisionDelegate?.didReport(progress: visionRequestProgress)
    }
}

final class LiveTextPosition: UITextPosition {
    
    override init() {
        super.init()
    }
}

final class LiveTextRange: UITextRange {
    private var _start: LiveTextPosition
    private var _end: LiveTextPosition
    override var start: UITextPosition {
        get { _start }
        set { _start = newValue as! LiveTextPosition }
    }
    override var end: UITextPosition {
        get { _end }
        set { _end = newValue as! LiveTextPosition }
    }
    
    init(start: LiveTextPosition, end: LiveTextPosition) {
        self._start = start
        self._end = end
        super.init()
    }
}

extension SelectableImageView: UITextInput {
    func text(in range: UITextRange) -> String? {
        <#code#>
    }
    
    var selectedTextRange: UITextRange? {
        get {
            <#code#>
        }
        set(selectedTextRange) {
            <#code#>
        }
    }
    
    var beginningOfDocument: UITextPosition {
        #warning("TODO")
        let pos: LiveTextPosition = .init()
        return pos
    }
    
    var endOfDocument: UITextPosition {
        #warning("TODO")
        let pos: LiveTextPosition = .init()
        return pos
    }
    
    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        <#code#>
    }
    
    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        <#code#>
    }
    
    func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        <#code#>
    }
    
    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        <#code#>
    }
    
    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        <#code#>
    }
    
    var inputDelegate: UITextInputDelegate? {
        get {
            <#code#>
        }
        set(inputDelegate) {
            <#code#>
        }
    }
    
    var tokenizer: UITextInputTokenizer {
        <#code#>
    }
    
    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        <#code#>
    }
    
    func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        <#code#>
    }
    
    func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        <#code#>
    }
    
    func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        <#code#>
    }
    
    func firstRect(for range: UITextRange) -> CGRect {
        <#code#>
    }
    
    func caretRect(for position: UITextPosition) -> CGRect {
        <#code#>
    }
    
    func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        <#code#>
    }
    
    func closestPosition(to point: CGPoint) -> UITextPosition? {
        <#code#>
    }
    
    func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        <#code#>
    }
    
    func characterRange(at point: CGPoint) -> UITextRange? {
        <#code#>
    }
    
    var hasText: Bool {
        <#code#>
    }
    
    func insertText(_ text: String) {
        <#code#>
    }
    
    func deleteBackward() {
        <#code#>
    }
    
    /// No text input.
    var markedTextRange: UITextRange? { return nil }
    
    /// No text input.
    var markedTextStyle: [NSAttributedString.Key : Any]? {
        get { return nil }
        set(markedTextStyle) { assert(false, "Do not set marked text!") }
    }
    
    /// No text input.
    func setMarkedText(_ markedText: String?, selectedRange: NSRange) { assert(false, "Do not set marked text!") }
    
    /// No text input.
    func unmarkText() { assert(false, "Do not set marked text!") }
    
    /// Cannot edit contents.
    func replace(_ range: UITextRange, withText text: String) {
        assert(false, "Non Editable!")
    }
}
