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

import WireTransport
import XCTest
@testable import WireDataModelSupport
@testable import WireRequestStrategySupport

final class MessageSenderTests: MessagingTestBase {
    struct Arrangement {
        // MARK: Lifecycle

        init(coreDataStack: CoreDataStack) {
            self.coreDataStack = coreDataStack

            apiProvider.messageAPIApiVersion_MockValue = messageApi
        }

        // MARK: Internal

        enum Scaffolding {
            static let groupID = MLSGroupID(.init([1, 2, 3]))
            static let clientID = QualifiedClientID(userID: UUID(), domain: "example.com", clientID: "client123")
            static let responseSuccess = ZMTransportResponse(
                payload: nil,
                httpStatus: 201,
                transportSessionError: nil,
                apiVersion: 0
            )
            static let messageSendingStatusSuccess = Payload.MessageSendingStatus(
                time: Date(),
                missing: [:],
                redundant: [:],
                deleted: [:],
                failedToSend: [:],
                failedToConfirm: [:]
            )
            static let messageSendingStatusMissingClients = Payload.MessageSendingStatus(
                time: Date(),
                missing: [clientID.domain: [clientID.userID.transportString(): [clientID.clientID]]],
                redundant: [:],
                deleted: [:],
                failedToSend: [:],
                failedToConfirm: [:]
            )
        }

        let selfUserId = UUID()
        let apiProvider = MockAPIProviderInterface()
        let messageApi = MockMessageAPI()
        let processor = MockPrekeyPayloadProcessorInterface()
        let clientRegistrationDelegate = MockClientRegistrationStatus()
        let sessionEstablisher = MockSessionEstablisherInterface()
        let messageDependencyResolver = MockMessageDependencyResolverInterface()
        let quickSyncObserver = MockQuickSyncObserverInterface()
        let mlsService = MockMLSServiceInterface()
        let coreDataStack: CoreDataStack

        func withApiVersionResolving(to apiVersion: APIVersion?) -> Arrangement {
            BackendInfo.apiVersion = apiVersion
            return self
        }

        func withQuickSyncObserverCompleting() -> Arrangement {
            quickSyncObserver.waitForQuickSyncToFinish_MockMethod = {}
            return self
        }

        func withMessageDependencyResolverReturning(result: Result<Void, MessageDependencyResolverError>)
            -> Arrangement {
            messageDependencyResolver.waitForDependenciesToResolveFor_MockMethod = { _ in
                if case let .failure(error) = result {
                    throw error
                }
            }
            return self
        }

        func withBroadcastProteusMessageFailing(with error: NetworkError) -> Arrangement {
            messageApi.broadcastProteusMessageMessage_MockMethod = { [weak messageApi] _ in
                if let count = messageApi?.broadcastProteusMessageMessage_Invocations.count, count > 1 {
                    return (Scaffolding.messageSendingStatusSuccess, Scaffolding.responseSuccess)
                } else {
                    throw error
                }
            }
            return self
        }

        func withSendProteusMessageFailing(with error: NetworkError) -> Arrangement {
            messageApi.sendProteusMessageMessageConversationID_MockMethod = { [weak messageApi] _, _ in
                if let count = messageApi?.sendProteusMessageMessageConversationID_Invocations.count, count > 1 {
                    return (Scaffolding.messageSendingStatusSuccess, Scaffolding.responseSuccess)
                } else {
                    throw error
                }
            }
            return self
        }

        func withMLServiceConfigured() -> Arrangement {
            coreDataStack.syncContext.performAndWait {
                coreDataStack.syncContext.mlsService = mlsService
            }
            return self
        }

        func withEstablishSessions(returning result: Result<Void, SessionEstablisherError>) -> Arrangement {
            switch result {
            case .success:
                sessionEstablisher.establishSessionWithApiVersion_MockMethod = { _, _ in }
            case let .failure(error):
                sessionEstablisher.establishSessionWithApiVersion_MockError = error
            }
            return self
        }

        func withBroadcastProteusMessage(returning result: Result<
            (Payload.MessageSendingStatus, ZMTransportResponse),
            NetworkError
        >) -> Arrangement {
            switch result {
            case let .success(value):
                messageApi.broadcastProteusMessageMessage_MockValue = value
            case let .failure(error):
                messageApi.broadcastProteusMessageMessage_MockError = error
            }
            return self
        }

        func withSendProteusMessage(returning result: Result<
            (Payload.MessageSendingStatus, ZMTransportResponse),
            NetworkError
        >) -> Arrangement {
            switch result {
            case let .success(value):
                messageApi.sendProteusMessageMessageConversationID_MockValue = value
            case let .failure(error):
                messageApi.sendProteusMessageMessageConversationID_MockError = error
            }
            return self
        }

        func withSendMlsMessage(returning result: Result<
            (Payload.MLSMessageSendingStatus, ZMTransportResponse),
            NetworkError
        >) -> Arrangement {
            switch result {
            case let .success(value):
                messageApi.sendMLSMessageMessageConversationIDExpirationDate_MockValue = value
            case let .failure(error):
                messageApi.sendMLSMessageMessageConversationIDExpirationDate_MockError = error
            }
            return self
        }

        func arrange() -> (Arrangement, MessageSender) {
            (self, MessageSender(
                apiProvider: apiProvider,
                clientRegistrationDelegate: clientRegistrationDelegate,
                sessionEstablisher: sessionEstablisher,
                messageDependencyResolver: messageDependencyResolver,
                quickSyncObserver: quickSyncObserver,
                context: coreDataStack.syncContext
            ))
        }
    }

    override func setUp() {
        super.setUp()

        BackendInfo.apiVersion = .v0
    }

    func testThatWhenSecurityLevelIsDegraded_thenFailWithSecurityLevelDegraded() async throws {
        // given
        await syncMOC.perform { [self] in
            groupConversation?.setPrimitiveValue(
                NSNumber(value: ZMConversationSecurityLevel.secureWithIgnored.rawValue), forKey: "securityLevel"
            )
        }

        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .failure(.securityLevelDegraded))
            .arrange()

        // then
        await assertItThrows(error: MessageDependencyResolverError.securityLevelDegraded) {
            try await messageSender.sendMessage(message: message)
        }
    }

    func testThatBeforeSendingMessage_thenCallDependencyResolver() async throws {
        // given
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: nil)
            .arrange()

        // when
        try? await messageSender.sendMessage(message: message)

        // then
        XCTAssertEqual(1, arrangement.messageDependencyResolver.waitForDependenciesToResolveFor_Invocations.count)
    }

    func testThatBeforeSendingMessage_thenWaitForQuickSyncToFinish() async throws {
        // given
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: nil)
            .arrange()

        // when
        try? await messageSender.sendMessage(message: message)

        // then
        XCTAssertEqual(1, arrangement.quickSyncObserver.waitForQuickSyncToFinish_Invocations.count)
    }

    func testThatWhenApiVersionIsNotResolved_thenFailWithUnresolvedApiVersion() async throws {
        // given
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: nil)
            .arrange()

        // then
        await assertItThrows(error: MessageSendError.unresolvedApiVersion) {
            try await messageSender.sendMessage(message: message)
        }
    }

    func testThatWhenBroadcastingProteusMessageSucceeds_thenCompleteWithoutErrors() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: 0)
        let messageSendingStatus = Payload.MessageSendingStatus(
            time: Date(),
            missing: [:],
            redundant: [:],
            deleted: [:],
            failedToSend: [:],
            failedToConfirm: [:]
        )

        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withApiVersionResolving(to: .v0)
            .withBroadcastProteusMessage(returning: .success((messageSendingStatus, response)))
            .arrange()

        // when
        try await messageSender.broadcastMessage(message: message)

        // then test completes
    }

    func testThatWhenBroadcastingProteusMessageFailsDueToMissingClients_thenEstablishSessionsAndTryAgain() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 412, transportSessionError: nil, apiVersion: 0)
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withApiVersionResolving(to: .v0)
            .withBroadcastProteusMessageFailing(with: NetworkError.missingClients(
                Arrangement.Scaffolding.messageSendingStatusMissingClients,
                response
            ))
            .withEstablishSessions(returning: .success(()))
            .arrange()

        // when
        try await messageSender.broadcastMessage(message: message)

        // then
        XCTAssertEqual(
            [Arrangement.Scaffolding.clientID],
            arrangement.sessionEstablisher.establishSessionWithApiVersion_Invocations[0].clients
        )
    }

    func testThatWhenBroadcastingMessageProteusFailsWithTemporaryError_thenTryAgain() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 408, transportSessionError: nil, apiVersion: 0)
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withApiVersionResolving(to: .v0)
            .withBroadcastProteusMessageFailing(with: NetworkError.errorDecodingResponse(response))
            .withEstablishSessions(returning: .success(()))
            .arrange()

        // when
        try await messageSender.broadcastMessage(message: message)

        // then
        XCTAssertEqual(2, arrangement.messageApi.broadcastProteusMessageMessage_Invocations.count)
    }

    func testThatWhenSendingProteusMessageSucceeds_thenCompleteWithoutErrors() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: 0)
        let messageSendingStatus = Payload.MessageSendingStatus(
            time: Date(),
            missing: [:],
            redundant: [:],
            deleted: [:],
            failedToSend: [:],
            failedToConfirm: [:]
        )

        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessage(returning: .success((messageSendingStatus, response)))
            .arrange()

        // when
        try await messageSender.sendMessage(message: message)

        // then test completes
    }

    func testThatWhenSendingProteusMessageFailsDueToMissingClients_thenEstablishSessionsAndTryAgain() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 412, transportSessionError: nil, apiVersion: 0)
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: NetworkError.missingClients(
                Arrangement.Scaffolding.messageSendingStatusMissingClients,
                response
            ))
            .withEstablishSessions(returning: .success(()))
            .arrange()

        // when
        try await messageSender.sendMessage(message: message)

        // then
        XCTAssertEqual(
            [Arrangement.Scaffolding.clientID],
            arrangement.sessionEstablisher.establishSessionWithApiVersion_Invocations[0].clients
        )
    }

    func testThatWhenSendingMessageProteusFailsWithTemporaryError_thenTryAgain() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 408, transportSessionError: nil, apiVersion: 0)
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: NetworkError.errorDecodingResponse(response))
            .withEstablishSessions(returning: .success(()))
            .arrange()

        // when
        try await messageSender.sendMessage(message: message)

        // then
        XCTAssertEqual(2, arrangement.messageApi.sendProteusMessageMessageConversationID_Invocations.count)
    }

    func testThatWhenSendingProteusMessageFailsWithTemporaryErrorButHasExpired_thenThrowError() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 408, transportSessionError: nil, apiVersion: 0)
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )
        message.isExpired = true

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: NetworkError.errorDecodingResponse(response))
            .arrange()

        // then
        await assertItThrows(error: MessageSendError.messageExpired) {
            try await messageSender.sendMessage(message: message)
        }
    }

    func testThatWhenSendingProteusMessageFailsWithPermanentError_thenReturnFailure() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 403, transportSessionError: nil, apiVersion: 0)
        let networkError = NetworkError.errorDecodingResponse(response)
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: networkError)
            .arrange()

        // then
        await assertItThrows(error: networkError) {
            try await messageSender.sendMessage(message: message)
        }
    }

    func testThatWhenSendingProteusMessageFailsWithFederationRemoteError_thenUpdateExpirationReasonCode() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 533, transportSessionError: nil, apiVersion: 0)
        let federationFailure = Payload.ResponseFailure.FederationFailure(
            domain: "",
            path: "",
            type: .federation
        )
        let responseFailure = Payload.ResponseFailure(
            code: 533,
            label: .federationRemoteError,
            message: "",
            data: federationFailure
        )
        let networkError = NetworkError.invalidRequestError(responseFailure, response)
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: networkError)
            .arrange()

        // when
        await assertItThrows(error: networkError) {
            try await messageSender.sendMessage(message: message)
        }

        // then
        XCTAssertEqual(NSNumber(value: MessageSendFailure.federationRemoteError.rawValue), message.expirationReasonCode)
    }

    func testThatWhenSendingProteusMessageFailsWithUnknownFederationError_thenUpdateExpirationReasonCode() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 533, transportSessionError: nil, apiVersion: 0)
        let federationFailure = Payload.ResponseFailure.FederationFailure(
            domain: "",
            path: "",
            type: .unknown
        )
        let responseFailure = Payload.ResponseFailure(
            code: 533,
            label: .federationRemoteError,
            message: "",
            data: federationFailure
        )
        let networkError = NetworkError.invalidRequestError(responseFailure, response)
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: networkError)
            .arrange()

        // when
        await assertItThrows(error: networkError) {
            try await messageSender.sendMessage(message: message)
        }

        // then
        XCTAssertEqual(NSNumber(value: MessageSendFailure.unknown.rawValue), message.expirationReasonCode)
    }

    func testThatWhenSendingMlsMessageSucceeds_thenCompleteWithoutErrors() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
        }
        let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: 0)
        let messageSendingStatus = Payload.MLSMessageSendingStatus(
            time: Date(),
            events: [],
            failedToSend: nil
        )

        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured()
            .withSendMlsMessage(returning: .success((messageSendingStatus, response)))
            .arrange()
        arrangement.mlsService.commitPendingProposalsIn_MockMethod = { _ in }
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        // when
        try await messageSender.sendMessage(message: message)

        // then test completes
    }

    func testThatWhenSendingMlsMessageSucceeds_thenCommitPendingProposalsInGroup() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
        }
        let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: 0)
        let messageSendingStatus = Payload.MLSMessageSendingStatus(
            time: Date(),
            events: [],
            failedToSend: nil
        )

        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured()
            .withSendMlsMessage(returning: .success((messageSendingStatus, response)))
            .arrange()
        arrangement.mlsService.commitPendingProposalsIn_MockMethod = { _ in }
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        // when
        try await messageSender.sendMessage(message: message)

        // then
        XCTAssertEqual([Arrangement.Scaffolding.groupID], arrangement.mlsService.commitPendingProposalsIn_Invocations)
    }

    func testThatWhenSendingMlsMessageFailsWithPermanentError_thenThrowError() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
        }
        let response = ZMTransportResponse(payload: nil, httpStatus: 403, transportSessionError: nil, apiVersion: 0)
        let networkError = NetworkError.errorDecodingResponse(response)
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured()
            .withSendMlsMessage(returning: .failure(networkError))
            .arrange()
        arrangement.mlsService.commitPendingProposalsIn_MockMethod = { _ in }
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        // then
        await assertItThrows(error: networkError) {
            try await messageSender.sendMessage(message: message)
        }
    }

    func testThatWhenSendingMlsMessageWithoutMlsService_thenThrowError() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
        }
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .arrange()

        // then
        await assertItThrows(error: MessageSendError.missingMlsService) {
            try await messageSender.sendMessage(message: message)
        }
    }

    func testThatWhenSendingMlsMessageWithoutGroupID_thenThrowError() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.messageProtocol = .mls
        }
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withQuickSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured()
            .arrange()

        // then
        await assertItThrows(error: MessageSendError.missingGroupID) {
            try await messageSender.sendMessage(message: message)
        }
    }
}
