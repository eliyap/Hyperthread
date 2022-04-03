//
//  SelectableImageView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 26/3/22.
//

import UIKit
import Vision
import BlackBox
import LTImage

extension SelectableImageView: ActiveCellDelegate {
    func didBecomeActiveCell() {
        visionImageView.didBecomeActiveCell()
    }
}

extension SelectableImageView: GeometryTargetProvider {
    var targetView: UIView {
        visionImageView
    }
}
