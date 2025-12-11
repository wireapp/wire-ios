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

import Foundation
import Testing

@testable import WireMessagingData
@testable import WireMessagingDomain

struct WireCellsNodeCacheTests {

    @MainActor
    private let sut: WireCellsNodeCache

    @MainActor
    init() {
        sut = WireCellsNodeCache()
    }

    @Test @MainActor
    func settingAndGetting() async {
        // Given
        let nodeIDA = UUID()
        let nodeA = WireCellsNode.fixture(uuid: nodeIDA)
        let nodeIDB = UUID()

        // When
        sut.setItem(WireCellsNodeCacheItem(node: nodeA), for: nodeIDA)
        sut.setItem(WireCellsNodeCacheItem(node: nil), for: nodeIDB)

        // Then
        #expect(await sut.item(for: nodeIDA)?.node == nodeA)
        #expect(await sut.item(for: nodeIDB)?.node == nil)
    }

}
