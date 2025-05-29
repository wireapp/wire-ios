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
import WireDesign

public struct AccountSwitcherView: View {

    let accounts: [AccountUIModel]
    let options: [Option]

    public init(accounts: [AccountUIModel], options: [Option]) {
        self.accounts = accounts
        self.options = options
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(accounts.indices, id: \.self) { index in
                AccountView(account: accounts[index])
                    .padding(.horizontal, 16)
                    .padding(.top, 8.5)
                    .padding(.bottom, 10.5)
                if index < accounts.count - 1 || !options.isEmpty {
                    divider()
                        .padding(.leading, 64)
                }
            }

            ForEach(options.indices, id: \.self) { index in
                OptionView(option: options[index])
                    .padding(.horizontal, 16)
                    .padding(.top, 16.5)
                    .padding(.bottom, 18.5)

                if index < options.count - 1 {
                    divider()
                        .padding(.leading, 64)
                }
            }
        }
        .background(Color(uiColor: ColorTheme.Backgrounds.surface))
    }

    @ViewBuilder
    func divider() -> some View {
        Divider()
            .frame(height: 1)
            .background(Color(ColorTheme.Strokes.outline))
    }
}

#Preview {
    AccountSwitcherView(
        accounts: [
            AccountUIModel(
                avatarSource: .image(.strokedCheckmark),
                name: "Kim Dawson",
                handle: "@username",
                teamName: nil,
                backendName: nil,
                action: {}
            ),
            AccountUIModel(
                avatarSource: .text("DS"),
                name: "Deniz Agha",
                handle: "@username",
                teamName: "team name",
                backendName: "backend name",
                action: {}
            ),
            AccountUIModel(
                avatarSource: .text("SD"),
                name: "Willy Wonka",
                handle: "@username",
                teamName: "team name",
                backendName: "backend name long long long long",
                action: {}
            )

        ],
        options: [
            .addAccountOption(action: {}),
            .manageTeamOption(action: {})
        ]
    )
}
