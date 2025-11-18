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

@available(iOS 17.0, *)
struct SidebarPreview: View {

    private let primarySplitColumnWidth: CGFloat = 260
    private let supplementarySplitColumnWidth: CGFloat = 280

    @State private var accountInfo = SidebarAccountInfo(
        displayName: "Firstname Lastname",
        username: "@username",
        accountImageSource: .image(.from(solidColor: .brown)),
        availability: .away,
        isE2EICertified: true,
        isVerified: true,
        isLegalHoldEnabled: true,
        showNotificationsBadge: true
    )
    @State private var selectedMenuItem: SidebarSelectableMenuItem = .all

    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn,
            sidebar: {
                SidebarView(
                    accountInfo: accountInfo,
                    selectedMenuItem: $selectedMenuItem,
                    showUnreadFilters: false,
                    showMeetings: false,
                    showFiles: false,
                    accountImageAction: {},
                    foldersAction: { _ in },
                    supportAction: {},
                    accountImageView: { _, _, _ in MockAccountImageView() },
                    legalHoldIndicatorView: { MockLegalHoldIndicatorView() }
                )
                .navigationSplitViewColumnWidth(primarySplitColumnWidth)
            }, content: {
                Text("\(selectedMenuItem)")
                    .navigationSplitViewColumnWidth(supplementarySplitColumnWidth)
            }, detail: {
                Text("Conversation Content")
            }
        )
    }
}

private struct MockAccountImageView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(Color.brown)
            Circle()
                .frame(width: 14, height: 14)
                .foregroundStyle(Color.green)
        }
    }
}

private struct MockLegalHoldIndicatorView: View {
    var body: some View {
        Circle()
            .fill(.red)
    }
}
