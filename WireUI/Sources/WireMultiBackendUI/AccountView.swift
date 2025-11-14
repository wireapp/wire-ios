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
import WireAccountImageUI
import WireDesign
import WireReusableUIComponents

struct AccountView: View {

    let account: AccountUIModel

    var body: some View {
        let details = [
            account.handle.map { "@\($0)" },
            account.teamName,
            account.backendName
        ].compactMap(\.self)

        HStack {
            HStack(spacing: 22) {

                AccountImageViewRepresentable(
                    source: account.avatarSource,
                    availability: nil,
                    showNotificationsBadge: false
                )
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {

                    Text(account.name)
                        .font(for: .body2)
                        .bold()
                        .foregroundStyle(Color(SemanticColors.Label.textDefault))

                    DotSeparatedTextView(items: details)
                }
                .padding(.vertical, 4)
            }

            Spacer()

            Image("ChevronRight", bundle: Bundle.wireReusableUIComponentsBundle)
                .resizable()
                .scaledToFill()
                .frame(width: 16, height: 16)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(([account.name] + details).joined(separator: ","))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(L10n.Accessibility.Account.hint)
        .contentShape(Rectangle())
        .onTapGesture {
            account.action()
        }
    }
}

private struct DotSeparatedTextView: View {

    let items: [String]

    var body: some View {
        let combinedText = items
            .joined(separator: " • ")
        Text(combinedText)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .font(for: .subline1)
            .foregroundStyle(Color(SemanticColors.Label.baseSecondaryText))
    }
}

#Preview {
    List {
        AccountView(
            account: AccountUIModel(
                avatarSource: .image(.close),
                name: "Deniz Agha",
                handle: "username",
                teamName: "team name",
                backendName: "backend ",
                action: {}
            )
        )
        AccountView(
            account: AccountUIModel(
                avatarSource: .text("DS"),
                name: "Deniz Agha",
                handle: "username",
                teamName: "team name",
                backendName: "backend name long long long long long ",
                action: {}
            )
        )

    }
}
