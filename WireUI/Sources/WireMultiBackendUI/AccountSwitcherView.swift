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

struct AccountSwitcherView: View {

    let accounts: [AccountUIModel]
    let options: [Option]

    var body: some View {
        List {
            ForEach(accounts) { account in
                AccountView(account: account)
            }
            
            ForEach(options) { option in
                OptionView(option: option)
                    .frame(height: 37)
            }
        }
        .background(Color(uiColor: SemanticColors.View.backgroundDefault))
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
                backendName: nil
            ),
            AccountUIModel(
                avatarSource: .text("DS"),
                name: "Deniz Agha",
                handle: "@username",
                teamName: "team name",
                backendName: "backend name"
            ),
        ],
        options: [
            .addAccountOption,
            .manageTeamOption
        ]
    )
}
