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

public final class SidebarViewController: UIHostingController<SidebarAdapter> {

    public weak var delegate: (any SidebarViewControllerDelegate)?

    public convenience init() {
        self.init(accountInfo: .init(), availability: .none, conversationFilter: .none)
    }

    public required init(
        accountInfo: SidebarAccountInfo?,
        availability: Availability?,
        conversationFilter: SidebarConversationFilter?
    ) {
        var self_: SidebarViewController?
        let rootView = SidebarAdapter(
            accountInfo: accountInfo,
            availability: availability,
            initialConversationFilter: conversationFilter,
            conversationFilterUpdated: { conversationFilter in
                self_?.delegate?.sidebarViewController(self_!, didSelect: conversationFilter)
            }
        )
        super.init(rootView: rootView)
        self_ = self
    }

    @available(*, unavailable) @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

public struct SidebarAdapter: View {

    public var accountInfo: SidebarAccountInfo?
    public var availability: Availability?

    @State public fileprivate(set) var conversationFilter: SidebarConversationFilter?
    let conversationFilterUpdated: (_ conversationFilter: SidebarConversationFilter?) -> Void

    init(
        accountInfo: SidebarAccountInfo?,
        availability: Availability?,
        initialConversationFilter conversationFilter: SidebarConversationFilter?,
        conversationFilterUpdated: @escaping (_ conversationFilter: SidebarConversationFilter?) -> Void
    ) {
        self.accountInfo = accountInfo
        self.availability = availability
        self.conversationFilter = conversationFilter
        self.conversationFilterUpdated = conversationFilterUpdated
    }

    public var body: some View {
        SidebarView(
            accountInfo: accountInfo,
            availability: availability,
            conversationFilter: $conversationFilter
        )
        .onReceive(conversationFilter.publisher) { conversationFilter in
            conversationFilterUpdated(conversationFilter)
        }
    }
}
