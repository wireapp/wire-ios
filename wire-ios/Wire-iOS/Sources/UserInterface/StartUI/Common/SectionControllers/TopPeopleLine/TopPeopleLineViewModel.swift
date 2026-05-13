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

import UIKit
import WireDataModel

final class TopPeopleLineViewModel {

    struct Layout {
        let sectionInsets: UIEdgeInsets
        let itemSize: CGSize
        let minimumInteritemSpacing: CGFloat

        static let `default` = Layout(
            sectionInsets: UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0),
            itemSize: CGSize(width: 56, height: 78),
            minimumInteritemSpacing: 12
        )
    }

    enum Action {
        case selectConversation(ZMConversation)
    }

    private(set) var topPeople: [ZMConversation]
    let layout: Layout

    var numberOfItems: Int {
        topPeople.count
    }

    init(
        topPeople: [ZMConversation] = [],
        layout: Layout = .default
    ) {
        self.topPeople = topPeople
        self.layout = layout
    }

    func updateTopPeople(_ topPeople: [ZMConversation]) {
        self.topPeople = topPeople
    }

    func conversation(at indexPath: IndexPath) -> ZMConversation? {
        guard !topPeople.isEmpty else {
            return nil
        }

        return topPeople[indexPath.item % topPeople.count]
    }

    func actionForSelection(at indexPath: IndexPath) -> Action? {
        guard let conversation = conversation(at: indexPath) else {
            return nil
        }

        return .selectConversation(conversation)
    }
}
