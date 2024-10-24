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

import LocalAuthentication
import Combine
import WireCoreCrypto

@testable import WireDataModel
























public class AuthenticationContextProtocolMock: AuthenticationContextProtocol {

    public init() {}

    public var laContext: LAContext {
        get { return underlyingLaContext }
        set(value) { underlyingLaContext = value }
    }
    public var underlyingLaContext: (LAContext)!
    public var evaluatedPolicyDomainState: Data?


    //MARK: - canEvaluatePolicy

    public var canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolCallsCount = 0
    public var canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolCalled: Bool {
        return canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolCallsCount > 0
    }
    public var canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolReceivedArguments: (policy: LAPolicy, error: NSErrorPointer)?
    public var canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolReceivedInvocations: [(policy: LAPolicy, error: NSErrorPointer)] = []
    public var canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolReturnValue: Bool!
    public var canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolClosure: ((LAPolicy, NSErrorPointer) -> Bool)?

    public func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolCallsCount += 1
        canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolReceivedArguments = (policy: policy, error: error)
        canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolReceivedInvocations.append((policy: policy, error: error))
        if let canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolClosure = canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolClosure {
            return canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolClosure(policy, error)
        } else {
            return canEvaluatePolicyPolicyLAPolicyErrorNSErrorPointerBoolReturnValue
        }
    }

    //MARK: - evaluatePolicy

    public var evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingPolicyReplyVoidCallsCount = 0
    public var evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingPolicyReplyVoidCalled: Bool {
        return evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingPolicyReplyVoidCallsCount > 0
    }
    public var evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingPolicyReplyVoidReceivedArguments: (policy: LAPolicy, localizedReason: String, reply: PolicyReply)?
    public var evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingPolicyReplyVoidReceivedInvocations: [(policy: LAPolicy, localizedReason: String, reply: PolicyReply)] = []
    public var evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingPolicyReplyVoidClosure: ((LAPolicy, String, @escaping PolicyReply) -> Void)?

    public func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: (@escaping PolicyReply))  {
        evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingPolicyReplyVoidCallsCount += 1
        evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingPolicyReplyVoidReceivedArguments = (policy: policy, localizedReason: localizedReason, reply: reply)
        evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingPolicyReplyVoidReceivedInvocations.append((policy: policy, localizedReason: localizedReason, reply: reply))
        evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingPolicyReplyVoidClosure?(policy, localizedReason, reply)
    }


}
class BiometricsStateProtocolMock: BiometricsStateProtocol {




    //MARK: - biometricsChanged

    var biometricsChangedInContextAuthenticationContextProtocolBoolCallsCount = 0
    var biometricsChangedInContextAuthenticationContextProtocolBoolCalled: Bool {
        return biometricsChangedInContextAuthenticationContextProtocolBoolCallsCount > 0
    }
    var biometricsChangedInContextAuthenticationContextProtocolBoolReceivedContext: (AuthenticationContextProtocol)?
    var biometricsChangedInContextAuthenticationContextProtocolBoolReceivedInvocations: [(AuthenticationContextProtocol)] = []
    var biometricsChangedInContextAuthenticationContextProtocolBoolReturnValue: Bool!
    var biometricsChangedInContextAuthenticationContextProtocolBoolClosure: ((AuthenticationContextProtocol) -> Bool)?

    func biometricsChanged(in context: AuthenticationContextProtocol) -> Bool {
        biometricsChangedInContextAuthenticationContextProtocolBoolCallsCount += 1
        biometricsChangedInContextAuthenticationContextProtocolBoolReceivedContext = context
        biometricsChangedInContextAuthenticationContextProtocolBoolReceivedInvocations.append(context)
        if let biometricsChangedInContextAuthenticationContextProtocolBoolClosure = biometricsChangedInContextAuthenticationContextProtocolBoolClosure {
            return biometricsChangedInContextAuthenticationContextProtocolBoolClosure(context)
        } else {
            return biometricsChangedInContextAuthenticationContextProtocolBoolReturnValue
        }
    }

    //MARK: - persistState

    var persistStateVoidCallsCount = 0
    var persistStateVoidCalled: Bool {
        return persistStateVoidCallsCount > 0
    }
    var persistStateVoidClosure: (() -> Void)?

    func persistState() {
        persistStateVoidCallsCount += 1
        persistStateVoidClosure?()
    }


}
public class CRLExpirationDatesRepositoryProtocolMock: CRLExpirationDatesRepositoryProtocol {

    public init() {}



    //MARK: - crlExpirationDateExists

    public var crlExpirationDateExistsForDistributionPointURLBoolCallsCount = 0
    public var crlExpirationDateExistsForDistributionPointURLBoolCalled: Bool {
        return crlExpirationDateExistsForDistributionPointURLBoolCallsCount > 0
    }
    public var crlExpirationDateExistsForDistributionPointURLBoolReceivedDistributionPoint: (URL)?
    public var crlExpirationDateExistsForDistributionPointURLBoolReceivedInvocations: [(URL)] = []
    public var crlExpirationDateExistsForDistributionPointURLBoolReturnValue: Bool!
    public var crlExpirationDateExistsForDistributionPointURLBoolClosure: ((URL) -> Bool)?

    public func crlExpirationDateExists(for distributionPoint: URL) -> Bool {
        crlExpirationDateExistsForDistributionPointURLBoolCallsCount += 1
        crlExpirationDateExistsForDistributionPointURLBoolReceivedDistributionPoint = distributionPoint
        crlExpirationDateExistsForDistributionPointURLBoolReceivedInvocations.append(distributionPoint)
        if let crlExpirationDateExistsForDistributionPointURLBoolClosure = crlExpirationDateExistsForDistributionPointURLBoolClosure {
            return crlExpirationDateExistsForDistributionPointURLBoolClosure(distributionPoint)
        } else {
            return crlExpirationDateExistsForDistributionPointURLBoolReturnValue
        }
    }

    //MARK: - storeCRLExpirationDate

    public var storeCRLExpirationDateExpirationDateDateForDistributionPointURLVoidCallsCount = 0
    public var storeCRLExpirationDateExpirationDateDateForDistributionPointURLVoidCalled: Bool {
        return storeCRLExpirationDateExpirationDateDateForDistributionPointURLVoidCallsCount > 0
    }
    public var storeCRLExpirationDateExpirationDateDateForDistributionPointURLVoidReceivedArguments: (expirationDate: Date, distributionPoint: URL)?
    public var storeCRLExpirationDateExpirationDateDateForDistributionPointURLVoidReceivedInvocations: [(expirationDate: Date, distributionPoint: URL)] = []
    public var storeCRLExpirationDateExpirationDateDateForDistributionPointURLVoidClosure: ((Date, URL) -> Void)?

    public func storeCRLExpirationDate(_ expirationDate: Date, for distributionPoint: URL) {
        storeCRLExpirationDateExpirationDateDateForDistributionPointURLVoidCallsCount += 1
        storeCRLExpirationDateExpirationDateDateForDistributionPointURLVoidReceivedArguments = (expirationDate: expirationDate, distributionPoint: distributionPoint)
        storeCRLExpirationDateExpirationDateDateForDistributionPointURLVoidReceivedInvocations.append((expirationDate: expirationDate, distributionPoint: distributionPoint))
        storeCRLExpirationDateExpirationDateDateForDistributionPointURLVoidClosure?(expirationDate, distributionPoint)
    }

    //MARK: - fetchAllCRLExpirationDates

    public var fetchAllCRLExpirationDatesURLDateCallsCount = 0
    public var fetchAllCRLExpirationDatesURLDateCalled: Bool {
        return fetchAllCRLExpirationDatesURLDateCallsCount > 0
    }
    public var fetchAllCRLExpirationDatesURLDateReturnValue: [URL: Date]!
    public var fetchAllCRLExpirationDatesURLDateClosure: (() -> [URL: Date])?

    public func fetchAllCRLExpirationDates() -> [URL: Date] {
        fetchAllCRLExpirationDatesURLDateCallsCount += 1
        if let fetchAllCRLExpirationDatesURLDateClosure = fetchAllCRLExpirationDatesURLDateClosure {
            return fetchAllCRLExpirationDatesURLDateClosure()
        } else {
            return fetchAllCRLExpirationDatesURLDateReturnValue
        }
    }


}
public class CommitSendingMock: CommitSending {

    public init() {}



    //MARK: - sendCommitBundle

    public var sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventThrowableError: (any Error)?
    public var sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventCallsCount = 0
    public var sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventCalled: Bool {
        return sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventCallsCount > 0
    }
    public var sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReceivedArguments: (bundle: CommitBundle, groupID: MLSGroupID)?
    public var sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReceivedInvocations: [(bundle: CommitBundle, groupID: MLSGroupID)] = []
    public var sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReturnValue: [ZMUpdateEvent]!
    public var sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventClosure: ((CommitBundle, MLSGroupID) async throws -> [ZMUpdateEvent])?

    public func sendCommitBundle(_ bundle: CommitBundle, for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventCallsCount += 1
        sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReceivedArguments = (bundle: bundle, groupID: groupID)
        sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReceivedInvocations.append((bundle: bundle, groupID: groupID))
        if let error = sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventThrowableError {
            throw error
        }
        if let sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventClosure = sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventClosure {
            return try await sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventClosure(bundle, groupID)
        } else {
            return sendCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReturnValue
        }
    }

    //MARK: - sendExternalCommitBundle

    public var sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventThrowableError: (any Error)?
    public var sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventCallsCount = 0
    public var sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventCalled: Bool {
        return sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventCallsCount > 0
    }
    public var sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReceivedArguments: (bundle: CommitBundle, groupID: MLSGroupID)?
    public var sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReceivedInvocations: [(bundle: CommitBundle, groupID: MLSGroupID)] = []
    public var sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReturnValue: [ZMUpdateEvent]!
    public var sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventClosure: ((CommitBundle, MLSGroupID) async throws -> [ZMUpdateEvent])?

    public func sendExternalCommitBundle(_ bundle: CommitBundle, for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventCallsCount += 1
        sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReceivedArguments = (bundle: bundle, groupID: groupID)
        sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReceivedInvocations.append((bundle: bundle, groupID: groupID))
        if let error = sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventThrowableError {
            throw error
        }
        if let sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventClosure = sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventClosure {
            return try await sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventClosure(bundle, groupID)
        } else {
            return sendExternalCommitBundleBundleCommitBundleForGroupIDMLSGroupIDZMUpdateEventReturnValue
        }
    }

    //MARK: - onEpochChanged

    public var onEpochChangedAnyPublisherMLSGroupIDNeverCallsCount = 0
    public var onEpochChangedAnyPublisherMLSGroupIDNeverCalled: Bool {
        return onEpochChangedAnyPublisherMLSGroupIDNeverCallsCount > 0
    }
    public var onEpochChangedAnyPublisherMLSGroupIDNeverReturnValue: AnyPublisher<MLSGroupID, Never>!
    public var onEpochChangedAnyPublisherMLSGroupIDNeverClosure: (() -> AnyPublisher<MLSGroupID, Never>)?

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        onEpochChangedAnyPublisherMLSGroupIDNeverCallsCount += 1
        if let onEpochChangedAnyPublisherMLSGroupIDNeverClosure = onEpochChangedAnyPublisherMLSGroupIDNeverClosure {
            return onEpochChangedAnyPublisherMLSGroupIDNeverClosure()
        } else {
            return onEpochChangedAnyPublisherMLSGroupIDNeverReturnValue
        }
    }


}
public class ConversationEventProcessorProtocolMock: ConversationEventProcessorProtocol {

    public init() {}



    //MARK: - processConversationEvents

    public var processConversationEventsEventsZMUpdateEventVoidCallsCount = 0
    public var processConversationEventsEventsZMUpdateEventVoidCalled: Bool {
        return processConversationEventsEventsZMUpdateEventVoidCallsCount > 0
    }
    public var processConversationEventsEventsZMUpdateEventVoidReceivedEvents: ([ZMUpdateEvent])?
    public var processConversationEventsEventsZMUpdateEventVoidReceivedInvocations: [([ZMUpdateEvent])] = []
    public var processConversationEventsEventsZMUpdateEventVoidClosure: (([ZMUpdateEvent]) async -> Void)?

    public func processConversationEvents(_ events: [ZMUpdateEvent]) async {
        processConversationEventsEventsZMUpdateEventVoidCallsCount += 1
        processConversationEventsEventsZMUpdateEventVoidReceivedEvents = events
        processConversationEventsEventsZMUpdateEventVoidReceivedInvocations.append(events)
        await processConversationEventsEventsZMUpdateEventVoidClosure?(events)
    }

    //MARK: - processAndSaveConversationEvents

    public var processAndSaveConversationEventsEventsZMUpdateEventVoidCallsCount = 0
    public var processAndSaveConversationEventsEventsZMUpdateEventVoidCalled: Bool {
        return processAndSaveConversationEventsEventsZMUpdateEventVoidCallsCount > 0
    }
    public var processAndSaveConversationEventsEventsZMUpdateEventVoidReceivedEvents: ([ZMUpdateEvent])?
    public var processAndSaveConversationEventsEventsZMUpdateEventVoidReceivedInvocations: [([ZMUpdateEvent])] = []
    public var processAndSaveConversationEventsEventsZMUpdateEventVoidClosure: (([ZMUpdateEvent]) async -> Void)?

    public func processAndSaveConversationEvents(_ events: [ZMUpdateEvent]) async {
        processAndSaveConversationEventsEventsZMUpdateEventVoidCallsCount += 1
        processAndSaveConversationEventsEventsZMUpdateEventVoidReceivedEvents = events
        processAndSaveConversationEventsEventsZMUpdateEventVoidReceivedInvocations.append(events)
        await processAndSaveConversationEventsEventsZMUpdateEventVoidClosure?(events)
    }


}
public class ConversationLikeMock: ConversationLike {

    public init() {}

    public var conversationType: ZMConversationType {
        get { return underlyingConversationType }
        set(value) { underlyingConversationType = value }
    }
    public var underlyingConversationType: (ZMConversationType)!
    public var isSelfAnActiveMember: Bool {
        get { return underlyingIsSelfAnActiveMember }
        set(value) { underlyingIsSelfAnActiveMember = value }
    }
    public var underlyingIsSelfAnActiveMember: (Bool)!
    public var teamRemoteIdentifier: UUID?
    public var localParticipantsCount: Int {
        get { return underlyingLocalParticipantsCount }
        set(value) { underlyingLocalParticipantsCount = value }
    }
    public var underlyingLocalParticipantsCount: (Int)!
    public var displayName: String?
    public var connectedUserType: UserType?
    public var allowGuests: Bool {
        get { return underlyingAllowGuests }
        set(value) { underlyingAllowGuests = value }
    }
    public var underlyingAllowGuests: (Bool)!
    public var allowServices: Bool {
        get { return underlyingAllowServices }
        set(value) { underlyingAllowServices = value }
    }
    public var underlyingAllowServices: (Bool)!
    public var isUnderLegalHold: Bool {
        get { return underlyingIsUnderLegalHold }
        set(value) { underlyingIsUnderLegalHold = value }
    }
    public var underlyingIsUnderLegalHold: (Bool)!
    public var isMLSConversationDegraded: Bool {
        get { return underlyingIsMLSConversationDegraded }
        set(value) { underlyingIsMLSConversationDegraded = value }
    }
    public var underlyingIsMLSConversationDegraded: (Bool)!
    public var isProteusConversationDegraded: Bool {
        get { return underlyingIsProteusConversationDegraded }
        set(value) { underlyingIsProteusConversationDegraded = value }
    }
    public var underlyingIsProteusConversationDegraded: (Bool)!
    public var sortedActiveParticipantsUserTypes: [UserType] = []
    public var relatedConnectionState: ZMConnectionStatus {
        get { return underlyingRelatedConnectionState }
        set(value) { underlyingRelatedConnectionState = value }
    }
    public var underlyingRelatedConnectionState: (ZMConnectionStatus)!
    public var lastMessage: ZMConversationMessage?
    public var firstUnreadMessage: ZMConversationMessage?
    public var areServicesPresent: Bool {
        get { return underlyingAreServicesPresent }
        set(value) { underlyingAreServicesPresent = value }
    }
    public var underlyingAreServicesPresent: (Bool)!
    public var domain: String?


    //MARK: - localParticipantsContain

    public var localParticipantsContainUserUserTypeBoolCallsCount = 0
    public var localParticipantsContainUserUserTypeBoolCalled: Bool {
        return localParticipantsContainUserUserTypeBoolCallsCount > 0
    }
    public var localParticipantsContainUserUserTypeBoolReceivedUser: (UserType)?
    public var localParticipantsContainUserUserTypeBoolReceivedInvocations: [(UserType)] = []
    public var localParticipantsContainUserUserTypeBoolReturnValue: Bool!
    public var localParticipantsContainUserUserTypeBoolClosure: ((UserType) -> Bool)?

    public func localParticipantsContain(user: UserType) -> Bool {
        localParticipantsContainUserUserTypeBoolCallsCount += 1
        localParticipantsContainUserUserTypeBoolReceivedUser = user
        localParticipantsContainUserUserTypeBoolReceivedInvocations.append(user)
        if let localParticipantsContainUserUserTypeBoolClosure = localParticipantsContainUserUserTypeBoolClosure {
            return localParticipantsContainUserUserTypeBoolClosure(user)
        } else {
            return localParticipantsContainUserUserTypeBoolReturnValue
        }
    }

    //MARK: - verifyLegalHoldSubjects

    public var verifyLegalHoldSubjectsVoidCallsCount = 0
    public var verifyLegalHoldSubjectsVoidCalled: Bool {
        return verifyLegalHoldSubjectsVoidCallsCount > 0
    }
    public var verifyLegalHoldSubjectsVoidClosure: (() -> Void)?

    public func verifyLegalHoldSubjects() {
        verifyLegalHoldSubjectsVoidCallsCount += 1
        verifyLegalHoldSubjectsVoidClosure?()
    }


}
public class CoreCryptoProtocolMock: CoreCryptoProtocol {

    public init() {}



    //MARK: - addClientsToConversation

    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesThrowableError: (any Error)?
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesCallsCount = 0
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesCalled: Bool {
        return addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesCallsCount > 0
    }
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesReceivedArguments: (conversationId: Data, keyPackages: [Data])?
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesReceivedInvocations: [(conversationId: Data, keyPackages: [Data])] = []
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesReturnValue: WireCoreCrypto.MemberAddedMessages!
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesClosure: ((Data, [Data]) async throws -> WireCoreCrypto.MemberAddedMessages)?

    public func addClientsToConversation(conversationId: Data, keyPackages: [Data]) async throws -> WireCoreCrypto.MemberAddedMessages {
        addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesCallsCount += 1
        addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesReceivedArguments = (conversationId: conversationId, keyPackages: keyPackages)
        addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesReceivedInvocations.append((conversationId: conversationId, keyPackages: keyPackages))
        if let error = addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesThrowableError {
            throw error
        }
        if let addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesClosure = addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesClosure {
            return try await addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesClosure(conversationId, keyPackages)
        } else {
            return addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoMemberAddedMessagesReturnValue
        }
    }

    //MARK: - clearPendingCommit

    public var clearPendingCommitConversationIdDataVoidThrowableError: (any Error)?
    public var clearPendingCommitConversationIdDataVoidCallsCount = 0
    public var clearPendingCommitConversationIdDataVoidCalled: Bool {
        return clearPendingCommitConversationIdDataVoidCallsCount > 0
    }
    public var clearPendingCommitConversationIdDataVoidReceivedConversationId: (Data)?
    public var clearPendingCommitConversationIdDataVoidReceivedInvocations: [(Data)] = []
    public var clearPendingCommitConversationIdDataVoidClosure: ((Data) async throws -> Void)?

    public func clearPendingCommit(conversationId: Data) async throws {
        clearPendingCommitConversationIdDataVoidCallsCount += 1
        clearPendingCommitConversationIdDataVoidReceivedConversationId = conversationId
        clearPendingCommitConversationIdDataVoidReceivedInvocations.append(conversationId)
        if let error = clearPendingCommitConversationIdDataVoidThrowableError {
            throw error
        }
        try await clearPendingCommitConversationIdDataVoidClosure?(conversationId)
    }

    //MARK: - clearPendingGroupFromExternalCommit

    public var clearPendingGroupFromExternalCommitConversationIdDataVoidThrowableError: (any Error)?
    public var clearPendingGroupFromExternalCommitConversationIdDataVoidCallsCount = 0
    public var clearPendingGroupFromExternalCommitConversationIdDataVoidCalled: Bool {
        return clearPendingGroupFromExternalCommitConversationIdDataVoidCallsCount > 0
    }
    public var clearPendingGroupFromExternalCommitConversationIdDataVoidReceivedConversationId: (Data)?
    public var clearPendingGroupFromExternalCommitConversationIdDataVoidReceivedInvocations: [(Data)] = []
    public var clearPendingGroupFromExternalCommitConversationIdDataVoidClosure: ((Data) async throws -> Void)?

    public func clearPendingGroupFromExternalCommit(conversationId: Data) async throws {
        clearPendingGroupFromExternalCommitConversationIdDataVoidCallsCount += 1
        clearPendingGroupFromExternalCommitConversationIdDataVoidReceivedConversationId = conversationId
        clearPendingGroupFromExternalCommitConversationIdDataVoidReceivedInvocations.append(conversationId)
        if let error = clearPendingGroupFromExternalCommitConversationIdDataVoidThrowableError {
            throw error
        }
        try await clearPendingGroupFromExternalCommitConversationIdDataVoidClosure?(conversationId)
    }

    //MARK: - clearPendingProposal

    public var clearPendingProposalConversationIdDataProposalRefDataVoidThrowableError: (any Error)?
    public var clearPendingProposalConversationIdDataProposalRefDataVoidCallsCount = 0
    public var clearPendingProposalConversationIdDataProposalRefDataVoidCalled: Bool {
        return clearPendingProposalConversationIdDataProposalRefDataVoidCallsCount > 0
    }
    public var clearPendingProposalConversationIdDataProposalRefDataVoidReceivedArguments: (conversationId: Data, proposalRef: Data)?
    public var clearPendingProposalConversationIdDataProposalRefDataVoidReceivedInvocations: [(conversationId: Data, proposalRef: Data)] = []
    public var clearPendingProposalConversationIdDataProposalRefDataVoidClosure: ((Data, Data) async throws -> Void)?

    public func clearPendingProposal(conversationId: Data, proposalRef: Data) async throws {
        clearPendingProposalConversationIdDataProposalRefDataVoidCallsCount += 1
        clearPendingProposalConversationIdDataProposalRefDataVoidReceivedArguments = (conversationId: conversationId, proposalRef: proposalRef)
        clearPendingProposalConversationIdDataProposalRefDataVoidReceivedInvocations.append((conversationId: conversationId, proposalRef: proposalRef))
        if let error = clearPendingProposalConversationIdDataProposalRefDataVoidThrowableError {
            throw error
        }
        try await clearPendingProposalConversationIdDataProposalRefDataVoidClosure?(conversationId, proposalRef)
    }

    //MARK: - clientKeypackages

    public var clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataThrowableError: (any Error)?
    public var clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataCallsCount = 0
    public var clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataCalled: Bool {
        return clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataCallsCount > 0
    }
    public var clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataReceivedArguments: (ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType, amountRequested: UInt32)?
    public var clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataReceivedInvocations: [(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType, amountRequested: UInt32)] = []
    public var clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataReturnValue: [Data]!
    public var clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataClosure: ((WireCoreCrypto.Ciphersuite, WireCoreCrypto.MlsCredentialType, UInt32) async throws -> [Data])?

    public func clientKeypackages(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType, amountRequested: UInt32) async throws -> [Data] {
        clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataCallsCount += 1
        clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataReceivedArguments = (ciphersuite: ciphersuite, credentialType: credentialType, amountRequested: amountRequested)
        clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataReceivedInvocations.append((ciphersuite: ciphersuite, credentialType: credentialType, amountRequested: amountRequested))
        if let error = clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataThrowableError {
            throw error
        }
        if let clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataClosure = clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataClosure {
            return try await clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataClosure(ciphersuite, credentialType, amountRequested)
        } else {
            return clientKeypackagesCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeAmountRequestedUInt32DataReturnValue
        }
    }

    //MARK: - clientPublicKey

    public var clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataThrowableError: (any Error)?
    public var clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataCallsCount = 0
    public var clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataCalled: Bool {
        return clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataCallsCount > 0
    }
    public var clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReceivedArguments: (ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType)?
    public var clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReceivedInvocations: [(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType)] = []
    public var clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReturnValue: Data!
    public var clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataClosure: ((WireCoreCrypto.Ciphersuite, WireCoreCrypto.MlsCredentialType) async throws -> Data)?

    public func clientPublicKey(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> Data {
        clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataCallsCount += 1
        clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReceivedArguments = (ciphersuite: ciphersuite, credentialType: credentialType)
        clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReceivedInvocations.append((ciphersuite: ciphersuite, credentialType: credentialType))
        if let error = clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataThrowableError {
            throw error
        }
        if let clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataClosure = clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataClosure {
            return try await clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataClosure(ciphersuite, credentialType)
        } else {
            return clientPublicKeyCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReturnValue
        }
    }

    //MARK: - clientValidKeypackagesCount

    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64ThrowableError: (any Error)?
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64CallsCount = 0
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64Called: Bool {
        return clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64CallsCount > 0
    }
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64ReceivedArguments: (ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType)?
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64ReceivedInvocations: [(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType)] = []
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64ReturnValue: UInt64!
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64Closure: ((WireCoreCrypto.Ciphersuite, WireCoreCrypto.MlsCredentialType) async throws -> UInt64)?

    public func clientValidKeypackagesCount(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> UInt64 {
        clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64CallsCount += 1
        clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64ReceivedArguments = (ciphersuite: ciphersuite, credentialType: credentialType)
        clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64ReceivedInvocations.append((ciphersuite: ciphersuite, credentialType: credentialType))
        if let error = clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64ThrowableError {
            throw error
        }
        if let clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64Closure = clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64Closure {
            return try await clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64Closure(ciphersuite, credentialType)
        } else {
            return clientValidKeypackagesCountCiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeUInt64ReturnValue
        }
    }

    //MARK: - commitAccepted

    public var commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageThrowableError: (any Error)?
    public var commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageCallsCount = 0
    public var commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageCalled: Bool {
        return commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageCallsCount > 0
    }
    public var commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageReceivedConversationId: (Data)?
    public var commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageReceivedInvocations: [(Data)] = []
    public var commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageReturnValue: [WireCoreCrypto.BufferedDecryptedMessage]?
    public var commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageClosure: ((Data) async throws -> [WireCoreCrypto.BufferedDecryptedMessage]?)?

    public func commitAccepted(conversationId: Data) async throws -> [WireCoreCrypto.BufferedDecryptedMessage]? {
        commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageCallsCount += 1
        commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageReceivedConversationId = conversationId
        commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageReceivedInvocations.append(conversationId)
        if let error = commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageThrowableError {
            throw error
        }
        if let commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageClosure = commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageClosure {
            return try await commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageClosure(conversationId)
        } else {
            return commitAcceptedConversationIdDataWireCoreCryptoBufferedDecryptedMessageReturnValue
        }
    }

    //MARK: - commitPendingProposals

    public var commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleThrowableError: (any Error)?
    public var commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleCallsCount = 0
    public var commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleCalled: Bool {
        return commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleCallsCount > 0
    }
    public var commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleReceivedConversationId: (Data)?
    public var commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleReceivedInvocations: [(Data)] = []
    public var commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleReturnValue: WireCoreCrypto.CommitBundle?
    public var commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleClosure: ((Data) async throws -> WireCoreCrypto.CommitBundle?)?

    public func commitPendingProposals(conversationId: Data) async throws -> WireCoreCrypto.CommitBundle? {
        commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleCallsCount += 1
        commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleReceivedConversationId = conversationId
        commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleReceivedInvocations.append(conversationId)
        if let error = commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleThrowableError {
            throw error
        }
        if let commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleClosure = commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleClosure {
            return try await commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleClosure(conversationId)
        } else {
            return commitPendingProposalsConversationIdDataWireCoreCryptoCommitBundleReturnValue
        }
    }

    //MARK: - conversationCiphersuite

    public var conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteThrowableError: (any Error)?
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteCallsCount = 0
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteCalled: Bool {
        return conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteCallsCount > 0
    }
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteReceivedConversationId: (Data)?
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteReceivedInvocations: [(Data)] = []
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteReturnValue: WireCoreCrypto.Ciphersuite!
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteClosure: ((Data) async throws -> WireCoreCrypto.Ciphersuite)?

    public func conversationCiphersuite(conversationId: Data) async throws -> WireCoreCrypto.Ciphersuite {
        conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteCallsCount += 1
        conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteReceivedConversationId = conversationId
        conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteReceivedInvocations.append(conversationId)
        if let error = conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteThrowableError {
            throw error
        }
        if let conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteClosure = conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteClosure {
            return try await conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteClosure(conversationId)
        } else {
            return conversationCiphersuiteConversationIdDataWireCoreCryptoCiphersuiteReturnValue
        }
    }

    //MARK: - conversationEpoch

    public var conversationEpochConversationIdDataUInt64ThrowableError: (any Error)?
    public var conversationEpochConversationIdDataUInt64CallsCount = 0
    public var conversationEpochConversationIdDataUInt64Called: Bool {
        return conversationEpochConversationIdDataUInt64CallsCount > 0
    }
    public var conversationEpochConversationIdDataUInt64ReceivedConversationId: (Data)?
    public var conversationEpochConversationIdDataUInt64ReceivedInvocations: [(Data)] = []
    public var conversationEpochConversationIdDataUInt64ReturnValue: UInt64!
    public var conversationEpochConversationIdDataUInt64Closure: ((Data) async throws -> UInt64)?

    public func conversationEpoch(conversationId: Data) async throws -> UInt64 {
        conversationEpochConversationIdDataUInt64CallsCount += 1
        conversationEpochConversationIdDataUInt64ReceivedConversationId = conversationId
        conversationEpochConversationIdDataUInt64ReceivedInvocations.append(conversationId)
        if let error = conversationEpochConversationIdDataUInt64ThrowableError {
            throw error
        }
        if let conversationEpochConversationIdDataUInt64Closure = conversationEpochConversationIdDataUInt64Closure {
            return try await conversationEpochConversationIdDataUInt64Closure(conversationId)
        } else {
            return conversationEpochConversationIdDataUInt64ReturnValue
        }
    }

    //MARK: - conversationExists

    public var conversationExistsConversationIdDataBoolCallsCount = 0
    public var conversationExistsConversationIdDataBoolCalled: Bool {
        return conversationExistsConversationIdDataBoolCallsCount > 0
    }
    public var conversationExistsConversationIdDataBoolReceivedConversationId: (Data)?
    public var conversationExistsConversationIdDataBoolReceivedInvocations: [(Data)] = []
    public var conversationExistsConversationIdDataBoolReturnValue: Bool!
    public var conversationExistsConversationIdDataBoolClosure: ((Data) async -> Bool)?

    public func conversationExists(conversationId: Data) async -> Bool {
        conversationExistsConversationIdDataBoolCallsCount += 1
        conversationExistsConversationIdDataBoolReceivedConversationId = conversationId
        conversationExistsConversationIdDataBoolReceivedInvocations.append(conversationId)
        if let conversationExistsConversationIdDataBoolClosure = conversationExistsConversationIdDataBoolClosure {
            return await conversationExistsConversationIdDataBoolClosure(conversationId)
        } else {
            return conversationExistsConversationIdDataBoolReturnValue
        }
    }

    //MARK: - createConversation

    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidThrowableError: (any Error)?
    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidCallsCount = 0
    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidCalled: Bool {
        return createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidCallsCount > 0
    }
    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidReceivedArguments: (conversationId: Data, creatorCredentialType: WireCoreCrypto.MlsCredentialType, config: WireCoreCrypto.ConversationConfiguration)?
    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidReceivedInvocations: [(conversationId: Data, creatorCredentialType: WireCoreCrypto.MlsCredentialType, config: WireCoreCrypto.ConversationConfiguration)] = []
    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidClosure: ((Data, WireCoreCrypto.MlsCredentialType, WireCoreCrypto.ConversationConfiguration) async throws -> Void)?

    public func createConversation(conversationId: Data, creatorCredentialType: WireCoreCrypto.MlsCredentialType, config: WireCoreCrypto.ConversationConfiguration) async throws {
        createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidCallsCount += 1
        createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidReceivedArguments = (conversationId: conversationId, creatorCredentialType: creatorCredentialType, config: config)
        createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidReceivedInvocations.append((conversationId: conversationId, creatorCredentialType: creatorCredentialType, config: config))
        if let error = createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidThrowableError {
            throw error
        }
        try await createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoMlsCredentialTypeConfigWireCoreCryptoConversationConfigurationVoidClosure?(conversationId, creatorCredentialType, config)
    }

    //MARK: - decryptMessage

    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageThrowableError: (any Error)?
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageCallsCount = 0
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageCalled: Bool {
        return decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageCallsCount > 0
    }
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageReceivedArguments: (conversationId: Data, payload: Data)?
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageReceivedInvocations: [(conversationId: Data, payload: Data)] = []
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageReturnValue: WireCoreCrypto.DecryptedMessage!
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageClosure: ((Data, Data) async throws -> WireCoreCrypto.DecryptedMessage)?

    public func decryptMessage(conversationId: Data, payload: Data) async throws -> WireCoreCrypto.DecryptedMessage {
        decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageCallsCount += 1
        decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageReceivedArguments = (conversationId: conversationId, payload: payload)
        decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageReceivedInvocations.append((conversationId: conversationId, payload: payload))
        if let error = decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageThrowableError {
            throw error
        }
        if let decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageClosure = decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageClosure {
            return try await decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageClosure(conversationId, payload)
        } else {
            return decryptMessageConversationIdDataPayloadDataWireCoreCryptoDecryptedMessageReturnValue
        }
    }

    //MARK: - deleteKeypackages

    public var deleteKeypackagesRefsDataVoidThrowableError: (any Error)?
    public var deleteKeypackagesRefsDataVoidCallsCount = 0
    public var deleteKeypackagesRefsDataVoidCalled: Bool {
        return deleteKeypackagesRefsDataVoidCallsCount > 0
    }
    public var deleteKeypackagesRefsDataVoidReceivedRefs: ([Data])?
    public var deleteKeypackagesRefsDataVoidReceivedInvocations: [([Data])] = []
    public var deleteKeypackagesRefsDataVoidClosure: (([Data]) async throws -> Void)?

    public func deleteKeypackages(refs: [Data]) async throws {
        deleteKeypackagesRefsDataVoidCallsCount += 1
        deleteKeypackagesRefsDataVoidReceivedRefs = refs
        deleteKeypackagesRefsDataVoidReceivedInvocations.append(refs)
        if let error = deleteKeypackagesRefsDataVoidThrowableError {
            throw error
        }
        try await deleteKeypackagesRefsDataVoidClosure?(refs)
    }

    //MARK: - e2eiConversationState

    public var e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateThrowableError: (any Error)?
    public var e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateCallsCount = 0
    public var e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateCalled: Bool {
        return e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateCallsCount > 0
    }
    public var e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateReceivedConversationId: (Data)?
    public var e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateReceivedInvocations: [(Data)] = []
    public var e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateReturnValue: WireCoreCrypto.E2eiConversationState!
    public var e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateClosure: ((Data) async throws -> WireCoreCrypto.E2eiConversationState)?

    public func e2eiConversationState(conversationId: Data) async throws -> WireCoreCrypto.E2eiConversationState {
        e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateCallsCount += 1
        e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateReceivedConversationId = conversationId
        e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateReceivedInvocations.append(conversationId)
        if let error = e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateThrowableError {
            throw error
        }
        if let e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateClosure = e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateClosure {
            return try await e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateClosure(conversationId)
        } else {
            return e2eiConversationStateConversationIdDataWireCoreCryptoE2eiConversationStateReturnValue
        }
    }

    //MARK: - e2eiDumpPkiEnv

    public var e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvThrowableError: (any Error)?
    public var e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvCallsCount = 0
    public var e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvCalled: Bool {
        return e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvCallsCount > 0
    }
    public var e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvReturnValue: WireCoreCrypto.E2eiDumpedPkiEnv?
    public var e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvClosure: (() async throws -> WireCoreCrypto.E2eiDumpedPkiEnv?)?

    public func e2eiDumpPkiEnv() async throws -> WireCoreCrypto.E2eiDumpedPkiEnv? {
        e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvCallsCount += 1
        if let error = e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvThrowableError {
            throw error
        }
        if let e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvClosure = e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvClosure {
            return try await e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvClosure()
        } else {
            return e2eiDumpPkiEnvWireCoreCryptoE2eiDumpedPkiEnvReturnValue
        }
    }

    //MARK: - e2eiEnrollmentStash

    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataThrowableError: (any Error)?
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataCallsCount = 0
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataCalled: Bool {
        return e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataCallsCount > 0
    }
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataReceivedEnrollment: (WireCoreCrypto.E2eiEnrollment)?
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataReceivedInvocations: [(WireCoreCrypto.E2eiEnrollment)] = []
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataReturnValue: Data!
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataClosure: ((WireCoreCrypto.E2eiEnrollment) async throws -> Data)?

    public func e2eiEnrollmentStash(enrollment: WireCoreCrypto.E2eiEnrollment) async throws -> Data {
        e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataCallsCount += 1
        e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataReceivedEnrollment = enrollment
        e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataReceivedInvocations.append(enrollment)
        if let error = e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataThrowableError {
            throw error
        }
        if let e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataClosure = e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataClosure {
            return try await e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataClosure(enrollment)
        } else {
            return e2eiEnrollmentStashEnrollmentWireCoreCryptoE2eiEnrollmentDataReturnValue
        }
    }

    //MARK: - e2eiEnrollmentStashPop

    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentThrowableError: (any Error)?
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentCallsCount = 0
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentCalled: Bool {
        return e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentCallsCount > 0
    }
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentReceivedHandle: (Data)?
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentReceivedInvocations: [(Data)] = []
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentReturnValue: WireCoreCrypto.E2eiEnrollment!
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentClosure: ((Data) async throws -> WireCoreCrypto.E2eiEnrollment)?

    public func e2eiEnrollmentStashPop(handle: Data) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentCallsCount += 1
        e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentReceivedHandle = handle
        e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentReceivedInvocations.append(handle)
        if let error = e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentThrowableError {
            throw error
        }
        if let e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentClosure = e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentClosure {
            return try await e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentClosure(handle)
        } else {
            return e2eiEnrollmentStashPopHandleDataWireCoreCryptoE2eiEnrollmentReturnValue
        }
    }

    //MARK: - e2eiIsEnabled

    public var e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolThrowableError: (any Error)?
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolCallsCount = 0
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolCalled: Bool {
        return e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolCallsCount > 0
    }
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolReceivedCiphersuite: (WireCoreCrypto.Ciphersuite)?
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolReceivedInvocations: [(WireCoreCrypto.Ciphersuite)] = []
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolReturnValue: Bool!
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolClosure: ((WireCoreCrypto.Ciphersuite) async throws -> Bool)?

    public func e2eiIsEnabled(ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> Bool {
        e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolCallsCount += 1
        e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolReceivedCiphersuite = ciphersuite
        e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolReceivedInvocations.append(ciphersuite)
        if let error = e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolThrowableError {
            throw error
        }
        if let e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolClosure = e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolClosure {
            return try await e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolClosure(ciphersuite)
        } else {
            return e2eiIsEnabledCiphersuiteWireCoreCryptoCiphersuiteBoolReturnValue
        }
    }

    //MARK: - e2eiIsPkiEnvSetup

    public var e2eiIsPkiEnvSetupBoolCallsCount = 0
    public var e2eiIsPkiEnvSetupBoolCalled: Bool {
        return e2eiIsPkiEnvSetupBoolCallsCount > 0
    }
    public var e2eiIsPkiEnvSetupBoolReturnValue: Bool!
    public var e2eiIsPkiEnvSetupBoolClosure: (() async -> Bool)?

    public func e2eiIsPkiEnvSetup() async -> Bool {
        e2eiIsPkiEnvSetupBoolCallsCount += 1
        if let e2eiIsPkiEnvSetupBoolClosure = e2eiIsPkiEnvSetupBoolClosure {
            return await e2eiIsPkiEnvSetupBoolClosure()
        } else {
            return e2eiIsPkiEnvSetupBoolReturnValue
        }
    }

    //MARK: - e2eiMlsInitOnly

    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringThrowableError: (any Error)?
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringCallsCount = 0
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringCalled: Bool {
        return e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringCallsCount > 0
    }
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringReceivedArguments: (enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?)?
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringReceivedInvocations: [(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?)] = []
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringReturnValue: [String]?
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringClosure: ((WireCoreCrypto.E2eiEnrollment, String, UInt32?) async throws -> [String]?)?

    public func e2eiMlsInitOnly(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?) async throws -> [String]? {
        e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringCallsCount += 1
        e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringReceivedArguments = (enrollment: enrollment, certificateChain: certificateChain, nbKeyPackage: nbKeyPackage)
        e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringReceivedInvocations.append((enrollment: enrollment, certificateChain: certificateChain, nbKeyPackage: nbKeyPackage))
        if let error = e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringThrowableError {
            throw error
        }
        if let e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringClosure = e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringClosure {
            return try await e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringClosure(enrollment, certificateChain, nbKeyPackage)
        } else {
            return e2eiMlsInitOnlyEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32StringReturnValue
        }
    }

    //MARK: - e2eiNewActivationEnrollment

    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentThrowableError: (any Error)?
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCallsCount = 0
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCalled: Bool {
        return e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCallsCount > 0
    }
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedArguments: (displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)?
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedInvocations: [(displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReturnValue: WireCoreCrypto.E2eiEnrollment!
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure: ((String, String, String?, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?

    public func e2eiNewActivationEnrollment(displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCallsCount += 1
        e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedArguments = (displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite)
        e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedInvocations.append((displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite))
        if let error = e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentThrowableError {
            throw error
        }
        if let e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure = e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure {
            return try await e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure(displayName, handle, team, expirySec, ciphersuite)
        } else {
            return e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReturnValue
        }
    }

    //MARK: - e2eiNewEnrollment

    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentThrowableError: (any Error)?
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCallsCount = 0
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCalled: Bool {
        return e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCallsCount > 0
    }
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedArguments: (clientId: String, displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)?
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedInvocations: [(clientId: String, displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReturnValue: WireCoreCrypto.E2eiEnrollment!
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure: ((String, String, String, String?, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?

    public func e2eiNewEnrollment(clientId: String, displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCallsCount += 1
        e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedArguments = (clientId: clientId, displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite)
        e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedInvocations.append((clientId: clientId, displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite))
        if let error = e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentThrowableError {
            throw error
        }
        if let e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure = e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure {
            return try await e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure(clientId, displayName, handle, team, expirySec, ciphersuite)
        } else {
            return e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReturnValue
        }
    }

    //MARK: - e2eiNewRotateEnrollment

    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentThrowableError: (any Error)?
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCallsCount = 0
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCalled: Bool {
        return e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCallsCount > 0
    }
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedArguments: (displayName: String?, handle: String?, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)?
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedInvocations: [(displayName: String?, handle: String?, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite)] = []
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReturnValue: WireCoreCrypto.E2eiEnrollment!
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure: ((String?, String?, String?, UInt32, WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment)?

    public func e2eiNewRotateEnrollment(displayName: String?, handle: String?, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment {
        e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentCallsCount += 1
        e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedArguments = (displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite)
        e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReceivedInvocations.append((displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite))
        if let error = e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentThrowableError {
            throw error
        }
        if let e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure = e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure {
            return try await e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentClosure(displayName, handle, team, expirySec, ciphersuite)
        } else {
            return e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoCiphersuiteWireCoreCryptoE2eiEnrollmentReturnValue
        }
    }

    //MARK: - e2eiRegisterAcmeCa

    public var e2eiRegisterAcmeCaTrustAnchorPemStringVoidThrowableError: (any Error)?
    public var e2eiRegisterAcmeCaTrustAnchorPemStringVoidCallsCount = 0
    public var e2eiRegisterAcmeCaTrustAnchorPemStringVoidCalled: Bool {
        return e2eiRegisterAcmeCaTrustAnchorPemStringVoidCallsCount > 0
    }
    public var e2eiRegisterAcmeCaTrustAnchorPemStringVoidReceivedTrustAnchorPem: (String)?
    public var e2eiRegisterAcmeCaTrustAnchorPemStringVoidReceivedInvocations: [(String)] = []
    public var e2eiRegisterAcmeCaTrustAnchorPemStringVoidClosure: ((String) async throws -> Void)?

    public func e2eiRegisterAcmeCa(trustAnchorPem: String) async throws {
        e2eiRegisterAcmeCaTrustAnchorPemStringVoidCallsCount += 1
        e2eiRegisterAcmeCaTrustAnchorPemStringVoidReceivedTrustAnchorPem = trustAnchorPem
        e2eiRegisterAcmeCaTrustAnchorPemStringVoidReceivedInvocations.append(trustAnchorPem)
        if let error = e2eiRegisterAcmeCaTrustAnchorPemStringVoidThrowableError {
            throw error
        }
        try await e2eiRegisterAcmeCaTrustAnchorPemStringVoidClosure?(trustAnchorPem)
    }

    //MARK: - e2eiRegisterCrl

    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationThrowableError: (any Error)?
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationCallsCount = 0
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationCalled: Bool {
        return e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationCallsCount > 0
    }
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationReceivedArguments: (crlDp: String, crlDer: Data)?
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationReceivedInvocations: [(crlDp: String, crlDer: Data)] = []
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationReturnValue: WireCoreCrypto.CrlRegistration!
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationClosure: ((String, Data) async throws -> WireCoreCrypto.CrlRegistration)?

    public func e2eiRegisterCrl(crlDp: String, crlDer: Data) async throws -> WireCoreCrypto.CrlRegistration {
        e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationCallsCount += 1
        e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationReceivedArguments = (crlDp: crlDp, crlDer: crlDer)
        e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationReceivedInvocations.append((crlDp: crlDp, crlDer: crlDer))
        if let error = e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationThrowableError {
            throw error
        }
        if let e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationClosure = e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationClosure {
            return try await e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationClosure(crlDp, crlDer)
        } else {
            return e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoCrlRegistrationReturnValue
        }
    }

    //MARK: - e2eiRegisterIntermediateCa

    public var e2eiRegisterIntermediateCaCertPemStringStringThrowableError: (any Error)?
    public var e2eiRegisterIntermediateCaCertPemStringStringCallsCount = 0
    public var e2eiRegisterIntermediateCaCertPemStringStringCalled: Bool {
        return e2eiRegisterIntermediateCaCertPemStringStringCallsCount > 0
    }
    public var e2eiRegisterIntermediateCaCertPemStringStringReceivedCertPem: (String)?
    public var e2eiRegisterIntermediateCaCertPemStringStringReceivedInvocations: [(String)] = []
    public var e2eiRegisterIntermediateCaCertPemStringStringReturnValue: [String]?
    public var e2eiRegisterIntermediateCaCertPemStringStringClosure: ((String) async throws -> [String]?)?

    public func e2eiRegisterIntermediateCa(certPem: String) async throws -> [String]? {
        e2eiRegisterIntermediateCaCertPemStringStringCallsCount += 1
        e2eiRegisterIntermediateCaCertPemStringStringReceivedCertPem = certPem
        e2eiRegisterIntermediateCaCertPemStringStringReceivedInvocations.append(certPem)
        if let error = e2eiRegisterIntermediateCaCertPemStringStringThrowableError {
            throw error
        }
        if let e2eiRegisterIntermediateCaCertPemStringStringClosure = e2eiRegisterIntermediateCaCertPemStringStringClosure {
            return try await e2eiRegisterIntermediateCaCertPemStringStringClosure(certPem)
        } else {
            return e2eiRegisterIntermediateCaCertPemStringStringReturnValue
        }
    }

    //MARK: - e2eiRotateAll

    public var e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleThrowableError: (any Error)?
    public var e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleCallsCount = 0
    public var e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleCalled: Bool {
        return e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleCallsCount > 0
    }
    public var e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleReceivedArguments: (enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, newKeyPackagesCount: UInt32)?
    public var e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleReceivedInvocations: [(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, newKeyPackagesCount: UInt32)] = []
    public var e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleReturnValue: WireCoreCrypto.RotateBundle!
    public var e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleClosure: ((WireCoreCrypto.E2eiEnrollment, String, UInt32) async throws -> WireCoreCrypto.RotateBundle)?

    public func e2eiRotateAll(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, newKeyPackagesCount: UInt32) async throws -> WireCoreCrypto.RotateBundle {
        e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleCallsCount += 1
        e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleReceivedArguments = (enrollment: enrollment, certificateChain: certificateChain, newKeyPackagesCount: newKeyPackagesCount)
        e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleReceivedInvocations.append((enrollment: enrollment, certificateChain: certificateChain, newKeyPackagesCount: newKeyPackagesCount))
        if let error = e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleThrowableError {
            throw error
        }
        if let e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleClosure = e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleClosure {
            return try await e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleClosure(enrollment, certificateChain, newKeyPackagesCount)
        } else {
            return e2eiRotateAllEnrollmentWireCoreCryptoE2eiEnrollmentCertificateChainStringNewKeyPackagesCountUInt32WireCoreCryptoRotateBundleReturnValue
        }
    }

    //MARK: - encryptMessage

    public var encryptMessageConversationIdDataMessageDataDataThrowableError: (any Error)?
    public var encryptMessageConversationIdDataMessageDataDataCallsCount = 0
    public var encryptMessageConversationIdDataMessageDataDataCalled: Bool {
        return encryptMessageConversationIdDataMessageDataDataCallsCount > 0
    }
    public var encryptMessageConversationIdDataMessageDataDataReceivedArguments: (conversationId: Data, message: Data)?
    public var encryptMessageConversationIdDataMessageDataDataReceivedInvocations: [(conversationId: Data, message: Data)] = []
    public var encryptMessageConversationIdDataMessageDataDataReturnValue: Data!
    public var encryptMessageConversationIdDataMessageDataDataClosure: ((Data, Data) async throws -> Data)?

    public func encryptMessage(conversationId: Data, message: Data) async throws -> Data {
        encryptMessageConversationIdDataMessageDataDataCallsCount += 1
        encryptMessageConversationIdDataMessageDataDataReceivedArguments = (conversationId: conversationId, message: message)
        encryptMessageConversationIdDataMessageDataDataReceivedInvocations.append((conversationId: conversationId, message: message))
        if let error = encryptMessageConversationIdDataMessageDataDataThrowableError {
            throw error
        }
        if let encryptMessageConversationIdDataMessageDataDataClosure = encryptMessageConversationIdDataMessageDataDataClosure {
            return try await encryptMessageConversationIdDataMessageDataDataClosure(conversationId, message)
        } else {
            return encryptMessageConversationIdDataMessageDataDataReturnValue
        }
    }

    //MARK: - exportSecretKey

    public var exportSecretKeyConversationIdDataKeyLengthUInt32DataThrowableError: (any Error)?
    public var exportSecretKeyConversationIdDataKeyLengthUInt32DataCallsCount = 0
    public var exportSecretKeyConversationIdDataKeyLengthUInt32DataCalled: Bool {
        return exportSecretKeyConversationIdDataKeyLengthUInt32DataCallsCount > 0
    }
    public var exportSecretKeyConversationIdDataKeyLengthUInt32DataReceivedArguments: (conversationId: Data, keyLength: UInt32)?
    public var exportSecretKeyConversationIdDataKeyLengthUInt32DataReceivedInvocations: [(conversationId: Data, keyLength: UInt32)] = []
    public var exportSecretKeyConversationIdDataKeyLengthUInt32DataReturnValue: Data!
    public var exportSecretKeyConversationIdDataKeyLengthUInt32DataClosure: ((Data, UInt32) async throws -> Data)?

    public func exportSecretKey(conversationId: Data, keyLength: UInt32) async throws -> Data {
        exportSecretKeyConversationIdDataKeyLengthUInt32DataCallsCount += 1
        exportSecretKeyConversationIdDataKeyLengthUInt32DataReceivedArguments = (conversationId: conversationId, keyLength: keyLength)
        exportSecretKeyConversationIdDataKeyLengthUInt32DataReceivedInvocations.append((conversationId: conversationId, keyLength: keyLength))
        if let error = exportSecretKeyConversationIdDataKeyLengthUInt32DataThrowableError {
            throw error
        }
        if let exportSecretKeyConversationIdDataKeyLengthUInt32DataClosure = exportSecretKeyConversationIdDataKeyLengthUInt32DataClosure {
            return try await exportSecretKeyConversationIdDataKeyLengthUInt32DataClosure(conversationId, keyLength)
        } else {
            return exportSecretKeyConversationIdDataKeyLengthUInt32DataReturnValue
        }
    }

    //MARK: - getClientIds

    public var getClientIdsConversationIdDataWireCoreCryptoClientIdThrowableError: (any Error)?
    public var getClientIdsConversationIdDataWireCoreCryptoClientIdCallsCount = 0
    public var getClientIdsConversationIdDataWireCoreCryptoClientIdCalled: Bool {
        return getClientIdsConversationIdDataWireCoreCryptoClientIdCallsCount > 0
    }
    public var getClientIdsConversationIdDataWireCoreCryptoClientIdReceivedConversationId: (Data)?
    public var getClientIdsConversationIdDataWireCoreCryptoClientIdReceivedInvocations: [(Data)] = []
    public var getClientIdsConversationIdDataWireCoreCryptoClientIdReturnValue: [WireCoreCrypto.ClientId]!
    public var getClientIdsConversationIdDataWireCoreCryptoClientIdClosure: ((Data) async throws -> [WireCoreCrypto.ClientId])?

    public func getClientIds(conversationId: Data) async throws -> [WireCoreCrypto.ClientId] {
        getClientIdsConversationIdDataWireCoreCryptoClientIdCallsCount += 1
        getClientIdsConversationIdDataWireCoreCryptoClientIdReceivedConversationId = conversationId
        getClientIdsConversationIdDataWireCoreCryptoClientIdReceivedInvocations.append(conversationId)
        if let error = getClientIdsConversationIdDataWireCoreCryptoClientIdThrowableError {
            throw error
        }
        if let getClientIdsConversationIdDataWireCoreCryptoClientIdClosure = getClientIdsConversationIdDataWireCoreCryptoClientIdClosure {
            return try await getClientIdsConversationIdDataWireCoreCryptoClientIdClosure(conversationId)
        } else {
            return getClientIdsConversationIdDataWireCoreCryptoClientIdReturnValue
        }
    }

    //MARK: - getCredentialInUse

    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateThrowableError: (any Error)?
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateCallsCount = 0
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateCalled: Bool {
        return getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateCallsCount > 0
    }
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateReceivedArguments: (groupInfo: Data, credentialType: WireCoreCrypto.MlsCredentialType)?
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateReceivedInvocations: [(groupInfo: Data, credentialType: WireCoreCrypto.MlsCredentialType)] = []
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateReturnValue: WireCoreCrypto.E2eiConversationState!
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateClosure: ((Data, WireCoreCrypto.MlsCredentialType) async throws -> WireCoreCrypto.E2eiConversationState)?

    public func getCredentialInUse(groupInfo: Data, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> WireCoreCrypto.E2eiConversationState {
        getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateCallsCount += 1
        getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateReceivedArguments = (groupInfo: groupInfo, credentialType: credentialType)
        getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateReceivedInvocations.append((groupInfo: groupInfo, credentialType: credentialType))
        if let error = getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateThrowableError {
            throw error
        }
        if let getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateClosure = getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateClosure {
            return try await getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateClosure(groupInfo, credentialType)
        } else {
            return getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoE2eiConversationStateReturnValue
        }
    }

    //MARK: - getDeviceIdentities

    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityThrowableError: (any Error)?
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityCallsCount = 0
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityCalled: Bool {
        return getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityCallsCount > 0
    }
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityReceivedArguments: (conversationId: Data, deviceIds: [WireCoreCrypto.ClientId])?
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityReceivedInvocations: [(conversationId: Data, deviceIds: [WireCoreCrypto.ClientId])] = []
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityReturnValue: [WireCoreCrypto.WireIdentity]!
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityClosure: ((Data, [WireCoreCrypto.ClientId]) async throws -> [WireCoreCrypto.WireIdentity])?

    public func getDeviceIdentities(conversationId: Data, deviceIds: [WireCoreCrypto.ClientId]) async throws -> [WireCoreCrypto.WireIdentity] {
        getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityCallsCount += 1
        getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityReceivedArguments = (conversationId: conversationId, deviceIds: deviceIds)
        getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityReceivedInvocations.append((conversationId: conversationId, deviceIds: deviceIds))
        if let error = getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityThrowableError {
            throw error
        }
        if let getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityClosure = getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityClosure {
            return try await getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityClosure(conversationId, deviceIds)
        } else {
            return getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoClientIdWireCoreCryptoWireIdentityReturnValue
        }
    }

    //MARK: - getExternalSender

    public var getExternalSenderConversationIdDataDataThrowableError: (any Error)?
    public var getExternalSenderConversationIdDataDataCallsCount = 0
    public var getExternalSenderConversationIdDataDataCalled: Bool {
        return getExternalSenderConversationIdDataDataCallsCount > 0
    }
    public var getExternalSenderConversationIdDataDataReceivedConversationId: (Data)?
    public var getExternalSenderConversationIdDataDataReceivedInvocations: [(Data)] = []
    public var getExternalSenderConversationIdDataDataReturnValue: Data!
    public var getExternalSenderConversationIdDataDataClosure: ((Data) async throws -> Data)?

    public func getExternalSender(conversationId: Data) async throws -> Data {
        getExternalSenderConversationIdDataDataCallsCount += 1
        getExternalSenderConversationIdDataDataReceivedConversationId = conversationId
        getExternalSenderConversationIdDataDataReceivedInvocations.append(conversationId)
        if let error = getExternalSenderConversationIdDataDataThrowableError {
            throw error
        }
        if let getExternalSenderConversationIdDataDataClosure = getExternalSenderConversationIdDataDataClosure {
            return try await getExternalSenderConversationIdDataDataClosure(conversationId)
        } else {
            return getExternalSenderConversationIdDataDataReturnValue
        }
    }

    //MARK: - getUserIdentities

    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityThrowableError: (any Error)?
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityCallsCount = 0
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityCalled: Bool {
        return getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityCallsCount > 0
    }
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityReceivedArguments: (conversationId: Data, userIds: [String])?
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityReceivedInvocations: [(conversationId: Data, userIds: [String])] = []
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityReturnValue: [String: [WireCoreCrypto.WireIdentity]]!
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityClosure: ((Data, [String]) async throws -> [String: [WireCoreCrypto.WireIdentity]])?

    public func getUserIdentities(conversationId: Data, userIds: [String]) async throws -> [String: [WireCoreCrypto.WireIdentity]] {
        getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityCallsCount += 1
        getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityReceivedArguments = (conversationId: conversationId, userIds: userIds)
        getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityReceivedInvocations.append((conversationId: conversationId, userIds: userIds))
        if let error = getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityThrowableError {
            throw error
        }
        if let getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityClosure = getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityClosure {
            return try await getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityClosure(conversationId, userIds)
        } else {
            return getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoWireIdentityReturnValue
        }
    }

    //MARK: - joinByExternalCommit

    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleThrowableError: (any Error)?
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleCallsCount = 0
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleCalled: Bool {
        return joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleCallsCount > 0
    }
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleReceivedArguments: (groupInfo: Data, customConfiguration: WireCoreCrypto.CustomConfiguration, credentialType: WireCoreCrypto.MlsCredentialType)?
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleReceivedInvocations: [(groupInfo: Data, customConfiguration: WireCoreCrypto.CustomConfiguration, credentialType: WireCoreCrypto.MlsCredentialType)] = []
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleReturnValue: WireCoreCrypto.ConversationInitBundle!
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleClosure: ((Data, WireCoreCrypto.CustomConfiguration, WireCoreCrypto.MlsCredentialType) async throws -> WireCoreCrypto.ConversationInitBundle)?

    public func joinByExternalCommit(groupInfo: Data, customConfiguration: WireCoreCrypto.CustomConfiguration, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> WireCoreCrypto.ConversationInitBundle {
        joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleCallsCount += 1
        joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleReceivedArguments = (groupInfo: groupInfo, customConfiguration: customConfiguration, credentialType: credentialType)
        joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleReceivedInvocations.append((groupInfo: groupInfo, customConfiguration: customConfiguration, credentialType: credentialType))
        if let error = joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleThrowableError {
            throw error
        }
        if let joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleClosure = joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleClosure {
            return try await joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleClosure(groupInfo, customConfiguration, credentialType)
        } else {
            return joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoCustomConfigurationCredentialTypeWireCoreCryptoMlsCredentialTypeWireCoreCryptoConversationInitBundleReturnValue
        }
    }

    //MARK: - markConversationAsChildOf

    public var markConversationAsChildOfChildIdDataParentIdDataVoidThrowableError: (any Error)?
    public var markConversationAsChildOfChildIdDataParentIdDataVoidCallsCount = 0
    public var markConversationAsChildOfChildIdDataParentIdDataVoidCalled: Bool {
        return markConversationAsChildOfChildIdDataParentIdDataVoidCallsCount > 0
    }
    public var markConversationAsChildOfChildIdDataParentIdDataVoidReceivedArguments: (childId: Data, parentId: Data)?
    public var markConversationAsChildOfChildIdDataParentIdDataVoidReceivedInvocations: [(childId: Data, parentId: Data)] = []
    public var markConversationAsChildOfChildIdDataParentIdDataVoidClosure: ((Data, Data) async throws -> Void)?

    public func markConversationAsChildOf(childId: Data, parentId: Data) async throws {
        markConversationAsChildOfChildIdDataParentIdDataVoidCallsCount += 1
        markConversationAsChildOfChildIdDataParentIdDataVoidReceivedArguments = (childId: childId, parentId: parentId)
        markConversationAsChildOfChildIdDataParentIdDataVoidReceivedInvocations.append((childId: childId, parentId: parentId))
        if let error = markConversationAsChildOfChildIdDataParentIdDataVoidThrowableError {
            throw error
        }
        try await markConversationAsChildOfChildIdDataParentIdDataVoidClosure?(childId, parentId)
    }

    //MARK: - mergePendingGroupFromExternalCommit

    public var mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageThrowableError: (any Error)?
    public var mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageCallsCount = 0
    public var mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageCalled: Bool {
        return mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageCallsCount > 0
    }
    public var mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageReceivedConversationId: (Data)?
    public var mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageReceivedInvocations: [(Data)] = []
    public var mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageReturnValue: [WireCoreCrypto.BufferedDecryptedMessage]?
    public var mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageClosure: ((Data) async throws -> [WireCoreCrypto.BufferedDecryptedMessage]?)?

    public func mergePendingGroupFromExternalCommit(conversationId: Data) async throws -> [WireCoreCrypto.BufferedDecryptedMessage]? {
        mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageCallsCount += 1
        mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageReceivedConversationId = conversationId
        mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageReceivedInvocations.append(conversationId)
        if let error = mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageThrowableError {
            throw error
        }
        if let mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageClosure = mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageClosure {
            return try await mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageClosure(conversationId)
        } else {
            return mergePendingGroupFromExternalCommitConversationIdDataWireCoreCryptoBufferedDecryptedMessageReturnValue
        }
    }

    //MARK: - mlsGenerateKeypairs

    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdThrowableError: (any Error)?
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdCallsCount = 0
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdCalled: Bool {
        return mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdCallsCount > 0
    }
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdReceivedCiphersuites: (WireCoreCrypto.Ciphersuites)?
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdReceivedInvocations: [(WireCoreCrypto.Ciphersuites)] = []
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdReturnValue: [WireCoreCrypto.ClientId]!
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdClosure: ((WireCoreCrypto.Ciphersuites) async throws -> [WireCoreCrypto.ClientId])?

    public func mlsGenerateKeypairs(ciphersuites: WireCoreCrypto.Ciphersuites) async throws -> [WireCoreCrypto.ClientId] {
        mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdCallsCount += 1
        mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdReceivedCiphersuites = ciphersuites
        mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdReceivedInvocations.append(ciphersuites)
        if let error = mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdThrowableError {
            throw error
        }
        if let mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdClosure = mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdClosure {
            return try await mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdClosure(ciphersuites)
        } else {
            return mlsGenerateKeypairsCiphersuitesWireCoreCryptoCiphersuitesWireCoreCryptoClientIdReturnValue
        }
    }

    //MARK: - mlsInit

    public var mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidThrowableError: (any Error)?
    public var mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidCallsCount = 0
    public var mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidCalled: Bool {
        return mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidCallsCount > 0
    }
    public var mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidReceivedArguments: (clientId: WireCoreCrypto.ClientId, ciphersuites: WireCoreCrypto.Ciphersuites, nbKeyPackage: UInt32?)?
    public var mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidReceivedInvocations: [(clientId: WireCoreCrypto.ClientId, ciphersuites: WireCoreCrypto.Ciphersuites, nbKeyPackage: UInt32?)] = []
    public var mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidClosure: ((WireCoreCrypto.ClientId, WireCoreCrypto.Ciphersuites, UInt32?) async throws -> Void)?

    public func mlsInit(clientId: WireCoreCrypto.ClientId, ciphersuites: WireCoreCrypto.Ciphersuites, nbKeyPackage: UInt32?) async throws {
        mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidCallsCount += 1
        mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidReceivedArguments = (clientId: clientId, ciphersuites: ciphersuites, nbKeyPackage: nbKeyPackage)
        mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidReceivedInvocations.append((clientId: clientId, ciphersuites: ciphersuites, nbKeyPackage: nbKeyPackage))
        if let error = mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidThrowableError {
            throw error
        }
        try await mlsInitClientIdWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesNbKeyPackageUInt32VoidClosure?(clientId, ciphersuites, nbKeyPackage)
    }

    //MARK: - mlsInitWithClientId

    public var mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidThrowableError: (any Error)?
    public var mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidCallsCount = 0
    public var mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidCalled: Bool {
        return mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidCallsCount > 0
    }
    public var mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidReceivedArguments: (clientId: WireCoreCrypto.ClientId, tmpClientIds: [WireCoreCrypto.ClientId], ciphersuites: WireCoreCrypto.Ciphersuites)?
    public var mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidReceivedInvocations: [(clientId: WireCoreCrypto.ClientId, tmpClientIds: [WireCoreCrypto.ClientId], ciphersuites: WireCoreCrypto.Ciphersuites)] = []
    public var mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidClosure: ((WireCoreCrypto.ClientId, [WireCoreCrypto.ClientId], WireCoreCrypto.Ciphersuites) async throws -> Void)?

    public func mlsInitWithClientId(clientId: WireCoreCrypto.ClientId, tmpClientIds: [WireCoreCrypto.ClientId], ciphersuites: WireCoreCrypto.Ciphersuites) async throws {
        mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidCallsCount += 1
        mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidReceivedArguments = (clientId: clientId, tmpClientIds: tmpClientIds, ciphersuites: ciphersuites)
        mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidReceivedInvocations.append((clientId: clientId, tmpClientIds: tmpClientIds, ciphersuites: ciphersuites))
        if let error = mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidThrowableError {
            throw error
        }
        try await mlsInitWithClientIdClientIdWireCoreCryptoClientIdTmpClientIdsWireCoreCryptoClientIdCiphersuitesWireCoreCryptoCiphersuitesVoidClosure?(clientId, tmpClientIds, ciphersuites)
    }

    //MARK: - newAddProposal

    public var newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleThrowableError: (any Error)?
    public var newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleCallsCount = 0
    public var newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleCalled: Bool {
        return newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleCallsCount > 0
    }
    public var newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleReceivedArguments: (conversationId: Data, keypackage: Data)?
    public var newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleReceivedInvocations: [(conversationId: Data, keypackage: Data)] = []
    public var newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleReturnValue: WireCoreCrypto.ProposalBundle!
    public var newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleClosure: ((Data, Data) async throws -> WireCoreCrypto.ProposalBundle)?

    public func newAddProposal(conversationId: Data, keypackage: Data) async throws -> WireCoreCrypto.ProposalBundle {
        newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleCallsCount += 1
        newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleReceivedArguments = (conversationId: conversationId, keypackage: keypackage)
        newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleReceivedInvocations.append((conversationId: conversationId, keypackage: keypackage))
        if let error = newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleThrowableError {
            throw error
        }
        if let newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleClosure = newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleClosure {
            return try await newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleClosure(conversationId, keypackage)
        } else {
            return newAddProposalConversationIdDataKeypackageDataWireCoreCryptoProposalBundleReturnValue
        }
    }

    //MARK: - newExternalAddProposal

    public var newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataThrowableError: (any Error)?
    public var newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataCallsCount = 0
    public var newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataCalled: Bool {
        return newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataCallsCount > 0
    }
    public var newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReceivedArguments: (conversationId: Data, epoch: UInt64, ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType)?
    public var newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReceivedInvocations: [(conversationId: Data, epoch: UInt64, ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType)] = []
    public var newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReturnValue: Data!
    public var newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataClosure: ((Data, UInt64, WireCoreCrypto.Ciphersuite, WireCoreCrypto.MlsCredentialType) async throws -> Data)?

    public func newExternalAddProposal(conversationId: Data, epoch: UInt64, ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> Data {
        newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataCallsCount += 1
        newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReceivedArguments = (conversationId: conversationId, epoch: epoch, ciphersuite: ciphersuite, credentialType: credentialType)
        newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReceivedInvocations.append((conversationId: conversationId, epoch: epoch, ciphersuite: ciphersuite, credentialType: credentialType))
        if let error = newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataThrowableError {
            throw error
        }
        if let newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataClosure = newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataClosure {
            return try await newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataClosure(conversationId, epoch, ciphersuite, credentialType)
        } else {
            return newExternalAddProposalConversationIdDataEpochUInt64CiphersuiteWireCoreCryptoCiphersuiteCredentialTypeWireCoreCryptoMlsCredentialTypeDataReturnValue
        }
    }

    //MARK: - newRemoveProposal

    public var newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleThrowableError: (any Error)?
    public var newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleCallsCount = 0
    public var newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleCalled: Bool {
        return newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleCallsCount > 0
    }
    public var newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleReceivedArguments: (conversationId: Data, clientId: WireCoreCrypto.ClientId)?
    public var newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleReceivedInvocations: [(conversationId: Data, clientId: WireCoreCrypto.ClientId)] = []
    public var newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleReturnValue: WireCoreCrypto.ProposalBundle!
    public var newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleClosure: ((Data, WireCoreCrypto.ClientId) async throws -> WireCoreCrypto.ProposalBundle)?

    public func newRemoveProposal(conversationId: Data, clientId: WireCoreCrypto.ClientId) async throws -> WireCoreCrypto.ProposalBundle {
        newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleCallsCount += 1
        newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleReceivedArguments = (conversationId: conversationId, clientId: clientId)
        newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleReceivedInvocations.append((conversationId: conversationId, clientId: clientId))
        if let error = newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleThrowableError {
            throw error
        }
        if let newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleClosure = newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleClosure {
            return try await newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleClosure(conversationId, clientId)
        } else {
            return newRemoveProposalConversationIdDataClientIdWireCoreCryptoClientIdWireCoreCryptoProposalBundleReturnValue
        }
    }

    //MARK: - newUpdateProposal

    public var newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleThrowableError: (any Error)?
    public var newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleCallsCount = 0
    public var newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleCalled: Bool {
        return newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleCallsCount > 0
    }
    public var newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleReceivedConversationId: (Data)?
    public var newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleReceivedInvocations: [(Data)] = []
    public var newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleReturnValue: WireCoreCrypto.ProposalBundle!
    public var newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleClosure: ((Data) async throws -> WireCoreCrypto.ProposalBundle)?

    public func newUpdateProposal(conversationId: Data) async throws -> WireCoreCrypto.ProposalBundle {
        newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleCallsCount += 1
        newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleReceivedConversationId = conversationId
        newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleReceivedInvocations.append(conversationId)
        if let error = newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleThrowableError {
            throw error
        }
        if let newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleClosure = newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleClosure {
            return try await newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleClosure(conversationId)
        } else {
            return newUpdateProposalConversationIdDataWireCoreCryptoProposalBundleReturnValue
        }
    }

    //MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleThrowableError: (any Error)?
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleCallsCount = 0
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleCalled: Bool {
        return processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleCallsCount > 0
    }
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleReceivedArguments: (welcomeMessage: Data, customConfiguration: WireCoreCrypto.CustomConfiguration)?
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleReceivedInvocations: [(welcomeMessage: Data, customConfiguration: WireCoreCrypto.CustomConfiguration)] = []
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleReturnValue: WireCoreCrypto.WelcomeBundle!
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleClosure: ((Data, WireCoreCrypto.CustomConfiguration) async throws -> WireCoreCrypto.WelcomeBundle)?

    public func processWelcomeMessage(welcomeMessage: Data, customConfiguration: WireCoreCrypto.CustomConfiguration) async throws -> WireCoreCrypto.WelcomeBundle {
        processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleCallsCount += 1
        processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleReceivedArguments = (welcomeMessage: welcomeMessage, customConfiguration: customConfiguration)
        processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleReceivedInvocations.append((welcomeMessage: welcomeMessage, customConfiguration: customConfiguration))
        if let error = processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleThrowableError {
            throw error
        }
        if let processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleClosure = processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleClosure {
            return try await processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleClosure(welcomeMessage, customConfiguration)
        } else {
            return processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoCustomConfigurationWireCoreCryptoWelcomeBundleReturnValue
        }
    }

    //MARK: - proteusCryptoboxMigrate

    public var proteusCryptoboxMigratePathStringVoidThrowableError: (any Error)?
    public var proteusCryptoboxMigratePathStringVoidCallsCount = 0
    public var proteusCryptoboxMigratePathStringVoidCalled: Bool {
        return proteusCryptoboxMigratePathStringVoidCallsCount > 0
    }
    public var proteusCryptoboxMigratePathStringVoidReceivedPath: (String)?
    public var proteusCryptoboxMigratePathStringVoidReceivedInvocations: [(String)] = []
    public var proteusCryptoboxMigratePathStringVoidClosure: ((String) async throws -> Void)?

    public func proteusCryptoboxMigrate(path: String) async throws {
        proteusCryptoboxMigratePathStringVoidCallsCount += 1
        proteusCryptoboxMigratePathStringVoidReceivedPath = path
        proteusCryptoboxMigratePathStringVoidReceivedInvocations.append(path)
        if let error = proteusCryptoboxMigratePathStringVoidThrowableError {
            throw error
        }
        try await proteusCryptoboxMigratePathStringVoidClosure?(path)
    }

    //MARK: - proteusDecrypt

    public var proteusDecryptSessionIdStringCiphertextDataDataThrowableError: (any Error)?
    public var proteusDecryptSessionIdStringCiphertextDataDataCallsCount = 0
    public var proteusDecryptSessionIdStringCiphertextDataDataCalled: Bool {
        return proteusDecryptSessionIdStringCiphertextDataDataCallsCount > 0
    }
    public var proteusDecryptSessionIdStringCiphertextDataDataReceivedArguments: (sessionId: String, ciphertext: Data)?
    public var proteusDecryptSessionIdStringCiphertextDataDataReceivedInvocations: [(sessionId: String, ciphertext: Data)] = []
    public var proteusDecryptSessionIdStringCiphertextDataDataReturnValue: Data!
    public var proteusDecryptSessionIdStringCiphertextDataDataClosure: ((String, Data) async throws -> Data)?

    public func proteusDecrypt(sessionId: String, ciphertext: Data) async throws -> Data {
        proteusDecryptSessionIdStringCiphertextDataDataCallsCount += 1
        proteusDecryptSessionIdStringCiphertextDataDataReceivedArguments = (sessionId: sessionId, ciphertext: ciphertext)
        proteusDecryptSessionIdStringCiphertextDataDataReceivedInvocations.append((sessionId: sessionId, ciphertext: ciphertext))
        if let error = proteusDecryptSessionIdStringCiphertextDataDataThrowableError {
            throw error
        }
        if let proteusDecryptSessionIdStringCiphertextDataDataClosure = proteusDecryptSessionIdStringCiphertextDataDataClosure {
            return try await proteusDecryptSessionIdStringCiphertextDataDataClosure(sessionId, ciphertext)
        } else {
            return proteusDecryptSessionIdStringCiphertextDataDataReturnValue
        }
    }

    //MARK: - proteusEncrypt

    public var proteusEncryptSessionIdStringPlaintextDataDataThrowableError: (any Error)?
    public var proteusEncryptSessionIdStringPlaintextDataDataCallsCount = 0
    public var proteusEncryptSessionIdStringPlaintextDataDataCalled: Bool {
        return proteusEncryptSessionIdStringPlaintextDataDataCallsCount > 0
    }
    public var proteusEncryptSessionIdStringPlaintextDataDataReceivedArguments: (sessionId: String, plaintext: Data)?
    public var proteusEncryptSessionIdStringPlaintextDataDataReceivedInvocations: [(sessionId: String, plaintext: Data)] = []
    public var proteusEncryptSessionIdStringPlaintextDataDataReturnValue: Data!
    public var proteusEncryptSessionIdStringPlaintextDataDataClosure: ((String, Data) async throws -> Data)?

    public func proteusEncrypt(sessionId: String, plaintext: Data) async throws -> Data {
        proteusEncryptSessionIdStringPlaintextDataDataCallsCount += 1
        proteusEncryptSessionIdStringPlaintextDataDataReceivedArguments = (sessionId: sessionId, plaintext: plaintext)
        proteusEncryptSessionIdStringPlaintextDataDataReceivedInvocations.append((sessionId: sessionId, plaintext: plaintext))
        if let error = proteusEncryptSessionIdStringPlaintextDataDataThrowableError {
            throw error
        }
        if let proteusEncryptSessionIdStringPlaintextDataDataClosure = proteusEncryptSessionIdStringPlaintextDataDataClosure {
            return try await proteusEncryptSessionIdStringPlaintextDataDataClosure(sessionId, plaintext)
        } else {
            return proteusEncryptSessionIdStringPlaintextDataDataReturnValue
        }
    }

    //MARK: - proteusEncryptBatched

    public var proteusEncryptBatchedSessionsStringPlaintextDataStringDataThrowableError: (any Error)?
    public var proteusEncryptBatchedSessionsStringPlaintextDataStringDataCallsCount = 0
    public var proteusEncryptBatchedSessionsStringPlaintextDataStringDataCalled: Bool {
        return proteusEncryptBatchedSessionsStringPlaintextDataStringDataCallsCount > 0
    }
    public var proteusEncryptBatchedSessionsStringPlaintextDataStringDataReceivedArguments: (sessions: [String], plaintext: Data)?
    public var proteusEncryptBatchedSessionsStringPlaintextDataStringDataReceivedInvocations: [(sessions: [String], plaintext: Data)] = []
    public var proteusEncryptBatchedSessionsStringPlaintextDataStringDataReturnValue: [String: Data]!
    public var proteusEncryptBatchedSessionsStringPlaintextDataStringDataClosure: (([String], Data) async throws -> [String: Data])?

    public func proteusEncryptBatched(sessions: [String], plaintext: Data) async throws -> [String: Data] {
        proteusEncryptBatchedSessionsStringPlaintextDataStringDataCallsCount += 1
        proteusEncryptBatchedSessionsStringPlaintextDataStringDataReceivedArguments = (sessions: sessions, plaintext: plaintext)
        proteusEncryptBatchedSessionsStringPlaintextDataStringDataReceivedInvocations.append((sessions: sessions, plaintext: plaintext))
        if let error = proteusEncryptBatchedSessionsStringPlaintextDataStringDataThrowableError {
            throw error
        }
        if let proteusEncryptBatchedSessionsStringPlaintextDataStringDataClosure = proteusEncryptBatchedSessionsStringPlaintextDataStringDataClosure {
            return try await proteusEncryptBatchedSessionsStringPlaintextDataStringDataClosure(sessions, plaintext)
        } else {
            return proteusEncryptBatchedSessionsStringPlaintextDataStringDataReturnValue
        }
    }

    //MARK: - proteusFingerprint

    public var proteusFingerprintStringThrowableError: (any Error)?
    public var proteusFingerprintStringCallsCount = 0
    public var proteusFingerprintStringCalled: Bool {
        return proteusFingerprintStringCallsCount > 0
    }
    public var proteusFingerprintStringReturnValue: String!
    public var proteusFingerprintStringClosure: (() async throws -> String)?

    public func proteusFingerprint() async throws -> String {
        proteusFingerprintStringCallsCount += 1
        if let error = proteusFingerprintStringThrowableError {
            throw error
        }
        if let proteusFingerprintStringClosure = proteusFingerprintStringClosure {
            return try await proteusFingerprintStringClosure()
        } else {
            return proteusFingerprintStringReturnValue
        }
    }

    //MARK: - proteusFingerprintLocal

    public var proteusFingerprintLocalSessionIdStringStringThrowableError: (any Error)?
    public var proteusFingerprintLocalSessionIdStringStringCallsCount = 0
    public var proteusFingerprintLocalSessionIdStringStringCalled: Bool {
        return proteusFingerprintLocalSessionIdStringStringCallsCount > 0
    }
    public var proteusFingerprintLocalSessionIdStringStringReceivedSessionId: (String)?
    public var proteusFingerprintLocalSessionIdStringStringReceivedInvocations: [(String)] = []
    public var proteusFingerprintLocalSessionIdStringStringReturnValue: String!
    public var proteusFingerprintLocalSessionIdStringStringClosure: ((String) async throws -> String)?

    public func proteusFingerprintLocal(sessionId: String) async throws -> String {
        proteusFingerprintLocalSessionIdStringStringCallsCount += 1
        proteusFingerprintLocalSessionIdStringStringReceivedSessionId = sessionId
        proteusFingerprintLocalSessionIdStringStringReceivedInvocations.append(sessionId)
        if let error = proteusFingerprintLocalSessionIdStringStringThrowableError {
            throw error
        }
        if let proteusFingerprintLocalSessionIdStringStringClosure = proteusFingerprintLocalSessionIdStringStringClosure {
            return try await proteusFingerprintLocalSessionIdStringStringClosure(sessionId)
        } else {
            return proteusFingerprintLocalSessionIdStringStringReturnValue
        }
    }

    //MARK: - proteusFingerprintPrekeybundle

    public var proteusFingerprintPrekeybundlePrekeyDataStringThrowableError: (any Error)?
    public var proteusFingerprintPrekeybundlePrekeyDataStringCallsCount = 0
    public var proteusFingerprintPrekeybundlePrekeyDataStringCalled: Bool {
        return proteusFingerprintPrekeybundlePrekeyDataStringCallsCount > 0
    }
    public var proteusFingerprintPrekeybundlePrekeyDataStringReceivedPrekey: (Data)?
    public var proteusFingerprintPrekeybundlePrekeyDataStringReceivedInvocations: [(Data)] = []
    public var proteusFingerprintPrekeybundlePrekeyDataStringReturnValue: String!
    public var proteusFingerprintPrekeybundlePrekeyDataStringClosure: ((Data) throws -> String)?

    public func proteusFingerprintPrekeybundle(prekey: Data) throws -> String {
        proteusFingerprintPrekeybundlePrekeyDataStringCallsCount += 1
        proteusFingerprintPrekeybundlePrekeyDataStringReceivedPrekey = prekey
        proteusFingerprintPrekeybundlePrekeyDataStringReceivedInvocations.append(prekey)
        if let error = proteusFingerprintPrekeybundlePrekeyDataStringThrowableError {
            throw error
        }
        if let proteusFingerprintPrekeybundlePrekeyDataStringClosure = proteusFingerprintPrekeybundlePrekeyDataStringClosure {
            return try proteusFingerprintPrekeybundlePrekeyDataStringClosure(prekey)
        } else {
            return proteusFingerprintPrekeybundlePrekeyDataStringReturnValue
        }
    }

    //MARK: - proteusFingerprintRemote

    public var proteusFingerprintRemoteSessionIdStringStringThrowableError: (any Error)?
    public var proteusFingerprintRemoteSessionIdStringStringCallsCount = 0
    public var proteusFingerprintRemoteSessionIdStringStringCalled: Bool {
        return proteusFingerprintRemoteSessionIdStringStringCallsCount > 0
    }
    public var proteusFingerprintRemoteSessionIdStringStringReceivedSessionId: (String)?
    public var proteusFingerprintRemoteSessionIdStringStringReceivedInvocations: [(String)] = []
    public var proteusFingerprintRemoteSessionIdStringStringReturnValue: String!
    public var proteusFingerprintRemoteSessionIdStringStringClosure: ((String) async throws -> String)?

    public func proteusFingerprintRemote(sessionId: String) async throws -> String {
        proteusFingerprintRemoteSessionIdStringStringCallsCount += 1
        proteusFingerprintRemoteSessionIdStringStringReceivedSessionId = sessionId
        proteusFingerprintRemoteSessionIdStringStringReceivedInvocations.append(sessionId)
        if let error = proteusFingerprintRemoteSessionIdStringStringThrowableError {
            throw error
        }
        if let proteusFingerprintRemoteSessionIdStringStringClosure = proteusFingerprintRemoteSessionIdStringStringClosure {
            return try await proteusFingerprintRemoteSessionIdStringStringClosure(sessionId)
        } else {
            return proteusFingerprintRemoteSessionIdStringStringReturnValue
        }
    }

    //MARK: - proteusInit

    public var proteusInitVoidThrowableError: (any Error)?
    public var proteusInitVoidCallsCount = 0
    public var proteusInitVoidCalled: Bool {
        return proteusInitVoidCallsCount > 0
    }
    public var proteusInitVoidClosure: (() async throws -> Void)?

    public func proteusInit() async throws {
        proteusInitVoidCallsCount += 1
        if let error = proteusInitVoidThrowableError {
            throw error
        }
        try await proteusInitVoidClosure?()
    }

    //MARK: - proteusLastErrorCode

    public var proteusLastErrorCodeUInt32CallsCount = 0
    public var proteusLastErrorCodeUInt32Called: Bool {
        return proteusLastErrorCodeUInt32CallsCount > 0
    }
    public var proteusLastErrorCodeUInt32ReturnValue: UInt32!
    public var proteusLastErrorCodeUInt32Closure: (() -> UInt32)?

    public func proteusLastErrorCode() -> UInt32 {
        proteusLastErrorCodeUInt32CallsCount += 1
        if let proteusLastErrorCodeUInt32Closure = proteusLastErrorCodeUInt32Closure {
            return proteusLastErrorCodeUInt32Closure()
        } else {
            return proteusLastErrorCodeUInt32ReturnValue
        }
    }

    //MARK: - proteusLastResortPrekey

    public var proteusLastResortPrekeyDataThrowableError: (any Error)?
    public var proteusLastResortPrekeyDataCallsCount = 0
    public var proteusLastResortPrekeyDataCalled: Bool {
        return proteusLastResortPrekeyDataCallsCount > 0
    }
    public var proteusLastResortPrekeyDataReturnValue: Data!
    public var proteusLastResortPrekeyDataClosure: (() async throws -> Data)?

    public func proteusLastResortPrekey() async throws -> Data {
        proteusLastResortPrekeyDataCallsCount += 1
        if let error = proteusLastResortPrekeyDataThrowableError {
            throw error
        }
        if let proteusLastResortPrekeyDataClosure = proteusLastResortPrekeyDataClosure {
            return try await proteusLastResortPrekeyDataClosure()
        } else {
            return proteusLastResortPrekeyDataReturnValue
        }
    }

    //MARK: - proteusLastResortPrekeyId

    public var proteusLastResortPrekeyIdUInt16ThrowableError: (any Error)?
    public var proteusLastResortPrekeyIdUInt16CallsCount = 0
    public var proteusLastResortPrekeyIdUInt16Called: Bool {
        return proteusLastResortPrekeyIdUInt16CallsCount > 0
    }
    public var proteusLastResortPrekeyIdUInt16ReturnValue: UInt16!
    public var proteusLastResortPrekeyIdUInt16Closure: (() throws -> UInt16)?

    public func proteusLastResortPrekeyId() throws -> UInt16 {
        proteusLastResortPrekeyIdUInt16CallsCount += 1
        if let error = proteusLastResortPrekeyIdUInt16ThrowableError {
            throw error
        }
        if let proteusLastResortPrekeyIdUInt16Closure = proteusLastResortPrekeyIdUInt16Closure {
            return try proteusLastResortPrekeyIdUInt16Closure()
        } else {
            return proteusLastResortPrekeyIdUInt16ReturnValue
        }
    }

    //MARK: - proteusNewPrekey

    public var proteusNewPrekeyPrekeyIdUInt16DataThrowableError: (any Error)?
    public var proteusNewPrekeyPrekeyIdUInt16DataCallsCount = 0
    public var proteusNewPrekeyPrekeyIdUInt16DataCalled: Bool {
        return proteusNewPrekeyPrekeyIdUInt16DataCallsCount > 0
    }
    public var proteusNewPrekeyPrekeyIdUInt16DataReceivedPrekeyId: (UInt16)?
    public var proteusNewPrekeyPrekeyIdUInt16DataReceivedInvocations: [(UInt16)] = []
    public var proteusNewPrekeyPrekeyIdUInt16DataReturnValue: Data!
    public var proteusNewPrekeyPrekeyIdUInt16DataClosure: ((UInt16) async throws -> Data)?

    public func proteusNewPrekey(prekeyId: UInt16) async throws -> Data {
        proteusNewPrekeyPrekeyIdUInt16DataCallsCount += 1
        proteusNewPrekeyPrekeyIdUInt16DataReceivedPrekeyId = prekeyId
        proteusNewPrekeyPrekeyIdUInt16DataReceivedInvocations.append(prekeyId)
        if let error = proteusNewPrekeyPrekeyIdUInt16DataThrowableError {
            throw error
        }
        if let proteusNewPrekeyPrekeyIdUInt16DataClosure = proteusNewPrekeyPrekeyIdUInt16DataClosure {
            return try await proteusNewPrekeyPrekeyIdUInt16DataClosure(prekeyId)
        } else {
            return proteusNewPrekeyPrekeyIdUInt16DataReturnValue
        }
    }

    //MARK: - proteusNewPrekeyAuto

    public var proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleThrowableError: (any Error)?
    public var proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleCallsCount = 0
    public var proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleCalled: Bool {
        return proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleCallsCount > 0
    }
    public var proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleReturnValue: WireCoreCrypto.ProteusAutoPrekeyBundle!
    public var proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleClosure: (() async throws -> WireCoreCrypto.ProteusAutoPrekeyBundle)?

    public func proteusNewPrekeyAuto() async throws -> WireCoreCrypto.ProteusAutoPrekeyBundle {
        proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleCallsCount += 1
        if let error = proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleThrowableError {
            throw error
        }
        if let proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleClosure = proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleClosure {
            return try await proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleClosure()
        } else {
            return proteusNewPrekeyAutoWireCoreCryptoProteusAutoPrekeyBundleReturnValue
        }
    }

    //MARK: - proteusSessionDelete

    public var proteusSessionDeleteSessionIdStringVoidThrowableError: (any Error)?
    public var proteusSessionDeleteSessionIdStringVoidCallsCount = 0
    public var proteusSessionDeleteSessionIdStringVoidCalled: Bool {
        return proteusSessionDeleteSessionIdStringVoidCallsCount > 0
    }
    public var proteusSessionDeleteSessionIdStringVoidReceivedSessionId: (String)?
    public var proteusSessionDeleteSessionIdStringVoidReceivedInvocations: [(String)] = []
    public var proteusSessionDeleteSessionIdStringVoidClosure: ((String) async throws -> Void)?

    public func proteusSessionDelete(sessionId: String) async throws {
        proteusSessionDeleteSessionIdStringVoidCallsCount += 1
        proteusSessionDeleteSessionIdStringVoidReceivedSessionId = sessionId
        proteusSessionDeleteSessionIdStringVoidReceivedInvocations.append(sessionId)
        if let error = proteusSessionDeleteSessionIdStringVoidThrowableError {
            throw error
        }
        try await proteusSessionDeleteSessionIdStringVoidClosure?(sessionId)
    }

    //MARK: - proteusSessionExists

    public var proteusSessionExistsSessionIdStringBoolThrowableError: (any Error)?
    public var proteusSessionExistsSessionIdStringBoolCallsCount = 0
    public var proteusSessionExistsSessionIdStringBoolCalled: Bool {
        return proteusSessionExistsSessionIdStringBoolCallsCount > 0
    }
    public var proteusSessionExistsSessionIdStringBoolReceivedSessionId: (String)?
    public var proteusSessionExistsSessionIdStringBoolReceivedInvocations: [(String)] = []
    public var proteusSessionExistsSessionIdStringBoolReturnValue: Bool!
    public var proteusSessionExistsSessionIdStringBoolClosure: ((String) async throws -> Bool)?

    public func proteusSessionExists(sessionId: String) async throws -> Bool {
        proteusSessionExistsSessionIdStringBoolCallsCount += 1
        proteusSessionExistsSessionIdStringBoolReceivedSessionId = sessionId
        proteusSessionExistsSessionIdStringBoolReceivedInvocations.append(sessionId)
        if let error = proteusSessionExistsSessionIdStringBoolThrowableError {
            throw error
        }
        if let proteusSessionExistsSessionIdStringBoolClosure = proteusSessionExistsSessionIdStringBoolClosure {
            return try await proteusSessionExistsSessionIdStringBoolClosure(sessionId)
        } else {
            return proteusSessionExistsSessionIdStringBoolReturnValue
        }
    }

    //MARK: - proteusSessionFromMessage

    public var proteusSessionFromMessageSessionIdStringEnvelopeDataDataThrowableError: (any Error)?
    public var proteusSessionFromMessageSessionIdStringEnvelopeDataDataCallsCount = 0
    public var proteusSessionFromMessageSessionIdStringEnvelopeDataDataCalled: Bool {
        return proteusSessionFromMessageSessionIdStringEnvelopeDataDataCallsCount > 0
    }
    public var proteusSessionFromMessageSessionIdStringEnvelopeDataDataReceivedArguments: (sessionId: String, envelope: Data)?
    public var proteusSessionFromMessageSessionIdStringEnvelopeDataDataReceivedInvocations: [(sessionId: String, envelope: Data)] = []
    public var proteusSessionFromMessageSessionIdStringEnvelopeDataDataReturnValue: Data!
    public var proteusSessionFromMessageSessionIdStringEnvelopeDataDataClosure: ((String, Data) async throws -> Data)?

    public func proteusSessionFromMessage(sessionId: String, envelope: Data) async throws -> Data {
        proteusSessionFromMessageSessionIdStringEnvelopeDataDataCallsCount += 1
        proteusSessionFromMessageSessionIdStringEnvelopeDataDataReceivedArguments = (sessionId: sessionId, envelope: envelope)
        proteusSessionFromMessageSessionIdStringEnvelopeDataDataReceivedInvocations.append((sessionId: sessionId, envelope: envelope))
        if let error = proteusSessionFromMessageSessionIdStringEnvelopeDataDataThrowableError {
            throw error
        }
        if let proteusSessionFromMessageSessionIdStringEnvelopeDataDataClosure = proteusSessionFromMessageSessionIdStringEnvelopeDataDataClosure {
            return try await proteusSessionFromMessageSessionIdStringEnvelopeDataDataClosure(sessionId, envelope)
        } else {
            return proteusSessionFromMessageSessionIdStringEnvelopeDataDataReturnValue
        }
    }

    //MARK: - proteusSessionFromPrekey

    public var proteusSessionFromPrekeySessionIdStringPrekeyDataVoidThrowableError: (any Error)?
    public var proteusSessionFromPrekeySessionIdStringPrekeyDataVoidCallsCount = 0
    public var proteusSessionFromPrekeySessionIdStringPrekeyDataVoidCalled: Bool {
        return proteusSessionFromPrekeySessionIdStringPrekeyDataVoidCallsCount > 0
    }
    public var proteusSessionFromPrekeySessionIdStringPrekeyDataVoidReceivedArguments: (sessionId: String, prekey: Data)?
    public var proteusSessionFromPrekeySessionIdStringPrekeyDataVoidReceivedInvocations: [(sessionId: String, prekey: Data)] = []
    public var proteusSessionFromPrekeySessionIdStringPrekeyDataVoidClosure: ((String, Data) async throws -> Void)?

    public func proteusSessionFromPrekey(sessionId: String, prekey: Data) async throws {
        proteusSessionFromPrekeySessionIdStringPrekeyDataVoidCallsCount += 1
        proteusSessionFromPrekeySessionIdStringPrekeyDataVoidReceivedArguments = (sessionId: sessionId, prekey: prekey)
        proteusSessionFromPrekeySessionIdStringPrekeyDataVoidReceivedInvocations.append((sessionId: sessionId, prekey: prekey))
        if let error = proteusSessionFromPrekeySessionIdStringPrekeyDataVoidThrowableError {
            throw error
        }
        try await proteusSessionFromPrekeySessionIdStringPrekeyDataVoidClosure?(sessionId, prekey)
    }

    //MARK: - proteusSessionSave

    public var proteusSessionSaveSessionIdStringVoidThrowableError: (any Error)?
    public var proteusSessionSaveSessionIdStringVoidCallsCount = 0
    public var proteusSessionSaveSessionIdStringVoidCalled: Bool {
        return proteusSessionSaveSessionIdStringVoidCallsCount > 0
    }
    public var proteusSessionSaveSessionIdStringVoidReceivedSessionId: (String)?
    public var proteusSessionSaveSessionIdStringVoidReceivedInvocations: [(String)] = []
    public var proteusSessionSaveSessionIdStringVoidClosure: ((String) async throws -> Void)?

    public func proteusSessionSave(sessionId: String) async throws {
        proteusSessionSaveSessionIdStringVoidCallsCount += 1
        proteusSessionSaveSessionIdStringVoidReceivedSessionId = sessionId
        proteusSessionSaveSessionIdStringVoidReceivedInvocations.append(sessionId)
        if let error = proteusSessionSaveSessionIdStringVoidThrowableError {
            throw error
        }
        try await proteusSessionSaveSessionIdStringVoidClosure?(sessionId)
    }

    //MARK: - randomBytes

    public var randomBytesLenUInt32DataThrowableError: (any Error)?
    public var randomBytesLenUInt32DataCallsCount = 0
    public var randomBytesLenUInt32DataCalled: Bool {
        return randomBytesLenUInt32DataCallsCount > 0
    }
    public var randomBytesLenUInt32DataReceivedLen: (UInt32)?
    public var randomBytesLenUInt32DataReceivedInvocations: [(UInt32)] = []
    public var randomBytesLenUInt32DataReturnValue: Data!
    public var randomBytesLenUInt32DataClosure: ((UInt32) async throws -> Data)?

    public func randomBytes(len: UInt32) async throws -> Data {
        randomBytesLenUInt32DataCallsCount += 1
        randomBytesLenUInt32DataReceivedLen = len
        randomBytesLenUInt32DataReceivedInvocations.append(len)
        if let error = randomBytesLenUInt32DataThrowableError {
            throw error
        }
        if let randomBytesLenUInt32DataClosure = randomBytesLenUInt32DataClosure {
            return try await randomBytesLenUInt32DataClosure(len)
        } else {
            return randomBytesLenUInt32DataReturnValue
        }
    }

    //MARK: - removeClientsFromConversation

    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleThrowableError: (any Error)?
    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleCallsCount = 0
    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleCalled: Bool {
        return removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleCallsCount > 0
    }
    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleReceivedArguments: (conversationId: Data, clients: [WireCoreCrypto.ClientId])?
    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleReceivedInvocations: [(conversationId: Data, clients: [WireCoreCrypto.ClientId])] = []
    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleReturnValue: WireCoreCrypto.CommitBundle!
    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleClosure: ((Data, [WireCoreCrypto.ClientId]) async throws -> WireCoreCrypto.CommitBundle)?

    public func removeClientsFromConversation(conversationId: Data, clients: [WireCoreCrypto.ClientId]) async throws -> WireCoreCrypto.CommitBundle {
        removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleCallsCount += 1
        removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleReceivedArguments = (conversationId: conversationId, clients: clients)
        removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleReceivedInvocations.append((conversationId: conversationId, clients: clients))
        if let error = removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleThrowableError {
            throw error
        }
        if let removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleClosure = removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleClosure {
            return try await removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleClosure(conversationId, clients)
        } else {
            return removeClientsFromConversationConversationIdDataClientsWireCoreCryptoClientIdWireCoreCryptoCommitBundleReturnValue
        }
    }

    //MARK: - reseedRng

    public var reseedRngSeedDataVoidThrowableError: (any Error)?
    public var reseedRngSeedDataVoidCallsCount = 0
    public var reseedRngSeedDataVoidCalled: Bool {
        return reseedRngSeedDataVoidCallsCount > 0
    }
    public var reseedRngSeedDataVoidReceivedSeed: (Data)?
    public var reseedRngSeedDataVoidReceivedInvocations: [(Data)] = []
    public var reseedRngSeedDataVoidClosure: ((Data) async throws -> Void)?

    public func reseedRng(seed: Data) async throws {
        reseedRngSeedDataVoidCallsCount += 1
        reseedRngSeedDataVoidReceivedSeed = seed
        reseedRngSeedDataVoidReceivedInvocations.append(seed)
        if let error = reseedRngSeedDataVoidThrowableError {
            throw error
        }
        try await reseedRngSeedDataVoidClosure?(seed)
    }

    //MARK: - restoreFromDisk

    public var restoreFromDiskVoidThrowableError: (any Error)?
    public var restoreFromDiskVoidCallsCount = 0
    public var restoreFromDiskVoidCalled: Bool {
        return restoreFromDiskVoidCallsCount > 0
    }
    public var restoreFromDiskVoidClosure: (() async throws -> Void)?

    public func restoreFromDisk() async throws {
        restoreFromDiskVoidCallsCount += 1
        if let error = restoreFromDiskVoidThrowableError {
            throw error
        }
        try await restoreFromDiskVoidClosure?()
    }

    //MARK: - setCallbacks

    public var setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidThrowableError: (any Error)?
    public var setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidCallsCount = 0
    public var setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidCalled: Bool {
        return setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidCallsCount > 0
    }
    public var setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidReceivedCallbacks: (any WireCoreCrypto.CoreCryptoCallbacks)?
    public var setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidReceivedInvocations: [(any WireCoreCrypto.CoreCryptoCallbacks)] = []
    public var setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidClosure: ((any WireCoreCrypto.CoreCryptoCallbacks) async throws -> Void)?

    public func setCallbacks(callbacks: any WireCoreCrypto.CoreCryptoCallbacks) async throws {
        setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidCallsCount += 1
        setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidReceivedCallbacks = callbacks
        setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidReceivedInvocations.append(callbacks)
        if let error = setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidThrowableError {
            throw error
        }
        try await setCallbacksCallbacksAnyWireCoreCryptoCoreCryptoCallbacksVoidClosure?(callbacks)
    }

    //MARK: - unload

    public var unloadVoidThrowableError: (any Error)?
    public var unloadVoidCallsCount = 0
    public var unloadVoidCalled: Bool {
        return unloadVoidCallsCount > 0
    }
    public var unloadVoidClosure: (() async throws -> Void)?

    public func unload() async throws {
        unloadVoidCallsCount += 1
        if let error = unloadVoidThrowableError {
            throw error
        }
        try await unloadVoidClosure?()
    }

    //MARK: - updateKeyingMaterial

    public var updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleThrowableError: (any Error)?
    public var updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleCallsCount = 0
    public var updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleCalled: Bool {
        return updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleCallsCount > 0
    }
    public var updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleReceivedConversationId: (Data)?
    public var updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleReceivedInvocations: [(Data)] = []
    public var updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleReturnValue: WireCoreCrypto.CommitBundle!
    public var updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleClosure: ((Data) async throws -> WireCoreCrypto.CommitBundle)?

    public func updateKeyingMaterial(conversationId: Data) async throws -> WireCoreCrypto.CommitBundle {
        updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleCallsCount += 1
        updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleReceivedConversationId = conversationId
        updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleReceivedInvocations.append(conversationId)
        if let error = updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleThrowableError {
            throw error
        }
        if let updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleClosure = updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleClosure {
            return try await updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleClosure(conversationId)
        } else {
            return updateKeyingMaterialConversationIdDataWireCoreCryptoCommitBundleReturnValue
        }
    }

    //MARK: - wipe

    public var wipeVoidThrowableError: (any Error)?
    public var wipeVoidCallsCount = 0
    public var wipeVoidCalled: Bool {
        return wipeVoidCallsCount > 0
    }
    public var wipeVoidClosure: (() async throws -> Void)?

    public func wipe() async throws {
        wipeVoidCallsCount += 1
        if let error = wipeVoidThrowableError {
            throw error
        }
        try await wipeVoidClosure?()
    }

    //MARK: - wipeConversation

    public var wipeConversationConversationIdDataVoidThrowableError: (any Error)?
    public var wipeConversationConversationIdDataVoidCallsCount = 0
    public var wipeConversationConversationIdDataVoidCalled: Bool {
        return wipeConversationConversationIdDataVoidCallsCount > 0
    }
    public var wipeConversationConversationIdDataVoidReceivedConversationId: (Data)?
    public var wipeConversationConversationIdDataVoidReceivedInvocations: [(Data)] = []
    public var wipeConversationConversationIdDataVoidClosure: ((Data) async throws -> Void)?

    public func wipeConversation(conversationId: Data) async throws {
        wipeConversationConversationIdDataVoidCallsCount += 1
        wipeConversationConversationIdDataVoidReceivedConversationId = conversationId
        wipeConversationConversationIdDataVoidReceivedInvocations.append(conversationId)
        if let error = wipeConversationConversationIdDataVoidThrowableError {
            throw error
        }
        try await wipeConversationConversationIdDataVoidClosure?(conversationId)
    }


}
public class CoreCryptoProviderProtocolMock: CoreCryptoProviderProtocol {

    public init() {}



    //MARK: - coreCrypto

    public var coreCryptoSafeCoreCryptoProtocolThrowableError: (any Error)?
    public var coreCryptoSafeCoreCryptoProtocolCallsCount = 0
    public var coreCryptoSafeCoreCryptoProtocolCalled: Bool {
        return coreCryptoSafeCoreCryptoProtocolCallsCount > 0
    }
    public var coreCryptoSafeCoreCryptoProtocolReturnValue: SafeCoreCryptoProtocol!
    public var coreCryptoSafeCoreCryptoProtocolClosure: (() async throws -> SafeCoreCryptoProtocol)?

    public func coreCrypto() async throws -> SafeCoreCryptoProtocol {
        coreCryptoSafeCoreCryptoProtocolCallsCount += 1
        if let error = coreCryptoSafeCoreCryptoProtocolThrowableError {
            throw error
        }
        if let coreCryptoSafeCoreCryptoProtocolClosure = coreCryptoSafeCoreCryptoProtocolClosure {
            return try await coreCryptoSafeCoreCryptoProtocolClosure()
        } else {
            return coreCryptoSafeCoreCryptoProtocolReturnValue
        }
    }

    //MARK: - initialiseMLSWithBasicCredentials

    public var initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidThrowableError: (any Error)?
    public var initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidCallsCount = 0
    public var initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidCalled: Bool {
        return initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidCallsCount > 0
    }
    public var initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidReceivedMlsClientID: (MLSClientID)?
    public var initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidReceivedInvocations: [(MLSClientID)] = []
    public var initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidClosure: ((MLSClientID) async throws -> Void)?

    public func initialiseMLSWithBasicCredentials(mlsClientID: MLSClientID) async throws {
        initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidCallsCount += 1
        initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidReceivedMlsClientID = mlsClientID
        initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidReceivedInvocations.append(mlsClientID)
        if let error = initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidThrowableError {
            throw error
        }
        try await initialiseMLSWithBasicCredentialsMlsClientIDMLSClientIDVoidClosure?(mlsClientID)
    }

    //MARK: - initialiseMLSWithEndToEndIdentity

    public var initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsThrowableError: (any Error)?
    public var initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsCallsCount = 0
    public var initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsCalled: Bool {
        return initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsCallsCount > 0
    }
    public var initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsReceivedArguments: (enrollment: E2eiEnrollment, certificateChain: String)?
    public var initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsReceivedInvocations: [(enrollment: E2eiEnrollment, certificateChain: String)] = []
    public var initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsReturnValue: CRLsDistributionPoints?
    public var initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsClosure: ((E2eiEnrollment, String) async throws -> CRLsDistributionPoints?)?

    public func initialiseMLSWithEndToEndIdentity(enrollment: E2eiEnrollment, certificateChain: String) async throws -> CRLsDistributionPoints? {
        initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsCallsCount += 1
        initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsReceivedArguments = (enrollment: enrollment, certificateChain: certificateChain)
        initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsReceivedInvocations.append((enrollment: enrollment, certificateChain: certificateChain))
        if let error = initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsThrowableError {
            throw error
        }
        if let initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsClosure = initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsClosure {
            return try await initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsClosure(enrollment, certificateChain)
        } else {
            return initialiseMLSWithEndToEndIdentityEnrollmentE2eiEnrollmentCertificateChainStringCRLsDistributionPointsReturnValue
        }
    }


}
class CoreDataMessagingMigratorProtocolMock: CoreDataMessagingMigratorProtocol {




    //MARK: - requiresMigration

    var requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolCallsCount = 0
    var requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolCalled: Bool {
        return requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolCallsCount > 0
    }
    var requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolReceivedArguments: (storeURL: URL, version: CoreDataMessagingMigrationVersion)?
    var requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolReceivedInvocations: [(storeURL: URL, version: CoreDataMessagingMigrationVersion)] = []
    var requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolReturnValue: Bool!
    var requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolClosure: ((URL, CoreDataMessagingMigrationVersion) -> Bool)?

    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) -> Bool {
        requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolCallsCount += 1
        requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolReceivedArguments = (storeURL: storeURL, version: version)
        requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolReceivedInvocations.append((storeURL: storeURL, version: version))
        if let requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolClosure = requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolClosure {
            return requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolClosure(storeURL, version)
        } else {
            return requiresMigrationAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionBoolReturnValue
        }
    }

    //MARK: - migrateStore

    var migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidThrowableError: (any Error)?
    var migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidCallsCount = 0
    var migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidCalled: Bool {
        return migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidCallsCount > 0
    }
    var migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidReceivedArguments: (storeURL: URL, version: CoreDataMessagingMigrationVersion)?
    var migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidReceivedInvocations: [(storeURL: URL, version: CoreDataMessagingMigrationVersion)] = []
    var migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidClosure: ((URL, CoreDataMessagingMigrationVersion) throws -> Void)?

    func migrateStore(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) throws {
        migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidCallsCount += 1
        migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidReceivedArguments = (storeURL: storeURL, version: version)
        migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidReceivedInvocations.append((storeURL: storeURL, version: version))
        if let error = migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidThrowableError {
            throw error
        }
        try migrateStoreAtStoreURLURLToVersionVersionCoreDataMessagingMigrationVersionVoidClosure?(storeURL, version)
    }


}
public class CryptoboxMigrationManagerInterfaceMock: CryptoboxMigrationManagerInterface {

    public init() {}



    //MARK: - isMigrationNeeded

    public var isMigrationNeededAccountDirectoryURLBoolCallsCount = 0
    public var isMigrationNeededAccountDirectoryURLBoolCalled: Bool {
        return isMigrationNeededAccountDirectoryURLBoolCallsCount > 0
    }
    public var isMigrationNeededAccountDirectoryURLBoolReceivedAccountDirectory: (URL)?
    public var isMigrationNeededAccountDirectoryURLBoolReceivedInvocations: [(URL)] = []
    public var isMigrationNeededAccountDirectoryURLBoolReturnValue: Bool!
    public var isMigrationNeededAccountDirectoryURLBoolClosure: ((URL) -> Bool)?

    public func isMigrationNeeded(accountDirectory: URL) -> Bool {
        isMigrationNeededAccountDirectoryURLBoolCallsCount += 1
        isMigrationNeededAccountDirectoryURLBoolReceivedAccountDirectory = accountDirectory
        isMigrationNeededAccountDirectoryURLBoolReceivedInvocations.append(accountDirectory)
        if let isMigrationNeededAccountDirectoryURLBoolClosure = isMigrationNeededAccountDirectoryURLBoolClosure {
            return isMigrationNeededAccountDirectoryURLBoolClosure(accountDirectory)
        } else {
            return isMigrationNeededAccountDirectoryURLBoolReturnValue
        }
    }

    //MARK: - performMigration

    public var performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidThrowableError: (any Error)?
    public var performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidCallsCount = 0
    public var performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidCalled: Bool {
        return performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidCallsCount > 0
    }
    public var performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidReceivedArguments: (accountDirectory: URL, coreCrypto: SafeCoreCryptoProtocol)?
    public var performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidReceivedInvocations: [(accountDirectory: URL, coreCrypto: SafeCoreCryptoProtocol)] = []
    public var performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidClosure: ((URL, SafeCoreCryptoProtocol) async throws -> Void)?

    public func performMigration(accountDirectory: URL, coreCrypto: SafeCoreCryptoProtocol) async throws {
        performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidCallsCount += 1
        performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidReceivedArguments = (accountDirectory: accountDirectory, coreCrypto: coreCrypto)
        performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidReceivedInvocations.append((accountDirectory: accountDirectory, coreCrypto: coreCrypto))
        if let error = performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidThrowableError {
            throw error
        }
        try await performMigrationAccountDirectoryURLCoreCryptoSafeCoreCryptoProtocolVoidClosure?(accountDirectory, coreCrypto)
    }


}
public class E2EIServiceInterfaceMock: E2EIServiceInterface {

    public init() {}

    public var e2eIdentity: E2eiEnrollmentProtocol {
        get { return underlyingE2eIdentity }
        set(value) { underlyingE2eIdentity = value }
    }
    public var underlyingE2eIdentity: (E2eiEnrollmentProtocol)!


    //MARK: - getDirectoryResponse

    public var getDirectoryResponseDirectoryDataDataAcmeDirectoryThrowableError: (any Error)?
    public var getDirectoryResponseDirectoryDataDataAcmeDirectoryCallsCount = 0
    public var getDirectoryResponseDirectoryDataDataAcmeDirectoryCalled: Bool {
        return getDirectoryResponseDirectoryDataDataAcmeDirectoryCallsCount > 0
    }
    public var getDirectoryResponseDirectoryDataDataAcmeDirectoryReceivedDirectoryData: (Data)?
    public var getDirectoryResponseDirectoryDataDataAcmeDirectoryReceivedInvocations: [(Data)] = []
    public var getDirectoryResponseDirectoryDataDataAcmeDirectoryReturnValue: AcmeDirectory!
    public var getDirectoryResponseDirectoryDataDataAcmeDirectoryClosure: ((Data) async throws -> AcmeDirectory)?

    public func getDirectoryResponse(directoryData: Data) async throws -> AcmeDirectory {
        getDirectoryResponseDirectoryDataDataAcmeDirectoryCallsCount += 1
        getDirectoryResponseDirectoryDataDataAcmeDirectoryReceivedDirectoryData = directoryData
        getDirectoryResponseDirectoryDataDataAcmeDirectoryReceivedInvocations.append(directoryData)
        if let error = getDirectoryResponseDirectoryDataDataAcmeDirectoryThrowableError {
            throw error
        }
        if let getDirectoryResponseDirectoryDataDataAcmeDirectoryClosure = getDirectoryResponseDirectoryDataDataAcmeDirectoryClosure {
            return try await getDirectoryResponseDirectoryDataDataAcmeDirectoryClosure(directoryData)
        } else {
            return getDirectoryResponseDirectoryDataDataAcmeDirectoryReturnValue
        }
    }

    //MARK: - getNewAccountRequest

    public var getNewAccountRequestNonceStringDataThrowableError: (any Error)?
    public var getNewAccountRequestNonceStringDataCallsCount = 0
    public var getNewAccountRequestNonceStringDataCalled: Bool {
        return getNewAccountRequestNonceStringDataCallsCount > 0
    }
    public var getNewAccountRequestNonceStringDataReceivedNonce: (String)?
    public var getNewAccountRequestNonceStringDataReceivedInvocations: [(String)] = []
    public var getNewAccountRequestNonceStringDataReturnValue: Data!
    public var getNewAccountRequestNonceStringDataClosure: ((String) async throws -> Data)?

    public func getNewAccountRequest(nonce: String) async throws -> Data {
        getNewAccountRequestNonceStringDataCallsCount += 1
        getNewAccountRequestNonceStringDataReceivedNonce = nonce
        getNewAccountRequestNonceStringDataReceivedInvocations.append(nonce)
        if let error = getNewAccountRequestNonceStringDataThrowableError {
            throw error
        }
        if let getNewAccountRequestNonceStringDataClosure = getNewAccountRequestNonceStringDataClosure {
            return try await getNewAccountRequestNonceStringDataClosure(nonce)
        } else {
            return getNewAccountRequestNonceStringDataReturnValue
        }
    }

    //MARK: - setAccountResponse

    public var setAccountResponseAccountDataDataVoidThrowableError: (any Error)?
    public var setAccountResponseAccountDataDataVoidCallsCount = 0
    public var setAccountResponseAccountDataDataVoidCalled: Bool {
        return setAccountResponseAccountDataDataVoidCallsCount > 0
    }
    public var setAccountResponseAccountDataDataVoidReceivedAccountData: (Data)?
    public var setAccountResponseAccountDataDataVoidReceivedInvocations: [(Data)] = []
    public var setAccountResponseAccountDataDataVoidClosure: ((Data) async throws -> Void)?

    public func setAccountResponse(accountData: Data) async throws {
        setAccountResponseAccountDataDataVoidCallsCount += 1
        setAccountResponseAccountDataDataVoidReceivedAccountData = accountData
        setAccountResponseAccountDataDataVoidReceivedInvocations.append(accountData)
        if let error = setAccountResponseAccountDataDataVoidThrowableError {
            throw error
        }
        try await setAccountResponseAccountDataDataVoidClosure?(accountData)
    }

    //MARK: - getNewOrderRequest

    public var getNewOrderRequestNonceStringDataThrowableError: (any Error)?
    public var getNewOrderRequestNonceStringDataCallsCount = 0
    public var getNewOrderRequestNonceStringDataCalled: Bool {
        return getNewOrderRequestNonceStringDataCallsCount > 0
    }
    public var getNewOrderRequestNonceStringDataReceivedNonce: (String)?
    public var getNewOrderRequestNonceStringDataReceivedInvocations: [(String)] = []
    public var getNewOrderRequestNonceStringDataReturnValue: Data!
    public var getNewOrderRequestNonceStringDataClosure: ((String) async throws -> Data)?

    public func getNewOrderRequest(nonce: String) async throws -> Data {
        getNewOrderRequestNonceStringDataCallsCount += 1
        getNewOrderRequestNonceStringDataReceivedNonce = nonce
        getNewOrderRequestNonceStringDataReceivedInvocations.append(nonce)
        if let error = getNewOrderRequestNonceStringDataThrowableError {
            throw error
        }
        if let getNewOrderRequestNonceStringDataClosure = getNewOrderRequestNonceStringDataClosure {
            return try await getNewOrderRequestNonceStringDataClosure(nonce)
        } else {
            return getNewOrderRequestNonceStringDataReturnValue
        }
    }

    //MARK: - setOrderResponse

    public var setOrderResponseOrderDataNewAcmeOrderThrowableError: (any Error)?
    public var setOrderResponseOrderDataNewAcmeOrderCallsCount = 0
    public var setOrderResponseOrderDataNewAcmeOrderCalled: Bool {
        return setOrderResponseOrderDataNewAcmeOrderCallsCount > 0
    }
    public var setOrderResponseOrderDataNewAcmeOrderReceivedOrder: (Data)?
    public var setOrderResponseOrderDataNewAcmeOrderReceivedInvocations: [(Data)] = []
    public var setOrderResponseOrderDataNewAcmeOrderReturnValue: NewAcmeOrder!
    public var setOrderResponseOrderDataNewAcmeOrderClosure: ((Data) async throws -> NewAcmeOrder)?

    public func setOrderResponse(order: Data) async throws -> NewAcmeOrder {
        setOrderResponseOrderDataNewAcmeOrderCallsCount += 1
        setOrderResponseOrderDataNewAcmeOrderReceivedOrder = order
        setOrderResponseOrderDataNewAcmeOrderReceivedInvocations.append(order)
        if let error = setOrderResponseOrderDataNewAcmeOrderThrowableError {
            throw error
        }
        if let setOrderResponseOrderDataNewAcmeOrderClosure = setOrderResponseOrderDataNewAcmeOrderClosure {
            return try await setOrderResponseOrderDataNewAcmeOrderClosure(order)
        } else {
            return setOrderResponseOrderDataNewAcmeOrderReturnValue
        }
    }

    //MARK: - getNewAuthzRequest

    public var getNewAuthzRequestUrlStringPreviousNonceStringDataThrowableError: (any Error)?
    public var getNewAuthzRequestUrlStringPreviousNonceStringDataCallsCount = 0
    public var getNewAuthzRequestUrlStringPreviousNonceStringDataCalled: Bool {
        return getNewAuthzRequestUrlStringPreviousNonceStringDataCallsCount > 0
    }
    public var getNewAuthzRequestUrlStringPreviousNonceStringDataReceivedArguments: (url: String, previousNonce: String)?
    public var getNewAuthzRequestUrlStringPreviousNonceStringDataReceivedInvocations: [(url: String, previousNonce: String)] = []
    public var getNewAuthzRequestUrlStringPreviousNonceStringDataReturnValue: Data!
    public var getNewAuthzRequestUrlStringPreviousNonceStringDataClosure: ((String, String) async throws -> Data)?

    public func getNewAuthzRequest(url: String, previousNonce: String) async throws -> Data {
        getNewAuthzRequestUrlStringPreviousNonceStringDataCallsCount += 1
        getNewAuthzRequestUrlStringPreviousNonceStringDataReceivedArguments = (url: url, previousNonce: previousNonce)
        getNewAuthzRequestUrlStringPreviousNonceStringDataReceivedInvocations.append((url: url, previousNonce: previousNonce))
        if let error = getNewAuthzRequestUrlStringPreviousNonceStringDataThrowableError {
            throw error
        }
        if let getNewAuthzRequestUrlStringPreviousNonceStringDataClosure = getNewAuthzRequestUrlStringPreviousNonceStringDataClosure {
            return try await getNewAuthzRequestUrlStringPreviousNonceStringDataClosure(url, previousNonce)
        } else {
            return getNewAuthzRequestUrlStringPreviousNonceStringDataReturnValue
        }
    }

    //MARK: - setAuthzResponse

    public var setAuthzResponseAuthzDataNewAcmeAuthzThrowableError: (any Error)?
    public var setAuthzResponseAuthzDataNewAcmeAuthzCallsCount = 0
    public var setAuthzResponseAuthzDataNewAcmeAuthzCalled: Bool {
        return setAuthzResponseAuthzDataNewAcmeAuthzCallsCount > 0
    }
    public var setAuthzResponseAuthzDataNewAcmeAuthzReceivedAuthz: (Data)?
    public var setAuthzResponseAuthzDataNewAcmeAuthzReceivedInvocations: [(Data)] = []
    public var setAuthzResponseAuthzDataNewAcmeAuthzReturnValue: NewAcmeAuthz!
    public var setAuthzResponseAuthzDataNewAcmeAuthzClosure: ((Data) async throws -> NewAcmeAuthz)?

    public func setAuthzResponse(authz: Data) async throws -> NewAcmeAuthz {
        setAuthzResponseAuthzDataNewAcmeAuthzCallsCount += 1
        setAuthzResponseAuthzDataNewAcmeAuthzReceivedAuthz = authz
        setAuthzResponseAuthzDataNewAcmeAuthzReceivedInvocations.append(authz)
        if let error = setAuthzResponseAuthzDataNewAcmeAuthzThrowableError {
            throw error
        }
        if let setAuthzResponseAuthzDataNewAcmeAuthzClosure = setAuthzResponseAuthzDataNewAcmeAuthzClosure {
            return try await setAuthzResponseAuthzDataNewAcmeAuthzClosure(authz)
        } else {
            return setAuthzResponseAuthzDataNewAcmeAuthzReturnValue
        }
    }

    //MARK: - getOAuthRefreshToken

    public var getOAuthRefreshTokenStringThrowableError: (any Error)?
    public var getOAuthRefreshTokenStringCallsCount = 0
    public var getOAuthRefreshTokenStringCalled: Bool {
        return getOAuthRefreshTokenStringCallsCount > 0
    }
    public var getOAuthRefreshTokenStringReturnValue: String!
    public var getOAuthRefreshTokenStringClosure: (() async throws -> String)?

    public func getOAuthRefreshToken() async throws -> String {
        getOAuthRefreshTokenStringCallsCount += 1
        if let error = getOAuthRefreshTokenStringThrowableError {
            throw error
        }
        if let getOAuthRefreshTokenStringClosure = getOAuthRefreshTokenStringClosure {
            return try await getOAuthRefreshTokenStringClosure()
        } else {
            return getOAuthRefreshTokenStringReturnValue
        }
    }

    //MARK: - createDpopToken

    public var createDpopTokenNonceStringStringThrowableError: (any Error)?
    public var createDpopTokenNonceStringStringCallsCount = 0
    public var createDpopTokenNonceStringStringCalled: Bool {
        return createDpopTokenNonceStringStringCallsCount > 0
    }
    public var createDpopTokenNonceStringStringReceivedNonce: (String)?
    public var createDpopTokenNonceStringStringReceivedInvocations: [(String)] = []
    public var createDpopTokenNonceStringStringReturnValue: String!
    public var createDpopTokenNonceStringStringClosure: ((String) async throws -> String)?

    public func createDpopToken(nonce: String) async throws -> String {
        createDpopTokenNonceStringStringCallsCount += 1
        createDpopTokenNonceStringStringReceivedNonce = nonce
        createDpopTokenNonceStringStringReceivedInvocations.append(nonce)
        if let error = createDpopTokenNonceStringStringThrowableError {
            throw error
        }
        if let createDpopTokenNonceStringStringClosure = createDpopTokenNonceStringStringClosure {
            return try await createDpopTokenNonceStringStringClosure(nonce)
        } else {
            return createDpopTokenNonceStringStringReturnValue
        }
    }

    //MARK: - getNewDpopChallengeRequest

    public var getNewDpopChallengeRequestAccessTokenStringNonceStringDataThrowableError: (any Error)?
    public var getNewDpopChallengeRequestAccessTokenStringNonceStringDataCallsCount = 0
    public var getNewDpopChallengeRequestAccessTokenStringNonceStringDataCalled: Bool {
        return getNewDpopChallengeRequestAccessTokenStringNonceStringDataCallsCount > 0
    }
    public var getNewDpopChallengeRequestAccessTokenStringNonceStringDataReceivedArguments: (accessToken: String, nonce: String)?
    public var getNewDpopChallengeRequestAccessTokenStringNonceStringDataReceivedInvocations: [(accessToken: String, nonce: String)] = []
    public var getNewDpopChallengeRequestAccessTokenStringNonceStringDataReturnValue: Data!
    public var getNewDpopChallengeRequestAccessTokenStringNonceStringDataClosure: ((String, String) async throws -> Data)?

    public func getNewDpopChallengeRequest(accessToken: String, nonce: String) async throws -> Data {
        getNewDpopChallengeRequestAccessTokenStringNonceStringDataCallsCount += 1
        getNewDpopChallengeRequestAccessTokenStringNonceStringDataReceivedArguments = (accessToken: accessToken, nonce: nonce)
        getNewDpopChallengeRequestAccessTokenStringNonceStringDataReceivedInvocations.append((accessToken: accessToken, nonce: nonce))
        if let error = getNewDpopChallengeRequestAccessTokenStringNonceStringDataThrowableError {
            throw error
        }
        if let getNewDpopChallengeRequestAccessTokenStringNonceStringDataClosure = getNewDpopChallengeRequestAccessTokenStringNonceStringDataClosure {
            return try await getNewDpopChallengeRequestAccessTokenStringNonceStringDataClosure(accessToken, nonce)
        } else {
            return getNewDpopChallengeRequestAccessTokenStringNonceStringDataReturnValue
        }
    }

    //MARK: - getNewOidcChallengeRequest

    public var getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataThrowableError: (any Error)?
    public var getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataCallsCount = 0
    public var getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataCalled: Bool {
        return getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataCallsCount > 0
    }
    public var getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataReceivedArguments: (idToken: String, refreshToken: String, nonce: String)?
    public var getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataReceivedInvocations: [(idToken: String, refreshToken: String, nonce: String)] = []
    public var getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataReturnValue: Data!
    public var getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataClosure: ((String, String, String) async throws -> Data)?

    public func getNewOidcChallengeRequest(idToken: String, refreshToken: String, nonce: String) async throws -> Data {
        getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataCallsCount += 1
        getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataReceivedArguments = (idToken: idToken, refreshToken: refreshToken, nonce: nonce)
        getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataReceivedInvocations.append((idToken: idToken, refreshToken: refreshToken, nonce: nonce))
        if let error = getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataThrowableError {
            throw error
        }
        if let getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataClosure = getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataClosure {
            return try await getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataClosure(idToken, refreshToken, nonce)
        } else {
            return getNewOidcChallengeRequestIdTokenStringRefreshTokenStringNonceStringDataReturnValue
        }
    }

    //MARK: - setDPoPChallengeResponse

    public var setDPoPChallengeResponseChallengeDataVoidThrowableError: (any Error)?
    public var setDPoPChallengeResponseChallengeDataVoidCallsCount = 0
    public var setDPoPChallengeResponseChallengeDataVoidCalled: Bool {
        return setDPoPChallengeResponseChallengeDataVoidCallsCount > 0
    }
    public var setDPoPChallengeResponseChallengeDataVoidReceivedChallenge: (Data)?
    public var setDPoPChallengeResponseChallengeDataVoidReceivedInvocations: [(Data)] = []
    public var setDPoPChallengeResponseChallengeDataVoidClosure: ((Data) async throws -> Void)?

    public func setDPoPChallengeResponse(challenge: Data) async throws {
        setDPoPChallengeResponseChallengeDataVoidCallsCount += 1
        setDPoPChallengeResponseChallengeDataVoidReceivedChallenge = challenge
        setDPoPChallengeResponseChallengeDataVoidReceivedInvocations.append(challenge)
        if let error = setDPoPChallengeResponseChallengeDataVoidThrowableError {
            throw error
        }
        try await setDPoPChallengeResponseChallengeDataVoidClosure?(challenge)
    }

    //MARK: - setOIDCChallengeResponse

    public var setOIDCChallengeResponseChallengeDataVoidThrowableError: (any Error)?
    public var setOIDCChallengeResponseChallengeDataVoidCallsCount = 0
    public var setOIDCChallengeResponseChallengeDataVoidCalled: Bool {
        return setOIDCChallengeResponseChallengeDataVoidCallsCount > 0
    }
    public var setOIDCChallengeResponseChallengeDataVoidReceivedChallenge: (Data)?
    public var setOIDCChallengeResponseChallengeDataVoidReceivedInvocations: [(Data)] = []
    public var setOIDCChallengeResponseChallengeDataVoidClosure: ((Data) async throws -> Void)?

    public func setOIDCChallengeResponse(challenge: Data) async throws {
        setOIDCChallengeResponseChallengeDataVoidCallsCount += 1
        setOIDCChallengeResponseChallengeDataVoidReceivedChallenge = challenge
        setOIDCChallengeResponseChallengeDataVoidReceivedInvocations.append(challenge)
        if let error = setOIDCChallengeResponseChallengeDataVoidThrowableError {
            throw error
        }
        try await setOIDCChallengeResponseChallengeDataVoidClosure?(challenge)
    }

    //MARK: - checkOrderRequest

    public var checkOrderRequestOrderUrlStringNonceStringDataThrowableError: (any Error)?
    public var checkOrderRequestOrderUrlStringNonceStringDataCallsCount = 0
    public var checkOrderRequestOrderUrlStringNonceStringDataCalled: Bool {
        return checkOrderRequestOrderUrlStringNonceStringDataCallsCount > 0
    }
    public var checkOrderRequestOrderUrlStringNonceStringDataReceivedArguments: (orderUrl: String, nonce: String)?
    public var checkOrderRequestOrderUrlStringNonceStringDataReceivedInvocations: [(orderUrl: String, nonce: String)] = []
    public var checkOrderRequestOrderUrlStringNonceStringDataReturnValue: Data!
    public var checkOrderRequestOrderUrlStringNonceStringDataClosure: ((String, String) async throws -> Data)?

    public func checkOrderRequest(orderUrl: String, nonce: String) async throws -> Data {
        checkOrderRequestOrderUrlStringNonceStringDataCallsCount += 1
        checkOrderRequestOrderUrlStringNonceStringDataReceivedArguments = (orderUrl: orderUrl, nonce: nonce)
        checkOrderRequestOrderUrlStringNonceStringDataReceivedInvocations.append((orderUrl: orderUrl, nonce: nonce))
        if let error = checkOrderRequestOrderUrlStringNonceStringDataThrowableError {
            throw error
        }
        if let checkOrderRequestOrderUrlStringNonceStringDataClosure = checkOrderRequestOrderUrlStringNonceStringDataClosure {
            return try await checkOrderRequestOrderUrlStringNonceStringDataClosure(orderUrl, nonce)
        } else {
            return checkOrderRequestOrderUrlStringNonceStringDataReturnValue
        }
    }

    //MARK: - checkOrderResponse

    public var checkOrderResponseOrderDataStringThrowableError: (any Error)?
    public var checkOrderResponseOrderDataStringCallsCount = 0
    public var checkOrderResponseOrderDataStringCalled: Bool {
        return checkOrderResponseOrderDataStringCallsCount > 0
    }
    public var checkOrderResponseOrderDataStringReceivedOrder: (Data)?
    public var checkOrderResponseOrderDataStringReceivedInvocations: [(Data)] = []
    public var checkOrderResponseOrderDataStringReturnValue: String!
    public var checkOrderResponseOrderDataStringClosure: ((Data) async throws -> String)?

    public func checkOrderResponse(order: Data) async throws -> String {
        checkOrderResponseOrderDataStringCallsCount += 1
        checkOrderResponseOrderDataStringReceivedOrder = order
        checkOrderResponseOrderDataStringReceivedInvocations.append(order)
        if let error = checkOrderResponseOrderDataStringThrowableError {
            throw error
        }
        if let checkOrderResponseOrderDataStringClosure = checkOrderResponseOrderDataStringClosure {
            return try await checkOrderResponseOrderDataStringClosure(order)
        } else {
            return checkOrderResponseOrderDataStringReturnValue
        }
    }

    //MARK: - finalizeRequest

    public var finalizeRequestNonceStringDataThrowableError: (any Error)?
    public var finalizeRequestNonceStringDataCallsCount = 0
    public var finalizeRequestNonceStringDataCalled: Bool {
        return finalizeRequestNonceStringDataCallsCount > 0
    }
    public var finalizeRequestNonceStringDataReceivedNonce: (String)?
    public var finalizeRequestNonceStringDataReceivedInvocations: [(String)] = []
    public var finalizeRequestNonceStringDataReturnValue: Data!
    public var finalizeRequestNonceStringDataClosure: ((String) async throws -> Data)?

    public func finalizeRequest(nonce: String) async throws -> Data {
        finalizeRequestNonceStringDataCallsCount += 1
        finalizeRequestNonceStringDataReceivedNonce = nonce
        finalizeRequestNonceStringDataReceivedInvocations.append(nonce)
        if let error = finalizeRequestNonceStringDataThrowableError {
            throw error
        }
        if let finalizeRequestNonceStringDataClosure = finalizeRequestNonceStringDataClosure {
            return try await finalizeRequestNonceStringDataClosure(nonce)
        } else {
            return finalizeRequestNonceStringDataReturnValue
        }
    }

    //MARK: - finalizeResponse

    public var finalizeResponseFinalizeDataStringThrowableError: (any Error)?
    public var finalizeResponseFinalizeDataStringCallsCount = 0
    public var finalizeResponseFinalizeDataStringCalled: Bool {
        return finalizeResponseFinalizeDataStringCallsCount > 0
    }
    public var finalizeResponseFinalizeDataStringReceivedFinalize: (Data)?
    public var finalizeResponseFinalizeDataStringReceivedInvocations: [(Data)] = []
    public var finalizeResponseFinalizeDataStringReturnValue: String!
    public var finalizeResponseFinalizeDataStringClosure: ((Data) async throws -> String)?

    public func finalizeResponse(finalize: Data) async throws -> String {
        finalizeResponseFinalizeDataStringCallsCount += 1
        finalizeResponseFinalizeDataStringReceivedFinalize = finalize
        finalizeResponseFinalizeDataStringReceivedInvocations.append(finalize)
        if let error = finalizeResponseFinalizeDataStringThrowableError {
            throw error
        }
        if let finalizeResponseFinalizeDataStringClosure = finalizeResponseFinalizeDataStringClosure {
            return try await finalizeResponseFinalizeDataStringClosure(finalize)
        } else {
            return finalizeResponseFinalizeDataStringReturnValue
        }
    }

    //MARK: - certificateRequest

    public var certificateRequestNonceStringDataThrowableError: (any Error)?
    public var certificateRequestNonceStringDataCallsCount = 0
    public var certificateRequestNonceStringDataCalled: Bool {
        return certificateRequestNonceStringDataCallsCount > 0
    }
    public var certificateRequestNonceStringDataReceivedNonce: (String)?
    public var certificateRequestNonceStringDataReceivedInvocations: [(String)] = []
    public var certificateRequestNonceStringDataReturnValue: Data!
    public var certificateRequestNonceStringDataClosure: ((String) async throws -> Data)?

    public func certificateRequest(nonce: String) async throws -> Data {
        certificateRequestNonceStringDataCallsCount += 1
        certificateRequestNonceStringDataReceivedNonce = nonce
        certificateRequestNonceStringDataReceivedInvocations.append(nonce)
        if let error = certificateRequestNonceStringDataThrowableError {
            throw error
        }
        if let certificateRequestNonceStringDataClosure = certificateRequestNonceStringDataClosure {
            return try await certificateRequestNonceStringDataClosure(nonce)
        } else {
            return certificateRequestNonceStringDataReturnValue
        }
    }

    //MARK: - createNewClient

    public var createNewClientCertificateChainStringVoidThrowableError: (any Error)?
    public var createNewClientCertificateChainStringVoidCallsCount = 0
    public var createNewClientCertificateChainStringVoidCalled: Bool {
        return createNewClientCertificateChainStringVoidCallsCount > 0
    }
    public var createNewClientCertificateChainStringVoidReceivedCertificateChain: (String)?
    public var createNewClientCertificateChainStringVoidReceivedInvocations: [(String)] = []
    public var createNewClientCertificateChainStringVoidClosure: ((String) async throws -> Void)?

    public func createNewClient(certificateChain: String) async throws {
        createNewClientCertificateChainStringVoidCallsCount += 1
        createNewClientCertificateChainStringVoidReceivedCertificateChain = certificateChain
        createNewClientCertificateChainStringVoidReceivedInvocations.append(certificateChain)
        if let error = createNewClientCertificateChainStringVoidThrowableError {
            throw error
        }
        try await createNewClientCertificateChainStringVoidClosure?(certificateChain)
    }


}
public class E2EIVerificationStatusServiceInterfaceMock: E2EIVerificationStatusServiceInterface {

    public init() {}



    //MARK: - getConversationStatus

    public var getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusThrowableError: (any Error)?
    public var getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusCallsCount = 0
    public var getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusCalled: Bool {
        return getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusCallsCount > 0
    }
    public var getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusReceivedGroupID: (MLSGroupID)?
    public var getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusReceivedInvocations: [(MLSGroupID)] = []
    public var getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusReturnValue: MLSVerificationStatus!
    public var getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusClosure: ((MLSGroupID) async throws -> MLSVerificationStatus)?

    public func getConversationStatus(groupID: MLSGroupID) async throws -> MLSVerificationStatus {
        getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusCallsCount += 1
        getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusReceivedGroupID = groupID
        getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusReceivedInvocations.append(groupID)
        if let error = getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusThrowableError {
            throw error
        }
        if let getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusClosure = getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusClosure {
            return try await getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusClosure(groupID)
        } else {
            return getConversationStatusGroupIDMLSGroupIDMLSVerificationStatusReturnValue
        }
    }


}
class EARKeyEncryptorInterfaceMock: EARKeyEncryptorInterface {




    //MARK: - encryptDatabaseKey

    var encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataThrowableError: (any Error)?
    var encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataCallsCount = 0
    var encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataCalled: Bool {
        return encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataCallsCount > 0
    }
    var encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataReceivedArguments: (databaseKey: Data, publicKey: SecKey)?
    var encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataReceivedInvocations: [(databaseKey: Data, publicKey: SecKey)] = []
    var encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataReturnValue: Data!
    var encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataClosure: ((Data, SecKey) throws -> Data)?

    func encryptDatabaseKey(_ databaseKey: Data, publicKey: SecKey) throws -> Data {
        encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataCallsCount += 1
        encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataReceivedArguments = (databaseKey: databaseKey, publicKey: publicKey)
        encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataReceivedInvocations.append((databaseKey: databaseKey, publicKey: publicKey))
        if let error = encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataThrowableError {
            throw error
        }
        if let encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataClosure = encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataClosure {
            return try encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataClosure(databaseKey, publicKey)
        } else {
            return encryptDatabaseKeyDatabaseKeyDataPublicKeySecKeyDataReturnValue
        }
    }

    //MARK: - decryptDatabaseKey

    var decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataThrowableError: (any Error)?
    var decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataCallsCount = 0
    var decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataCalled: Bool {
        return decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataCallsCount > 0
    }
    var decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataReceivedArguments: (encryptedDatabaseKey: Data, privateKey: SecKey)?
    var decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataReceivedInvocations: [(encryptedDatabaseKey: Data, privateKey: SecKey)] = []
    var decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataReturnValue: Data!
    var decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataClosure: ((Data, SecKey) throws -> Data)?

    func decryptDatabaseKey(_ encryptedDatabaseKey: Data, privateKey: SecKey) throws -> Data {
        decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataCallsCount += 1
        decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataReceivedArguments = (encryptedDatabaseKey: encryptedDatabaseKey, privateKey: privateKey)
        decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataReceivedInvocations.append((encryptedDatabaseKey: encryptedDatabaseKey, privateKey: privateKey))
        if let error = decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataThrowableError {
            throw error
        }
        if let decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataClosure = decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataClosure {
            return try decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataClosure(encryptedDatabaseKey, privateKey)
        } else {
            return decryptDatabaseKeyEncryptedDatabaseKeyDataPrivateKeySecKeyDataReturnValue
        }
    }


}
class EARKeyRepositoryInterfaceMock: EARKeyRepositoryInterface {




    //MARK: - storePublicKey

    var storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidThrowableError: (any Error)?
    var storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidCallsCount = 0
    var storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidCalled: Bool {
        return storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidCallsCount > 0
    }
    var storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidReceivedArguments: (description: PublicEARKeyDescription, key: SecKey)?
    var storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidReceivedInvocations: [(description: PublicEARKeyDescription, key: SecKey)] = []
    var storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidClosure: ((PublicEARKeyDescription, SecKey) throws -> Void)?

    func storePublicKey(description: PublicEARKeyDescription, key: SecKey) throws {
        storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidCallsCount += 1
        storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidReceivedArguments = (description: description, key: key)
        storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidReceivedInvocations.append((description: description, key: key))
        if let error = storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidThrowableError {
            throw error
        }
        try storePublicKeyDescriptionPublicEARKeyDescriptionKeySecKeyVoidClosure?(description, key)
    }

    //MARK: - fetchPublicKey

    var fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyThrowableError: (any Error)?
    var fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyCallsCount = 0
    var fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyCalled: Bool {
        return fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyCallsCount > 0
    }
    var fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyReceivedDescription: (PublicEARKeyDescription)?
    var fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyReceivedInvocations: [(PublicEARKeyDescription)] = []
    var fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyReturnValue: SecKey!
    var fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyClosure: ((PublicEARKeyDescription) throws -> SecKey)?

    func fetchPublicKey(description: PublicEARKeyDescription) throws -> SecKey {
        fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyCallsCount += 1
        fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyReceivedDescription = description
        fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyReceivedInvocations.append(description)
        if let error = fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyThrowableError {
            throw error
        }
        if let fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyClosure = fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyClosure {
            return try fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyClosure(description)
        } else {
            return fetchPublicKeyDescriptionPublicEARKeyDescriptionSecKeyReturnValue
        }
    }

    //MARK: - deletePublicKey

    var deletePublicKeyDescriptionPublicEARKeyDescriptionVoidThrowableError: (any Error)?
    var deletePublicKeyDescriptionPublicEARKeyDescriptionVoidCallsCount = 0
    var deletePublicKeyDescriptionPublicEARKeyDescriptionVoidCalled: Bool {
        return deletePublicKeyDescriptionPublicEARKeyDescriptionVoidCallsCount > 0
    }
    var deletePublicKeyDescriptionPublicEARKeyDescriptionVoidReceivedDescription: (PublicEARKeyDescription)?
    var deletePublicKeyDescriptionPublicEARKeyDescriptionVoidReceivedInvocations: [(PublicEARKeyDescription)] = []
    var deletePublicKeyDescriptionPublicEARKeyDescriptionVoidClosure: ((PublicEARKeyDescription) throws -> Void)?

    func deletePublicKey(description: PublicEARKeyDescription) throws {
        deletePublicKeyDescriptionPublicEARKeyDescriptionVoidCallsCount += 1
        deletePublicKeyDescriptionPublicEARKeyDescriptionVoidReceivedDescription = description
        deletePublicKeyDescriptionPublicEARKeyDescriptionVoidReceivedInvocations.append(description)
        if let error = deletePublicKeyDescriptionPublicEARKeyDescriptionVoidThrowableError {
            throw error
        }
        try deletePublicKeyDescriptionPublicEARKeyDescriptionVoidClosure?(description)
    }

    //MARK: - fetchPrivateKey

    var fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyThrowableError: (any Error)?
    var fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyCallsCount = 0
    var fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyCalled: Bool {
        return fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyCallsCount > 0
    }
    var fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyReceivedDescription: (PrivateEARKeyDescription)?
    var fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyReceivedInvocations: [(PrivateEARKeyDescription)] = []
    var fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyReturnValue: SecKey!
    var fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyClosure: ((PrivateEARKeyDescription) throws -> SecKey)?

    func fetchPrivateKey(description: PrivateEARKeyDescription) throws -> SecKey {
        fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyCallsCount += 1
        fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyReceivedDescription = description
        fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyReceivedInvocations.append(description)
        if let error = fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyThrowableError {
            throw error
        }
        if let fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyClosure = fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyClosure {
            return try fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyClosure(description)
        } else {
            return fetchPrivateKeyDescriptionPrivateEARKeyDescriptionSecKeyReturnValue
        }
    }

    //MARK: - deletePrivateKey

    var deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidThrowableError: (any Error)?
    var deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidCallsCount = 0
    var deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidCalled: Bool {
        return deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidCallsCount > 0
    }
    var deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidReceivedDescription: (PrivateEARKeyDescription)?
    var deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidReceivedInvocations: [(PrivateEARKeyDescription)] = []
    var deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidClosure: ((PrivateEARKeyDescription) throws -> Void)?

    func deletePrivateKey(description: PrivateEARKeyDescription) throws {
        deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidCallsCount += 1
        deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidReceivedDescription = description
        deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidReceivedInvocations.append(description)
        if let error = deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidThrowableError {
            throw error
        }
        try deletePrivateKeyDescriptionPrivateEARKeyDescriptionVoidClosure?(description)
    }

    //MARK: - storeDatabaseKey

    var storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidThrowableError: (any Error)?
    var storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidCallsCount = 0
    var storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidCalled: Bool {
        return storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidCallsCount > 0
    }
    var storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidReceivedArguments: (description: DatabaseEARKeyDescription, key: Data)?
    var storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidReceivedInvocations: [(description: DatabaseEARKeyDescription, key: Data)] = []
    var storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidClosure: ((DatabaseEARKeyDescription, Data) throws -> Void)?

    func storeDatabaseKey(description: DatabaseEARKeyDescription, key: Data) throws {
        storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidCallsCount += 1
        storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidReceivedArguments = (description: description, key: key)
        storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidReceivedInvocations.append((description: description, key: key))
        if let error = storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidThrowableError {
            throw error
        }
        try storeDatabaseKeyDescriptionDatabaseEARKeyDescriptionKeyDataVoidClosure?(description, key)
    }

    //MARK: - fetchDatabaseKey

    var fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataThrowableError: (any Error)?
    var fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataCallsCount = 0
    var fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataCalled: Bool {
        return fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataCallsCount > 0
    }
    var fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataReceivedDescription: (DatabaseEARKeyDescription)?
    var fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataReceivedInvocations: [(DatabaseEARKeyDescription)] = []
    var fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataReturnValue: Data!
    var fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataClosure: ((DatabaseEARKeyDescription) throws -> Data)?

    func fetchDatabaseKey(description: DatabaseEARKeyDescription) throws -> Data {
        fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataCallsCount += 1
        fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataReceivedDescription = description
        fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataReceivedInvocations.append(description)
        if let error = fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataThrowableError {
            throw error
        }
        if let fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataClosure = fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataClosure {
            return try fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataClosure(description)
        } else {
            return fetchDatabaseKeyDescriptionDatabaseEARKeyDescriptionDataReturnValue
        }
    }

    //MARK: - deleteDatabaseKey

    var deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidThrowableError: (any Error)?
    var deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidCallsCount = 0
    var deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidCalled: Bool {
        return deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidCallsCount > 0
    }
    var deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidReceivedDescription: (DatabaseEARKeyDescription)?
    var deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidReceivedInvocations: [(DatabaseEARKeyDescription)] = []
    var deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidClosure: ((DatabaseEARKeyDescription) throws -> Void)?

    func deleteDatabaseKey(description: DatabaseEARKeyDescription) throws {
        deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidCallsCount += 1
        deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidReceivedDescription = description
        deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidReceivedInvocations.append(description)
        if let error = deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidThrowableError {
            throw error
        }
        try deleteDatabaseKeyDescriptionDatabaseEARKeyDescriptionVoidClosure?(description)
    }

    //MARK: - clearCache

    var clearCacheVoidCallsCount = 0
    var clearCacheVoidCalled: Bool {
        return clearCacheVoidCallsCount > 0
    }
    var clearCacheVoidClosure: (() -> Void)?

    func clearCache() {
        clearCacheVoidCallsCount += 1
        clearCacheVoidClosure?()
    }


}
public class EARServiceInterfaceMock: EARServiceInterface {

    public init() {}

    public var delegate: EARServiceDelegate?


    //MARK: - enableEncryptionAtRest

    public var enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidThrowableError: (any Error)?
    public var enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidCallsCount = 0
    public var enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidCalled: Bool {
        return enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidCallsCount > 0
    }
    public var enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidReceivedArguments: (context: NSManagedObjectContext, skipMigration: Bool)?
    public var enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidReceivedInvocations: [(context: NSManagedObjectContext, skipMigration: Bool)] = []
    public var enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidClosure: ((NSManagedObjectContext, Bool) throws -> Void)?

    public func enableEncryptionAtRest(context: NSManagedObjectContext, skipMigration: Bool) throws {
        enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidCallsCount += 1
        enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidReceivedArguments = (context: context, skipMigration: skipMigration)
        enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidReceivedInvocations.append((context: context, skipMigration: skipMigration))
        if let error = enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidThrowableError {
            throw error
        }
        try enableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidClosure?(context, skipMigration)
    }

    //MARK: - disableEncryptionAtRest

    public var disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidThrowableError: (any Error)?
    public var disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidCallsCount = 0
    public var disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidCalled: Bool {
        return disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidCallsCount > 0
    }
    public var disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidReceivedArguments: (context: NSManagedObjectContext, skipMigration: Bool)?
    public var disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidReceivedInvocations: [(context: NSManagedObjectContext, skipMigration: Bool)] = []
    public var disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidClosure: ((NSManagedObjectContext, Bool) throws -> Void)?

    public func disableEncryptionAtRest(context: NSManagedObjectContext, skipMigration: Bool) throws {
        disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidCallsCount += 1
        disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidReceivedArguments = (context: context, skipMigration: skipMigration)
        disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidReceivedInvocations.append((context: context, skipMigration: skipMigration))
        if let error = disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidThrowableError {
            throw error
        }
        try disableEncryptionAtRestContextNSManagedObjectContextSkipMigrationBoolVoidClosure?(context, skipMigration)
    }

    //MARK: - lockDatabase

    public var lockDatabaseVoidCallsCount = 0
    public var lockDatabaseVoidCalled: Bool {
        return lockDatabaseVoidCallsCount > 0
    }
    public var lockDatabaseVoidClosure: (() -> Void)?

    public func lockDatabase() {
        lockDatabaseVoidCallsCount += 1
        lockDatabaseVoidClosure?()
    }

    //MARK: - unlockDatabase

    public var unlockDatabaseVoidThrowableError: (any Error)?
    public var unlockDatabaseVoidCallsCount = 0
    public var unlockDatabaseVoidCalled: Bool {
        return unlockDatabaseVoidCallsCount > 0
    }
    public var unlockDatabaseVoidClosure: (() throws -> Void)?

    public func unlockDatabase() throws {
        unlockDatabaseVoidCallsCount += 1
        if let error = unlockDatabaseVoidThrowableError {
            throw error
        }
        try unlockDatabaseVoidClosure?()
    }

    //MARK: - fetchPublicKeys

    public var fetchPublicKeysEARPublicKeysThrowableError: (any Error)?
    public var fetchPublicKeysEARPublicKeysCallsCount = 0
    public var fetchPublicKeysEARPublicKeysCalled: Bool {
        return fetchPublicKeysEARPublicKeysCallsCount > 0
    }
    public var fetchPublicKeysEARPublicKeysReturnValue: EARPublicKeys?
    public var fetchPublicKeysEARPublicKeysClosure: (() throws -> EARPublicKeys?)?

    public func fetchPublicKeys() throws -> EARPublicKeys? {
        fetchPublicKeysEARPublicKeysCallsCount += 1
        if let error = fetchPublicKeysEARPublicKeysThrowableError {
            throw error
        }
        if let fetchPublicKeysEARPublicKeysClosure = fetchPublicKeysEARPublicKeysClosure {
            return try fetchPublicKeysEARPublicKeysClosure()
        } else {
            return fetchPublicKeysEARPublicKeysReturnValue
        }
    }

    //MARK: - fetchPrivateKeys

    public var fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysThrowableError: (any Error)?
    public var fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysCallsCount = 0
    public var fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysCalled: Bool {
        return fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysCallsCount > 0
    }
    public var fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysReceivedIncludingPrimary: (Bool)?
    public var fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysReceivedInvocations: [(Bool)] = []
    public var fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysReturnValue: EARPrivateKeys?
    public var fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysClosure: ((Bool) throws -> EARPrivateKeys?)?

    public func fetchPrivateKeys(includingPrimary: Bool) throws -> EARPrivateKeys? {
        fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysCallsCount += 1
        fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysReceivedIncludingPrimary = includingPrimary
        fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysReceivedInvocations.append(includingPrimary)
        if let error = fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysThrowableError {
            throw error
        }
        if let fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysClosure = fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysClosure {
            return try fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysClosure(includingPrimary)
        } else {
            return fetchPrivateKeysIncludingPrimaryBoolEARPrivateKeysReturnValue
        }
    }

    //MARK: - setInitialEARFlagValue

    public var setInitialEARFlagValueEnabledBoolVoidCallsCount = 0
    public var setInitialEARFlagValueEnabledBoolVoidCalled: Bool {
        return setInitialEARFlagValueEnabledBoolVoidCallsCount > 0
    }
    public var setInitialEARFlagValueEnabledBoolVoidReceivedEnabled: (Bool)?
    public var setInitialEARFlagValueEnabledBoolVoidReceivedInvocations: [(Bool)] = []
    public var setInitialEARFlagValueEnabledBoolVoidClosure: ((Bool) -> Void)?

    public func setInitialEARFlagValue(_ enabled: Bool) {
        setInitialEARFlagValueEnabledBoolVoidCallsCount += 1
        setInitialEARFlagValueEnabledBoolVoidReceivedEnabled = enabled
        setInitialEARFlagValueEnabledBoolVoidReceivedInvocations.append(enabled)
        setInitialEARFlagValueEnabledBoolVoidClosure?(enabled)
    }


}
public class FeatureRepositoryInterfaceMock: FeatureRepositoryInterface {

    public init() {}



    //MARK: - fetchAppLock

    public var fetchAppLockFeatureAppLockCallsCount = 0
    public var fetchAppLockFeatureAppLockCalled: Bool {
        return fetchAppLockFeatureAppLockCallsCount > 0
    }
    public var fetchAppLockFeatureAppLockReturnValue: Feature.AppLock!
    public var fetchAppLockFeatureAppLockClosure: (() -> Feature.AppLock)?

    public func fetchAppLock() -> Feature.AppLock {
        fetchAppLockFeatureAppLockCallsCount += 1
        if let fetchAppLockFeatureAppLockClosure = fetchAppLockFeatureAppLockClosure {
            return fetchAppLockFeatureAppLockClosure()
        } else {
            return fetchAppLockFeatureAppLockReturnValue
        }
    }

    //MARK: - storeAppLock

    public var storeAppLockAppLockFeatureAppLockVoidCallsCount = 0
    public var storeAppLockAppLockFeatureAppLockVoidCalled: Bool {
        return storeAppLockAppLockFeatureAppLockVoidCallsCount > 0
    }
    public var storeAppLockAppLockFeatureAppLockVoidReceivedAppLock: (Feature.AppLock)?
    public var storeAppLockAppLockFeatureAppLockVoidReceivedInvocations: [(Feature.AppLock)] = []
    public var storeAppLockAppLockFeatureAppLockVoidClosure: ((Feature.AppLock) -> Void)?

    public func storeAppLock(_ appLock: Feature.AppLock) {
        storeAppLockAppLockFeatureAppLockVoidCallsCount += 1
        storeAppLockAppLockFeatureAppLockVoidReceivedAppLock = appLock
        storeAppLockAppLockFeatureAppLockVoidReceivedInvocations.append(appLock)
        storeAppLockAppLockFeatureAppLockVoidClosure?(appLock)
    }

    //MARK: - fetchConferenceCalling

    public var fetchConferenceCallingFeatureConferenceCallingCallsCount = 0
    public var fetchConferenceCallingFeatureConferenceCallingCalled: Bool {
        return fetchConferenceCallingFeatureConferenceCallingCallsCount > 0
    }
    public var fetchConferenceCallingFeatureConferenceCallingReturnValue: Feature.ConferenceCalling!
    public var fetchConferenceCallingFeatureConferenceCallingClosure: (() -> Feature.ConferenceCalling)?

    public func fetchConferenceCalling() -> Feature.ConferenceCalling {
        fetchConferenceCallingFeatureConferenceCallingCallsCount += 1
        if let fetchConferenceCallingFeatureConferenceCallingClosure = fetchConferenceCallingFeatureConferenceCallingClosure {
            return fetchConferenceCallingFeatureConferenceCallingClosure()
        } else {
            return fetchConferenceCallingFeatureConferenceCallingReturnValue
        }
    }

    //MARK: - storeConferenceCalling

    public var storeConferenceCallingConferenceCallingFeatureConferenceCallingVoidCallsCount = 0
    public var storeConferenceCallingConferenceCallingFeatureConferenceCallingVoidCalled: Bool {
        return storeConferenceCallingConferenceCallingFeatureConferenceCallingVoidCallsCount > 0
    }
    public var storeConferenceCallingConferenceCallingFeatureConferenceCallingVoidReceivedConferenceCalling: (Feature.ConferenceCalling)?
    public var storeConferenceCallingConferenceCallingFeatureConferenceCallingVoidReceivedInvocations: [(Feature.ConferenceCalling)] = []
    public var storeConferenceCallingConferenceCallingFeatureConferenceCallingVoidClosure: ((Feature.ConferenceCalling) -> Void)?

    public func storeConferenceCalling(_ conferenceCalling: Feature.ConferenceCalling) {
        storeConferenceCallingConferenceCallingFeatureConferenceCallingVoidCallsCount += 1
        storeConferenceCallingConferenceCallingFeatureConferenceCallingVoidReceivedConferenceCalling = conferenceCalling
        storeConferenceCallingConferenceCallingFeatureConferenceCallingVoidReceivedInvocations.append(conferenceCalling)
        storeConferenceCallingConferenceCallingFeatureConferenceCallingVoidClosure?(conferenceCalling)
    }

    //MARK: - fetchFileSharing

    public var fetchFileSharingFeatureFileSharingCallsCount = 0
    public var fetchFileSharingFeatureFileSharingCalled: Bool {
        return fetchFileSharingFeatureFileSharingCallsCount > 0
    }
    public var fetchFileSharingFeatureFileSharingReturnValue: Feature.FileSharing!
    public var fetchFileSharingFeatureFileSharingClosure: (() -> Feature.FileSharing)?

    public func fetchFileSharing() -> Feature.FileSharing {
        fetchFileSharingFeatureFileSharingCallsCount += 1
        if let fetchFileSharingFeatureFileSharingClosure = fetchFileSharingFeatureFileSharingClosure {
            return fetchFileSharingFeatureFileSharingClosure()
        } else {
            return fetchFileSharingFeatureFileSharingReturnValue
        }
    }

    //MARK: - storeFileSharing

    public var storeFileSharingFileSharingFeatureFileSharingVoidCallsCount = 0
    public var storeFileSharingFileSharingFeatureFileSharingVoidCalled: Bool {
        return storeFileSharingFileSharingFeatureFileSharingVoidCallsCount > 0
    }
    public var storeFileSharingFileSharingFeatureFileSharingVoidReceivedFileSharing: (Feature.FileSharing)?
    public var storeFileSharingFileSharingFeatureFileSharingVoidReceivedInvocations: [(Feature.FileSharing)] = []
    public var storeFileSharingFileSharingFeatureFileSharingVoidClosure: ((Feature.FileSharing) -> Void)?

    public func storeFileSharing(_ fileSharing: Feature.FileSharing) {
        storeFileSharingFileSharingFeatureFileSharingVoidCallsCount += 1
        storeFileSharingFileSharingFeatureFileSharingVoidReceivedFileSharing = fileSharing
        storeFileSharingFileSharingFeatureFileSharingVoidReceivedInvocations.append(fileSharing)
        storeFileSharingFileSharingFeatureFileSharingVoidClosure?(fileSharing)
    }

    //MARK: - fetchSelfDeletingMesssages

    public var fetchSelfDeletingMesssagesFeatureSelfDeletingMessagesCallsCount = 0
    public var fetchSelfDeletingMesssagesFeatureSelfDeletingMessagesCalled: Bool {
        return fetchSelfDeletingMesssagesFeatureSelfDeletingMessagesCallsCount > 0
    }
    public var fetchSelfDeletingMesssagesFeatureSelfDeletingMessagesReturnValue: Feature.SelfDeletingMessages!
    public var fetchSelfDeletingMesssagesFeatureSelfDeletingMessagesClosure: (() -> Feature.SelfDeletingMessages)?

    public func fetchSelfDeletingMesssages() -> Feature.SelfDeletingMessages {
        fetchSelfDeletingMesssagesFeatureSelfDeletingMessagesCallsCount += 1
        if let fetchSelfDeletingMesssagesFeatureSelfDeletingMessagesClosure = fetchSelfDeletingMesssagesFeatureSelfDeletingMessagesClosure {
            return fetchSelfDeletingMesssagesFeatureSelfDeletingMessagesClosure()
        } else {
            return fetchSelfDeletingMesssagesFeatureSelfDeletingMessagesReturnValue
        }
    }

    //MARK: - storeSelfDeletingMessages

    public var storeSelfDeletingMessagesSelfDeletingMessagesFeatureSelfDeletingMessagesVoidCallsCount = 0
    public var storeSelfDeletingMessagesSelfDeletingMessagesFeatureSelfDeletingMessagesVoidCalled: Bool {
        return storeSelfDeletingMessagesSelfDeletingMessagesFeatureSelfDeletingMessagesVoidCallsCount > 0
    }
    public var storeSelfDeletingMessagesSelfDeletingMessagesFeatureSelfDeletingMessagesVoidReceivedSelfDeletingMessages: (Feature.SelfDeletingMessages)?
    public var storeSelfDeletingMessagesSelfDeletingMessagesFeatureSelfDeletingMessagesVoidReceivedInvocations: [(Feature.SelfDeletingMessages)] = []
    public var storeSelfDeletingMessagesSelfDeletingMessagesFeatureSelfDeletingMessagesVoidClosure: ((Feature.SelfDeletingMessages) -> Void)?

    public func storeSelfDeletingMessages(_ selfDeletingMessages: Feature.SelfDeletingMessages) {
        storeSelfDeletingMessagesSelfDeletingMessagesFeatureSelfDeletingMessagesVoidCallsCount += 1
        storeSelfDeletingMessagesSelfDeletingMessagesFeatureSelfDeletingMessagesVoidReceivedSelfDeletingMessages = selfDeletingMessages
        storeSelfDeletingMessagesSelfDeletingMessagesFeatureSelfDeletingMessagesVoidReceivedInvocations.append(selfDeletingMessages)
        storeSelfDeletingMessagesSelfDeletingMessagesFeatureSelfDeletingMessagesVoidClosure?(selfDeletingMessages)
    }

    //MARK: - fetchConversationGuestLinks

    public var fetchConversationGuestLinksFeatureConversationGuestLinksCallsCount = 0
    public var fetchConversationGuestLinksFeatureConversationGuestLinksCalled: Bool {
        return fetchConversationGuestLinksFeatureConversationGuestLinksCallsCount > 0
    }
    public var fetchConversationGuestLinksFeatureConversationGuestLinksReturnValue: Feature.ConversationGuestLinks!
    public var fetchConversationGuestLinksFeatureConversationGuestLinksClosure: (() -> Feature.ConversationGuestLinks)?

    public func fetchConversationGuestLinks() -> Feature.ConversationGuestLinks {
        fetchConversationGuestLinksFeatureConversationGuestLinksCallsCount += 1
        if let fetchConversationGuestLinksFeatureConversationGuestLinksClosure = fetchConversationGuestLinksFeatureConversationGuestLinksClosure {
            return fetchConversationGuestLinksFeatureConversationGuestLinksClosure()
        } else {
            return fetchConversationGuestLinksFeatureConversationGuestLinksReturnValue
        }
    }

    //MARK: - storeConversationGuestLinks

    public var storeConversationGuestLinksConversationGuestLinksFeatureConversationGuestLinksVoidCallsCount = 0
    public var storeConversationGuestLinksConversationGuestLinksFeatureConversationGuestLinksVoidCalled: Bool {
        return storeConversationGuestLinksConversationGuestLinksFeatureConversationGuestLinksVoidCallsCount > 0
    }
    public var storeConversationGuestLinksConversationGuestLinksFeatureConversationGuestLinksVoidReceivedConversationGuestLinks: (Feature.ConversationGuestLinks)?
    public var storeConversationGuestLinksConversationGuestLinksFeatureConversationGuestLinksVoidReceivedInvocations: [(Feature.ConversationGuestLinks)] = []
    public var storeConversationGuestLinksConversationGuestLinksFeatureConversationGuestLinksVoidClosure: ((Feature.ConversationGuestLinks) -> Void)?

    public func storeConversationGuestLinks(_ conversationGuestLinks: Feature.ConversationGuestLinks) {
        storeConversationGuestLinksConversationGuestLinksFeatureConversationGuestLinksVoidCallsCount += 1
        storeConversationGuestLinksConversationGuestLinksFeatureConversationGuestLinksVoidReceivedConversationGuestLinks = conversationGuestLinks
        storeConversationGuestLinksConversationGuestLinksFeatureConversationGuestLinksVoidReceivedInvocations.append(conversationGuestLinks)
        storeConversationGuestLinksConversationGuestLinksFeatureConversationGuestLinksVoidClosure?(conversationGuestLinks)
    }

    //MARK: - fetchClassifiedDomains

    public var fetchClassifiedDomainsFeatureClassifiedDomainsCallsCount = 0
    public var fetchClassifiedDomainsFeatureClassifiedDomainsCalled: Bool {
        return fetchClassifiedDomainsFeatureClassifiedDomainsCallsCount > 0
    }
    public var fetchClassifiedDomainsFeatureClassifiedDomainsReturnValue: Feature.ClassifiedDomains!
    public var fetchClassifiedDomainsFeatureClassifiedDomainsClosure: (() -> Feature.ClassifiedDomains)?

    public func fetchClassifiedDomains() -> Feature.ClassifiedDomains {
        fetchClassifiedDomainsFeatureClassifiedDomainsCallsCount += 1
        if let fetchClassifiedDomainsFeatureClassifiedDomainsClosure = fetchClassifiedDomainsFeatureClassifiedDomainsClosure {
            return fetchClassifiedDomainsFeatureClassifiedDomainsClosure()
        } else {
            return fetchClassifiedDomainsFeatureClassifiedDomainsReturnValue
        }
    }

    //MARK: - storeClassifiedDomains

    public var storeClassifiedDomainsClassifiedDomainsFeatureClassifiedDomainsVoidCallsCount = 0
    public var storeClassifiedDomainsClassifiedDomainsFeatureClassifiedDomainsVoidCalled: Bool {
        return storeClassifiedDomainsClassifiedDomainsFeatureClassifiedDomainsVoidCallsCount > 0
    }
    public var storeClassifiedDomainsClassifiedDomainsFeatureClassifiedDomainsVoidReceivedClassifiedDomains: (Feature.ClassifiedDomains)?
    public var storeClassifiedDomainsClassifiedDomainsFeatureClassifiedDomainsVoidReceivedInvocations: [(Feature.ClassifiedDomains)] = []
    public var storeClassifiedDomainsClassifiedDomainsFeatureClassifiedDomainsVoidClosure: ((Feature.ClassifiedDomains) -> Void)?

    public func storeClassifiedDomains(_ classifiedDomains: Feature.ClassifiedDomains) {
        storeClassifiedDomainsClassifiedDomainsFeatureClassifiedDomainsVoidCallsCount += 1
        storeClassifiedDomainsClassifiedDomainsFeatureClassifiedDomainsVoidReceivedClassifiedDomains = classifiedDomains
        storeClassifiedDomainsClassifiedDomainsFeatureClassifiedDomainsVoidReceivedInvocations.append(classifiedDomains)
        storeClassifiedDomainsClassifiedDomainsFeatureClassifiedDomainsVoidClosure?(classifiedDomains)
    }

    //MARK: - fetchDigitalSignature

    public var fetchDigitalSignatureFeatureDigitalSignatureCallsCount = 0
    public var fetchDigitalSignatureFeatureDigitalSignatureCalled: Bool {
        return fetchDigitalSignatureFeatureDigitalSignatureCallsCount > 0
    }
    public var fetchDigitalSignatureFeatureDigitalSignatureReturnValue: Feature.DigitalSignature!
    public var fetchDigitalSignatureFeatureDigitalSignatureClosure: (() -> Feature.DigitalSignature)?

    public func fetchDigitalSignature() -> Feature.DigitalSignature {
        fetchDigitalSignatureFeatureDigitalSignatureCallsCount += 1
        if let fetchDigitalSignatureFeatureDigitalSignatureClosure = fetchDigitalSignatureFeatureDigitalSignatureClosure {
            return fetchDigitalSignatureFeatureDigitalSignatureClosure()
        } else {
            return fetchDigitalSignatureFeatureDigitalSignatureReturnValue
        }
    }

    //MARK: - storeDigitalSignature

    public var storeDigitalSignatureDigitalSignatureFeatureDigitalSignatureVoidCallsCount = 0
    public var storeDigitalSignatureDigitalSignatureFeatureDigitalSignatureVoidCalled: Bool {
        return storeDigitalSignatureDigitalSignatureFeatureDigitalSignatureVoidCallsCount > 0
    }
    public var storeDigitalSignatureDigitalSignatureFeatureDigitalSignatureVoidReceivedDigitalSignature: (Feature.DigitalSignature)?
    public var storeDigitalSignatureDigitalSignatureFeatureDigitalSignatureVoidReceivedInvocations: [(Feature.DigitalSignature)] = []
    public var storeDigitalSignatureDigitalSignatureFeatureDigitalSignatureVoidClosure: ((Feature.DigitalSignature) -> Void)?

    public func storeDigitalSignature(_ digitalSignature: Feature.DigitalSignature) {
        storeDigitalSignatureDigitalSignatureFeatureDigitalSignatureVoidCallsCount += 1
        storeDigitalSignatureDigitalSignatureFeatureDigitalSignatureVoidReceivedDigitalSignature = digitalSignature
        storeDigitalSignatureDigitalSignatureFeatureDigitalSignatureVoidReceivedInvocations.append(digitalSignature)
        storeDigitalSignatureDigitalSignatureFeatureDigitalSignatureVoidClosure?(digitalSignature)
    }

    //MARK: - fetchMLS

    public var fetchMLSFeatureMLSCallsCount = 0
    public var fetchMLSFeatureMLSCalled: Bool {
        return fetchMLSFeatureMLSCallsCount > 0
    }
    public var fetchMLSFeatureMLSReturnValue: Feature.MLS!
    public var fetchMLSFeatureMLSClosure: (() -> Feature.MLS)?

    public func fetchMLS() -> Feature.MLS {
        fetchMLSFeatureMLSCallsCount += 1
        if let fetchMLSFeatureMLSClosure = fetchMLSFeatureMLSClosure {
            return fetchMLSFeatureMLSClosure()
        } else {
            return fetchMLSFeatureMLSReturnValue
        }
    }

    //MARK: - storeMLS

    public var storeMLSMlsFeatureMLSVoidCallsCount = 0
    public var storeMLSMlsFeatureMLSVoidCalled: Bool {
        return storeMLSMlsFeatureMLSVoidCallsCount > 0
    }
    public var storeMLSMlsFeatureMLSVoidReceivedMls: (Feature.MLS)?
    public var storeMLSMlsFeatureMLSVoidReceivedInvocations: [(Feature.MLS)] = []
    public var storeMLSMlsFeatureMLSVoidClosure: ((Feature.MLS) -> Void)?

    public func storeMLS(_ mls: Feature.MLS) {
        storeMLSMlsFeatureMLSVoidCallsCount += 1
        storeMLSMlsFeatureMLSVoidReceivedMls = mls
        storeMLSMlsFeatureMLSVoidReceivedInvocations.append(mls)
        storeMLSMlsFeatureMLSVoidClosure?(mls)
    }

    //MARK: - fetchE2EI

    public var fetchE2EIFeatureE2EICallsCount = 0
    public var fetchE2EIFeatureE2EICalled: Bool {
        return fetchE2EIFeatureE2EICallsCount > 0
    }
    public var fetchE2EIFeatureE2EIReturnValue: Feature.E2EI!
    public var fetchE2EIFeatureE2EIClosure: (() -> Feature.E2EI)?

    public func fetchE2EI() -> Feature.E2EI {
        fetchE2EIFeatureE2EICallsCount += 1
        if let fetchE2EIFeatureE2EIClosure = fetchE2EIFeatureE2EIClosure {
            return fetchE2EIFeatureE2EIClosure()
        } else {
            return fetchE2EIFeatureE2EIReturnValue
        }
    }

    //MARK: - storeE2EI

    public var storeE2EIE2eiFeatureE2EIVoidCallsCount = 0
    public var storeE2EIE2eiFeatureE2EIVoidCalled: Bool {
        return storeE2EIE2eiFeatureE2EIVoidCallsCount > 0
    }
    public var storeE2EIE2eiFeatureE2EIVoidReceivedE2ei: (Feature.E2EI)?
    public var storeE2EIE2eiFeatureE2EIVoidReceivedInvocations: [(Feature.E2EI)] = []
    public var storeE2EIE2eiFeatureE2EIVoidClosure: ((Feature.E2EI) -> Void)?

    public func storeE2EI(_ e2ei: Feature.E2EI) {
        storeE2EIE2eiFeatureE2EIVoidCallsCount += 1
        storeE2EIE2eiFeatureE2EIVoidReceivedE2ei = e2ei
        storeE2EIE2eiFeatureE2EIVoidReceivedInvocations.append(e2ei)
        storeE2EIE2eiFeatureE2EIVoidClosure?(e2ei)
    }

    //MARK: - fetchMLSMigration

    public var fetchMLSMigrationFeatureMLSMigrationCallsCount = 0
    public var fetchMLSMigrationFeatureMLSMigrationCalled: Bool {
        return fetchMLSMigrationFeatureMLSMigrationCallsCount > 0
    }
    public var fetchMLSMigrationFeatureMLSMigrationReturnValue: Feature.MLSMigration!
    public var fetchMLSMigrationFeatureMLSMigrationClosure: (() -> Feature.MLSMigration)?

    public func fetchMLSMigration() -> Feature.MLSMigration {
        fetchMLSMigrationFeatureMLSMigrationCallsCount += 1
        if let fetchMLSMigrationFeatureMLSMigrationClosure = fetchMLSMigrationFeatureMLSMigrationClosure {
            return fetchMLSMigrationFeatureMLSMigrationClosure()
        } else {
            return fetchMLSMigrationFeatureMLSMigrationReturnValue
        }
    }

    //MARK: - storeMLSMigration

    public var storeMLSMigrationMlsMigrationFeatureMLSMigrationVoidCallsCount = 0
    public var storeMLSMigrationMlsMigrationFeatureMLSMigrationVoidCalled: Bool {
        return storeMLSMigrationMlsMigrationFeatureMLSMigrationVoidCallsCount > 0
    }
    public var storeMLSMigrationMlsMigrationFeatureMLSMigrationVoidReceivedMlsMigration: (Feature.MLSMigration)?
    public var storeMLSMigrationMlsMigrationFeatureMLSMigrationVoidReceivedInvocations: [(Feature.MLSMigration)] = []
    public var storeMLSMigrationMlsMigrationFeatureMLSMigrationVoidClosure: ((Feature.MLSMigration) -> Void)?

    public func storeMLSMigration(_ mlsMigration: Feature.MLSMigration) {
        storeMLSMigrationMlsMigrationFeatureMLSMigrationVoidCallsCount += 1
        storeMLSMigrationMlsMigrationFeatureMLSMigrationVoidReceivedMlsMigration = mlsMigration
        storeMLSMigrationMlsMigrationFeatureMLSMigrationVoidReceivedInvocations.append(mlsMigration)
        storeMLSMigrationMlsMigrationFeatureMLSMigrationVoidClosure?(mlsMigration)
    }


}
class FileManagerInterfaceMock: FileManagerInterface {




    //MARK: - fileExists

    var fileExistsAtPathPathStringBoolCallsCount = 0
    var fileExistsAtPathPathStringBoolCalled: Bool {
        return fileExistsAtPathPathStringBoolCallsCount > 0
    }
    var fileExistsAtPathPathStringBoolReceivedPath: (String)?
    var fileExistsAtPathPathStringBoolReceivedInvocations: [(String)] = []
    var fileExistsAtPathPathStringBoolReturnValue: Bool!
    var fileExistsAtPathPathStringBoolClosure: ((String) -> Bool)?

    func fileExists(atPath path: String) -> Bool {
        fileExistsAtPathPathStringBoolCallsCount += 1
        fileExistsAtPathPathStringBoolReceivedPath = path
        fileExistsAtPathPathStringBoolReceivedInvocations.append(path)
        if let fileExistsAtPathPathStringBoolClosure = fileExistsAtPathPathStringBoolClosure {
            return fileExistsAtPathPathStringBoolClosure(path)
        } else {
            return fileExistsAtPathPathStringBoolReturnValue
        }
    }

    //MARK: - removeItem

    var removeItemAtUrlURLVoidThrowableError: (any Error)?
    var removeItemAtUrlURLVoidCallsCount = 0
    var removeItemAtUrlURLVoidCalled: Bool {
        return removeItemAtUrlURLVoidCallsCount > 0
    }
    var removeItemAtUrlURLVoidReceivedUrl: (URL)?
    var removeItemAtUrlURLVoidReceivedInvocations: [(URL)] = []
    var removeItemAtUrlURLVoidClosure: ((URL) throws -> Void)?

    func removeItem(at url: URL) throws {
        removeItemAtUrlURLVoidCallsCount += 1
        removeItemAtUrlURLVoidReceivedUrl = url
        removeItemAtUrlURLVoidReceivedInvocations.append(url)
        if let error = removeItemAtUrlURLVoidThrowableError {
            throw error
        }
        try removeItemAtUrlURLVoidClosure?(url)
    }

    //MARK: - cryptoboxDirectory

    var cryptoboxDirectoryInAccountDirectoryURLUrlCallsCount = 0
    var cryptoboxDirectoryInAccountDirectoryURLUrlCalled: Bool {
        return cryptoboxDirectoryInAccountDirectoryURLUrlCallsCount > 0
    }
    var cryptoboxDirectoryInAccountDirectoryURLUrlReceivedAccountDirectory: (URL)?
    var cryptoboxDirectoryInAccountDirectoryURLUrlReceivedInvocations: [(URL)] = []
    var cryptoboxDirectoryInAccountDirectoryURLUrlReturnValue: URL!
    var cryptoboxDirectoryInAccountDirectoryURLUrlClosure: ((URL) -> URL)?

    func cryptoboxDirectory(in accountDirectory: URL) -> URL {
        cryptoboxDirectoryInAccountDirectoryURLUrlCallsCount += 1
        cryptoboxDirectoryInAccountDirectoryURLUrlReceivedAccountDirectory = accountDirectory
        cryptoboxDirectoryInAccountDirectoryURLUrlReceivedInvocations.append(accountDirectory)
        if let cryptoboxDirectoryInAccountDirectoryURLUrlClosure = cryptoboxDirectoryInAccountDirectoryURLUrlClosure {
            return cryptoboxDirectoryInAccountDirectoryURLUrlClosure(accountDirectory)
        } else {
            return cryptoboxDirectoryInAccountDirectoryURLUrlReturnValue
        }
    }


}
public class IsSelfUserE2EICertifiedUseCaseProtocolMock: IsSelfUserE2EICertifiedUseCaseProtocol {

    public init() {}



    //MARK: - invoke

    public var invokeBoolThrowableError: (any Error)?
    public var invokeBoolCallsCount = 0
    public var invokeBoolCalled: Bool {
        return invokeBoolCallsCount > 0
    }
    public var invokeBoolReturnValue: Bool!
    public var invokeBoolClosure: (() async throws -> Bool)?

    public func invoke() async throws -> Bool {
        invokeBoolCallsCount += 1
        if let error = invokeBoolThrowableError {
            throw error
        }
        if let invokeBoolClosure = invokeBoolClosure {
            return try await invokeBoolClosure()
        } else {
            return invokeBoolReturnValue
        }
    }


}
public class IsUserE2EICertifiedUseCaseProtocolMock: IsUserE2EICertifiedUseCaseProtocol {

    public init() {}



    //MARK: - invoke

    public var invokeConversationZMConversationUserZMUserBoolThrowableError: (any Error)?
    public var invokeConversationZMConversationUserZMUserBoolCallsCount = 0
    public var invokeConversationZMConversationUserZMUserBoolCalled: Bool {
        return invokeConversationZMConversationUserZMUserBoolCallsCount > 0
    }
    public var invokeConversationZMConversationUserZMUserBoolReceivedArguments: (conversation: ZMConversation, user: ZMUser)?
    public var invokeConversationZMConversationUserZMUserBoolReceivedInvocations: [(conversation: ZMConversation, user: ZMUser)] = []
    public var invokeConversationZMConversationUserZMUserBoolReturnValue: Bool!
    public var invokeConversationZMConversationUserZMUserBoolClosure: ((ZMConversation, ZMUser) async throws -> Bool)?

    public func invoke(conversation: ZMConversation, user: ZMUser) async throws -> Bool {
        invokeConversationZMConversationUserZMUserBoolCallsCount += 1
        invokeConversationZMConversationUserZMUserBoolReceivedArguments = (conversation: conversation, user: user)
        invokeConversationZMConversationUserZMUserBoolReceivedInvocations.append((conversation: conversation, user: user))
        if let error = invokeConversationZMConversationUserZMUserBoolThrowableError {
            throw error
        }
        if let invokeConversationZMConversationUserZMUserBoolClosure = invokeConversationZMConversationUserZMUserBoolClosure {
            return try await invokeConversationZMConversationUserZMUserBoolClosure(conversation, user)
        } else {
            return invokeConversationZMConversationUserZMUserBoolReturnValue
        }
    }


}
public class LAContextStorableMock: LAContextStorable {

    public init() {}

    public var context: LAContext?


    //MARK: - clear

    public var clearVoidCallsCount = 0
    public var clearVoidCalled: Bool {
        return clearVoidCallsCount > 0
    }
    public var clearVoidClosure: (() -> Void)?

    public func clear() {
        clearVoidCallsCount += 1
        clearVoidClosure?()
    }


}
public class LastEventIDRepositoryInterfaceMock: LastEventIDRepositoryInterface {

    public init() {}



    //MARK: - fetchLastEventID

    public var fetchLastEventIDUuidCallsCount = 0
    public var fetchLastEventIDUuidCalled: Bool {
        return fetchLastEventIDUuidCallsCount > 0
    }
    public var fetchLastEventIDUuidReturnValue: UUID?
    public var fetchLastEventIDUuidClosure: (() -> UUID?)?

    public func fetchLastEventID() -> UUID? {
        fetchLastEventIDUuidCallsCount += 1
        if let fetchLastEventIDUuidClosure = fetchLastEventIDUuidClosure {
            return fetchLastEventIDUuidClosure()
        } else {
            return fetchLastEventIDUuidReturnValue
        }
    }

    //MARK: - storeLastEventID

    public var storeLastEventIDIdUUIDVoidCallsCount = 0
    public var storeLastEventIDIdUUIDVoidCalled: Bool {
        return storeLastEventIDIdUUIDVoidCallsCount > 0
    }
    public var storeLastEventIDIdUUIDVoidReceivedId: (UUID)?
    public var storeLastEventIDIdUUIDVoidReceivedInvocations: [(UUID)?] = []
    public var storeLastEventIDIdUUIDVoidClosure: ((UUID?) -> Void)?

    public func storeLastEventID(_ id: UUID?) {
        storeLastEventIDIdUUIDVoidCallsCount += 1
        storeLastEventIDIdUUIDVoidReceivedId = id
        storeLastEventIDIdUUIDVoidReceivedInvocations.append(id)
        storeLastEventIDIdUUIDVoidClosure?(id)
    }


}
class MLSActionsProviderProtocolMock: MLSActionsProviderProtocol {




    //MARK: - fetchBackendPublicKeys

    var fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysThrowableError: (any Error)?
    var fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysCallsCount = 0
    var fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysCalled: Bool {
        return fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysCallsCount > 0
    }
    var fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysReceivedContext: (NotificationContext)?
    var fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysReceivedInvocations: [(NotificationContext)] = []
    var fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysReturnValue: BackendMLSPublicKeys!
    var fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysClosure: ((NotificationContext) async throws -> BackendMLSPublicKeys)?

    func fetchBackendPublicKeys(in context: NotificationContext) async throws -> BackendMLSPublicKeys {
        fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysCallsCount += 1
        fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysReceivedContext = context
        fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysReceivedInvocations.append(context)
        if let error = fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysThrowableError {
            throw error
        }
        if let fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysClosure = fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysClosure {
            return try await fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysClosure(context)
        } else {
            return fetchBackendPublicKeysInContextNotificationContextBackendMLSPublicKeysReturnValue
        }
    }

    //MARK: - countUnclaimedKeyPackages

    var countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntThrowableError: (any Error)?
    var countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntCallsCount = 0
    var countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntCalled: Bool {
        return countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntCallsCount > 0
    }
    var countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntReceivedArguments: (clientID: String, context: NotificationContext)?
    var countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntReceivedInvocations: [(clientID: String, context: NotificationContext)] = []
    var countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntReturnValue: Int!
    var countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntClosure: ((String, NotificationContext) async throws -> Int)?

    func countUnclaimedKeyPackages(clientID: String, context: NotificationContext) async throws -> Int {
        countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntCallsCount += 1
        countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntReceivedArguments = (clientID: clientID, context: context)
        countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntReceivedInvocations.append((clientID: clientID, context: context))
        if let error = countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntThrowableError {
            throw error
        }
        if let countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntClosure = countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntClosure {
            return try await countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntClosure(clientID, context)
        } else {
            return countUnclaimedKeyPackagesClientIDStringContextNotificationContextIntReturnValue
        }
    }

    //MARK: - uploadKeyPackages

    var uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidThrowableError: (any Error)?
    var uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidCallsCount = 0
    var uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidCalled: Bool {
        return uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidCallsCount > 0
    }
    var uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidReceivedArguments: (clientID: String, keyPackages: [String], context: NotificationContext)?
    var uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidReceivedInvocations: [(clientID: String, keyPackages: [String], context: NotificationContext)] = []
    var uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidClosure: ((String, [String], NotificationContext) async throws -> Void)?

    func uploadKeyPackages(clientID: String, keyPackages: [String], context: NotificationContext) async throws {
        uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidCallsCount += 1
        uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidReceivedArguments = (clientID: clientID, keyPackages: keyPackages, context: context)
        uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidReceivedInvocations.append((clientID: clientID, keyPackages: keyPackages, context: context))
        if let error = uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidThrowableError {
            throw error
        }
        try await uploadKeyPackagesClientIDStringKeyPackagesStringContextNotificationContextVoidClosure?(clientID, keyPackages, context)
    }

    //MARK: - claimKeyPackages

    var claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageThrowableError: (any Error)?
    var claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageCallsCount = 0
    var claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageCalled: Bool {
        return claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageCallsCount > 0
    }
    var claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageReceivedArguments: (userID: UUID, domain: String?, ciphersuite: MLSCipherSuite, excludedSelfClientID: String?, context: NotificationContext)?
    var claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageReceivedInvocations: [(userID: UUID, domain: String?, ciphersuite: MLSCipherSuite, excludedSelfClientID: String?, context: NotificationContext)] = []
    var claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageReturnValue: [KeyPackage]!
    var claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageClosure: ((UUID, String?, MLSCipherSuite, String?, NotificationContext) async throws -> [KeyPackage])?

    func claimKeyPackages(userID: UUID, domain: String?, ciphersuite: MLSCipherSuite, excludedSelfClientID: String?, in context: NotificationContext) async throws -> [KeyPackage] {
        claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageCallsCount += 1
        claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageReceivedArguments = (userID: userID, domain: domain, ciphersuite: ciphersuite, excludedSelfClientID: excludedSelfClientID, context: context)
        claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageReceivedInvocations.append((userID: userID, domain: domain, ciphersuite: ciphersuite, excludedSelfClientID: excludedSelfClientID, context: context))
        if let error = claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageThrowableError {
            throw error
        }
        if let claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageClosure = claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageClosure {
            return try await claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageClosure(userID, domain, ciphersuite, excludedSelfClientID, context)
        } else {
            return claimKeyPackagesUserIDUUIDDomainStringCiphersuiteMLSCipherSuiteExcludedSelfClientIDStringInContextNotificationContextKeyPackageReturnValue
        }
    }

    //MARK: - sendMessage

    var sendMessageMessageDataInContextNotificationContextZMUpdateEventThrowableError: (any Error)?
    var sendMessageMessageDataInContextNotificationContextZMUpdateEventCallsCount = 0
    var sendMessageMessageDataInContextNotificationContextZMUpdateEventCalled: Bool {
        return sendMessageMessageDataInContextNotificationContextZMUpdateEventCallsCount > 0
    }
    var sendMessageMessageDataInContextNotificationContextZMUpdateEventReceivedArguments: (message: Data, context: NotificationContext)?
    var sendMessageMessageDataInContextNotificationContextZMUpdateEventReceivedInvocations: [(message: Data, context: NotificationContext)] = []
    var sendMessageMessageDataInContextNotificationContextZMUpdateEventReturnValue: [ZMUpdateEvent]!
    var sendMessageMessageDataInContextNotificationContextZMUpdateEventClosure: ((Data, NotificationContext) async throws -> [ZMUpdateEvent])?

    func sendMessage(_ message: Data, in context: NotificationContext) async throws -> [ZMUpdateEvent] {
        sendMessageMessageDataInContextNotificationContextZMUpdateEventCallsCount += 1
        sendMessageMessageDataInContextNotificationContextZMUpdateEventReceivedArguments = (message: message, context: context)
        sendMessageMessageDataInContextNotificationContextZMUpdateEventReceivedInvocations.append((message: message, context: context))
        if let error = sendMessageMessageDataInContextNotificationContextZMUpdateEventThrowableError {
            throw error
        }
        if let sendMessageMessageDataInContextNotificationContextZMUpdateEventClosure = sendMessageMessageDataInContextNotificationContextZMUpdateEventClosure {
            return try await sendMessageMessageDataInContextNotificationContextZMUpdateEventClosure(message, context)
        } else {
            return sendMessageMessageDataInContextNotificationContextZMUpdateEventReturnValue
        }
    }

    //MARK: - sendCommitBundle

    var sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventThrowableError: (any Error)?
    var sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventCallsCount = 0
    var sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventCalled: Bool {
        return sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventCallsCount > 0
    }
    var sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventReceivedArguments: (bundle: Data, context: NotificationContext)?
    var sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventReceivedInvocations: [(bundle: Data, context: NotificationContext)] = []
    var sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventReturnValue: [ZMUpdateEvent]!
    var sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventClosure: ((Data, NotificationContext) async throws -> [ZMUpdateEvent])?

    func sendCommitBundle(_ bundle: Data, in context: NotificationContext) async throws -> [ZMUpdateEvent] {
        sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventCallsCount += 1
        sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventReceivedArguments = (bundle: bundle, context: context)
        sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventReceivedInvocations.append((bundle: bundle, context: context))
        if let error = sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventThrowableError {
            throw error
        }
        if let sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventClosure = sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventClosure {
            return try await sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventClosure(bundle, context)
        } else {
            return sendCommitBundleBundleDataInContextNotificationContextZMUpdateEventReturnValue
        }
    }

    //MARK: - fetchConversationGroupInfo

    var fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataThrowableError: (any Error)?
    var fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataCallsCount = 0
    var fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataCalled: Bool {
        return fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataCallsCount > 0
    }
    var fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataReceivedArguments: (conversationId: UUID, domain: String, subgroupType: SubgroupType?, context: NotificationContext)?
    var fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataReceivedInvocations: [(conversationId: UUID, domain: String, subgroupType: SubgroupType?, context: NotificationContext)] = []
    var fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataReturnValue: Data!
    var fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataClosure: ((UUID, String, SubgroupType?, NotificationContext) async throws -> Data)?

    func fetchConversationGroupInfo(conversationId: UUID, domain: String, subgroupType: SubgroupType?, context: NotificationContext) async throws -> Data {
        fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataCallsCount += 1
        fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataReceivedArguments = (conversationId: conversationId, domain: domain, subgroupType: subgroupType, context: context)
        fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataReceivedInvocations.append((conversationId: conversationId, domain: domain, subgroupType: subgroupType, context: context))
        if let error = fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataThrowableError {
            throw error
        }
        if let fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataClosure = fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataClosure {
            return try await fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataClosure(conversationId, domain, subgroupType, context)
        } else {
            return fetchConversationGroupInfoConversationIdUUIDDomainStringSubgroupTypeSubgroupTypeContextNotificationContextDataReturnValue
        }
    }

    //MARK: - fetchSubgroup

    var fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupThrowableError: (any Error)?
    var fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupCallsCount = 0
    var fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupCalled: Bool {
        return fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupCallsCount > 0
    }
    var fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupReceivedArguments: (conversationID: UUID, domain: String, type: SubgroupType, context: NotificationContext)?
    var fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupReceivedInvocations: [(conversationID: UUID, domain: String, type: SubgroupType, context: NotificationContext)] = []
    var fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupReturnValue: MLSSubgroup!
    var fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupClosure: ((UUID, String, SubgroupType, NotificationContext) async throws -> MLSSubgroup)?

    func fetchSubgroup(conversationID: UUID, domain: String, type: SubgroupType, context: NotificationContext) async throws -> MLSSubgroup {
        fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupCallsCount += 1
        fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupReceivedArguments = (conversationID: conversationID, domain: domain, type: type, context: context)
        fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupReceivedInvocations.append((conversationID: conversationID, domain: domain, type: type, context: context))
        if let error = fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupThrowableError {
            throw error
        }
        if let fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupClosure = fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupClosure {
            return try await fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupClosure(conversationID, domain, type, context)
        } else {
            return fetchSubgroupConversationIDUUIDDomainStringTypeSubgroupTypeContextNotificationContextMLSSubgroupReturnValue
        }
    }

    //MARK: - deleteSubgroup

    var deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidThrowableError: (any Error)?
    var deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidCallsCount = 0
    var deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidCalled: Bool {
        return deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidCallsCount > 0
    }
    var deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidReceivedArguments: (conversationID: UUID, domain: String, subgroupType: SubgroupType, epoch: Int, groupID: MLSGroupID, context: NotificationContext)?
    var deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidReceivedInvocations: [(conversationID: UUID, domain: String, subgroupType: SubgroupType, epoch: Int, groupID: MLSGroupID, context: NotificationContext)] = []
    var deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidClosure: ((UUID, String, SubgroupType, Int, MLSGroupID, NotificationContext) async throws -> Void)?

    func deleteSubgroup(conversationID: UUID, domain: String, subgroupType: SubgroupType, epoch: Int, groupID: MLSGroupID, context: NotificationContext) async throws {
        deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidCallsCount += 1
        deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidReceivedArguments = (conversationID: conversationID, domain: domain, subgroupType: subgroupType, epoch: epoch, groupID: groupID, context: context)
        deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidReceivedInvocations.append((conversationID: conversationID, domain: domain, subgroupType: subgroupType, epoch: epoch, groupID: groupID, context: context))
        if let error = deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidThrowableError {
            throw error
        }
        try await deleteSubgroupConversationIDUUIDDomainStringSubgroupTypeSubgroupTypeEpochIntGroupIDMLSGroupIDContextNotificationContextVoidClosure?(conversationID, domain, subgroupType, epoch, groupID, context)
    }

    //MARK: - leaveSubconversation

    var leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidThrowableError: (any Error)?
    var leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidCallsCount = 0
    var leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidCalled: Bool {
        return leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidCallsCount > 0
    }
    var leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidReceivedArguments: (conversationID: UUID, domain: String, subconversationType: SubgroupType, context: NotificationContext)?
    var leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidReceivedInvocations: [(conversationID: UUID, domain: String, subconversationType: SubgroupType, context: NotificationContext)] = []
    var leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidClosure: ((UUID, String, SubgroupType, NotificationContext) async throws -> Void)?

    func leaveSubconversation(conversationID: UUID, domain: String, subconversationType: SubgroupType, context: NotificationContext) async throws {
        leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidCallsCount += 1
        leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidReceivedArguments = (conversationID: conversationID, domain: domain, subconversationType: subconversationType, context: context)
        leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidReceivedInvocations.append((conversationID: conversationID, domain: domain, subconversationType: subconversationType, context: context))
        if let error = leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidThrowableError {
            throw error
        }
        try await leaveSubconversationConversationIDUUIDDomainStringSubconversationTypeSubgroupTypeContextNotificationContextVoidClosure?(conversationID, domain, subconversationType, context)
    }

    //MARK: - syncConversation

    var syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidThrowableError: (any Error)?
    var syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidCallsCount = 0
    var syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidCalled: Bool {
        return syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidCallsCount > 0
    }
    var syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidReceivedArguments: (qualifiedID: QualifiedID, context: NotificationContext)?
    var syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidReceivedInvocations: [(qualifiedID: QualifiedID, context: NotificationContext)] = []
    var syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidClosure: ((QualifiedID, NotificationContext) async throws -> Void)?

    func syncConversation(qualifiedID: QualifiedID, context: NotificationContext) async throws {
        syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidCallsCount += 1
        syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidReceivedArguments = (qualifiedID: qualifiedID, context: context)
        syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidReceivedInvocations.append((qualifiedID: qualifiedID, context: context))
        if let error = syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidThrowableError {
            throw error
        }
        try await syncConversationQualifiedIDQualifiedIDContextNotificationContextVoidClosure?(qualifiedID, context)
    }

    //MARK: - updateConversationProtocol

    var updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidThrowableError: (any Error)?
    var updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidCallsCount = 0
    var updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidCalled: Bool {
        return updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidCallsCount > 0
    }
    var updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidReceivedArguments: (qualifiedID: QualifiedID, messageProtocol: MessageProtocol, context: NotificationContext)?
    var updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidReceivedInvocations: [(qualifiedID: QualifiedID, messageProtocol: MessageProtocol, context: NotificationContext)] = []
    var updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidClosure: ((QualifiedID, MessageProtocol, NotificationContext) async throws -> Void)?

    func updateConversationProtocol(qualifiedID: QualifiedID, messageProtocol: MessageProtocol, context: NotificationContext) async throws {
        updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidCallsCount += 1
        updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidReceivedArguments = (qualifiedID: qualifiedID, messageProtocol: messageProtocol, context: context)
        updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidReceivedInvocations.append((qualifiedID: qualifiedID, messageProtocol: messageProtocol, context: context))
        if let error = updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidThrowableError {
            throw error
        }
        try await updateConversationProtocolQualifiedIDQualifiedIDMessageProtocolMessageProtocolContextNotificationContextVoidClosure?(qualifiedID, messageProtocol, context)
    }

    //MARK: - syncUsers

    var syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidThrowableError: (any Error)?
    var syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidCallsCount = 0
    var syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidCalled: Bool {
        return syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidCallsCount > 0
    }
    var syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidReceivedArguments: (qualifiedIDs: [QualifiedID], context: NotificationContext)?
    var syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidReceivedInvocations: [(qualifiedIDs: [QualifiedID], context: NotificationContext)] = []
    var syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidClosure: (([QualifiedID], NotificationContext) async throws -> Void)?

    func syncUsers(qualifiedIDs: [QualifiedID], context: NotificationContext) async throws {
        syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidCallsCount += 1
        syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidReceivedArguments = (qualifiedIDs: qualifiedIDs, context: context)
        syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidReceivedInvocations.append((qualifiedIDs: qualifiedIDs, context: context))
        if let error = syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidThrowableError {
            throw error
        }
        try await syncUsersQualifiedIDsQualifiedIDContextNotificationContextVoidClosure?(qualifiedIDs, context)
    }


}
public class MLSDecryptionServiceInterfaceMock: MLSDecryptionServiceInterface {

    public init() {}



    //MARK: - onEpochChanged

    public var onEpochChangedAnyPublisherMLSGroupIDNeverCallsCount = 0
    public var onEpochChangedAnyPublisherMLSGroupIDNeverCalled: Bool {
        return onEpochChangedAnyPublisherMLSGroupIDNeverCallsCount > 0
    }
    public var onEpochChangedAnyPublisherMLSGroupIDNeverReturnValue: AnyPublisher<MLSGroupID, Never>!
    public var onEpochChangedAnyPublisherMLSGroupIDNeverClosure: (() -> AnyPublisher<MLSGroupID, Never>)?

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        onEpochChangedAnyPublisherMLSGroupIDNeverCallsCount += 1
        if let onEpochChangedAnyPublisherMLSGroupIDNeverClosure = onEpochChangedAnyPublisherMLSGroupIDNeverClosure {
            return onEpochChangedAnyPublisherMLSGroupIDNeverClosure()
        } else {
            return onEpochChangedAnyPublisherMLSGroupIDNeverReturnValue
        }
    }

    //MARK: - onNewCRLsDistributionPoints

    public var onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverCallsCount = 0
    public var onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverCalled: Bool {
        return onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverCallsCount > 0
    }
    public var onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverReturnValue: AnyPublisher<CRLsDistributionPoints, Never>!
    public var onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverClosure: (() -> AnyPublisher<CRLsDistributionPoints, Never>)?

    public func onNewCRLsDistributionPoints() -> AnyPublisher<CRLsDistributionPoints, Never> {
        onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverCallsCount += 1
        if let onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverClosure = onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverClosure {
            return onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverClosure()
        } else {
            return onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverReturnValue
        }
    }

    //MARK: - decrypt

    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultThrowableError: (any Error)?
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultCallsCount = 0
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultCalled: Bool {
        return decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultCallsCount > 0
    }
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReceivedArguments: (message: String, groupID: MLSGroupID, subconversationType: SubgroupType?)?
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReceivedInvocations: [(message: String, groupID: MLSGroupID, subconversationType: SubgroupType?)] = []
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReturnValue: [MLSDecryptResult]!
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultClosure: ((String, MLSGroupID, SubgroupType?) async throws -> [MLSDecryptResult])?

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?) async throws -> [MLSDecryptResult] {
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultCallsCount += 1
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReceivedArguments = (message: message, groupID: groupID, subconversationType: subconversationType)
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReceivedInvocations.append((message: message, groupID: groupID, subconversationType: subconversationType))
        if let error = decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultThrowableError {
            throw error
        }
        if let decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultClosure = decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultClosure {
            return try await decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultClosure(message, groupID, subconversationType)
        } else {
            return decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReturnValue
        }
    }

    //MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDThrowableError: (any Error)?
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDCallsCount = 0
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDCalled: Bool {
        return processWelcomeMessageWelcomeMessageStringMLSGroupIDCallsCount > 0
    }
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDReceivedWelcomeMessage: (String)?
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDReceivedInvocations: [(String)] = []
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDReturnValue: MLSGroupID!
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDClosure: ((String) async throws -> MLSGroupID)?

    public func processWelcomeMessage(welcomeMessage: String) async throws -> MLSGroupID {
        processWelcomeMessageWelcomeMessageStringMLSGroupIDCallsCount += 1
        processWelcomeMessageWelcomeMessageStringMLSGroupIDReceivedWelcomeMessage = welcomeMessage
        processWelcomeMessageWelcomeMessageStringMLSGroupIDReceivedInvocations.append(welcomeMessage)
        if let error = processWelcomeMessageWelcomeMessageStringMLSGroupIDThrowableError {
            throw error
        }
        if let processWelcomeMessageWelcomeMessageStringMLSGroupIDClosure = processWelcomeMessageWelcomeMessageStringMLSGroupIDClosure {
            return try await processWelcomeMessageWelcomeMessageStringMLSGroupIDClosure(welcomeMessage)
        } else {
            return processWelcomeMessageWelcomeMessageStringMLSGroupIDReturnValue
        }
    }


}
public class MLSEncryptionServiceInterfaceMock: MLSEncryptionServiceInterface {

    public init() {}



    //MARK: - encrypt

    public var encryptMessageDataForGroupIDMLSGroupIDDataThrowableError: (any Error)?
    public var encryptMessageDataForGroupIDMLSGroupIDDataCallsCount = 0
    public var encryptMessageDataForGroupIDMLSGroupIDDataCalled: Bool {
        return encryptMessageDataForGroupIDMLSGroupIDDataCallsCount > 0
    }
    public var encryptMessageDataForGroupIDMLSGroupIDDataReceivedArguments: (message: Data, groupID: MLSGroupID)?
    public var encryptMessageDataForGroupIDMLSGroupIDDataReceivedInvocations: [(message: Data, groupID: MLSGroupID)] = []
    public var encryptMessageDataForGroupIDMLSGroupIDDataReturnValue: Data!
    public var encryptMessageDataForGroupIDMLSGroupIDDataClosure: ((Data, MLSGroupID) async throws -> Data)?

    public func encrypt(message: Data, for groupID: MLSGroupID) async throws -> Data {
        encryptMessageDataForGroupIDMLSGroupIDDataCallsCount += 1
        encryptMessageDataForGroupIDMLSGroupIDDataReceivedArguments = (message: message, groupID: groupID)
        encryptMessageDataForGroupIDMLSGroupIDDataReceivedInvocations.append((message: message, groupID: groupID))
        if let error = encryptMessageDataForGroupIDMLSGroupIDDataThrowableError {
            throw error
        }
        if let encryptMessageDataForGroupIDMLSGroupIDDataClosure = encryptMessageDataForGroupIDMLSGroupIDDataClosure {
            return try await encryptMessageDataForGroupIDMLSGroupIDDataClosure(message, groupID)
        } else {
            return encryptMessageDataForGroupIDMLSGroupIDDataReturnValue
        }
    }


}
public class MLSGroupVerificationProtocolMock: MLSGroupVerificationProtocol {

    public init() {}



    //MARK: - startObserving

    public var startObservingVoidCallsCount = 0
    public var startObservingVoidCalled: Bool {
        return startObservingVoidCallsCount > 0
    }
    public var startObservingVoidClosure: (() -> Void)?

    public func startObserving() {
        startObservingVoidCallsCount += 1
        startObservingVoidClosure?()
    }

    //MARK: - updateConversation

    public var updateConversationByGroupIDMLSGroupIDVoidCallsCount = 0
    public var updateConversationByGroupIDMLSGroupIDVoidCalled: Bool {
        return updateConversationByGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var updateConversationByGroupIDMLSGroupIDVoidReceivedGroupID: (MLSGroupID)?
    public var updateConversationByGroupIDMLSGroupIDVoidReceivedInvocations: [(MLSGroupID)] = []
    public var updateConversationByGroupIDMLSGroupIDVoidClosure: ((MLSGroupID) async -> Void)?

    public func updateConversation(by groupID: MLSGroupID) async {
        updateConversationByGroupIDMLSGroupIDVoidCallsCount += 1
        updateConversationByGroupIDMLSGroupIDVoidReceivedGroupID = groupID
        updateConversationByGroupIDMLSGroupIDVoidReceivedInvocations.append(groupID)
        await updateConversationByGroupIDMLSGroupIDVoidClosure?(groupID)
    }

    //MARK: - updateConversation

    public var updateConversationConversationZMConversationWithGroupIDMLSGroupIDVoidCallsCount = 0
    public var updateConversationConversationZMConversationWithGroupIDMLSGroupIDVoidCalled: Bool {
        return updateConversationConversationZMConversationWithGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var updateConversationConversationZMConversationWithGroupIDMLSGroupIDVoidReceivedArguments: (conversation: ZMConversation, groupID: MLSGroupID)?
    public var updateConversationConversationZMConversationWithGroupIDMLSGroupIDVoidReceivedInvocations: [(conversation: ZMConversation, groupID: MLSGroupID)] = []
    public var updateConversationConversationZMConversationWithGroupIDMLSGroupIDVoidClosure: ((ZMConversation, MLSGroupID) async -> Void)?

    public func updateConversation(_ conversation: ZMConversation, with groupID: MLSGroupID) async {
        updateConversationConversationZMConversationWithGroupIDMLSGroupIDVoidCallsCount += 1
        updateConversationConversationZMConversationWithGroupIDMLSGroupIDVoidReceivedArguments = (conversation: conversation, groupID: groupID)
        updateConversationConversationZMConversationWithGroupIDMLSGroupIDVoidReceivedInvocations.append((conversation: conversation, groupID: groupID))
        await updateConversationConversationZMConversationWithGroupIDMLSGroupIDVoidClosure?(conversation, groupID)
    }

    //MARK: - updateAllConversations

    public var updateAllConversationsVoidCallsCount = 0
    public var updateAllConversationsVoidCalled: Bool {
        return updateAllConversationsVoidCallsCount > 0
    }
    public var updateAllConversationsVoidClosure: (() async -> Void)?

    public func updateAllConversations() async {
        updateAllConversationsVoidCallsCount += 1
        await updateAllConversationsVoidClosure?()
    }


}
public class MLSServiceInterfaceMock: MLSServiceInterface {

    public init() {}



    //MARK: - createGroup

    public var createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteThrowableError: (any Error)?
    public var createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteCallsCount = 0
    public var createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteCalled: Bool {
        return createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteCallsCount > 0
    }
    public var createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteReceivedArguments: (groupID: MLSGroupID, parentGroupID: MLSGroupID)?
    public var createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteReceivedInvocations: [(groupID: MLSGroupID, parentGroupID: MLSGroupID)] = []
    public var createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteReturnValue: MLSCipherSuite!
    public var createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteClosure: ((MLSGroupID, MLSGroupID) async throws -> MLSCipherSuite)?

    public func createGroup(for groupID: MLSGroupID, parentGroupID: MLSGroupID) async throws -> MLSCipherSuite {
        createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteCallsCount += 1
        createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteReceivedArguments = (groupID: groupID, parentGroupID: parentGroupID)
        createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteReceivedInvocations.append((groupID: groupID, parentGroupID: parentGroupID))
        if let error = createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteThrowableError {
            throw error
        }
        if let createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteClosure = createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteClosure {
            return try await createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteClosure(groupID, parentGroupID)
        } else {
            return createGroupForGroupIDMLSGroupIDParentGroupIDMLSGroupIDMLSCipherSuiteReturnValue
        }
    }

    //MARK: - createGroup

    public var createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteThrowableError: (any Error)?
    public var createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteCallsCount = 0
    public var createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteCalled: Bool {
        return createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteCallsCount > 0
    }
    public var createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReceivedArguments: (groupID: MLSGroupID, removalKeys: BackendMLSPublicKeys?)?
    public var createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReceivedInvocations: [(groupID: MLSGroupID, removalKeys: BackendMLSPublicKeys?)] = []
    public var createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReturnValue: MLSCipherSuite!
    public var createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteClosure: ((MLSGroupID, BackendMLSPublicKeys?) async throws -> MLSCipherSuite)?

    public func createGroup(for groupID: MLSGroupID, removalKeys: BackendMLSPublicKeys?) async throws -> MLSCipherSuite {
        createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteCallsCount += 1
        createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReceivedArguments = (groupID: groupID, removalKeys: removalKeys)
        createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReceivedInvocations.append((groupID: groupID, removalKeys: removalKeys))
        if let error = createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteThrowableError {
            throw error
        }
        if let createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteClosure = createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteClosure {
            return try await createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteClosure(groupID, removalKeys)
        } else {
            return createGroupForGroupIDMLSGroupIDRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReturnValue
        }
    }

    //MARK: - createSelfGroup

    public var createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteThrowableError: (any Error)?
    public var createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteCallsCount = 0
    public var createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteCalled: Bool {
        return createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteCallsCount > 0
    }
    public var createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteReceivedGroupID: (MLSGroupID)?
    public var createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteReceivedInvocations: [(MLSGroupID)] = []
    public var createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteReturnValue: MLSCipherSuite!
    public var createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteClosure: ((MLSGroupID) async throws -> MLSCipherSuite)?

    public func createSelfGroup(for groupID: MLSGroupID) async throws -> MLSCipherSuite {
        createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteCallsCount += 1
        createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteReceivedGroupID = groupID
        createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteReceivedInvocations.append(groupID)
        if let error = createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteThrowableError {
            throw error
        }
        if let createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteClosure = createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteClosure {
            return try await createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteClosure(groupID)
        } else {
            return createSelfGroupForGroupIDMLSGroupIDMLSCipherSuiteReturnValue
        }
    }

    //MARK: - establishGroup

    public var establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteThrowableError: (any Error)?
    public var establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteCallsCount = 0
    public var establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteCalled: Bool {
        return establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteCallsCount > 0
    }
    public var establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReceivedArguments: (groupID: MLSGroupID, users: [MLSUser], removalKeys: BackendMLSPublicKeys?)?
    public var establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReceivedInvocations: [(groupID: MLSGroupID, users: [MLSUser], removalKeys: BackendMLSPublicKeys?)] = []
    public var establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReturnValue: MLSCipherSuite!
    public var establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteClosure: ((MLSGroupID, [MLSUser], BackendMLSPublicKeys?) async throws -> MLSCipherSuite)?

    public func establishGroup(for groupID: MLSGroupID, with users: [MLSUser], removalKeys: BackendMLSPublicKeys?) async throws -> MLSCipherSuite {
        establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteCallsCount += 1
        establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReceivedArguments = (groupID: groupID, users: users, removalKeys: removalKeys)
        establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReceivedInvocations.append((groupID: groupID, users: users, removalKeys: removalKeys))
        if let error = establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteThrowableError {
            throw error
        }
        if let establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteClosure = establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteClosure {
            return try await establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteClosure(groupID, users, removalKeys)
        } else {
            return establishGroupForGroupIDMLSGroupIDWithUsersMLSUserRemovalKeysBackendMLSPublicKeysMLSCipherSuiteReturnValue
        }
    }

    //MARK: - joinGroup

    public var joinGroupWithGroupIDMLSGroupIDVoidThrowableError: (any Error)?
    public var joinGroupWithGroupIDMLSGroupIDVoidCallsCount = 0
    public var joinGroupWithGroupIDMLSGroupIDVoidCalled: Bool {
        return joinGroupWithGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var joinGroupWithGroupIDMLSGroupIDVoidReceivedGroupID: (MLSGroupID)?
    public var joinGroupWithGroupIDMLSGroupIDVoidReceivedInvocations: [(MLSGroupID)] = []
    public var joinGroupWithGroupIDMLSGroupIDVoidClosure: ((MLSGroupID) async throws -> Void)?

    public func joinGroup(with groupID: MLSGroupID) async throws {
        joinGroupWithGroupIDMLSGroupIDVoidCallsCount += 1
        joinGroupWithGroupIDMLSGroupIDVoidReceivedGroupID = groupID
        joinGroupWithGroupIDMLSGroupIDVoidReceivedInvocations.append(groupID)
        if let error = joinGroupWithGroupIDMLSGroupIDVoidThrowableError {
            throw error
        }
        try await joinGroupWithGroupIDMLSGroupIDVoidClosure?(groupID)
    }

    //MARK: - joinNewGroup

    public var joinNewGroupWithGroupIDMLSGroupIDVoidThrowableError: (any Error)?
    public var joinNewGroupWithGroupIDMLSGroupIDVoidCallsCount = 0
    public var joinNewGroupWithGroupIDMLSGroupIDVoidCalled: Bool {
        return joinNewGroupWithGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var joinNewGroupWithGroupIDMLSGroupIDVoidReceivedGroupID: (MLSGroupID)?
    public var joinNewGroupWithGroupIDMLSGroupIDVoidReceivedInvocations: [(MLSGroupID)] = []
    public var joinNewGroupWithGroupIDMLSGroupIDVoidClosure: ((MLSGroupID) async throws -> Void)?

    public func joinNewGroup(with groupID: MLSGroupID) async throws {
        joinNewGroupWithGroupIDMLSGroupIDVoidCallsCount += 1
        joinNewGroupWithGroupIDMLSGroupIDVoidReceivedGroupID = groupID
        joinNewGroupWithGroupIDMLSGroupIDVoidReceivedInvocations.append(groupID)
        if let error = joinNewGroupWithGroupIDMLSGroupIDVoidThrowableError {
            throw error
        }
        try await joinNewGroupWithGroupIDMLSGroupIDVoidClosure?(groupID)
    }

    //MARK: - performPendingJoins

    public var performPendingJoinsVoidThrowableError: (any Error)?
    public var performPendingJoinsVoidCallsCount = 0
    public var performPendingJoinsVoidCalled: Bool {
        return performPendingJoinsVoidCallsCount > 0
    }
    public var performPendingJoinsVoidClosure: (() async throws -> Void)?

    public func performPendingJoins() async throws {
        performPendingJoinsVoidCallsCount += 1
        if let error = performPendingJoinsVoidThrowableError {
            throw error
        }
        try await performPendingJoinsVoidClosure?()
    }

    //MARK: - wipeGroup

    public var wipeGroupGroupIDMLSGroupIDVoidThrowableError: (any Error)?
    public var wipeGroupGroupIDMLSGroupIDVoidCallsCount = 0
    public var wipeGroupGroupIDMLSGroupIDVoidCalled: Bool {
        return wipeGroupGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var wipeGroupGroupIDMLSGroupIDVoidReceivedGroupID: (MLSGroupID)?
    public var wipeGroupGroupIDMLSGroupIDVoidReceivedInvocations: [(MLSGroupID)] = []
    public var wipeGroupGroupIDMLSGroupIDVoidClosure: ((MLSGroupID) async throws -> Void)?

    public func wipeGroup(_ groupID: MLSGroupID) async throws {
        wipeGroupGroupIDMLSGroupIDVoidCallsCount += 1
        wipeGroupGroupIDMLSGroupIDVoidReceivedGroupID = groupID
        wipeGroupGroupIDMLSGroupIDVoidReceivedInvocations.append(groupID)
        if let error = wipeGroupGroupIDMLSGroupIDVoidThrowableError {
            throw error
        }
        try await wipeGroupGroupIDMLSGroupIDVoidClosure?(groupID)
    }

    //MARK: - conversationExists

    public var conversationExistsGroupIDMLSGroupIDBoolThrowableError: (any Error)?
    public var conversationExistsGroupIDMLSGroupIDBoolCallsCount = 0
    public var conversationExistsGroupIDMLSGroupIDBoolCalled: Bool {
        return conversationExistsGroupIDMLSGroupIDBoolCallsCount > 0
    }
    public var conversationExistsGroupIDMLSGroupIDBoolReceivedGroupID: (MLSGroupID)?
    public var conversationExistsGroupIDMLSGroupIDBoolReceivedInvocations: [(MLSGroupID)] = []
    public var conversationExistsGroupIDMLSGroupIDBoolReturnValue: Bool!
    public var conversationExistsGroupIDMLSGroupIDBoolClosure: ((MLSGroupID) async throws -> Bool)?

    public func conversationExists(groupID: MLSGroupID) async throws -> Bool {
        conversationExistsGroupIDMLSGroupIDBoolCallsCount += 1
        conversationExistsGroupIDMLSGroupIDBoolReceivedGroupID = groupID
        conversationExistsGroupIDMLSGroupIDBoolReceivedInvocations.append(groupID)
        if let error = conversationExistsGroupIDMLSGroupIDBoolThrowableError {
            throw error
        }
        if let conversationExistsGroupIDMLSGroupIDBoolClosure = conversationExistsGroupIDMLSGroupIDBoolClosure {
            return try await conversationExistsGroupIDMLSGroupIDBoolClosure(groupID)
        } else {
            return conversationExistsGroupIDMLSGroupIDBoolReturnValue
        }
    }

    //MARK: - addMembersToConversation

    public var addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidThrowableError: (any Error)?
    public var addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidCallsCount = 0
    public var addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidCalled: Bool {
        return addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidReceivedArguments: (users: [MLSUser], groupID: MLSGroupID)?
    public var addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidReceivedInvocations: [(users: [MLSUser], groupID: MLSGroupID)] = []
    public var addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidClosure: (([MLSUser], MLSGroupID) async throws -> Void)?

    public func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) async throws {
        addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidCallsCount += 1
        addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidReceivedArguments = (users: users, groupID: groupID)
        addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidReceivedInvocations.append((users: users, groupID: groupID))
        if let error = addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidThrowableError {
            throw error
        }
        try await addMembersToConversationWithUsersMLSUserForGroupIDMLSGroupIDVoidClosure?(users, groupID)
    }

    //MARK: - removeMembersFromConversation

    public var removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidThrowableError: (any Error)?
    public var removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidCallsCount = 0
    public var removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidCalled: Bool {
        return removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidReceivedArguments: (clientIds: [MLSClientID], groupID: MLSGroupID)?
    public var removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidReceivedInvocations: [(clientIds: [MLSClientID], groupID: MLSGroupID)] = []
    public var removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidClosure: (([MLSClientID], MLSGroupID) async throws -> Void)?

    public func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) async throws {
        removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidCallsCount += 1
        removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidReceivedArguments = (clientIds: clientIds, groupID: groupID)
        removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidReceivedInvocations.append((clientIds: clientIds, groupID: groupID))
        if let error = removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidThrowableError {
            throw error
        }
        try await removeMembersFromConversationWithClientIdsMLSClientIDForGroupIDMLSGroupIDVoidClosure?(clientIds, groupID)
    }

    //MARK: - createOrJoinSubgroup

    public var createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDThrowableError: (any Error)?
    public var createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDCallsCount = 0
    public var createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDCalled: Bool {
        return createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDCallsCount > 0
    }
    public var createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDReceivedArguments: (parentQualifiedID: QualifiedID, parentID: MLSGroupID)?
    public var createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDReceivedInvocations: [(parentQualifiedID: QualifiedID, parentID: MLSGroupID)] = []
    public var createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDReturnValue: MLSGroupID!
    public var createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDClosure: ((QualifiedID, MLSGroupID) async throws -> MLSGroupID)?

    public func createOrJoinSubgroup(parentQualifiedID: QualifiedID, parentID: MLSGroupID) async throws -> MLSGroupID {
        createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDCallsCount += 1
        createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDReceivedArguments = (parentQualifiedID: parentQualifiedID, parentID: parentID)
        createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDReceivedInvocations.append((parentQualifiedID: parentQualifiedID, parentID: parentID))
        if let error = createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDThrowableError {
            throw error
        }
        if let createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDClosure = createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDClosure {
            return try await createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDClosure(parentQualifiedID, parentID)
        } else {
            return createOrJoinSubgroupParentQualifiedIDQualifiedIDParentIDMLSGroupIDMLSGroupIDReturnValue
        }
    }

    //MARK: - leaveSubconversation

    public var leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidThrowableError: (any Error)?
    public var leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidCallsCount = 0
    public var leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidCalled: Bool {
        return leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidCallsCount > 0
    }
    public var leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidReceivedArguments: (parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType)?
    public var leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidReceivedInvocations: [(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType)] = []
    public var leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidClosure: ((QualifiedID, MLSGroupID, SubgroupType) async throws -> Void)?

    public func leaveSubconversation(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType) async throws {
        leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidCallsCount += 1
        leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidReceivedArguments = (parentQualifiedID: parentQualifiedID, parentGroupID: parentGroupID, subconversationType: subconversationType)
        leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidReceivedInvocations.append((parentQualifiedID: parentQualifiedID, parentGroupID: parentGroupID, subconversationType: subconversationType))
        if let error = leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidThrowableError {
            throw error
        }
        try await leaveSubconversationParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeVoidClosure?(parentQualifiedID, parentGroupID, subconversationType)
    }

    //MARK: - leaveSubconversationIfNeeded

    public var leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidThrowableError: (any Error)?
    public var leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidCallsCount = 0
    public var leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidCalled: Bool {
        return leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidCallsCount > 0
    }
    public var leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidReceivedArguments: (parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType, selfClientID: MLSClientID)?
    public var leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidReceivedInvocations: [(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType, selfClientID: MLSClientID)] = []
    public var leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidClosure: ((QualifiedID, MLSGroupID, SubgroupType, MLSClientID) async throws -> Void)?

    public func leaveSubconversationIfNeeded(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType, selfClientID: MLSClientID) async throws {
        leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidCallsCount += 1
        leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidReceivedArguments = (parentQualifiedID: parentQualifiedID, parentGroupID: parentGroupID, subconversationType: subconversationType, selfClientID: selfClientID)
        leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidReceivedInvocations.append((parentQualifiedID: parentQualifiedID, parentGroupID: parentGroupID, subconversationType: subconversationType, selfClientID: selfClientID))
        if let error = leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidThrowableError {
            throw error
        }
        try await leaveSubconversationIfNeededParentQualifiedIDQualifiedIDParentGroupIDMLSGroupIDSubconversationTypeSubgroupTypeSelfClientIDMLSClientIDVoidClosure?(parentQualifiedID, parentGroupID, subconversationType, selfClientID)
    }

    //MARK: - deleteSubgroup

    public var deleteSubgroupParentQualifiedIDQualifiedIDVoidThrowableError: (any Error)?
    public var deleteSubgroupParentQualifiedIDQualifiedIDVoidCallsCount = 0
    public var deleteSubgroupParentQualifiedIDQualifiedIDVoidCalled: Bool {
        return deleteSubgroupParentQualifiedIDQualifiedIDVoidCallsCount > 0
    }
    public var deleteSubgroupParentQualifiedIDQualifiedIDVoidReceivedParentQualifiedID: (QualifiedID)?
    public var deleteSubgroupParentQualifiedIDQualifiedIDVoidReceivedInvocations: [(QualifiedID)] = []
    public var deleteSubgroupParentQualifiedIDQualifiedIDVoidClosure: ((QualifiedID) async throws -> Void)?

    public func deleteSubgroup(parentQualifiedID: QualifiedID) async throws {
        deleteSubgroupParentQualifiedIDQualifiedIDVoidCallsCount += 1
        deleteSubgroupParentQualifiedIDQualifiedIDVoidReceivedParentQualifiedID = parentQualifiedID
        deleteSubgroupParentQualifiedIDQualifiedIDVoidReceivedInvocations.append(parentQualifiedID)
        if let error = deleteSubgroupParentQualifiedIDQualifiedIDVoidThrowableError {
            throw error
        }
        try await deleteSubgroupParentQualifiedIDQualifiedIDVoidClosure?(parentQualifiedID)
    }

    //MARK: - subconversationMembers

    public var subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDThrowableError: (any Error)?
    public var subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDCallsCount = 0
    public var subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDCalled: Bool {
        return subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDCallsCount > 0
    }
    public var subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDReceivedSubconversationGroupID: (MLSGroupID)?
    public var subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDReceivedInvocations: [(MLSGroupID)] = []
    public var subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDReturnValue: [MLSClientID]!
    public var subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDClosure: ((MLSGroupID) async throws -> [MLSClientID])?

    public func subconversationMembers(for subconversationGroupID: MLSGroupID) async throws -> [MLSClientID] {
        subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDCallsCount += 1
        subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDReceivedSubconversationGroupID = subconversationGroupID
        subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDReceivedInvocations.append(subconversationGroupID)
        if let error = subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDThrowableError {
            throw error
        }
        if let subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDClosure = subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDClosure {
            return try await subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDClosure(subconversationGroupID)
        } else {
            return subconversationMembersForSubconversationGroupIDMLSGroupIDMLSClientIDReturnValue
        }
    }

    //MARK: - commitPendingProposalsIfNeeded

    public var commitPendingProposalsIfNeededVoidCallsCount = 0
    public var commitPendingProposalsIfNeededVoidCalled: Bool {
        return commitPendingProposalsIfNeededVoidCallsCount > 0
    }
    public var commitPendingProposalsIfNeededVoidClosure: (() -> Void)?

    public func commitPendingProposalsIfNeeded() {
        commitPendingProposalsIfNeededVoidCallsCount += 1
        commitPendingProposalsIfNeededVoidClosure?()
    }

    //MARK: - commitPendingProposals

    public var commitPendingProposalsInGroupIDMLSGroupIDVoidThrowableError: (any Error)?
    public var commitPendingProposalsInGroupIDMLSGroupIDVoidCallsCount = 0
    public var commitPendingProposalsInGroupIDMLSGroupIDVoidCalled: Bool {
        return commitPendingProposalsInGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var commitPendingProposalsInGroupIDMLSGroupIDVoidReceivedGroupID: (MLSGroupID)?
    public var commitPendingProposalsInGroupIDMLSGroupIDVoidReceivedInvocations: [(MLSGroupID)] = []
    public var commitPendingProposalsInGroupIDMLSGroupIDVoidClosure: ((MLSGroupID) async throws -> Void)?

    public func commitPendingProposals(in groupID: MLSGroupID) async throws {
        commitPendingProposalsInGroupIDMLSGroupIDVoidCallsCount += 1
        commitPendingProposalsInGroupIDMLSGroupIDVoidReceivedGroupID = groupID
        commitPendingProposalsInGroupIDMLSGroupIDVoidReceivedInvocations.append(groupID)
        if let error = commitPendingProposalsInGroupIDMLSGroupIDVoidThrowableError {
            throw error
        }
        try await commitPendingProposalsInGroupIDMLSGroupIDVoidClosure?(groupID)
    }

    //MARK: - updateKeyMaterialForAllStaleGroupsIfNeeded

    public var updateKeyMaterialForAllStaleGroupsIfNeededVoidCallsCount = 0
    public var updateKeyMaterialForAllStaleGroupsIfNeededVoidCalled: Bool {
        return updateKeyMaterialForAllStaleGroupsIfNeededVoidCallsCount > 0
    }
    public var updateKeyMaterialForAllStaleGroupsIfNeededVoidClosure: (() async -> Void)?

    public func updateKeyMaterialForAllStaleGroupsIfNeeded() async {
        updateKeyMaterialForAllStaleGroupsIfNeededVoidCallsCount += 1
        await updateKeyMaterialForAllStaleGroupsIfNeededVoidClosure?()
    }

    //MARK: - uploadKeyPackagesIfNeeded

    public var uploadKeyPackagesIfNeededVoidCallsCount = 0
    public var uploadKeyPackagesIfNeededVoidCalled: Bool {
        return uploadKeyPackagesIfNeededVoidCallsCount > 0
    }
    public var uploadKeyPackagesIfNeededVoidClosure: (() async -> Void)?

    public func uploadKeyPackagesIfNeeded() async {
        uploadKeyPackagesIfNeededVoidCallsCount += 1
        await uploadKeyPackagesIfNeededVoidClosure?()
    }

    //MARK: - repairOutOfSyncConversations

    public var repairOutOfSyncConversationsVoidThrowableError: (any Error)?
    public var repairOutOfSyncConversationsVoidCallsCount = 0
    public var repairOutOfSyncConversationsVoidCalled: Bool {
        return repairOutOfSyncConversationsVoidCallsCount > 0
    }
    public var repairOutOfSyncConversationsVoidClosure: (() async throws -> Void)?

    public func repairOutOfSyncConversations() async throws {
        repairOutOfSyncConversationsVoidCallsCount += 1
        if let error = repairOutOfSyncConversationsVoidThrowableError {
            throw error
        }
        try await repairOutOfSyncConversationsVoidClosure?()
    }

    //MARK: - fetchAndRepairGroup

    public var fetchAndRepairGroupWithGroupIDMLSGroupIDVoidCallsCount = 0
    public var fetchAndRepairGroupWithGroupIDMLSGroupIDVoidCalled: Bool {
        return fetchAndRepairGroupWithGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var fetchAndRepairGroupWithGroupIDMLSGroupIDVoidReceivedGroupID: (MLSGroupID)?
    public var fetchAndRepairGroupWithGroupIDMLSGroupIDVoidReceivedInvocations: [(MLSGroupID)] = []
    public var fetchAndRepairGroupWithGroupIDMLSGroupIDVoidClosure: ((MLSGroupID) async -> Void)?

    public func fetchAndRepairGroup(with groupID: MLSGroupID) async {
        fetchAndRepairGroupWithGroupIDMLSGroupIDVoidCallsCount += 1
        fetchAndRepairGroupWithGroupIDMLSGroupIDVoidReceivedGroupID = groupID
        fetchAndRepairGroupWithGroupIDMLSGroupIDVoidReceivedInvocations.append(groupID)
        await fetchAndRepairGroupWithGroupIDMLSGroupIDVoidClosure?(groupID)
    }

    //MARK: - generateNewEpoch

    public var generateNewEpochGroupIDMLSGroupIDVoidThrowableError: (any Error)?
    public var generateNewEpochGroupIDMLSGroupIDVoidCallsCount = 0
    public var generateNewEpochGroupIDMLSGroupIDVoidCalled: Bool {
        return generateNewEpochGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var generateNewEpochGroupIDMLSGroupIDVoidReceivedGroupID: (MLSGroupID)?
    public var generateNewEpochGroupIDMLSGroupIDVoidReceivedInvocations: [(MLSGroupID)] = []
    public var generateNewEpochGroupIDMLSGroupIDVoidClosure: ((MLSGroupID) async throws -> Void)?

    public func generateNewEpoch(groupID: MLSGroupID) async throws {
        generateNewEpochGroupIDMLSGroupIDVoidCallsCount += 1
        generateNewEpochGroupIDMLSGroupIDVoidReceivedGroupID = groupID
        generateNewEpochGroupIDMLSGroupIDVoidReceivedInvocations.append(groupID)
        if let error = generateNewEpochGroupIDMLSGroupIDVoidThrowableError {
            throw error
        }
        try await generateNewEpochGroupIDMLSGroupIDVoidClosure?(groupID)
    }

    //MARK: - epochChanges

    public var epochChangesAsyncStreamMLSGroupIDCallsCount = 0
    public var epochChangesAsyncStreamMLSGroupIDCalled: Bool {
        return epochChangesAsyncStreamMLSGroupIDCallsCount > 0
    }
    public var epochChangesAsyncStreamMLSGroupIDReturnValue: AsyncStream<MLSGroupID>!
    public var epochChangesAsyncStreamMLSGroupIDClosure: (() -> AsyncStream<MLSGroupID>)?

    public func epochChanges() -> AsyncStream<MLSGroupID> {
        epochChangesAsyncStreamMLSGroupIDCallsCount += 1
        if let epochChangesAsyncStreamMLSGroupIDClosure = epochChangesAsyncStreamMLSGroupIDClosure {
            return epochChangesAsyncStreamMLSGroupIDClosure()
        } else {
            return epochChangesAsyncStreamMLSGroupIDReturnValue
        }
    }

    //MARK: - generateConferenceInfo

    public var generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoThrowableError: (any Error)?
    public var generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoCallsCount = 0
    public var generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoCalled: Bool {
        return generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoCallsCount > 0
    }
    public var generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoReceivedArguments: (parentGroupID: MLSGroupID, subconversationGroupID: MLSGroupID)?
    public var generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoReceivedInvocations: [(parentGroupID: MLSGroupID, subconversationGroupID: MLSGroupID)] = []
    public var generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoReturnValue: MLSConferenceInfo!
    public var generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoClosure: ((MLSGroupID, MLSGroupID) async throws -> MLSConferenceInfo)?

    public func generateConferenceInfo(parentGroupID: MLSGroupID, subconversationGroupID: MLSGroupID) async throws -> MLSConferenceInfo {
        generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoCallsCount += 1
        generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoReceivedArguments = (parentGroupID: parentGroupID, subconversationGroupID: subconversationGroupID)
        generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoReceivedInvocations.append((parentGroupID: parentGroupID, subconversationGroupID: subconversationGroupID))
        if let error = generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoThrowableError {
            throw error
        }
        if let generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoClosure = generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoClosure {
            return try await generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoClosure(parentGroupID, subconversationGroupID)
        } else {
            return generateConferenceInfoParentGroupIDMLSGroupIDSubconversationGroupIDMLSGroupIDMLSConferenceInfoReturnValue
        }
    }

    //MARK: - onConferenceInfoChange

    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorCallsCount = 0
    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorCalled: Bool {
        return onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorCallsCount > 0
    }
    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorReceivedArguments: (parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID)?
    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorReceivedInvocations: [(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID)] = []
    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorReturnValue: AsyncThrowingStream<MLSConferenceInfo, Error>!
    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorClosure: ((MLSGroupID, MLSGroupID) -> AsyncThrowingStream<MLSConferenceInfo, Error>)?

    public func onConferenceInfoChange(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID) -> AsyncThrowingStream<MLSConferenceInfo, Error> {
        onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorCallsCount += 1
        onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorReceivedArguments = (parentGroupID: parentGroupID, subConversationGroupID: subConversationGroupID)
        onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorReceivedInvocations.append((parentGroupID: parentGroupID, subConversationGroupID: subConversationGroupID))
        if let onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorClosure = onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorClosure {
            return onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorClosure(parentGroupID, subConversationGroupID)
        } else {
            return onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoErrorReturnValue
        }
    }

    //MARK: - startProteusToMLSMigration

    public var startProteusToMLSMigrationVoidThrowableError: (any Error)?
    public var startProteusToMLSMigrationVoidCallsCount = 0
    public var startProteusToMLSMigrationVoidCalled: Bool {
        return startProteusToMLSMigrationVoidCallsCount > 0
    }
    public var startProteusToMLSMigrationVoidClosure: (() async throws -> Void)?

    public func startProteusToMLSMigration() async throws {
        startProteusToMLSMigrationVoidCallsCount += 1
        if let error = startProteusToMLSMigrationVoidThrowableError {
            throw error
        }
        try await startProteusToMLSMigrationVoidClosure?()
    }

    //MARK: - onEpochChanged

    public var onEpochChangedAnyPublisherMLSGroupIDNeverCallsCount = 0
    public var onEpochChangedAnyPublisherMLSGroupIDNeverCalled: Bool {
        return onEpochChangedAnyPublisherMLSGroupIDNeverCallsCount > 0
    }
    public var onEpochChangedAnyPublisherMLSGroupIDNeverReturnValue: AnyPublisher<MLSGroupID, Never>!
    public var onEpochChangedAnyPublisherMLSGroupIDNeverClosure: (() -> AnyPublisher<MLSGroupID, Never>)?

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        onEpochChangedAnyPublisherMLSGroupIDNeverCallsCount += 1
        if let onEpochChangedAnyPublisherMLSGroupIDNeverClosure = onEpochChangedAnyPublisherMLSGroupIDNeverClosure {
            return onEpochChangedAnyPublisherMLSGroupIDNeverClosure()
        } else {
            return onEpochChangedAnyPublisherMLSGroupIDNeverReturnValue
        }
    }

    //MARK: - onNewCRLsDistributionPoints

    public var onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverCallsCount = 0
    public var onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverCalled: Bool {
        return onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverCallsCount > 0
    }
    public var onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverReturnValue: AnyPublisher<CRLsDistributionPoints, Never>!
    public var onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverClosure: (() -> AnyPublisher<CRLsDistributionPoints, Never>)?

    public func onNewCRLsDistributionPoints() -> AnyPublisher<CRLsDistributionPoints, Never> {
        onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverCallsCount += 1
        if let onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverClosure = onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverClosure {
            return onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverClosure()
        } else {
            return onNewCRLsDistributionPointsAnyPublisherCRLsDistributionPointsNeverReturnValue
        }
    }

    //MARK: - decrypt

    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultThrowableError: (any Error)?
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultCallsCount = 0
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultCalled: Bool {
        return decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultCallsCount > 0
    }
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReceivedArguments: (message: String, groupID: MLSGroupID, subconversationType: SubgroupType?)?
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReceivedInvocations: [(message: String, groupID: MLSGroupID, subconversationType: SubgroupType?)] = []
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReturnValue: [MLSDecryptResult]!
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultClosure: ((String, MLSGroupID, SubgroupType?) async throws -> [MLSDecryptResult])?

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?) async throws -> [MLSDecryptResult] {
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultCallsCount += 1
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReceivedArguments = (message: message, groupID: groupID, subconversationType: subconversationType)
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReceivedInvocations.append((message: message, groupID: groupID, subconversationType: subconversationType))
        if let error = decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultThrowableError {
            throw error
        }
        if let decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultClosure = decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultClosure {
            return try await decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultClosure(message, groupID, subconversationType)
        } else {
            return decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeMLSDecryptResultReturnValue
        }
    }

    //MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDThrowableError: (any Error)?
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDCallsCount = 0
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDCalled: Bool {
        return processWelcomeMessageWelcomeMessageStringMLSGroupIDCallsCount > 0
    }
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDReceivedWelcomeMessage: (String)?
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDReceivedInvocations: [(String)] = []
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDReturnValue: MLSGroupID!
    public var processWelcomeMessageWelcomeMessageStringMLSGroupIDClosure: ((String) async throws -> MLSGroupID)?

    public func processWelcomeMessage(welcomeMessage: String) async throws -> MLSGroupID {
        processWelcomeMessageWelcomeMessageStringMLSGroupIDCallsCount += 1
        processWelcomeMessageWelcomeMessageStringMLSGroupIDReceivedWelcomeMessage = welcomeMessage
        processWelcomeMessageWelcomeMessageStringMLSGroupIDReceivedInvocations.append(welcomeMessage)
        if let error = processWelcomeMessageWelcomeMessageStringMLSGroupIDThrowableError {
            throw error
        }
        if let processWelcomeMessageWelcomeMessageStringMLSGroupIDClosure = processWelcomeMessageWelcomeMessageStringMLSGroupIDClosure {
            return try await processWelcomeMessageWelcomeMessageStringMLSGroupIDClosure(welcomeMessage)
        } else {
            return processWelcomeMessageWelcomeMessageStringMLSGroupIDReturnValue
        }
    }

    //MARK: - encrypt

    public var encryptMessageDataForGroupIDMLSGroupIDDataThrowableError: (any Error)?
    public var encryptMessageDataForGroupIDMLSGroupIDDataCallsCount = 0
    public var encryptMessageDataForGroupIDMLSGroupIDDataCalled: Bool {
        return encryptMessageDataForGroupIDMLSGroupIDDataCallsCount > 0
    }
    public var encryptMessageDataForGroupIDMLSGroupIDDataReceivedArguments: (message: Data, groupID: MLSGroupID)?
    public var encryptMessageDataForGroupIDMLSGroupIDDataReceivedInvocations: [(message: Data, groupID: MLSGroupID)] = []
    public var encryptMessageDataForGroupIDMLSGroupIDDataReturnValue: Data!
    public var encryptMessageDataForGroupIDMLSGroupIDDataClosure: ((Data, MLSGroupID) async throws -> Data)?

    public func encrypt(message: Data, for groupID: MLSGroupID) async throws -> Data {
        encryptMessageDataForGroupIDMLSGroupIDDataCallsCount += 1
        encryptMessageDataForGroupIDMLSGroupIDDataReceivedArguments = (message: message, groupID: groupID)
        encryptMessageDataForGroupIDMLSGroupIDDataReceivedInvocations.append((message: message, groupID: groupID))
        if let error = encryptMessageDataForGroupIDMLSGroupIDDataThrowableError {
            throw error
        }
        if let encryptMessageDataForGroupIDMLSGroupIDDataClosure = encryptMessageDataForGroupIDMLSGroupIDDataClosure {
            return try await encryptMessageDataForGroupIDMLSGroupIDDataClosure(message, groupID)
        } else {
            return encryptMessageDataForGroupIDMLSGroupIDDataReturnValue
        }
    }


}
public class OneOnOneMigratorInterfaceMock: OneOnOneMigratorInterface {

    public init() {}



    //MARK: - migrateToMLS

    public var migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDThrowableError: (any Error)?
    public var migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDCallsCount = 0
    public var migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDCalled: Bool {
        return migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDCallsCount > 0
    }
    public var migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDReceivedArguments: (userID: QualifiedID, context: NSManagedObjectContext)?
    public var migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDReceivedInvocations: [(userID: QualifiedID, context: NSManagedObjectContext)] = []
    public var migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDReturnValue: MLSGroupID!
    public var migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDClosure: ((QualifiedID, NSManagedObjectContext) async throws -> MLSGroupID)?

    @discardableResult
    public func migrateToMLS(userID: QualifiedID, in context: NSManagedObjectContext) async throws -> MLSGroupID {
        migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDCallsCount += 1
        migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDReceivedArguments = (userID: userID, context: context)
        migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDReceivedInvocations.append((userID: userID, context: context))
        if let error = migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDThrowableError {
            throw error
        }
        if let migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDClosure = migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDClosure {
            return try await migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDClosure(userID, context)
        } else {
            return migrateToMLSUserIDQualifiedIDInContextNSManagedObjectContextMLSGroupIDReturnValue
        }
    }


}
public class OneOnOneProtocolSelectorInterfaceMock: OneOnOneProtocolSelectorInterface {

    public init() {}



    //MARK: - getProtocolForUser

    public var getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolThrowableError: (any Error)?
    public var getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolCallsCount = 0
    public var getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolCalled: Bool {
        return getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolCallsCount > 0
    }
    public var getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolReceivedArguments: (id: QualifiedID, context: NSManagedObjectContext)?
    public var getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolReceivedInvocations: [(id: QualifiedID, context: NSManagedObjectContext)] = []
    public var getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolReturnValue: MessageProtocol?
    public var getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolClosure: ((QualifiedID, NSManagedObjectContext) async throws -> MessageProtocol?)?

    public func getProtocolForUser(with id: QualifiedID, in context: NSManagedObjectContext) async throws -> MessageProtocol? {
        getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolCallsCount += 1
        getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolReceivedArguments = (id: id, context: context)
        getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolReceivedInvocations.append((id: id, context: context))
        if let error = getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolThrowableError {
            throw error
        }
        if let getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolClosure = getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolClosure {
            return try await getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolClosure(id, context)
        } else {
            return getProtocolForUserWithIdQualifiedIDInContextNSManagedObjectContextMessageProtocolReturnValue
        }
    }


}
public class OneOnOneResolverInterfaceMock: OneOnOneResolverInterface {

    public init() {}



    //MARK: - resolveAllOneOnOneConversations

    public var resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidThrowableError: (any Error)?
    public var resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidCallsCount = 0
    public var resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidCalled: Bool {
        return resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidCallsCount > 0
    }
    public var resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidReceivedContext: (NSManagedObjectContext)?
    public var resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidReceivedInvocations: [(NSManagedObjectContext)] = []
    public var resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidClosure: ((NSManagedObjectContext) async throws -> Void)?

    public func resolveAllOneOnOneConversations(in context: NSManagedObjectContext) async throws {
        resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidCallsCount += 1
        resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidReceivedContext = context
        resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidReceivedInvocations.append(context)
        if let error = resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidThrowableError {
            throw error
        }
        try await resolveAllOneOnOneConversationsInContextNSManagedObjectContextVoidClosure?(context)
    }

    //MARK: - resolveOneOnOneConversation

    public var resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionThrowableError: (any Error)?
    public var resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionCallsCount = 0
    public var resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionCalled: Bool {
        return resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionCallsCount > 0
    }
    public var resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionReceivedArguments: (userID: QualifiedID, context: NSManagedObjectContext)?
    public var resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionReceivedInvocations: [(userID: QualifiedID, context: NSManagedObjectContext)] = []
    public var resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionReturnValue: OneOnOneConversationResolution!
    public var resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionClosure: ((QualifiedID, NSManagedObjectContext) async throws -> OneOnOneConversationResolution)?

    @discardableResult
    public func resolveOneOnOneConversation(with userID: QualifiedID, in context: NSManagedObjectContext) async throws -> OneOnOneConversationResolution {
        resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionCallsCount += 1
        resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionReceivedArguments = (userID: userID, context: context)
        resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionReceivedInvocations.append((userID: userID, context: context))
        if let error = resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionThrowableError {
            throw error
        }
        if let resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionClosure = resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionClosure {
            return try await resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionClosure(userID, context)
        } else {
            return resolveOneOnOneConversationWithUserIDQualifiedIDInContextNSManagedObjectContextOneOnOneConversationResolutionReturnValue
        }
    }


}
public class ProteusServiceInterfaceMock: ProteusServiceInterface {

    public init() {}

    public var lastPrekeyIDCallsCount = 0
    public var lastPrekeyIDCalled: Bool {
        return lastPrekeyIDCallsCount > 0
    }

    public var lastPrekeyID: UInt16 {
        get async {
            lastPrekeyIDCallsCount += 1
            if let lastPrekeyIDClosure = lastPrekeyIDClosure {
                return await lastPrekeyIDClosure()
            } else {
                return underlyingLastPrekeyID
            }
        }
    }
    public var underlyingLastPrekeyID: UInt16!
    public var lastPrekeyIDClosure: (() async -> UInt16)?


    //MARK: - establishSession

    public var establishSessionIdProteusSessionIDFromPrekeyStringVoidThrowableError: (any Error)?
    public var establishSessionIdProteusSessionIDFromPrekeyStringVoidCallsCount = 0
    public var establishSessionIdProteusSessionIDFromPrekeyStringVoidCalled: Bool {
        return establishSessionIdProteusSessionIDFromPrekeyStringVoidCallsCount > 0
    }
    public var establishSessionIdProteusSessionIDFromPrekeyStringVoidReceivedArguments: (id: ProteusSessionID, fromPrekey: String)?
    public var establishSessionIdProteusSessionIDFromPrekeyStringVoidReceivedInvocations: [(id: ProteusSessionID, fromPrekey: String)] = []
    public var establishSessionIdProteusSessionIDFromPrekeyStringVoidClosure: ((ProteusSessionID, String) async throws -> Void)?

    public func establishSession(id: ProteusSessionID, fromPrekey: String) async throws {
        establishSessionIdProteusSessionIDFromPrekeyStringVoidCallsCount += 1
        establishSessionIdProteusSessionIDFromPrekeyStringVoidReceivedArguments = (id: id, fromPrekey: fromPrekey)
        establishSessionIdProteusSessionIDFromPrekeyStringVoidReceivedInvocations.append((id: id, fromPrekey: fromPrekey))
        if let error = establishSessionIdProteusSessionIDFromPrekeyStringVoidThrowableError {
            throw error
        }
        try await establishSessionIdProteusSessionIDFromPrekeyStringVoidClosure?(id, fromPrekey)
    }

    //MARK: - deleteSession

    public var deleteSessionIdProteusSessionIDVoidThrowableError: (any Error)?
    public var deleteSessionIdProteusSessionIDVoidCallsCount = 0
    public var deleteSessionIdProteusSessionIDVoidCalled: Bool {
        return deleteSessionIdProteusSessionIDVoidCallsCount > 0
    }
    public var deleteSessionIdProteusSessionIDVoidReceivedId: (ProteusSessionID)?
    public var deleteSessionIdProteusSessionIDVoidReceivedInvocations: [(ProteusSessionID)] = []
    public var deleteSessionIdProteusSessionIDVoidClosure: ((ProteusSessionID) async throws -> Void)?

    public func deleteSession(id: ProteusSessionID) async throws {
        deleteSessionIdProteusSessionIDVoidCallsCount += 1
        deleteSessionIdProteusSessionIDVoidReceivedId = id
        deleteSessionIdProteusSessionIDVoidReceivedInvocations.append(id)
        if let error = deleteSessionIdProteusSessionIDVoidThrowableError {
            throw error
        }
        try await deleteSessionIdProteusSessionIDVoidClosure?(id)
    }

    //MARK: - sessionExists

    public var sessionExistsIdProteusSessionIDBoolCallsCount = 0
    public var sessionExistsIdProteusSessionIDBoolCalled: Bool {
        return sessionExistsIdProteusSessionIDBoolCallsCount > 0
    }
    public var sessionExistsIdProteusSessionIDBoolReceivedId: (ProteusSessionID)?
    public var sessionExistsIdProteusSessionIDBoolReceivedInvocations: [(ProteusSessionID)] = []
    public var sessionExistsIdProteusSessionIDBoolReturnValue: Bool!
    public var sessionExistsIdProteusSessionIDBoolClosure: ((ProteusSessionID) async -> Bool)?

    public func sessionExists(id: ProteusSessionID) async -> Bool {
        sessionExistsIdProteusSessionIDBoolCallsCount += 1
        sessionExistsIdProteusSessionIDBoolReceivedId = id
        sessionExistsIdProteusSessionIDBoolReceivedInvocations.append(id)
        if let sessionExistsIdProteusSessionIDBoolClosure = sessionExistsIdProteusSessionIDBoolClosure {
            return await sessionExistsIdProteusSessionIDBoolClosure(id)
        } else {
            return sessionExistsIdProteusSessionIDBoolReturnValue
        }
    }

    //MARK: - encrypt

    public var encryptDataDataForSessionIdProteusSessionIDDataThrowableError: (any Error)?
    public var encryptDataDataForSessionIdProteusSessionIDDataCallsCount = 0
    public var encryptDataDataForSessionIdProteusSessionIDDataCalled: Bool {
        return encryptDataDataForSessionIdProteusSessionIDDataCallsCount > 0
    }
    public var encryptDataDataForSessionIdProteusSessionIDDataReceivedArguments: (data: Data, id: ProteusSessionID)?
    public var encryptDataDataForSessionIdProteusSessionIDDataReceivedInvocations: [(data: Data, id: ProteusSessionID)] = []
    public var encryptDataDataForSessionIdProteusSessionIDDataReturnValue: Data!
    public var encryptDataDataForSessionIdProteusSessionIDDataClosure: ((Data, ProteusSessionID) async throws -> Data)?

    public func encrypt(data: Data, forSession id: ProteusSessionID) async throws -> Data {
        encryptDataDataForSessionIdProteusSessionIDDataCallsCount += 1
        encryptDataDataForSessionIdProteusSessionIDDataReceivedArguments = (data: data, id: id)
        encryptDataDataForSessionIdProteusSessionIDDataReceivedInvocations.append((data: data, id: id))
        if let error = encryptDataDataForSessionIdProteusSessionIDDataThrowableError {
            throw error
        }
        if let encryptDataDataForSessionIdProteusSessionIDDataClosure = encryptDataDataForSessionIdProteusSessionIDDataClosure {
            return try await encryptDataDataForSessionIdProteusSessionIDDataClosure(data, id)
        } else {
            return encryptDataDataForSessionIdProteusSessionIDDataReturnValue
        }
    }

    //MARK: - encryptBatched

    public var encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataThrowableError: (any Error)?
    public var encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataCallsCount = 0
    public var encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataCalled: Bool {
        return encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataCallsCount > 0
    }
    public var encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataReceivedArguments: (data: Data, sessions: [ProteusSessionID])?
    public var encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataReceivedInvocations: [(data: Data, sessions: [ProteusSessionID])] = []
    public var encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataReturnValue: [String: Data]!
    public var encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataClosure: ((Data, [ProteusSessionID]) async throws -> [String: Data])?

    public func encryptBatched(data: Data, forSessions sessions: [ProteusSessionID]) async throws -> [String: Data] {
        encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataCallsCount += 1
        encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataReceivedArguments = (data: data, sessions: sessions)
        encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataReceivedInvocations.append((data: data, sessions: sessions))
        if let error = encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataThrowableError {
            throw error
        }
        if let encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataClosure = encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataClosure {
            return try await encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataClosure(data, sessions)
        } else {
            return encryptBatchedDataDataForSessionsSessionsProteusSessionIDStringDataReturnValue
        }
    }

    //MARK: - decrypt

    public var decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataThrowableError: (any Error)?
    public var decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataCallsCount = 0
    public var decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataCalled: Bool {
        return decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataCallsCount > 0
    }
    public var decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataReceivedArguments: (data: Data, id: ProteusSessionID)?
    public var decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataReceivedInvocations: [(data: Data, id: ProteusSessionID)] = []
    public var decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataReturnValue: (didCreateNewSession: Bool, decryptedData: Data)!
    public var decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataClosure: ((Data, ProteusSessionID) async throws -> (didCreateNewSession: Bool, decryptedData: Data))?

    public func decrypt(data: Data, forSession id: ProteusSessionID) async throws -> (didCreateNewSession: Bool, decryptedData: Data) {
        decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataCallsCount += 1
        decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataReceivedArguments = (data: data, id: id)
        decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataReceivedInvocations.append((data: data, id: id))
        if let error = decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataThrowableError {
            throw error
        }
        if let decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataClosure = decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataClosure {
            return try await decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataClosure(data, id)
        } else {
            return decryptDataDataForSessionIdProteusSessionID_DidCreateNewSessionBoolDecryptedDataDataReturnValue
        }
    }

    //MARK: - generatePrekey

    public var generatePrekeyIdUInt16StringThrowableError: (any Error)?
    public var generatePrekeyIdUInt16StringCallsCount = 0
    public var generatePrekeyIdUInt16StringCalled: Bool {
        return generatePrekeyIdUInt16StringCallsCount > 0
    }
    public var generatePrekeyIdUInt16StringReceivedId: (UInt16)?
    public var generatePrekeyIdUInt16StringReceivedInvocations: [(UInt16)] = []
    public var generatePrekeyIdUInt16StringReturnValue: String!
    public var generatePrekeyIdUInt16StringClosure: ((UInt16) async throws -> String)?

    public func generatePrekey(id: UInt16) async throws -> String {
        generatePrekeyIdUInt16StringCallsCount += 1
        generatePrekeyIdUInt16StringReceivedId = id
        generatePrekeyIdUInt16StringReceivedInvocations.append(id)
        if let error = generatePrekeyIdUInt16StringThrowableError {
            throw error
        }
        if let generatePrekeyIdUInt16StringClosure = generatePrekeyIdUInt16StringClosure {
            return try await generatePrekeyIdUInt16StringClosure(id)
        } else {
            return generatePrekeyIdUInt16StringReturnValue
        }
    }

    //MARK: - lastPrekey

    public var lastPrekeyStringThrowableError: (any Error)?
    public var lastPrekeyStringCallsCount = 0
    public var lastPrekeyStringCalled: Bool {
        return lastPrekeyStringCallsCount > 0
    }
    public var lastPrekeyStringReturnValue: String!
    public var lastPrekeyStringClosure: (() async throws -> String)?

    public func lastPrekey() async throws -> String {
        lastPrekeyStringCallsCount += 1
        if let error = lastPrekeyStringThrowableError {
            throw error
        }
        if let lastPrekeyStringClosure = lastPrekeyStringClosure {
            return try await lastPrekeyStringClosure()
        } else {
            return lastPrekeyStringReturnValue
        }
    }

    //MARK: - generatePrekeys

    public var generatePrekeysStartUInt16CountUInt16_UInt16StringThrowableError: (any Error)?
    public var generatePrekeysStartUInt16CountUInt16_UInt16StringCallsCount = 0
    public var generatePrekeysStartUInt16CountUInt16_UInt16StringCalled: Bool {
        return generatePrekeysStartUInt16CountUInt16_UInt16StringCallsCount > 0
    }
    public var generatePrekeysStartUInt16CountUInt16_UInt16StringReceivedArguments: (start: UInt16, count: UInt16)?
    public var generatePrekeysStartUInt16CountUInt16_UInt16StringReceivedInvocations: [(start: UInt16, count: UInt16)] = []
    public var generatePrekeysStartUInt16CountUInt16_UInt16StringReturnValue: [IdPrekeyTuple]!
    public var generatePrekeysStartUInt16CountUInt16_UInt16StringClosure: ((UInt16, UInt16) async throws -> [IdPrekeyTuple])?

    public func generatePrekeys(start: UInt16, count: UInt16) async throws -> [IdPrekeyTuple] {
        generatePrekeysStartUInt16CountUInt16_UInt16StringCallsCount += 1
        generatePrekeysStartUInt16CountUInt16_UInt16StringReceivedArguments = (start: start, count: count)
        generatePrekeysStartUInt16CountUInt16_UInt16StringReceivedInvocations.append((start: start, count: count))
        if let error = generatePrekeysStartUInt16CountUInt16_UInt16StringThrowableError {
            throw error
        }
        if let generatePrekeysStartUInt16CountUInt16_UInt16StringClosure = generatePrekeysStartUInt16CountUInt16_UInt16StringClosure {
            return try await generatePrekeysStartUInt16CountUInt16_UInt16StringClosure(start, count)
        } else {
            return generatePrekeysStartUInt16CountUInt16_UInt16StringReturnValue
        }
    }

    //MARK: - localFingerprint

    public var localFingerprintStringThrowableError: (any Error)?
    public var localFingerprintStringCallsCount = 0
    public var localFingerprintStringCalled: Bool {
        return localFingerprintStringCallsCount > 0
    }
    public var localFingerprintStringReturnValue: String!
    public var localFingerprintStringClosure: (() async throws -> String)?

    public func localFingerprint() async throws -> String {
        localFingerprintStringCallsCount += 1
        if let error = localFingerprintStringThrowableError {
            throw error
        }
        if let localFingerprintStringClosure = localFingerprintStringClosure {
            return try await localFingerprintStringClosure()
        } else {
            return localFingerprintStringReturnValue
        }
    }

    //MARK: - remoteFingerprint

    public var remoteFingerprintForSessionIdProteusSessionIDStringThrowableError: (any Error)?
    public var remoteFingerprintForSessionIdProteusSessionIDStringCallsCount = 0
    public var remoteFingerprintForSessionIdProteusSessionIDStringCalled: Bool {
        return remoteFingerprintForSessionIdProteusSessionIDStringCallsCount > 0
    }
    public var remoteFingerprintForSessionIdProteusSessionIDStringReceivedId: (ProteusSessionID)?
    public var remoteFingerprintForSessionIdProteusSessionIDStringReceivedInvocations: [(ProteusSessionID)] = []
    public var remoteFingerprintForSessionIdProteusSessionIDStringReturnValue: String!
    public var remoteFingerprintForSessionIdProteusSessionIDStringClosure: ((ProteusSessionID) async throws -> String)?

    public func remoteFingerprint(forSession id: ProteusSessionID) async throws -> String {
        remoteFingerprintForSessionIdProteusSessionIDStringCallsCount += 1
        remoteFingerprintForSessionIdProteusSessionIDStringReceivedId = id
        remoteFingerprintForSessionIdProteusSessionIDStringReceivedInvocations.append(id)
        if let error = remoteFingerprintForSessionIdProteusSessionIDStringThrowableError {
            throw error
        }
        if let remoteFingerprintForSessionIdProteusSessionIDStringClosure = remoteFingerprintForSessionIdProteusSessionIDStringClosure {
            return try await remoteFingerprintForSessionIdProteusSessionIDStringClosure(id)
        } else {
            return remoteFingerprintForSessionIdProteusSessionIDStringReturnValue
        }
    }

    //MARK: - fingerprint

    public var fingerprintFromPrekeyPrekeyStringStringThrowableError: (any Error)?
    public var fingerprintFromPrekeyPrekeyStringStringCallsCount = 0
    public var fingerprintFromPrekeyPrekeyStringStringCalled: Bool {
        return fingerprintFromPrekeyPrekeyStringStringCallsCount > 0
    }
    public var fingerprintFromPrekeyPrekeyStringStringReceivedPrekey: (String)?
    public var fingerprintFromPrekeyPrekeyStringStringReceivedInvocations: [(String)] = []
    public var fingerprintFromPrekeyPrekeyStringStringReturnValue: String!
    public var fingerprintFromPrekeyPrekeyStringStringClosure: ((String) async throws -> String)?

    public func fingerprint(fromPrekey prekey: String) async throws -> String {
        fingerprintFromPrekeyPrekeyStringStringCallsCount += 1
        fingerprintFromPrekeyPrekeyStringStringReceivedPrekey = prekey
        fingerprintFromPrekeyPrekeyStringStringReceivedInvocations.append(prekey)
        if let error = fingerprintFromPrekeyPrekeyStringStringThrowableError {
            throw error
        }
        if let fingerprintFromPrekeyPrekeyStringStringClosure = fingerprintFromPrekeyPrekeyStringStringClosure {
            return try await fingerprintFromPrekeyPrekeyStringStringClosure(prekey)
        } else {
            return fingerprintFromPrekeyPrekeyStringStringReturnValue
        }
    }


}
public class ProteusToMLSMigrationCoordinatingMock: ProteusToMLSMigrationCoordinating {

    public init() {}



    //MARK: - updateMigrationStatus

    public var updateMigrationStatusVoidThrowableError: (any Error)?
    public var updateMigrationStatusVoidCallsCount = 0
    public var updateMigrationStatusVoidCalled: Bool {
        return updateMigrationStatusVoidCallsCount > 0
    }
    public var updateMigrationStatusVoidClosure: (() async throws -> Void)?

    public func updateMigrationStatus() async throws {
        updateMigrationStatusVoidCallsCount += 1
        if let error = updateMigrationStatusVoidThrowableError {
            throw error
        }
        try await updateMigrationStatusVoidClosure?()
    }


}
class ProteusToMLSMigrationStorageInterfaceMock: ProteusToMLSMigrationStorageInterface {


    var migrationStatus: ProteusToMLSMigrationCoordinator.MigrationStatus {
        get { return underlyingMigrationStatus }
        set(value) { underlyingMigrationStatus = value }
    }
    var underlyingMigrationStatus: (ProteusToMLSMigrationCoordinator.MigrationStatus)!



}
public class StaleMLSKeyDetectorProtocolMock: StaleMLSKeyDetectorProtocol {

    public init() {}

    public var refreshIntervalInDays: UInt {
        get { return underlyingRefreshIntervalInDays }
        set(value) { underlyingRefreshIntervalInDays = value }
    }
    public var underlyingRefreshIntervalInDays: (UInt)!
    public var groupsWithStaleKeyingMaterial: Set<MLSGroupID> {
        get { return underlyingGroupsWithStaleKeyingMaterial }
        set(value) { underlyingGroupsWithStaleKeyingMaterial = value }
    }
    public var underlyingGroupsWithStaleKeyingMaterial: (Set<MLSGroupID>)!


    //MARK: - keyingMaterialUpdated

    public var keyingMaterialUpdatedForGroupIDMLSGroupIDVoidCallsCount = 0
    public var keyingMaterialUpdatedForGroupIDMLSGroupIDVoidCalled: Bool {
        return keyingMaterialUpdatedForGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var keyingMaterialUpdatedForGroupIDMLSGroupIDVoidReceivedGroupID: (MLSGroupID)?
    public var keyingMaterialUpdatedForGroupIDMLSGroupIDVoidReceivedInvocations: [(MLSGroupID)] = []
    public var keyingMaterialUpdatedForGroupIDMLSGroupIDVoidClosure: ((MLSGroupID) -> Void)?

    public func keyingMaterialUpdated(for groupID: MLSGroupID) {
        keyingMaterialUpdatedForGroupIDMLSGroupIDVoidCallsCount += 1
        keyingMaterialUpdatedForGroupIDMLSGroupIDVoidReceivedGroupID = groupID
        keyingMaterialUpdatedForGroupIDMLSGroupIDVoidReceivedInvocations.append(groupID)
        keyingMaterialUpdatedForGroupIDMLSGroupIDVoidClosure?(groupID)
    }


}
public class SubconversationGroupIDRepositoryInterfaceMock: SubconversationGroupIDRepositoryInterface {

    public init() {}



    //MARK: - storeSubconversationGroupID

    public var storeSubconversationGroupIDGroupIDMLSGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDVoidCallsCount = 0
    public var storeSubconversationGroupIDGroupIDMLSGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDVoidCalled: Bool {
        return storeSubconversationGroupIDGroupIDMLSGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var storeSubconversationGroupIDGroupIDMLSGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDVoidReceivedArguments: (groupID: MLSGroupID?, type: SubgroupType, parentGroupID: MLSGroupID)?
    public var storeSubconversationGroupIDGroupIDMLSGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDVoidReceivedInvocations: [(groupID: MLSGroupID?, type: SubgroupType, parentGroupID: MLSGroupID)] = []
    public var storeSubconversationGroupIDGroupIDMLSGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDVoidClosure: ((MLSGroupID?, SubgroupType, MLSGroupID) async -> Void)?

    public func storeSubconversationGroupID(_ groupID: MLSGroupID?, forType type: SubgroupType, parentGroupID: MLSGroupID) async {
        storeSubconversationGroupIDGroupIDMLSGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDVoidCallsCount += 1
        storeSubconversationGroupIDGroupIDMLSGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDVoidReceivedArguments = (groupID: groupID, type: type, parentGroupID: parentGroupID)
        storeSubconversationGroupIDGroupIDMLSGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDVoidReceivedInvocations.append((groupID: groupID, type: type, parentGroupID: parentGroupID))
        await storeSubconversationGroupIDGroupIDMLSGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDVoidClosure?(groupID, type, parentGroupID)
    }

    //MARK: - fetchSubconversationGroupID

    public var fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDCallsCount = 0
    public var fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDCalled: Bool {
        return fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDCallsCount > 0
    }
    public var fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDReceivedArguments: (type: SubgroupType, parentGroupID: MLSGroupID)?
    public var fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDReceivedInvocations: [(type: SubgroupType, parentGroupID: MLSGroupID)] = []
    public var fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDReturnValue: MLSGroupID?
    public var fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDClosure: ((SubgroupType, MLSGroupID) async -> MLSGroupID?)?

    public func fetchSubconversationGroupID(forType type: SubgroupType, parentGroupID: MLSGroupID) async -> MLSGroupID? {
        fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDCallsCount += 1
        fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDReceivedArguments = (type: type, parentGroupID: parentGroupID)
        fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDReceivedInvocations.append((type: type, parentGroupID: parentGroupID))
        if let fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDClosure = fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDClosure {
            return await fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDClosure(type, parentGroupID)
        } else {
            return fetchSubconversationGroupIDForTypeTypeSubgroupTypeParentGroupIDMLSGroupIDMLSGroupIDReturnValue
        }
    }

    //MARK: - findSubgroupTypeAndParentID

    public var findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeCallsCount = 0
    public var findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeCalled: Bool {
        return findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeCallsCount > 0
    }
    public var findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeReceivedTargetGroupID: (MLSGroupID)?
    public var findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeReceivedInvocations: [(MLSGroupID)] = []
    public var findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeReturnValue: (parentID: MLSGroupID, type: SubgroupType)?
    public var findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeClosure: ((MLSGroupID) async -> (parentID: MLSGroupID, type: SubgroupType)?)?

    public func findSubgroupTypeAndParentID(for targetGroupID: MLSGroupID) async -> (parentID: MLSGroupID, type: SubgroupType)? {
        findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeCallsCount += 1
        findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeReceivedTargetGroupID = targetGroupID
        findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeReceivedInvocations.append(targetGroupID)
        if let findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeClosure = findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeClosure {
            return await findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeClosure(targetGroupID)
        } else {
            return findSubgroupTypeAndParentIDForTargetGroupIDMLSGroupID_ParentIDMLSGroupIDTypeSubgroupTypeReturnValue
        }
    }


}
public class UpdateMLSGroupVerificationStatusUseCaseProtocolMock: UpdateMLSGroupVerificationStatusUseCaseProtocol {

    public init() {}



    //MARK: - invoke

    public var invokeForConversationZMConversationGroupIDMLSGroupIDVoidThrowableError: (any Error)?
    public var invokeForConversationZMConversationGroupIDMLSGroupIDVoidCallsCount = 0
    public var invokeForConversationZMConversationGroupIDMLSGroupIDVoidCalled: Bool {
        return invokeForConversationZMConversationGroupIDMLSGroupIDVoidCallsCount > 0
    }
    public var invokeForConversationZMConversationGroupIDMLSGroupIDVoidReceivedArguments: (conversation: ZMConversation, groupID: MLSGroupID)?
    public var invokeForConversationZMConversationGroupIDMLSGroupIDVoidReceivedInvocations: [(conversation: ZMConversation, groupID: MLSGroupID)] = []
    public var invokeForConversationZMConversationGroupIDMLSGroupIDVoidClosure: ((ZMConversation, MLSGroupID) async throws -> Void)?

    public func invoke(for conversation: ZMConversation, groupID: MLSGroupID) async throws {
        invokeForConversationZMConversationGroupIDMLSGroupIDVoidCallsCount += 1
        invokeForConversationZMConversationGroupIDMLSGroupIDVoidReceivedArguments = (conversation: conversation, groupID: groupID)
        invokeForConversationZMConversationGroupIDMLSGroupIDVoidReceivedInvocations.append((conversation: conversation, groupID: groupID))
        if let error = invokeForConversationZMConversationGroupIDMLSGroupIDVoidThrowableError {
            throw error
        }
        try await invokeForConversationZMConversationGroupIDMLSGroupIDVoidClosure?(conversation, groupID)
    }


}
public class UserObservingMock: UserObserving {

    public init() {}



    //MARK: - userDidChange

    public var userDidChangeChangeInfoUserChangeInfoVoidCallsCount = 0
    public var userDidChangeChangeInfoUserChangeInfoVoidCalled: Bool {
        return userDidChangeChangeInfoUserChangeInfoVoidCallsCount > 0
    }
    public var userDidChangeChangeInfoUserChangeInfoVoidReceivedChangeInfo: (UserChangeInfo)?
    public var userDidChangeChangeInfoUserChangeInfoVoidReceivedInvocations: [(UserChangeInfo)] = []
    public var userDidChangeChangeInfoUserChangeInfoVoidClosure: ((UserChangeInfo) -> Void)?

    public func userDidChange(_ changeInfo: UserChangeInfo) {
        userDidChangeChangeInfoUserChangeInfoVoidCallsCount += 1
        userDidChangeChangeInfoUserChangeInfoVoidReceivedChangeInfo = changeInfo
        userDidChangeChangeInfoUserChangeInfoVoidReceivedInvocations.append(changeInfo)
        userDidChangeChangeInfoUserChangeInfoVoidClosure?(changeInfo)
    }


}
// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
