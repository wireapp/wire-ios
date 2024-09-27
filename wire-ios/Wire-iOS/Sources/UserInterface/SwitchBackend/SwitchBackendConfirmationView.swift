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

import SwiftUI

struct SwitchBackendConfirmationView: View {
    // MARK: Internal

    let viewModel: SwitchBackendConfirmationViewModel

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            title
            backendDetails
            buttons
        }
        .padding()
        .interactiveDismissDisabled()
    }

    // MARK: Private

    private typealias Strings = L10n.Localizable.UrlAction.SwitchBackendConfirmation

    @ViewBuilder private var title: some View {
        Text(Strings.title)
            .font(.textStyle(.h2))
            .foregroundStyle(Color.primaryText)
    }

    @ViewBuilder private var backendDetails: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(Strings.message)
                    .foregroundStyle(Color.primaryText)

                itemView(
                    title: Strings.backendName,
                    value: viewModel.backendName
                )

                itemView(
                    title: Strings.backendUrl,
                    value: viewModel.backendURL,
                    isURL: true
                )

                itemView(
                    title: Strings.backendWsurl,
                    value: viewModel.backendWSURL,
                    isURL: true
                )

                itemView(
                    title: Strings.blacklistUrl,
                    value: viewModel.blacklistURL,
                    isURL: true
                )

                itemView(
                    title: Strings.teamsUrl,
                    value: viewModel.teamsURL,
                    isURL: true
                )

                itemView(
                    title: Strings.accountsUrl,
                    value: viewModel.accountsURL,
                    isURL: true
                )

                itemView(
                    title: Strings.websiteUrl,
                    value: viewModel.websiteURL,
                    isURL: true
                )
            }
        }
    }

    @ViewBuilder private var buttons: some View {
        VStack(spacing: 6) {
            cancelButton
            proceedButton
        }
    }

    @ViewBuilder private var cancelButton: some View {
        Button {
            viewModel.handleEvent(.userDidCancel)
            dismiss()
        } label: {
            Text(L10n.Localizable.General.cancel)
                .font(.textStyle(.buttonBig))
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    @ViewBuilder private var proceedButton: some View {
        Button {
            viewModel.handleEvent(.userDidConfirm)
            dismiss()
        } label: {
            Text(Strings.proceed)
                .font(.textStyle(.buttonBig))
        }
        .buttonStyle(PrimaryButtonStyle())
    }

    @ViewBuilder
    private func itemView(
        title: String,
        value: String,
        isURL: Bool = false
    ) -> some View {
        VStack {
            Text(title)
                .foregroundStyle(Color.secondaryText)
            Text(value)
                .foregroundStyle(Color.primaryText)
                // Helps VoiceOver read the URLs better.
                .accessibilityTextContentType(isURL ? .fileSystem : .plain)
        }
    }
}

// MARK: - Previews

#Preview {
    SwitchBackendConfirmationView(
        viewModel: SwitchBackendConfirmationViewModel(
            backendName: "Staging",
            backendURL: "www.staging.com",
            backendWSURL: "www.ws.staging.com",
            blacklistURL: "www.blacklist.staging.com",
            teamsURL: "www.teams.staging.com",
            accountsURL: "www.accounts.staging.com",
            websiteURL: "www.wire.com",
            didConfirm: { _ in }
        )
    )
}
