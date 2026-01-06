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

import Combine
import Foundation
import SwiftUI
import WireAuthenticationAPI
import WireNetwork

@MainActor
package final class RootViewModel: ObservableObject, Router {

    package typealias Factory =
        OpenAppStoreUseCaseFactory &
        RootFactory

    // MARK: - View state

    @Published var path = NavigationPath()
    @Published var modalDestination: RootViewSheet?
    @Published var alert: Alert?

    let isMultibackendEnabled: Bool
    let hasOtherAccountsProvider: () -> Bool

    var shouldShowSwitchAccountsAlertButton: Bool {
        isMultibackendEnabled && hasOtherAccountsProvider()
    }

    // MARK: - Dependencies

    package let factory: any Factory
    private var cancellable: AnyCancellable?
    private var lastModalDestination: RootViewSheet?
    private var bridge: WireAuthenticationBridge

    // MARK: - Life cycle

    package init(
        factory: any Factory,
        bridge: WireAuthenticationBridge,
        environment: BackendEnvironment2,
        authenticationType: AuthenticationType,
        isMultibackendEnabled: Bool,
        hasOtherAccountsProvider: @escaping () -> Bool
    ) {
        self.factory = factory
        self.isMultibackendEnabled = isMultibackendEnabled
        self.hasOtherAccountsProvider = hasOtherAccountsProvider
        self.bridge = bridge

        self.cancellable = bridge.inboundEvents.sink { [weak self] event in
            switch event {
            case .didRewindToThisView:
                self?.restoreSheet()
            default:
                break
            }
        }

        switch authenticationType {
        case .new:
            self.modalDestination = .authFlow(environment: environment)
        case let .reauthEmail(email):
            self.modalDestination = .reauthFlow(email: email)
        case .reauthSSO:
            self.modalDestination = .reauthSSO
        }
    }

    // MARK: - Actions

    package func popToRoot() {
        path.removeLast(path.count)
    }

    package func pop() {
        path.removeLast()
    }

    package func navigate(to destination: some Hashable) {
        path.append(destination)
    }

    package func presentSheet(_ modalDestination: RootViewSheet) {
        self.modalDestination = modalDestination
    }

    public func presentAlert(_ alert: Alert) {
        self.alert = alert
    }

    public func dismissAlert() {
        alert = nil
    }

    public func dismissSheet() {
        lastModalDestination = modalDestination
        modalDestination = nil
    }

    func goToAppStore() {
        factory.openAppStoreUseCase().invoke()
    }

    func switchAccounts() {
        modalDestination = .accountSwitcher
    }

    func logout(deleteData: Bool) {
        bridge.sendOutboundEvent(.logoutRequested(deleteData: deleteData))
    }

    // MARK: - Private

    private func restoreSheet() {
        if let lastModalDestination, modalDestination == nil {
            modalDestination = lastModalDestination
            self.lastModalDestination = nil
        }
    }

}
