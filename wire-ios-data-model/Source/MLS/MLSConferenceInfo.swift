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

/// Represents the information about an MLS conference.

public struct MLSConferenceInfo: Equatable {
    // MARK: Lifecycle

    public init(
        epoch: UInt64,
        keyData: Data,
        members: [Member]
    ) {
        self.epoch = epoch
        self.keyData = keyData
        self.members = members
    }

    // MARK: Public

    public struct Member: Equatable {
        // MARK: Lifecycle

        public init(
            id: MLSClientID,
            isInSubconversation: Bool
        ) {
            self.id = id
            self.isInSubconversation = isInSubconversation
        }

        // MARK: Public

        public let id: MLSClientID
        public let isInSubconversation: Bool
    }

    public let epoch: UInt64
    public let keyData: Data
    public let members: [Member]
}
