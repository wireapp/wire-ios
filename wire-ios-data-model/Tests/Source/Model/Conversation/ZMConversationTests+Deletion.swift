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

import XCTest

class ZMConversationTests_Deletion: ZMConversationTestsBase {
    func testThatCachedAssetsAreDeleted_WhenConversationIsDeleted() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let fileMetadata = createFileMetadata()
        let message = try! sut.appendFile(with: fileMetadata)
        let cacheKey = FileAssetCache.cacheKeyForAsset(message)!
        uiMOC.zm_fileAssetCache.storeOriginalFile(data: .secureRandomData(ofLength: 100), for: message)
        XCTAssertNotNil(uiMOC.zm_fileAssetCache.assetData(cacheKey))

        // WHEN
        uiMOC.delete(sut)

        // THEN
        XCTAssertNil(uiMOC.zm_fileAssetCache.assetData(cacheKey))
    }
}
