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

import Foundation

enum BlockerViewControllerContext {
    case blacklist
    case jailbroken
    case databaseFailure
    case backendObsolete
    case clientObsolete
    case pendingCertificateEnroll
    case networkError(code: Int)
    case genericError
}

struct BlockerViewModel {

    struct Capabilities {
        let canSwitchAccounts: Bool
        let hasSelectedAccount: Bool
    }

    enum Route {
        case obsoleteClient
        case obsoleteServer
        case alert(AlertState)
    }

    struct AlertState {
        let title: String
        let message: String
        let debugLogMessage: String?
        let actions: [ActionState]
    }

    struct ActionState {
        let title: String
        let style: ActionStyle
        let kind: ActionKind
    }

    enum ActionStyle {
        case `default`
        case cancel
        case destructive
    }

    enum ActionKind {
        case ok
        case switchAccount
        case sendLogs
        case signOut
        case retrySelectedAccount
        case retryStart
        case requestDatabaseDeletion
        case confirmDatabaseDeletion
        case cancelDatabaseDeletion
        case learnMoreCertificate
        case getCertificate
    }

    private let context: BlockerViewControllerContext
    private let errorDescription: String?

    init(context: BlockerViewControllerContext, error: Error? = nil) {
        self.context = context
        self.errorDescription = error?.localizedDescription
    }

    func route(capabilities: Capabilities) -> Route {
        switch context {
        case .blacklist, .clientObsolete:
            .obsoleteClient
        case .backendObsolete:
            .obsoleteServer
        case .jailbroken:
            .alert(jailbrokenAlert)
        case .databaseFailure:
            .alert(databaseFailureAlert(canSwitchAccounts: capabilities.canSwitchAccounts))
        case .pendingCertificateEnroll:
            .alert(certificateEnrollmentAlert)
        case let .networkError(code):
            .alert(networkErrorAlert(code: code, capabilities: capabilities))
        case .genericError:
            .alert(genericErrorAlert(capabilities: capabilities))
        }
    }

    var databaseDeletionConfirmationAlert: AlertState {
        .init(
            title: L10n.Localizable.Databaseloadingfailure.Alert.deleteDatabase,
            message: L10n.Localizable.Databaseloadingfailure.Alert.DeleteDatabase.message,
            debugLogMessage: nil,
            actions: [
                .init(
                    title: L10n.Localizable.Databaseloadingfailure.Alert.DeleteDatabase.continue,
                    style: .destructive,
                    kind: .confirmDatabaseDeletion
                ),
                .init(
                    title: L10n.Localizable.General.cancel,
                    style: .default,
                    kind: .cancelDatabaseDeletion
                )
            ]
        )
    }

    private var jailbrokenAlert: AlertState {
        .init(
            title: L10n.Localizable.Jailbrokendevice.Alert.title,
            message: L10n.Localizable.Jailbrokendevice.Alert.message,
            debugLogMessage: nil,
            actions: [
                .init(
                    title: L10n.Localizable.General.ok,
                    style: .cancel,
                    kind: .ok
                )
            ]
        )
    }

    private var certificateEnrollmentAlert: AlertState {
        typealias E2EI = L10n.Localizable.Registration.Signin.E2ei

        return .init(
            title: E2EI.title,
            message: E2EI.subtitle,
            debugLogMessage: nil,
            actions: [
                .init(
                    title: L10n.Localizable.FeatureConfig.Alert.MlsE2ei.Button.learnMore,
                    style: .default,
                    kind: .learnMoreCertificate
                ),
                .init(
                    title: E2EI.GetCertificateButton.title,
                    style: .default,
                    kind: .getCertificate
                )
            ]
        )
    }

    private func databaseFailureAlert(canSwitchAccounts: Bool) -> AlertState {
        var actions: [ActionState] = [
            .init(
                title: L10n.Localizable.Self.Settings.TechnicalReport.sendReport,
                style: .default,
                kind: .sendLogs
            ),
            .init(
                title: L10n.Localizable.Databaseloadingfailure.Alert.retry,
                style: .default,
                kind: .retryStart
            ),
            .init(
                title: L10n.Localizable.Databaseloadingfailure.Alert.deleteDatabase,
                style: .destructive,
                kind: .requestDatabaseDeletion
            )
        ]

        if canSwitchAccounts {
            actions.append(
                .init(
                    title: L10n.Localizable.AccountBlocked.GenericError.Alert.switchAccounts,
                    style: .default,
                    kind: .switchAccount
                )
            )
        }

        return .init(
            title: L10n.Localizable.Databaseloadingfailure.Alert.title,
            message: L10n.Localizable.Databaseloadingfailure.Alert.message(errorDescription ?? "-"),
            debugLogMessage: nil,
            actions: actions
        )
    }

    private func networkErrorAlert(code: Int, capabilities: Capabilities) -> AlertState {
        typealias Strings = L10n.Localizable.AccountBlocked.NetworkError.Alert

        return accountLoadingErrorAlert(
            title: Strings.title,
            message: Strings.message,
            debugLogMessage: "Account failed to load due to network error (code: \(code))",
            capabilities: capabilities
        )
    }

    private func genericErrorAlert(capabilities: Capabilities) -> AlertState {
        typealias Strings = L10n.Localizable.AccountBlocked.GenericError.Alert

        return accountLoadingErrorAlert(
            title: Strings.title,
            message: Strings.message,
            debugLogMessage: "Account failed to load",
            capabilities: capabilities
        )
    }

    private func accountLoadingErrorAlert(
        title: String,
        message: String,
        debugLogMessage: String,
        capabilities: Capabilities
    ) -> AlertState {
        typealias Strings = L10n.Localizable.AccountBlocked.GenericError.Alert

        var actions = [ActionState]()

        if capabilities.canSwitchAccounts {
            actions.append(
                .init(
                    title: Strings.switchAccounts,
                    style: .default,
                    kind: .switchAccount
                )
            )
        }

        actions.append(
            .init(
                title: Strings.sendLogs,
                style: .default,
                kind: .sendLogs
            )
        )

        if capabilities.hasSelectedAccount {
            actions.append(
                .init(
                    title: L10n.Localizable.Self.signOut,
                    style: .default,
                    kind: .signOut
                )
            )

            actions.append(
                .init(
                    title: Strings.retry,
                    style: .cancel,
                    kind: .retrySelectedAccount
                )
            )
        }

        return .init(
            title: title,
            message: message,
            debugLogMessage: debugLogMessage,
            actions: actions
        )
    }
}
