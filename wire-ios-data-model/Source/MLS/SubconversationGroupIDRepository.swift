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

// sourcery: AutoMockable
public protocol SubconversationGroupIDRepositoryInterface {

    /// Stores the group ID of a subconversation in relation to their type and parent group.
    ///
    /// - Parameters:
    ///   - groupID: The group ID of the subconversation
    ///   - type: The type of the subconversation
    ///   - parentGroupID: The group ID of the parent conversation

    func storeSubconversationGroupID(
        _ groupID: MLSGroupID?,
        forType type: SubgroupType,
        parentGroupID: MLSGroupID
    ) async

    /// Fetches the group ID of a subconversation of a given type, associated with a given parent group.
    ///
    /// - Parameters:
    ///   - type: The type of the subconversation
    ///   - parentGroupID: The group ID of the parent conversation
    /// - Returns: The group ID of the subconversation
    ///
    /// **Note:** This will return `nil` if the group ID hasn't previously been stored 
    /// by calling ``storeSubconversationGroupID(_:forType:parentGroupID:)``

    func fetchSubconversationGroupID(
        forType type: SubgroupType,
        parentGroupID: MLSGroupID
    ) async -> MLSGroupID?

    /// Finds the type and parent group ID of a subconversation
    ///
    /// - Parameter targetGroupID: The group ID of the subconversation
    /// - Returns: The type and parent group ID of the subconversation
    ///
    /// **Note:** This will return `nil` if the group ID hasn't previously been stored 
    /// by calling ``storeSubconversationGroupID(_:forType:parentGroupID:)``

    func findSubgroupTypeAndParentID(
        for targetGroupID: MLSGroupID
    ) async -> (parentID: MLSGroupID, type: SubgroupType)?
}

/// An actor responsible for storing and fetching subconversations group IDs.
/// It is used to keep track of which subconversation is associated with which conversation.

public final actor SubconversationGroupIDRepository: SubconversationGroupIDRepositoryInterface {

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

    // MARK: - Finding subgroup

    public func findSubgroupTypeAndParentID(
        for targetGroupID: MLSGroupID
    ) -> (parentID: MLSGroupID, type: SubgroupType)? {

        for (parentID, subgroupIDsByType) in storage {
            if let entry = subgroupIDsByType.first(where: { _, subgroupID in
                subgroupID == targetGroupID
            }) {
                return (parentID: parentID, type: entry.key)
            }
        }

        return nil
    }
}
