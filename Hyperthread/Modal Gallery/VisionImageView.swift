import LTImage

extension VisionImageView: ActiveCellDelegate {
    func didBecomeActiveCell() {
        /// Report progress when cell becomes active, so that button may be updated.
        imageVisionDelegate?.didReport(progress: visionRequestProgress)
    }
}
