//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireFoundation
import WireLegacyLogging
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
    private let featureRepositoryProvider: any LegacyFeatureRepositoryProvider
    private let featureChangeActionsHandler: E2EINotificationActions
    private let e2eiActivationDateRepository: any E2EIActivationDateRepositoryProtocol
    private var featureChangeObserverToken: Any?
    private var revokedCertificateObserverToken: Any?

    // MARK: - Public Property

    private weak var _zClientViewController: ZClientViewController?

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
        self.featureRepositoryProvider = featureRepositoryProvider
        self.featureChangeActionsHandler = featureChangeActionsHandler
        self.e2eiActivationDateRepository = e2eiActivationDateRepository

        self.callEndedAnalyticsController = .init(
            contextProvider: userSession.contextProvider,
            notificationCenter: notificationCenter,
            analyticsEventTracker: { [weak userSession] in userSession?.analyticsEventTracker },
            logger: WireLogger.analytics,
            currentDateProvider: .system
        )

        self.featureChangeObserverToken = notificationCenter.addObserver(
            forName: .featureDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.notifyFeatureChange(notification)
        }

        self.revokedCertificateObserverToken = notificationCenter.addObserver(
            forName: .presentRevokedCertificateWarningAlert,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.notifyRevokedCertificate()
        }
    }

    deinit {
        if let featureChangeObserverToken {
            notificationCenter.removeObserver(featureChangeObserverToken)
        }

        if let revokedCertificateObserverToken {
            notificationCenter.removeObserver(revokedCertificateObserverToken)
        }
    }

    private func notifyFeatureChange(_ note: Notification) {
        guard
            let change = note.object as? LegacyFeatureRepository.FeatureChange,
            let alert = change.hasFurtherActions
            ? UIAlertController.fromFeatureChangeWithActions(
                change,
                acknowledger: featureRepositoryProvider
                    .featureRepository,
                actionsHandler: featureChangeActionsHandler
            )
            : UIAlertController.fromFeatureChange(
                change,
                acknowledger: featureRepositoryProvider.featureRepository
            )
        else { return }

        if change == .e2eIEnabled, e2eiActivationDateRepository.e2eiActivatedAt == nil {
            e2eiActivationDateRepository.storeE2EIActivationDate(Date.now)
        }

        _zClientViewController?.present(alert, animated: true)
    }

    private func notifyRevokedCertificate() {
        guard let sessionManager = SessionManager.shared else { return }

        let alert = UIAlertController.revokedCertificateWarning {
            sessionManager.logoutCurrentSession()
        }

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
        case let .conversation(converation, message):
            _zClientViewController?.showConversation(converation, at: message)
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

protocol LegacyFeatureRepositoryProvider {
    var featureRepository: LegacyFeatureRepository { get }
}

extension ZMUserSession: LegacyFeatureRepositoryProvider {}
