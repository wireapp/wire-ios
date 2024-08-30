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

public final class SidebarViewController: UIHostingController<SidebarView> {

    public var accountInfo: SidebarAccountInfo? {
        get { rootView.accountInfo }
        set { rootView.accountInfo = newValue }
    }

    public var availability: Availability? {
        get { rootView.availability }
        set { rootView.availability = newValue }
    }

    public var conversationFilter: SidebarConversationFilter? {
        get { rootView.conversationFilter }
        set { rootView.conversationFilter = newValue }
    }

    public required init(
        accountInfo: SidebarAccountInfo?,
        availability: Availability?,
        conversationFilter: SidebarConversationFilter?
    ) {
        let rootView = SidebarView(
            accountInfo: accountInfo,
            availability: availability,
            conversationFilter: conversationFilter
        )
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
