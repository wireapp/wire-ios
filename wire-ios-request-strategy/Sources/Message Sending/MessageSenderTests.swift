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

import GenericMessageProtocol
import WireCoreCrypto
import WireTransport
import XCTest

@testable import WireDataModelSupport
@testable import WireRequestStrategySupport

final class MessageSenderTests: MessagingTestBase {

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
            .withIncrementalSyncObserverCompleting()
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
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: nil)
            .arrange()

        // when
        try? await messageSender.sendMessage(message: message)

        // then
        XCTAssertEqual(1, arrangement.messageDependencyResolver.waitForDependenciesToResolveFor_Invocations.count)
    }

    func testThatBeforeSendingMessage_thenWaitForDecryptionOfEventsToFinish() async throws {
        // given
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: nil)
            .arrange()

        // when
        try? await messageSender.sendMessage(message: message)

        // then
        XCTAssertEqual(1, arrangement.incrementalSyncObserver.waitUntilCanSendMessage_Invocations.count)
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
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: nil)
            .arrange()

        // then
        await assertItThrows(error: MessageSendError.unresolvedApiVersion) {
            try await messageSender.sendMessage(message: message)
        }
    }

    // MARK: - Broadcasting

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

        let message = await broadcastMessage()

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withProteusConfigured()
            .withIncrementalSyncObserverCompleting()
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
        let message = await broadcastMessage()

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withProteusConfigured()
            .withIncrementalSyncObserverCompleting()
            .withApiVersionResolving(to: .v0)
            .withBroadcastProteusMessageFailing(
                with: NetworkError.missingClients(
                    Arrangement.Scaffolding.messageSendingStatusMissingClients,
                    response
                )
            )
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
        let message = await broadcastMessage()

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withProteusConfigured()
            .withIncrementalSyncObserverCompleting()
            .withApiVersionResolving(to: .v0)
            .withBroadcastProteusMessageFailing(with: NetworkError.errorDecodingResponse(response))
            .withEstablishSessions(returning: .success(()))
            .arrange()

        // when
        try await messageSender.broadcastMessage(message: message)

        // then
        XCTAssertEqual(2, arrangement.messageApi.broadcastProteusMessageMessage_Invocations.count)
    }

    // MARK: - Send Proteus Message

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
            .withProteusConfigured()
            .withIncrementalSyncObserverCompleting()
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
            .withProteusConfigured()
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(
                with: NetworkError.missingClients(
                    Arrangement.Scaffolding.messageSendingStatusMissingClients,
                    response
                )
            )
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
            .withProteusConfigured()
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: NetworkError.errorDecodingResponse(response))
            .withEstablishSessions(returning: .success(()))
            .arrange()

        // when
        try await messageSender.sendMessage(message: message)

        // then
        XCTAssertEqual(
            2,
            arrangement.messageApi.sendProteusMessageMessageConversationIDExpirationDate_Invocations.count
        )
    }

    func testThatWhenSendingProteusExpiredMessageFailsIndefinitely_thenThrowError() async throws {
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
            .withProteusConfigured()
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            // simulates a potential infinite loop when sending proteus message keeps failing
            .withSendProteusMessageFailing(with: NetworkError.errorDecodingResponse(response), failsIndefinitely: true)
            .arrange()

        // then
        await assertItThrows(error: MessageSendError.messageExpired) {
            // Ensures it breaks the loop and throws error
            try await messageSender.sendMessage(message: message)
        }
    }

    func testThatWhenSendingProteusMessageFailsIndefinitely_thenThrowError() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 408, transportSessionError: nil, apiVersion: 0)
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )
        message.isExpired = false

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withProteusConfigured()
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            // simulates a potential infinite loop when sending proteus message keeps failing
            .withSendProteusMessageFailing(with: NetworkError.errorDecodingResponse(response), failsIndefinitely: true)
            .arrange()

        // then
        await assertItThrows(error: MessageSendError.failed(NetworkError.errorDecodingResponse(.init()))) {
            // Ensures it breaks the loop and throws error
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
            .withProteusConfigured()
            .withIncrementalSyncObserverCompleting()
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
            .withProteusConfigured()
            .withIncrementalSyncObserverCompleting()
            .withProteusConfigured()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: networkError)
            .arrange()

        // when
        await assertItThrows(error: networkError) {
            try await messageSender.sendMessage(message: message)
        }

        // then
        XCTAssertEqual(NSNumber(value: ExpirationReason.federationRemoteError.rawValue), message.expirationReasonCode)
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
            .withProteusConfigured()
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: networkError)
            .arrange()

        // when
        await assertItThrows(error: networkError) {
            try await messageSender.sendMessage(message: message)
        }

        // then
        XCTAssertEqual(NSNumber(value: ExpirationReason.other.rawValue), message.expirationReasonCode)
    }

    // MARK: - Send MLS Message

    func testThatWhenSendingMlsMessageSucceeds_thenCompleteWithoutErrors() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsStatus = .ready
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
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured()
            .withSendMlsMessage(returning: .success((messageSendingStatus, response)))
            .arrange()
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        // when
        try await messageSender.sendMessage(message: message)

        // then test completes
        XCTAssertEqual(arrangement.mlsService.reEstablishPendingGroupGroupID_Invocations.count, 0)
    }

    func testThatWhenSendingMlsMessageSucceeds_thenCommitPendingProposalsInGroup() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsStatus = .ready
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
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured()
            .withSendMlsMessage(returning: .success((messageSendingStatus, response)))
            .arrange()
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        // when
        try await messageSender.sendMessage(message: message)

        // then
        let invocation = try XCTUnwrap(arrangement.mlsService.commitPendingProposalsInSkipRetry_Invocations.first)
        XCTAssertEqual(Arrangement.Scaffolding.groupID, invocation.groupID)
        XCTAssertTrue(invocation.skipRetry)
        XCTAssertEqual(arrangement.mlsService.reEstablishPendingGroupGroupID_Invocations.count, 0)
    }

    func testThatWhenSendingMlsMessageFailsWithPermanentError_thenThrowError() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsStatus = .ready
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
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured()
            .withSendMlsMessage(returning: .failure(networkError))
            .arrange()
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        // then
        await assertItThrows(error: networkError) {
            try await messageSender.sendMessage(message: message)
        }
    }

    func testThatWhenSendingMlsMessageFailsWithMLSError_thenThrowError() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsStatus = .ready
        }
        let networkError = SendMLSMessageFailure.mlsMissingSenderClient(message: "test")
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured()
            .withSendMlsMessage(returning: .failure(networkError))
            .arrange()
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        // then
        await assertItThrows(error: networkError) {
            try await messageSender.sendMessage(message: message)
        }
    }

    func testThatWhenSendingMlsMessageFailsWithResetMLSConversationError_thenInitiatesReset() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsStatus = .ready
        }
        let networkError = SendMLSMessageFailure.mlsInvalidLeafNodeIndex(message: "Test")
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured()
            .withSendMlsMessage(returning: .failure(networkError))
            .arrange()
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        try await messageSender.sendMessage(message: message)

        XCTAssertEqual(arrangement.initiateResetMLSConversationUseCase.invokeGroupIDEpoch_Invocations.count, 1)
        let invocation = arrangement.initiateResetMLSConversationUseCase.invokeGroupIDEpoch_Invocations.first
        XCTAssertEqual(invocation?.epoch, 0)
        XCTAssertEqual(invocation?.groupID, Arrangement.Scaffolding.groupID)
        XCTAssertEqual(arrangement.mlsService.reEstablishPendingGroupGroupID_Invocations.count, 0)
    }

    func testThatWhenSendingMlsMessageFailsWithResetMLSConversationError_AndFeatureFlagIsOff_JustThrows() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsStatus = .ready
        }
        let networkError = SendMLSMessageFailure.mlsInvalidLeafNodeIndex(message: "Test")
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured()
            .withSendMlsMessage(returning: .failure(networkError))
            .withResetMLSConversationsFeatureOff()
            .arrange()
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        await assertItThrows(error: networkError) {
            try await messageSender.sendMessage(message: message)
        }

        XCTAssertEqual(arrangement.initiateResetMLSConversationUseCase.invokeGroupIDEpoch_Invocations.count, 0)
        XCTAssertEqual(arrangement.mlsService.reEstablishPendingGroupGroupID_Invocations.count, 0)
    }

    func testThatWhenSendingMlsMessageWithoutMlsService_thenThrowError() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsStatus = .ready
        }
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withIncrementalSyncObserverCompleting()
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
            self.groupConversation.mlsStatus = .ready
        }
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured()
            .arrange()

        // then
        await assertItThrows(error: MessageSendError.missingGroupID) {
            try await messageSender.sendMessage(message: message)
        }

        XCTAssertEqual(arrangement.mlsService.reEstablishPendingGroupGroupID_Invocations.count, 0)
    }

    func testThatWhenSendingMlsMessageOnAPendingJoinConversation_CallsReEstablishPendingJoin() async throws {
        // given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsStatus = .pendingJoinAfterReset
        }

        let domain = await syncMOC.perform {
            self.groupConversation.domain
        }
        let localDomain = try XCTUnwrap(domain)
        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )
        let response = ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: 0)
        let messageSendingStatus = Payload.MLSMessageSendingStatus(
            time: Date(),
            events: [],
            failedToSend: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v5)
            .withMLServiceConfigured(domain: localDomain)
            .withSendMlsMessage(returning: .success((messageSendingStatus, response)))
            .arrange()
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        try await messageSender.sendMessage(message: message)

        XCTAssertEqual(arrangement.mlsService.reEstablishPendingGroupGroupID_Invocations.count, 1)
    }

    func testThatWhenSendingMlsMessageOnAnOutOfSyncGroup_ItAddsMissingUsersAndTriesAgain() async throws {
        // Given
        await syncMOC.perform {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsStatus = .ready
        }

        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        // For failure.
        let id1 = QualifiedID.randomID()
        let id2 = QualifiedID.randomID()
        let missingUsers = Set([id1, id2])

        // For success.
        let response = ZMTransportResponse(
            payload: nil,
            httpStatus: 200,
            transportSessionError: nil,
            apiVersion: 0
        )
        let messageSendingStatus = Payload.MLSMessageSendingStatus(
            time: Date(),
            events: [],
            failedToSend: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v13)
            .withMLServiceConfigured()
            .withSendMlsMessageResults(returning: [
                .failure(SendMLSMessageFailure.groupOutOfSync(missingUsers: missingUsers)),
                .success((messageSendingStatus, response))
            ])
            .arrange()
        arrangement.mlsService.addMembersToConversationWithFor_MockMethod = { _, _ in }
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        // When
        try await messageSender.sendMessage(message: message)

        // Then
        // It tried to send once (but failed), then one more time after adding members.
        let sendMessageInvocations = arrangement.messageApi
            .sendMLSMessageMessageConversationIDExpirationDate_Invocations
        XCTAssertEqual(sendMessageInvocations.count, 2)
        XCTAssertEqual(arrangement.mlsService.addMembersToConversationWithFor_Invocations.count, 1)
    }

    func testThatWhenSendingMlsMessageOnAnOutOfSyncGroup_ItRetriesMax3Times() async throws {
        // Given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsStatus = .ready
        }

        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let id1 = QualifiedID.randomID()
        let id2 = QualifiedID.randomID()
        let missingUsers = Set([id1, id2])

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v13)
            .withMLServiceConfigured()
            .withSendMlsMessage(returning: .failure(SendMLSMessageFailure.groupOutOfSync(missingUsers: missingUsers)))
            .arrange()
        arrangement.mlsService.addMembersToConversationWithFor_MockMethod = { _, _ in }
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        // When
        await XCTAssertThrowsErrorAsync {
            try await messageSender.sendMessage(message: message)
        }

        // Then
        // It tried to send the message 4 times (initial + 3 retries)
        let sendMessageInvocations = arrangement.messageApi
            .sendMLSMessageMessageConversationIDExpirationDate_Invocations
        XCTAssertEqual(sendMessageInvocations.count, 4)
        XCTAssertEqual(arrangement.mlsService.addMembersToConversationWithFor_Invocations.count, 3)
    }

    func testThatWhenSendingMlsMessageCommitMissingReferences_ItRetriesMax3Times() async throws {
        // Given
        await syncMOC.performGrouped {
            self.groupConversation.mlsGroupID = Arrangement.Scaffolding.groupID
            self.groupConversation.messageProtocol = .mls
            self.groupConversation.mlsStatus = .ready
        }

        let message = GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            completionHandler: nil
        )

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withIncrementalSyncObserverCompleting()
            .withMessageDependencyResolverReturning(result: .success(()))
            .withApiVersionResolving(to: .v13)
            .withMLServiceConfigured()
            .arrange()
        let errorString = try XCTUnwrap(String(
            data: try JSONEncoder().encode(MLSTransportError.mlsCommitMissingReferences),
            encoding: .utf8
        ))
        arrangement.mlsService.commitPendingProposalsInSkipRetry_MockError = CoreCryptoError
            .Mls(mlsError: .MessageRejected(reason: errorString))
        arrangement.mlsService.encryptMessageFor_MockMethod = { message, _ in
            message + [000]
        }

        // When
        await XCTAssertThrowsErrorAsync {
            try await messageSender.sendMessage(message: message)
        }

        // Then
        // It tried to send the message 4 times (initial + 3 retries)
        XCTAssertEqual(arrangement.mlsService.commitPendingProposalsInSkipRetry_Invocations.count, 4)
    }

    // MARK: - Helpers

    private func broadcastMessage() async -> GenericMessageEntity {
        let users = await coreDataStack.syncContext.perform { [self] in
            let user = ZMUser.insertNewObject(in: coreDataStack.syncContext)
            user.remoteIdentifier = .create()
            user.domain = "example.com"
            let client = UserClient.insertNewObject(in: coreDataStack.syncContext)
            client.remoteIdentifier = .randomClientIdentifier()
            client.user = user
            return [user]
        }

        return GenericMessageEntity(
            message: GenericMessage(content: Text(content: "Hello World")),
            context: syncMOC,
            conversation: groupConversation,
            targetRecipients: .users(Set(users)),
            completionHandler: nil
        )
    }

    class Arrangement {

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
        let sessionEstablisher = MockSessionEstablisherInterface()
        let messageDependencyResolver = MockMessageDependencyResolverInterface()
        let incrementalSyncObserver = MockIncrementalSyncObserverProtocol()
        let mlsService = MockMLSServiceInterface()
        let proteusService = MockProteusServiceInterface()
        let coreDataStack: CoreDataStack
        let initiateResetMLSConversationUseCase = WireRequestStrategySupport
            .MockInitiateResetMLSConversationUseCaseProtocol()
        let featureRepository = MockLegacyFeatureRepositoryInterface()
        var apiVersion: APIVersion?

        init(coreDataStack: CoreDataStack) {
            self.coreDataStack = coreDataStack

            apiProvider.messageAPIApiVersion_MockValue = messageApi

            initiateResetMLSConversationUseCase.invokeGroupIDEpoch_MockMethod = { _, _ in }

            featureRepository.fetchAllowedGlobalOperations_MockValue = .init(
                status: .enabled,
                config: .init(mlsConversationReset: true)
            )
            mlsService.reEstablishPendingGroupGroupID_MockMethod = { _ in }

        }

        func withApiVersionResolving(to apiVersion: APIVersion?) -> Arrangement {
            self.apiVersion = apiVersion
            return self
        }

        func withIncrementalSyncObserverCompleting() -> Arrangement {
            incrementalSyncObserver.waitUntilCanSendMessage_MockMethod = {}
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

        func withSendProteusMessageFailing(with error: NetworkError, failsIndefinitely: Bool = false) -> Arrangement {
            messageApi.sendProteusMessageMessageConversationIDExpirationDate_MockMethod = { [weak messageApi] _, _, _ in
                if failsIndefinitely {
                    throw error
                } else {
                    if let count = messageApi?.sendProteusMessageMessageConversationIDExpirationDate_Invocations.count,
                       count > 1 {
                        return (Scaffolding.messageSendingStatusSuccess, Scaffolding.responseSuccess)
                    } else {
                        throw error
                    }
                }
            }

            return self
        }

        func withMLServiceConfigured(domain: String = "local.domain") -> Arrangement {
            coreDataStack.syncContext.performAndWait {
                coreDataStack.syncContext.mlsService = mlsService
            }
            mlsService.commitPendingProposalsInSkipRetry_MockMethod = { _, _ in }
            mlsService.underlyingLocalDomain = domain
            return self
        }

        func withResetMLSConversationsFeatureOff() -> Arrangement {
            featureRepository.fetchAllowedGlobalOperations_MockValue = .init(
                status: .disabled,
                config: .init(mlsConversationReset: false)
            )
            return self
        }

        func withProteusConfigured() -> Arrangement {
            coreDataStack.syncContext.performAndWait {
                coreDataStack.syncContext.proteusService = proteusService
                proteusService.encryptBatchedDataForSessions_MockMethod = { _, _ in
                    // success dumb data
                    ["test": Data()]
                }
                proteusService.sessionExistsId_MockValue = true
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
            Error
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
            Error
        >) -> Arrangement {

            switch result {
            case let .success(value):
                messageApi.sendProteusMessageMessageConversationIDExpirationDate_MockValue = value
            case let .failure(error):
                messageApi.sendProteusMessageMessageConversationIDExpirationDate_MockError = error
            }
            return self
        }

        func withSendMlsMessage(
            returning result: Result<(Payload.MLSMessageSendingStatus, ZMTransportResponse), Error>
        ) -> Arrangement {

            switch result {
            case let .success(value):
                messageApi.sendMLSMessageMessageConversationIDExpirationDate_MockValue = value
            case let .failure(error):
                messageApi.sendMLSMessageMessageConversationIDExpirationDate_MockError = error
            }
            return self
        }

        func withSendMlsMessageResults(
            returning results: [Result<(Payload.MLSMessageSendingStatus, ZMTransportResponse), Error>]
        ) -> Arrangement {
            var results = results
            messageApi.sendMLSMessageMessageConversationIDExpirationDate_MockMethod = { _, _, _ in
                guard !results.isEmpty else {
                    fatalError("no mocks left for send mls message")
                }

                switch results.removeFirst() {
                case let .success(value):
                    return value
                case let .failure(error):
                    throw error
                }
            }
            return self
        }

        func arrange() -> (Arrangement, MessageSender) {
            (
                self,
                MessageSender(
                    apiProvider: apiProvider,
                    sessionEstablisher: sessionEstablisher,
                    messageDependencyResolver: messageDependencyResolver,
                    context: coreDataStack.syncContext,
                    incrementalSyncObserver: incrementalSyncObserver,
                    initiateResetMLSConversationUseCase: initiateResetMLSConversationUseCase,
                    featureRepository: featureRepository,
                    apiVersion: apiVersion
                )
            )
        }
    }

}

extension MessageSendError: @retroactive Equatable {
    public static func == (lhs: MessageSendError, rhs: MessageSendError) -> Bool {
        switch (lhs, rhs) {
        case let (.failed(lhsError), .failed(rhsError)):
            lhsError as NSError == rhsError as NSError
        case (.missingMessageProtocol, .missingMessageProtocol):
            true
        case (.missingGroupID, .missingGroupID):
            true
        case (.missingQualifiedID, .missingQualifiedID):
            true
        case (.missingMlsService, .missingMlsService):
            true
        case (.unresolvedApiVersion, .unresolvedApiVersion):
            true
        case (.messageExpired, .messageExpired):
            true
        case (.missingProteusService, .missingProteusService):
            true
        default:
            false
        }
    }
}

struct MockInitiateResetMLSConversationUseCase: WireRequestStrategy.InitiateResetMLSConversationUseCaseProtocol {
    func invoke(groupID: WireDataModel.MLSGroupID, epoch: UInt64) async {}
}
