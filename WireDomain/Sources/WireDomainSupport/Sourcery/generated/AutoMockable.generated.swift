// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
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

// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import WireAPI
import WireDataModel

@testable import WireDomain
























public class ConnectionsRepositoryProtocolMock: ConnectionsRepositoryProtocol {

    public init() {}



    //MARK: - pullConnections

    public var pullConnectionsVoidThrowableError: (any Error)?
    public var pullConnectionsVoidCallsCount = 0
    public var pullConnectionsVoidCalled: Bool {
        return pullConnectionsVoidCallsCount > 0
    }
    public var pullConnectionsVoidClosure: (() async throws -> Void)?

    public func pullConnections() async throws {
        pullConnectionsVoidCallsCount += 1
        if let error = pullConnectionsVoidThrowableError {
            throw error
        }
        try await pullConnectionsVoidClosure?()
    }

    //MARK: - updateConnection

    public var updateConnectionConnectionConnectionVoidThrowableError: (any Error)?
    public var updateConnectionConnectionConnectionVoidCallsCount = 0
    public var updateConnectionConnectionConnectionVoidCalled: Bool {
        return updateConnectionConnectionConnectionVoidCallsCount > 0
    }
    public var updateConnectionConnectionConnectionVoidReceivedConnection: (Connection)?
    public var updateConnectionConnectionConnectionVoidReceivedInvocations: [(Connection)] = []
    public var updateConnectionConnectionConnectionVoidClosure: ((Connection) async throws -> Void)?

    public func updateConnection(_ connection: Connection) async throws {
        updateConnectionConnectionConnectionVoidCallsCount += 1
        updateConnectionConnectionConnectionVoidReceivedConnection = connection
        updateConnectionConnectionConnectionVoidReceivedInvocations.append(connection)
        if let error = updateConnectionConnectionConnectionVoidThrowableError {
            throw error
        }
        try await updateConnectionConnectionConnectionVoidClosure?(connection)
    }


}
public class ConversationLabelsRepositoryProtocolMock: ConversationLabelsRepositoryProtocol {

    public init() {}



    //MARK: - pullConversationLabels

    public var pullConversationLabelsVoidThrowableError: (any Error)?
    public var pullConversationLabelsVoidCallsCount = 0
    public var pullConversationLabelsVoidCalled: Bool {
        return pullConversationLabelsVoidCallsCount > 0
    }
    public var pullConversationLabelsVoidClosure: (() async throws -> Void)?

    public func pullConversationLabels() async throws {
        pullConversationLabelsVoidCallsCount += 1
        if let error = pullConversationLabelsVoidThrowableError {
            throw error
        }
        try await pullConversationLabelsVoidClosure?()
    }

    //MARK: - updateConversationLabels

    public var updateConversationLabelsConversationLabelsConversationLabelVoidThrowableError: (any Error)?
    public var updateConversationLabelsConversationLabelsConversationLabelVoidCallsCount = 0
    public var updateConversationLabelsConversationLabelsConversationLabelVoidCalled: Bool {
        return updateConversationLabelsConversationLabelsConversationLabelVoidCallsCount > 0
    }
    public var updateConversationLabelsConversationLabelsConversationLabelVoidReceivedConversationLabels: ([ConversationLabel])?
    public var updateConversationLabelsConversationLabelsConversationLabelVoidReceivedInvocations: [([ConversationLabel])] = []
    public var updateConversationLabelsConversationLabelsConversationLabelVoidClosure: (([ConversationLabel]) async throws -> Void)?

    public func updateConversationLabels(_ conversationLabels: [ConversationLabel]) async throws {
        updateConversationLabelsConversationLabelsConversationLabelVoidCallsCount += 1
        updateConversationLabelsConversationLabelsConversationLabelVoidReceivedConversationLabels = conversationLabels
        updateConversationLabelsConversationLabelsConversationLabelVoidReceivedInvocations.append(conversationLabels)
        if let error = updateConversationLabelsConversationLabelsConversationLabelVoidThrowableError {
            throw error
        }
        try await updateConversationLabelsConversationLabelsConversationLabelVoidClosure?(conversationLabels)
    }


}
public class ConversationLocalStoreProtocolMock: ConversationLocalStoreProtocol {

    public init() {}



    //MARK: - storeConversation

    public var storeConversationConversationWireAPIConversationIsFederationEnabledBoolVoidCallsCount = 0
    public var storeConversationConversationWireAPIConversationIsFederationEnabledBoolVoidCalled: Bool {
        return storeConversationConversationWireAPIConversationIsFederationEnabledBoolVoidCallsCount > 0
    }
    public var storeConversationConversationWireAPIConversationIsFederationEnabledBoolVoidReceivedArguments: (conversation: WireAPI.Conversation, isFederationEnabled: Bool)?
    public var storeConversationConversationWireAPIConversationIsFederationEnabledBoolVoidReceivedInvocations: [(conversation: WireAPI.Conversation, isFederationEnabled: Bool)] = []
    public var storeConversationConversationWireAPIConversationIsFederationEnabledBoolVoidClosure: ((WireAPI.Conversation, Bool) async -> Void)?

    public func storeConversation(_ conversation: WireAPI.Conversation, isFederationEnabled: Bool) async {
        storeConversationConversationWireAPIConversationIsFederationEnabledBoolVoidCallsCount += 1
        storeConversationConversationWireAPIConversationIsFederationEnabledBoolVoidReceivedArguments = (conversation: conversation, isFederationEnabled: isFederationEnabled)
        storeConversationConversationWireAPIConversationIsFederationEnabledBoolVoidReceivedInvocations.append((conversation: conversation, isFederationEnabled: isFederationEnabled))
        await storeConversationConversationWireAPIConversationIsFederationEnabledBoolVoidClosure?(conversation, isFederationEnabled)
    }

    //MARK: - storeConversationNeedsBackendUpdate

    public var storeConversationNeedsBackendUpdateNeedsUpdateBoolQualifiedIdWireAPIQualifiedIDVoidCallsCount = 0
    public var storeConversationNeedsBackendUpdateNeedsUpdateBoolQualifiedIdWireAPIQualifiedIDVoidCalled: Bool {
        return storeConversationNeedsBackendUpdateNeedsUpdateBoolQualifiedIdWireAPIQualifiedIDVoidCallsCount > 0
    }
    public var storeConversationNeedsBackendUpdateNeedsUpdateBoolQualifiedIdWireAPIQualifiedIDVoidReceivedArguments: (needsUpdate: Bool, qualifiedId: WireAPI.QualifiedID)?
    public var storeConversationNeedsBackendUpdateNeedsUpdateBoolQualifiedIdWireAPIQualifiedIDVoidReceivedInvocations: [(needsUpdate: Bool, qualifiedId: WireAPI.QualifiedID)] = []
    public var storeConversationNeedsBackendUpdateNeedsUpdateBoolQualifiedIdWireAPIQualifiedIDVoidClosure: ((Bool, WireAPI.QualifiedID) async -> Void)?

    public func storeConversationNeedsBackendUpdate(_ needsUpdate: Bool, qualifiedId: WireAPI.QualifiedID) async {
        storeConversationNeedsBackendUpdateNeedsUpdateBoolQualifiedIdWireAPIQualifiedIDVoidCallsCount += 1
        storeConversationNeedsBackendUpdateNeedsUpdateBoolQualifiedIdWireAPIQualifiedIDVoidReceivedArguments = (needsUpdate: needsUpdate, qualifiedId: qualifiedId)
        storeConversationNeedsBackendUpdateNeedsUpdateBoolQualifiedIdWireAPIQualifiedIDVoidReceivedInvocations.append((needsUpdate: needsUpdate, qualifiedId: qualifiedId))
        await storeConversationNeedsBackendUpdateNeedsUpdateBoolQualifiedIdWireAPIQualifiedIDVoidClosure?(needsUpdate, qualifiedId)
    }

    //MARK: - storeFailedConversation

    public var storeFailedConversationWithQualifiedIdQualifiedIdWireAPIQualifiedIDVoidCallsCount = 0
    public var storeFailedConversationWithQualifiedIdQualifiedIdWireAPIQualifiedIDVoidCalled: Bool {
        return storeFailedConversationWithQualifiedIdQualifiedIdWireAPIQualifiedIDVoidCallsCount > 0
    }
    public var storeFailedConversationWithQualifiedIdQualifiedIdWireAPIQualifiedIDVoidReceivedQualifiedId: (WireAPI.QualifiedID)?
    public var storeFailedConversationWithQualifiedIdQualifiedIdWireAPIQualifiedIDVoidReceivedInvocations: [(WireAPI.QualifiedID)] = []
    public var storeFailedConversationWithQualifiedIdQualifiedIdWireAPIQualifiedIDVoidClosure: ((WireAPI.QualifiedID) async -> Void)?

    public func storeFailedConversation(withQualifiedId qualifiedId: WireAPI.QualifiedID) async {
        storeFailedConversationWithQualifiedIdQualifiedIdWireAPIQualifiedIDVoidCallsCount += 1
        storeFailedConversationWithQualifiedIdQualifiedIdWireAPIQualifiedIDVoidReceivedQualifiedId = qualifiedId
        storeFailedConversationWithQualifiedIdQualifiedIdWireAPIQualifiedIDVoidReceivedInvocations.append(qualifiedId)
        await storeFailedConversationWithQualifiedIdQualifiedIdWireAPIQualifiedIDVoidClosure?(qualifiedId)
    }

    //MARK: - fetchMLSConversation

    public var fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationCallsCount = 0
    public var fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationCalled: Bool {
        return fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationCallsCount > 0
    }
    public var fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationReceivedGroupID: (WireDataModel.MLSGroupID)?
    public var fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationReceivedInvocations: [(WireDataModel.MLSGroupID)] = []
    public var fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationReturnValue: ZMConversation?
    public var fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationClosure: ((WireDataModel.MLSGroupID) async -> ZMConversation?)?

    public func fetchMLSConversation(with groupID: WireDataModel.MLSGroupID) async -> ZMConversation? {
        fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationCallsCount += 1
        fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationReceivedGroupID = groupID
        fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationReceivedInvocations.append(groupID)
        if let fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationClosure = fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationClosure {
            return await fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationClosure(groupID)
        } else {
            return fetchMLSConversationWithGroupIDWireDataModelMLSGroupIDZMConversationReturnValue
        }
    }

    //MARK: - removeFromConversations

    public var removeFromConversationsUserZMUserRemovalDateDateVoidCallsCount = 0
    public var removeFromConversationsUserZMUserRemovalDateDateVoidCalled: Bool {
        return removeFromConversationsUserZMUserRemovalDateDateVoidCallsCount > 0
    }
    public var removeFromConversationsUserZMUserRemovalDateDateVoidReceivedArguments: (user: ZMUser, removalDate: Date)?
    public var removeFromConversationsUserZMUserRemovalDateDateVoidReceivedInvocations: [(user: ZMUser, removalDate: Date)] = []
    public var removeFromConversationsUserZMUserRemovalDateDateVoidClosure: ((ZMUser, Date) async -> Void)?

    public func removeFromConversations(user: ZMUser, removalDate: Date) async {
        removeFromConversationsUserZMUserRemovalDateDateVoidCallsCount += 1
        removeFromConversationsUserZMUserRemovalDateDateVoidReceivedArguments = (user: user, removalDate: removalDate)
        removeFromConversationsUserZMUserRemovalDateDateVoidReceivedInvocations.append((user: user, removalDate: removalDate))
        await removeFromConversationsUserZMUserRemovalDateDateVoidClosure?(user, removalDate)
    }


}
public class ConversationRepositoryProtocolMock: ConversationRepositoryProtocol {

    public init() {}



    //MARK: - pullConversations

    public var pullConversationsVoidThrowableError: (any Error)?
    public var pullConversationsVoidCallsCount = 0
    public var pullConversationsVoidCalled: Bool {
        return pullConversationsVoidCallsCount > 0
    }
    public var pullConversationsVoidClosure: (() async throws -> Void)?

    public func pullConversations() async throws {
        pullConversationsVoidCallsCount += 1
        if let error = pullConversationsVoidThrowableError {
            throw error
        }
        try await pullConversationsVoidClosure?()
    }

    //MARK: - pullMLSOneToOneConversation

    public var pullMLSOneToOneConversationUserIDStringDomainStringStringThrowableError: (any Error)?
    public var pullMLSOneToOneConversationUserIDStringDomainStringStringCallsCount = 0
    public var pullMLSOneToOneConversationUserIDStringDomainStringStringCalled: Bool {
        return pullMLSOneToOneConversationUserIDStringDomainStringStringCallsCount > 0
    }
    public var pullMLSOneToOneConversationUserIDStringDomainStringStringReceivedArguments: (userID: String, domain: String)?
    public var pullMLSOneToOneConversationUserIDStringDomainStringStringReceivedInvocations: [(userID: String, domain: String)] = []
    public var pullMLSOneToOneConversationUserIDStringDomainStringStringReturnValue: String!
    public var pullMLSOneToOneConversationUserIDStringDomainStringStringClosure: ((String, String) async throws -> String)?

    public func pullMLSOneToOneConversation(userID: String, domain: String) async throws -> String {
        pullMLSOneToOneConversationUserIDStringDomainStringStringCallsCount += 1
        pullMLSOneToOneConversationUserIDStringDomainStringStringReceivedArguments = (userID: userID, domain: domain)
        pullMLSOneToOneConversationUserIDStringDomainStringStringReceivedInvocations.append((userID: userID, domain: domain))
        if let error = pullMLSOneToOneConversationUserIDStringDomainStringStringThrowableError {
            throw error
        }
        if let pullMLSOneToOneConversationUserIDStringDomainStringStringClosure = pullMLSOneToOneConversationUserIDStringDomainStringStringClosure {
            return try await pullMLSOneToOneConversationUserIDStringDomainStringStringClosure(userID, domain)
        } else {
            return pullMLSOneToOneConversationUserIDStringDomainStringStringReturnValue
        }
    }

    //MARK: - fetchMLSConversation

    public var fetchMLSConversationWithGroupIDStringZMConversationCallsCount = 0
    public var fetchMLSConversationWithGroupIDStringZMConversationCalled: Bool {
        return fetchMLSConversationWithGroupIDStringZMConversationCallsCount > 0
    }
    public var fetchMLSConversationWithGroupIDStringZMConversationReceivedGroupID: (String)?
    public var fetchMLSConversationWithGroupIDStringZMConversationReceivedInvocations: [(String)] = []
    public var fetchMLSConversationWithGroupIDStringZMConversationReturnValue: ZMConversation?
    public var fetchMLSConversationWithGroupIDStringZMConversationClosure: ((String) async -> ZMConversation?)?

    public func fetchMLSConversation(with groupID: String) async -> ZMConversation? {
        fetchMLSConversationWithGroupIDStringZMConversationCallsCount += 1
        fetchMLSConversationWithGroupIDStringZMConversationReceivedGroupID = groupID
        fetchMLSConversationWithGroupIDStringZMConversationReceivedInvocations.append(groupID)
        if let fetchMLSConversationWithGroupIDStringZMConversationClosure = fetchMLSConversationWithGroupIDStringZMConversationClosure {
            return await fetchMLSConversationWithGroupIDStringZMConversationClosure(groupID)
        } else {
            return fetchMLSConversationWithGroupIDStringZMConversationReturnValue
        }
    }

    //MARK: - removeFromConversations

    public var removeFromConversationsUserZMUserRemovalDateDateVoidCallsCount = 0
    public var removeFromConversationsUserZMUserRemovalDateDateVoidCalled: Bool {
        return removeFromConversationsUserZMUserRemovalDateDateVoidCallsCount > 0
    }
    public var removeFromConversationsUserZMUserRemovalDateDateVoidReceivedArguments: (user: ZMUser, removalDate: Date)?
    public var removeFromConversationsUserZMUserRemovalDateDateVoidReceivedInvocations: [(user: ZMUser, removalDate: Date)] = []
    public var removeFromConversationsUserZMUserRemovalDateDateVoidClosure: ((ZMUser, Date) async -> Void)?

    public func removeFromConversations(user: ZMUser, removalDate: Date) async {
        removeFromConversationsUserZMUserRemovalDateDateVoidCallsCount += 1
        removeFromConversationsUserZMUserRemovalDateDateVoidReceivedArguments = (user: user, removalDate: removalDate)
        removeFromConversationsUserZMUserRemovalDateDateVoidReceivedInvocations.append((user: user, removalDate: removalDate))
        await removeFromConversationsUserZMUserRemovalDateDateVoidClosure?(user, removalDate)
    }


}
public class OneOnOneResolverProtocolMock: OneOnOneResolverProtocol {

    public init() {}



    //MARK: - invoke

    public var invokeVoidThrowableError: (any Error)?
    public var invokeVoidCallsCount = 0
    public var invokeVoidCalled: Bool {
        return invokeVoidCallsCount > 0
    }
    public var invokeVoidClosure: (() async throws -> Void)?

    public func invoke() async throws {
        invokeVoidCallsCount += 1
        if let error = invokeVoidThrowableError {
            throw error
        }
        try await invokeVoidClosure?()
    }


}
class ProteusMessageDecryptorProtocolMock: ProteusMessageDecryptorProtocol {




    //MARK: - decryptedEventData

    var decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventThrowableError: (any Error)?
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventCallsCount = 0
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventCalled: Bool {
        return decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventCallsCount > 0
    }
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventReceivedEventData: (ConversationProteusMessageAddEvent)?
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventReceivedInvocations: [(ConversationProteusMessageAddEvent)] = []
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventReturnValue: ConversationProteusMessageAddEvent!
    var decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventClosure: ((ConversationProteusMessageAddEvent) async throws -> ConversationProteusMessageAddEvent)?

    func decryptedEventData(from eventData: ConversationProteusMessageAddEvent) async throws -> ConversationProteusMessageAddEvent {
        decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventCallsCount += 1
        decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventReceivedEventData = eventData
        decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventReceivedInvocations.append(eventData)
        if let error = decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventThrowableError {
            throw error
        }
        if let decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventClosure = decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventClosure {
            return try await decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventClosure(eventData)
        } else {
            return decryptedEventDataFromEventDataConversationProteusMessageAddEventConversationProteusMessageAddEventReturnValue
        }
    }


}
public class SelfUserProviderProtocolMock: SelfUserProviderProtocol {

    public init() {}



    //MARK: - fetchSelfUser

    public var fetchSelfUserZMUserCallsCount = 0
    public var fetchSelfUserZMUserCalled: Bool {
        return fetchSelfUserZMUserCallsCount > 0
    }
    public var fetchSelfUserZMUserReturnValue: ZMUser!
    public var fetchSelfUserZMUserClosure: (() -> ZMUser)?

    public func fetchSelfUser() -> ZMUser {
        fetchSelfUserZMUserCallsCount += 1
        if let fetchSelfUserZMUserClosure = fetchSelfUserZMUserClosure {
            return fetchSelfUserZMUserClosure()
        } else {
            return fetchSelfUserZMUserReturnValue
        }
    }


}
public class TeamRepositoryProtocolMock: TeamRepositoryProtocol {

    public init() {}



    //MARK: - pullSelfTeam

    public var pullSelfTeamVoidThrowableError: (any Error)?
    public var pullSelfTeamVoidCallsCount = 0
    public var pullSelfTeamVoidCalled: Bool {
        return pullSelfTeamVoidCallsCount > 0
    }
    public var pullSelfTeamVoidClosure: (() async throws -> Void)?

    public func pullSelfTeam() async throws {
        pullSelfTeamVoidCallsCount += 1
        if let error = pullSelfTeamVoidThrowableError {
            throw error
        }
        try await pullSelfTeamVoidClosure?()
    }

    //MARK: - pullSelfTeamRoles

    public var pullSelfTeamRolesVoidThrowableError: (any Error)?
    public var pullSelfTeamRolesVoidCallsCount = 0
    public var pullSelfTeamRolesVoidCalled: Bool {
        return pullSelfTeamRolesVoidCallsCount > 0
    }
    public var pullSelfTeamRolesVoidClosure: (() async throws -> Void)?

    public func pullSelfTeamRoles() async throws {
        pullSelfTeamRolesVoidCallsCount += 1
        if let error = pullSelfTeamRolesVoidThrowableError {
            throw error
        }
        try await pullSelfTeamRolesVoidClosure?()
    }

    //MARK: - pullSelfTeamMembers

    public var pullSelfTeamMembersVoidThrowableError: (any Error)?
    public var pullSelfTeamMembersVoidCallsCount = 0
    public var pullSelfTeamMembersVoidCalled: Bool {
        return pullSelfTeamMembersVoidCallsCount > 0
    }
    public var pullSelfTeamMembersVoidClosure: (() async throws -> Void)?

    public func pullSelfTeamMembers() async throws {
        pullSelfTeamMembersVoidCallsCount += 1
        if let error = pullSelfTeamMembersVoidThrowableError {
            throw error
        }
        try await pullSelfTeamMembersVoidClosure?()
    }

    //MARK: - fetchSelfLegalholdStatus

    public var fetchSelfLegalholdStatusLegalholdStatusThrowableError: (any Error)?
    public var fetchSelfLegalholdStatusLegalholdStatusCallsCount = 0
    public var fetchSelfLegalholdStatusLegalholdStatusCalled: Bool {
        return fetchSelfLegalholdStatusLegalholdStatusCallsCount > 0
    }
    public var fetchSelfLegalholdStatusLegalholdStatusReturnValue: LegalholdStatus!
    public var fetchSelfLegalholdStatusLegalholdStatusClosure: (() async throws -> LegalholdStatus)?

    public func fetchSelfLegalholdStatus() async throws -> LegalholdStatus {
        fetchSelfLegalholdStatusLegalholdStatusCallsCount += 1
        if let error = fetchSelfLegalholdStatusLegalholdStatusThrowableError {
            throw error
        }
        if let fetchSelfLegalholdStatusLegalholdStatusClosure = fetchSelfLegalholdStatusLegalholdStatusClosure {
            return try await fetchSelfLegalholdStatusLegalholdStatusClosure()
        } else {
            return fetchSelfLegalholdStatusLegalholdStatusReturnValue
        }
    }

    //MARK: - deleteMembership

    public var deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidThrowableError: (any Error)?
    public var deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidCallsCount = 0
    public var deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidCalled: Bool {
        return deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidCallsCount > 0
    }
    public var deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidReceivedArguments: (userID: UUID, teamID: UUID, time: Date)?
    public var deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidReceivedInvocations: [(userID: UUID, teamID: UUID, time: Date)] = []
    public var deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidClosure: ((UUID, UUID, Date) async throws -> Void)?

    public func deleteMembership(forUser userID: UUID, fromTeam teamID: UUID, at time: Date) async throws {
        deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidCallsCount += 1
        deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidReceivedArguments = (userID: userID, teamID: teamID, time: time)
        deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidReceivedInvocations.append((userID: userID, teamID: teamID, time: time))
        if let error = deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidThrowableError {
            throw error
        }
        try await deleteMembershipForUserUserIDUUIDFromTeamTeamIDUUIDAtTimeDateVoidClosure?(userID, teamID, time)
    }

    //MARK: - storeTeamMemberNeedsBackendUpdate

    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidThrowableError: (any Error)?
    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidCallsCount = 0
    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidCalled: Bool {
        return storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidCallsCount > 0
    }
    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidReceivedMembershipID: (UUID)?
    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidReceivedInvocations: [(UUID)] = []
    public var storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidClosure: ((UUID) async throws -> Void)?

    public func storeTeamMemberNeedsBackendUpdate(membershipID: UUID) async throws {
        storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidCallsCount += 1
        storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidReceivedMembershipID = membershipID
        storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidReceivedInvocations.append(membershipID)
        if let error = storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidThrowableError {
            throw error
        }
        try await storeTeamMemberNeedsBackendUpdateMembershipIDUUIDVoidClosure?(membershipID)
    }


}
class UpdateEventDecryptorProtocolMock: UpdateEventDecryptorProtocol {




    //MARK: - decryptEvents

    var decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventThrowableError: (any Error)?
    var decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventCallsCount = 0
    var decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventCalled: Bool {
        return decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventCallsCount > 0
    }
    var decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventReceivedEventEnvelope: (UpdateEventEnvelope)?
    var decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventReceivedInvocations: [(UpdateEventEnvelope)] = []
    var decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventReturnValue: [UpdateEvent]!
    var decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventClosure: ((UpdateEventEnvelope) async throws -> [UpdateEvent])?

    func decryptEvents(in eventEnvelope: UpdateEventEnvelope) async throws -> [UpdateEvent] {
        decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventCallsCount += 1
        decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventReceivedEventEnvelope = eventEnvelope
        decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventReceivedInvocations.append(eventEnvelope)
        if let error = decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventThrowableError {
            throw error
        }
        if let decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventClosure = decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventClosure {
            return try await decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventClosure(eventEnvelope)
        } else {
            return decryptEventsInEventEnvelopeUpdateEventEnvelopeUpdateEventReturnValue
        }
    }


}
class UpdateEventProcessorProtocolMock: UpdateEventProcessorProtocol {




    //MARK: - processEvent

    var processEventEventUpdateEventVoidThrowableError: (any Error)?
    var processEventEventUpdateEventVoidCallsCount = 0
    var processEventEventUpdateEventVoidCalled: Bool {
        return processEventEventUpdateEventVoidCallsCount > 0
    }
    var processEventEventUpdateEventVoidReceivedEvent: (UpdateEvent)?
    var processEventEventUpdateEventVoidReceivedInvocations: [(UpdateEvent)] = []
    var processEventEventUpdateEventVoidClosure: ((UpdateEvent) async throws -> Void)?

    func processEvent(_ event: UpdateEvent) async throws {
        processEventEventUpdateEventVoidCallsCount += 1
        processEventEventUpdateEventVoidReceivedEvent = event
        processEventEventUpdateEventVoidReceivedInvocations.append(event)
        if let error = processEventEventUpdateEventVoidThrowableError {
            throw error
        }
        try await processEventEventUpdateEventVoidClosure?(event)
    }


}
class UpdateEventsRepositoryProtocolMock: UpdateEventsRepositoryProtocol {




    //MARK: - pullPendingEvents

    var pullPendingEventsVoidThrowableError: (any Error)?
    var pullPendingEventsVoidCallsCount = 0
    var pullPendingEventsVoidCalled: Bool {
        return pullPendingEventsVoidCallsCount > 0
    }
    var pullPendingEventsVoidClosure: (() async throws -> Void)?

    func pullPendingEvents() async throws {
        pullPendingEventsVoidCallsCount += 1
        if let error = pullPendingEventsVoidThrowableError {
            throw error
        }
        try await pullPendingEventsVoidClosure?()
    }

    //MARK: - fetchNextPendingEvents

    var fetchNextPendingEventsLimitUIntUpdateEventEnvelopeThrowableError: (any Error)?
    var fetchNextPendingEventsLimitUIntUpdateEventEnvelopeCallsCount = 0
    var fetchNextPendingEventsLimitUIntUpdateEventEnvelopeCalled: Bool {
        return fetchNextPendingEventsLimitUIntUpdateEventEnvelopeCallsCount > 0
    }
    var fetchNextPendingEventsLimitUIntUpdateEventEnvelopeReceivedLimit: (UInt)?
    var fetchNextPendingEventsLimitUIntUpdateEventEnvelopeReceivedInvocations: [(UInt)] = []
    var fetchNextPendingEventsLimitUIntUpdateEventEnvelopeReturnValue: [UpdateEventEnvelope]!
    var fetchNextPendingEventsLimitUIntUpdateEventEnvelopeClosure: ((UInt) async throws -> [UpdateEventEnvelope])?

    func fetchNextPendingEvents(limit: UInt) async throws -> [UpdateEventEnvelope] {
        fetchNextPendingEventsLimitUIntUpdateEventEnvelopeCallsCount += 1
        fetchNextPendingEventsLimitUIntUpdateEventEnvelopeReceivedLimit = limit
        fetchNextPendingEventsLimitUIntUpdateEventEnvelopeReceivedInvocations.append(limit)
        if let error = fetchNextPendingEventsLimitUIntUpdateEventEnvelopeThrowableError {
            throw error
        }
        if let fetchNextPendingEventsLimitUIntUpdateEventEnvelopeClosure = fetchNextPendingEventsLimitUIntUpdateEventEnvelopeClosure {
            return try await fetchNextPendingEventsLimitUIntUpdateEventEnvelopeClosure(limit)
        } else {
            return fetchNextPendingEventsLimitUIntUpdateEventEnvelopeReturnValue
        }
    }

    //MARK: - deleteNextPendingEvents

    var deleteNextPendingEventsLimitUIntVoidThrowableError: (any Error)?
    var deleteNextPendingEventsLimitUIntVoidCallsCount = 0
    var deleteNextPendingEventsLimitUIntVoidCalled: Bool {
        return deleteNextPendingEventsLimitUIntVoidCallsCount > 0
    }
    var deleteNextPendingEventsLimitUIntVoidReceivedLimit: (UInt)?
    var deleteNextPendingEventsLimitUIntVoidReceivedInvocations: [(UInt)] = []
    var deleteNextPendingEventsLimitUIntVoidClosure: ((UInt) async throws -> Void)?

    func deleteNextPendingEvents(limit: UInt) async throws {
        deleteNextPendingEventsLimitUIntVoidCallsCount += 1
        deleteNextPendingEventsLimitUIntVoidReceivedLimit = limit
        deleteNextPendingEventsLimitUIntVoidReceivedInvocations.append(limit)
        if let error = deleteNextPendingEventsLimitUIntVoidThrowableError {
            throw error
        }
        try await deleteNextPendingEventsLimitUIntVoidClosure?(limit)
    }

    //MARK: - startBufferingLiveEvents

    var startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorThrowableError: (any Error)?
    var startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorCallsCount = 0
    var startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorCalled: Bool {
        return startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorCallsCount > 0
    }
    var startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorReturnValue: AsyncThrowingStream<UpdateEventEnvelope, Error>!
    var startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorClosure: (() async throws -> AsyncThrowingStream<UpdateEventEnvelope, Error>)?

    func startBufferingLiveEvents() async throws -> AsyncThrowingStream<UpdateEventEnvelope, Error> {
        startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorCallsCount += 1
        if let error = startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorThrowableError {
            throw error
        }
        if let startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorClosure = startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorClosure {
            return try await startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorClosure()
        } else {
            return startBufferingLiveEventsAsyncThrowingStreamUpdateEventEnvelopeErrorReturnValue
        }
    }

    //MARK: - stopReceivingLiveEvents

    var stopReceivingLiveEventsVoidCallsCount = 0
    var stopReceivingLiveEventsVoidCalled: Bool {
        return stopReceivingLiveEventsVoidCallsCount > 0
    }
    var stopReceivingLiveEventsVoidClosure: (() async -> Void)?

    func stopReceivingLiveEvents() async {
        stopReceivingLiveEventsVoidCallsCount += 1
        await stopReceivingLiveEventsVoidClosure?()
    }

    //MARK: - storeLastEventEnvelopeID

    var storeLastEventEnvelopeIDIdUUIDVoidCallsCount = 0
    var storeLastEventEnvelopeIDIdUUIDVoidCalled: Bool {
        return storeLastEventEnvelopeIDIdUUIDVoidCallsCount > 0
    }
    var storeLastEventEnvelopeIDIdUUIDVoidReceivedId: (UUID)?
    var storeLastEventEnvelopeIDIdUUIDVoidReceivedInvocations: [(UUID)] = []
    var storeLastEventEnvelopeIDIdUUIDVoidClosure: ((UUID) -> Void)?

    func storeLastEventEnvelopeID(_ id: UUID) {
        storeLastEventEnvelopeIDIdUUIDVoidCallsCount += 1
        storeLastEventEnvelopeIDIdUUIDVoidReceivedId = id
        storeLastEventEnvelopeIDIdUUIDVoidReceivedInvocations.append(id)
        storeLastEventEnvelopeIDIdUUIDVoidClosure?(id)
    }

    //MARK: - pullLastEventID

    var pullLastEventIDVoidThrowableError: (any Error)?
    var pullLastEventIDVoidCallsCount = 0
    var pullLastEventIDVoidCalled: Bool {
        return pullLastEventIDVoidCallsCount > 0
    }
    var pullLastEventIDVoidClosure: (() async throws -> Void)?

    func pullLastEventID() async throws {
        pullLastEventIDVoidCallsCount += 1
        if let error = pullLastEventIDVoidThrowableError {
            throw error
        }
        try await pullLastEventIDVoidClosure?()
    }


}
public class UserRepositoryProtocolMock: UserRepositoryProtocol {

    public init() {}



    //MARK: - fetchSelfUser

    public var fetchSelfUserZMUserCallsCount = 0
    public var fetchSelfUserZMUserCalled: Bool {
        return fetchSelfUserZMUserCallsCount > 0
    }
    public var fetchSelfUserZMUserReturnValue: ZMUser!
    public var fetchSelfUserZMUserClosure: (() -> ZMUser)?

    public func fetchSelfUser() -> ZMUser {
        fetchSelfUserZMUserCallsCount += 1
        if let fetchSelfUserZMUserClosure = fetchSelfUserZMUserClosure {
            return fetchSelfUserZMUserClosure()
        } else {
            return fetchSelfUserZMUserReturnValue
        }
    }

    //MARK: - fetchUser

    public var fetchUserWithIdUUIDDomainStringZMUserThrowableError: (any Error)?
    public var fetchUserWithIdUUIDDomainStringZMUserCallsCount = 0
    public var fetchUserWithIdUUIDDomainStringZMUserCalled: Bool {
        return fetchUserWithIdUUIDDomainStringZMUserCallsCount > 0
    }
    public var fetchUserWithIdUUIDDomainStringZMUserReceivedArguments: (id: UUID, domain: String?)?
    public var fetchUserWithIdUUIDDomainStringZMUserReceivedInvocations: [(id: UUID, domain: String?)] = []
    public var fetchUserWithIdUUIDDomainStringZMUserReturnValue: ZMUser!
    public var fetchUserWithIdUUIDDomainStringZMUserClosure: ((UUID, String?) async throws -> ZMUser)?

    public func fetchUser(with id: UUID, domain: String?) async throws -> ZMUser {
        fetchUserWithIdUUIDDomainStringZMUserCallsCount += 1
        fetchUserWithIdUUIDDomainStringZMUserReceivedArguments = (id: id, domain: domain)
        fetchUserWithIdUUIDDomainStringZMUserReceivedInvocations.append((id: id, domain: domain))
        if let error = fetchUserWithIdUUIDDomainStringZMUserThrowableError {
            throw error
        }
        if let fetchUserWithIdUUIDDomainStringZMUserClosure = fetchUserWithIdUUIDDomainStringZMUserClosure {
            return try await fetchUserWithIdUUIDDomainStringZMUserClosure(id, domain)
        } else {
            return fetchUserWithIdUUIDDomainStringZMUserReturnValue
        }
    }

    //MARK: - pushSelfSupportedProtocols

    public var pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidThrowableError: (any Error)?
    public var pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidCallsCount = 0
    public var pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidCalled: Bool {
        return pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidCallsCount > 0
    }
    public var pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidReceivedSupportedProtocols: (Set<WireAPI.MessageProtocol>)?
    public var pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidReceivedInvocations: [(Set<WireAPI.MessageProtocol>)] = []
    public var pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidClosure: ((Set<WireAPI.MessageProtocol>) async throws -> Void)?

    public func pushSelfSupportedProtocols(_ supportedProtocols: Set<WireAPI.MessageProtocol>) async throws {
        pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidCallsCount += 1
        pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidReceivedSupportedProtocols = supportedProtocols
        pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidReceivedInvocations.append(supportedProtocols)
        if let error = pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidThrowableError {
            throw error
        }
        try await pushSelfSupportedProtocolsSupportedProtocolsSetWireAPIMessageProtocolVoidClosure?(supportedProtocols)
    }

    //MARK: - pullKnownUsers

    public var pullKnownUsersVoidThrowableError: (any Error)?
    public var pullKnownUsersVoidCallsCount = 0
    public var pullKnownUsersVoidCalled: Bool {
        return pullKnownUsersVoidCallsCount > 0
    }
    public var pullKnownUsersVoidClosure: (() async throws -> Void)?

    public func pullKnownUsers() async throws {
        pullKnownUsersVoidCallsCount += 1
        if let error = pullKnownUsersVoidThrowableError {
            throw error
        }
        try await pullKnownUsersVoidClosure?()
    }

    //MARK: - pullUsers

    public var pullUsersUserIDsWireDataModelQualifiedIDVoidThrowableError: (any Error)?
    public var pullUsersUserIDsWireDataModelQualifiedIDVoidCallsCount = 0
    public var pullUsersUserIDsWireDataModelQualifiedIDVoidCalled: Bool {
        return pullUsersUserIDsWireDataModelQualifiedIDVoidCallsCount > 0
    }
    public var pullUsersUserIDsWireDataModelQualifiedIDVoidReceivedUserIDs: ([WireDataModel.QualifiedID])?
    public var pullUsersUserIDsWireDataModelQualifiedIDVoidReceivedInvocations: [([WireDataModel.QualifiedID])] = []
    public var pullUsersUserIDsWireDataModelQualifiedIDVoidClosure: (([WireDataModel.QualifiedID]) async throws -> Void)?

    public func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws {
        pullUsersUserIDsWireDataModelQualifiedIDVoidCallsCount += 1
        pullUsersUserIDsWireDataModelQualifiedIDVoidReceivedUserIDs = userIDs
        pullUsersUserIDsWireDataModelQualifiedIDVoidReceivedInvocations.append(userIDs)
        if let error = pullUsersUserIDsWireDataModelQualifiedIDVoidThrowableError {
            throw error
        }
        try await pullUsersUserIDsWireDataModelQualifiedIDVoidClosure?(userIDs)
    }

    //MARK: - updateUser

    public var updateUserFromEventUserUpdateEventVoidCallsCount = 0
    public var updateUserFromEventUserUpdateEventVoidCalled: Bool {
        return updateUserFromEventUserUpdateEventVoidCallsCount > 0
    }
    public var updateUserFromEventUserUpdateEventVoidReceivedEvent: (UserUpdateEvent)?
    public var updateUserFromEventUserUpdateEventVoidReceivedInvocations: [(UserUpdateEvent)] = []
    public var updateUserFromEventUserUpdateEventVoidClosure: ((UserUpdateEvent) async -> Void)?

    public func updateUser(from event: UserUpdateEvent) async {
        updateUserFromEventUserUpdateEventVoidCallsCount += 1
        updateUserFromEventUserUpdateEventVoidReceivedEvent = event
        updateUserFromEventUserUpdateEventVoidReceivedInvocations.append(event)
        await updateUserFromEventUserUpdateEventVoidClosure?(event)
    }

    //MARK: - fetchOrCreateUser

    public var fetchOrCreateUserWithUuidUUIDDomainStringZMUserCallsCount = 0
    public var fetchOrCreateUserWithUuidUUIDDomainStringZMUserCalled: Bool {
        return fetchOrCreateUserWithUuidUUIDDomainStringZMUserCallsCount > 0
    }
    public var fetchOrCreateUserWithUuidUUIDDomainStringZMUserReceivedArguments: (uuid: UUID, domain: String?)?
    public var fetchOrCreateUserWithUuidUUIDDomainStringZMUserReceivedInvocations: [(uuid: UUID, domain: String?)] = []
    public var fetchOrCreateUserWithUuidUUIDDomainStringZMUserReturnValue: ZMUser!
    public var fetchOrCreateUserWithUuidUUIDDomainStringZMUserClosure: ((UUID, String?) -> ZMUser)?

    public func fetchOrCreateUser(with uuid: UUID, domain: String?) -> ZMUser {
        fetchOrCreateUserWithUuidUUIDDomainStringZMUserCallsCount += 1
        fetchOrCreateUserWithUuidUUIDDomainStringZMUserReceivedArguments = (uuid: uuid, domain: domain)
        fetchOrCreateUserWithUuidUUIDDomainStringZMUserReceivedInvocations.append((uuid: uuid, domain: domain))
        if let fetchOrCreateUserWithUuidUUIDDomainStringZMUserClosure = fetchOrCreateUserWithUuidUUIDDomainStringZMUserClosure {
            return fetchOrCreateUserWithUuidUUIDDomainStringZMUserClosure(uuid, domain)
        } else {
            return fetchOrCreateUserWithUuidUUIDDomainStringZMUserReturnValue
        }
    }

    //MARK: - removePushToken

    public var removePushTokenVoidCallsCount = 0
    public var removePushTokenVoidCalled: Bool {
        return removePushTokenVoidCallsCount > 0
    }
    public var removePushTokenVoidClosure: (() -> Void)?

    public func removePushToken() {
        removePushTokenVoidCallsCount += 1
        removePushTokenVoidClosure?()
    }

    //MARK: - fetchOrCreateUserClient

    public var fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolThrowableError: (any Error)?
    public var fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolCallsCount = 0
    public var fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolCalled: Bool {
        return fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolCallsCount > 0
    }
    public var fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolReceivedId: (String)?
    public var fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolReceivedInvocations: [(String)] = []
    public var fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolReturnValue: (client: WireDataModel.UserClient, isNew: Bool)!
    public var fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolClosure: ((String) async throws -> (client: WireDataModel.UserClient, isNew: Bool))?

    public func fetchOrCreateUserClient(with id: String) async throws -> (client: WireDataModel.UserClient, isNew: Bool) {
        fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolCallsCount += 1
        fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolReceivedId = id
        fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolReceivedInvocations.append(id)
        if let error = fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolThrowableError {
            throw error
        }
        if let fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolClosure = fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolClosure {
            return try await fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolClosure(id)
        } else {
            return fetchOrCreateUserClientWithIdString_ClientWireDataModelUserClientIsNewBoolReturnValue
        }
    }

    //MARK: - updateUserClient

    public var updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidThrowableError: (any Error)?
    public var updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidCallsCount = 0
    public var updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidCalled: Bool {
        return updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidCallsCount > 0
    }
    public var updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidReceivedArguments: (localClient: WireDataModel.UserClient, remoteClient: WireAPI.UserClient, isNewClient: Bool)?
    public var updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidReceivedInvocations: [(localClient: WireDataModel.UserClient, remoteClient: WireAPI.UserClient, isNewClient: Bool)] = []
    public var updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidClosure: ((WireDataModel.UserClient, WireAPI.UserClient, Bool) async throws -> Void)?

    public func updateUserClient(_ localClient: WireDataModel.UserClient, from remoteClient: WireAPI.UserClient, isNewClient: Bool) async throws {
        updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidCallsCount += 1
        updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidReceivedArguments = (localClient: localClient, remoteClient: remoteClient, isNewClient: isNewClient)
        updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidReceivedInvocations.append((localClient: localClient, remoteClient: remoteClient, isNewClient: isNewClient))
        if let error = updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidThrowableError {
            throw error
        }
        try await updateUserClientLocalClientWireDataModelUserClientFromRemoteClientWireAPIUserClientIsNewClientBoolVoidClosure?(localClient, remoteClient, isNewClient)
    }

    //MARK: - addLegalHoldRequest

    public var addLegalHoldRequestForUserIDUUIDClientIDStringLastPrekeyPrekeyVoidCallsCount = 0
    public var addLegalHoldRequestForUserIDUUIDClientIDStringLastPrekeyPrekeyVoidCalled: Bool {
        return addLegalHoldRequestForUserIDUUIDClientIDStringLastPrekeyPrekeyVoidCallsCount > 0
    }
    public var addLegalHoldRequestForUserIDUUIDClientIDStringLastPrekeyPrekeyVoidReceivedArguments: (userID: UUID, clientID: String, lastPrekey: Prekey)?
    public var addLegalHoldRequestForUserIDUUIDClientIDStringLastPrekeyPrekeyVoidReceivedInvocations: [(userID: UUID, clientID: String, lastPrekey: Prekey)] = []
    public var addLegalHoldRequestForUserIDUUIDClientIDStringLastPrekeyPrekeyVoidClosure: ((UUID, String, Prekey) async -> Void)?

    public func addLegalHoldRequest(for userID: UUID, clientID: String, lastPrekey: Prekey) async {
        addLegalHoldRequestForUserIDUUIDClientIDStringLastPrekeyPrekeyVoidCallsCount += 1
        addLegalHoldRequestForUserIDUUIDClientIDStringLastPrekeyPrekeyVoidReceivedArguments = (userID: userID, clientID: clientID, lastPrekey: lastPrekey)
        addLegalHoldRequestForUserIDUUIDClientIDStringLastPrekeyPrekeyVoidReceivedInvocations.append((userID: userID, clientID: clientID, lastPrekey: lastPrekey))
        await addLegalHoldRequestForUserIDUUIDClientIDStringLastPrekeyPrekeyVoidClosure?(userID, clientID, lastPrekey)
    }

    //MARK: - disableUserLegalHold

    public var disableUserLegalHoldVoidThrowableError: (any Error)?
    public var disableUserLegalHoldVoidCallsCount = 0
    public var disableUserLegalHoldVoidCalled: Bool {
        return disableUserLegalHoldVoidCallsCount > 0
    }
    public var disableUserLegalHoldVoidClosure: (() async throws -> Void)?

    public func disableUserLegalHold() async throws {
        disableUserLegalHoldVoidCallsCount += 1
        if let error = disableUserLegalHoldVoidThrowableError {
            throw error
        }
        try await disableUserLegalHoldVoidClosure?()
    }

    //MARK: - updateUserProperty

    public var updateUserPropertyUserPropertyWireAPIUserPropertyVoidThrowableError: (any Error)?
    public var updateUserPropertyUserPropertyWireAPIUserPropertyVoidCallsCount = 0
    public var updateUserPropertyUserPropertyWireAPIUserPropertyVoidCalled: Bool {
        return updateUserPropertyUserPropertyWireAPIUserPropertyVoidCallsCount > 0
    }
    public var updateUserPropertyUserPropertyWireAPIUserPropertyVoidReceivedUserProperty: (WireAPI.UserProperty)?
    public var updateUserPropertyUserPropertyWireAPIUserPropertyVoidReceivedInvocations: [(WireAPI.UserProperty)] = []
    public var updateUserPropertyUserPropertyWireAPIUserPropertyVoidClosure: ((WireAPI.UserProperty) async throws -> Void)?

    public func updateUserProperty(_ userProperty: WireAPI.UserProperty) async throws {
        updateUserPropertyUserPropertyWireAPIUserPropertyVoidCallsCount += 1
        updateUserPropertyUserPropertyWireAPIUserPropertyVoidReceivedUserProperty = userProperty
        updateUserPropertyUserPropertyWireAPIUserPropertyVoidReceivedInvocations.append(userProperty)
        if let error = updateUserPropertyUserPropertyWireAPIUserPropertyVoidThrowableError {
            throw error
        }
        try await updateUserPropertyUserPropertyWireAPIUserPropertyVoidClosure?(userProperty)
    }

    //MARK: - deleteUserProperty

    public var deleteUserPropertyWithKeyKeyUserPropertyKeyVoidCallsCount = 0
    public var deleteUserPropertyWithKeyKeyUserPropertyKeyVoidCalled: Bool {
        return deleteUserPropertyWithKeyKeyUserPropertyKeyVoidCallsCount > 0
    }
    public var deleteUserPropertyWithKeyKeyUserPropertyKeyVoidReceivedKey: (UserProperty.Key)?
    public var deleteUserPropertyWithKeyKeyUserPropertyKeyVoidReceivedInvocations: [(UserProperty.Key)] = []
    public var deleteUserPropertyWithKeyKeyUserPropertyKeyVoidClosure: ((UserProperty.Key) async -> Void)?

    public func deleteUserProperty(withKey key: UserProperty.Key) async {
        deleteUserPropertyWithKeyKeyUserPropertyKeyVoidCallsCount += 1
        deleteUserPropertyWithKeyKeyUserPropertyKeyVoidReceivedKey = key
        deleteUserPropertyWithKeyKeyUserPropertyKeyVoidReceivedInvocations.append(key)
        await deleteUserPropertyWithKeyKeyUserPropertyKeyVoidClosure?(key)
    }

    //MARK: - deleteUserAccount

    public var deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidThrowableError: (any Error)?
    public var deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidCallsCount = 0
    public var deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidCalled: Bool {
        return deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidCallsCount > 0
    }
    public var deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidReceivedArguments: (id: UUID, domain: String?, date: Date)?
    public var deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidReceivedInvocations: [(id: UUID, domain: String?, date: Date)] = []
    public var deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidClosure: ((UUID, String?, Date) async throws -> Void)?

    public func deleteUserAccount(with id: UUID, domain: String?, at date: Date) async throws {
        deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidCallsCount += 1
        deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidReceivedArguments = (id: id, domain: domain, date: date)
        deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidReceivedInvocations.append((id: id, domain: domain, date: date))
        if let error = deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidThrowableError {
            throw error
        }
        try await deleteUserAccountWithIdUUIDDomainStringAtDateDateVoidClosure?(id, domain, date)
    }


}
// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
