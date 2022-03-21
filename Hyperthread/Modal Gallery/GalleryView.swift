//
//  GalleryView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit

final class GalleryView: UIView {
    
    private weak var pageView: ModalPageView!
    private let topShade: TopShadeView
    private let imageCount: Int
    
    public weak var closeDelegate: CloseDelegate? = nil
    
    private var shadesHidden = false
    
    init(pageView: ModalPageView, imageCount: Int, startIndex: Int) {
        self.pageView = pageView
        self.topShade = .init(imageCount: imageCount, startIndex: startIndex)
        self.imageCount = imageCount
        super.init(frame: .zero)
        
        pageView.pageDelegate = topShade
        pageView.shadeToggleDelegate = self
        topShade.closeDelegate = self
        
        addSubview(pageView)
        addSubview(topShade)
    }
    
    /// Called by superview.
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        pageView.constrain(to: self)
        topShade.constrain(to: self)
    }
    
    public func prepareDismissal(snapshot: UIView) -> Void {
        /// - Note: transition takes care of removing from superview in case of cancellation.
        insertSubview(snapshot, belowSubview: topShade)
    }
    
    public func transitionShow() -> Void {
        /// If shades are already hidden, leave them hidden when transitioning.
        if shadesHidden == false {
            topShade.transitionShow()
        }
    }
    
    public func transitionHide() -> Void {
        topShade.transitionHide()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GalleryView: CloseDelegate {
    func closeGallery() {
        closeDelegate?.closeGallery()
    }
}

extension GalleryView: GeometryTargetProvider {
    var targetView: UIView {
        pageView.targetView
    }
}

extension GalleryView: ShadeToggleDelegate {
    func toggleShades() {
        if shadesHidden {
            UIView.animate(
                withDuration: 0.25,
                delay: .zero,
                options: [.curveEaseOut],
                animations: { [weak self] in
                    self?.topShade.transitionShow()
                    self?.shadesHidden = false
                },
                completion: nil
            )
        } else {
            UIView.animate(
                withDuration: 0.25,
                delay: .zero,
                options: [.curveEaseIn],
                animations: { [weak self] in
                    self?.topShade.transitionHide()
                    self?.shadesHidden = true
                },
                completion: nil
            )
        }
    }
}