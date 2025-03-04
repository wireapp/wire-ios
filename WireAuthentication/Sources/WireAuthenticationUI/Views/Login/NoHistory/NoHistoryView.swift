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

package protocol NoHistoryViewBuilder {

    @MainActor
    func noHistoryView(
        userID: UUID,
        cookies: [HTTPCookie],
        accessToken: AccessToken?,
        emailConflictWithCloudAccount: Bool
    ) -> NoHistoryView

}

package struct NoHistoryView: View {

    @StateObject var viewModel: NoHistoryViewModel

    package init(
        viewModel: NoHistoryViewModel
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    package var body: some View {
        VStack(spacing: 20) {
            Text(L10n.Authentication.NoHistory.title)
                .multilineTextAlignment(.center)
                .font(.textStyle(.h2))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.Authentication.NoHistory.message)
                .multilineTextAlignment(.center)
                .wireTextStyle(.body1)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Button(L10n.Authentication.NoHistory.confirm, action: viewModel.confirm)
                .wireButtonStyle(.primary)
                .bold()
        }
        .alert(
            item: $viewModel.alert,
            title: titleForAlert,
            message: messageForAlert,
            actions: { _ in
                Button(L10n.Authentication.Error.howToChangeEmail, action: {
                    viewModel.howToChangeEmail()
                })
                Button(L10n.Authentication.Error.howToDeleteAccount, action: {
                    viewModel.howToDeleteAccount()
                })
                Button(L10n.Authentication.Error.confirm, action: {})
            }
        )
        .onAppear {
            if viewModel.emailConflictWithCloudAccount {
                viewModel.alert = .cloudAccountAlreadyRegistered
            }
        }
        .padding()
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    private func titleForAlert(_ alert: NoHistoryViewModel.Alert) -> Text {
        switch alert {
        case .cloudAccountAlreadyRegistered:
            Text(L10n.Authentication.Error.Title.emailAlreadyInUse)
        }
    }

    private func messageForAlert(_ alert: NoHistoryViewModel.Alert) -> Text {
        switch alert {
        case .cloudAccountAlreadyRegistered:
            Text(L10n.Authentication.Error.Message.emailAlreadyInUse)
        }
    }

}

#Preview {
    let viewModel = NoHistoryViewModel(
        userID: UUID(),
        cookies: [],
        accessToken: nil,
        emailConflictWithCloudAccount: false,
        howToChangeEmailURL: URL(string: "https://wire.com")!,
        howToDeleteAccountURL: URL(string: "https://wire.com")!,
        onFlowCompletion: { _ in }
    )
    NoHistoryView(viewModel: viewModel)
}

#Preview("With background") {
    BackgroundView()
        .sheet(isPresented: .constant(true)) {
            let viewModel = NoHistoryViewModel(
                userID: UUID(),
                cookies: [],
                accessToken: nil,
                emailConflictWithCloudAccount: false,
                howToChangeEmailURL: URL(string: "https://wire.com")!,
                howToDeleteAccountURL: URL(string: "https://wire.com")!,
                onFlowCompletion: { _ in }
            )
            NoHistoryView(viewModel: viewModel)
        }
}
