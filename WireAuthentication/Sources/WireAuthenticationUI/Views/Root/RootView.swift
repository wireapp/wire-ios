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

package struct RootView: View {

    @StateObject var viewModel: RootViewModel

    let determineAuthMethodBuilder: any DetermineAuthMethodBuilder
    let noHistoryViewBuilder: any NoHistoryViewBuilder

    package init(
        viewModel: RootViewModel,
        determineAuthMethodBuilder: any DetermineAuthMethodBuilder,
        noHistoryViewBuilder: any NoHistoryViewBuilder
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.determineAuthMethodBuilder = determineAuthMethodBuilder
        self.noHistoryViewBuilder = noHistoryViewBuilder
    }

    package var body: some View {
        BackgroundView()
            .sheet(item: $viewModel.activeSheet) { sheet in
                switch sheet {
                case .authFlow:
                    NavigationStack(path: $viewModel.path) {
                        determineAuthMethodBuilder.determineAuthMethodView
                            .alert(
                                L10n.Authentication.Error.Title.ssoLoginFailed,
                                isPresented: $viewModel.showSSOFailureAlert
                            ) {
                                Button(L10n.Authentication.Error.confirm, role: .cancel) {
                                    viewModel.showSSOFailureAlert = false
                                }
                            } message: {
                                Text(L10n.Authentication.Error.Message.ssoLoginFailed)
                            }
                    }
                case let .noHistory(userID, cookieData):
                    noHistoryViewBuilder.noHistoryView(
                        userID: userID,
                        cookieData: cookieData
                    )
                }
            }
    }

}

#Preview {
    MockDependencies().rootView
}
