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

public import WireConversationsImplementation
public import WireConversationsAPI

import UIKit

public class MockChannelAccessUseCaseProtocol: ChannelAccessUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - settings

    public var settings: ChannelAccessSettings {
        get { return underlyingSettings }
        set(value) { underlyingSettings = value }
    }

    public var underlyingSettings: ChannelAccessSettings!

    // MARK: - updateAccessLevel

    public var updateAccessLevelTo_Invocations: [ChannelAccessLevel] = []
    public var updateAccessLevelTo_MockError: (any Error)?

    public func updateAccessLevel(to level: ChannelAccessLevel) async throws -> ChannelAccessSettings {
        updateAccessLevelTo_Invocations.append(level)

        if let error = updateAccessLevelTo_MockError {
            throw error
        }

        return underlyingSettings
    }

    // MARK: - updateParticipantPermission

    public var updateParticipantPermissionTo_Invocations: [ChannelAccessLevelPermission] = []
    public var updateParticipantPermissionTo_MockError: (any Error)?

    @Sendable
    public func updateParticipantPermission(to permission: ChannelAccessLevelPermission) async throws -> ChannelAccessSettings {
        updateParticipantPermissionTo_Invocations.append(permission)

        if let error = updateParticipantPermissionTo_MockError {
            throw error
        }

        return underlyingSettings
    }

}

public class MockChannelAccessRepositoryProtocol: ChannelAccessRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - updateAccessLevel

    public var updateAccessLevelTo_Invocations: [ChannelAccessLevel] = []
    public var updateAccessLevelTo_MockError: (any Error)?

    public func updateAccessLevel(to level: ChannelAccessLevel) async throws {
        updateAccessLevelTo_Invocations.append(level)

        if let error = updateAccessLevelTo_MockError {
            throw error
        }
    }

    // MARK: - updateParticipantPermission

    public var updateParticipantPermissionTo_Invocations: [ChannelAccessLevelPermission] = []
    public var updateParticipantPermissionTo_MockError: (any Error)?

    public func updateParticipantPermission(to permission: ChannelAccessLevelPermission) async throws {
        updateParticipantPermissionTo_Invocations.append(permission)

        if let error = updateParticipantPermissionTo_MockError {
            throw error
        }
    }

}
