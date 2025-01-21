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

struct SwitchBackendConfirmationView_V2: View {

    private typealias Strings = L10n.SwitchBackendConfirmation

    let viewModel: SwitchBackendConfirmationViewModel_V2

    @Environment(\.dismiss) var dismiss
    @State private var showFullDetails: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            title
            backendDetails
            buttons
        }
        .padding()
        .interactiveDismissDisabled()
    }

    @ViewBuilder private var title: some View {
        Text(Strings.title)
            .font(.textStyle(.h2))
            .foregroundStyle(Color.primaryText)
    }

    @ViewBuilder private var backendDetails: some View {
        VStack(spacing: 16) {
            Text(Strings.message)
                .foregroundStyle(Color.primaryText)

            if showFullDetails {
                ScrollView {
                    VStack(spacing: 16) {
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
            } else {
                itemView(
                    title: Strings.backendName,
                    value: viewModel.backendName
                )

                itemView(
                    title: Strings.backendUrl,
                    value: viewModel.backendURL,
                    isURL: true
                )

                Button {
                    withAnimation {
                        showFullDetails.toggle()
                        viewModel.handleEvent(.showDetails)
                    }
                } label: {
                    Text(Strings.showDetails)
                        .font(.textStyle(.body1))
                        .foregroundStyle(Color.primaryText)
                        .underline()
                        .padding(.top, 8)
                }
            }
        }
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
            Text(Strings.cancel)
                .font(.textStyle(.buttonBig))
        }
        //.buttonStyle(SecondaryButtonStyle())
    }

    @ViewBuilder private var proceedButton: some View {
        Button {
            viewModel.handleEvent(.userDidConfirm)
            dismiss()
        } label: {
            Text(Strings.proceed)
                .font(.textStyle(.buttonBig))
        }
        //.buttonStyle(PrimaryButtonStyle())
    }


}

// MARK: - Previews

#Preview {
    SwitchBackendConfirmationView_V2(
        viewModel: SwitchBackendConfirmationViewModel_V2(
            backendName: "Staging",
            backendURL: "www.staging.com",
            backendWSURL: "www.ws.staging.com",
            blacklistURL: "www.blacklist.staging.com",
            teamsURL: "www.teams.staging.com",
            accountsURL: "www.accounts.staging.com",
            websiteURL: "www.wire.com",
            didConfirm: { _ in },
            showDetails: {}
        )
    )
}
