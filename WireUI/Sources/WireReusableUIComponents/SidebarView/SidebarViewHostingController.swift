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

public final class SidebarViewHostingController: UIHostingController<SidebarView> {

    public weak var delegate: (any SidebarViewHostingControllerDelegate)?

    private var conversationFilter: SidebarConversationFilter? {
        didSet { delegate?.sidebarViewHostingController(self, didSelect: conversationFilter) }
    }

    public convenience init() {
        self.init(accountInfo: .init(), availability: .none, conversationFilter: .none)
    }

    public required init(
        accountInfo: SidebarAccountInfo?,
        availability: Availability?,
        conversationFilter: SidebarConversationFilter?
    ) {
        var self_: SidebarViewHostingController?
        let rootView = SidebarView(
            accountInfo: accountInfo,
            availability: availability,
            conversationFilter: .init(
                get: { self_?.conversationFilter ?? conversationFilter },
                set: { self_?.conversationFilter = $0 }
            )
        )
        super.init(rootView: rootView)
        self_ = self
    }

    @available(*, unavailable) @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
