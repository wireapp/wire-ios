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

package import Foundation
package import WireMessagingDomain

@MainActor
package final class WireCellsNodeCache: WireCellsNodeCacheProtocol {

    private var storage: [UUID: WireCellsNodeCacheItem] = [:]

    package init() {}

    package func setItem(_ value: WireCellsNodeCacheItem, for nodeID: UUID) {
        storage.updateValue(value, forKey: nodeID)
    }

    package func item(for nodeID: UUID) -> WireCellsNodeCacheItem? {
        storage[nodeID]
    }

}
