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

import SwiftUI
import WireAuthenticationAPI

package protocol RootFactory {

    @MainActor var viewModel: RootViewModel { get }

    @MainActor
    func determineAuthMethodFactory(backendInfo: BackendInfo) -> any DetermineAuthMethodFactory
}

package struct RootView: View {

    @StateObject var viewModel: RootViewModel

    private let cornerRadius: CGFloat = 10

    package init(
        factory: @autoclosure @escaping () -> any RootFactory
    ) {
        self._viewModel = StateObject(wrappedValue: factory().viewModel)
    }

    package var body: some View {
        BackgroundView()
            .universalSheet(item: $viewModel.modalDestination) { item in
                sheetContent(for: item)
            }
    }

    @ViewBuilder
    private func sheetContent(for sheet: RootView.ModalDestination) -> some View {
        switch sheet {
        case let .authFlow(backendInfo):
            NavigationStack(path: $viewModel.path) {
                DetermineAuthMethodView(
                    factory: viewModel.factory.determineAuthMethodFactory(
                        backendInfo: backendInfo
                    )
                )
            }
            // We must provide an explicit id so it knows to create a new
            // view when the backend info changes.
            .id(backendInfo)
            .sheetCornerRadius(cornerRadius, inNavigationStack: true)
            // The alert should be shown on the navigation stack, otherwise
            // it will dismiss the sheet.
            .alert(
                item: $viewModel.alert,
                title: { Text($0.title) },
                message: { Text($0.message) },
                actions: { alert in
                    switch alert {
                    case .obsoleteClient:
                        Button(L10n.ObsoleteClient.Alert.okButton, action: viewModel.goToAppStore)
                    default:
                        Button(L10n.Authentication.Error.confirm, action: {})
                    }
                }
            )
        }
    }

    package enum ModalDestination: Identifiable, Hashable {
        public var id: Self { self }

        case authFlow(backendInfo: BackendInfo)
    }
}
