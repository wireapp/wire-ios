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

import SwiftUI
import WireAuthenticationAPI
import WireNetwork
import WireReusableUIComponents

package protocol RootFactory {

    @MainActor var viewModel: RootViewModel { get }

    @MainActor
    func determineAuthMethodFactory(environment: BackendEnvironment2) -> any DetermineAuthMethodFactory

    @MainActor
    func reloginViaEmailFactory(email: String) -> any ReloginViaEmailFactory

    @MainActor
    func reloginViaSSOFactory() -> any ReloginViaSSOFactory

    @MainActor
    func accountsSwitcherFactory() -> any AccountSwitcherFactory
}

package struct RootView: View {

    @StateObject private var viewModel: RootViewModel

    private let cornerRadius: CGFloat = 10

    private typealias Strings = L10n.Localizable

    package init(
        factory: @autoclosure @escaping () -> any RootFactory
    ) {
        self._viewModel = StateObject(wrappedValue: factory().viewModel)
    }

    package var body: some View {
        BackgroundView()
            .universalSheet(item: $viewModel.modalDestination) { item in
                sheetContent(for: item)
                    .sheetCornerRadius(cornerRadius, inNavigationStack: true)
                    // The alert should be shown on the navigation stack, otherwise
                    // it will dismiss the sheet.
                    .alert(
                        item: $viewModel.alert,
                        title: { alert in
                            switch alert {
                            case .obsoleteClient:
                                Text(
                                    viewModel.isMultibackendEnabled ? L10n.Localizable.ObsoleteClientMultibackend.Alert
                                        .title : L10n.Localizable.ObsoleteClient.Alert.title
                                )
                            default:
                                Text(alert.title)
                            }
                        },
                        message: { alert in
                            switch alert {
                            case .obsoleteBackend:
                                Text(
                                    viewModel.isMultibackendEnabled ? L10n.Localizable.ObsoleteBackendMultibackend.Alert
                                        .message : L10n.Localizable.ObsoleteBackend.Alert.message
                                )
                            case .obsoleteClient:
                                Text(
                                    viewModel.isMultibackendEnabled ? L10n.Localizable.ObsoleteClientMultibackend
                                        .Alert.message : L10n.Localizable.ObsoleteClient.Alert.message
                                )
                            default:
                                Text(alert.message)
                            }
                        },
                        actions: { alert in
                            switch alert {
                            case .obsoleteClient:
                                obsoleteClientAlertActions()
                            case .obsoleteBackend where viewModel.isMultibackendEnabled:
                                obsoleteBackendAlertActions()
                            case .logoutConfirmation:
                                logoutConfirmationButtons
                            default:
                                Button(Strings.Authentication.Error.confirm, action: {})
                            }
                        }
                    )
            }
    }

    @ViewBuilder
    private func sheetContent(for sheet: RootViewSheet) -> some View {
        switch sheet {
        case let .authFlow(environment):
            // The navigation stack needs to wrap the view otherwise we may
            // run into issues finding the right navigation path.
            // See [WPB-20414]
            NavigationStack(path: $viewModel.path) {
                DetermineAuthMethodView(
                    factory: viewModel.factory.determineAuthMethodFactory(
                        environment: environment
                    )
                )

            }
            // We must provide an explicit id so it knows to create a new
            // view when the backend environment changes.
            .id(environment)
        case let .reauthFlow(email):
            NavigationStack(path: $viewModel.path) {
                ReloginViaEmailView(
                    factory: viewModel.factory.reloginViaEmailFactory(
                        email: email
                    )
                )
            }
        case .reauthSSO:
            NavigationStack(path: $viewModel.path) {
                ReloginViaSSOView(
                    factory: viewModel.factory.reloginViaSSOFactory()
                )
            }
        case .accountSwitcher:
            AccountSwitcherModalView(
                factory: viewModel.factory.accountsSwitcherFactory()
            )
        }
    }

    @ViewBuilder
    fileprivate func switchAccountsAlertButtonIfNeeded() -> some View {
        if viewModel.shouldShowSwitchAccountsAlertButton {
            Button(
                Strings.Obsolete.Alert.switchAccounts,
                action: viewModel.switchAccounts
            )
        }
    }

    @ViewBuilder
    private func obsoleteBackendAlertActions() -> some View {
        Button(
            Strings.Obsolete.Alert.ok,
            action: viewModel.dismissAlert
        )
        switchAccountsAlertButtonIfNeeded()
    }

    @ViewBuilder
    private func obsoleteClientAlertActions() -> some View {
        Button(
            viewModel.isMultibackendEnabled ? Strings.Obsolete.Alert.updateButton : Strings.ObsoleteClient.Alert
                .okButton,
            action: viewModel.goToAppStore
        )
        switchAccountsAlertButtonIfNeeded()
        if viewModel.isMultibackendEnabled {
            Button(
                Strings.Obsolete.Alert.cancel,
                action: viewModel.dismissAlert
            )
        }
    }

    @ViewBuilder private var logoutConfirmationButtons: some View {
        Button(Strings.Logout.Alert.cancel, role: .cancel) {}
        Button(Strings.Logout.Alert.keepDataButton) {
            viewModel.logout(deleteData: false)
        }
        Button(Strings.Logout.Alert.deleteDataButton, role: .destructive) {
            viewModel.logout(deleteData: true)
        }
    }

}
