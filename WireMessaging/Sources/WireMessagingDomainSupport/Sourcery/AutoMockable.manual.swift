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

public import WireMessagingDomain

import UIKit

public class MockChannelHistoryUseCaseProtocol: ChannelHistoryUseCaseProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: updateHistoryDepth

    public var updateHistoryDepth_Invocations: [(WireMessagingDomain.ChannelHistoryOption, WireMessagingDomain.ChannelHistoryOption.Custom)] = []
    public var updateHistoryDepth_MockMethod: (((WireMessagingDomain.ChannelHistoryOption, WireMessagingDomain.ChannelHistoryOption.Custom)) async throws -> Void)?
    public var updateHistoryDepth_MockError: (any Error)?

    public func updateHistoryDepth(
        channelHistoryOption: WireMessagingDomain.ChannelHistoryOption,
        channelHistoryOptionCustom: WireMessagingDomain.ChannelHistoryOption.Custom
    ) async throws {
        updateHistoryDepth_Invocations.append((channelHistoryOption, channelHistoryOptionCustom))

        if let error = updateHistoryDepth_MockError {
            throw error
        }

        if let mock = updateHistoryDepth_MockMethod {
            try await mock((channelHistoryOption, channelHistoryOptionCustom))
        } else {
            fatalError("no mock for `updateHistoryDepth`")
        }
    }

    // MARK: - isEnterpriseUser

    public var isEnterpriseUser_Invocations: [Void] = []
    public var isEnterpriseUser_MockValue: Bool?
    public var isEnterpriseUser_MockError: (any Error)?

    public func isEnterpriseUser() async throws -> Bool {
        isEnterpriseUser_Invocations.append(())

        if let error = isEnterpriseUser_MockError {
            throw error
        }

        if let mock = isEnterpriseUser_MockValue {
            return mock
        } else {
            fatalError("no mock for `isEnterpriseUser`")
        }
    }

}

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

public class MockChannelRepositoryProtocol: ChannelRepositoryProtocol {

    // MARK: - Life cycle

    public init() {}

    // MARK: - updateParticipantPermission

    public var updateParticipantPermissionTo_Invocations: [ChannelAccessLevelPermission] = []
    public var updateParticipantPermissionTo_MockError: (any Error)?
    public var updateParticipantPermissionTo_MockValue: WireMessagingDomain.ChannelAccessLevelPermission?

    public func updateParticipantPermission(to permission: ChannelAccessLevelPermission) async throws -> WireMessagingDomain.ChannelAccessLevelPermission {
        updateParticipantPermissionTo_Invocations.append(permission)

        if let error = updateParticipantPermissionTo_MockError {
            throw error
        }

        if let mock = updateParticipantPermissionTo_MockValue {
            return mock
        } else {
            fatalError("no mock for `updateParticipantPermissionTo`")
        }
    }

    // MARK: - updateHistoryDepth

    public var updateHistoryDepth_Invocations: [Void] = []
    public var updateHistoryDepth_MockMethod: ((String?) async throws -> Void)?
    public var updateHistoryDepth_MockError: (any Error)?

    public func updateHistoryDepth(_ historyDepth: String?) async throws {
        updateHistoryDepth_Invocations.append(())

        if let error = updateParticipantPermissionTo_MockError {
            throw error
        }

        if let mock = updateHistoryDepth_MockMethod {
            try await mock(historyDepth)
        } else {
            fatalError("no mock for `updateHistoryDepth`")
        }
    }

    // MARK: - isConferenceCallingFeatureEnabled

    public var isConferenceCallingFeatureEnabled_Invocations: [Void] = []
    public var isConferenceCallingFeatureEnabled_MockValue: Bool?

    public func isConferenceCallingFeatureEnabled() async throws -> Bool {
        isConferenceCallingFeatureEnabled_Invocations.append(())

        if let mock = isConferenceCallingFeatureEnabled_MockValue {
            return mock
        } else {
            fatalError("no mock for `isConferenceCallingFeatureEnabled`")
        }
    }

}

package class MockLoadConversationMessagesUseCaseProtocol: LoadConversationMessagesUseCaseProtocol, @unchecked Sendable {

    // MARK: - Life cycle

    package init() { }

    // MARK: - loadMessages

    package var loadMessagesOffset_Invocations: [Int] = []
    package var loadMessagesOffset_MockMethod: ((Int) async -> [MessageModel])?
    package var loadMessagesOffset_MockValue: [MessageModel]?

    package func loadMessages(offset: Int) async -> [MessageModel] {
        loadMessagesOffset_Invocations.append(offset)

        if let mock = loadMessagesOffset_MockMethod {
            return await mock(offset)
        } else if let mock = loadMessagesOffset_MockValue {
            return mock
        } else {
            fatalError("no mock for `loadMessagesOffset`")
        }
    }

}

package class MockMonitorMessagesUseCaseProtocol: MonitorMessagesUseCaseProtocol {

    // MARK: - Life cycle

    package init() { }

    // MARK: - messagesUpdatesStream

    package var messagesUpdatesStream: AsyncStream<MessagesUpdate> {
        get { return underlyingMessagesUpdatesStream }
        set(value) { underlyingMessagesUpdatesStream = value }
    }

    package var underlyingMessagesUpdatesStream: AsyncStream<MessagesUpdate>!

}
