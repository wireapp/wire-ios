//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import WireSyncEngine
import WireCommonComponents
import SwiftUI

extension Notification.Name {
    static let companyLoginDidFinish = Notification.Name("Wire.CompanyLoginDidFinish")
}

// MARK: - URLActionRouterDelegete
protocol URLActionRouterDelegate: AnyObject {

    func urlActionRouterWillShowCompanyLoginError()
    func urlActionRouterCanDisplayAlerts() -> Bool

}

// MARK: - URLActionRouterProtocol
protocol URLActionRouterProtocol {
    func open(url: URL) -> Bool
}

// MARK: - Logging
private let zmLog = ZMSLog(tag: "UI")

// MARK: - URLActionRouter
class URLActionRouter: URLActionRouterProtocol {

    // MARK: - Public Property
    var sessionManager: SessionManager?
    weak var delegate: URLActionRouterDelegate?
    weak var authenticatedRouter: AuthenticatedRouterProtocol?

    // MARK: - Private Property
    private let rootViewController: RootViewController
    private var pendingDestination: NavigationDestination?
    private var pendingAlert: UIAlertController?

    // MARK: - Initialization
    public init(viewController: RootViewController,
                sessionManager: SessionManager? = nil) {
        self.rootViewController = viewController
        self.sessionManager = sessionManager
    }

    // MARK: - Public Implementation
    @discardableResult
    func open(url: URL) -> Bool {
        do {
            return try sessionManager?.openURL(url) ?? false
        } catch let error as LocalizedError {
            if error is CompanyLoginError {
                delegate?.urlActionRouterWillShowCompanyLoginError()

                UIApplication.shared.topmostViewController()?.dismissIfNeeded(animated: true, completion: {
                    UIApplication.shared.topmostViewController()?.showAlert(for: error)
                })
            } else {
                UIApplication.shared.topmostViewController()?.showAlert(for: error)
            }
            return false
        } catch {
            return false
        }
    }

    func performPendingActions() {
        performPendingNavigation()
        presentPendingAlert()
    }

    // MARK: - Private Implementation

    func performPendingNavigation() {
        guard let destination = pendingDestination else {
            return
        }

        pendingDestination = nil
        navigate(to: destination)
    }

    func navigate(to destination: NavigationDestination) {
        guard authenticatedRouter != nil else {
            pendingDestination = destination
            return
        }

        authenticatedRouter?.navigate(to: destination)
    }

    func presentPendingAlert() {
        guard let alert = pendingAlert else {
            return
        }

        pendingAlert = nil
        presentAlert(alert)
    }

    func presentAlert(_ alert: UIAlertController) {
        guard delegate?.urlActionRouterCanDisplayAlerts() == true else {
            pendingAlert = alert
            return
        }

        internalPresentAlert(alert)
    }

    func internalPresentAlert(_ alert: UIAlertController) {
        rootViewController.present(alert, animated: true, completion: nil)
    }
}

// MARK: - PresentationDelegate
extension URLActionRouter: PresentationDelegate {

    // MARK: - Public Implementation
    func failedToPerformAction(_ action: URLAction, error: Error) {
        let localizedError = mapToLocalizedError(error)
        presentLocalizedErrorAlert(localizedError)
    }

    func completedURLAction(_ action: URLAction) {
        guard case URLAction.companyLoginSuccess = action else { return }
        notifyCompanyLoginCompletion()
    }

    func shouldPerformAction(_ action: URLAction, decisionHandler: @escaping (Bool) -> Void) {
        typealias UrlAction = L10n.Localizable.UrlAction
        switch action {
        case .connectBot:
            presentConfirmationAlert(title: UrlAction.title, message: UrlAction.ConnectToBot.message, decisionHandler: decisionHandler)
        case .accessBackend(let url):
            // Switching backend is handled below, so pass false here.
            decisionHandler(false)
            switchBackend(configURL: url)
        default:
            decisionHandler(true)
        }
    }

    func shouldPerformActionWithMessage(_ message: String, action: URLAction, decisionHandler: @escaping (_ shouldPerformAction: Bool) -> Void) {
        switch action {
        case .joinConversation:
            presentConfirmationAlert(title: nil,
                                     message: L10n.Localizable.UrlAction.JoinConversation.Confirmation.message(message),
                                     decisionHandler: decisionHandler)
        default:
            decisionHandler(true)
        }
    }

    func showConnectionRequest(userId: UUID) {
        navigate(to: .connectionRequest(userId))
    }

    func showUserProfile(user: UserType) {
        navigate(to: .userProfile(user))
    }

    func showConversation(_ conversation: ZMConversation, at message: ZMConversationMessage?) {
        navigate(to: .conversation(conversation, message))
    }

    func showConversationList() {
        navigate(to: .conversationList)
    }

    // MARK: - Private Implementation
    private func notifyCompanyLoginCompletion() {
        NotificationCenter.default.post(name: .companyLoginDidFinish, object: self)
    }

    private func presentConfirmationAlert(title: String?, message: String, decisionHandler: @escaping (Bool) -> Void) {

        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)

        let agreeAction = UIAlertAction.confirm(style: .default) { _ in decisionHandler(true) }
        alert.addAction(agreeAction)

        let cancelAction = UIAlertAction.cancel({ decisionHandler(false) })
        alert.addAction(cancelAction)

        presentAlert(alert)
    }

    private func switchBackend(configURL: URL) {
        guard
            SecurityFlags.customBackend.isEnabled,
            let sessionManager
        else {
            return
        }

        sessionManager.fetchBackendEnvironment(at: configURL) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let backendEnvironment):
                self.requestUserConfirmationToSwitchBackend(backendEnvironment) { didConfirm in
                    guard didConfirm else { return }
                    sessionManager.switchBackend(to: backendEnvironment)
                    BackendEnvironment.shared = backendEnvironment
                }

            case .failure(let error):
                let localizedError = self.mapToLocalizedError(error)
                self.presentLocalizedErrorAlert(localizedError)
            }
        }
    }

    private func requestUserConfirmationToSwitchBackend(
        _ environment: BackendEnvironment,
        didConfirm: @escaping (Bool) -> Void
    ) {
        let viewModel = SwitchBackendConfirmationViewModel(
            environment: environment,
            didConfirm: didConfirm
        )

        let view = SwitchBackendConfirmationView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        rootViewController.present(hostingController, animated: true)
    }

}

// MARK: - Errors

private extension URLActionRouter {

    enum URLActionError: LocalizedError {

        private typealias AlertStrings = L10n.Localizable.UrlAction.JoinConversation.Error.Alert

        /// Could not join a conversation because it is full.

        case conversationIsFull

        /// Converation link may have been revoked or it is corrupted.

        case conversationLinkIsInvalid

        /// The guest link feature is disabled and all guest links have been revoked

        case conversationLinkIsDisabled

        /// A generic error case.

        case unknown

        init(from error: Error) {
            switch error {
            case ConversationJoinError.invalidCode:
                self = .conversationLinkIsInvalid

            case ConversationJoinError.tooManyMembers:
                self = .conversationIsFull

            case ConversationJoinError.guestLinksDisabled, ConversationFetchError.guestLinksDisabled:
                self = .conversationLinkIsDisabled

            default:
                self = .unknown
            }
        }

        var errorDescription: String? {
            return AlertStrings.title
        }

        var failureReason: String? {
            switch self {
            case .conversationIsFull:
                return AlertStrings.ConverationIsFull.message

            case .conversationLinkIsInvalid, .conversationLinkIsDisabled:
                return AlertStrings.LinkIsInvalid.message

            case .unknown:
                return L10n.Localizable.Error.User.unkownError
            }
        }

    }

    private func mapToLocalizedError(_ error: Error) -> LocalizedError {
        return (error as? LocalizedError) ?? URLActionError(from: error)
    }

    private func presentLocalizedErrorAlert(_ error: LocalizedError) {
        let title = error.errorDescription
        let message = error.failureReason ?? L10n.Localizable.Error.User.unkownError
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.ok(style: .cancel))

        switch error {
        case URLActionError.conversationLinkIsDisabled:
            let topmostViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)
            let guestLinksLearnMoreHandler: ((UIAlertAction) -> Swift.Void) = { _ in
                let browserViewController = BrowserViewController(url: WireURLs.shared.guestLinksInfo)
                topmostViewController?.present(browserViewController, animated: true)
            }
            alert.addAction(UIAlertAction(title: L10n.Localizable.UrlAction.JoinConversation.Error.Alert.LearnMore.action,
                                          style: .default,
                                          handler: guestLinksLearnMoreHandler))
        default:
            break
        }
        presentAlert(alert)
    }

}
