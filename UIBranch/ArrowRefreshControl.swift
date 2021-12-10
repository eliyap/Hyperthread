//
//  ArrowRefreshControl.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 8/12/21.
//

import UIKit

final class ArrowRefreshView: UIView {

    private let arrowView: UIImageView
    private let indicator = UIActivityIndicatorView()

    public static let offset: CGFloat = 50
    private var threshhold: CGFloat { 2 * Self.offset }
    
    weak var scrollView: UIScrollView?
    
    private let inactiveTint = UIColor.systemGray4
    private let activeTint = UIColor.label
    
    private let onRefresh: () -> ()
    
    private var isRefreshing = false
    
    init(scrollView: UIScrollView, onRefresh: @escaping () -> ()) {
        self.scrollView = scrollView
        self.onRefresh = onRefresh
        let config = UIImage.SymbolConfiguration(textStyle: .headline)
        arrowView = UIImageView(image: UIImage(systemName: "arrow.up", withConfiguration: config))
        
        super.init(frame: .zero)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(arrowView)
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            arrowView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
        
        addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
        
        styleInactivated()
    }
    
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            bottomAnchor.constraint(equalTo: view.topAnchor, constant: -ArrowRefreshView.offset),
        ])
    }
    
    public func didScroll(offset: CGFloat) -> Void {
        /// Ignore scrolling during the  refresh animation.
        guard isRefreshing == false else { return }
        
        /// Ignore scrolling if the user's finger isn't down.
        /// This prevents the arrow flipping when the view "bounces" against the top, which might cause confusion.
        guard (scrollView?.isTracking ?? false) else { return }
        
        style(selected: -offset > threshhold)
    }
    
    public func didStopScrolling(offset: CGFloat) -> Void {
        if -offset > threshhold {
            onRefresh()
        }
    }
    
    public func beginRefreshing() -> Void {
        isRefreshing = true
        styleSpinning()
    }
    
    public func endRefreshing() -> Void {
        isRefreshing = false
        styleInactivated()
    }
    
    private func style(selected: Bool) -> Void {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else {
                assert(false, "self is nil")
                return
            }
            /// By changing the radius, offset, and transform at the same time, we can grow / shrink the shadow in place,
            /// creating a "lifting" illusion.
            if selected {
                self.styleActivated()
            } else {
                self.styleInactivated()
            }
        }
    }
    
    private func styleActivated() -> Void {
        arrowView.transform = CGAffineTransform(rotationAngle: .pi)
        arrowView.tintColor = activeTint
        indicator.stopAnimating()
    }

    private func styleInactivated() -> Void {
        arrowView.transform = .identity
        arrowView.tintColor = inactiveTint
        indicator.stopAnimating()
    }
    
    private func styleSpinning() -> Void {
        arrowView.tintColor = .clear
        indicator.startAnimating()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
