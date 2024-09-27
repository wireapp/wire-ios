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

import UIKit
import WireDesign
import WireSystem

// MARK: - NetworkStatusViewState

enum NetworkStatusViewState {
    case online
    case onlineSynchronizing
    case offlineExpanded
}

// MARK: - NetworkStatusViewDelegate

// sourcery: AutoMockable
protocol NetworkStatusViewDelegate: AnyObject {
    /// Set this var to true after viewDidAppear. This flag prevents first layout animation when the UIViewController is
    /// created but not yet appear, if didChangeHeight called with animated = true.
    var shouldAnimateNetworkStatusView: Bool { get set }

    /// bottom margin to the neighbour view
    var bottomMargin: CGFloat { get }

    /// When the networkStatusView changes its height, this delegate method is called. The delegate should refresh its
    /// layout in the method.
    ///
    /// - Parameters:
    ///   - networkStatusView: the delegate caller
    ///   - animated: networkStatusView changes height animated?
    ///   - state: the new NetworkStatusViewState of networkStatusView
    func didChangeHeight(_ networkStatusView: NetworkStatusView, animated: Bool, state: NetworkStatusViewState)
}

// MARK: - default implementation of didChangeHeight, animates the layout process

extension NetworkStatusViewDelegate where Self: UIViewController {
    func didChangeHeight(_ networkStatusView: NetworkStatusView, animated: Bool, state: NetworkStatusViewState) {
        guard shouldAnimateNetworkStatusView else {
            return
        }

        if animated {
            UIView.animate(
                withDuration: TimeInterval.NetworkStatusBar.resizeAnimationTime,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState]
            ) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }
}

// MARK: - NetworkStatusView

final class NetworkStatusView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        self.connectingView = BreathLoadingBar.withDefaultAnimationDuration()
        connectingView.accessibilityIdentifier = "LoadBar"
        self.offlineView = OfflineBar()

        super.init(frame: frame)

        connectingView.delegate = self

        for subview in [offlineView, connectingView] {
            addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false
        }

        self.state = .online
        backgroundColor = SemanticColors.View.backgroundDefault
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: Internal

    let connectingView: BreathLoadingBar
    weak var delegate: NetworkStatusViewDelegate?

    var state: NetworkStatusViewState {
        get { _state }
        set { update(state: newValue, animated: false) }
    }

    func update(state: NetworkStatusViewState, animated: Bool) {
        _state = state
        // if this is called before the frame is set then the offline
        // bar zooms into view (which we don't want).
        updateViewState(animated: (frame == .zero) ? false : animated)
    }

    func updateConstraints(networkStatusViewState: NetworkStatusViewState) {
        var bottomMargin: CGFloat = 0

        if let margin = delegate?.bottomMargin {
            bottomMargin = margin
        }

        switch networkStatusViewState {
        case .online:
            connectingViewBottomMargin.constant = 0
            offlineViewBottomMargin.constant = 0
            offlineViewTopMargin.constant = 0

            connectingViewBottomMargin.isActive = false
            offlineViewBottomMargin.isActive = true

        case .onlineSynchronizing:
            connectingViewBottomMargin.constant = -bottomMargin
            offlineViewTopMargin.constant = topMargin

            offlineViewBottomMargin.isActive = false
            connectingViewBottomMargin.isActive = true

        case .offlineExpanded:
            offlineViewBottomMargin.constant = -bottomMargin
            offlineViewTopMargin.constant = topMargin

            connectingViewBottomMargin.isActive = false
            offlineViewBottomMargin.isActive = true
        }
    }

    func updateUI(animated: Bool) {
        log(networkStatus: state)
        var networkStatusViewState = state

        // When the app is in background, hide the sync bar and offline bar. It prevents the sync bar is "disappear in a
        // blink" visual artifact.
        if let activationState = window?.windowScene?.activationState,
           ![.foregroundActive, .foregroundInactive].contains(activationState) {
            networkStatusViewState = .online
        }

        updateConstraints(networkStatusViewState: networkStatusViewState)

        offlineView.state = networkStatusViewState
        connectingView.state = networkStatusViewState

        layoutIfNeeded()
    }

    func updateUICompletion(offlineViewHidden: Bool) {
        offlineView.isHidden = offlineViewHidden
    }

    // Detects when the view can be touchable
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        state == .offlineExpanded
    }

    // MARK: - Helper Logging

    func log(networkStatus: NetworkStatusViewState) {
        do {
            let status = String(describing: networkStatus)
            let logInfo = LogInfo(status: status)
            let data = try JSONEncoder().encode(logInfo)
            let jsonString = String(decoding: data, as: UTF8.self)

            WireLogger.network.debug("NETWORK_STATUS_VIEW_STATE: \(jsonString)")
        } catch {
            WireLogger.network.error("NETWORK_STATUS_VIEW_STATE: failure: \(error.localizedDescription)")
        }
    }

    // MARK: Private

    private let offlineView: OfflineBar
    private var _state: NetworkStatusViewState = .online

    private lazy var offlineViewTopMargin: NSLayoutConstraint = offlineView.topAnchor.constraint(equalTo: topAnchor)
    private lazy var offlineViewBottomMargin: NSLayoutConstraint = offlineView.bottomAnchor
        .constraint(equalTo: bottomAnchor)
    private lazy var connectingViewBottomMargin: NSLayoutConstraint = connectingView.bottomAnchor
        .constraint(equalTo: bottomAnchor)

    private lazy var topMargin: CGFloat =
        if UIScreen.hasNotch {
            0
        } else {
            CGFloat.NetworkStatusBar.topMargin
        }

    private func createConstraints() {
        [offlineView, connectingView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            offlineView.leftAnchor.constraint(equalTo: leftAnchor, constant: CGFloat.NetworkStatusBar.horizontalMargin),
            offlineView.rightAnchor.constraint(
                equalTo: rightAnchor,
                constant: -CGFloat.NetworkStatusBar.horizontalMargin
            ),
            offlineViewTopMargin,
            offlineViewBottomMargin,

            connectingView.leftAnchor.constraint(equalTo: offlineView.leftAnchor),
            connectingView.rightAnchor.constraint(equalTo: offlineView.rightAnchor),
            connectingView.topAnchor.constraint(equalTo: offlineView.topAnchor),
            connectingViewBottomMargin,
        ])
    }

    private func updateViewState(animated: Bool) {
        let offlineViewHidden = state != .offlineExpanded

        let updateUIBlock: () -> Void = {
            self.updateUI(animated: animated)
        }

        let completionBlock: (Bool) -> Void = { _ in
            self.updateUICompletion(offlineViewHidden: offlineViewHidden)
            self.connectingView.animating = self.state == .onlineSynchronizing
        }

        if animated {
            connectingView.animating = false
            if state == .offlineExpanded {
                offlineView.isHidden = false
            }

            UIView.animate(
                withDuration: TimeInterval.NetworkStatusBar.resizeAnimationTime,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: updateUIBlock,
                completion: completionBlock
            )
        } else {
            updateUIBlock()
            completionBlock(true)
        }

        delegate?.didChangeHeight(self, animated: animated, state: state)
    }
}

// MARK: BreathLoadingBarDelegate

extension NetworkStatusView: BreathLoadingBarDelegate {
    func animationDidStarted() {
        delegate?.didChangeHeight(self, animated: true, state: state)
    }

    func animationDidStopped() {
        delegate?.didChangeHeight(self, animated: true, state: state)
    }
}

// MARK: - LogInfo

private struct LogInfo: Encodable {
    var status: String
}
