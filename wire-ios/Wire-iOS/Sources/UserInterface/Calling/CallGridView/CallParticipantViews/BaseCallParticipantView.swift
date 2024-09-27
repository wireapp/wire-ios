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
import WireCommonComponents
import WireDesign
import WireSyncEngine

// MARK: - BaseCallParticipantView

class BaseCallParticipantView: OrientableView {
    // MARK: Lifecycle

    // MARK: - View Life Cycle

    init(
        stream: Stream,
        isCovered: Bool,
        shouldShowActiveSpeakerFrame: Bool,
        shouldShowBorderWhenVideoIsStopped: Bool,
        pinchToZoomRule: PinchToZoomRule
    ) {
        self.stream = stream
        self.isCovered = isCovered
        self.shouldShowActiveSpeakerFrame = shouldShowActiveSpeakerFrame
        self.shouldShowBorderWhenVideoIsStopped = shouldShowBorderWhenVideoIsStopped
        self.pinchToZoomRule = pinchToZoomRule

        super.init(frame: .zero)

        setupViews()
        createConstraints()
        updateUserDetails()
        updateVideoKind()
        updateBorderStyle()
        hideVideoViewsIfNeeded()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateUserDetailsVisibility),
            name: .videoGridVisibilityChanged,
            object: nil
        )
        setupAccessibility()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let userDetailsView = CallParticipantDetailsView()
    var scalableView: ScalableView?
    var avatarView = UserImageView(size: .normal)
    var userSession = ZMUserSession.shared()

    // MARK: - Public Properties

    var stream: Stream {
        didSet {
            updateUserDetails()
            updateBorderStyle()
            updateVideoKind()
            hideVideoViewsIfNeeded()
            setupAccessibility()
        }
    }

    var shouldShowActiveSpeakerFrame: Bool {
        didSet {
            updateBorderStyle()
        }
    }

    var shouldShowBorderWhenVideoIsStopped: Bool {
        didSet {
            updateBorderStyle()
        }
    }

    /// indicates wether or not the view is shown in full in the grid
    var isMaximized = false {
        didSet {
            updateBorderStyle()
            updateFillMode()
            updateScalableView()
            setupAccessibility()
        }
    }

    var shouldFill: Bool {
        isMaximized ? false : videoKind.shouldFill
    }

    // MARK: - Pinch To Zoom

    var pinchToZoomRule: PinchToZoomRule {
        didSet {
            guard oldValue != pinchToZoomRule else { return }
            updateScalableView()
        }
    }

    var shouldEnableScaling: Bool {
        switch pinchToZoomRule {
        case .enableWhenFitted:
            !shouldFill
        case .enableWhenMaximized:
            isMaximized
        }
    }

    // MARK: - Accessibility for automation

    override var accessibilityIdentifier: String? {
        get {
            let name = stream.user?.name ?? ""
            let maximizationState = isMaximized ? "maximized" : "minimized"
            let activityState = stream.isParticipantUnmutedAndActive ? "active" : "inactive"
            let viewKind = stream.isSharingVideo ? "videoView" : "audioView"
            return "\(viewKind).\(name).\(maximizationState).\(activityState)"
        }
        set {}
    }

    // MARK: - Setup

    func updateUserDetails() {
        userDetailsView.name = stream.user?.name
        userDetailsView.microphoneIconStyle = MicrophoneIconStyle(
            state: stream.microphoneState,
            shouldPulse: stream.activeSpeakerState.isSpeakingNow
        )
        userDetailsView.callState = stream.callParticipantState
        userDetailsView.alpha = userDetailsAlpha
    }

    func setupViews() {
        addSubview(avatarView)
        addSubview(userDetailsView)

        backgroundColor = .graphite
        avatarView.user = stream.user
        avatarView.userSession = userSession
        userDetailsView.alpha = 1

        layer.cornerRadius = 3
        layer.masksToBounds = true
        borderLayer.borderColor = SemanticColors.View.backgroundDefaultWhite.cgColor
        borderLayer.borderWidth = 5.0
        borderLayer.cornerRadius = 3
        layer.insertSublayer(borderLayer, above: layer)
    }

    func createConstraints() {
        [avatarView, userDetailsView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        detailsConstraints = UserDetailsConstraints(
            view: userDetailsView,
            superview: self,
            safeAreaInsets: adjustedInsets
        )
        let avatarWidth = 72.0
        NSLayoutConstraint.activate([
            userDetailsView.heightAnchor.constraint(equalToConstant: 24),
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: avatarWidth),
            avatarView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.7),
            avatarView.heightAnchor.constraint(equalTo: avatarView.widthAnchor),
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        borderLayer.borderColor = SemanticColors.View.backgroundDefaultWhite.cgColor
    }

    func updateScalableView() {
        scalableView?.isScalingEnabled = shouldEnableScaling
    }

    func updateVideoShouldFill(_: Bool) {
        // overide in subclasses
    }

    // MARK: - Orientation & Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        detailsConstraints?.updateEdges(with: adjustedInsets)
        borderLayer.frame = bounds
    }

    func layout(
        forInterfaceOrientation interfaceOrientation: UIInterfaceOrientation,
        deviceOrientation: UIDeviceOrientation
    ) {
        guard let superview else { return }

        delta = .equal

        transform = CGAffineTransform(rotationAngle: delta.radians)
        frame = superview.bounds

        layoutSubviews()
    }

    // MARK: Private

    private var borderLayer = CALayer()

    // MARK: - Private Properties

    private var delta = OrientationDelta()
    private var detailsConstraints: UserDetailsConstraints?
    private var isCovered: Bool

    private var adjustedInsets: UIEdgeInsets {
        safeAreaInsetsOrFallback.adjusted(for: delta)
    }

    private var userDetailsAlpha: CGFloat {
        isCovered ? 0 : 1
    }

    // MARK: - Fill Mode

    private var videoKind: VideoKind = .none {
        didSet {
            guard oldValue != videoKind else { return }
            updateFillMode()
            updateScalableView()
        }
    }

    private func setupAccessibility() {
        typealias Calling = L10n.Accessibility.Calling

        guard let userName = userDetailsView.name else {
            return
        }

        isAccessibilityElement = true
        accessibilityTraits = .button
        let microphoneState = userDetailsView.microphoneIconStyle.accessibilityLabel
        let cameraState = (stream.isSharingVideo && !stream.isScreenSharing) ? Calling.CameraOn.description : Calling
            .CameraOff.description
        let activeSpeaker = stream.isParticipantUnmutedAndSpeakingNow ? Calling.ActiveSpeaker.description : ""
        let screenSharing = stream.isScreenSharing ? Calling.SharesScreen.description : ""
        accessibilityLabel = "\(userName), \(microphoneState), \(cameraState), \(activeSpeaker), \(screenSharing)"
        accessibilityHint = isMaximized ? Calling.UserCellMinimize.hint : Calling.UserCellFullscreen.hint
    }

    private func hideVideoViewsIfNeeded() {
        scalableView?.isHidden = !stream.isSharingVideo
    }

    private func updateVideoKind() {
        videoKind = VideoKind(videoState: stream.videoState)
    }

    private func updateFillMode() {
        // Reset scale if the view was zoomed in
        scalableView?.resetScale()
        updateVideoShouldFill(shouldFill)
    }

    // MARK: - Border Style

    private func updateBorderStyle() {
        let showBorderForActiveSpeaker = shouldShowActiveSpeakerFrame && stream.isParticipantUnmutedAndSpeakingNow

        layer.borderWidth = showBorderForActiveSpeaker ? 2 : 0
        layer.borderColor = showBorderForActiveSpeaker ? UIColor.accent().cgColor : UIColor.clear.cgColor
        borderLayer.isHidden = !showBorderForActiveSpeaker
    }

    // MARK: - Visibility

    @objc
    private func updateUserDetailsVisibility(_ notification: Notification?) {
        guard let isCovered = notification?.userInfo?[CallGridViewController.isCoveredKey] as? Bool else {
            return
        }
        self.isCovered = isCovered
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                self.userDetailsView.alpha = self.userDetailsAlpha
            }
        )
    }
}

// MARK: - UserDetailsConstraints

private struct UserDetailsConstraints {
    // MARK: Lifecycle

    init(view: UIView, superview: UIView, safeAreaInsets insets: UIEdgeInsets) {
        self.bottom = view.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        self.leading = view.leadingAnchor.constraint(equalTo: superview.leadingAnchor)
        self.trailing = view.trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor)
        updateEdges(with: insets)
        NSLayoutConstraint.activate([bottom, leading, trailing])
    }

    // MARK: Internal

    func updateEdges(with insets: UIEdgeInsets) {
        leading.constant = margin + insets.left
        trailing.constant = -(margin + insets.right)
        bottom.constant = -(margin + insets.bottom)
    }

    // MARK: Private

    private let bottom: NSLayoutConstraint
    private let leading: NSLayoutConstraint
    private let trailing: NSLayoutConstraint

    private let margin: CGFloat = 8
}
