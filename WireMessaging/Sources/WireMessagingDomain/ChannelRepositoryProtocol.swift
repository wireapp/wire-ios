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

@MainActor
public protocol ChannelRepositoryProtocol {
    func updateParticipantPermission(
        to permission: ChannelAccessLevelPermission
    ) async throws -> ChannelAccessLevelPermission

    /// Updates the history depth (one day, one week, 4 weeks, unlimited..) for a given channel.
    /// Past messages for a channel will be shown according to that value.
    ///
    /// - parameter historyDepth: The new history depth value.

    func updateHistoryDepth(
        _ historyDepth: String?
    ) async throws

    func isConferenceCallingFeatureEnabled() async throws -> Bool
}
