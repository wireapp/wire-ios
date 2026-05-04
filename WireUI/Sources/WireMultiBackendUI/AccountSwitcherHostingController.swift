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
import UIKit
import WireDesign

public class AccountSwitcherHostingController: UIHostingController<AccountSwitcherRootView> {

    public init(otherAccounts: [AccountUIModel], options: [Option]) {
        super.init(
            rootView: AccountSwitcherRootView(
                otherAccounts: otherAccounts,
                options: options
            )
        )
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public struct AccountSwitcherRootView: View {

    let otherAccounts: [AccountUIModel]
    let options: [Option]

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !otherAccounts.isEmpty {
                Text(L10n.Localizable.Accounts.header.uppercased())
                    .font(for: .h5)
                    .foregroundStyle(Color(SemanticColors.Label.baseSecondaryText))
                    .padding(.leading, 16)
            }
            switcherView()
        }
    }

    @ViewBuilder
    func switcherView() -> some View {
        AccountSwitcherView(
            otherAccounts: otherAccounts,
            options: options,
            showLastSeparator: false
        )
    }
}
