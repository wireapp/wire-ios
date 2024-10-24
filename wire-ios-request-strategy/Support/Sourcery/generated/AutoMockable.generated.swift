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

import WireCoreCrypto
import Combine

@testable import WireRequestStrategy
























public class APIProviderInterfaceMock: APIProviderInterface {

    public init() {}



    //MARK: - prekeyAPI

    public var prekeyAPIApiVersionAPIVersionPrekeyAPICallsCount = 0
    public var prekeyAPIApiVersionAPIVersionPrekeyAPICalled: Bool {
        return prekeyAPIApiVersionAPIVersionPrekeyAPICallsCount > 0
    }
    public var prekeyAPIApiVersionAPIVersionPrekeyAPIReceivedApiVersion: (APIVersion)?
    public var prekeyAPIApiVersionAPIVersionPrekeyAPIReceivedInvocations: [(APIVersion)] = []
    public var prekeyAPIApiVersionAPIVersionPrekeyAPIReturnValue: PrekeyAPI!
    public var prekeyAPIApiVersionAPIVersionPrekeyAPIClosure: ((APIVersion) -> PrekeyAPI)?

    public func prekeyAPI(apiVersion: APIVersion) -> PrekeyAPI {
        prekeyAPIApiVersionAPIVersionPrekeyAPICallsCount += 1
        prekeyAPIApiVersionAPIVersionPrekeyAPIReceivedApiVersion = apiVersion
        prekeyAPIApiVersionAPIVersionPrekeyAPIReceivedInvocations.append(apiVersion)
        if let prekeyAPIApiVersionAPIVersionPrekeyAPIClosure = prekeyAPIApiVersionAPIVersionPrekeyAPIClosure {
            return prekeyAPIApiVersionAPIVersionPrekeyAPIClosure(apiVersion)
        } else {
            return prekeyAPIApiVersionAPIVersionPrekeyAPIReturnValue
        }
    }

    //MARK: - messageAPI

    public var messageAPIApiVersionAPIVersionMessageAPICallsCount = 0
    public var messageAPIApiVersionAPIVersionMessageAPICalled: Bool {
        return messageAPIApiVersionAPIVersionMessageAPICallsCount > 0
    }
    public var messageAPIApiVersionAPIVersionMessageAPIReceivedApiVersion: (APIVersion)?
    public var messageAPIApiVersionAPIVersionMessageAPIReceivedInvocations: [(APIVersion)] = []
    public var messageAPIApiVersionAPIVersionMessageAPIReturnValue: MessageAPI!
    public var messageAPIApiVersionAPIVersionMessageAPIClosure: ((APIVersion) -> MessageAPI)?

    public func messageAPI(apiVersion: APIVersion) -> MessageAPI {
        messageAPIApiVersionAPIVersionMessageAPICallsCount += 1
        messageAPIApiVersionAPIVersionMessageAPIReceivedApiVersion = apiVersion
        messageAPIApiVersionAPIVersionMessageAPIReceivedInvocations.append(apiVersion)
        if let messageAPIApiVersionAPIVersionMessageAPIClosure = messageAPIApiVersionAPIVersionMessageAPIClosure {
            return messageAPIApiVersionAPIVersionMessageAPIClosure(apiVersion)
        } else {
            return messageAPIApiVersionAPIVersionMessageAPIReturnValue
        }
    }

    //MARK: - e2eIAPI

    public var e2eIAPIApiVersionAPIVersionE2eIAPICallsCount = 0
    public var e2eIAPIApiVersionAPIVersionE2eIAPICalled: Bool {
        return e2eIAPIApiVersionAPIVersionE2eIAPICallsCount > 0
    }
    public var e2eIAPIApiVersionAPIVersionE2eIAPIReceivedApiVersion: (APIVersion)?
    public var e2eIAPIApiVersionAPIVersionE2eIAPIReceivedInvocations: [(APIVersion)] = []
    public var e2eIAPIApiVersionAPIVersionE2eIAPIReturnValue: E2eIAPI?
    public var e2eIAPIApiVersionAPIVersionE2eIAPIClosure: ((APIVersion) -> E2eIAPI?)?

    public func e2eIAPI(apiVersion: APIVersion) -> E2eIAPI? {
        e2eIAPIApiVersionAPIVersionE2eIAPICallsCount += 1
        e2eIAPIApiVersionAPIVersionE2eIAPIReceivedApiVersion = apiVersion
        e2eIAPIApiVersionAPIVersionE2eIAPIReceivedInvocations.append(apiVersion)
        if let e2eIAPIApiVersionAPIVersionE2eIAPIClosure = e2eIAPIApiVersionAPIVersionE2eIAPIClosure {
            return e2eIAPIApiVersionAPIVersionE2eIAPIClosure(apiVersion)
        } else {
            return e2eIAPIApiVersionAPIVersionE2eIAPIReturnValue
        }
    }

    //MARK: - userClientAPI

    public var userClientAPIApiVersionAPIVersionUserClientAPICallsCount = 0
    public var userClientAPIApiVersionAPIVersionUserClientAPICalled: Bool {
        return userClientAPIApiVersionAPIVersionUserClientAPICallsCount > 0
    }
    public var userClientAPIApiVersionAPIVersionUserClientAPIReceivedApiVersion: (APIVersion)?
    public var userClientAPIApiVersionAPIVersionUserClientAPIReceivedInvocations: [(APIVersion)] = []
    public var userClientAPIApiVersionAPIVersionUserClientAPIReturnValue: UserClientAPI!
    public var userClientAPIApiVersionAPIVersionUserClientAPIClosure: ((APIVersion) -> UserClientAPI)?

    public func userClientAPI(apiVersion: APIVersion) -> UserClientAPI {
        userClientAPIApiVersionAPIVersionUserClientAPICallsCount += 1
        userClientAPIApiVersionAPIVersionUserClientAPIReceivedApiVersion = apiVersion
        userClientAPIApiVersionAPIVersionUserClientAPIReceivedInvocations.append(apiVersion)
        if let userClientAPIApiVersionAPIVersionUserClientAPIClosure = userClientAPIApiVersionAPIVersionUserClientAPIClosure {
            return userClientAPIApiVersionAPIVersionUserClientAPIClosure(apiVersion)
        } else {
            return userClientAPIApiVersionAPIVersionUserClientAPIReturnValue
        }
    }


}
public class AcmeAPIInterfaceMock: AcmeAPIInterface {

    public init() {}



    //MARK: - getACMEDirectory

    public var getACMEDirectoryDataThrowableError: (any Error)?
    public var getACMEDirectoryDataCallsCount = 0
    public var getACMEDirectoryDataCalled: Bool {
        return getACMEDirectoryDataCallsCount > 0
    }
    public var getACMEDirectoryDataReturnValue: Data!
    public var getACMEDirectoryDataClosure: (() async throws -> Data)?

    public func getACMEDirectory() async throws -> Data {
        getACMEDirectoryDataCallsCount += 1
        if let error = getACMEDirectoryDataThrowableError {
            throw error
        }
        if let getACMEDirectoryDataClosure = getACMEDirectoryDataClosure {
            return try await getACMEDirectoryDataClosure()
        } else {
            return getACMEDirectoryDataReturnValue
        }
    }

    //MARK: - getACMENonce

    public var getACMENoncePathStringStringThrowableError: (any Error)?
    public var getACMENoncePathStringStringCallsCount = 0
    public var getACMENoncePathStringStringCalled: Bool {
        return getACMENoncePathStringStringCallsCount > 0
    }
    public var getACMENoncePathStringStringReceivedPath: (String)?
    public var getACMENoncePathStringStringReceivedInvocations: [(String)] = []
    public var getACMENoncePathStringStringReturnValue: String!
    public var getACMENoncePathStringStringClosure: ((String) async throws -> String)?

    public func getACMENonce(path: String) async throws -> String {
        getACMENoncePathStringStringCallsCount += 1
        getACMENoncePathStringStringReceivedPath = path
        getACMENoncePathStringStringReceivedInvocations.append(path)
        if let error = getACMENoncePathStringStringThrowableError {
            throw error
        }
        if let getACMENoncePathStringStringClosure = getACMENoncePathStringStringClosure {
            return try await getACMENoncePathStringStringClosure(path)
        } else {
            return getACMENoncePathStringStringReturnValue
        }
    }

    //MARK: - getTrustAnchor

    public var getTrustAnchorStringThrowableError: (any Error)?
    public var getTrustAnchorStringCallsCount = 0
    public var getTrustAnchorStringCalled: Bool {
        return getTrustAnchorStringCallsCount > 0
    }
    public var getTrustAnchorStringReturnValue: String!
    public var getTrustAnchorStringClosure: (() async throws -> String)?

    public func getTrustAnchor() async throws -> String {
        getTrustAnchorStringCallsCount += 1
        if let error = getTrustAnchorStringThrowableError {
            throw error
        }
        if let getTrustAnchorStringClosure = getTrustAnchorStringClosure {
            return try await getTrustAnchorStringClosure()
        } else {
            return getTrustAnchorStringReturnValue
        }
    }

    //MARK: - getFederationCertificates

    public var getFederationCertificatesStringThrowableError: (any Error)?
    public var getFederationCertificatesStringCallsCount = 0
    public var getFederationCertificatesStringCalled: Bool {
        return getFederationCertificatesStringCallsCount > 0
    }
    public var getFederationCertificatesStringReturnValue: [String]!
    public var getFederationCertificatesStringClosure: (() async throws -> [String])?

    public func getFederationCertificates() async throws -> [String] {
        getFederationCertificatesStringCallsCount += 1
        if let error = getFederationCertificatesStringThrowableError {
            throw error
        }
        if let getFederationCertificatesStringClosure = getFederationCertificatesStringClosure {
            return try await getFederationCertificatesStringClosure()
        } else {
            return getFederationCertificatesStringReturnValue
        }
    }

    //MARK: - sendACMERequest

    public var sendACMERequestPathStringRequestBodyDataACMEResponseThrowableError: (any Error)?
    public var sendACMERequestPathStringRequestBodyDataACMEResponseCallsCount = 0
    public var sendACMERequestPathStringRequestBodyDataACMEResponseCalled: Bool {
        return sendACMERequestPathStringRequestBodyDataACMEResponseCallsCount > 0
    }
    public var sendACMERequestPathStringRequestBodyDataACMEResponseReceivedArguments: (path: String, requestBody: Data)?
    public var sendACMERequestPathStringRequestBodyDataACMEResponseReceivedInvocations: [(path: String, requestBody: Data)] = []
    public var sendACMERequestPathStringRequestBodyDataACMEResponseReturnValue: ACMEResponse!
    public var sendACMERequestPathStringRequestBodyDataACMEResponseClosure: ((String, Data) async throws -> ACMEResponse)?

    public func sendACMERequest(path: String, requestBody: Data) async throws -> ACMEResponse {
        sendACMERequestPathStringRequestBodyDataACMEResponseCallsCount += 1
        sendACMERequestPathStringRequestBodyDataACMEResponseReceivedArguments = (path: path, requestBody: requestBody)
        sendACMERequestPathStringRequestBodyDataACMEResponseReceivedInvocations.append((path: path, requestBody: requestBody))
        if let error = sendACMERequestPathStringRequestBodyDataACMEResponseThrowableError {
            throw error
        }
        if let sendACMERequestPathStringRequestBodyDataACMEResponseClosure = sendACMERequestPathStringRequestBodyDataACMEResponseClosure {
            return try await sendACMERequestPathStringRequestBodyDataACMEResponseClosure(path, requestBody)
        } else {
            return sendACMERequestPathStringRequestBodyDataACMEResponseReturnValue
        }
    }

    //MARK: - sendAuthorizationRequest

    public var sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseThrowableError: (any Error)?
    public var sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseCallsCount = 0
    public var sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseCalled: Bool {
        return sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseCallsCount > 0
    }
    public var sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseReceivedArguments: (path: String, requestBody: Data)?
    public var sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseReceivedInvocations: [(path: String, requestBody: Data)] = []
    public var sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseReturnValue: ACMEAuthorizationResponse!
    public var sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseClosure: ((String, Data) async throws -> ACMEAuthorizationResponse)?

    public func sendAuthorizationRequest(path: String, requestBody: Data) async throws -> ACMEAuthorizationResponse {
        sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseCallsCount += 1
        sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseReceivedArguments = (path: path, requestBody: requestBody)
        sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseReceivedInvocations.append((path: path, requestBody: requestBody))
        if let error = sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseThrowableError {
            throw error
        }
        if let sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseClosure = sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseClosure {
            return try await sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseClosure(path, requestBody)
        } else {
            return sendAuthorizationRequestPathStringRequestBodyDataACMEAuthorizationResponseReturnValue
        }
    }

    //MARK: - sendChallengeRequest

    public var sendChallengeRequestPathStringRequestBodyDataChallengeResponseThrowableError: (any Error)?
    public var sendChallengeRequestPathStringRequestBodyDataChallengeResponseCallsCount = 0
    public var sendChallengeRequestPathStringRequestBodyDataChallengeResponseCalled: Bool {
        return sendChallengeRequestPathStringRequestBodyDataChallengeResponseCallsCount > 0
    }
    public var sendChallengeRequestPathStringRequestBodyDataChallengeResponseReceivedArguments: (path: String, requestBody: Data)?
    public var sendChallengeRequestPathStringRequestBodyDataChallengeResponseReceivedInvocations: [(path: String, requestBody: Data)] = []
    public var sendChallengeRequestPathStringRequestBodyDataChallengeResponseReturnValue: ChallengeResponse!
    public var sendChallengeRequestPathStringRequestBodyDataChallengeResponseClosure: ((String, Data) async throws -> ChallengeResponse)?

    public func sendChallengeRequest(path: String, requestBody: Data) async throws -> ChallengeResponse {
        sendChallengeRequestPathStringRequestBodyDataChallengeResponseCallsCount += 1
        sendChallengeRequestPathStringRequestBodyDataChallengeResponseReceivedArguments = (path: path, requestBody: requestBody)
        sendChallengeRequestPathStringRequestBodyDataChallengeResponseReceivedInvocations.append((path: path, requestBody: requestBody))
        if let error = sendChallengeRequestPathStringRequestBodyDataChallengeResponseThrowableError {
            throw error
        }
        if let sendChallengeRequestPathStringRequestBodyDataChallengeResponseClosure = sendChallengeRequestPathStringRequestBodyDataChallengeResponseClosure {
            return try await sendChallengeRequestPathStringRequestBodyDataChallengeResponseClosure(path, requestBody)
        } else {
            return sendChallengeRequestPathStringRequestBodyDataChallengeResponseReturnValue
        }
    }


}
public class CertificateRevocationListAPIProtocolMock: CertificateRevocationListAPIProtocol {

    public init() {}



    //MARK: - getRevocationList

    public var getRevocationListFromDistributionPointURLDataThrowableError: (any Error)?
    public var getRevocationListFromDistributionPointURLDataCallsCount = 0
    public var getRevocationListFromDistributionPointURLDataCalled: Bool {
        return getRevocationListFromDistributionPointURLDataCallsCount > 0
    }
    public var getRevocationListFromDistributionPointURLDataReceivedDistributionPoint: (URL)?
    public var getRevocationListFromDistributionPointURLDataReceivedInvocations: [(URL)] = []
    public var getRevocationListFromDistributionPointURLDataReturnValue: Data!
    public var getRevocationListFromDistributionPointURLDataClosure: ((URL) async throws -> Data)?

    public func getRevocationList(from distributionPoint: URL) async throws -> Data {
        getRevocationListFromDistributionPointURLDataCallsCount += 1
        getRevocationListFromDistributionPointURLDataReceivedDistributionPoint = distributionPoint
        getRevocationListFromDistributionPointURLDataReceivedInvocations.append(distributionPoint)
        if let error = getRevocationListFromDistributionPointURLDataThrowableError {
            throw error
        }
        if let getRevocationListFromDistributionPointURLDataClosure = getRevocationListFromDistributionPointURLDataClosure {
            return try await getRevocationListFromDistributionPointURLDataClosure(distributionPoint)
        } else {
            return getRevocationListFromDistributionPointURLDataReturnValue
        }
    }


}
public class ConversationParticipantsServiceInterfaceMock: ConversationParticipantsServiceInterface {

    public init() {}



    //MARK: - addParticipants

    public var addParticipantsUsersZMUserToConversationZMConversationVoidThrowableError: (any Error)?
    public var addParticipantsUsersZMUserToConversationZMConversationVoidCallsCount = 0
    public var addParticipantsUsersZMUserToConversationZMConversationVoidCalled: Bool {
        return addParticipantsUsersZMUserToConversationZMConversationVoidCallsCount > 0
    }
    public var addParticipantsUsersZMUserToConversationZMConversationVoidReceivedArguments: (users: [ZMUser], conversation: ZMConversation)?
    public var addParticipantsUsersZMUserToConversationZMConversationVoidReceivedInvocations: [(users: [ZMUser], conversation: ZMConversation)] = []
    public var addParticipantsUsersZMUserToConversationZMConversationVoidClosure: (([ZMUser], ZMConversation) async throws -> Void)?

    public func addParticipants(_ users: [ZMUser], to conversation: ZMConversation) async throws {
        addParticipantsUsersZMUserToConversationZMConversationVoidCallsCount += 1
        addParticipantsUsersZMUserToConversationZMConversationVoidReceivedArguments = (users: users, conversation: conversation)
        addParticipantsUsersZMUserToConversationZMConversationVoidReceivedInvocations.append((users: users, conversation: conversation))
        if let error = addParticipantsUsersZMUserToConversationZMConversationVoidThrowableError {
            throw error
        }
        try await addParticipantsUsersZMUserToConversationZMConversationVoidClosure?(users, conversation)
    }

    //MARK: - removeParticipant

    public var removeParticipantUserZMUserFromConversationZMConversationVoidThrowableError: (any Error)?
    public var removeParticipantUserZMUserFromConversationZMConversationVoidCallsCount = 0
    public var removeParticipantUserZMUserFromConversationZMConversationVoidCalled: Bool {
        return removeParticipantUserZMUserFromConversationZMConversationVoidCallsCount > 0
    }
    public var removeParticipantUserZMUserFromConversationZMConversationVoidReceivedArguments: (user: ZMUser, conversation: ZMConversation)?
    public var removeParticipantUserZMUserFromConversationZMConversationVoidReceivedInvocations: [(user: ZMUser, conversation: ZMConversation)] = []
    public var removeParticipantUserZMUserFromConversationZMConversationVoidClosure: ((ZMUser, ZMConversation) async throws -> Void)?

    public func removeParticipant(_ user: ZMUser, from conversation: ZMConversation) async throws {
        removeParticipantUserZMUserFromConversationZMConversationVoidCallsCount += 1
        removeParticipantUserZMUserFromConversationZMConversationVoidReceivedArguments = (user: user, conversation: conversation)
        removeParticipantUserZMUserFromConversationZMConversationVoidReceivedInvocations.append((user: user, conversation: conversation))
        if let error = removeParticipantUserZMUserFromConversationZMConversationVoidThrowableError {
            throw error
        }
        try await removeParticipantUserZMUserFromConversationZMConversationVoidClosure?(user, conversation)
    }


}
public class ConversationServiceInterfaceMock: ConversationServiceInterface {

    public init() {}



    //MARK: - createGroupConversation

    public var createGroupConversationNameStringUsersSetZMUserAllowGuestsBoolAllowServicesBoolEnableReceiptsBoolMessageProtocolMessageProtocolCompletionEscapingResultZMConversationConversationCreationFailureVoidVoidCallsCount = 0
    public var createGroupConversationNameStringUsersSetZMUserAllowGuestsBoolAllowServicesBoolEnableReceiptsBoolMessageProtocolMessageProtocolCompletionEscapingResultZMConversationConversationCreationFailureVoidVoidCalled: Bool {
        return createGroupConversationNameStringUsersSetZMUserAllowGuestsBoolAllowServicesBoolEnableReceiptsBoolMessageProtocolMessageProtocolCompletionEscapingResultZMConversationConversationCreationFailureVoidVoidCallsCount > 0
    }
    public var createGroupConversationNameStringUsersSetZMUserAllowGuestsBoolAllowServicesBoolEnableReceiptsBoolMessageProtocolMessageProtocolCompletionEscapingResultZMConversationConversationCreationFailureVoidVoidReceivedArguments: (name: String?, users: Set<ZMUser>, allowGuests: Bool, allowServices: Bool, enableReceipts: Bool, messageProtocol: MessageProtocol, completion: (Result<ZMConversation, ConversationCreationFailure>) -> Void)?
    public var createGroupConversationNameStringUsersSetZMUserAllowGuestsBoolAllowServicesBoolEnableReceiptsBoolMessageProtocolMessageProtocolCompletionEscapingResultZMConversationConversationCreationFailureVoidVoidReceivedInvocations: [(name: String?, users: Set<ZMUser>, allowGuests: Bool, allowServices: Bool, enableReceipts: Bool, messageProtocol: MessageProtocol, completion: (Result<ZMConversation, ConversationCreationFailure>) -> Void)] = []
    public var createGroupConversationNameStringUsersSetZMUserAllowGuestsBoolAllowServicesBoolEnableReceiptsBoolMessageProtocolMessageProtocolCompletionEscapingResultZMConversationConversationCreationFailureVoidVoidClosure: ((String?, Set<ZMUser>, Bool, Bool, Bool, MessageProtocol, @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void) -> Void)?

    public func createGroupConversation(name: String?, users: Set<ZMUser>, allowGuests: Bool, allowServices: Bool, enableReceipts: Bool, messageProtocol: MessageProtocol, completion: @escaping (Result<ZMConversation, ConversationCreationFailure>) -> Void) {
        createGroupConversationNameStringUsersSetZMUserAllowGuestsBoolAllowServicesBoolEnableReceiptsBoolMessageProtocolMessageProtocolCompletionEscapingResultZMConversationConversationCreationFailureVoidVoidCallsCount += 1
        createGroupConversationNameStringUsersSetZMUserAllowGuestsBoolAllowServicesBoolEnableReceiptsBoolMessageProtocolMessageProtocolCompletionEscapingResultZMConversationConversationCreationFailureVoidVoidReceivedArguments = (name: name, users: users, allowGuests: allowGuests, allowServices: allowServices, enableReceipts: enableReceipts, messageProtocol: messageProtocol, completion: completion)
        createGroupConversationNameStringUsersSetZMUserAllowGuestsBoolAllowServicesBoolEnableReceiptsBoolMessageProtocolMessageProtocolCompletionEscapingResultZMConversationConversationCreationFailureVoidVoidReceivedInvocations.append((name: name, users: users, allowGuests: allowGuests, allowServices: allowServices, enableReceipts: enableReceipts, messageProtocol: messageProtocol, completion: completion))
        createGroupConversationNameStringUsersSetZMUserAllowGuestsBoolAllowServicesBoolEnableReceiptsBoolMessageProtocolMessageProtocolCompletionEscapingResultZMConversationConversationCreationFailureVoidVoidClosure?(name, users, allowGuests, allowServices, enableReceipts, messageProtocol, completion)
    }

    //MARK: - createTeamOneOnOneProteusConversation

    public var createTeamOneOnOneProteusConversationUserZMUserCompletionEscapingSwiftResultZMConversationConversationCreationFailureVoidVoidCallsCount = 0
    public var createTeamOneOnOneProteusConversationUserZMUserCompletionEscapingSwiftResultZMConversationConversationCreationFailureVoidVoidCalled: Bool {
        return createTeamOneOnOneProteusConversationUserZMUserCompletionEscapingSwiftResultZMConversationConversationCreationFailureVoidVoidCallsCount > 0
    }
    public var createTeamOneOnOneProteusConversationUserZMUserCompletionEscapingSwiftResultZMConversationConversationCreationFailureVoidVoidReceivedArguments: (user: ZMUser, completion: (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void)?
    public var createTeamOneOnOneProteusConversationUserZMUserCompletionEscapingSwiftResultZMConversationConversationCreationFailureVoidVoidReceivedInvocations: [(user: ZMUser, completion: (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void)] = []
    public var createTeamOneOnOneProteusConversationUserZMUserCompletionEscapingSwiftResultZMConversationConversationCreationFailureVoidVoidClosure: ((ZMUser, @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void) -> Void)?

    public func createTeamOneOnOneProteusConversation(user: ZMUser, completion: @escaping (Swift.Result<ZMConversation, ConversationCreationFailure>) -> Void) {
        createTeamOneOnOneProteusConversationUserZMUserCompletionEscapingSwiftResultZMConversationConversationCreationFailureVoidVoidCallsCount += 1
        createTeamOneOnOneProteusConversationUserZMUserCompletionEscapingSwiftResultZMConversationConversationCreationFailureVoidVoidReceivedArguments = (user: user, completion: completion)
        createTeamOneOnOneProteusConversationUserZMUserCompletionEscapingSwiftResultZMConversationConversationCreationFailureVoidVoidReceivedInvocations.append((user: user, completion: completion))
        createTeamOneOnOneProteusConversationUserZMUserCompletionEscapingSwiftResultZMConversationConversationCreationFailureVoidVoidClosure?(user, completion)
    }

    //MARK: - syncConversation

    public var syncConversationQualifiedIDQualifiedIDCompletionEscapingVoidVoidCallsCount = 0
    public var syncConversationQualifiedIDQualifiedIDCompletionEscapingVoidVoidCalled: Bool {
        return syncConversationQualifiedIDQualifiedIDCompletionEscapingVoidVoidCallsCount > 0
    }
    public var syncConversationQualifiedIDQualifiedIDCompletionEscapingVoidVoidReceivedArguments: (qualifiedID: QualifiedID, completion: () -> Void)?
    public var syncConversationQualifiedIDQualifiedIDCompletionEscapingVoidVoidReceivedInvocations: [(qualifiedID: QualifiedID, completion: () -> Void)] = []
    public var syncConversationQualifiedIDQualifiedIDCompletionEscapingVoidVoidClosure: ((QualifiedID, @escaping () -> Void) -> Void)?

    public func syncConversation(qualifiedID: QualifiedID, completion: @escaping () -> Void) {
        syncConversationQualifiedIDQualifiedIDCompletionEscapingVoidVoidCallsCount += 1
        syncConversationQualifiedIDQualifiedIDCompletionEscapingVoidVoidReceivedArguments = (qualifiedID: qualifiedID, completion: completion)
        syncConversationQualifiedIDQualifiedIDCompletionEscapingVoidVoidReceivedInvocations.append((qualifiedID: qualifiedID, completion: completion))
        syncConversationQualifiedIDQualifiedIDCompletionEscapingVoidVoidClosure?(qualifiedID, completion)
    }

    //MARK: - syncConversation

    public var syncConversationQualifiedIDQualifiedIDVoidCallsCount = 0
    public var syncConversationQualifiedIDQualifiedIDVoidCalled: Bool {
        return syncConversationQualifiedIDQualifiedIDVoidCallsCount > 0
    }
    public var syncConversationQualifiedIDQualifiedIDVoidReceivedQualifiedID: (QualifiedID)?
    public var syncConversationQualifiedIDQualifiedIDVoidReceivedInvocations: [(QualifiedID)] = []
    public var syncConversationQualifiedIDQualifiedIDVoidClosure: ((QualifiedID) async -> Void)?

    public func syncConversation(qualifiedID: QualifiedID) async {
        syncConversationQualifiedIDQualifiedIDVoidCallsCount += 1
        syncConversationQualifiedIDQualifiedIDVoidReceivedQualifiedID = qualifiedID
        syncConversationQualifiedIDQualifiedIDVoidReceivedInvocations.append(qualifiedID)
        await syncConversationQualifiedIDQualifiedIDVoidClosure?(qualifiedID)
    }

    //MARK: - syncConversationIfMissing

    public var syncConversationIfMissingQualifiedIDQualifiedIDVoidCallsCount = 0
    public var syncConversationIfMissingQualifiedIDQualifiedIDVoidCalled: Bool {
        return syncConversationIfMissingQualifiedIDQualifiedIDVoidCallsCount > 0
    }
    public var syncConversationIfMissingQualifiedIDQualifiedIDVoidReceivedQualifiedID: (QualifiedID)?
    public var syncConversationIfMissingQualifiedIDQualifiedIDVoidReceivedInvocations: [(QualifiedID)] = []
    public var syncConversationIfMissingQualifiedIDQualifiedIDVoidClosure: ((QualifiedID) async -> Void)?

    public func syncConversationIfMissing(qualifiedID: QualifiedID) async {
        syncConversationIfMissingQualifiedIDQualifiedIDVoidCallsCount += 1
        syncConversationIfMissingQualifiedIDQualifiedIDVoidReceivedQualifiedID = qualifiedID
        syncConversationIfMissingQualifiedIDQualifiedIDVoidReceivedInvocations.append(qualifiedID)
        await syncConversationIfMissingQualifiedIDQualifiedIDVoidClosure?(qualifiedID)
    }


}
public class E2EIKeyPackageRotatingMock: E2EIKeyPackageRotating {

    public init() {}



    //MARK: - rotateKeysAndMigrateConversations

    public var rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidThrowableError: (any Error)?
    public var rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidCallsCount = 0
    public var rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidCalled: Bool {
        return rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidCallsCount > 0
    }
    public var rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidReceivedArguments: (enrollment: E2eiEnrollmentProtocol, certificateChain: String)?
    public var rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidReceivedInvocations: [(enrollment: E2eiEnrollmentProtocol, certificateChain: String)] = []
    public var rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidClosure: ((E2eiEnrollmentProtocol, String) async throws -> Void)?

    public func rotateKeysAndMigrateConversations(enrollment: E2eiEnrollmentProtocol, certificateChain: String) async throws {
        rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidCallsCount += 1
        rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidReceivedArguments = (enrollment: enrollment, certificateChain: certificateChain)
        rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidReceivedInvocations.append((enrollment: enrollment, certificateChain: certificateChain))
        if let error = rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidThrowableError {
            throw error
        }
        try await rotateKeysAndMigrateConversationsEnrollmentE2eiEnrollmentProtocolCertificateChainStringVoidClosure?(enrollment, certificateChain)
    }


}
public class E2eIAPIMock: E2eIAPI {

    public init() {}



    //MARK: - getWireNonce

    public var getWireNonceClientIdStringStringThrowableError: (any Error)?
    public var getWireNonceClientIdStringStringCallsCount = 0
    public var getWireNonceClientIdStringStringCalled: Bool {
        return getWireNonceClientIdStringStringCallsCount > 0
    }
    public var getWireNonceClientIdStringStringReceivedClientId: (String)?
    public var getWireNonceClientIdStringStringReceivedInvocations: [(String)] = []
    public var getWireNonceClientIdStringStringReturnValue: String!
    public var getWireNonceClientIdStringStringClosure: ((String) async throws -> String)?

    public func getWireNonce(clientId: String) async throws -> String {
        getWireNonceClientIdStringStringCallsCount += 1
        getWireNonceClientIdStringStringReceivedClientId = clientId
        getWireNonceClientIdStringStringReceivedInvocations.append(clientId)
        if let error = getWireNonceClientIdStringStringThrowableError {
            throw error
        }
        if let getWireNonceClientIdStringStringClosure = getWireNonceClientIdStringStringClosure {
            return try await getWireNonceClientIdStringStringClosure(clientId)
        } else {
            return getWireNonceClientIdStringStringReturnValue
        }
    }

    //MARK: - getAccessToken

    public var getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseThrowableError: (any Error)?
    public var getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseCallsCount = 0
    public var getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseCalled: Bool {
        return getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseCallsCount > 0
    }
    public var getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseReceivedArguments: (clientId: String, dpopToken: String)?
    public var getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseReceivedInvocations: [(clientId: String, dpopToken: String)] = []
    public var getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseReturnValue: AccessTokenResponse!
    public var getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseClosure: ((String, String) async throws -> AccessTokenResponse)?

    public func getAccessToken(clientId: String, dpopToken: String) async throws -> AccessTokenResponse {
        getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseCallsCount += 1
        getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseReceivedArguments = (clientId: clientId, dpopToken: dpopToken)
        getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseReceivedInvocations.append((clientId: clientId, dpopToken: dpopToken))
        if let error = getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseThrowableError {
            throw error
        }
        if let getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseClosure = getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseClosure {
            return try await getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseClosure(clientId, dpopToken)
        } else {
            return getAccessTokenClientIdStringDpopTokenStringAccessTokenResponseReturnValue
        }
    }


}
public class EnrollE2EICertificateUseCaseProtocolMock: EnrollE2EICertificateUseCaseProtocol {

    public init() {}



    //MARK: - invoke

    public var invokeAuthenticateEscapingOAuthBlockStringThrowableError: (any Error)?
    public var invokeAuthenticateEscapingOAuthBlockStringCallsCount = 0
    public var invokeAuthenticateEscapingOAuthBlockStringCalled: Bool {
        return invokeAuthenticateEscapingOAuthBlockStringCallsCount > 0
    }
    public var invokeAuthenticateEscapingOAuthBlockStringReceivedAuthenticate: ((OAuthBlock))?
    public var invokeAuthenticateEscapingOAuthBlockStringReceivedInvocations: [((OAuthBlock))] = []
    public var invokeAuthenticateEscapingOAuthBlockStringReturnValue: String!
    public var invokeAuthenticateEscapingOAuthBlockStringClosure: ((@escaping OAuthBlock) async throws -> String)?

    public func invoke(authenticate: @escaping OAuthBlock) async throws -> String {
        invokeAuthenticateEscapingOAuthBlockStringCallsCount += 1
        invokeAuthenticateEscapingOAuthBlockStringReceivedAuthenticate = authenticate
        invokeAuthenticateEscapingOAuthBlockStringReceivedInvocations.append(authenticate)
        if let error = invokeAuthenticateEscapingOAuthBlockStringThrowableError {
            throw error
        }
        if let invokeAuthenticateEscapingOAuthBlockStringClosure = invokeAuthenticateEscapingOAuthBlockStringClosure {
            return try await invokeAuthenticateEscapingOAuthBlockStringClosure(authenticate)
        } else {
            return invokeAuthenticateEscapingOAuthBlockStringReturnValue
        }
    }


}
public class EventDecoderProtocolMock: EventDecoderProtocol {

    public init() {}



    //MARK: - decryptAndStoreEvents

    public var decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventThrowableError: (any Error)?
    public var decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventCallsCount = 0
    public var decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventCalled: Bool {
        return decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventCallsCount > 0
    }
    public var decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventReceivedArguments: (events: [ZMUpdateEvent], publicKeys: EARPublicKeys?)?
    public var decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventReceivedInvocations: [(events: [ZMUpdateEvent], publicKeys: EARPublicKeys?)] = []
    public var decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventReturnValue: [ZMUpdateEvent]!
    public var decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventClosure: (([ZMUpdateEvent], EARPublicKeys?) async throws -> [ZMUpdateEvent])?

    public func decryptAndStoreEvents(_ events: [ZMUpdateEvent], publicKeys: EARPublicKeys?) async throws -> [ZMUpdateEvent] {
        decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventCallsCount += 1
        decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventReceivedArguments = (events: events, publicKeys: publicKeys)
        decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventReceivedInvocations.append((events: events, publicKeys: publicKeys))
        if let error = decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventThrowableError {
            throw error
        }
        if let decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventClosure = decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventClosure {
            return try await decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventClosure(events, publicKeys)
        } else {
            return decryptAndStoreEventsEventsZMUpdateEventPublicKeysEARPublicKeysZMUpdateEventReturnValue
        }
    }

    //MARK: - processStoredEvents

    public var processStoredEventsWithPrivateKeysEARPrivateKeysCallEventsOnlyBoolBlockEscapingZMUpdateEventAsyncVoidVoidCallsCount = 0
    public var processStoredEventsWithPrivateKeysEARPrivateKeysCallEventsOnlyBoolBlockEscapingZMUpdateEventAsyncVoidVoidCalled: Bool {
        return processStoredEventsWithPrivateKeysEARPrivateKeysCallEventsOnlyBoolBlockEscapingZMUpdateEventAsyncVoidVoidCallsCount > 0
    }
    public var processStoredEventsWithPrivateKeysEARPrivateKeysCallEventsOnlyBoolBlockEscapingZMUpdateEventAsyncVoidVoidReceivedArguments: (privateKeys: EARPrivateKeys?, callEventsOnly: Bool, block: ([ZMUpdateEvent]) async -> Void)?
    public var processStoredEventsWithPrivateKeysEARPrivateKeysCallEventsOnlyBoolBlockEscapingZMUpdateEventAsyncVoidVoidReceivedInvocations: [(privateKeys: EARPrivateKeys?, callEventsOnly: Bool, block: ([ZMUpdateEvent]) async -> Void)] = []
    public var processStoredEventsWithPrivateKeysEARPrivateKeysCallEventsOnlyBoolBlockEscapingZMUpdateEventAsyncVoidVoidClosure: ((EARPrivateKeys?, Bool, @escaping ([ZMUpdateEvent]) async -> Void) async -> Void)?

    public func processStoredEvents(with privateKeys: EARPrivateKeys?, callEventsOnly: Bool, _ block: @escaping ([ZMUpdateEvent]) async -> Void) async {
        processStoredEventsWithPrivateKeysEARPrivateKeysCallEventsOnlyBoolBlockEscapingZMUpdateEventAsyncVoidVoidCallsCount += 1
        processStoredEventsWithPrivateKeysEARPrivateKeysCallEventsOnlyBoolBlockEscapingZMUpdateEventAsyncVoidVoidReceivedArguments = (privateKeys: privateKeys, callEventsOnly: callEventsOnly, block: block)
        processStoredEventsWithPrivateKeysEARPrivateKeysCallEventsOnlyBoolBlockEscapingZMUpdateEventAsyncVoidVoidReceivedInvocations.append((privateKeys: privateKeys, callEventsOnly: callEventsOnly, block: block))
        await processStoredEventsWithPrivateKeysEARPrivateKeysCallEventsOnlyBoolBlockEscapingZMUpdateEventAsyncVoidVoidClosure?(privateKeys, callEventsOnly, block)
    }


}
class MLSClientIDsProvidingMock: MLSClientIDsProviding {




    //MARK: - fetchUserClients

    var fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDThrowableError: (any Error)?
    var fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDCallsCount = 0
    var fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDCalled: Bool {
        return fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDCallsCount > 0
    }
    var fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDReceivedArguments: (userID: QualifiedID, context: NotificationContext)?
    var fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDReceivedInvocations: [(userID: QualifiedID, context: NotificationContext)] = []
    var fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDReturnValue: [MLSClientID]!
    var fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDClosure: ((QualifiedID, NotificationContext) async throws -> [MLSClientID])?

    func fetchUserClients(for userID: QualifiedID, in context: NotificationContext) async throws -> [MLSClientID] {
        fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDCallsCount += 1
        fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDReceivedArguments = (userID: userID, context: context)
        fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDReceivedInvocations.append((userID: userID, context: context))
        if let error = fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDThrowableError {
            throw error
        }
        if let fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDClosure = fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDClosure {
            return try await fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDClosure(userID, context)
        } else {
            return fetchUserClientsForUserIDQualifiedIDInContextNotificationContextMLSClientIDReturnValue
        }
    }


}
class MLSConversationParticipantsServiceInterfaceMock: MLSConversationParticipantsServiceInterface {




    //MARK: - addParticipants

    var addParticipantsUsersZMUserToConversationZMConversationVoidThrowableError: (any Error)?
    var addParticipantsUsersZMUserToConversationZMConversationVoidCallsCount = 0
    var addParticipantsUsersZMUserToConversationZMConversationVoidCalled: Bool {
        return addParticipantsUsersZMUserToConversationZMConversationVoidCallsCount > 0
    }
    var addParticipantsUsersZMUserToConversationZMConversationVoidReceivedArguments: (users: [ZMUser], conversation: ZMConversation)?
    var addParticipantsUsersZMUserToConversationZMConversationVoidReceivedInvocations: [(users: [ZMUser], conversation: ZMConversation)] = []
    var addParticipantsUsersZMUserToConversationZMConversationVoidClosure: (([ZMUser], ZMConversation) async throws -> Void)?

    func addParticipants(_ users: [ZMUser], to conversation: ZMConversation) async throws {
        addParticipantsUsersZMUserToConversationZMConversationVoidCallsCount += 1
        addParticipantsUsersZMUserToConversationZMConversationVoidReceivedArguments = (users: users, conversation: conversation)
        addParticipantsUsersZMUserToConversationZMConversationVoidReceivedInvocations.append((users: users, conversation: conversation))
        if let error = addParticipantsUsersZMUserToConversationZMConversationVoidThrowableError {
            throw error
        }
        try await addParticipantsUsersZMUserToConversationZMConversationVoidClosure?(users, conversation)
    }

    //MARK: - removeParticipant

    var removeParticipantUserZMUserFromConversationZMConversationVoidThrowableError: (any Error)?
    var removeParticipantUserZMUserFromConversationZMConversationVoidCallsCount = 0
    var removeParticipantUserZMUserFromConversationZMConversationVoidCalled: Bool {
        return removeParticipantUserZMUserFromConversationZMConversationVoidCallsCount > 0
    }
    var removeParticipantUserZMUserFromConversationZMConversationVoidReceivedArguments: (user: ZMUser, conversation: ZMConversation)?
    var removeParticipantUserZMUserFromConversationZMConversationVoidReceivedInvocations: [(user: ZMUser, conversation: ZMConversation)] = []
    var removeParticipantUserZMUserFromConversationZMConversationVoidClosure: ((ZMUser, ZMConversation) async throws -> Void)?

    func removeParticipant(_ user: ZMUser, from conversation: ZMConversation) async throws {
        removeParticipantUserZMUserFromConversationZMConversationVoidCallsCount += 1
        removeParticipantUserZMUserFromConversationZMConversationVoidReceivedArguments = (user: user, conversation: conversation)
        removeParticipantUserZMUserFromConversationZMConversationVoidReceivedInvocations.append((user: user, conversation: conversation))
        if let error = removeParticipantUserZMUserFromConversationZMConversationVoidThrowableError {
            throw error
        }
        try await removeParticipantUserZMUserFromConversationZMConversationVoidClosure?(user, conversation)
    }


}
public class MLSEventProcessingMock: MLSEventProcessing {

    public init() {}



    //MARK: - updateConversationIfNeeded

    public var updateConversationIfNeededConversationZMConversationFallbackGroupIDMLSGroupIDContextNSManagedObjectContextVoidCallsCount = 0
    public var updateConversationIfNeededConversationZMConversationFallbackGroupIDMLSGroupIDContextNSManagedObjectContextVoidCalled: Bool {
        return updateConversationIfNeededConversationZMConversationFallbackGroupIDMLSGroupIDContextNSManagedObjectContextVoidCallsCount > 0
    }
    public var updateConversationIfNeededConversationZMConversationFallbackGroupIDMLSGroupIDContextNSManagedObjectContextVoidReceivedArguments: (conversation: ZMConversation, fallbackGroupID: MLSGroupID?, context: NSManagedObjectContext)?
    public var updateConversationIfNeededConversationZMConversationFallbackGroupIDMLSGroupIDContextNSManagedObjectContextVoidReceivedInvocations: [(conversation: ZMConversation, fallbackGroupID: MLSGroupID?, context: NSManagedObjectContext)] = []
    public var updateConversationIfNeededConversationZMConversationFallbackGroupIDMLSGroupIDContextNSManagedObjectContextVoidClosure: ((ZMConversation, MLSGroupID?, NSManagedObjectContext) async -> Void)?

    public func updateConversationIfNeeded(conversation: ZMConversation, fallbackGroupID: MLSGroupID?, context: NSManagedObjectContext) async {
        updateConversationIfNeededConversationZMConversationFallbackGroupIDMLSGroupIDContextNSManagedObjectContextVoidCallsCount += 1
        updateConversationIfNeededConversationZMConversationFallbackGroupIDMLSGroupIDContextNSManagedObjectContextVoidReceivedArguments = (conversation: conversation, fallbackGroupID: fallbackGroupID, context: context)
        updateConversationIfNeededConversationZMConversationFallbackGroupIDMLSGroupIDContextNSManagedObjectContextVoidReceivedInvocations.append((conversation: conversation, fallbackGroupID: fallbackGroupID, context: context))
        await updateConversationIfNeededConversationZMConversationFallbackGroupIDMLSGroupIDContextNSManagedObjectContextVoidClosure?(conversation, fallbackGroupID, context)
    }

    //MARK: - process

    public var processWelcomeMessageStringConversationIDQualifiedIDInContextNSManagedObjectContextVoidCallsCount = 0
    public var processWelcomeMessageStringConversationIDQualifiedIDInContextNSManagedObjectContextVoidCalled: Bool {
        return processWelcomeMessageStringConversationIDQualifiedIDInContextNSManagedObjectContextVoidCallsCount > 0
    }
    public var processWelcomeMessageStringConversationIDQualifiedIDInContextNSManagedObjectContextVoidReceivedArguments: (welcomeMessage: String, conversationID: QualifiedID, context: NSManagedObjectContext)?
    public var processWelcomeMessageStringConversationIDQualifiedIDInContextNSManagedObjectContextVoidReceivedInvocations: [(welcomeMessage: String, conversationID: QualifiedID, context: NSManagedObjectContext)] = []
    public var processWelcomeMessageStringConversationIDQualifiedIDInContextNSManagedObjectContextVoidClosure: ((String, QualifiedID, NSManagedObjectContext) async -> Void)?

    public func process(welcomeMessage: String, conversationID: QualifiedID, in context: NSManagedObjectContext) async {
        processWelcomeMessageStringConversationIDQualifiedIDInContextNSManagedObjectContextVoidCallsCount += 1
        processWelcomeMessageStringConversationIDQualifiedIDInContextNSManagedObjectContextVoidReceivedArguments = (welcomeMessage: welcomeMessage, conversationID: conversationID, context: context)
        processWelcomeMessageStringConversationIDQualifiedIDInContextNSManagedObjectContextVoidReceivedInvocations.append((welcomeMessage: welcomeMessage, conversationID: conversationID, context: context))
        await processWelcomeMessageStringConversationIDQualifiedIDInContextNSManagedObjectContextVoidClosure?(welcomeMessage, conversationID, context)
    }

    //MARK: - wipeMLSGroup

    public var wipeMLSGroupForConversationConversationZMConversationContextNSManagedObjectContextVoidCallsCount = 0
    public var wipeMLSGroupForConversationConversationZMConversationContextNSManagedObjectContextVoidCalled: Bool {
        return wipeMLSGroupForConversationConversationZMConversationContextNSManagedObjectContextVoidCallsCount > 0
    }
    public var wipeMLSGroupForConversationConversationZMConversationContextNSManagedObjectContextVoidReceivedArguments: (conversation: ZMConversation, context: NSManagedObjectContext)?
    public var wipeMLSGroupForConversationConversationZMConversationContextNSManagedObjectContextVoidReceivedInvocations: [(conversation: ZMConversation, context: NSManagedObjectContext)] = []
    public var wipeMLSGroupForConversationConversationZMConversationContextNSManagedObjectContextVoidClosure: ((ZMConversation, NSManagedObjectContext) async -> Void)?

    public func wipeMLSGroup(forConversation conversation: ZMConversation, context: NSManagedObjectContext) async {
        wipeMLSGroupForConversationConversationZMConversationContextNSManagedObjectContextVoidCallsCount += 1
        wipeMLSGroupForConversationConversationZMConversationContextNSManagedObjectContextVoidReceivedArguments = (conversation: conversation, context: context)
        wipeMLSGroupForConversationConversationZMConversationContextNSManagedObjectContextVoidReceivedInvocations.append((conversation: conversation, context: context))
        await wipeMLSGroupForConversationConversationZMConversationContextNSManagedObjectContextVoidClosure?(conversation, context)
    }


}
public class MessageAPIMock: MessageAPI {

    public init() {}



    //MARK: - broadcastProteusMessage

    public var broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseThrowableError: (any Error)?
    public var broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseCallsCount = 0
    public var broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseCalled: Bool {
        return broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseCallsCount > 0
    }
    public var broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseReceivedEncryptedMessage: (Data)?
    public var broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseReceivedInvocations: [(Data)] = []
    public var broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseReturnValue: (Payload.MessageSendingStatus, ZMTransportResponse)!
    public var broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseClosure: ((Data) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse))?

    public func broadcastProteusMessage(message encryptedMessage: Data) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseCallsCount += 1
        broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseReceivedEncryptedMessage = encryptedMessage
        broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseReceivedInvocations.append(encryptedMessage)
        if let error = broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseThrowableError {
            throw error
        }
        if let broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseClosure = broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseClosure {
            return try await broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseClosure(encryptedMessage)
        } else {
            return broadcastProteusMessageMessageEncryptedMessageData_PayloadMessageSendingStatusZMTransportResponseReturnValue
        }
    }

    //MARK: - sendProteusMessage

    public var sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseThrowableError: (any Error)?
    public var sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseCallsCount = 0
    public var sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseCalled: Bool {
        return sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseCallsCount > 0
    }
    public var sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseReceivedArguments: (encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?)?
    public var sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseReceivedInvocations: [(encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?)] = []
    public var sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseReturnValue: (Payload.MessageSendingStatus, ZMTransportResponse)!
    public var sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseClosure: ((Data, QualifiedID, Date?) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse))?

    public func sendProteusMessage(message encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseCallsCount += 1
        sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseReceivedArguments = (encryptedMessage: encryptedMessage, conversationID: conversationID, expirationDate: expirationDate)
        sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseReceivedInvocations.append((encryptedMessage: encryptedMessage, conversationID: conversationID, expirationDate: expirationDate))
        if let error = sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseThrowableError {
            throw error
        }
        if let sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseClosure = sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseClosure {
            return try await sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseClosure(encryptedMessage, conversationID, expirationDate)
        } else {
            return sendProteusMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMessageSendingStatusZMTransportResponseReturnValue
        }
    }

    //MARK: - sendMLSMessage

    public var sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseThrowableError: (any Error)?
    public var sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseCallsCount = 0
    public var sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseCalled: Bool {
        return sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseCallsCount > 0
    }
    public var sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseReceivedArguments: (encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?)?
    public var sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseReceivedInvocations: [(encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?)] = []
    public var sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseReturnValue: (Payload.MLSMessageSendingStatus, ZMTransportResponse)!
    public var sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseClosure: ((Data, QualifiedID, Date?) async throws -> (Payload.MLSMessageSendingStatus, ZMTransportResponse))?

    public func sendMLSMessage(message encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?) async throws -> (Payload.MLSMessageSendingStatus, ZMTransportResponse) {
        sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseCallsCount += 1
        sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseReceivedArguments = (encryptedMessage: encryptedMessage, conversationID: conversationID, expirationDate: expirationDate)
        sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseReceivedInvocations.append((encryptedMessage: encryptedMessage, conversationID: conversationID, expirationDate: expirationDate))
        if let error = sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseThrowableError {
            throw error
        }
        if let sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseClosure = sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseClosure {
            return try await sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseClosure(encryptedMessage, conversationID, expirationDate)
        } else {
            return sendMLSMessageMessageEncryptedMessageDataConversationIDQualifiedIDExpirationDateDate_PayloadMLSMessageSendingStatusZMTransportResponseReturnValue
        }
    }


}
public class MessageDependencyResolverInterfaceMock: MessageDependencyResolverInterface {

    public init() {}



    //MARK: - waitForDependenciesToResolve

    public var waitForDependenciesToResolveForMessageAnySendableMessageVoidThrowableError: (any Error)?
    public var waitForDependenciesToResolveForMessageAnySendableMessageVoidCallsCount = 0
    public var waitForDependenciesToResolveForMessageAnySendableMessageVoidCalled: Bool {
        return waitForDependenciesToResolveForMessageAnySendableMessageVoidCallsCount > 0
    }
    public var waitForDependenciesToResolveForMessageAnySendableMessageVoidReceivedMessage: (any SendableMessage)?
    public var waitForDependenciesToResolveForMessageAnySendableMessageVoidReceivedInvocations: [(any SendableMessage)] = []
    public var waitForDependenciesToResolveForMessageAnySendableMessageVoidClosure: ((any SendableMessage) async throws -> Void)?

    public func waitForDependenciesToResolve(for message: any SendableMessage) async throws {
        waitForDependenciesToResolveForMessageAnySendableMessageVoidCallsCount += 1
        waitForDependenciesToResolveForMessageAnySendableMessageVoidReceivedMessage = message
        waitForDependenciesToResolveForMessageAnySendableMessageVoidReceivedInvocations.append(message)
        if let error = waitForDependenciesToResolveForMessageAnySendableMessageVoidThrowableError {
            throw error
        }
        try await waitForDependenciesToResolveForMessageAnySendableMessageVoidClosure?(message)
    }


}
public class MessageSenderInterfaceMock: MessageSenderInterface {

    public init() {}



    //MARK: - sendMessage

    public var sendMessageMessageAnySendableMessageVoidThrowableError: (any Error)?
    public var sendMessageMessageAnySendableMessageVoidCallsCount = 0
    public var sendMessageMessageAnySendableMessageVoidCalled: Bool {
        return sendMessageMessageAnySendableMessageVoidCallsCount > 0
    }
    public var sendMessageMessageAnySendableMessageVoidReceivedMessage: (any SendableMessage)?
    public var sendMessageMessageAnySendableMessageVoidReceivedInvocations: [(any SendableMessage)] = []
    public var sendMessageMessageAnySendableMessageVoidClosure: ((any SendableMessage) async throws -> Void)?

    public func sendMessage(message: any SendableMessage) async throws {
        sendMessageMessageAnySendableMessageVoidCallsCount += 1
        sendMessageMessageAnySendableMessageVoidReceivedMessage = message
        sendMessageMessageAnySendableMessageVoidReceivedInvocations.append(message)
        if let error = sendMessageMessageAnySendableMessageVoidThrowableError {
            throw error
        }
        try await sendMessageMessageAnySendableMessageVoidClosure?(message)
    }

    //MARK: - broadcastMessage

    public var broadcastMessageMessageAnyProteusMessageVoidThrowableError: (any Error)?
    public var broadcastMessageMessageAnyProteusMessageVoidCallsCount = 0
    public var broadcastMessageMessageAnyProteusMessageVoidCalled: Bool {
        return broadcastMessageMessageAnyProteusMessageVoidCallsCount > 0
    }
    public var broadcastMessageMessageAnyProteusMessageVoidReceivedMessage: (any ProteusMessage)?
    public var broadcastMessageMessageAnyProteusMessageVoidReceivedInvocations: [(any ProteusMessage)] = []
    public var broadcastMessageMessageAnyProteusMessageVoidClosure: ((any ProteusMessage) async throws -> Void)?

    public func broadcastMessage(message: any ProteusMessage) async throws {
        broadcastMessageMessageAnyProteusMessageVoidCallsCount += 1
        broadcastMessageMessageAnyProteusMessageVoidReceivedMessage = message
        broadcastMessageMessageAnyProteusMessageVoidReceivedInvocations.append(message)
        if let error = broadcastMessageMessageAnyProteusMessageVoidThrowableError {
            throw error
        }
        try await broadcastMessageMessageAnyProteusMessageVoidClosure?(message)
    }


}
public class PrekeyAPIMock: PrekeyAPI {

    public init() {}



    //MARK: - fetchPrekeys

    public var fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyThrowableError: (any Error)?
    public var fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyCallsCount = 0
    public var fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyCalled: Bool {
        return fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyCallsCount > 0
    }
    public var fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyReceivedClients: (Set<QualifiedClientID>)?
    public var fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyReceivedInvocations: [(Set<QualifiedClientID>)] = []
    public var fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyReturnValue: Payload.PrekeyByQualifiedUserID!
    public var fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyClosure: ((Set<QualifiedClientID>) async throws -> Payload.PrekeyByQualifiedUserID)?

    public func fetchPrekeys(for clients: Set<QualifiedClientID>) async throws -> Payload.PrekeyByQualifiedUserID {
        fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyCallsCount += 1
        fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyReceivedClients = clients
        fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyReceivedInvocations.append(clients)
        if let error = fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyThrowableError {
            throw error
        }
        if let fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyClosure = fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyClosure {
            return try await fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyClosure(clients)
        } else {
            return fetchPrekeysForClientsSetQualifiedClientIDStringStringStringPayloadPrekeyReturnValue
        }
    }


}
public class PrekeyPayloadProcessorInterfaceMock: PrekeyPayloadProcessorInterface {

    public init() {}



    //MARK: - establishSessions

    public var establishSessionsFromPayloadPayloadPrekeyByQualifiedUserIDWithSelfClientUserClientContextNSManagedObjectContextVoidCallsCount = 0
    public var establishSessionsFromPayloadPayloadPrekeyByQualifiedUserIDWithSelfClientUserClientContextNSManagedObjectContextVoidCalled: Bool {
        return establishSessionsFromPayloadPayloadPrekeyByQualifiedUserIDWithSelfClientUserClientContextNSManagedObjectContextVoidCallsCount > 0
    }
    public var establishSessionsFromPayloadPayloadPrekeyByQualifiedUserIDWithSelfClientUserClientContextNSManagedObjectContextVoidReceivedArguments: (payload: Payload.PrekeyByQualifiedUserID, selfClient: UserClient, context: NSManagedObjectContext)?
    public var establishSessionsFromPayloadPayloadPrekeyByQualifiedUserIDWithSelfClientUserClientContextNSManagedObjectContextVoidReceivedInvocations: [(payload: Payload.PrekeyByQualifiedUserID, selfClient: UserClient, context: NSManagedObjectContext)] = []
    public var establishSessionsFromPayloadPayloadPrekeyByQualifiedUserIDWithSelfClientUserClientContextNSManagedObjectContextVoidClosure: ((Payload.PrekeyByQualifiedUserID, UserClient, NSManagedObjectContext) async -> Void)?

    public func establishSessions(from payload: Payload.PrekeyByQualifiedUserID, with selfClient: UserClient, context: NSManagedObjectContext) async {
        establishSessionsFromPayloadPayloadPrekeyByQualifiedUserIDWithSelfClientUserClientContextNSManagedObjectContextVoidCallsCount += 1
        establishSessionsFromPayloadPayloadPrekeyByQualifiedUserIDWithSelfClientUserClientContextNSManagedObjectContextVoidReceivedArguments = (payload: payload, selfClient: selfClient, context: context)
        establishSessionsFromPayloadPayloadPrekeyByQualifiedUserIDWithSelfClientUserClientContextNSManagedObjectContextVoidReceivedInvocations.append((payload: payload, selfClient: selfClient, context: context))
        await establishSessionsFromPayloadPayloadPrekeyByQualifiedUserIDWithSelfClientUserClientContextNSManagedObjectContextVoidClosure?(payload, selfClient, context)
    }


}
class ProteusConversationParticipantsServiceInterfaceMock: ProteusConversationParticipantsServiceInterface {




    //MARK: - addParticipants

    var addParticipantsUsersZMUserToConversationZMConversationVoidThrowableError: (any Error)?
    var addParticipantsUsersZMUserToConversationZMConversationVoidCallsCount = 0
    var addParticipantsUsersZMUserToConversationZMConversationVoidCalled: Bool {
        return addParticipantsUsersZMUserToConversationZMConversationVoidCallsCount > 0
    }
    var addParticipantsUsersZMUserToConversationZMConversationVoidReceivedArguments: (users: [ZMUser], conversation: ZMConversation)?
    var addParticipantsUsersZMUserToConversationZMConversationVoidReceivedInvocations: [(users: [ZMUser], conversation: ZMConversation)] = []
    var addParticipantsUsersZMUserToConversationZMConversationVoidClosure: (([ZMUser], ZMConversation) async throws -> Void)?

    func addParticipants(_ users: [ZMUser], to conversation: ZMConversation) async throws {
        addParticipantsUsersZMUserToConversationZMConversationVoidCallsCount += 1
        addParticipantsUsersZMUserToConversationZMConversationVoidReceivedArguments = (users: users, conversation: conversation)
        addParticipantsUsersZMUserToConversationZMConversationVoidReceivedInvocations.append((users: users, conversation: conversation))
        if let error = addParticipantsUsersZMUserToConversationZMConversationVoidThrowableError {
            throw error
        }
        try await addParticipantsUsersZMUserToConversationZMConversationVoidClosure?(users, conversation)
    }

    //MARK: - removeParticipant

    var removeParticipantUserZMUserFromConversationZMConversationVoidThrowableError: (any Error)?
    var removeParticipantUserZMUserFromConversationZMConversationVoidCallsCount = 0
    var removeParticipantUserZMUserFromConversationZMConversationVoidCalled: Bool {
        return removeParticipantUserZMUserFromConversationZMConversationVoidCallsCount > 0
    }
    var removeParticipantUserZMUserFromConversationZMConversationVoidReceivedArguments: (user: ZMUser, conversation: ZMConversation)?
    var removeParticipantUserZMUserFromConversationZMConversationVoidReceivedInvocations: [(user: ZMUser, conversation: ZMConversation)] = []
    var removeParticipantUserZMUserFromConversationZMConversationVoidClosure: ((ZMUser, ZMConversation) async throws -> Void)?

    func removeParticipant(_ user: ZMUser, from conversation: ZMConversation) async throws {
        removeParticipantUserZMUserFromConversationZMConversationVoidCallsCount += 1
        removeParticipantUserZMUserFromConversationZMConversationVoidReceivedArguments = (user: user, conversation: conversation)
        removeParticipantUserZMUserFromConversationZMConversationVoidReceivedInvocations.append((user: user, conversation: conversation))
        if let error = removeParticipantUserZMUserFromConversationZMConversationVoidThrowableError {
            throw error
        }
        try await removeParticipantUserZMUserFromConversationZMConversationVoidClosure?(user, conversation)
    }


}
public class ProteusMessageMock: ProteusMessage {

    public init() {}

    public var shouldExpire: Bool {
        get { return underlyingShouldExpire }
        set(value) { underlyingShouldExpire = value }
    }
    public var underlyingShouldExpire: (Bool)!
    public var underlyingMessage: GenericMessage?
    public var targetRecipients: Recipients {
        get { return underlyingTargetRecipients }
        set(value) { underlyingTargetRecipients = value }
    }
    public var underlyingTargetRecipients: (Recipients)!
    public var context: NSManagedObjectContext {
        get { return underlyingContext }
        set(value) { underlyingContext = value }
    }
    public var underlyingContext: (NSManagedObjectContext)!
    public var conversation: ZMConversation?
    public var dependentObjectNeedingUpdateBeforeProcessing: NSObject?
    public var isExpired: Bool {
        get { return underlyingIsExpired }
        set(value) { underlyingIsExpired = value }
    }
    public var underlyingIsExpired: (Bool)!
    public var shouldIgnoreTheSecurityLevelCheck: Bool {
        get { return underlyingShouldIgnoreTheSecurityLevelCheck }
        set(value) { underlyingShouldIgnoreTheSecurityLevelCheck = value }
    }
    public var underlyingShouldIgnoreTheSecurityLevelCheck: (Bool)!
    public var expirationDate: Date?
    public var expirationReasonCode: NSNumber?


    //MARK: - setExpirationDate

    public var setExpirationDateVoidCallsCount = 0
    public var setExpirationDateVoidCalled: Bool {
        return setExpirationDateVoidCallsCount > 0
    }
    public var setExpirationDateVoidClosure: (() -> Void)?

    public func setExpirationDate() {
        setExpirationDateVoidCallsCount += 1
        setExpirationDateVoidClosure?()
    }

    //MARK: - prepareMessageForSending

    public var prepareMessageForSendingVoidThrowableError: (any Error)?
    public var prepareMessageForSendingVoidCallsCount = 0
    public var prepareMessageForSendingVoidCalled: Bool {
        return prepareMessageForSendingVoidCallsCount > 0
    }
    public var prepareMessageForSendingVoidClosure: (() async throws -> Void)?

    public func prepareMessageForSending() async throws {
        prepareMessageForSendingVoidCallsCount += 1
        if let error = prepareMessageForSendingVoidThrowableError {
            throw error
        }
        try await prepareMessageForSendingVoidClosure?()
    }

    //MARK: - setUnderlyingMessage

    public var setUnderlyingMessageMessageGenericMessageVoidThrowableError: (any Error)?
    public var setUnderlyingMessageMessageGenericMessageVoidCallsCount = 0
    public var setUnderlyingMessageMessageGenericMessageVoidCalled: Bool {
        return setUnderlyingMessageMessageGenericMessageVoidCallsCount > 0
    }
    public var setUnderlyingMessageMessageGenericMessageVoidReceivedMessage: (GenericMessage)?
    public var setUnderlyingMessageMessageGenericMessageVoidReceivedInvocations: [(GenericMessage)] = []
    public var setUnderlyingMessageMessageGenericMessageVoidClosure: ((GenericMessage) throws -> Void)?

    public func setUnderlyingMessage(_ message: GenericMessage) throws {
        setUnderlyingMessageMessageGenericMessageVoidCallsCount += 1
        setUnderlyingMessageMessageGenericMessageVoidReceivedMessage = message
        setUnderlyingMessageMessageGenericMessageVoidReceivedInvocations.append(message)
        if let error = setUnderlyingMessageMessageGenericMessageVoidThrowableError {
            throw error
        }
        try setUnderlyingMessageMessageGenericMessageVoidClosure?(message)
    }

    //MARK: - missesRecipients

    public var missesRecipientsRecipientsSetWireDataModelUserClientVoidCallsCount = 0
    public var missesRecipientsRecipientsSetWireDataModelUserClientVoidCalled: Bool {
        return missesRecipientsRecipientsSetWireDataModelUserClientVoidCallsCount > 0
    }
    public var missesRecipientsRecipientsSetWireDataModelUserClientVoidReceivedRecipients: (Set<WireDataModel.UserClient>)?
    public var missesRecipientsRecipientsSetWireDataModelUserClientVoidReceivedInvocations: [(Set<WireDataModel.UserClient>)] = []
    public var missesRecipientsRecipientsSetWireDataModelUserClientVoidClosure: ((Set<WireDataModel.UserClient>) -> Void)?

    public func missesRecipients(_ recipients: Set<WireDataModel.UserClient>) {
        missesRecipientsRecipientsSetWireDataModelUserClientVoidCallsCount += 1
        missesRecipientsRecipientsSetWireDataModelUserClientVoidReceivedRecipients = recipients
        missesRecipientsRecipientsSetWireDataModelUserClientVoidReceivedInvocations.append(recipients)
        missesRecipientsRecipientsSetWireDataModelUserClientVoidClosure?(recipients)
    }

    //MARK: - detectedRedundantUsers

    public var detectedRedundantUsersUsersZMUserVoidCallsCount = 0
    public var detectedRedundantUsersUsersZMUserVoidCalled: Bool {
        return detectedRedundantUsersUsersZMUserVoidCallsCount > 0
    }
    public var detectedRedundantUsersUsersZMUserVoidReceivedUsers: ([ZMUser])?
    public var detectedRedundantUsersUsersZMUserVoidReceivedInvocations: [([ZMUser])] = []
    public var detectedRedundantUsersUsersZMUserVoidClosure: (([ZMUser]) -> Void)?

    public func detectedRedundantUsers(_ users: [ZMUser]) {
        detectedRedundantUsersUsersZMUserVoidCallsCount += 1
        detectedRedundantUsersUsersZMUserVoidReceivedUsers = users
        detectedRedundantUsersUsersZMUserVoidReceivedInvocations.append(users)
        detectedRedundantUsersUsersZMUserVoidClosure?(users)
    }

    //MARK: - delivered

    public var deliveredWithResponseZMTransportResponseVoidCallsCount = 0
    public var deliveredWithResponseZMTransportResponseVoidCalled: Bool {
        return deliveredWithResponseZMTransportResponseVoidCallsCount > 0
    }
    public var deliveredWithResponseZMTransportResponseVoidReceivedResponse: (ZMTransportResponse)?
    public var deliveredWithResponseZMTransportResponseVoidReceivedInvocations: [(ZMTransportResponse)] = []
    public var deliveredWithResponseZMTransportResponseVoidClosure: ((ZMTransportResponse) -> Void)?

    public func delivered(with response: ZMTransportResponse) {
        deliveredWithResponseZMTransportResponseVoidCallsCount += 1
        deliveredWithResponseZMTransportResponseVoidReceivedResponse = response
        deliveredWithResponseZMTransportResponseVoidReceivedInvocations.append(response)
        deliveredWithResponseZMTransportResponseVoidClosure?(response)
    }

    //MARK: - addFailedToSendRecipients

    public var addFailedToSendRecipientsRecipientsZMUserVoidCallsCount = 0
    public var addFailedToSendRecipientsRecipientsZMUserVoidCalled: Bool {
        return addFailedToSendRecipientsRecipientsZMUserVoidCallsCount > 0
    }
    public var addFailedToSendRecipientsRecipientsZMUserVoidReceivedRecipients: ([ZMUser])?
    public var addFailedToSendRecipientsRecipientsZMUserVoidReceivedInvocations: [([ZMUser])] = []
    public var addFailedToSendRecipientsRecipientsZMUserVoidClosure: (([ZMUser]) -> Void)?

    public func addFailedToSendRecipients(_ recipients: [ZMUser]) {
        addFailedToSendRecipientsRecipientsZMUserVoidCallsCount += 1
        addFailedToSendRecipientsRecipientsZMUserVoidReceivedRecipients = recipients
        addFailedToSendRecipientsRecipientsZMUserVoidReceivedInvocations.append(recipients)
        addFailedToSendRecipientsRecipientsZMUserVoidClosure?(recipients)
    }

    //MARK: - expire

    public var expireWithReasonReasonExpirationReasonVoidCallsCount = 0
    public var expireWithReasonReasonExpirationReasonVoidCalled: Bool {
        return expireWithReasonReasonExpirationReasonVoidCallsCount > 0
    }
    public var expireWithReasonReasonExpirationReasonVoidReceivedReason: (ExpirationReason)?
    public var expireWithReasonReasonExpirationReasonVoidReceivedInvocations: [(ExpirationReason)] = []
    public var expireWithReasonReasonExpirationReasonVoidClosure: ((ExpirationReason) -> Void)?

    public func expire(withReason reason: ExpirationReason) {
        expireWithReasonReasonExpirationReasonVoidCallsCount += 1
        expireWithReasonReasonExpirationReasonVoidReceivedReason = reason
        expireWithReasonReasonExpirationReasonVoidReceivedInvocations.append(reason)
        expireWithReasonReasonExpirationReasonVoidClosure?(reason)
    }


}
public class QuickSyncObserverInterfaceMock: QuickSyncObserverInterface {

    public init() {}



    //MARK: - waitForQuickSyncToFinish

    public var waitForQuickSyncToFinishVoidCallsCount = 0
    public var waitForQuickSyncToFinishVoidCalled: Bool {
        return waitForQuickSyncToFinishVoidCallsCount > 0
    }
    public var waitForQuickSyncToFinishVoidClosure: (() async -> Void)?

    public func waitForQuickSyncToFinish() async {
        waitForQuickSyncToFinishVoidCallsCount += 1
        await waitForQuickSyncToFinishVoidClosure?()
    }


}
public class SessionEstablisherInterfaceMock: SessionEstablisherInterface {

    public init() {}



    //MARK: - establishSession

    public var establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidThrowableError: (any Error)?
    public var establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidCallsCount = 0
    public var establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidCalled: Bool {
        return establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidCallsCount > 0
    }
    public var establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidReceivedArguments: (clients: Set<QualifiedClientID>, apiVersion: APIVersion)?
    public var establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidReceivedInvocations: [(clients: Set<QualifiedClientID>, apiVersion: APIVersion)] = []
    public var establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidClosure: ((Set<QualifiedClientID>, APIVersion) async throws -> Void)?

    public func establishSession(with clients: Set<QualifiedClientID>, apiVersion: APIVersion) async throws {
        establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidCallsCount += 1
        establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidReceivedArguments = (clients: clients, apiVersion: apiVersion)
        establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidReceivedInvocations.append((clients: clients, apiVersion: apiVersion))
        if let error = establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidThrowableError {
            throw error
        }
        try await establishSessionWithClientsSetQualifiedClientIDApiVersionAPIVersionVoidClosure?(clients, apiVersion)
    }


}
public class SyncProgressMock: SyncProgress {

    public init() {}

    public var currentSyncPhase: SyncPhase {
        get { return underlyingCurrentSyncPhase }
        set(value) { underlyingCurrentSyncPhase = value }
    }
    public var underlyingCurrentSyncPhase: (SyncPhase)!


    //MARK: - finishCurrentSyncPhase

    public var finishCurrentSyncPhasePhaseSyncPhaseVoidCallsCount = 0
    public var finishCurrentSyncPhasePhaseSyncPhaseVoidCalled: Bool {
        return finishCurrentSyncPhasePhaseSyncPhaseVoidCallsCount > 0
    }
    public var finishCurrentSyncPhasePhaseSyncPhaseVoidReceivedPhase: (SyncPhase)?
    public var finishCurrentSyncPhasePhaseSyncPhaseVoidReceivedInvocations: [(SyncPhase)] = []
    public var finishCurrentSyncPhasePhaseSyncPhaseVoidClosure: ((SyncPhase) -> Void)?

    public func finishCurrentSyncPhase(phase: SyncPhase) {
        finishCurrentSyncPhasePhaseSyncPhaseVoidCallsCount += 1
        finishCurrentSyncPhasePhaseSyncPhaseVoidReceivedPhase = phase
        finishCurrentSyncPhasePhaseSyncPhaseVoidReceivedInvocations.append(phase)
        finishCurrentSyncPhasePhaseSyncPhaseVoidClosure?(phase)
    }

    //MARK: - failCurrentSyncPhase

    public var failCurrentSyncPhasePhaseSyncPhaseVoidCallsCount = 0
    public var failCurrentSyncPhasePhaseSyncPhaseVoidCalled: Bool {
        return failCurrentSyncPhasePhaseSyncPhaseVoidCallsCount > 0
    }
    public var failCurrentSyncPhasePhaseSyncPhaseVoidReceivedPhase: (SyncPhase)?
    public var failCurrentSyncPhasePhaseSyncPhaseVoidReceivedInvocations: [(SyncPhase)] = []
    public var failCurrentSyncPhasePhaseSyncPhaseVoidClosure: ((SyncPhase) -> Void)?

    public func failCurrentSyncPhase(phase: SyncPhase) {
        failCurrentSyncPhasePhaseSyncPhaseVoidCallsCount += 1
        failCurrentSyncPhasePhaseSyncPhaseVoidReceivedPhase = phase
        failCurrentSyncPhasePhaseSyncPhaseVoidReceivedInvocations.append(phase)
        failCurrentSyncPhasePhaseSyncPhaseVoidClosure?(phase)
    }


}
public class UserClientAPIMock: UserClientAPI {

    public init() {}



    //MARK: - deleteUserClient

    public var deleteUserClientClientIdStringPasswordStringVoidThrowableError: (any Error)?
    public var deleteUserClientClientIdStringPasswordStringVoidCallsCount = 0
    public var deleteUserClientClientIdStringPasswordStringVoidCalled: Bool {
        return deleteUserClientClientIdStringPasswordStringVoidCallsCount > 0
    }
    public var deleteUserClientClientIdStringPasswordStringVoidReceivedArguments: (clientId: String, password: String)?
    public var deleteUserClientClientIdStringPasswordStringVoidReceivedInvocations: [(clientId: String, password: String)] = []
    public var deleteUserClientClientIdStringPasswordStringVoidClosure: ((String, String) async throws -> Void)?

    public func deleteUserClient(clientId: String, password: String) async throws {
        deleteUserClientClientIdStringPasswordStringVoidCallsCount += 1
        deleteUserClientClientIdStringPasswordStringVoidReceivedArguments = (clientId: clientId, password: password)
        deleteUserClientClientIdStringPasswordStringVoidReceivedInvocations.append((clientId: clientId, password: password))
        if let error = deleteUserClientClientIdStringPasswordStringVoidThrowableError {
            throw error
        }
        try await deleteUserClientClientIdStringPasswordStringVoidClosure?(clientId, password)
    }


}
class UserProfilePayloadProcessingMock: UserProfilePayloadProcessing {




    //MARK: - updateUserProfiles

    var updateUserProfilesFromUserProfilesPayloadUserProfilesInContextNSManagedObjectContextVoidCallsCount = 0
    var updateUserProfilesFromUserProfilesPayloadUserProfilesInContextNSManagedObjectContextVoidCalled: Bool {
        return updateUserProfilesFromUserProfilesPayloadUserProfilesInContextNSManagedObjectContextVoidCallsCount > 0
    }
    var updateUserProfilesFromUserProfilesPayloadUserProfilesInContextNSManagedObjectContextVoidReceivedArguments: (userProfiles: Payload.UserProfiles, context: NSManagedObjectContext)?
    var updateUserProfilesFromUserProfilesPayloadUserProfilesInContextNSManagedObjectContextVoidReceivedInvocations: [(userProfiles: Payload.UserProfiles, context: NSManagedObjectContext)] = []
    var updateUserProfilesFromUserProfilesPayloadUserProfilesInContextNSManagedObjectContextVoidClosure: ((Payload.UserProfiles, NSManagedObjectContext) -> Void)?

    func updateUserProfiles(from userProfiles: Payload.UserProfiles, in context: NSManagedObjectContext) {
        updateUserProfilesFromUserProfilesPayloadUserProfilesInContextNSManagedObjectContextVoidCallsCount += 1
        updateUserProfilesFromUserProfilesPayloadUserProfilesInContextNSManagedObjectContextVoidReceivedArguments = (userProfiles: userProfiles, context: context)
        updateUserProfilesFromUserProfilesPayloadUserProfilesInContextNSManagedObjectContextVoidReceivedInvocations.append((userProfiles: userProfiles, context: context))
        updateUserProfilesFromUserProfilesPayloadUserProfilesInContextNSManagedObjectContextVoidClosure?(userProfiles, context)
    }


}
// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
