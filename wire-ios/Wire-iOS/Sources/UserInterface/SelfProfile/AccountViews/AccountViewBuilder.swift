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

import WireDataModel

struct AccountViewBuilder {

    var account: Account
    var user: ZMUser?
    var displayContext: DisplayContext

    func build() -> BaseAccountView {

        // TODO: [WPB-7307] availability status must be shown on the avatar image (right-bottom)

        if let accountView = TeamAccountView(user: user, account: account, displayContext: displayContext) {
            accountView
        } else {
            PersonalAccountView(account: account, user: user, displayContext: displayContext)
        }
    }
}
