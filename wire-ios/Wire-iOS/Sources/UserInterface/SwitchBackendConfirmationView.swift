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

    private typealias Strings = L10n.Localizable.UrlAction.SwitchBackendConfirmation

    let viewModel: SwitchBackendConfirmationViewModel

    @Environment(\.dismiss)
    var dismiss

    var body: some View {
        VStack(spacing: 24) {
            title
            backendDetails
            buttons
        }
        .padding()
    }

    @ViewBuilder
    private var title: some View {
        Text(Strings.title)
            .textStyle(.h2)
            .foregroundStyle(Color.primaryText)
    }

    @ViewBuilder
    private var backendDetails: some View {
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
                    value: viewModel.backendURL
                )

                itemView(
                    title: Strings.backendWsurl,
                    value: viewModel.backendWSURL
                )

                itemView(
                    title: Strings.blacklistUrl,
                    value: viewModel.blacklistURL
                )

                itemView(
                    title: Strings.teamsUrl,
                    value: viewModel.teamsURL
                )

                itemView(
                    title: Strings.accountsUrl,
                    value: viewModel.accountsURL
                )

                itemView(
                    title: Strings.websiteUrl,
                    value: viewModel.websiteURL
                )
            }
        }

        // TODO: When iOS 16.4 is min version
        // add this to scroll view to enable scrolling only when needed
        // .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
    }

    @ViewBuilder
    private func itemView(
        title: String,
        value: String
    ) -> some View {
        VStack {
            Text(title)
                .foregroundStyle(Color.secondaryText)
            Text(value)
                .foregroundStyle(Color.primaryText)
        }
    }

    @ViewBuilder
    private var buttons: some View {
        VStack(spacing: 6) {
            cancelButton
            proceedButton
        }
    }

    @ViewBuilder
    private var cancelButton: some View {
        Button {
            viewModel.handleEvent(.userDidCancel)
            dismiss()
        } label: {
            Text(L10n.Localizable.General.cancel)
                .textStyle(.buttonBig)
        }
        .buttonStyle(SecondaryButton())
    }

    @ViewBuilder
    private var proceedButton: some View {
        Button {
            viewModel.handleEvent(.userDidConfirm)
            dismiss()
        } label: {
            Text(Strings.proceed)
                .textStyle(.buttonBig)
        }
        .buttonStyle(PrimaryButton())
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
            decisionHandler: { _ in }
        )
    )
}

struct PrimaryButton: SwiftUI.ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .expandToFill(axis: .horizontal)
                .background(Color.primaryButtonBackground)
                .foregroundStyle(Color.primaryButtonText)
                .clipShape(.rect(cornerRadius: 16))
        }

}

struct SecondaryButton: SwiftUI.ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .expandToFill(axis: .horizontal)
                .background(Color.secondaryButtonBackground)
                .foregroundStyle(Color.secondaryButtonText)
                .clipShape(.rect(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondaryButtonBorder, lineWidth: 1)
                )
        }

}

struct FrameExpansion: ViewModifier {

    let axis: Axis

    func body(content: Content) -> some View {
        switch axis {
        case .horizontal:
            return content.frame(maxWidth: .infinity)

        case .vertical:
            return content.frame(maxHeight: .infinity)
        }
    }

    enum Axis {

        case horizontal
        case vertical

    }

}

extension View {

    func expandToFill(axis: FrameExpansion.Axis) -> some View {
        modifier(FrameExpansion(axis: axis))
    }

}

extension Color {

    static let primaryText = Color(uiColor: UIColor(
            light: Asset.Colors.black,
            dark: Asset.Colors.white
        )
    )

    static let secondaryText = Color(uiColor: UIColor(
            light: Asset.Colors.gray70,
            dark: Asset.Colors.gray30
        )
    )

    static let primaryButtonBackground = Color(uiColor: UIColor(
            light: Asset.Colors.blue500Light,
            dark: Asset.Colors.blue500Dark
        )
    )

    static let primaryButtonText = Color(uiColor: UIColor(
            light: Asset.Colors.white,
            dark: Asset.Colors.black
        )
    )

    static let secondaryButtonBackground = Color(uiColor: UIColor(
            light: Asset.Colors.white,
            dark: Asset.Colors.gray95
        )
    )

    static let secondaryButtonBorder = Color(uiColor: UIColor(
            light: Asset.Colors.gray40,
            dark: Asset.Colors.gray80
        )
    )

    static let secondaryButtonText = Color(uiColor: UIColor(
            light: Asset.Colors.black,
            dark: Asset.Colors.white
        )
    )


}

enum WireTextStyle {

    case h1
    case h2
    case h3
    case h4
    case h5
    case body1
    case body2
    case body3
    case subline1
    case link
    case buttonSmall
    case buttonBig

}

extension Text {

    @ViewBuilder
    func textStyle(_ textStyle: WireTextStyle) -> some View {
        switch textStyle {
        case .h1:
            font(.title3)
        case .h2:
            font(.title3).bold()
        case .h3:
            font(.headline)
        case .h4:
            font(.subheadline)
        case .h5:
            font(.footnote)
        case .body1:
            font(.body)
        case .body2:
            font(.callout).fontWeight(.semibold)
        case .body3:
            font(.callout).bold()
        case .subline1:
            font(.caption)
        case .link:
            font(.body).underline()
        case .buttonSmall:
            fatalError("not implemented")
        case .buttonBig:
            font(.title3).fontWeight(.semibold)
        }
    }

}
