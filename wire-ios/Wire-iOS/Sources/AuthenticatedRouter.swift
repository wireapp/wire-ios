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

    private let zClientViewControllerBuilder: ZClientViewControllerBuilder
    private let activeCallRouter: ActiveCallRouter<TopOverlayPresenter>
    private let featureRepositoryProvider: any FeatureRepositoryProvider
    private let featureChangeActionsHandler: E2EINotificationActions
    private let e2eiActivationDateRepository: any E2EIActivationDateRepositoryProtocol
    private var featureChangeObserverToken: Any?
    private var revokedCertificateObserverToken: Any?

    private weak var zClientViewController: ZClientViewController?

    // MARK: - Public Property

    var viewController: UIViewController {
        zClientViewController = zClientViewController ?? zClientViewControllerBuilder(router: self)
        return zClientViewController!
    }

    // MARK: - Init

    init(
        rootViewController: @escaping () -> UIViewController,
        account: Account,
        userSession: UserSession,
        featureRepositoryProvider: any FeatureRepositoryProvider,
        featureChangeActionsHandler: E2EINotificationActionsHandler,
        e2eiActivationDateRepository: any E2EIActivationDateRepositoryProtocol
    ) {
        activeCallRouter = ActiveCallRouter(
            rootViewController: rootViewController,
            userSession: userSession,
            topOverlayPresenter: .init(rootViewController: rootViewController)
        )
        zClientViewControllerBuilder = .init(account: account, userSession: userSession)

        self.featureRepositoryProvider = featureRepositoryProvider
        self.featureChangeActionsHandler = featureChangeActionsHandler
        self.e2eiActivationDateRepository = e2eiActivationDateRepository

        featureChangeObserverToken = NotificationCenter.default.addObserver(
            forName: .featureDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.notifyFeatureChange(notification)
        }

        revokedCertificateObserverToken = NotificationCenter.default.addObserver(
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
                ? UIAlertController.fromFeatureChangeWithActions(change,
                                                                 acknowledger: featureRepositoryProvider.featureRepository,
                                                                 actionsHandler: featureChangeActionsHandler)
                : UIAlertController.fromFeatureChange(change,
                                                      acknowledger: featureRepositoryProvider.featureRepository)
        else { return }

        if change == .e2eIEnabled && e2eiActivationDateRepository.e2eiActivatedAt == nil {
            e2eiActivationDateRepository.storeE2EIActivationDate(Date.now)
        }

        zClientViewController?.presentAlert(alert)
    }

    private func notifyRevokedCertificate() {
        guard let sessionManager = SessionManager.shared else { return }

        let alert = UIAlertController.revokedCertificateWarning {
            sessionManager.logoutCurrentSession()
        }

        zClientViewController?.presentAlert(alert)
    }
}

// MARK: - AuthenticatedRouterProtocol
extension AuthenticatedRouter: AuthenticatedRouterProtocol {
    func updateActiveCallPresentationState() {
        activeCallRouter.updateActiveCallPresentationState()
    }

    func minimizeCallOverlay(animated: Bool,
                             withCompletion completion: Completion?) {
        activeCallRouter.minimizeCall(animated: animated, completion: completion)
    }

    func navigate(to destination: NavigationDestination) {
        switch destination {
        case .conversation(let converation, let message):
            zClientViewController?.showConversation(converation, at: message)
        case .connectionRequest(let userId):
            zClientViewController?.showConnectionRequest(userId: userId)
        case .conversationList:
            zClientViewController?.showConversationList()
        case .userProfile(let user):
            zClientViewController?.showUserProfile(user: user)
        }
    }
}

private extension UIViewController {

    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true, completion: nil)
    }
}

protocol FeatureRepositoryProvider {

    var featureRepository: FeatureRepository { get }

}

extension ZMUserSession: FeatureRepositoryProvider {}
