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

// TODO: remove

import SwiftUI

public final class SidebarViewController<AccountImageView: View>: UIHostingController<SidebarViewAdapter<AccountImageView>> {

    public weak var delegate: (any SidebarViewControllerDelegate)?

    public var accountInfo: SidebarAccountInfo? {
        get { rootView.accountInfo }
        set { rootView.accountInfo = newValue }
    }

    public var conversationFilter: SidebarConversationFilter? {
        get { rootView.conversationFilter }
        set { rootView.conversationFilter = newValue }
    }

    public convenience init() {
        self.init(accountInfo: .init(), conversationFilter: .none)
    }

    public required init(
        accountInfo: SidebarAccountInfo?,
        conversationFilter: SidebarConversationFilter?
    ) {
        var self_: SidebarViewController?
        super.init(
            rootView: SidebarViewAdapter(
                accountInfo: accountInfo,
                conversationFilter: conversationFilter,
                conversationFilterUpdated: { conversationFilter in
                   // self_?.delegate?.sidebarViewController(self_!, didSelect: conversationFilter)
                },
                accountImageView: { _, _ in fatalError() }
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

public struct SidebarViewAdapter<AccountImageView>: View where AccountImageView: View {

    fileprivate var accountInfo: SidebarAccountInfo?

    @State fileprivate(set) var conversationFilter: SidebarConversationFilter?
    fileprivate let conversationFilterUpdated: (_ conversationFilter: SidebarConversationFilter?) -> Void
    private(set) var accountImageView: (
        _ accountImage: UIImage,
        _ availability: SidebarAccountInfo.Availability?
    ) -> AccountImageView

    public var body: some View {
        SidebarView(
            accountInfo: accountInfo,
            conversationFilter: $conversationFilter,
            accountImageView: accountImageView
        )
        .onReceive(conversationFilter.publisher) { conversationFilter in
            conversationFilterUpdated(conversationFilter)
        }
    }
}
