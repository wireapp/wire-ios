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

public struct AccountSwitcherView: View {

    let otherAccounts: [AccountUIModel]
    let options: [Option]
    let showLastSeparator: Bool

    public init(
        otherAccounts: [AccountUIModel],
        options: [Option],
        showLastSeparator: Bool
    ) {
        self.otherAccounts = otherAccounts
        self.options = options
        self.showLastSeparator = showLastSeparator
    }

    public var body: some View {
        VStack(spacing: 0) {

            let totalCount = otherAccounts.count + options.count

            ForEach(0 ..< totalCount, id: \.self) { index in
                if index < otherAccounts.count {
                    AccountView(account: otherAccounts[index])
                        .padding(EdgeInsets(top: 8.5, leading: 16, bottom: 8.5, trailing: 20))
                } else {
                    OptionView(option: options[index - otherAccounts.count])
                        .padding(EdgeInsets(top: 16.5, leading: 16, bottom: 18.5, trailing: 20))
                }

                let isLastItem = index == totalCount - 1
                if showLastSeparator || !isLastItem {
                    divider()
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
            .padding(.leading, 64)
    }
}

#Preview {
    AccountSwitcherView(
        otherAccounts: [
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
        ],
        showLastSeparator: false
    )
}
