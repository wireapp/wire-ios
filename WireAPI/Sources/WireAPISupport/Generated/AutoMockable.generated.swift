// Generated using Sourcery 2.1.7 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// swiftlint:disable superfluous_disable_command
// swiftlint:disable vertical_whitespace
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import WireAPI






















public class MockTeamsAPI: TeamsAPI {

    // MARK: - Life cycle

    public init() {}


    // MARK: - getTeam

    public var getTeamFor_Invocations: [Team.ID] = []
    public var getTeamFor_MockError: Error?
    public var getTeamFor_MockMethod: ((Team.ID) async throws -> Team)?
    public var getTeamFor_MockValue: Team?

    public func getTeam(for teamID: Team.ID) async throws -> Team {
        getTeamFor_Invocations.append(teamID)

        if let error = getTeamFor_MockError {
            throw error
        }

        if let mock = getTeamFor_MockMethod {
            return try await mock(teamID)
        } else if let mock = getTeamFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `getTeamFor`")
        }
    }

    // MARK: - getTeamRoles

    public var getTeamRolesFor_Invocations: [Team.ID] = []
    public var getTeamRolesFor_MockError: Error?
    public var getTeamRolesFor_MockMethod: ((Team.ID) async throws -> [ConversationRole])?
    public var getTeamRolesFor_MockValue: [ConversationRole]?

    public func getTeamRoles(for teamID: Team.ID) async throws -> [ConversationRole] {
        getTeamRolesFor_Invocations.append(teamID)

        if let error = getTeamRolesFor_MockError {
            throw error
        }

        if let mock = getTeamRolesFor_MockMethod {
            return try await mock(teamID)
        } else if let mock = getTeamRolesFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `getTeamRolesFor`")
        }
    }

    // MARK: - getTeamMembers

    public var getTeamMembersForMaxResults_Invocations: [(teamID: Team.ID, maxResults: UInt)] = []
    public var getTeamMembersForMaxResults_MockError: Error?
    public var getTeamMembersForMaxResults_MockMethod: ((Team.ID, UInt) async throws -> [TeamMember])?
    public var getTeamMembersForMaxResults_MockValue: [TeamMember]?

    public func getTeamMembers(for teamID: Team.ID, maxResults: UInt) async throws -> [TeamMember] {
        getTeamMembersForMaxResults_Invocations.append((teamID: teamID, maxResults: maxResults))

        if let error = getTeamMembersForMaxResults_MockError {
            throw error
        }

        if let mock = getTeamMembersForMaxResults_MockMethod {
            return try await mock(teamID, maxResults)
        } else if let mock = getTeamMembersForMaxResults_MockValue {
            return mock
        } else {
            fatalError("no mock for `getTeamMembersForMaxResults`")
        }
    }

    // MARK: - getLegalholdStatus

    public var getLegalholdStatusForUserID_Invocations: [(teamID: Team.ID, userID: UUID)] = []
    public var getLegalholdStatusForUserID_MockError: Error?
    public var getLegalholdStatusForUserID_MockMethod: ((Team.ID, UUID) async throws -> LegalholdStatus)?
    public var getLegalholdStatusForUserID_MockValue: LegalholdStatus?

    public func getLegalholdStatus(for teamID: Team.ID, userID: UUID) async throws -> LegalholdStatus {
        getLegalholdStatusForUserID_Invocations.append((teamID: teamID, userID: userID))

        if let error = getLegalholdStatusForUserID_MockError {
            throw error
        }

        if let mock = getLegalholdStatusForUserID_MockMethod {
            return try await mock(teamID, userID)
        } else if let mock = getLegalholdStatusForUserID_MockValue {
            return mock
        } else {
            fatalError("no mock for `getLegalholdStatusForUserID`")
        }
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
