// Generated using Sourcery 2.1.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif


@testable import WireRequestStrategy





















public class MockAPIProviderInterface: APIProviderInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - prekeyAPI

    public var prekeyAPIApiVersion_Invocations: [APIVersion] = []
    public var prekeyAPIApiVersion_MockMethod: ((APIVersion) -> PrekeyAPI)?
    public var prekeyAPIApiVersion_MockValue: PrekeyAPI?

    public func prekeyAPI(apiVersion: APIVersion) -> PrekeyAPI {
        prekeyAPIApiVersion_Invocations.append(apiVersion)

        if let mock = prekeyAPIApiVersion_MockMethod {
            return mock(apiVersion)
        } else if let mock = prekeyAPIApiVersion_MockValue {
            return mock
        } else {
            fatalError("no mock for `prekeyAPIApiVersion`")
        }
    }

    // MARK: - messageAPI

    public var messageAPIApiVersion_Invocations: [APIVersion] = []
    public var messageAPIApiVersion_MockMethod: ((APIVersion) -> MessageAPI)?
    public var messageAPIApiVersion_MockValue: MessageAPI?

    public func messageAPI(apiVersion: APIVersion) -> MessageAPI {
        messageAPIApiVersion_Invocations.append(apiVersion)

        if let mock = messageAPIApiVersion_MockMethod {
            return mock(apiVersion)
        } else if let mock = messageAPIApiVersion_MockValue {
            return mock
        } else {
            fatalError("no mock for `messageAPIApiVersion`")
        }
    }

}
public class MockMessageAPI: MessageAPI {

    // MARK: - Life cycle

    public init() {}


    // MARK: - sendProteusMessage

    public var sendProteusMessageMessageConversationID_Invocations: [(message: any ProteusMessage, conversationID: QualifiedID)] = []
    public var sendProteusMessageMessageConversationID_MockError: Error?
    public var sendProteusMessageMessageConversationID_MockMethod: ((any ProteusMessage, QualifiedID) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse))?
    public var sendProteusMessageMessageConversationID_MockValue: (Payload.MessageSendingStatus, ZMTransportResponse)?

    public func sendProteusMessage(message: any ProteusMessage, conversationID: QualifiedID) async throws -> (Payload.MessageSendingStatus, ZMTransportResponse) {
        sendProteusMessageMessageConversationID_Invocations.append((message: message, conversationID: conversationID))

        if let error = sendProteusMessageMessageConversationID_MockError {
            throw error
        }

        if let mock = sendProteusMessageMessageConversationID_MockMethod {
            return try await mock(message, conversationID)
        } else if let mock = sendProteusMessageMessageConversationID_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendProteusMessageMessageConversationID`")
        }
    }

    // MARK: - sendMLSMessage

    public var sendMLSMessageMessageConversationIDExpirationDate_Invocations: [(encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?)] = []
    public var sendMLSMessageMessageConversationIDExpirationDate_MockError: Error?
    public var sendMLSMessageMessageConversationIDExpirationDate_MockMethod: ((Data, QualifiedID, Date?) async throws -> (Payload.MLSMessageSendingStatus, ZMTransportResponse))?
    public var sendMLSMessageMessageConversationIDExpirationDate_MockValue: (Payload.MLSMessageSendingStatus, ZMTransportResponse)?

    public func sendMLSMessage(message encryptedMessage: Data, conversationID: QualifiedID, expirationDate: Date?) async throws -> (Payload.MLSMessageSendingStatus, ZMTransportResponse) {
        sendMLSMessageMessageConversationIDExpirationDate_Invocations.append((encryptedMessage: encryptedMessage, conversationID: conversationID, expirationDate: expirationDate))

        if let error = sendMLSMessageMessageConversationIDExpirationDate_MockError {
            throw error
        }

        if let mock = sendMLSMessageMessageConversationIDExpirationDate_MockMethod {
            return try await mock(encryptedMessage, conversationID, expirationDate)
        } else if let mock = sendMLSMessageMessageConversationIDExpirationDate_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendMLSMessageMessageConversationIDExpirationDate`")
        }
    }

}
public class MockMessageDependencyResolverInterface: MessageDependencyResolverInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - waitForDependenciesToResolve

    public var waitForDependenciesToResolveFor_Invocations: [any SendableMessage] = []
    public var waitForDependenciesToResolveFor_MockError: Error?
    public var waitForDependenciesToResolveFor_MockMethod: ((any SendableMessage) async throws -> Void)?

    public func waitForDependenciesToResolve(for message: any SendableMessage) async throws {
        waitForDependenciesToResolveFor_Invocations.append(message)

        if let error = waitForDependenciesToResolveFor_MockError {
            throw error
        }

        guard let mock = waitForDependenciesToResolveFor_MockMethod else {
            fatalError("no mock for `waitForDependenciesToResolveFor`")
        }

        try await mock(message)            
    }

}
public class MockMessageSenderInterface: MessageSenderInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - sendMessage

    public var sendMessageMessage_Invocations: [any SendableMessage] = []
    public var sendMessageMessage_MockError: Error?
    public var sendMessageMessage_MockMethod: ((any SendableMessage) async throws -> Void)?

    public func sendMessage(message: any SendableMessage) async throws {
        sendMessageMessage_Invocations.append(message)

        if let error = sendMessageMessage_MockError {
            throw error
        }

        guard let mock = sendMessageMessage_MockMethod else {
            fatalError("no mock for `sendMessageMessage`")
        }

        try await mock(message)            
    }

}
public class MockPrekeyAPI: PrekeyAPI {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchPrekeys

    public var fetchPrekeysFor_Invocations: [Set<QualifiedClientID>] = []
    public var fetchPrekeysFor_MockError: Error?
    public var fetchPrekeysFor_MockMethod: ((Set<QualifiedClientID>) async throws -> Payload.PrekeyByQualifiedUserID)?
    public var fetchPrekeysFor_MockValue: Payload.PrekeyByQualifiedUserID?

    public func fetchPrekeys(for clients: Set<QualifiedClientID>) async throws -> Payload.PrekeyByQualifiedUserID {
        fetchPrekeysFor_Invocations.append(clients)

        if let error = fetchPrekeysFor_MockError {
            throw error
        }

        if let mock = fetchPrekeysFor_MockMethod {
            return try await mock(clients)
        } else if let mock = fetchPrekeysFor_MockValue {
            return mock
        } else {
            fatalError("no mock for `fetchPrekeysFor`")
        }
    }

}
public class MockPrekeyPayloadProcessorInterface: PrekeyPayloadProcessorInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - establishSessions

    public var establishSessionsFromWithContext_Invocations: [(payload: Payload.PrekeyByQualifiedUserID, selfClient: UserClient, context: NSManagedObjectContext)] = []
    public var establishSessionsFromWithContext_MockMethod: ((Payload.PrekeyByQualifiedUserID, UserClient, NSManagedObjectContext) -> Bool)?
    public var establishSessionsFromWithContext_MockValue: Bool?

    public func establishSessions(from payload: Payload.PrekeyByQualifiedUserID, with selfClient: UserClient, context: NSManagedObjectContext) -> Bool {
        establishSessionsFromWithContext_Invocations.append((payload: payload, selfClient: selfClient, context: context))

        if let mock = establishSessionsFromWithContext_MockMethod {
            return mock(payload, selfClient, context)
        } else if let mock = establishSessionsFromWithContext_MockValue {
            return mock
        } else {
            fatalError("no mock for `establishSessionsFromWithContext`")
        }
    }

}

public class MockQuickSyncObserverInterface: QuickSyncObserverInterface {

    // MARK: - Life cycle

    public init() {}
    public var waitForQuickSyncToFinish_Invocations: [Void] = []
    public var waitForQuickSyncToFinish_MockMethod: (() async -> Void)?

    public func waitForQuickSyncToFinish() async {
        waitForQuickSyncToFinish_Invocations.append(())

        guard let mock = waitForQuickSyncToFinish_MockMethod else {
            fatalError("no mock for `waitForQuickSyncToFinish`")
        }

        await mock()            
    }

}
public class MockSessionEstablisherInterface: SessionEstablisherInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - establishSession

    public var establishSessionWithApiVersion_Invocations: [(clients: Set<QualifiedClientID>, apiVersion: APIVersion)] = []
    public var establishSessionWithApiVersion_MockError: Error?
    public var establishSessionWithApiVersion_MockMethod: ((Set<QualifiedClientID>, APIVersion) async throws -> Void)?

    public func establishSession(with clients: Set<QualifiedClientID>, apiVersion: APIVersion) async throws {
        establishSessionWithApiVersion_Invocations.append((clients: clients, apiVersion: apiVersion))

        if let error = establishSessionWithApiVersion_MockError {
            throw error
        }

        guard let mock = establishSessionWithApiVersion_MockMethod else {
            fatalError("no mock for `establishSessionWithApiVersion`")
        }

        try await mock(clients, apiVersion)            
    }

}
