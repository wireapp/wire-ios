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

import Combine
import Foundation
import WireFoundation
import WireMessagingDomain

@MainActor
final class FileVersionItemViewModel: ObservableObject {

    private let nodeID: UUID
    private let versionID: UUID
    private let onRestore: (FileVersionItem) async -> Void

    let item: FileVersionItem
    let accentColor: WireAccentColor

    init(
        nodeID: UUID,
        item: FileVersionItem,
        accentColor: WireAccentColor,
        onRestore: @escaping (FileVersionItem) async -> Void
    ) {
        self.nodeID = nodeID
        self.versionID = item.id
        self.item = item
        self.accentColor = accentColor
        self.onRestore = onRestore
    }

    func restore() async {
        await onRestore(item)
    }
}
