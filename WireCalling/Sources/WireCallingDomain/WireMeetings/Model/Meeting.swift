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

public import Foundation
public import SwiftUICore

/// Represents the meeting entity

public struct Meeting: Equatable, Sendable {

    public let id: UUID

    public let title: String

    public let start: Date

    public let end: Date

    public let isNew: Bool

    public let participants: [Participant]

    public init(
        id: UUID,
        title: String,
        start: Date,
        end: Date,
        isNew: Bool = false,
        participants: [Participant]
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.isNew = isNew
        self.participants = participants
    }

}

public struct Participant: Equatable, Sendable, Identifiable {
    public let id = UUID()
    public let initials: String
    public let color: Color = .blue

    public init(initials: String) {
        self.initials = initials
    }
}
