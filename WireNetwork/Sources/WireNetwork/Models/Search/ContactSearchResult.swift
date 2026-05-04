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

public import Foundation

public struct ContactSearchResult: Equatable, Sendable {

    public let documents: [Contact]

    public init(documents: [Contact]) {
        self.documents = documents
    }

    public struct Contact: Equatable, Sendable {

        public let id: UUID?
        public let qualifiedID: QualifiedID?
        public let name: String
        public let handle: String?
        public let team: UUID?
        public let accentID: Int?
        public let type: UserType

        public init(
            id: UUID?,
            qualifiedID: QualifiedID?,
            name: String,
            handle: String?,
            team: UUID?,
            accentID: Int?,
            type: UserType
        ) {
            self.id = id
            self.qualifiedID = qualifiedID
            self.name = name
            self.handle = handle
            self.team = team
            self.accentID = accentID
            self.type = type
        }

    }

}
