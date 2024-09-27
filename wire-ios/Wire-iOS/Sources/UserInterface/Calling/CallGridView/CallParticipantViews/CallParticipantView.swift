//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import avs
import UIKit
import WireSyncEngine

final class CallParticipantView: BaseCallParticipantView {
    // MARK: Lifecycle

    // MARK: - Initialization

    override init(
        stream: Stream,
        isCovered: Bool,
        shouldShowActiveSpeakerFrame: Bool,
        shouldShowBorderWhenVideoIsStopped: Bool,
        pinchToZoomRule: PinchToZoomRule
    ) {
        super.init(
            stream: stream,
            isCovered: isCovered,
            shouldShowActiveSpeakerFrame: shouldShowActiveSpeakerFrame,
            shouldShowBorderWhenVideoIsStopped: shouldShowBorderWhenVideoIsStopped,
            pinchToZoomRule: pinchToZoomRule
        )

        updateState()
    }

    // MARK: Internal

    // MARK: - Public Properties

    var isPaused = false {
        didSet {
            guard oldValue != isPaused else {
                return
            }
            updateState(animated: true)
        }
    }

    // MARK: - Setup

    override func setupViews() {
        super.setupViews()

        for item in [blurView, pausedLabel] {
            item.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(item, belowSubview: userDetailsView)
        }
        pausedLabel.textAlignment = .center
    }

    override func createConstraints() {
        super.createConstraints()
        blurView.fitIn(view: self)
        pausedLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        pausedLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    // MARK: Override Base

    override func updateVideoShouldFill(_ shouldFill: Bool) {
        videoView?.shouldFill = shouldFill
    }

    // MARK: Private

    // MARK: - Private Properties

    private weak var videoContainerView: AVSVideoContainerView?
    private weak var videoView: AVSVideoView?
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let pausedLabel = UILabel(
        key: "call.video.paused",
        size: .normal,
        weight: .semibold,
        color: .white
    )
    private var snapshotView: UIView?

    // MARK: - Paused state update

    private func updateState(animated: Bool = false) {
        if isPaused {
            createSnapshotView()
            blurView.effect = nil
            pausedLabel.alpha = 0
            blurView.isHidden = false
            pausedLabel.isHidden = false

            executeAnimations(animated: animated) { [weak self] in
                self?.blurView.effect = UIBlurEffect(style: .dark)
                self?.pausedLabel.alpha = 1
            } completionBlock: { [weak self] _ in
                self?.videoContainerView?.removeFromSuperview()
            }
        } else {
            createVideoContainer()
            updateVideoShouldFill(shouldFill)

            executeAnimations(animated: animated, animationBlock: { [weak self] in
                self?.blurView.effect = nil
                self?.snapshotView?.alpha = 0
                self?.pausedLabel.alpha = 0
            }, completionBlock: { [weak self] _ in
                self?.snapshotView?.removeFromSuperview()
                self?.snapshotView = nil
                self?.blurView.isHidden = true
                self?.pausedLabel.isHidden = true
            })
        }
    }

    private func createVideoContainer() {
        let videoContainerView = AVSVideoContainerView()
        videoContainerView.backgroundColor = .clear
        videoContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.videoContainerView?.removeFromSuperview()
        self.videoContainerView = videoContainerView

        let videoView = makeVideoView()
        self.videoView = videoView
        videoContainerView.setupVideoView(videoView)

        // Adding the preview into a container allows smoother scaling
        let scalableView = ScalableView(isScalingEnabled: shouldEnableScaling)
        scalableView.addSubview(videoContainerView)
        self.scalableView?.removeFromSuperview()
        self.scalableView = scalableView

        if let snapshotView {
            insertSubview(scalableView, belowSubview: snapshotView)
        } else {
            insertSubview(scalableView, belowSubview: userDetailsView)
        }

        for item in [scalableView, videoContainerView] {
            item.translatesAutoresizingMaskIntoConstraints = false
            item.fitIn(view: self)
        }
    }

    private func createSnapshotView() {
        guard let snapshotView = videoView?.snapshotView(afterScreenUpdates: true) else {
            return
        }
        insertSubview(snapshotView, belowSubview: blurView)
        snapshotView.translatesAutoresizingMaskIntoConstraints = false
        snapshotView.fitIn(view: blurView)
        self.snapshotView = snapshotView
    }

    private func executeAnimations(
        animated: Bool,
        animationBlock: @escaping () -> Void,
        completionBlock: @escaping (Bool) -> Void
    ) {
        if animated {
            UIView.animate(withDuration: 0.2, animations: animationBlock, completion: completionBlock)
        } else {
            animationBlock()
            completionBlock(true)
        }
    }

    private func makeVideoView() -> AVSVideoView {
        let videoView = AVSVideoView()
        videoView.backgroundColor = .clear
        videoView.userid = stream.streamId.avsIdentifier.serialized
        videoView.clientid = stream.streamId.clientId
        videoView.shouldFill = shouldFill

        return videoView
    }
}
