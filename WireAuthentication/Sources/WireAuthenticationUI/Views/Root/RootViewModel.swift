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

import Combine
import Foundation
import SwiftUI
import WireAuthenticationAPI

@MainActor
package final class RootViewModel: ObservableObject, Router {

    package typealias Factory =
        OpenAppStoreUseCaseFactory &
        RootFactory

    // MARK: - View state

    @Published var path = NavigationPath()
    @Published var modalDestination: RootViewSheet?
    @Published var alert: Alert?

    // MARK: - Dependencies

    package let factory: any Factory
    private var cancellable: AnyCancellable?
    private var lastModalDestination: RootViewSheet?

    // MARK: - Life cycle

    package init(
        factory: any Factory,
        bridge: WireAuthenticationBridge,
        backendInfo: BackendInfo
    ) {
        self.factory = factory
        self.modalDestination = .authFlow(backendInfo: backendInfo)
        self.cancellable = bridge.inboundEvents.sink { [weak self] event in
            switch event {
            case .didRewindToThisView:
                self?.restoreSheet()
            default:
                break
            }
        }
    }

    // MARK: - Actions

    package func popToRoot() {
        path.removeLast(path.count)
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

    public func dismissSheet() {
        lastModalDestination = modalDestination
        modalDestination = nil
    }

    func goToAppStore() {
        factory.openAppStoreUseCase().invoke()
    }

    // MARK: - Private

    private func restoreSheet() {
        if let lastModalDestination, modalDestination == nil {
            modalDestination = lastModalDestination
            self.lastModalDestination = nil
        }
    }

}
