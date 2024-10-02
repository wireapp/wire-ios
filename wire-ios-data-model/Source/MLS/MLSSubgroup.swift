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

/// Contains metadata about a subgroup. Used when fetching information about subgroup from the backend.

public struct MLSSubgroup: Equatable {

    public let cipherSuite: Int
    public let epoch: Int
    public let epochTimestamp: Date?
    public let groupID: MLSGroupID
    public let members: [MLSClientID]
    public let parentQualifiedID: QualifiedID

    public init(
        cipherSuite: Int,
        epoch: Int,
        epochTimestamp: Date?,
        groupID: MLSGroupID,
        members: [MLSClientID],
        parentQualifiedID: QualifiedID
    ) {
        self.cipherSuite = cipherSuite
        self.epoch = epoch
        self.epochTimestamp = epochTimestamp
        self.groupID = groupID
        self.members = members
        self.parentQualifiedID = parentQualifiedID
    }

}
