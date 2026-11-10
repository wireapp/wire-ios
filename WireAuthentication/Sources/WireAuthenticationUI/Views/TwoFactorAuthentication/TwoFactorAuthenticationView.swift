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
import WireDesign

@MainActor
package struct TwoFactorAuthenticationView<ViewModel: TwoFactorAuthenticationViewModelProtocol>: View {

    @State private var viewModel: ViewModel

    private typealias Strings = L10n.Localizable.TwoFactorAuthentication

    package init(viewModel: ViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    package var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statusRow

                Divider()

                Text(Strings.description)
                    .font(.body)
                    .foregroundStyle(Color(ColorTheme.Base.secondaryText))

                if viewModel.isTwoFactorAuthenticationEnabled == true {
                    enabledDetails
                        .padding(.top, 16)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionButton
                .disabled(viewModel.isLoading || viewModel.isTwoFactorAuthenticationEnabled == nil)
                .padding()
                .background(Color(ColorTheme.Backgrounds.background))
        }
        .background(Color(ColorTheme.Backgrounds.background))
        .accessibilityIdentifier("twoFactorAuthenticationView")
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadStatus()
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if viewModel.isTwoFactorAuthenticationEnabled == true {
            Button(role: .destructive, action: viewModel.turnOff) {
                Text(Strings.turnOff)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color(ColorTheme.Base.error))
            .foregroundStyle(Color(ColorTheme.Base.onError))
            .accessibilityLabel(Strings.turnOff)
            .accessibilityIdentifier("twoFactorAuthenticationTurnOffButton")
        } else {
            Button(Strings.setUp, action: viewModel.setUp)
                .bold()
                .wireButtonStyle(.primary)
                .accessibilityLabel(Strings.setUp)
                .accessibilityIdentifier("twoFactorAuthenticationSetUpButton")
        }
    }

    private var enabledDetails: some View {
        VStack(spacing: 0) {
            detailRow(
                title: Strings.AuthenticatorApps.title,
                summary: viewModel.registeredAuthenticatorApps.map { Strings.AuthenticatorApps.count($0.count) },
                identifier: "twoFactorAuthenticationAuthenticatorAppsCell",
                action: viewModel.showAuthenticatorApps
            )

            Divider()

            detailRow(
                title: Strings.RecoveryCodes.title,
                summary: viewModel.recoveryCodesStatus.map {
                    Strings.RecoveryCodes.remaining($0.remainingCount, $0.originalCount)
                },
                identifier: "twoFactorAuthenticationRecoveryCodesCell",
                action: viewModel.showRecoveryCodes
            )

            Divider()
        }
    }

    private func detailRow(
        title: String,
        summary: String?,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color(ColorTheme.Backgrounds.onBackground))

                    if let summary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(Color(ColorTheme.Base.secondaryText))
                    } else if viewModel.isLoading {
                        ProgressView()
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.forward")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(ColorTheme.Base.secondaryText))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading || summary == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(summary ?? (viewModel.isLoading ? Strings.loading : ""))
        .accessibilityIdentifier(identifier)
    }

    private var statusRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                statusTitle
                Spacer(minLength: 16)
                statusBadge
            }

            VStack(alignment: .leading, spacing: 8) {
                statusTitle
                statusBadge
            }
        }
    }

    private var statusTitle: some View {
        Text(Strings.title)
            .font(.headline)
            .foregroundStyle(Color(ColorTheme.Backgrounds.onBackground))
    }

    @ViewBuilder
    private var statusBadge: some View {
        if viewModel.isLoading {
            ProgressView()
                .accessibilityLabel(Strings.loading)
                .accessibilityIdentifier("twoFactorAuthenticationLoadingIndicator")
        } else if let isEnabled = viewModel.isTwoFactorAuthenticationEnabled {
            Text(isEnabled ? Strings.Status.on : Strings.Status.off)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(ColorTheme.Backgrounds.onBackground))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Color(ColorTheme.Backgrounds.backgroundVariant),
                    in: RoundedRectangle(cornerRadius: 4)
                )
                .accessibilityLabel(Strings.title)
                .accessibilityValue(isEnabled ? Strings.Status.on : Strings.Status.off)
                .accessibilityIdentifier("twoFactorAuthenticationStatus")
        }
    }
}

#Preview("Off") {
    NavigationStack {
        TwoFactorAuthenticationView(viewModel: PreviewTwoFactorAuthenticationViewModel())
    }
}

#Preview("On") {
    NavigationStack {
        TwoFactorAuthenticationView(viewModel: PreviewTwoFactorAuthenticationViewModel.enabled)
    }
}

#Preview("On, Large Text") {
    NavigationStack {
        TwoFactorAuthenticationView(viewModel: PreviewTwoFactorAuthenticationViewModel.enabled)
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Loading Details") {
    NavigationStack {
        TwoFactorAuthenticationView(viewModel: PreviewTwoFactorAuthenticationViewModel(
            isTwoFactorAuthenticationEnabled: true,
            isLoading: true
        ))
    }
}

#Preview("Loading") {
    NavigationStack {
        TwoFactorAuthenticationView(viewModel: PreviewTwoFactorAuthenticationViewModel(
            isTwoFactorAuthenticationEnabled: nil,
            isLoading: true
        ))
    }
}

private struct PreviewTwoFactorAuthenticationViewModel: TwoFactorAuthenticationViewModelProtocol {

    var isTwoFactorAuthenticationEnabled: Bool? = false
    var isLoading = false
    var registeredAuthenticatorApps: [RegisteredAuthenticatorApp]?
    var recoveryCodesStatus: RecoveryCodesStatus?

    static var enabled: Self {
        Self(
            isTwoFactorAuthenticationEnabled: true,
            registeredAuthenticatorApps: [
                RegisteredAuthenticatorApp(
                    name: "Google Authenticator",
                    registrationDate: Date(timeIntervalSince1970: 1_790_000_000)
                ),
                RegisteredAuthenticatorApp(
                    name: "1Password",
                    registrationDate: Date(timeIntervalSince1970: 1_790_086_400)
                )
            ],
            recoveryCodesStatus: RecoveryCodesStatus(originalCount: 10, remainingCount: 10)
        )
    }

    func loadStatus() async {}
    func setUp() {}
    func turnOff() {}
    func showAuthenticatorApps() {}
    func showRecoveryCodes() {}

}
