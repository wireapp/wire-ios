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
    public var sendProteusMessageMessageConversationID_MockMethod: ((any ProteusMessage, QualifiedID) async -> Swift.Result<(Payload.MessageSendingStatus, ZMTransportResponse), NetworkError>)?
    public var sendProteusMessageMessageConversationID_MockValue: Swift.Result<(Payload.MessageSendingStatus, ZMTransportResponse), NetworkError>?

    public func sendProteusMessage(message: any ProteusMessage, conversationID: QualifiedID) async -> Swift.Result<(Payload.MessageSendingStatus, ZMTransportResponse), NetworkError> {
        sendProteusMessageMessageConversationID_Invocations.append((message: message, conversationID: conversationID))

        if let mock = sendProteusMessageMessageConversationID_MockMethod {
            return await mock(message, conversationID)
        } else if let mock = sendProteusMessageMessageConversationID_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendProteusMessageMessageConversationID`")
        }
    }

}
public class MockMessageSenderInterface: MessageSenderInterface {

    // MARK: - Life cycle

    public init() {}


    // MARK: - sendMessage

    public var sendMessageMessage_Invocations: [any SendableMessage] = []
    public var sendMessageMessage_MockMethod: ((any SendableMessage) async -> Swift.Result<Void, MessageSendError>)?
    public var sendMessageMessage_MockValue: Swift.Result<Void, MessageSendError>?

    public func sendMessage(message: any SendableMessage) async -> Swift.Result<Void, MessageSendError> {
        sendMessageMessage_Invocations.append(message)

        if let mock = sendMessageMessage_MockMethod {
            return await mock(message)
        } else if let mock = sendMessageMessage_MockValue {
            return mock
        } else {
            fatalError("no mock for `sendMessageMessage`")
        }
    }

}
public class MockPrekeyAPI: PrekeyAPI {

    // MARK: - Life cycle

    public init() {}


    // MARK: - fetchPrekeys

    public var fetchPrekeysFor_Invocations: [Set<QualifiedClientID>] = []
    public var fetchPrekeysFor_MockMethod: ((Set<QualifiedClientID>) async -> Swift.Result<Payload.PrekeyByQualifiedUserID, NetworkError>)?
    public var fetchPrekeysFor_MockValue: Swift.Result<Payload.PrekeyByQualifiedUserID, NetworkError>?

    public func fetchPrekeys(for clients: Set<QualifiedClientID>) async -> Swift.Result<Payload.PrekeyByQualifiedUserID, NetworkError> {
        fetchPrekeysFor_Invocations.append(clients)

        if let mock = fetchPrekeysFor_MockMethod {
            return await mock(clients)
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
