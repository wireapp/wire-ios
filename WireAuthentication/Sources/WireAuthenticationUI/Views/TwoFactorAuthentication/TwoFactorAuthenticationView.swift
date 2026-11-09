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
            }
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(Strings.setUp, action: viewModel.setUp)
                .bold()
                .wireButtonStyle(.primary)
                .disabled(viewModel.isLoading || viewModel.isTwoFactorAuthenticationEnabled != false)
                .accessibilityLabel(Strings.setUp)
                .accessibilityIdentifier("twoFactorAuthenticationSetUpButton")
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

    func loadStatus() async {}
    func setUp() {}

}
