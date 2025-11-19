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
import WireDesign
import WireNetwork

public struct SwitchBackendConfirmation: View {

    private typealias Strings = L10n.Localizable.SwitchBackendConfirmation

    private struct Item {

        let title: String
        let value: String
        let isURL: Bool

    }

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
    @State private var showFullDetails: Bool = false

    private let items: [Item]
    private let onConfirm: (Bool) -> Void

    public init(
        environment: BackendEnvironment2,
        onConfirm: @escaping (Bool) -> Void
    ) {
        var items = [
            Item(
                title: Strings.backendName,
                value: environment.title,
                isURL: false
            ),
            Item(
                title: Strings.backendUrl,
                value: environment.config.endpoints.restAPIURL.absoluteString,
                isURL: true
            ),
            Item(
                title: Strings.backendWsurl,
                value: environment.config.endpoints.websocketURL.absoluteString,
                isURL: true
            ),
            Item(
                title: Strings.blacklistUrl,
                value: environment.config.endpoints.blacklistURL.absoluteString,
                isURL: true
            ),
            Item(
                title: Strings.teamsUrl,
                value: environment.config.endpoints.teamsURL.absoluteString,
                isURL: true
            ),
            Item(
                title: Strings.accountsUrl,
                value: environment.config.endpoints.accountsURL.absoluteString,
                isURL: true
            ),
            Item(
                title: Strings.websiteUrl,
                value: environment.config.endpoints.websiteURL.absoluteString,
                isURL: true
            )
        ]

        self.items = items
        self.onConfirm = onConfirm
    }

    // MARK: - UI

    public var body: some View {
        VStack(spacing: 20) {
            title
            backendDetails
            buttons
        }
        .padding()
        .interactiveDismissDisabled()
        .background(ColorTheme.Backgrounds.surface.color)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.Backgrounds.surface.color, lineWidth: 1)
        )
        .frame(width: 350)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var title: some View {
        Text(Strings.title)
            .font(for: .h2)
            .foregroundStyle(Color.primaryText)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .minimumScaleFactor(0.8)
    }

    private var backendDetails: some View {
        Group {
            if showFullDetails {
                fullDetails
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            } else {
                shortDetails
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            }
        }
        .animation(.default, value: showFullDetails)
    }

    private var contentHeight: CGFloat {
        UIScreen.main.bounds.height * 0.4
    }

    private var fullDetails: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(Strings.message)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(items, id: \.title) { model in
                    itemView(
                        title: model.title,
                        value: model.value,
                        isURL: model.isURL
                    )
                }
            }
        }
        .frame(maxHeight: contentHeight)
    }

    private var shortDetails: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(Strings.message)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(items.prefix(2), id: \.title) { model in
                    itemView(
                        title: model.title,
                        value: model.value,
                        isURL: model.isURL
                    )
                }
                Button {
                    withAnimation {
                        showFullDetails.toggle()
                    }
                } label: {
                    Text(Strings.showDetails)
                        .font(for: .body1)
                }
                .wireButtonStyle(.link)
            }
        }
        .frame(maxHeight: contentHeight)
    }

    private func itemView(
        title: String,
        value: String,
        isURL: Bool = false
    ) -> some View {
        VStack {
            Text(title)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .foregroundStyle(Color.primaryText)
                .accessibilityTextContentType(isURL ? .fileSystem : .plain)
        }
    }

    private var buttons: some View {
        VStack(spacing: 6) {
            cancelButton
            proceedButton
        }
    }

    private var cancelButton: some View {
        Button {
            dismiss()
            onConfirm(false)
        } label: {
            Text(Strings.cancel)
                .font(for: .buttonBig)
        }
        .wireButtonStyle(.secondary)
    }

    private var proceedButton: some View {
        Button {
            dismiss()
            onConfirm(true)
        } label: {
            Text(Strings.proceed)
                .font(for: .buttonBig)
        }
        .wireButtonStyle(.primary)
    }

}
