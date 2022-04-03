//
//  GalleryView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit
import LTImage

final class GalleryView: UIView {
    
    /// Component Views
    private weak var pageView: ModalPageView!
    private let topShade: TopShadeView
    private let bottomShade: BottomShadeView
    
    /// State information.
    private let imageCount: Int
    public private(set) var areShadesHidden = false
    
    /// Delegates.
    public weak var closeDelegate: CloseDelegate? {
        get { topShade.closeDelegate }
        set { topShade.closeDelegate = newValue }
    }
    public weak var shadeToggleDelegate: ShadeToggleDelegate? = nil
    
    init(imageCount: Int, startIndex: Int) {
        self.topShade = .init(imageCount: imageCount, startIndex: startIndex)
        self.bottomShade = .init()
        self.imageCount = imageCount
        super.init(frame: .zero)
        
        addSubview(topShade)
        addSubview(bottomShade)
        
        topShade.textRequestDelegate = self
    }
    
    /// Due to a circular (weak) dependency, we need to do a little dance.
    public func bindPageView(_ pageView: ModalPageView) {
        self.pageView = pageView
        pageView.pageDelegate = topShade
        pageView.shadeToggleDelegate = self
        insertSubview(pageView, at: 0)
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
        bottomShade.constrain(to: self)
    }
    
    public func insert(snapshot: UIView) -> Void {
        /// - Note: transition takes care of removing from superview in case of cancellation.
        insertSubview(snapshot, belowSubview: topShade)
    }
    
    public func transitionShow() -> Void {
        /// If shades are already hidden, leave them hidden when transitioning.
        if areShadesHidden == false {
            topShade.transitionShow()
            bottomShade.transitionShow()
        }
    }
    
    public func transitionHide() -> Void {
        topShade.transitionHide()
        bottomShade.transitionHide()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GalleryView: GeometryTargetProvider {
    var targetView: UIView {
        pageView.targetView
    }
}

extension GalleryView: ShadeToggleDelegate {
    func toggleShades() {
        if areShadesHidden {
            UIView.animate(
                withDuration: 0.25,
                delay: .zero,
                options: [.curveEaseOut],
                animations: { [weak self] in
                    self?.topShade.transitionShow()
                    self?.bottomShade.transitionShow()
                    self?.areShadesHidden = false
                    self?.shadeToggleDelegate?.toggleShades()
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
                    self?.bottomShade.transitionHide()
                    self?.areShadesHidden = true
                    self?.shadeToggleDelegate?.toggleShades()
                },
                completion: nil
            )
        }
    }
}

extension GalleryView: ImageVisionDelegate {
    func didReport(progress: Double) -> Void {
        /// Disable view updates while scrolling.
        /// Update is requested when scrolling stops, so final still will certainly be reported.
        guard pageView.isScrolling == false else { return }
        
        topShade.didReport(progress: progress)
    }
    
    func didChangeHighlightState(to highlighting: Bool) {
        topShade.didChangeHighlightState(to: highlighting)
    }
}

extension GalleryView: TextRequestDelegate {
    func didRequestText(show: Bool?) -> Void {
        /// Simply forwards request.
        pageView.didRequestText(show: show)
    }
}
