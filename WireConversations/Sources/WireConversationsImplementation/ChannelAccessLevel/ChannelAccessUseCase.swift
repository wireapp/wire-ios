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

import Foundation
public import WireConversationsAPI

@MainActor
public protocol ChannelAccessUseCaseProtocol {
    var settings: ChannelAccessSettings { get }
    func updateAccessLevel(to level: ChannelAccessLevel) async throws
    func updateParticipantPermission(to permission: ChannelAccessLevelPermission) async throws
}

@MainActor
public protocol ChannelAccessRepositoryProtocol {
    func updateAccessLevel(to level: ChannelAccessLevel) async throws
    func updateParticipantPermission(to permission: ChannelAccessLevelPermission) async throws
}

public class ChannelAccessUseCase: ChannelAccessUseCaseProtocol {

    public var settings: ChannelAccessSettings
    public let repository: any ChannelAccessRepositoryProtocol

    public init(
        permission: ChannelAccessLevelPermission?,
        repository: any ChannelAccessRepositoryProtocol
    ) {
        let settings = ChannelAccessSettings(
            accessLevel: permission == nil ? .public : .private,
            participantPermission: permission
        )
        self.settings = settings
        self.repository = repository
    }

    public func updateAccessLevel(to level: ChannelAccessLevel) async throws {
        guard settings.accessLevel == .public else {
            return
        }
        try await repository.updateAccessLevel(to: level)
        settings.accessLevel = level
        settings.participantPermission = .adminsAndMembers
    }

    public func updateParticipantPermission(to permission: ChannelAccessLevelPermission) async throws {
        settings.participantPermission = permission
    }
}
