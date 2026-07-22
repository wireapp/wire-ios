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

// sourcery: AutoMockable
import WireMockable

@Mockable
/// Searches the user's team for members so they can be added as participants
/// to a meeting.
///
/// Backing implementations may serve results from local storage, the remote
/// backend, or both.
public protocol MeetingMemberRepositoryProtocol: Sendable {

    /// Returns team members matching the given query.
    ///
    /// - Parameter query: A search string matched against member name and
    ///   handle. An empty query returns the full available pool.
    /// - Returns: The matching team members.
    /// - Throws: An error if the underlying source (local store or remote
    ///   backend) fails to produce results.
    func search(query: String) async throws -> [MeetingMember]

}
