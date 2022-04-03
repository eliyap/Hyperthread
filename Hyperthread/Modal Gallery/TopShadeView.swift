//
//  TopShadeView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 20/3/22.
//

import UIKit
import BlackBox
import LTImage

final class TopShadeView: UIView {
    
    private let closeButton: ShadeCloseButton
    private let countLabel: UILabel
    private let liveTextButton: LiveTextButton
    private let imageCount: Int
    
    public weak var closeDelegate: CloseDelegate? {
        get { closeButton.closeDelegate }
        set { closeButton.closeDelegate = newValue }
    }
    
    public weak var textRequestDelegate: TextRequestDelegate? {
        get { liveTextButton.textRequestDelegate }
        set { liveTextButton.textRequestDelegate = newValue }
    }
    
    @MainActor
    init(imageCount: Int, startIndex: Int) {
        self.closeButton = .init()
        self.countLabel = .init()
        self.liveTextButton = .init()
        self.imageCount = imageCount
        super.init(frame: .zero)
        
        backgroundColor = .galleryShade
        
        addSubview(closeButton)
        addSubview(countLabel)
        addSubview(liveTextButton)
        
        countLabel.text = "–/–"
        countLabel.textColor = .galleryUI
        countLabel.font = UIFont.preferredFont(forTextStyle: .body)
        countLabel.adjustsFontForContentSizeCategory = true
        if imageCount == 1 {
            countLabel.isHidden = true
        }
        
        setPageLabel(pageNo: startIndex)
    }
    
    public func transitionShow() -> Void {
        transform = .identity
        layer.opacity = 1
    }
    
    public func transitionHide() -> Void {
        transform = .init(translationX: .zero, y: -frame.height)
        layer.opacity = 0
    }
    
    /// Called by superview.
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            /// Full width, ignoring safe area in iPhone landscape.
            leftAnchor.constraint(equalTo: view.leftAnchor),
            rightAnchor.constraint(equalTo: view.rightAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
        ])
        
        let horizontalMargin = 1.5
        
        let topConstraint: NSLayoutConstraint
        if UIDevice.current.userInterfaceIdiom == .pad {
            /// On iPad, there's a jump when we hide the status bar because it's not hiding up with the notch.
            /// To avoid this, we use a fixed distance rather than the safe-area layout guide.
            let barHeight = getStatusBarHeight()
            topConstraint = countLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: barHeight)
        } else {
            topConstraint = countLabel.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 0.5)
        }
        
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: countLabel.centerXAnchor),
            /// Ensure view covers label.
            bottomAnchor.constraint(equalToSystemSpacingBelow: countLabel.bottomAnchor, multiplier: 1),
            topConstraint,
        ])
        
        closeButton.constrain(parent: self, sibling: countLabel, horizontalMargin: horizontalMargin)
        liveTextButton.constrain(parent: self, sibling: countLabel, horizontalMargin: horizontalMargin)
    }
    
    private func setPageLabel(pageNo: Int) -> Void {
        countLabel.text = "\(pageNo)/\(imageCount)"
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TopShadeView: PageDelegate {
    func didScrollTo(pageNo: Int) -> Void {
        setPageLabel(pageNo: pageNo)
    }
}

protocol ShadeToggleDelegate: AnyObject {
    @MainActor
    func toggleShades() -> Void
}

extension TopShadeView: ImageVisionDelegate {
    func didReport(progress: Double) {
        liveTextButton.didReport(progress: progress)
    }
    
    func didChangeHighlightState(to highlighting: Bool) {
        liveTextButton.didChangeHighlightState(to: highlighting)
    }
}
