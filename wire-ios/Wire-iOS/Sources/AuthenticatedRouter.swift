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
import WireDataModel
import WireDomain
import WireFoundation
import WireLogging
import WireNetwork
import WireSyncEngine

enum NavigationDestination {
    case conversation(ZMConversation, ZMConversationMessage?)
    case userProfile(WireDataModel.UserType)
    case connectionRequest(WireDataModel.QualifiedID)
    case conversationList
}

protocol AuthenticatedRouterProtocol: AnyObject {
    func updateActiveCallPresentationState()
    func minimizeCallOverlay(animated: Bool, completion: Completion?)
    func navigate(to destination: NavigationDestination)
}

final class AuthenticatedRouter {

    // MARK: - Private Property

    private let notificationCenter: NotificationCenter
    private let zClientControllerBuilder: ZClientControllerBuilder
    private let activeCallRouter: ActiveCallRouter<TopOverlayPresenter>
    private let callEndedAnalyticsController: CallEndedAnalyticsController<WireCallCenterV3>
    private let featureChangeNotifier: FeatureChangeNotifier
    private var revokedCertificateObserverToken: Any?

    // MARK: - Public Property

    private var _zClientViewController: ZClientViewController?

    @MainActor var zClientViewController: ZClientViewController {
        let zClientViewController = _zClientViewController ?? zClientControllerBuilder(router: self)
        _zClientViewController = zClientViewController
        return zClientViewController
    }

    // MARK: - Init

    init(
        mainWindow: UIWindow,
        account: Account,
        userSession: UserSession,
        legacyEnvironment: WireTransport.BackendEnvironment,
        newEnvironment: BackendEnvironment2?,
        // TODO: [WPB-18798] remove legacyEnvironment and newEnvironment properties when ticket is implemented
        notificationCenter: NotificationCenter = .default,
        trackingManager: TrackingManager,
        featureRepositoryProvider: any LegacyFeatureRepositoryProvider,
        featureChangeActionsHandler: E2EINotificationActionsHandler,
        e2eiActivationDateRepository: any E2EIActivationDateRepositoryProtocol
    ) {
        self.activeCallRouter = ActiveCallRouter(
            mainWindow: mainWindow,
            userSession: userSession,
            topOverlayPresenter: .init(mainWindow: mainWindow)
        )
        self.zClientControllerBuilder = .init(
            account: account,
            userSession: userSession,
            trackingManager: trackingManager,
            legacyEnvironment: legacyEnvironment,
            newEnvironment: newEnvironment
        )

        self.notificationCenter = notificationCenter

        self.callEndedAnalyticsController = .init(
            contextProvider: userSession.contextProvider,
            notificationCenter: notificationCenter,
            analyticsEventTracker: { [weak userSession] in userSession?.analyticsEventTracker },
            logger: WireLogger.analytics,
            currentDateProvider: .system
        )

        self.featureChangeNotifier = FeatureChangeNotifier(
            notificationCenter: notificationCenter,
            userSession: userSession,
            featureRepositoryProvider: featureRepositoryProvider,
            featureChangeActionsHandler: featureChangeActionsHandler,
            e2eiActivationDateRepository: e2eiActivationDateRepository
        )

        self.featureChangeNotifier.presenter = self

        self.revokedCertificateObserverToken = notificationCenter.addObserver(
            forName: .presentRevokedCertificateWarningAlert,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.notifyRevokedCertificate()
        }
    }

    deinit {
        if let revokedCertificateObserverToken {
            notificationCenter.removeObserver(revokedCertificateObserverToken)
        }
    }

    private func notifyRevokedCertificate() {
        guard let sessionManager = SessionManager.shared else { return }

        let alert = UIAlertController.revokedCertificateWarning {
            sessionManager.logoutCurrentSession()
        }

        present(alert)
    }
}

// MARK: - FeatureChangeAlertPresenting

extension AuthenticatedRouter: FeatureChangeAlertPresenting {

    func present(_ alert: UIAlertController) {
        _zClientViewController?.present(alert, animated: true)
    }

}

// MARK: - AuthenticatedRouterProtocol

extension AuthenticatedRouter: AuthenticatedRouterProtocol {

    func updateActiveCallPresentationState() {
        activeCallRouter.updateActiveCallPresentationState()
    }

    func minimizeCallOverlay(animated: Bool, completion: Completion?) {
        activeCallRouter.minimizeCall(animated: animated, completion: completion)
    }

    func navigate(to destination: NavigationDestination) {
        switch destination {
        case let .conversation(conversation, message):
            _zClientViewController?.showConversation(conversation, at: message)
        case let .connectionRequest(qualifiedID):
            _zClientViewController?.showConnectionRequest(qualifiedID: qualifiedID)
        case .conversationList:
            _zClientViewController?.showConversationList()
        case let .userProfile(user):
            Task { @MainActor in
                await _zClientViewController?.showUserProfile(user: user)
            }
        }
    }
}
