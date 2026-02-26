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

import Foundation
import WireSyncEngine

extension ConversationListViewController {

    var isEmptyPlaceholderVisible: Bool {
        listContentController.listViewModel.isEmptyList
    }

    var emptyPlaceholderForSelectedFilter: EmptyPlaceholder {
        typealias Strings = L10n.Localizable.ConversationList.EmptyPlaceholder

        guard let selectedFilter = listContentController.listViewModel.selectedFilter else {
            return EmptyPlaceholder(
                headline: Strings.All.headline + " 👋",
                subheadline: Strings.All.subheadline.attributedString
            )
        }
        switch selectedFilter {
        case .favorites:
            let subheadline = Strings.Favorite.subheadline.attributedString
            let link = NSAttributedString(
                string: Strings.Favorite.link,
                attributes: [
                    .link: WireURLs.shared.howToAddConversationToYourFavourites
                ]
            )

            return EmptyPlaceholder(
                subheadline: subheadline + "\n\n" + link,
                showArrow: false
            )
        case .groups:
            return EmptyPlaceholder(subheadline: Strings.Group.subheadline.attributedString)
        case .channels:
            let subheadline = Strings.Channels.subheadline.attributedString
            let link = NSAttributedString(
                string: Strings.Channels.link,
                attributes: [
                    .link: WireURLs.shared.learnMoreAboutChannels
                ]
            )

            return EmptyPlaceholder(
                subheadline: subheadline + "\n\n" + link,
                showArrow: false
            )
        case .oneOnOne:
            let domain = listContentController.listViewModel.userSession.selfUser.domain ?? ""
            return EmptyPlaceholder(
                subheadline: Strings.Oneonone.subheadline(domain).attributedString,
                showArrow: !isIPadRegular(),
                showButton: isIPadRegular()
            )
        case .unread:
            return EmptyPlaceholder(
                headline: L10n.Localizable.ConversationList.EmptyState.Unread.title,
                subheadline: L10n.Localizable.ConversationList.EmptyState.UpToDate.subtitle.attributedString,
                showArrow: false
            )
        case .mentions:
            return EmptyPlaceholder(
                headline: L10n.Localizable.ConversationList.EmptyState.Mentions.title,
                subheadline: L10n.Localizable.ConversationList.EmptyState.UpToDate.subtitle.attributedString,
                showArrow: false
            )
        case .replies:
            return EmptyPlaceholder(
                headline: L10n.Localizable.ConversationList.EmptyState.Replies.title,
                subheadline: L10n.Localizable.ConversationList.EmptyState.UpToDate.subtitle.attributedString,
                showArrow: false
            )
        case .drafts:
            return EmptyPlaceholder(
                headline: L10n.Localizable.ConversationList.EmptyState.Drafts.title,
                subheadline: L10n.Localizable.ConversationList.EmptyState.UpToDate.subtitle.attributedString,
                showArrow: false
            )
        case .folder:
            // FIXME: [WPB-13905] Disallow this state
            return EmptyPlaceholder(subheadline: "".attributedString)
        }
    }

    struct EmptyPlaceholder {

        let headline: String
        let subheadline: NSAttributedString
        let showArrow: Bool
        let showButton: Bool

        init(
            headline: String? = nil,
            subheadline: NSAttributedString,
            showArrow: Bool = true,
            showButton: Bool = false
        ) {
            self.headline = headline ?? ""
            self.subheadline = subheadline
            self.showArrow = showArrow
            self.showButton = showButton
        }

    }

}
