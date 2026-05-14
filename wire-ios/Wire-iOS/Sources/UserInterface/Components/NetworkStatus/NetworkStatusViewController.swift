//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

struct NetworkStatusViewControllerBuilder {

    private let userSession: UserSession
    private let kmpViewModelEnvironment: KMPViewModelEnvironment

    init(
        userSession: UserSession,
        kmpViewModelEnvironment: KMPViewModelEnvironment
    ) {
        self.userSession = userSession
        self.kmpViewModelEnvironment = kmpViewModelEnvironment
    }

    @MainActor
    func build() -> NetworkStatusViewController {
        if shouldBuildKMPViewModelImplementation {
            return buildKMPViewModelImplementation()
        }

        return buildLegacy()
    }

    private var shouldBuildKMPViewModelImplementation: Bool {
        kmpViewModelEnvironment.usesKMPViewModel(
            for: .networkStatus,
            isKMPImplementationAvailable: false
        )
    }

    @MainActor
    private func buildKMPViewModelImplementation() -> NetworkStatusViewController {
        // KMP-backed implementation will be added once Metro/Kalium exposes this screen contract.
        buildLegacy()
    }

    @MainActor
    private func buildLegacy() -> NetworkStatusViewController {
        NetworkStatusViewController(userSession: userSession)
    }
}

final class NetworkStatusViewController: UIViewController {

    weak var delegate: NetworkStatusBarDelegate? {
        didSet {
            networkStatusView.delegate = delegate
        }
    }

    let networkStatusView = NetworkStatusView()
    private var observersTokens: [Any] = []
    private var networkStatusObserverToken: Any?
    private let viewModel = NetworkStatusViewModel()
    private var finishedViewWillAppear: Bool = false

    private var device: DeviceAbstraction
    private var application: ApplicationProtocol

    let userSession: UserSession

    /// Convenience init for injecting mock device and mock application in tests.
    ///
    /// - Parameter device: Provide this param for testing only
    /// - Parameter application: Provide this param for testing only
    /// - Parameter userSession: The user session to observe network state from
    convenience init(
        device: DeviceAbstraction,
        application: ApplicationProtocol,
        userSession: UserSession
    ) {
        self.init(userSession: userSession)
        self.device = device
        self.application = application
    }

    init(userSession: UserSession) {
        self.userSession = userSession
        self.device = .current
        self.application = UIApplication.shared
        super.init(nibName: nil, bundle: nil)

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
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("Use init(userSession:)")
    }

    private func createConstraints() {
        networkStatusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            networkStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            networkStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            networkStatusView.topAnchor.constraint(equalTo: view.topAnchor),
            networkStatusView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(applyPendingState), object: nil)
    }

    override func loadView() {
        let passthroughTouchesView = PassthroughTouchesView()
        passthroughTouchesView.clipsToBounds = true
        view = passthroughTouchesView
    }

    override func viewDidLoad() {
        // The cast is not needed for compilation but is a necessary hack for tests
        if let userSession = userSession as? ZMUserSession {
            enqueue(state: viewModel.viewState(from: userSession.networkState))
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

        guard !finishedViewWillAppear else { return }

        finishedViewWillAppear = true
        enqueue(state: viewModel.viewState(from: userSession.networkState))
    }

    func showOfflineAlert(_ alertContent: NetworkStatusViewModel.AlertContent) {
        let alert = UIAlertController(
            title: alertContent.title,
            message: alertContent.message,
            preferredStyle: .alert
        )
        alert.addAction(.confirm())
        alert.presentOverAll()
    }

    @objc
    func tappedOnNetworkStatusBar() {
        switch viewModel.routeForTap(on: networkStatusView.state) {
        case let .offlineAlert(alertContent):
            showOfflineAlert(alertContent)
        case .none:
            break
        }
    }

    private func enqueue(state: NetworkStatusViewState) {
        viewModel.enqueue(state: state)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(applyPendingState), object: nil)

        perform(#selector(applyPendingState), with: nil, afterDelay: 1)
    }

    @objc
    func applyPendingState() {
        guard let state = viewModel.applyPendingState() else { return }
        update(state: state)
    }

    func update(state newState: NetworkStatusViewState) {
        viewModel.update(state: newState)

        guard shouldShowOnIPad() else { return }

        networkStatusView.update(state: newState, animated: true)
    }
}

extension NetworkStatusViewController: ZMNetworkAvailabilityObserver {

    func didChangeAvailability(newState: NetworkState) {
        enqueue(state: viewModel.viewState(from: newState))
    }

}

// MARK: - iPad size class and orientation switching

extension NetworkStatusViewController {
    func shouldShowOnIPad() -> Bool {
        let isIPadRegular = isIPadRegular(device: device)

        return viewModel.shouldApplyState(
            isIPadRegular: isIPadRegular,
            delegateAllowsDisplay: isIPadRegular ? delegateAllowsDisplayOnIPad() : true
        )
    }

    @objc
    func updateStateForIPad() {
        guard device.userInterfaceIdiom == .pad else { return }

        let horizontalSizeClass = viewModelHorizontalSizeClass

        networkStatusView.update(
            state: viewModel.visibleStateForIPadTraitChange(
                horizontalSizeClass: horizontalSizeClass,
                delegateAllowsDisplay: horizontalSizeClass == .regular ? delegateAllowsDisplayOnIPad() : true
            ),
            animated: false
        )
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateStateForIPad()
    }

    private var viewModelHorizontalSizeClass: NetworkStatusViewModel.HorizontalSizeClass {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            .compact
        case .regular:
            .regular
        case .unspecified:
            .unspecified
        @unknown default:
            .unspecified
        }
    }

    private func delegateAllowsDisplayOnIPad() -> Bool {
        guard let delegate else { return true }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return true
        }

        return delegate.showInIPad(networkStatusViewController: self, with: windowScene.interfaceOrientation)
    }
}

extension NetworkStatusViewController: ApplicationStateObserving {

    func addObserverToken(_ token: NSObjectProtocol) {
        observersTokens.append(token)
    }

    func applicationDidBecomeActive() {
        // Enqueue the current state because the UI might be out of sync if the
        // last state update was applied after the app transitioned to the
        // background, because the view animations would not be applied.
        enqueue(state: viewModel.stateToEnqueueWhenApplicationBecomesActive())
    }

}
