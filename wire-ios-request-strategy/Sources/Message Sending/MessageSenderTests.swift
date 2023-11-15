////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import XCTest

final class MessageSenderTests: MessagingTestBase {

    func testThatWhenSecurityLevelIsDegraded_thenFailWithSecurityLevelDegraded() async throws {
        // given
        syncMOC.performAndWait {
            groupConversation?.setPrimitiveValue(
                NSNumber(value: ZMConversationSecurityLevel.secureWithIgnored.rawValue), forKey: "securityLevel"
            )
        }

        let message = GenericMessageEntity(
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withMessageDependencyResolverReturning(result: .failure(.securityLevelDegraded))
            .arrange()

        // when
        let result = await messageSender.sendMessage(message: message)

        // then
        assertFailure(result: result, expectedFailure: MessageSendError.securityLevelDegraded)
    }

    func testThatBeforeSendingMessage_thenCallDependencyResolver() async throws {
        // given
        let message = GenericMessageEntity(
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withMessageDependencyResolverReturning(result: .success(Void()))
            .withApiVersionResolving(to: nil)
            .arrange()

        // when
        _ = await messageSender.sendMessage(message: message)

        // then
        XCTAssertEqual(1, arrangement.messageDependencyResolver.waitForDependenciesToResolveFor_Invocations.count)
    }

    func testThatWhenApiVersionIsNotResolved_thenFailWithUnresolvedApiVersion() async throws {
        // given
        let message = GenericMessageEntity(
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withMessageDependencyResolverReturning(result: .success(Void()))
            .withApiVersionResolving(to: nil)
            .arrange()

        // when
        let result = await messageSender.sendMessage(message: message)

        // then
        assertFailure(result: result, expectedFailure: MessageSendError.unresolvedApiVersion)
    }

    func testThatWhenSendingMessageSucceeds_thenReturnSuccessResult() async throws {
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
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withMessageDependencyResolverReturning(result: .success(Void()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessage(returning: .success((messageSendingStatus, response)))
            .arrange()

        // when
        let result = await messageSender.sendMessage(message: message)

        // then
        assertSuccess(result: result)
    }

    func testThatWhenSendingMessageFailsDueToMissingClients_thenEstablishSessionsAndTryAgain() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 412, transportSessionError: nil, apiVersion: 0)
        let message = GenericMessageEntity(
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withMessageDependencyResolverReturning(result: .success(Void()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: NetworkError.missingClients(
                Arrangement.Scaffolding.messageSendingStatusMissingClients,
                response)
            )
            .withEstablishSessions(returning: .success(Void()))
            .arrange()

        // when
        let result = await messageSender.sendMessage(message: message)

        // then
        assertSuccess(result: result)
        XCTAssertEqual(Set(arrayLiteral: Arrangement.Scaffolding.clientID), arrangement.sessionEstablisher.establishSessionWithApiVersion_Invocations[0].clients)

    }

    func testThatWhenSendingMessageFailsWithTemporaryError_thenTryAgain() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 408, transportSessionError: nil, apiVersion: 0)
        let message = GenericMessageEntity(
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)

        let (arrangement, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withMessageDependencyResolverReturning(result: .success(Void()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: NetworkError.errorDecodingResponse(response))
            .withEstablishSessions(returning: .success(Void()))
            .arrange()

        // when
        let result = await messageSender.sendMessage(message: message)

        // then
        assertSuccess(result: result)
        XCTAssertEqual(2, arrangement.messageApi.sendProteusMessageMessageConversationID_Invocations.count)
    }

    func testThatWhenSendingMessageFailsWithTemporaryErrorButHasExpired_thenReturnFailure() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 408, transportSessionError: nil, apiVersion: 0)
        let message = GenericMessageEntity(
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)
        message.isExpired = true

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withMessageDependencyResolverReturning(result: .success(Void()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: NetworkError.errorDecodingResponse(response))
            .arrange()

        // when
        let result = await messageSender.sendMessage(message: message)

        // then
        assertFailure(result: result, expectedFailure: MessageSendError.messageExpired)
    }

    func testThatWhenSendingMessageFailsWithPermanentError_thenReturnFailure() async throws {
        // given
        let response = ZMTransportResponse(payload: nil, httpStatus: 403, transportSessionError: nil, apiVersion: 0)
        let networkError = NetworkError.errorDecodingResponse(response)
        let message = GenericMessageEntity(
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withMessageDependencyResolverReturning(result: .success(Void()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: networkError)
            .arrange()

        // when
        let result = await messageSender.sendMessage(message: message)

        // then
        assertFailure(result: result, expectedFailure: MessageSendError.networkError(networkError))
    }

    func testThatWhenSendingMessageFailsWithFederationRemoteError_thenUpdateExpirationReasonCode() async throws {
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
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withMessageDependencyResolverReturning(result: .success(Void()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: networkError)
            .arrange()

        // when
        let result = await messageSender.sendMessage(message: message)

        // then
        assertFailure(result: result, expectedFailure: MessageSendError.networkError(networkError))
        XCTAssertEqual(NSNumber(value: MessageSendFailure.federationRemoteError.rawValue), message.expirationReasonCode)
    }

    func testThatWhenSendingMessageFailsWithUnknownFederationError_thenUpdateExpirationReasonCode() async throws {
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
            conversation: groupConversation,
            message: GenericMessage(content: Text(content: "Hello World")),
            completionHandler: nil)

        let (_, messageSender) = Arrangement(coreDataStack: coreDataStack)
            .withMessageDependencyResolverReturning(result: .success(Void()))
            .withApiVersionResolving(to: .v0)
            .withSendProteusMessageFailing(with: networkError)
            .arrange()

        // when
        let result = await messageSender.sendMessage(message: message)

        // then
        assertFailure(result: result, expectedFailure: MessageSendError.networkError(networkError))
        XCTAssertEqual(NSNumber(value: MessageSendFailure.unknown.rawValue), message.expirationReasonCode)
    }

    struct Arrangement {

        struct Scaffolding {
            static let clientID = QualifiedClientID(userID: UUID(), domain: "example.com", clientID: "client123")
            static let responseSuccess = ZMTransportResponse(payload: nil, httpStatus: 201, transportSessionError: nil, apiVersion: 0)
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
        let coreDataStack: CoreDataStack

        init(coreDataStack: CoreDataStack) {
            self.coreDataStack = coreDataStack

            apiProvider.messageAPIApiVersion_MockValue = messageApi
        }

        func withApiVersionResolving(to apiVersion: APIVersion?) -> Arrangement {
            BackendInfo.apiVersion = apiVersion
            return self
        }

        func withMessageDependencyResolverReturning(result: Swift.Result<Void, MessageDependencyResolverError>) -> Arrangement {
            messageDependencyResolver.waitForDependenciesToResolveFor_MockMethod = { _ in result }
            return self
        }

        func withSendProteusMessageFailing(with error: NetworkError) -> Arrangement {
            messageApi.sendProteusMessageMessageConversationID_MockMethod = { [weak messageApi] _, _ in
                if messageApi?.sendProteusMessageMessageConversationID_Invocations.count > 1 {
                    return .success((Scaffolding.messageSendingStatusSuccess, Scaffolding.responseSuccess))
                } else {
                    return .failure(error)
                }
            }
            return self
        }

        func withEstablishSessions(returning result: Swift.Result<Void, SessionEstablisherError>) -> Arrangement {
            sessionEstablisher.establishSessionWithApiVersion_MockValue = result
            return self
        }

        func withSendProteusMessage(returning result: Swift.Result<(Payload.MessageSendingStatus, ZMTransportResponse), NetworkError>) -> Arrangement {
            messageApi.sendProteusMessageMessageConversationID_MockValue = result
            return self
        }

        func arrange() -> (Arrangement, MessageSender) {
            return (self, MessageSender(
                apiProvider: apiProvider,
                clientRegistrationDelegate: clientRegistrationDelegate,
                sessionEstablisher: sessionEstablisher,
                messageDependencyResolver: messageDependencyResolver,
                context: coreDataStack.syncContext)
            )
        }
    }

}
