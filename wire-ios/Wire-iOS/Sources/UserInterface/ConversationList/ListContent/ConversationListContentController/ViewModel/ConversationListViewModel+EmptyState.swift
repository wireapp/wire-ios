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

import Foundation
import WireSyncEngine

extension ConversationListViewModel {

    var isEmptyPlaceholderVisible: Bool {
        let totalItems = sections.map { $0.items.count }.reduce(0, +)
        return totalItems == 0
    }

    var emptyPlaceholderForSelectedFilter: EmptyPlaceholder {
        typealias Strings = L10n.Localizable.ConversationList.EmptyPlaceholder

        guard let selectedFilter else {
            return EmptyPlaceholder(
                headline: Strings.All.headline + " 👋",
                subheadline: Strings.All.subheadline.attributedString)
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
                showArrow: false)
        case .groups:
            return EmptyPlaceholder(subheadline: Strings.Group.subheadline.attributedString)
        case .oneOnOne:
            let domain = userSession?.selfUser.domain ?? ""
            return EmptyPlaceholder(subheadline: Strings.Oneonone.subheadline(domain).attributedString)
        }
    }

    struct EmptyPlaceholder {

        let headline: String
        let subheadline: NSAttributedString
        let showArrow: Bool

        init(
            headline: String? = nil,
            subheadline: NSAttributedString,
            showArrow: Bool = true
        ) {
            self.headline = headline ?? ""
            self.subheadline = subheadline
            self.showArrow = showArrow
        }

    }

}


