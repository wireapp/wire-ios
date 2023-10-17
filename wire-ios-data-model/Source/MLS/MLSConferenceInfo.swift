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

public struct MLSConferenceInfo: Equatable {

    public struct Member: Equatable {

        public let id: MLSClientID
        public let isInSubconversation: Bool

        public init(
            id: MLSClientID,
            isInSubconversation: Bool
        ) {
            self.id = id
            self.isInSubconversation = isInSubconversation
        }

        public static func random() -> Member {
            return Member(
                id: .random(),
                isInSubconversation: .random()
            )
        }

    }

    public let epoch: UInt64
    public let keyData: Data
    public let members: [Member]

    public init(
        epoch: UInt64,
        keyData: Data,
        members: [Member]
    ) {
        self.epoch = epoch
        self.keyData = keyData
        self.members = members
    }
}

public extension MLSConferenceInfo {

    static func random() -> Self {
        return MLSConferenceInfo(
            epoch: .random(in: (.min)...(.max)),
            keyData: Data.random(byteCount: 8),
            members: [.random()])
    }

}
