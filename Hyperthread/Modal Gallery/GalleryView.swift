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
    
    init(pageView: ModalPageView, imageCount: Int, startIndex: Int) {
        self.pageView = pageView
        self.topShade = .init(imageCount: imageCount, startIndex: startIndex)
        self.imageCount = imageCount
        super.init(frame: .zero)
        
        pageView.pageDelegate = topShade
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
        topShade.transitionShow()
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
