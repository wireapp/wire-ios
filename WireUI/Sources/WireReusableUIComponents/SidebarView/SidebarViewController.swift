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

public final class SidebarViewController: UIHostingController<SidebarViewAdapter> {

    public weak var delegate: (any SidebarViewControllerDelegate)?

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

    public convenience init() {
        self.init(accountInfo: .init(), availability: .none, conversationFilter: .none)
    }

    public required init(
        accountInfo: SidebarAccountInfo?,
        availability: Availability?,
        conversationFilter: SidebarConversationFilter?
    ) {
        var self_: SidebarViewController?
        super.init(
            rootView: SidebarViewAdapter(
                accountInfo: accountInfo,
                availability: availability,
                conversationFilter: conversationFilter,
                conversationFilterUpdated: { conversationFilter in
                    self_?.delegate?.sidebarViewController(self_!, didSelect: conversationFilter)
                }
            )
        )
        self_ = self
    }

    @available(*, unavailable) @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

// MARK: - SidebarViewAdapter

public struct SidebarViewAdapter: View {

    fileprivate var accountInfo: SidebarAccountInfo?
    fileprivate var availability: Availability?

    @State fileprivate(set) var conversationFilter: SidebarConversationFilter?
    fileprivate let conversationFilterUpdated: (_ conversationFilter: SidebarConversationFilter?) -> Void

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
