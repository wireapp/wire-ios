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
import WireDataModel

extension ConversationViewController {
    private enum PrivacyAlertAction {
        case verifyDevices
        case sendAnyway
        case sendAnywayWithAction((Bool) -> Void)
        case legalHoldDetails
        case cancelWithAction((Bool) -> Void)
        case cancel

        var localizedTitle: String {
            switch self {
            case .verifyDevices:
                L10n.Localizable.Meta.Degraded.verifyDevicesButton
            case .sendAnyway, .sendAnywayWithAction:
                L10n.Localizable.Meta.Degraded.sendAnywayButton
            case .legalHoldDetails:
                L10n.Localizable.Meta.Legalhold.infoButton
            case .cancel, .cancelWithAction:
                L10n.Localizable.General.cancel
            }
        }

        var preferredStyle: UIAlertAction.Style {
            switch self {
            case .cancel, .cancelWithAction:
                .cancel
            default:
                .default
            }
        }
    }

    // MARK: - Alert

    private typealias AlertContent = (title: String, message: String, actions: [PrivacyAlertAction])

    /// Presents an alert in response to a change in privacy (legal hold or client verification or e2ei).
    func presentPrivacyWarningAlert(for changeInfo: ConversationChangeInfo) {
        let alertContent: AlertContent

        if conversation.legalHoldStatus == .pendingApproval {
            alertContent = legalHoldPrivacyWarningAlertContent()
        } else if conversation.securityLevel == .secureWithIgnored {
            alertContent = clientVerificationPrivacyWarningAlertContent(
                degradedUsers: changeInfo.usersThatCausedConversationToDegrade
            )
        } else {
            // no-op: there is no privacy warning
            return
        }

        presentAlert(with: alertContent)
    }

    private func presentAlert(with alertContent: AlertContent) {
        let alert = UIAlertController(title: alertContent.title, message: alertContent.message, preferredStyle: .alert)

        for action in alertContent.actions {
            let alertAction = UIAlertAction(
                title: action.localizedTitle,
                style: action.preferredStyle
            ) { [weak self] _ in
                self?.performPrivacyAction(action)
            }

            alert.addAction(alertAction)
        }

        present(alert, animated: true)
    }

    private func clientVerificationPrivacyWarningAlertContent(degradedUsers: Set<ZMUser>) -> AlertContent {
        typealias DegradationReasonMessage = L10n.Localizable.Meta.Degraded.DegradationReasonMessage

        let names = degradedUsers.compactMap(\.name).joined(separator: ", ")
        let title = degradedUsers.count <= 1
            ? DegradationReasonMessage.singular(names)
            : DegradationReasonMessage.plural(names)
        let message = L10n.Localizable.Meta.Degraded.dialogMessage

        let actions: [PrivacyAlertAction] = [.verifyDevices, .sendAnyway, .cancel]

        return (title, message, actions)
    }

    private func clientVerificationPrivacyWarningAlertContent(action: @escaping (Bool) -> Void) -> AlertContent {
        typealias DegradationReasonMessage = L10n.Localizable.Meta.Degraded.DegradationReasonMessage

        let title = DegradationReasonMessage.someone
        let message = L10n.Localizable.Meta.Degraded.dialogMessage

        let actions: [PrivacyAlertAction] = [.verifyDevices, .sendAnywayWithAction(action), .cancelWithAction(action)]

        return (title, message, actions)
    }

    private func legalHoldPrivacyWarningAlertContent() -> AlertContent {
        let title = L10n.Localizable.Meta.Legalhold.sendAlertTitle
        let message = L10n.Localizable.Meta.Degraded.dialogMessage
        var actions: [PrivacyAlertAction] = [.legalHoldDetails]

        if conversation.securityLevel == .secureWithIgnored {
            actions.append(.verifyDevices)
        }
        actions += [.sendAnyway, .cancel]

        return (title, message, actions)
    }

    private func e2eIPrivacyWarningAlertContent(action: @escaping (Bool) -> Void) -> AlertContent {
        let title = L10n.Localizable.Meta.Mls.Degraded.Alert.title
        let message = L10n.Localizable.Meta.Mls.Degraded.Alert.message

        let actions: [PrivacyAlertAction] = [.sendAnywayWithAction(action), .cancelWithAction(action)]

        return (title, message, actions)
    }

    // MARK: - Handling the Result

    private func performPrivacyAction(_ action: PrivacyAlertAction) {
        switch action {
        case .verifyDevices:
            presentVerificationScreen()
        case .legalHoldDetails:
            presentLegalHoldDetails()
        case .sendAnyway:
            conversation.acknowledgePrivacyWarningAndResendMessages()
        case .cancel:
            conversation.discardPendingMessagesAfterPrivacyChanges()
        case let .sendAnywayWithAction(closure):
            closure(true)
        case let .cancelWithAction(closure):
            closure(false)
        }
    }

    private func presentVerificationScreen() {
        guard let selfUser = ZMUser.selfUser() else {
            return
        }

        if selfUser.hasUntrustedClients {
            ZClientViewController.shared?.openClientListScreen(for: selfUser)
        } else if let connectedUser = conversation.connectedUser, conversation.conversationType == .oneOnOne {
            let profileViewController = ProfileViewController(
                user: connectedUser,
                viewer: selfUser,
                conversation: conversation,
                context: .deviceList,
                userSession: userSession,
                mainCoordinator: mainCoordinator
            )
            profileViewController.delegate = self
            profileViewController.viewControllerDismisser = self
            let navigationController = profileViewController.wrapInNavigationController()
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true)
        } else if conversation.conversationType == .group {
            let participantsViewController = GroupParticipantsDetailViewController(
                selectedParticipants: [],
                conversation: conversation,
                userSession: userSession,
                mainCoordinator: mainCoordinator
            )
            let navigationController = participantsViewController.wrapInNavigationController()
            navigationController.modalPresentationStyle = .formSheet
            present(navigationController, animated: true)
        }
    }

    private func presentLegalHoldDetails() {
        LegalHoldDetailsViewController.present(
            in: self,
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mainCoordinator
        )
    }
}

// MARK: - ConversationViewController + PrivacyWarningPresenter

extension ConversationViewController: PrivacyWarningPresenter {
    func presentPrivacyWarningAlert(_ notification: Notification) {
        switch conversation.messageProtocol {
        case .proteus, .mixed:
            presentClientVerificationPrivacyWarningAlert(notification)
        case .mls:
            presentE2EIPrivacyWarningAlert(notification)
        }
    }

    private func presentE2EIPrivacyWarningAlert(_ notification: Notification) {
        switch notification.alertType {
        case .incomingCall?:
            let alert = UIAlertController.makeIncomingDegradedMLSCall { continueDegradedCall in

                if continueDegradedCall {
                    self.conversation.acknowledgePrivacyChanges()
                }
                PrivacyWarningChecker.privacyWarningConfirm(sendAnyway: continueDegradedCall)
            }

            present(alert, animated: true)

        case .outgoingCall?:
            let alert = UIAlertController.makeOutgoingDegradedMLSCall { continueDegradedCall in

                if continueDegradedCall {
                    self.conversation.acknowledgePrivacyChanges()
                }
                PrivacyWarningChecker.privacyWarningConfirm(sendAnyway: continueDegradedCall)
            }

            present(alert, animated: true)

        case .message?:
            let content = e2eIPrivacyWarningAlertContent { sendAnyway in

                if sendAnyway {
                    self.conversation.acknowledgePrivacyChanges()
                }

                PrivacyWarningChecker.privacyWarningConfirm(sendAnyway: sendAnyway)
            }

            presentAlert(with: content)

        case .none:
            assertionFailure("wrong type of notification sent!")
        }
    }

    private func presentClientVerificationPrivacyWarningAlert(_ notification: Notification) {
        switch notification.alertType {
        case .incomingCall?:
            let alert = UIAlertController.makeIncomingDegradedProteusCall(degradedUser: nil) { continueDegradedCall in

                if continueDegradedCall {
                    self.conversation.acknowledgePrivacyChanges()
                }
                PrivacyWarningChecker.privacyWarningConfirm(sendAnyway: continueDegradedCall)
            }

            present(alert, animated: true)

        case .outgoingCall?:
            let alert = UIAlertController.makeOutgoingDegradedProteusCall(degradedUser: nil) { continueDegradedCall in

                if continueDegradedCall {
                    self.conversation.acknowledgePrivacyChanges()
                }
                PrivacyWarningChecker.privacyWarningConfirm(sendAnyway: continueDegradedCall)
            }

            present(alert, animated: true)

        case .message?:
            let content = clientVerificationPrivacyWarningAlertContent { sendAnyway in

                if sendAnyway {
                    self.conversation.acknowledgePrivacyChanges()
                }

                PrivacyWarningChecker.privacyWarningConfirm(sendAnyway: sendAnyway)
            }
            presentAlert(with: content)

        case .none:
            assertionFailure("wrong type of notification sent!")
        }
    }
}
