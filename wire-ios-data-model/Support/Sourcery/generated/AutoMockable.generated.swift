// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
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

// swiftlint:disable line_length
// swiftlint:disable variable_name

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

    public var evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingBoolErrorVoidVoidCallsCount = 0
    public var evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingBoolErrorVoidVoidCalled: Bool {
        return evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingBoolErrorVoidVoidCallsCount > 0
    }
    public var evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingBoolErrorVoidVoidReceivedArguments: (policy: LAPolicy, localizedReason: String, reply: (Bool, Error?) -> Void)?
    public var evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingBoolErrorVoidVoidReceivedInvocations: [(policy: LAPolicy, localizedReason: String, reply: (Bool, Error?) -> Void)] = []
    public var evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingBoolErrorVoidVoidClosure: ((LAPolicy, String, @escaping (Bool, Error?) -> Void) -> Void)?

    public func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: (@escaping (Bool, Error?) -> Void)) {
        evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingBoolErrorVoidVoidCallsCount += 1
        evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingBoolErrorVoidVoidReceivedArguments = (policy: policy, localizedReason: localizedReason, reply: reply)
        evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingBoolErrorVoidVoidReceivedInvocations.append((policy: policy, localizedReason: localizedReason, reply: reply))
        evaluatePolicyPolicyLAPolicyLocalizedReasonStringReplyEscapingBoolErrorVoidVoidClosure?(policy, localizedReason, reply)
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
public class ConversationLikeMock: ConversationLike {

    public init() {}

    public var objectId: Any {
        get { return underlyingObjectId }
        set(value) { underlyingObjectId = value }
    }
    public var underlyingObjectId: (Any)!
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
    public var isChannel: Bool {
        get { return underlyingIsChannel }
        set(value) { underlyingIsChannel = value }
    }
    public var underlyingIsChannel: (Bool)!
    public var privateChannelPermission: PrivateChannelPermission {
        get { return underlyingPrivateChannelPermission }
        set(value) { underlyingPrivateChannelPermission = value }
    }
    public var underlyingPrivateChannelPermission: (PrivateChannelPermission)!
    public var wireCellName: String {
        get { return underlyingWireCellName }
        set(value) { underlyingWireCellName = value }
    }
    public var underlyingWireCellName: (String)!


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
public class CoreCryptoContextProtocolMock: CoreCryptoContextProtocol, @unchecked Sendable {

    public init() {}



    //MARK: - addClientsToConversation

    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsThrowableError: (any Error)?
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsCallsCount = 0
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsCalled: Bool {
        return addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsCallsCount > 0
    }
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsReceivedArguments: (conversationId: Data, keyPackages: [Data])?
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsReceivedInvocations: [(conversationId: Data, keyPackages: [Data])] = []
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsReturnValue: WireCoreCryptoUniffi.NewCrlDistributionPoints!
    public var addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsClosure: ((Data, [Data]) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints)?

    public func addClientsToConversation(conversationId: Data, keyPackages: [Data]) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints {
        addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsCallsCount += 1
        addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsReceivedArguments = (conversationId: conversationId, keyPackages: keyPackages)
        addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsReceivedInvocations.append((conversationId: conversationId, keyPackages: keyPackages))
        if let error = addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsThrowableError {
            throw error
        }
        if let addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsClosure = addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsClosure {
            return try await addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsClosure(conversationId, keyPackages)
        } else {
            return addClientsToConversationConversationIdDataKeyPackagesDataWireCoreCryptoUniffiNewCrlDistributionPointsReturnValue
        }
    }

    //MARK: - clientKeypackages

    public var clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataThrowableError: (any Error)?
    public var clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataCallsCount = 0
    public var clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataCalled: Bool {
        return clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataCallsCount > 0
    }
    public var clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataReceivedArguments: (ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.CredentialType, amountRequested: UInt32)?
    public var clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataReceivedInvocations: [(ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.CredentialType, amountRequested: UInt32)] = []
    public var clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataReturnValue: [Data]!
    public var clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataClosure: ((WireCoreCryptoUniffi.Ciphersuite, WireCoreCryptoUniffi.CredentialType, UInt32) async throws -> [Data])?

    public func clientKeypackages(ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.CredentialType, amountRequested: UInt32) async throws -> [Data] {
        clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataCallsCount += 1
        clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataReceivedArguments = (ciphersuite: ciphersuite, credentialType: credentialType, amountRequested: amountRequested)
        clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataReceivedInvocations.append((ciphersuite: ciphersuite, credentialType: credentialType, amountRequested: amountRequested))
        if let error = clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataThrowableError {
            throw error
        }
        if let clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataClosure = clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataClosure {
            return try await clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataClosure(ciphersuite, credentialType, amountRequested)
        } else {
            return clientKeypackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeAmountRequestedUInt32DataReturnValue
        }
    }

    //MARK: - clientPublicKey

    public var clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataThrowableError: (any Error)?
    public var clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataCallsCount = 0
    public var clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataCalled: Bool {
        return clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataCallsCount > 0
    }
    public var clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataReceivedArguments: (ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.CredentialType)?
    public var clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataReceivedInvocations: [(ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.CredentialType)] = []
    public var clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataReturnValue: Data!
    public var clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataClosure: ((WireCoreCryptoUniffi.Ciphersuite, WireCoreCryptoUniffi.CredentialType) async throws -> Data)?

    public func clientPublicKey(ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.CredentialType) async throws -> Data {
        clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataCallsCount += 1
        clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataReceivedArguments = (ciphersuite: ciphersuite, credentialType: credentialType)
        clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataReceivedInvocations.append((ciphersuite: ciphersuite, credentialType: credentialType))
        if let error = clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataThrowableError {
            throw error
        }
        if let clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataClosure = clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataClosure {
            return try await clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataClosure(ciphersuite, credentialType)
        } else {
            return clientPublicKeyCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeDataReturnValue
        }
    }

    //MARK: - clientValidKeypackagesCount

    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64ThrowableError: (any Error)?
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64CallsCount = 0
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64Called: Bool {
        return clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64CallsCount > 0
    }
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64ReceivedArguments: (ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.CredentialType)?
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64ReceivedInvocations: [(ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.CredentialType)] = []
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64ReturnValue: UInt64!
    public var clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64Closure: ((WireCoreCryptoUniffi.Ciphersuite, WireCoreCryptoUniffi.CredentialType) async throws -> UInt64)?

    public func clientValidKeypackagesCount(ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.CredentialType) async throws -> UInt64 {
        clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64CallsCount += 1
        clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64ReceivedArguments = (ciphersuite: ciphersuite, credentialType: credentialType)
        clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64ReceivedInvocations.append((ciphersuite: ciphersuite, credentialType: credentialType))
        if let error = clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64ThrowableError {
            throw error
        }
        if let clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64Closure = clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64Closure {
            return try await clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64Closure(ciphersuite, credentialType)
        } else {
            return clientValidKeypackagesCountCiphersuiteWireCoreCryptoUniffiCiphersuiteCredentialTypeWireCoreCryptoUniffiCredentialTypeUInt64ReturnValue
        }
    }

    //MARK: - commitPendingProposals

    public var commitPendingProposalsConversationIdDataVoidThrowableError: (any Error)?
    public var commitPendingProposalsConversationIdDataVoidCallsCount = 0
    public var commitPendingProposalsConversationIdDataVoidCalled: Bool {
        return commitPendingProposalsConversationIdDataVoidCallsCount > 0
    }
    public var commitPendingProposalsConversationIdDataVoidReceivedConversationId: (Data)?
    public var commitPendingProposalsConversationIdDataVoidReceivedInvocations: [(Data)] = []
    public var commitPendingProposalsConversationIdDataVoidClosure: ((Data) async throws -> Void)?

    public func commitPendingProposals(conversationId: Data) async throws {
        commitPendingProposalsConversationIdDataVoidCallsCount += 1
        commitPendingProposalsConversationIdDataVoidReceivedConversationId = conversationId
        commitPendingProposalsConversationIdDataVoidReceivedInvocations.append(conversationId)
        if let error = commitPendingProposalsConversationIdDataVoidThrowableError {
            throw error
        }
        try await commitPendingProposalsConversationIdDataVoidClosure?(conversationId)
    }

    //MARK: - conversationCiphersuite

    public var conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteThrowableError: (any Error)?
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteCallsCount = 0
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteCalled: Bool {
        return conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteCallsCount > 0
    }
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteReceivedConversationId: (Data)?
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteReceivedInvocations: [(Data)] = []
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteReturnValue: WireCoreCryptoUniffi.Ciphersuite!
    public var conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteClosure: ((Data) async throws -> WireCoreCryptoUniffi.Ciphersuite)?

    public func conversationCiphersuite(conversationId: Data) async throws -> WireCoreCryptoUniffi.Ciphersuite {
        conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteCallsCount += 1
        conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteReceivedConversationId = conversationId
        conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteReceivedInvocations.append(conversationId)
        if let error = conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteThrowableError {
            throw error
        }
        if let conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteClosure = conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteClosure {
            return try await conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteClosure(conversationId)
        } else {
            return conversationCiphersuiteConversationIdDataWireCoreCryptoUniffiCiphersuiteReturnValue
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

    public var conversationExistsConversationIdDataBoolThrowableError: (any Error)?
    public var conversationExistsConversationIdDataBoolCallsCount = 0
    public var conversationExistsConversationIdDataBoolCalled: Bool {
        return conversationExistsConversationIdDataBoolCallsCount > 0
    }
    public var conversationExistsConversationIdDataBoolReceivedConversationId: (Data)?
    public var conversationExistsConversationIdDataBoolReceivedInvocations: [(Data)] = []
    public var conversationExistsConversationIdDataBoolReturnValue: Bool!
    public var conversationExistsConversationIdDataBoolClosure: ((Data) async throws -> Bool)?

    public func conversationExists(conversationId: Data) async throws -> Bool {
        conversationExistsConversationIdDataBoolCallsCount += 1
        conversationExistsConversationIdDataBoolReceivedConversationId = conversationId
        conversationExistsConversationIdDataBoolReceivedInvocations.append(conversationId)
        if let error = conversationExistsConversationIdDataBoolThrowableError {
            throw error
        }
        if let conversationExistsConversationIdDataBoolClosure = conversationExistsConversationIdDataBoolClosure {
            return try await conversationExistsConversationIdDataBoolClosure(conversationId)
        } else {
            return conversationExistsConversationIdDataBoolReturnValue
        }
    }

    //MARK: - createConversation

    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidThrowableError: (any Error)?
    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidCallsCount = 0
    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidCalled: Bool {
        return createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidCallsCount > 0
    }
    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidReceivedArguments: (conversationId: Data, creatorCredentialType: WireCoreCryptoUniffi.CredentialType, config: WireCoreCryptoUniffi.ConversationConfiguration)?
    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidReceivedInvocations: [(conversationId: Data, creatorCredentialType: WireCoreCryptoUniffi.CredentialType, config: WireCoreCryptoUniffi.ConversationConfiguration)] = []
    public var createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidClosure: ((Data, WireCoreCryptoUniffi.CredentialType, WireCoreCryptoUniffi.ConversationConfiguration) async throws -> Void)?

    public func createConversation(conversationId: Data, creatorCredentialType: WireCoreCryptoUniffi.CredentialType, config: WireCoreCryptoUniffi.ConversationConfiguration) async throws {
        createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidCallsCount += 1
        createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidReceivedArguments = (conversationId: conversationId, creatorCredentialType: creatorCredentialType, config: config)
        createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidReceivedInvocations.append((conversationId: conversationId, creatorCredentialType: creatorCredentialType, config: config))
        if let error = createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidThrowableError {
            throw error
        }
        try await createConversationConversationIdDataCreatorCredentialTypeWireCoreCryptoUniffiCredentialTypeConfigWireCoreCryptoUniffiConversationConfigurationVoidClosure?(conversationId, creatorCredentialType, config)
    }

    //MARK: - decryptMessage

    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageThrowableError: (any Error)?
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageCallsCount = 0
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageCalled: Bool {
        return decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageCallsCount > 0
    }
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageReceivedArguments: (conversationId: Data, payload: Data)?
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageReceivedInvocations: [(conversationId: Data, payload: Data)] = []
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageReturnValue: WireCoreCryptoUniffi.DecryptedMessage!
    public var decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageClosure: ((Data, Data) async throws -> WireCoreCryptoUniffi.DecryptedMessage)?

    public func decryptMessage(conversationId: Data, payload: Data) async throws -> WireCoreCryptoUniffi.DecryptedMessage {
        decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageCallsCount += 1
        decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageReceivedArguments = (conversationId: conversationId, payload: payload)
        decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageReceivedInvocations.append((conversationId: conversationId, payload: payload))
        if let error = decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageThrowableError {
            throw error
        }
        if let decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageClosure = decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageClosure {
            return try await decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageClosure(conversationId, payload)
        } else {
            return decryptMessageConversationIdDataPayloadDataWireCoreCryptoUniffiDecryptedMessageReturnValue
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

    //MARK: - deleteStaleKeyPackages

    public var deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidThrowableError: (any Error)?
    public var deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidCallsCount = 0
    public var deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidCalled: Bool {
        return deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidCallsCount > 0
    }
    public var deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidReceivedCiphersuite: (WireCoreCryptoUniffi.Ciphersuite)?
    public var deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidReceivedInvocations: [(WireCoreCryptoUniffi.Ciphersuite)] = []
    public var deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidClosure: ((WireCoreCryptoUniffi.Ciphersuite) async throws -> Void)?

    public func deleteStaleKeyPackages(ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws {
        deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidCallsCount += 1
        deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidReceivedCiphersuite = ciphersuite
        deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidReceivedInvocations.append(ciphersuite)
        if let error = deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidThrowableError {
            throw error
        }
        try await deleteStaleKeyPackagesCiphersuiteWireCoreCryptoUniffiCiphersuiteVoidClosure?(ciphersuite)
    }

    //MARK: - e2eiConversationState

    public var e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateThrowableError: (any Error)?
    public var e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateCallsCount = 0
    public var e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateCalled: Bool {
        return e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateCallsCount > 0
    }
    public var e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateReceivedConversationId: (Data)?
    public var e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateReceivedInvocations: [(Data)] = []
    public var e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateReturnValue: WireCoreCryptoUniffi.E2eiConversationState!
    public var e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateClosure: ((Data) async throws -> WireCoreCryptoUniffi.E2eiConversationState)?

    public func e2eiConversationState(conversationId: Data) async throws -> WireCoreCryptoUniffi.E2eiConversationState {
        e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateCallsCount += 1
        e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateReceivedConversationId = conversationId
        e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateReceivedInvocations.append(conversationId)
        if let error = e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateThrowableError {
            throw error
        }
        if let e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateClosure = e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateClosure {
            return try await e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateClosure(conversationId)
        } else {
            return e2eiConversationStateConversationIdDataWireCoreCryptoUniffiE2eiConversationStateReturnValue
        }
    }

    //MARK: - e2eiDumpPkiEnv

    public var e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvThrowableError: (any Error)?
    public var e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvCallsCount = 0
    public var e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvCalled: Bool {
        return e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvCallsCount > 0
    }
    public var e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvReturnValue: WireCoreCryptoUniffi.E2eiDumpedPkiEnv?
    public var e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvClosure: (() async throws -> WireCoreCryptoUniffi.E2eiDumpedPkiEnv?)?

    public func e2eiDumpPkiEnv() async throws -> WireCoreCryptoUniffi.E2eiDumpedPkiEnv? {
        e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvCallsCount += 1
        if let error = e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvThrowableError {
            throw error
        }
        if let e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvClosure = e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvClosure {
            return try await e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvClosure()
        } else {
            return e2eiDumpPkiEnvWireCoreCryptoUniffiE2eiDumpedPkiEnvReturnValue
        }
    }

    //MARK: - e2eiEnrollmentStash

    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataThrowableError: (any Error)?
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataCallsCount = 0
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataCalled: Bool {
        return e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataCallsCount > 0
    }
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataReceivedEnrollment: (WireCoreCryptoUniffi.E2eiEnrollment)?
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataReceivedInvocations: [(WireCoreCryptoUniffi.E2eiEnrollment)] = []
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataReturnValue: Data!
    public var e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataClosure: ((WireCoreCryptoUniffi.E2eiEnrollment) async throws -> Data)?

    public func e2eiEnrollmentStash(enrollment: WireCoreCryptoUniffi.E2eiEnrollment) async throws -> Data {
        e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataCallsCount += 1
        e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataReceivedEnrollment = enrollment
        e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataReceivedInvocations.append(enrollment)
        if let error = e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataThrowableError {
            throw error
        }
        if let e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataClosure = e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataClosure {
            return try await e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataClosure(enrollment)
        } else {
            return e2eiEnrollmentStashEnrollmentWireCoreCryptoUniffiE2eiEnrollmentDataReturnValue
        }
    }

    //MARK: - e2eiEnrollmentStashPop

    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentThrowableError: (any Error)?
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentCallsCount = 0
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentCalled: Bool {
        return e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentCallsCount > 0
    }
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentReceivedHandle: (Data)?
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentReceivedInvocations: [(Data)] = []
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentReturnValue: WireCoreCryptoUniffi.E2eiEnrollment!
    public var e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentClosure: ((Data) async throws -> WireCoreCryptoUniffi.E2eiEnrollment)?

    public func e2eiEnrollmentStashPop(handle: Data) async throws -> WireCoreCryptoUniffi.E2eiEnrollment {
        e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentCallsCount += 1
        e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentReceivedHandle = handle
        e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentReceivedInvocations.append(handle)
        if let error = e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentThrowableError {
            throw error
        }
        if let e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentClosure = e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentClosure {
            return try await e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentClosure(handle)
        } else {
            return e2eiEnrollmentStashPopHandleDataWireCoreCryptoUniffiE2eiEnrollmentReturnValue
        }
    }

    //MARK: - e2eiIsEnabled

    public var e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolThrowableError: (any Error)?
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolCallsCount = 0
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolCalled: Bool {
        return e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolCallsCount > 0
    }
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolReceivedCiphersuite: (WireCoreCryptoUniffi.Ciphersuite)?
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolReceivedInvocations: [(WireCoreCryptoUniffi.Ciphersuite)] = []
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolReturnValue: Bool!
    public var e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolClosure: ((WireCoreCryptoUniffi.Ciphersuite) async throws -> Bool)?

    public func e2eiIsEnabled(ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws -> Bool {
        e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolCallsCount += 1
        e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolReceivedCiphersuite = ciphersuite
        e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolReceivedInvocations.append(ciphersuite)
        if let error = e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolThrowableError {
            throw error
        }
        if let e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolClosure = e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolClosure {
            return try await e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolClosure(ciphersuite)
        } else {
            return e2eiIsEnabledCiphersuiteWireCoreCryptoUniffiCiphersuiteBoolReturnValue
        }
    }

    //MARK: - e2eiIsPkiEnvSetup

    public var e2eiIsPkiEnvSetupBoolThrowableError: (any Error)?
    public var e2eiIsPkiEnvSetupBoolCallsCount = 0
    public var e2eiIsPkiEnvSetupBoolCalled: Bool {
        return e2eiIsPkiEnvSetupBoolCallsCount > 0
    }
    public var e2eiIsPkiEnvSetupBoolReturnValue: Bool!
    public var e2eiIsPkiEnvSetupBoolClosure: (() async throws -> Bool)?

    public func e2eiIsPkiEnvSetup() async throws -> Bool {
        e2eiIsPkiEnvSetupBoolCallsCount += 1
        if let error = e2eiIsPkiEnvSetupBoolThrowableError {
            throw error
        }
        if let e2eiIsPkiEnvSetupBoolClosure = e2eiIsPkiEnvSetupBoolClosure {
            return try await e2eiIsPkiEnvSetupBoolClosure()
        } else {
            return e2eiIsPkiEnvSetupBoolReturnValue
        }
    }

    //MARK: - e2eiMlsInitOnly

    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsThrowableError: (any Error)?
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsCallsCount = 0
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsCalled: Bool {
        return e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsCallsCount > 0
    }
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsReceivedArguments: (enrollment: WireCoreCryptoUniffi.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?)?
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsReceivedInvocations: [(enrollment: WireCoreCryptoUniffi.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?)] = []
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsReturnValue: WireCoreCryptoUniffi.NewCrlDistributionPoints!
    public var e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsClosure: ((WireCoreCryptoUniffi.E2eiEnrollment, String, UInt32?) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints)?

    public func e2eiMlsInitOnly(enrollment: WireCoreCryptoUniffi.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints {
        e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsCallsCount += 1
        e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsReceivedArguments = (enrollment: enrollment, certificateChain: certificateChain, nbKeyPackage: nbKeyPackage)
        e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsReceivedInvocations.append((enrollment: enrollment, certificateChain: certificateChain, nbKeyPackage: nbKeyPackage))
        if let error = e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsThrowableError {
            throw error
        }
        if let e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsClosure = e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsClosure {
            return try await e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsClosure(enrollment, certificateChain, nbKeyPackage)
        } else {
            return e2eiMlsInitOnlyEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringNbKeyPackageUInt32WireCoreCryptoUniffiNewCrlDistributionPointsReturnValue
        }
    }

    //MARK: - e2eiNewActivationEnrollment

    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentThrowableError: (any Error)?
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCallsCount = 0
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCalled: Bool {
        return e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCallsCount > 0
    }
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedArguments: (displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite)?
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedInvocations: [(displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite)] = []
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReturnValue: WireCoreCryptoUniffi.E2eiEnrollment!
    public var e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure: ((String, String, String?, UInt32, WireCoreCryptoUniffi.Ciphersuite) async throws -> WireCoreCryptoUniffi.E2eiEnrollment)?

    public func e2eiNewActivationEnrollment(displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws -> WireCoreCryptoUniffi.E2eiEnrollment {
        e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCallsCount += 1
        e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedArguments = (displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite)
        e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedInvocations.append((displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite))
        if let error = e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentThrowableError {
            throw error
        }
        if let e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure = e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure {
            return try await e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure(displayName, handle, team, expirySec, ciphersuite)
        } else {
            return e2eiNewActivationEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReturnValue
        }
    }

    //MARK: - e2eiNewEnrollment

    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentThrowableError: (any Error)?
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCallsCount = 0
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCalled: Bool {
        return e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCallsCount > 0
    }
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedArguments: (clientId: String, displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite)?
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedInvocations: [(clientId: String, displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite)] = []
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReturnValue: WireCoreCryptoUniffi.E2eiEnrollment!
    public var e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure: ((String, String, String, String?, UInt32, WireCoreCryptoUniffi.Ciphersuite) async throws -> WireCoreCryptoUniffi.E2eiEnrollment)?

    public func e2eiNewEnrollment(clientId: String, displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws -> WireCoreCryptoUniffi.E2eiEnrollment {
        e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCallsCount += 1
        e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedArguments = (clientId: clientId, displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite)
        e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedInvocations.append((clientId: clientId, displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite))
        if let error = e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentThrowableError {
            throw error
        }
        if let e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure = e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure {
            return try await e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure(clientId, displayName, handle, team, expirySec, ciphersuite)
        } else {
            return e2eiNewEnrollmentClientIdStringDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReturnValue
        }
    }

    //MARK: - e2eiNewRotateEnrollment

    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentThrowableError: (any Error)?
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCallsCount = 0
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCalled: Bool {
        return e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCallsCount > 0
    }
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedArguments: (displayName: String?, handle: String?, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite)?
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedInvocations: [(displayName: String?, handle: String?, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite)] = []
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReturnValue: WireCoreCryptoUniffi.E2eiEnrollment!
    public var e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure: ((String?, String?, String?, UInt32, WireCoreCryptoUniffi.Ciphersuite) async throws -> WireCoreCryptoUniffi.E2eiEnrollment)?

    public func e2eiNewRotateEnrollment(displayName: String?, handle: String?, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws -> WireCoreCryptoUniffi.E2eiEnrollment {
        e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentCallsCount += 1
        e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedArguments = (displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite)
        e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReceivedInvocations.append((displayName: displayName, handle: handle, team: team, expirySec: expirySec, ciphersuite: ciphersuite))
        if let error = e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentThrowableError {
            throw error
        }
        if let e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure = e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure {
            return try await e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentClosure(displayName, handle, team, expirySec, ciphersuite)
        } else {
            return e2eiNewRotateEnrollmentDisplayNameStringHandleStringTeamStringExpirySecUInt32CiphersuiteWireCoreCryptoUniffiCiphersuiteWireCoreCryptoUniffiE2eiEnrollmentReturnValue
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

    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationThrowableError: (any Error)?
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationCallsCount = 0
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationCalled: Bool {
        return e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationCallsCount > 0
    }
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationReceivedArguments: (crlDp: String, crlDer: Data)?
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationReceivedInvocations: [(crlDp: String, crlDer: Data)] = []
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationReturnValue: WireCoreCryptoUniffi.CrlRegistration!
    public var e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationClosure: ((String, Data) async throws -> WireCoreCryptoUniffi.CrlRegistration)?

    public func e2eiRegisterCrl(crlDp: String, crlDer: Data) async throws -> WireCoreCryptoUniffi.CrlRegistration {
        e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationCallsCount += 1
        e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationReceivedArguments = (crlDp: crlDp, crlDer: crlDer)
        e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationReceivedInvocations.append((crlDp: crlDp, crlDer: crlDer))
        if let error = e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationThrowableError {
            throw error
        }
        if let e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationClosure = e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationClosure {
            return try await e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationClosure(crlDp, crlDer)
        } else {
            return e2eiRegisterCrlCrlDpStringCrlDerDataWireCoreCryptoUniffiCrlRegistrationReturnValue
        }
    }

    //MARK: - e2eiRegisterIntermediateCa

    public var e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsThrowableError: (any Error)?
    public var e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsCallsCount = 0
    public var e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsCalled: Bool {
        return e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsCallsCount > 0
    }
    public var e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsReceivedCertPem: (String)?
    public var e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsReceivedInvocations: [(String)] = []
    public var e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsReturnValue: WireCoreCryptoUniffi.NewCrlDistributionPoints!
    public var e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsClosure: ((String) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints)?

    public func e2eiRegisterIntermediateCa(certPem: String) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints {
        e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsCallsCount += 1
        e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsReceivedCertPem = certPem
        e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsReceivedInvocations.append(certPem)
        if let error = e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsThrowableError {
            throw error
        }
        if let e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsClosure = e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsClosure {
            return try await e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsClosure(certPem)
        } else {
            return e2eiRegisterIntermediateCaCertPemStringWireCoreCryptoUniffiNewCrlDistributionPointsReturnValue
        }
    }

    //MARK: - e2eiRotate

    public var e2eiRotateConversationIdDataVoidThrowableError: (any Error)?
    public var e2eiRotateConversationIdDataVoidCallsCount = 0
    public var e2eiRotateConversationIdDataVoidCalled: Bool {
        return e2eiRotateConversationIdDataVoidCallsCount > 0
    }
    public var e2eiRotateConversationIdDataVoidReceivedConversationId: (Data)?
    public var e2eiRotateConversationIdDataVoidReceivedInvocations: [(Data)] = []
    public var e2eiRotateConversationIdDataVoidClosure: ((Data) async throws -> Void)?

    public func e2eiRotate(conversationId: Data) async throws {
        e2eiRotateConversationIdDataVoidCallsCount += 1
        e2eiRotateConversationIdDataVoidReceivedConversationId = conversationId
        e2eiRotateConversationIdDataVoidReceivedInvocations.append(conversationId)
        if let error = e2eiRotateConversationIdDataVoidThrowableError {
            throw error
        }
        try await e2eiRotateConversationIdDataVoidClosure?(conversationId)
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

    public var getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdThrowableError: (any Error)?
    public var getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdCallsCount = 0
    public var getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdCalled: Bool {
        return getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdCallsCount > 0
    }
    public var getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdReceivedConversationId: (Data)?
    public var getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdReceivedInvocations: [(Data)] = []
    public var getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdReturnValue: [WireCoreCryptoUniffi.ClientId]!
    public var getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdClosure: ((Data) async throws -> [WireCoreCryptoUniffi.ClientId])?

    public func getClientIds(conversationId: Data) async throws -> [WireCoreCryptoUniffi.ClientId] {
        getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdCallsCount += 1
        getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdReceivedConversationId = conversationId
        getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdReceivedInvocations.append(conversationId)
        if let error = getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdThrowableError {
            throw error
        }
        if let getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdClosure = getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdClosure {
            return try await getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdClosure(conversationId)
        } else {
            return getClientIdsConversationIdDataWireCoreCryptoUniffiClientIdReturnValue
        }
    }

    //MARK: - getCredentialInUse

    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateThrowableError: (any Error)?
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateCallsCount = 0
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateCalled: Bool {
        return getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateCallsCount > 0
    }
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateReceivedArguments: (groupInfo: Data, credentialType: WireCoreCryptoUniffi.CredentialType)?
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateReceivedInvocations: [(groupInfo: Data, credentialType: WireCoreCryptoUniffi.CredentialType)] = []
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateReturnValue: WireCoreCryptoUniffi.E2eiConversationState!
    public var getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateClosure: ((Data, WireCoreCryptoUniffi.CredentialType) async throws -> WireCoreCryptoUniffi.E2eiConversationState)?

    public func getCredentialInUse(groupInfo: Data, credentialType: WireCoreCryptoUniffi.CredentialType) async throws -> WireCoreCryptoUniffi.E2eiConversationState {
        getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateCallsCount += 1
        getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateReceivedArguments = (groupInfo: groupInfo, credentialType: credentialType)
        getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateReceivedInvocations.append((groupInfo: groupInfo, credentialType: credentialType))
        if let error = getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateThrowableError {
            throw error
        }
        if let getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateClosure = getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateClosure {
            return try await getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateClosure(groupInfo, credentialType)
        } else {
            return getCredentialInUseGroupInfoDataCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiE2eiConversationStateReturnValue
        }
    }

    //MARK: - getData

    public var getDataDataThrowableError: (any Error)?
    public var getDataDataCallsCount = 0
    public var getDataDataCalled: Bool {
        return getDataDataCallsCount > 0
    }
    public var getDataDataReturnValue: Data?
    public var getDataDataClosure: (() async throws -> Data?)?

    public func getData() async throws -> Data? {
        getDataDataCallsCount += 1
        if let error = getDataDataThrowableError {
            throw error
        }
        if let getDataDataClosure = getDataDataClosure {
            return try await getDataDataClosure()
        } else {
            return getDataDataReturnValue
        }
    }

    //MARK: - getDeviceIdentities

    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityThrowableError: (any Error)?
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityCallsCount = 0
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityCalled: Bool {
        return getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityCallsCount > 0
    }
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityReceivedArguments: (conversationId: Data, deviceIds: [WireCoreCryptoUniffi.ClientId])?
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityReceivedInvocations: [(conversationId: Data, deviceIds: [WireCoreCryptoUniffi.ClientId])] = []
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityReturnValue: [WireCoreCryptoUniffi.WireIdentity]!
    public var getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityClosure: ((Data, [WireCoreCryptoUniffi.ClientId]) async throws -> [WireCoreCryptoUniffi.WireIdentity])?

    public func getDeviceIdentities(conversationId: Data, deviceIds: [WireCoreCryptoUniffi.ClientId]) async throws -> [WireCoreCryptoUniffi.WireIdentity] {
        getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityCallsCount += 1
        getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityReceivedArguments = (conversationId: conversationId, deviceIds: deviceIds)
        getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityReceivedInvocations.append((conversationId: conversationId, deviceIds: deviceIds))
        if let error = getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityThrowableError {
            throw error
        }
        if let getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityClosure = getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityClosure {
            return try await getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityClosure(conversationId, deviceIds)
        } else {
            return getDeviceIdentitiesConversationIdDataDeviceIdsWireCoreCryptoUniffiClientIdWireCoreCryptoUniffiWireIdentityReturnValue
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

    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityThrowableError: (any Error)?
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityCallsCount = 0
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityCalled: Bool {
        return getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityCallsCount > 0
    }
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityReceivedArguments: (conversationId: Data, userIds: [String])?
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityReceivedInvocations: [(conversationId: Data, userIds: [String])] = []
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityReturnValue: [String: [WireCoreCryptoUniffi.WireIdentity]]!
    public var getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityClosure: ((Data, [String]) async throws -> [String: [WireCoreCryptoUniffi.WireIdentity]])?

    public func getUserIdentities(conversationId: Data, userIds: [String]) async throws -> [String: [WireCoreCryptoUniffi.WireIdentity]] {
        getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityCallsCount += 1
        getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityReceivedArguments = (conversationId: conversationId, userIds: userIds)
        getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityReceivedInvocations.append((conversationId: conversationId, userIds: userIds))
        if let error = getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityThrowableError {
            throw error
        }
        if let getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityClosure = getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityClosure {
            return try await getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityClosure(conversationId, userIds)
        } else {
            return getUserIdentitiesConversationIdDataUserIdsStringStringWireCoreCryptoUniffiWireIdentityReturnValue
        }
    }

    //MARK: - joinByExternalCommit

    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleThrowableError: (any Error)?
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleCallsCount = 0
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleCalled: Bool {
        return joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleCallsCount > 0
    }
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleReceivedArguments: (groupInfo: Data, customConfiguration: WireCoreCryptoUniffi.CustomConfiguration, credentialType: WireCoreCryptoUniffi.CredentialType)?
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleReceivedInvocations: [(groupInfo: Data, customConfiguration: WireCoreCryptoUniffi.CustomConfiguration, credentialType: WireCoreCryptoUniffi.CredentialType)] = []
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleReturnValue: WireCoreCryptoUniffi.WelcomeBundle!
    public var joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleClosure: ((Data, WireCoreCryptoUniffi.CustomConfiguration, WireCoreCryptoUniffi.CredentialType) async throws -> WireCoreCryptoUniffi.WelcomeBundle)?

    public func joinByExternalCommit(groupInfo: Data, customConfiguration: WireCoreCryptoUniffi.CustomConfiguration, credentialType: WireCoreCryptoUniffi.CredentialType) async throws -> WireCoreCryptoUniffi.WelcomeBundle {
        joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleCallsCount += 1
        joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleReceivedArguments = (groupInfo: groupInfo, customConfiguration: customConfiguration, credentialType: credentialType)
        joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleReceivedInvocations.append((groupInfo: groupInfo, customConfiguration: customConfiguration, credentialType: credentialType))
        if let error = joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleThrowableError {
            throw error
        }
        if let joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleClosure = joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleClosure {
            return try await joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleClosure(groupInfo, customConfiguration, credentialType)
        } else {
            return joinByExternalCommitGroupInfoDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationCredentialTypeWireCoreCryptoUniffiCredentialTypeWireCoreCryptoUniffiWelcomeBundleReturnValue
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

    //MARK: - mlsGenerateKeypairs

    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdThrowableError: (any Error)?
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdCallsCount = 0
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdCalled: Bool {
        return mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdCallsCount > 0
    }
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdReceivedCiphersuites: (WireCoreCryptoUniffi.Ciphersuites)?
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdReceivedInvocations: [(WireCoreCryptoUniffi.Ciphersuites)] = []
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdReturnValue: [WireCoreCryptoUniffi.ClientId]!
    public var mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdClosure: ((WireCoreCryptoUniffi.Ciphersuites) async throws -> [WireCoreCryptoUniffi.ClientId])?

    public func mlsGenerateKeypairs(ciphersuites: WireCoreCryptoUniffi.Ciphersuites) async throws -> [WireCoreCryptoUniffi.ClientId] {
        mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdCallsCount += 1
        mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdReceivedCiphersuites = ciphersuites
        mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdReceivedInvocations.append(ciphersuites)
        if let error = mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdThrowableError {
            throw error
        }
        if let mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdClosure = mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdClosure {
            return try await mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdClosure(ciphersuites)
        } else {
            return mlsGenerateKeypairsCiphersuitesWireCoreCryptoUniffiCiphersuitesWireCoreCryptoUniffiClientIdReturnValue
        }
    }

    //MARK: - mlsInit

    public var mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidThrowableError: (any Error)?
    public var mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidCallsCount = 0
    public var mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidCalled: Bool {
        return mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidCallsCount > 0
    }
    public var mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidReceivedArguments: (clientId: WireCoreCryptoUniffi.ClientId, ciphersuites: WireCoreCryptoUniffi.Ciphersuites, nbKeyPackage: UInt32?)?
    public var mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidReceivedInvocations: [(clientId: WireCoreCryptoUniffi.ClientId, ciphersuites: WireCoreCryptoUniffi.Ciphersuites, nbKeyPackage: UInt32?)] = []
    public var mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidClosure: ((WireCoreCryptoUniffi.ClientId, WireCoreCryptoUniffi.Ciphersuites, UInt32?) async throws -> Void)?

    public func mlsInit(clientId: WireCoreCryptoUniffi.ClientId, ciphersuites: WireCoreCryptoUniffi.Ciphersuites, nbKeyPackage: UInt32?) async throws {
        mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidCallsCount += 1
        mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidReceivedArguments = (clientId: clientId, ciphersuites: ciphersuites, nbKeyPackage: nbKeyPackage)
        mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidReceivedInvocations.append((clientId: clientId, ciphersuites: ciphersuites, nbKeyPackage: nbKeyPackage))
        if let error = mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidThrowableError {
            throw error
        }
        try await mlsInitClientIdWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesNbKeyPackageUInt32VoidClosure?(clientId, ciphersuites, nbKeyPackage)
    }

    //MARK: - mlsInitWithClientId

    public var mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidThrowableError: (any Error)?
    public var mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidCallsCount = 0
    public var mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidCalled: Bool {
        return mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidCallsCount > 0
    }
    public var mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidReceivedArguments: (clientId: WireCoreCryptoUniffi.ClientId, tmpClientIds: [WireCoreCryptoUniffi.ClientId], ciphersuites: WireCoreCryptoUniffi.Ciphersuites)?
    public var mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidReceivedInvocations: [(clientId: WireCoreCryptoUniffi.ClientId, tmpClientIds: [WireCoreCryptoUniffi.ClientId], ciphersuites: WireCoreCryptoUniffi.Ciphersuites)] = []
    public var mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidClosure: ((WireCoreCryptoUniffi.ClientId, [WireCoreCryptoUniffi.ClientId], WireCoreCryptoUniffi.Ciphersuites) async throws -> Void)?

    public func mlsInitWithClientId(clientId: WireCoreCryptoUniffi.ClientId, tmpClientIds: [WireCoreCryptoUniffi.ClientId], ciphersuites: WireCoreCryptoUniffi.Ciphersuites) async throws {
        mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidCallsCount += 1
        mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidReceivedArguments = (clientId: clientId, tmpClientIds: tmpClientIds, ciphersuites: ciphersuites)
        mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidReceivedInvocations.append((clientId: clientId, tmpClientIds: tmpClientIds, ciphersuites: ciphersuites))
        if let error = mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidThrowableError {
            throw error
        }
        try await mlsInitWithClientIdClientIdWireCoreCryptoUniffiClientIdTmpClientIdsWireCoreCryptoUniffiClientIdCiphersuitesWireCoreCryptoUniffiCiphersuitesVoidClosure?(clientId, tmpClientIds, ciphersuites)
    }

    //MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleThrowableError: (any Error)?
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleCallsCount = 0
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleCalled: Bool {
        return processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleCallsCount > 0
    }
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleReceivedArguments: (welcomeMessage: Data, customConfiguration: WireCoreCryptoUniffi.CustomConfiguration)?
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleReceivedInvocations: [(welcomeMessage: Data, customConfiguration: WireCoreCryptoUniffi.CustomConfiguration)] = []
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleReturnValue: WireCoreCryptoUniffi.WelcomeBundle!
    public var processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleClosure: ((Data, WireCoreCryptoUniffi.CustomConfiguration) async throws -> WireCoreCryptoUniffi.WelcomeBundle)?

    public func processWelcomeMessage(welcomeMessage: Data, customConfiguration: WireCoreCryptoUniffi.CustomConfiguration) async throws -> WireCoreCryptoUniffi.WelcomeBundle {
        processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleCallsCount += 1
        processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleReceivedArguments = (welcomeMessage: welcomeMessage, customConfiguration: customConfiguration)
        processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleReceivedInvocations.append((welcomeMessage: welcomeMessage, customConfiguration: customConfiguration))
        if let error = processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleThrowableError {
            throw error
        }
        if let processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleClosure = processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleClosure {
            return try await processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleClosure(welcomeMessage, customConfiguration)
        } else {
            return processWelcomeMessageWelcomeMessageDataCustomConfigurationWireCoreCryptoUniffiCustomConfigurationWireCoreCryptoUniffiWelcomeBundleReturnValue
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

    public var proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleThrowableError: (any Error)?
    public var proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleCallsCount = 0
    public var proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleCalled: Bool {
        return proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleCallsCount > 0
    }
    public var proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleReturnValue: WireCoreCryptoUniffi.ProteusAutoPrekeyBundle!
    public var proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleClosure: (() async throws -> WireCoreCryptoUniffi.ProteusAutoPrekeyBundle)?

    public func proteusNewPrekeyAuto() async throws -> WireCoreCryptoUniffi.ProteusAutoPrekeyBundle {
        proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleCallsCount += 1
        if let error = proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleThrowableError {
            throw error
        }
        if let proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleClosure = proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleClosure {
            return try await proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleClosure()
        } else {
            return proteusNewPrekeyAutoWireCoreCryptoUniffiProteusAutoPrekeyBundleReturnValue
        }
    }

    //MARK: - proteusReloadSessions

    public var proteusReloadSessionsVoidThrowableError: (any Error)?
    public var proteusReloadSessionsVoidCallsCount = 0
    public var proteusReloadSessionsVoidCalled: Bool {
        return proteusReloadSessionsVoidCallsCount > 0
    }
    public var proteusReloadSessionsVoidClosure: (() async throws -> Void)?

    public func proteusReloadSessions() async throws {
        proteusReloadSessionsVoidCallsCount += 1
        if let error = proteusReloadSessionsVoidThrowableError {
            throw error
        }
        try await proteusReloadSessionsVoidClosure?()
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

    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidThrowableError: (any Error)?
    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidCallsCount = 0
    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidCalled: Bool {
        return removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidCallsCount > 0
    }
    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidReceivedArguments: (conversationId: Data, clients: [WireCoreCryptoUniffi.ClientId])?
    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidReceivedInvocations: [(conversationId: Data, clients: [WireCoreCryptoUniffi.ClientId])] = []
    public var removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidClosure: ((Data, [WireCoreCryptoUniffi.ClientId]) async throws -> Void)?

    public func removeClientsFromConversation(conversationId: Data, clients: [WireCoreCryptoUniffi.ClientId]) async throws {
        removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidCallsCount += 1
        removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidReceivedArguments = (conversationId: conversationId, clients: clients)
        removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidReceivedInvocations.append((conversationId: conversationId, clients: clients))
        if let error = removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidThrowableError {
            throw error
        }
        try await removeClientsFromConversationConversationIdDataClientsWireCoreCryptoUniffiClientIdVoidClosure?(conversationId, clients)
    }

    //MARK: - saveX509Credential

    public var saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsThrowableError: (any Error)?
    public var saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsCallsCount = 0
    public var saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsCalled: Bool {
        return saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsCallsCount > 0
    }
    public var saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsReceivedArguments: (enrollment: WireCoreCryptoUniffi.E2eiEnrollment, certificateChain: String)?
    public var saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsReceivedInvocations: [(enrollment: WireCoreCryptoUniffi.E2eiEnrollment, certificateChain: String)] = []
    public var saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsReturnValue: WireCoreCryptoUniffi.NewCrlDistributionPoints!
    public var saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsClosure: ((WireCoreCryptoUniffi.E2eiEnrollment, String) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints)?

    public func saveX509Credential(enrollment: WireCoreCryptoUniffi.E2eiEnrollment, certificateChain: String) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints {
        saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsCallsCount += 1
        saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsReceivedArguments = (enrollment: enrollment, certificateChain: certificateChain)
        saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsReceivedInvocations.append((enrollment: enrollment, certificateChain: certificateChain))
        if let error = saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsThrowableError {
            throw error
        }
        if let saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsClosure = saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsClosure {
            return try await saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsClosure(enrollment, certificateChain)
        } else {
            return saveX509CredentialEnrollmentWireCoreCryptoUniffiE2eiEnrollmentCertificateChainStringWireCoreCryptoUniffiNewCrlDistributionPointsReturnValue
        }
    }

    //MARK: - setData

    public var setDataDataDataVoidThrowableError: (any Error)?
    public var setDataDataDataVoidCallsCount = 0
    public var setDataDataDataVoidCalled: Bool {
        return setDataDataDataVoidCallsCount > 0
    }
    public var setDataDataDataVoidReceivedData: (Data)?
    public var setDataDataDataVoidReceivedInvocations: [(Data)] = []
    public var setDataDataDataVoidClosure: ((Data) async throws -> Void)?

    public func setData(data: Data) async throws {
        setDataDataDataVoidCallsCount += 1
        setDataDataDataVoidReceivedData = data
        setDataDataDataVoidReceivedInvocations.append(data)
        if let error = setDataDataDataVoidThrowableError {
            throw error
        }
        try await setDataDataDataVoidClosure?(data)
    }

    //MARK: - updateKeyingMaterial

    public var updateKeyingMaterialConversationIdDataVoidThrowableError: (any Error)?
    public var updateKeyingMaterialConversationIdDataVoidCallsCount = 0
    public var updateKeyingMaterialConversationIdDataVoidCalled: Bool {
        return updateKeyingMaterialConversationIdDataVoidCallsCount > 0
    }
    public var updateKeyingMaterialConversationIdDataVoidReceivedConversationId: (Data)?
    public var updateKeyingMaterialConversationIdDataVoidReceivedInvocations: [(Data)] = []
    public var updateKeyingMaterialConversationIdDataVoidClosure: ((Data) async throws -> Void)?

    public func updateKeyingMaterial(conversationId: Data) async throws {
        updateKeyingMaterialConversationIdDataVoidCallsCount += 1
        updateKeyingMaterialConversationIdDataVoidReceivedConversationId = conversationId
        updateKeyingMaterialConversationIdDataVoidReceivedInvocations.append(conversationId)
        if let error = updateKeyingMaterialConversationIdDataVoidThrowableError {
            throw error
        }
        try await updateKeyingMaterialConversationIdDataVoidClosure?(conversationId)
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
public class CoreCryptoKeyMigrationManagerProtocolMock: CoreCryptoKeyMigrationManagerProtocol {

    public init() {}

    public var isMigrationNeeded: Bool {
        get { return underlyingIsMigrationNeeded }
        set(value) { underlyingIsMigrationNeeded = value }
    }
    public var underlyingIsMigrationNeeded: (Bool)!


    //MARK: - performMigrationIfNeeded

    public var performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidThrowableError: (any Error)?
    public var performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidCallsCount = 0
    public var performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidCalled: Bool {
        return performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidCallsCount > 0
    }
    public var performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidReceivedArguments: (path: String, oldKey: String, newKey: Data)?
    public var performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidReceivedInvocations: [(path: String, oldKey: String, newKey: Data)] = []
    public var performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidClosure: ((String, String, Data) async throws -> Void)?

    public func performMigrationIfNeeded(path: String, oldKey: String, newKey: Data) async throws {
        performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidCallsCount += 1
        performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidReceivedArguments = (path: path, oldKey: oldKey, newKey: newKey)
        performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidReceivedInvocations.append((path: path, oldKey: oldKey, newKey: newKey))
        if let error = performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidThrowableError {
            throw error
        }
        try await performMigrationIfNeededPathStringOldKeyStringNewKeyDataVoidClosure?(path, oldKey, newKey)
    }

    //MARK: - markMigrationAsSkipped

    public var markMigrationAsSkippedVoidCallsCount = 0
    public var markMigrationAsSkippedVoidCalled: Bool {
        return markMigrationAsSkippedVoidCallsCount > 0
    }
    public var markMigrationAsSkippedVoidClosure: (() -> Void)?

    public func markMigrationAsSkipped() {
        markMigrationAsSkippedVoidCallsCount += 1
        markMigrationAsSkippedVoidClosure?()
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

    //MARK: - registerMlsTransport

    public var registerMlsTransportTransportAnyMlsTransportVoidCallsCount = 0
    public var registerMlsTransportTransportAnyMlsTransportVoidCalled: Bool {
        return registerMlsTransportTransportAnyMlsTransportVoidCallsCount > 0
    }
    public var registerMlsTransportTransportAnyMlsTransportVoidReceivedTransport: (any MlsTransport)?
    public var registerMlsTransportTransportAnyMlsTransportVoidReceivedInvocations: [(any MlsTransport)] = []
    public var registerMlsTransportTransportAnyMlsTransportVoidClosure: ((any MlsTransport) -> Void)?

    public func registerMlsTransport(_ transport: any MlsTransport) {
        registerMlsTransportTransportAnyMlsTransportVoidCallsCount += 1
        registerMlsTransportTransportAnyMlsTransportVoidReceivedTransport = transport
        registerMlsTransportTransportAnyMlsTransportVoidReceivedInvocations.append(transport)
        registerMlsTransportTransportAnyMlsTransportVoidClosure?(transport)
    }

    //MARK: - registerEpochObserver

    public var registerEpochObserverEpochObserverAnyWireCoreCryptoUniffiEpochObserverVoidCallsCount = 0
    public var registerEpochObserverEpochObserverAnyWireCoreCryptoUniffiEpochObserverVoidCalled: Bool {
        return registerEpochObserverEpochObserverAnyWireCoreCryptoUniffiEpochObserverVoidCallsCount > 0
    }
    public var registerEpochObserverEpochObserverAnyWireCoreCryptoUniffiEpochObserverVoidReceivedEpochObserver: (any WireCoreCryptoUniffi.EpochObserver)?
    public var registerEpochObserverEpochObserverAnyWireCoreCryptoUniffiEpochObserverVoidReceivedInvocations: [(any WireCoreCryptoUniffi.EpochObserver)] = []
    public var registerEpochObserverEpochObserverAnyWireCoreCryptoUniffiEpochObserverVoidClosure: ((any WireCoreCryptoUniffi.EpochObserver) async -> Void)?

    public func registerEpochObserver(_ epochObserver: any WireCoreCryptoUniffi.EpochObserver) async {
        registerEpochObserverEpochObserverAnyWireCoreCryptoUniffiEpochObserverVoidCallsCount += 1
        registerEpochObserverEpochObserverAnyWireCoreCryptoUniffiEpochObserverVoidReceivedEpochObserver = epochObserver
        registerEpochObserverEpochObserverAnyWireCoreCryptoUniffiEpochObserverVoidReceivedInvocations.append(epochObserver)
        await registerEpochObserverEpochObserverAnyWireCoreCryptoUniffiEpochObserverVoidClosure?(epochObserver)
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
public class CoreDataStackProtocolMock: CoreDataStackProtocol {

    public init() {}

    public var storesExists: Bool {
        get { return underlyingStoresExists }
        set(value) { underlyingStoresExists = value }
    }
    public var underlyingStoresExists: (Bool)!
    public var needsMigration: Bool {
        get { return underlyingNeedsMigration }
        set(value) { underlyingNeedsMigration = value }
    }
    public var underlyingNeedsMigration: (Bool)!
    public var account: Account {
        get { return underlyingAccount }
        set(value) { underlyingAccount = value }
    }
    public var underlyingAccount: (Account)!
    public var viewContext: NSManagedObjectContext {
        get { return underlyingViewContext }
        set(value) { underlyingViewContext = value }
    }
    public var underlyingViewContext: (NSManagedObjectContext)!
    public var syncContext: NSManagedObjectContext {
        get { return underlyingSyncContext }
        set(value) { underlyingSyncContext = value }
    }
    public var underlyingSyncContext: (NSManagedObjectContext)!
    public var searchContext: NSManagedObjectContext {
        get { return underlyingSearchContext }
        set(value) { underlyingSearchContext = value }
    }
    public var underlyingSearchContext: (NSManagedObjectContext)!
    public var eventContext: NSManagedObjectContext {
        get { return underlyingEventContext }
        set(value) { underlyingEventContext = value }
    }
    public var underlyingEventContext: (NSManagedObjectContext)!


    //MARK: - loadStores

    public var loadStoresCompletionHandlerEscapingErrorVoidVoidCallsCount = 0
    public var loadStoresCompletionHandlerEscapingErrorVoidVoidCalled: Bool {
        return loadStoresCompletionHandlerEscapingErrorVoidVoidCallsCount > 0
    }
    public var loadStoresCompletionHandlerEscapingErrorVoidVoidReceivedCompletionHandler: (((Error?) -> Void))?
    public var loadStoresCompletionHandlerEscapingErrorVoidVoidReceivedInvocations: [(((Error?) -> Void))] = []
    public var loadStoresCompletionHandlerEscapingErrorVoidVoidClosure: ((@escaping (Error?) -> Void) -> Void)?

    public func loadStores(completionHandler: @escaping (Error?) -> Void) {
        loadStoresCompletionHandlerEscapingErrorVoidVoidCallsCount += 1
        loadStoresCompletionHandlerEscapingErrorVoidVoidReceivedCompletionHandler = completionHandler
        loadStoresCompletionHandlerEscapingErrorVoidVoidReceivedInvocations.append(completionHandler)
        loadStoresCompletionHandlerEscapingErrorVoidVoidClosure?(completionHandler)
    }

    //MARK: - newBackgroundContext

    public var newBackgroundContextNSManagedObjectContextCallsCount = 0
    public var newBackgroundContextNSManagedObjectContextCalled: Bool {
        return newBackgroundContextNSManagedObjectContextCallsCount > 0
    }
    public var newBackgroundContextNSManagedObjectContextReturnValue: NSManagedObjectContext!
    public var newBackgroundContextNSManagedObjectContextClosure: (() -> NSManagedObjectContext)?

    public func newBackgroundContext() -> NSManagedObjectContext {
        newBackgroundContextNSManagedObjectContextCallsCount += 1
        if let newBackgroundContextNSManagedObjectContextClosure = newBackgroundContextNSManagedObjectContextClosure {
            return newBackgroundContextNSManagedObjectContextClosure()
        } else {
            return newBackgroundContextNSManagedObjectContextReturnValue
        }
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

    //MARK: - fetchChannels

    public var fetchChannelsFeatureChannelsCallsCount = 0
    public var fetchChannelsFeatureChannelsCalled: Bool {
        return fetchChannelsFeatureChannelsCallsCount > 0
    }
    public var fetchChannelsFeatureChannelsReturnValue: Feature.Channels!
    public var fetchChannelsFeatureChannelsClosure: (() -> Feature.Channels)?

    public func fetchChannels() -> Feature.Channels {
        fetchChannelsFeatureChannelsCallsCount += 1
        if let fetchChannelsFeatureChannelsClosure = fetchChannelsFeatureChannelsClosure {
            return fetchChannelsFeatureChannelsClosure()
        } else {
            return fetchChannelsFeatureChannelsReturnValue
        }
    }

    //MARK: - storeChannels

    public var storeChannelsChannelsFeatureChannelsVoidCallsCount = 0
    public var storeChannelsChannelsFeatureChannelsVoidCalled: Bool {
        return storeChannelsChannelsFeatureChannelsVoidCallsCount > 0
    }
    public var storeChannelsChannelsFeatureChannelsVoidReceivedChannels: (Feature.Channels)?
    public var storeChannelsChannelsFeatureChannelsVoidReceivedInvocations: [(Feature.Channels)] = []
    public var storeChannelsChannelsFeatureChannelsVoidClosure: ((Feature.Channels) -> Void)?

    public func storeChannels(_ channels: Feature.Channels) {
        storeChannelsChannelsFeatureChannelsVoidCallsCount += 1
        storeChannelsChannelsFeatureChannelsVoidReceivedChannels = channels
        storeChannelsChannelsFeatureChannelsVoidReceivedInvocations.append(channels)
        storeChannelsChannelsFeatureChannelsVoidClosure?(channels)
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
public class LegacyConversationEventProcessorProtocolMock: LegacyConversationEventProcessorProtocol {

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

    var countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntThrowableError: (any Error)?
    var countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntCallsCount = 0
    var countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntCalled: Bool {
        return countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntCallsCount > 0
    }
    var countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntReceivedArguments: (clientID: String, ciphersuite: MLSCipherSuite?, context: NotificationContext)?
    var countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntReceivedInvocations: [(clientID: String, ciphersuite: MLSCipherSuite?, context: NotificationContext)] = []
    var countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntReturnValue: Int!
    var countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntClosure: ((String, MLSCipherSuite?, NotificationContext) async throws -> Int)?

    func countUnclaimedKeyPackages(clientID: String, ciphersuite: MLSCipherSuite?, context: NotificationContext) async throws -> Int {
        countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntCallsCount += 1
        countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntReceivedArguments = (clientID: clientID, ciphersuite: ciphersuite, context: context)
        countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntReceivedInvocations.append((clientID: clientID, ciphersuite: ciphersuite, context: context))
        if let error = countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntThrowableError {
            throw error
        }
        if let countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntClosure = countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntClosure {
            return try await countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntClosure(clientID, ciphersuite, context)
        } else {
            return countUnclaimedKeyPackagesClientIDStringCiphersuiteMLSCipherSuiteContextNotificationContextIntReturnValue
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
public class MLSClientManagerProtocolMock: MLSClientManagerProtocol {

    public init() {}



    //MARK: - initializeMLSClientIfNeeded

    public var initializeMLSClientIfNeededForQualifiedClientIDQualifiedClientIDHasRegisteredMLSClientBoolMlsFeatureFeatureMLSVoidCallsCount = 0
    public var initializeMLSClientIfNeededForQualifiedClientIDQualifiedClientIDHasRegisteredMLSClientBoolMlsFeatureFeatureMLSVoidCalled: Bool {
        return initializeMLSClientIfNeededForQualifiedClientIDQualifiedClientIDHasRegisteredMLSClientBoolMlsFeatureFeatureMLSVoidCallsCount > 0
    }
    public var initializeMLSClientIfNeededForQualifiedClientIDQualifiedClientIDHasRegisteredMLSClientBoolMlsFeatureFeatureMLSVoidReceivedArguments: (qualifiedClientID: QualifiedClientID, hasRegisteredMLSClient: Bool, mlsFeature: Feature.MLS)?
    public var initializeMLSClientIfNeededForQualifiedClientIDQualifiedClientIDHasRegisteredMLSClientBoolMlsFeatureFeatureMLSVoidReceivedInvocations: [(qualifiedClientID: QualifiedClientID, hasRegisteredMLSClient: Bool, mlsFeature: Feature.MLS)] = []
    public var initializeMLSClientIfNeededForQualifiedClientIDQualifiedClientIDHasRegisteredMLSClientBoolMlsFeatureFeatureMLSVoidClosure: ((QualifiedClientID, Bool, Feature.MLS) async -> Void)?

    public func initializeMLSClientIfNeeded(for qualifiedClientID: QualifiedClientID, hasRegisteredMLSClient: Bool, mlsFeature: Feature.MLS) async {
        initializeMLSClientIfNeededForQualifiedClientIDQualifiedClientIDHasRegisteredMLSClientBoolMlsFeatureFeatureMLSVoidCallsCount += 1
        initializeMLSClientIfNeededForQualifiedClientIDQualifiedClientIDHasRegisteredMLSClientBoolMlsFeatureFeatureMLSVoidReceivedArguments = (qualifiedClientID: qualifiedClientID, hasRegisteredMLSClient: hasRegisteredMLSClient, mlsFeature: mlsFeature)
        initializeMLSClientIfNeededForQualifiedClientIDQualifiedClientIDHasRegisteredMLSClientBoolMlsFeatureFeatureMLSVoidReceivedInvocations.append((qualifiedClientID: qualifiedClientID, hasRegisteredMLSClient: hasRegisteredMLSClient, mlsFeature: mlsFeature))
        await initializeMLSClientIfNeededForQualifiedClientIDQualifiedClientIDHasRegisteredMLSClientBoolMlsFeatureFeatureMLSVoidClosure?(qualifiedClientID, hasRegisteredMLSClient, mlsFeature)
    }


}
public class MLSDecryptionServiceInterfaceMock: MLSDecryptionServiceInterface {

    public init() {}



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

    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultThrowableError: (any Error)?
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultCallsCount = 0
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultCalled: Bool {
        return decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultCallsCount > 0
    }
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReceivedArguments: (message: String, groupID: MLSGroupID, subconversationType: SubgroupType?, context: CoreCryptoContextProtocol?)?
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReceivedInvocations: [(message: String, groupID: MLSGroupID, subconversationType: SubgroupType?, context: CoreCryptoContextProtocol?)] = []
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReturnValue: [MLSDecryptResult]!
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultClosure: ((String, MLSGroupID, SubgroupType?, CoreCryptoContextProtocol?) async throws -> [MLSDecryptResult])?

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?, context: CoreCryptoContextProtocol?) async throws -> [MLSDecryptResult] {
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultCallsCount += 1
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReceivedArguments = (message: message, groupID: groupID, subconversationType: subconversationType, context: context)
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReceivedInvocations.append((message: message, groupID: groupID, subconversationType: subconversationType, context: context))
        if let error = decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultThrowableError {
            throw error
        }
        if let decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultClosure = decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultClosure {
            return try await decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultClosure(message, groupID, subconversationType, context)
        } else {
            return decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReturnValue
        }
    }

    //MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDThrowableError: (any Error)?
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDCallsCount = 0
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDCalled: Bool {
        return processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDCallsCount > 0
    }
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReceivedArguments: (welcomeMessage: String, context: CoreCryptoContextProtocol?)?
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReceivedInvocations: [(welcomeMessage: String, context: CoreCryptoContextProtocol?)] = []
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReturnValue: MLSGroupID!
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDClosure: ((String, CoreCryptoContextProtocol?) async throws -> MLSGroupID)?

    public func processWelcomeMessage(welcomeMessage: String, context: CoreCryptoContextProtocol?) async throws -> MLSGroupID {
        processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDCallsCount += 1
        processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReceivedArguments = (welcomeMessage: welcomeMessage, context: context)
        processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReceivedInvocations.append((welcomeMessage: welcomeMessage, context: context))
        if let error = processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDThrowableError {
            throw error
        }
        if let processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDClosure = processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDClosure {
            return try await processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDClosure(welcomeMessage, context)
        } else {
            return processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReturnValue
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
    public var commitPendingProposalsIfNeededVoidClosure: (() async -> Void)?

    public func commitPendingProposalsIfNeeded() async {
        commitPendingProposalsIfNeededVoidCallsCount += 1
        await commitPendingProposalsIfNeededVoidClosure?()
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

    public var fetchAndRepairGroupWithGroupIDMLSGroupIDShouldPerformIncrementalSyncBoolVoidCallsCount = 0
    public var fetchAndRepairGroupWithGroupIDMLSGroupIDShouldPerformIncrementalSyncBoolVoidCalled: Bool {
        return fetchAndRepairGroupWithGroupIDMLSGroupIDShouldPerformIncrementalSyncBoolVoidCallsCount > 0
    }
    public var fetchAndRepairGroupWithGroupIDMLSGroupIDShouldPerformIncrementalSyncBoolVoidReceivedArguments: (groupID: MLSGroupID, shouldPerformIncrementalSync: Bool)?
    public var fetchAndRepairGroupWithGroupIDMLSGroupIDShouldPerformIncrementalSyncBoolVoidReceivedInvocations: [(groupID: MLSGroupID, shouldPerformIncrementalSync: Bool)] = []
    public var fetchAndRepairGroupWithGroupIDMLSGroupIDShouldPerformIncrementalSyncBoolVoidClosure: ((MLSGroupID, Bool) async -> Void)?

    public func fetchAndRepairGroup(with groupID: MLSGroupID, shouldPerformIncrementalSync: Bool) async {
        fetchAndRepairGroupWithGroupIDMLSGroupIDShouldPerformIncrementalSyncBoolVoidCallsCount += 1
        fetchAndRepairGroupWithGroupIDMLSGroupIDShouldPerformIncrementalSyncBoolVoidReceivedArguments = (groupID: groupID, shouldPerformIncrementalSync: shouldPerformIncrementalSync)
        fetchAndRepairGroupWithGroupIDMLSGroupIDShouldPerformIncrementalSyncBoolVoidReceivedInvocations.append((groupID: groupID, shouldPerformIncrementalSync: shouldPerformIncrementalSync))
        await fetchAndRepairGroupWithGroupIDMLSGroupIDShouldPerformIncrementalSyncBoolVoidClosure?(groupID, shouldPerformIncrementalSync)
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

    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorCallsCount = 0
    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorCalled: Bool {
        return onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorCallsCount > 0
    }
    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorReceivedArguments: (parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID)?
    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorReceivedInvocations: [(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID)] = []
    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorReturnValue: AsyncThrowingStream<MLSConferenceInfo, Error>!
    public var onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorClosure: ((MLSGroupID, MLSGroupID) -> AsyncThrowingStream<MLSConferenceInfo, Error>)?

    public func onConferenceInfoChange(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID) -> AsyncThrowingStream<MLSConferenceInfo, Error> {
        onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorCallsCount += 1
        onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorReceivedArguments = (parentGroupID: parentGroupID, subConversationGroupID: subConversationGroupID)
        onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorReceivedInvocations.append((parentGroupID: parentGroupID, subConversationGroupID: subConversationGroupID))
        if let onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorClosure = onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorClosure {
            return onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorClosure(parentGroupID, subConversationGroupID)
        } else {
            return onConferenceInfoChangeParentGroupIDMLSGroupIDSubConversationGroupIDMLSGroupIDAsyncThrowingStreamMLSConferenceInfoGetTeamAccountImageSourceUseCaseErrorReturnValue
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

    //MARK: - setSyncDelegate

    public var setSyncDelegateDelegateAnyMLSSyncDelegateVoidCallsCount = 0
    public var setSyncDelegateDelegateAnyMLSSyncDelegateVoidCalled: Bool {
        return setSyncDelegateDelegateAnyMLSSyncDelegateVoidCallsCount > 0
    }
    public var setSyncDelegateDelegateAnyMLSSyncDelegateVoidReceivedDelegate: (any MLSSyncDelegate)?
    public var setSyncDelegateDelegateAnyMLSSyncDelegateVoidReceivedInvocations: [(any MLSSyncDelegate)] = []
    public var setSyncDelegateDelegateAnyMLSSyncDelegateVoidClosure: ((any MLSSyncDelegate) -> Void)?

    public func setSyncDelegate(_ delegate: any MLSSyncDelegate) {
        setSyncDelegateDelegateAnyMLSSyncDelegateVoidCallsCount += 1
        setSyncDelegateDelegateAnyMLSSyncDelegateVoidReceivedDelegate = delegate
        setSyncDelegateDelegateAnyMLSSyncDelegateVoidReceivedInvocations.append(delegate)
        setSyncDelegateDelegateAnyMLSSyncDelegateVoidClosure?(delegate)
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

    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultThrowableError: (any Error)?
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultCallsCount = 0
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultCalled: Bool {
        return decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultCallsCount > 0
    }
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReceivedArguments: (message: String, groupID: MLSGroupID, subconversationType: SubgroupType?, context: CoreCryptoContextProtocol?)?
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReceivedInvocations: [(message: String, groupID: MLSGroupID, subconversationType: SubgroupType?, context: CoreCryptoContextProtocol?)] = []
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReturnValue: [MLSDecryptResult]!
    public var decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultClosure: ((String, MLSGroupID, SubgroupType?, CoreCryptoContextProtocol?) async throws -> [MLSDecryptResult])?

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?, context: CoreCryptoContextProtocol?) async throws -> [MLSDecryptResult] {
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultCallsCount += 1
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReceivedArguments = (message: message, groupID: groupID, subconversationType: subconversationType, context: context)
        decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReceivedInvocations.append((message: message, groupID: groupID, subconversationType: subconversationType, context: context))
        if let error = decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultThrowableError {
            throw error
        }
        if let decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultClosure = decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultClosure {
            return try await decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultClosure(message, groupID, subconversationType, context)
        } else {
            return decryptMessageStringForGroupIDMLSGroupIDSubconversationTypeSubgroupTypeContextCoreCryptoContextProtocolMLSDecryptResultReturnValue
        }
    }

    //MARK: - processWelcomeMessage

    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDThrowableError: (any Error)?
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDCallsCount = 0
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDCalled: Bool {
        return processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDCallsCount > 0
    }
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReceivedArguments: (welcomeMessage: String, context: CoreCryptoContextProtocol?)?
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReceivedInvocations: [(welcomeMessage: String, context: CoreCryptoContextProtocol?)] = []
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReturnValue: MLSGroupID!
    public var processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDClosure: ((String, CoreCryptoContextProtocol?) async throws -> MLSGroupID)?

    public func processWelcomeMessage(welcomeMessage: String, context: CoreCryptoContextProtocol?) async throws -> MLSGroupID {
        processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDCallsCount += 1
        processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReceivedArguments = (welcomeMessage: welcomeMessage, context: context)
        processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReceivedInvocations.append((welcomeMessage: welcomeMessage, context: context))
        if let error = processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDThrowableError {
            throw error
        }
        if let processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDClosure = processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDClosure {
            return try await processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDClosure(welcomeMessage, context)
        } else {
            return processWelcomeMessageWelcomeMessageStringContextCoreCryptoContextProtocolMLSGroupIDReturnValue
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
public class MLSSyncDelegateMock: MLSSyncDelegate {

    public init() {}



    //MARK: - recoverWithIncrementalSync

    public var recoverWithIncrementalSyncVoidThrowableError: (any Error)?
    public var recoverWithIncrementalSyncVoidCallsCount = 0
    public var recoverWithIncrementalSyncVoidCalled: Bool {
        return recoverWithIncrementalSyncVoidCallsCount > 0
    }
    public var recoverWithIncrementalSyncVoidClosure: (() async throws -> Void)?

    public func recoverWithIncrementalSync() async throws {
        recoverWithIncrementalSyncVoidCallsCount += 1
        if let error = recoverWithIncrementalSyncVoidThrowableError {
            throw error
        }
        try await recoverWithIncrementalSyncVoidClosure?()
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

    public var decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataThrowableError: (any Error)?
    public var decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataCallsCount = 0
    public var decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataCalled: Bool {
        return decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataCallsCount > 0
    }
    public var decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataReceivedArguments: (data: Data, id: ProteusSessionID, context: CoreCryptoContextProtocol?)?
    public var decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataReceivedInvocations: [(data: Data, id: ProteusSessionID, context: CoreCryptoContextProtocol?)] = []
    public var decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataReturnValue: (didCreateNewSession: Bool, decryptedData: Data)!
    public var decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataClosure: ((Data, ProteusSessionID, CoreCryptoContextProtocol?) async throws -> (didCreateNewSession: Bool, decryptedData: Data))?

    public func decrypt(data: Data, forSession id: ProteusSessionID, context: CoreCryptoContextProtocol?) async throws -> (didCreateNewSession: Bool, decryptedData: Data) {
        decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataCallsCount += 1
        decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataReceivedArguments = (data: data, id: id, context: context)
        decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataReceivedInvocations.append((data: data, id: id, context: context))
        if let error = decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataThrowableError {
            throw error
        }
        if let decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataClosure = decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataClosure {
            return try await decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataClosure(data, id, context)
        } else {
            return decryptDataDataForSessionIdProteusSessionIDContextCoreCryptoContextProtocol_DidCreateNewSessionBoolDecryptedDataDataReturnValue
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
public class SyncStatusProtocolMock: SyncStatusProtocol {

    public init() {}

    public var isLive: Bool {
        get { return underlyingIsLive }
        set(value) { underlyingIsLive = value }
    }
    public var underlyingIsLive: (Bool)!


    //MARK: - performQuickSync

    public var performQuickSyncVoidCallsCount = 0
    public var performQuickSyncVoidCalled: Bool {
        return performQuickSyncVoidCallsCount > 0
    }
    public var performQuickSyncVoidClosure: (() async -> Void)?

    public func performQuickSync() async {
        performQuickSyncVoidCallsCount += 1
        await performQuickSyncVoidClosure?()
    }

    //MARK: - resyncResources

    public var resyncResourcesVoidCallsCount = 0
    public var resyncResourcesVoidCalled: Bool {
        return resyncResourcesVoidCallsCount > 0
    }
    public var resyncResourcesVoidClosure: (() -> Void)?

    public func resyncResources() {
        resyncResourcesVoidCallsCount += 1
        resyncResourcesVoidClosure?()
    }

    //MARK: - forceSlowSync

    public var forceSlowSyncVoidCallsCount = 0
    public var forceSlowSyncVoidCalled: Bool {
        return forceSlowSyncVoidCallsCount > 0
    }
    public var forceSlowSyncVoidClosure: (() -> Void)?

    public func forceSlowSync() {
        forceSlowSyncVoidCallsCount += 1
        forceSlowSyncVoidClosure?()
    }

    //MARK: - recoverWithQuickSync

    public var recoverWithQuickSyncVoidCallsCount = 0
    public var recoverWithQuickSyncVoidCalled: Bool {
        return recoverWithQuickSyncVoidCallsCount > 0
    }
    public var recoverWithQuickSyncVoidClosure: (() async -> Void)?

    public func recoverWithQuickSync() async {
        recoverWithQuickSyncVoidCallsCount += 1
        await recoverWithQuickSyncVoidClosure?()
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
