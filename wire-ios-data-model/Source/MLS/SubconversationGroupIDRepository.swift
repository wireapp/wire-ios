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

// sourcery: AutoMockable
public protocol SubconversationGroupIDRepositoryInterface {

    func storeSubconversationGroupID(
        _ groupID: MLSGroupID?,
        forType type: SubgroupType,
        parentGroupID: MLSGroupID
    )

    func fetchSubconversationGroupID(
        forType type: SubgroupType,
        parentGroupID: MLSGroupID
    ) -> MLSGroupID?

}

public final class SubconversationGroupIDRepository: SubconversationGroupIDRepositoryInterface {

    // MARK: - Properties

    private var storage = [MLSGroupID: [SubgroupType: MLSGroupID]]()

    // MARK: - Life cycle

    public init() {

    }

    // MARK: - Store

    public func storeSubconversationGroupID(
        _ groupID: MLSGroupID?,
        forType type: SubgroupType,
        parentGroupID: MLSGroupID
    ) {
        storage[parentGroupID, default: [:]][type] = groupID
    }

    // MARK: - Fetch

    public func fetchSubconversationGroupID(
        forType type: SubgroupType,
        parentGroupID: MLSGroupID
    ) -> MLSGroupID? {
        return storage[parentGroupID]?[type]
    }

}
