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

import Foundation

@MainActor
public protocol ChannelAccessUseCaseProtocol {
    var settings: ChannelAccessSettings { get }
    func updateAccessLevel(to level: ChannelAccessLevel) async throws -> ChannelAccessSettings
    func updateParticipantPermission(to permission: ChannelAccessLevelPermission) async throws -> ChannelAccessSettings
}

@MainActor
public protocol ChannelAccessRepositoryProtocol {
    func updateParticipantPermission(
        to permission: ChannelAccessLevelPermission
    ) async throws -> WireMessagingDomain.ChannelAccessLevelPermission
}

public enum ChannelAccessError: Error {
    case notAllowed
}

public class ChannelAccessUseCase: ChannelAccessUseCaseProtocol {

    public private(set) var settings: ChannelAccessSettings
    public let repository: any ChannelRepositoryProtocol

    public init(
        permission: ChannelAccessLevelPermission?,
        repository: any ChannelRepositoryProtocol
    ) {
        let settings = ChannelAccessSettings(
            // for MVP only private supported, uncomment for next phase
            // TODO: [WPB-16860] https://wearezeta.atlassian.net/browse/WPB-16860
            accessLevel: .private,
//            accessLevel: permission == nil ? .public : .private,
            participantPermission: permission ?? .everyone
        )
        self.settings = settings
        self.repository = repository
    }

    public func updateAccessLevel(to level: ChannelAccessLevel) async throws -> ChannelAccessSettings {
        guard settings.accessLevel == .public else {
            throw ChannelAccessError.notAllowed
        }
        let updatedPermission = try await repository.updateParticipantPermission(to: .everyone) // default value
        settings.accessLevel = level
        settings.participantPermission = updatedPermission
        return settings
    }

    public func updateParticipantPermission(
        to permission: ChannelAccessLevelPermission
    ) async throws -> ChannelAccessSettings {
        let updatedPermission = try await repository.updateParticipantPermission(to: permission)
        settings.participantPermission = updatedPermission
        return settings
    }
}
