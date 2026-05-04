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
import WireLocators
import WireReusableUIComponents

package struct NoHistoryView: View {

    @StateObject private var viewModel: NoHistoryViewModel

    private typealias Strings = L10n.Localizable.Authentication

    package init(
        factory: @autoclosure @escaping () -> NoHistoryFactory
    ) {
        self._viewModel = StateObject(wrappedValue: factory().viewModel)
    }

    package var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.didReauthenticate ? Strings.MissingHistory.title : Strings.NoHistory.title)
                .multilineTextAlignment(.center)
                .font(for: .h2)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Text(viewModel.didReauthenticate ? Strings.MissingHistory.message : Strings.NoHistory.message)
                .multilineTextAlignment(.center)
                .font(for: .body1)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                viewModel.confirm()
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                    }

                    Text(Strings.NoHistory.confirm)
                        .lineLimit(nil)
                }
            }
            .wireButtonStyle(.primary)
            .bold()
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier(Locators.FirstTimePage.okButton.rawValue)

        }
        .alert(
            item: $viewModel.alert,
            title: titleForAlert,
            message: messageForAlert,
            actions: { _ in
                Button(Strings.Error.howToChangeEmail, action: {
                    viewModel.howToChangeEmail()
                })
                Button(Strings.Error.howToDeleteAccount, action: {
                    viewModel.howToDeleteAccount()
                })
                Button(Strings.Error.confirm, action: {
                    viewModel.confirmAlert()
                })
            }
        )
        .onAppear {
            viewModel.onAppear()
        }
        .padding(.vertical, 32)
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification
            )
        ) { _ in
            viewModel.onAppear()
        }
        .padding()
        .setPreferredSize()
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
        .navigationBarBackButtonHidden()
    }

    private func titleForAlert(_ alert: NoHistoryViewModel.Alert) -> Text {
        switch alert {
        case .cloudAccountAlreadyRegistered:
            Text(Strings.Error.Title.emailAlreadyInUse)
        }
    }

    private func messageForAlert(_ alert: NoHistoryViewModel.Alert) -> Text {
        switch alert {
        case .cloudAccountAlreadyRegistered:
            Text(Strings.Error.Message.emailAlreadyInUse)
        }
    }

}
