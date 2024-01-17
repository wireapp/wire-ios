//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import XCTest
@testable import WireDataModel

final class SubconversationGroupIDRepositoryTests: XCTestCase {

    func test_StoreAndFetchGroupID() async throws {
        // Given
        let sut = SubconversationGroupIDRepository()
        let subconversationGroupID = MLSGroupID.random()
        let subconversationType = SubgroupType.conference
        let parentGroupID = MLSGroupID.random()

        let result = await sut.fetchSubconversationGroupID(
            forType: subconversationType,
            parentGroupID: parentGroupID
        )
        XCTAssertNil(result)

        // When
        await sut.storeSubconversationGroupID(
            subconversationGroupID,
            forType: subconversationType,
            parentGroupID: parentGroupID
        )

        // Then
        let fetchResult = await sut.fetchSubconversationGroupID(
            forType: subconversationType,
            parentGroupID: parentGroupID
        )
        XCTAssertEqual(
            fetchResult,
            subconversationGroupID
        )
    }

    func test_FindSubgroupTypeAndParentID() async {
        // GIVEN
        let sut = SubconversationGroupIDRepository()
        let parentGroupID = MLSGroupID.random()
        let subgroupID = MLSGroupID.random()

        let repositoryData: [MLSGroupID: [SubgroupType: MLSGroupID]] = [
            .random(): [.conference: .random()],
            .random(): [.conference: .random()],
            .random(): [.conference: .random()],
            parentGroupID: [.conference: subgroupID]
        ]

        await repositoryData.asyncForEach { parent in
            await parent.value.asyncForEach { subgroup in
                await sut.storeSubconversationGroupID(subgroup.value, forType: .conference, parentGroupID: parent.key)
            }
        }

        // WHEN
        let subgroupInfo = await sut.findSubgroupTypeAndParentID(for: subgroupID)

        // THEN
        XCTAssertNotNil(subgroupInfo)
        XCTAssertEqual(subgroupInfo?.parentID, parentGroupID)
    }

}
