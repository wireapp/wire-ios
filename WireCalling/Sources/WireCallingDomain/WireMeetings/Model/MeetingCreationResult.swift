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

/// The result of creation. The link is returned by the server and is not stored locally.
public struct MeetingCreationResult: Equatable, Sendable {

    public let meeting: Meeting
    public let link: URL?

    public init(meeting: Meeting, link: URL?) {
        self.meeting = meeting
        self.link = link
    }

}

public enum MeetingType: Equatable, Sendable {

    case immediate
    case scheduled

}
