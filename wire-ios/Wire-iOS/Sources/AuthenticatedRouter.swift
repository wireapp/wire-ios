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
import WireSyncEngine

enum NavigationDestination {
    case conversation(ZMConversation, ZMConversationMessage?)
    case userProfile(UserType)
    case connectionRequest(UUID)
    case conversationList
}

protocol AuthenticatedRouterProtocol: AnyObject {
    func updateActiveCallPresentationState()
    func minimizeCallOverlay(animated: Bool, withCompletion completion: Completion?)
    func navigate(to destination: NavigationDestination)
}

final class AuthenticatedRouter {
    // MARK: - Private Property

    private let builder: AuthenticatedWireFrame
    private let activeCallRouter: ActiveCallRouter<TopOverlayPresenter>
    private weak var _viewController: ZClientViewController?
    private let featureRepositoryProvider: any FeatureRepositoryProvider
    private let featureChangeActionsHandler: E2EINotificationActions
    private let e2eiActivationDateRepository: any E2EIActivationDateRepositoryProtocol
    private var featureChangeObserverToken: Any?
    private var revokedCertificateObserverToken: Any?

    // MARK: - Public Property

    var viewController: UIViewController {
        let viewController = _viewController ?? builder.build(router: self)
        _viewController = viewController
        return viewController
    }

    // MARK: - Init

    init(
        mainWindow: UIWindow,
        account: Account,
        userSession: UserSession,
        featureRepositoryProvider: any FeatureRepositoryProvider,
        featureChangeActionsHandler: E2EINotificationActionsHandler,
        e2eiActivationDateRepository: any E2EIActivationDateRepositoryProtocol
    ) {
        self.activeCallRouter = ActiveCallRouter(
            mainWindow: mainWindow,
            userSession: userSession,
            topOverlayPresenter: .init(mainWindow: mainWindow)
        )

        self.builder = AuthenticatedWireFrame(
            account: account,
            userSession: userSession
        )

        self.featureRepositoryProvider = featureRepositoryProvider
        self.featureChangeActionsHandler = featureChangeActionsHandler
        self.e2eiActivationDateRepository = e2eiActivationDateRepository

        self.featureChangeObserverToken = NotificationCenter.default.addObserver(
            forName: .featureDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.notifyFeatureChange(notification)
        }

        self.revokedCertificateObserverToken = NotificationCenter.default.addObserver(
            forName: .presentRevokedCertificateWarningAlert,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.notifyRevokedCertificate()
        }
    }

    deinit {
        if let featureChangeObserverToken {
            NotificationCenter.default.removeObserver(featureChangeObserverToken)
        }

        if let revokedCertificateObserverToken {
            NotificationCenter.default.removeObserver(revokedCertificateObserverToken)
        }
    }

    private func notifyFeatureChange(_ note: Notification) {
        guard
            let change = note.object as? FeatureRepository.FeatureChange,
            let alert = change.hasFurtherActions
            ? UIAlertController.fromFeatureChangeWithActions(
                change,
                acknowledger: featureRepositoryProvider.featureRepository,
                actionsHandler: featureChangeActionsHandler
            )
            : UIAlertController.fromFeatureChange(
                change,
                acknowledger: featureRepositoryProvider.featureRepository
            )
        else {
            return
        }

        if change == .e2eIEnabled, e2eiActivationDateRepository.e2eiActivatedAt == nil {
            e2eiActivationDateRepository.storeE2EIActivationDate(Date.now)
        }

        _viewController?.presentAlert(alert)
    }

    private func notifyRevokedCertificate() {
        guard let sessionManager = SessionManager.shared else { return }

        let alert = UIAlertController.revokedCertificateWarning {
            sessionManager.logoutCurrentSession()
        }

        _viewController?.presentAlert(alert)
    }
}

// MARK: - AuthenticatedRouterProtocol

extension AuthenticatedRouter: AuthenticatedRouterProtocol {
    func updateActiveCallPresentationState() {
        activeCallRouter.updateActiveCallPresentationState()
    }

    func minimizeCallOverlay(
        animated: Bool,
        withCompletion completion: Completion?
    ) {
        activeCallRouter.minimizeCall(animated: animated, completion: completion)
    }

    func navigate(to destination: NavigationDestination) {
        switch destination {
        case let .conversation(converation, message):
            _viewController?.showConversation(converation, at: message)
        case let .connectionRequest(userId):
            _viewController?.showConnectionRequest(userId: userId)
        case .conversationList:
            _viewController?.showConversationList()
        case let .userProfile(user):
            _viewController?.showUserProfile(user: user)
        }
    }
}

// MARK: - AuthenticatedWireFrame

struct AuthenticatedWireFrame {
    private var account: Account
    private var userSession: UserSession

    init(
        account: Account,
        userSession: UserSession
    ) {
        self.account = account
        self.userSession = userSession
    }

    func build(router: AuthenticatedRouterProtocol) -> ZClientViewController {
        let viewController = ZClientViewController(account: account, userSession: userSession)
        viewController.router = router
        return viewController
    }
}

extension UIViewController {
    fileprivate func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true, completion: nil)
    }
}

protocol FeatureRepositoryProvider {
    var featureRepository: FeatureRepository { get }
}

extension ZMUserSession: FeatureRepositoryProvider {}
