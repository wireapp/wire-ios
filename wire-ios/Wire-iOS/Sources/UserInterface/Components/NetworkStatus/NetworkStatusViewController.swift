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
import WireFoundation
import WireSyncEngine

typealias NetworkStatusBarDelegate = NetworkStatusViewControllerDelegate & NetworkStatusViewDelegate

// MARK: - NetworkStatusViewControllerDelegate

protocol NetworkStatusViewControllerDelegate: AnyObject {
    ///  return false if NetworkStatusViewController will not disapper in iPad regular mode with specific orientation.
    ///
    /// - networkStatusViewController: caller of this delegate method
    /// - Parameter orientation: orientation to check
    /// - Returns: return false if the class conform this protocol does not show NetworkStatusViewController in certain
    /// orientation.
    func showInIPad(networkStatusViewController: NetworkStatusViewController, with orientation: UIInterfaceOrientation)
        -> Bool
}

// MARK: - NetworkStatusViewController

final class NetworkStatusViewController: UIViewController {
    // MARK: Lifecycle

    /// default init method with a parameter for injecting mock device and mock application
    ///
    /// - Parameter device: Provide this param for testing only
    /// - Parameter application: Provide this param for testing only
    convenience init(
        device: DeviceAbstraction,
        application: ApplicationProtocol
    ) {
        self.init(nibName: nil, bundle: nil)

        self.device = device
        self.application = application
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.device = .current
        self.application = UIApplication.shared
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateStateForIPad),
            name: UIDevice.orientationDidChangeNotification,
            object: .none
        )

        view.addSubview(networkStatusView)

        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(applyPendingState), object: nil)
    }

    // MARK: Internal

    let networkStatusView = NetworkStatusView()

    weak var delegate: NetworkStatusBarDelegate? {
        didSet {
            networkStatusView.delegate = delegate
        }
    }

    override func loadView() {
        let passthroughTouchesView = PassthroughTouchesView()
        passthroughTouchesView.clipsToBounds = true
        view = passthroughTouchesView
    }

    override func viewDidLoad() {
        if let userSession = ZMUserSession.shared() {
            enqueue(state: viewState(from: userSession.networkState))
            networkStatusObserverToken = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(
                self,
                notificationContext: userSession.managedObjectContext.notificationContext
            )
        }

        networkStatusView.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(tappedOnNetworkStatusBar)
        ))

        setupApplicationNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard !finishedViewWillAppear else {
            return
        }

        finishedViewWillAppear = true
        if let userSession = ZMUserSession.shared() {
            enqueue(state: viewState(from: userSession.networkState))
        }
    }

    func showOfflineAlert() {
        let alert = UIAlertController(
            title: L10n.Localizable.SystemStatusBar.NoInternet.title,
            message: L10n.Localizable.SystemStatusBar.NoInternet.explanation,
            preferredStyle: .alert
        )
        alert.addAction(.confirm())
        alert.presentTopmost()
    }

    @objc
    func tappedOnNetworkStatusBar() {
        switch networkStatusView.state {
        case .offlineExpanded:
            showOfflineAlert()
        default:
            break
        }
    }

    @objc
    func applyPendingState() {
        guard let state = pendingState else {
            return
        }
        update(state: state)
        pendingState = nil
    }

    func update(state newState: NetworkStatusViewState) {
        state = newState

        guard shouldShowOnIPad() else {
            return
        }

        networkStatusView.update(state: newState, animated: true)
    }

    // MARK: Private

    private var observersTokens: [Any] = []
    private var networkStatusObserverToken: Any?
    private var pendingState: NetworkStatusViewState?
    private var state: NetworkStatusViewState = .online
    private var finishedViewWillAppear = false

    private var device: DeviceAbstraction
    private var application: ApplicationProtocol

    private func createConstraints() {
        networkStatusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            networkStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            networkStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            networkStatusView.topAnchor.constraint(equalTo: view.topAnchor),
            networkStatusView.heightAnchor.constraint(equalTo: view.heightAnchor),
        ])
    }

    private func viewState(from networkState: NetworkState) -> NetworkStatusViewState {
        switch networkState {
        case .offline:
            .offlineExpanded
        case .online:
            .online
        case .onlineSynchronizing:
            .onlineSynchronizing
        }
    }

    private func enqueue(state: NetworkStatusViewState) {
        pendingState = state
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(applyPendingState), object: nil)

        perform(#selector(applyPendingState), with: nil, afterDelay: 1)
    }
}

// MARK: ZMNetworkAvailabilityObserver

extension NetworkStatusViewController: ZMNetworkAvailabilityObserver {
    func didChangeAvailability(newState: NetworkState) {
        enqueue(state: viewState(from: newState))
    }
}

// MARK: - iPad size class and orientation switching

extension NetworkStatusViewController {
    func shouldShowOnIPad() -> Bool {
        guard isIPadRegular(device: device) else {
            return true
        }
        guard let delegate else {
            return true
        }

        let newOrientation = application.statusBarOrientation

        return delegate.showInIPad(networkStatusViewController: self, with: newOrientation)
    }

    @objc
    func updateStateForIPad() {
        guard device.userInterfaceIdiom == .pad else {
            return
        }

        switch traitCollection.horizontalSizeClass {
        case .regular:
            if shouldShowOnIPad() {
                networkStatusView.update(state: state, animated: false)
            } else {
                // When size class changes and delegate view controller disabled to show networkStatusView, hide the
                // networkStatusView
                networkStatusView.update(state: .online, animated: false)
            }

        case .compact, .unspecified:
            networkStatusView.update(state: state, animated: false)

        @unknown default:
            networkStatusView.update(state: state, animated: false)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateStateForIPad()
    }
}

// MARK: ApplicationStateObserving

extension NetworkStatusViewController: ApplicationStateObserving {
    func addObserverToken(_ token: NSObjectProtocol) {
        observersTokens.append(token)
    }

    func applicationDidBecomeActive() {
        // Enqueue the current state because the UI might be out of sync if the
        // last state update was applied after the app transitioned to the
        // background, because the view animations would not be applied.
        enqueue(state: pendingState ?? state)
    }
}
