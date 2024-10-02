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

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import WireAnalytics

@testable import WireSyncEngine

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

    // MARK: - broadcastMessage

    public var broadcastMessageMessage_Invocations: [any ProteusMessage] = []
    public var broadcastMessageMessage_MockError: Error?
    public var broadcastMessageMessage_MockMethod: ((any ProteusMessage) async throws -> Void)?

    public func broadcastMessage(message: any ProteusMessage) async throws {
        broadcastMessageMessage_Invocations.append(message)

        if let error = broadcastMessageMessage_MockError {
            throw error
        }

        guard let mock = broadcastMessageMessage_MockMethod else {
            fatalError("no mock for `broadcastMessageMessage`")
        }

        try await mock(message)
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

public class MockMessageAppendableConversation: MessageAppendableConversation {

    // MARK: - Life cycle

    public init() {}

    // MARK: - conversationType

    public var conversationType: ZMConversationType {
        get { return underlyingConversationType }
        set(value) { underlyingConversationType = value }
    }

    public var underlyingConversationType: ZMConversationType!

    // MARK: - localParticipants

    public var localParticipants: Set<ZMUser> {
        get { return underlyingLocalParticipants }
        set(value) { underlyingLocalParticipants = value }
    }

    public var underlyingLocalParticipants: Set<ZMUser>!

    // MARK: - draftMessage

    public var draftMessage: DraftMessage?

    // MARK: - appendText

    public var appendTextContentMentionsReplyingToFetchLinkPreviewNonce_Invocations: [(content: String, mentions: [Mention], quotedMessage: (any ZMConversationMessage)?, fetchLinkPreview: Bool, nonce: UUID)] = []
    public var appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockError: Error?
    public var appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockMethod: ((String, [Mention], (any ZMConversationMessage)?, Bool, UUID) throws -> any ZMConversationMessage)?
    public var appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockValue: (any ZMConversationMessage)?

    @discardableResult
    public func appendText(content: String, mentions: [Mention], replyingTo quotedMessage: (any ZMConversationMessage)?, fetchLinkPreview: Bool, nonce: UUID) throws -> any ZMConversationMessage {
        appendTextContentMentionsReplyingToFetchLinkPreviewNonce_Invocations.append((content: content, mentions: mentions, quotedMessage: quotedMessage, fetchLinkPreview: fetchLinkPreview, nonce: nonce))

        if let error = appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockError {
            throw error
        }

        if let mock = appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockMethod {
            return try mock(content, mentions, quotedMessage, fetchLinkPreview, nonce)
        } else if let mock = appendTextContentMentionsReplyingToFetchLinkPreviewNonce_MockValue {
            return mock
        } else {
            fatalError("no mock for `appendTextContentMentionsReplyingToFetchLinkPreviewNonce`")
        }
    }

    // MARK: - appendKnock

    public var appendKnock_Invocations: [UUID] = []
    public var appendKnock_MockError: Error?
    public var appendKnock_MockMethod: ((UUID) throws -> any ZMConversationMessage)?
    public var appendKnock_MockValue: (any ZMConversationMessage)?

    @discardableResult
    public func appendKnock(nonce: UUID) throws -> any ZMConversationMessage {
        appendKnock_Invocations.append(nonce)

        if let error = appendKnock_MockError {
            throw error
        }

        if let mock = appendKnock_MockMethod {
            return try mock(nonce)
        } else if let mock = appendKnock_MockValue {
            return mock
        } else {
            fatalError("no mock for `appendKnock`")
        }
    }

    // MARK: - appendImage

    public var appendImage_Invocations: [(imageData: Data, nonce: UUID)] = []
    public var appendImage_MockError: Error?
    public var appendImage_MockMethod: ((Data, UUID) throws -> any ZMConversationMessage)?
    public var appendImage_MockValue: (any ZMConversationMessage)?

    @discardableResult
    public func appendImage(from imageData: Data, nonce: UUID) throws -> any ZMConversationMessage {
        appendImage_Invocations.append((imageData: imageData, nonce: nonce))

        if let error = appendImage_MockError {
            throw error
        }

        if let mock = appendImage_MockMethod {
            return try mock(imageData, nonce)
        } else if let mock = appendImage_MockValue {
            return mock
        } else {
            fatalError("no mock for `appendImage`")
        }
    }

    // MARK: - appendLocation

    public var appendLocation_Invocations: [(locationData: LocationData, nonce: UUID)] = []
    public var appendLocation_MockError: Error?
    public var appendLocation_MockMethod: ((LocationData, UUID) throws -> any ZMConversationMessage)?
    public var appendLocation_MockValue: (any WireDataModel.ZMConversationMessage)?

    @discardableResult
    public func appendLocation(with locationData: LocationData, nonce: UUID) throws -> any ZMConversationMessage {
        appendLocation_Invocations.append((locationData: locationData, nonce: nonce))

        if let error = appendLocation_MockError {
            throw error
        }

        if let mock = appendLocation_MockMethod {
            return try mock(locationData, nonce)
        } else if let mock = appendLocation_MockValue {
            return mock
        } else {
            fatalError("no mock for `appendLocation`")
        }
    }

    // MARK: - appendFile

       public var appendFile_Invocations: [(fileMetadata: ZMFileMetadata, nonce: UUID)] = []
       public var appendFile_MockError: Error?
       public var appendFile_MockMethod: ((ZMFileMetadata, UUID) throws -> ZMConversationMessage)?
       public var appendFile_MockValue: ZMConversationMessage?

       @discardableResult
       public func appendFile(with fileMetadata: ZMFileMetadata, nonce: UUID) throws -> ZMConversationMessage {
           appendFile_Invocations.append((fileMetadata: fileMetadata, nonce: nonce))

           if let error = appendFile_MockError {
               throw error
           }

           if let mock = appendFile_MockMethod {
               return try mock(fileMetadata, nonce)
           } else if let mock = appendFile_MockValue {
               return mock
           } else {
               fatalError("no mock for `appendFile`")
           }
       }
}

class MockDisableAnalyticsUseCaseAnalyticsSessionProviding: DisableAnalyticsUseCaseAnalyticsSessionProviding {

    // MARK: - Life cycle

    // MARK: - analyticsSession

    var analyticsSession: (any AnalyticsSessionProtocol)?
}

class MockEnableAnalyticsUseCaseAnalyticsSessionProviding: EnableAnalyticsUseCaseAnalyticsSessionProviding {

    // MARK: - Life cycle

    // MARK: - analyticsSession

    var analyticsSession: (any AnalyticsSessionProtocol)?
}
