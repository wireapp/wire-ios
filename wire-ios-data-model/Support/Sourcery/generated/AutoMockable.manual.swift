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

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import Combine
import LocalAuthentication
import WireCoreCrypto

@testable import WireDataModel

// It's because of this error that we need to create this mock manually:
// Cannot declare conformance to 'NSObjectProtocol' in Swift; 'MockZMConversationMessage' should inherit 'NSObject' instead
public class MockZMConversationMessage: NSObject, ZMConversationMessage {

    // MARK: - nonce

    public var nonce: UUID?

    // MARK: - sender

    public var sender: ZMUser?

    // MARK: - senderUser

    public var senderUser: UserType?

    // MARK: - serverTimestamp

    public var serverTimestamp: Date?

    // MARK: - conversation

    public var conversation: ZMConversation?

    // MARK: - conversationLike

    public var conversationLike: ConversationLike?

    // MARK: - deliveryState

    public var deliveryState: ZMDeliveryState {
        get { return underlyingDeliveryState }
        set(value) { underlyingDeliveryState = value }
    }

    public var underlyingDeliveryState: ZMDeliveryState!

    // MARK: - isSent

    public var isSent: Bool {
        get { return underlyingIsSent }
        set(value) { underlyingIsSent = value }
    }

    public var underlyingIsSent: Bool!

    // MARK: - readReceipts

    public var readReceipts: [ReadReceipt] = []

    // MARK: - needsReadConfirmation

    public var needsReadConfirmation: Bool {
        get { return underlyingNeedsReadConfirmation }
        set(value) { underlyingNeedsReadConfirmation = value }
    }

    public var underlyingNeedsReadConfirmation: Bool!

    // MARK: - textMessageData

    public var textMessageData: ZMTextMessageData?

    // MARK: - imageMessageData

    public var imageMessageData: ZMImageMessageData?

    // MARK: - systemMessageData

    public var systemMessageData: ZMSystemMessageData?

    // MARK: - knockMessageData

    public var knockMessageData: ZMKnockMessageData?

    // MARK: - fileMessageData

    public var fileMessageData: ZMFileMessageData?

    // MARK: - locationMessageData

    public var locationMessageData: LocationMessageData?

    // MARK: - usersReaction

    public var usersReaction: [String: [UserType]] = [:]

    // MARK: - reactionData

    public var reactionData: Set<ReactionData> {
        get { return underlyingReactionData }
        set(value) { underlyingReactionData = value }
    }

    public var underlyingReactionData: Set<ReactionData>!

    // MARK: - canBeDeleted

    public var canBeDeleted: Bool {
        get { return underlyingCanBeDeleted }
        set(value) { underlyingCanBeDeleted = value }
    }

    public var underlyingCanBeDeleted: Bool!

    // MARK: - hasBeenDeleted

    public var hasBeenDeleted: Bool {
        get { return underlyingHasBeenDeleted }
        set(value) { underlyingHasBeenDeleted = value }
    }

    public var underlyingHasBeenDeleted: Bool!

    // MARK: - updatedAt

    public var updatedAt: Date?

    // MARK: - isEphemeral

    public var isEphemeral: Bool {
        get { return underlyingIsEphemeral }
        set(value) { underlyingIsEphemeral = value }
    }

    public var underlyingIsEphemeral: Bool!

    // MARK: - deletionTimeout

    public var deletionTimeout: TimeInterval {
        get { return underlyingDeletionTimeout }
        set(value) { underlyingDeletionTimeout = value }
    }

    public var underlyingDeletionTimeout: TimeInterval!

    // MARK: - isObfuscated

    public var isObfuscated: Bool {
        get { return underlyingIsObfuscated }
        set(value) { underlyingIsObfuscated = value }
    }

    public var underlyingIsObfuscated: Bool!

    // MARK: - destructionDate

    public var destructionDate: Date?

    // MARK: - causedSecurityLevelDegradation

    public var causedSecurityLevelDegradation: Bool {
        get { return underlyingCausedSecurityLevelDegradation }
        set(value) { underlyingCausedSecurityLevelDegradation = value }
    }

    public var underlyingCausedSecurityLevelDegradation: Bool!

    // MARK: - canBeMarkedUnread

    public var canBeMarkedUnread: Bool {
        get { return underlyingCanBeMarkedUnread }
        set(value) { underlyingCanBeMarkedUnread = value }
    }

    public var underlyingCanBeMarkedUnread: Bool!

    // MARK: - replies

    public var replies: Set<ZMMessage> {
        get { return underlyingReplies }
        set(value) { underlyingReplies = value }
    }

    public var underlyingReplies: Set<ZMMessage>!

    // MARK: - objectIdentifier

    public var objectIdentifier: String {
        get { return underlyingObjectIdentifier }
        set(value) { underlyingObjectIdentifier = value }
    }

    public var underlyingObjectIdentifier: String!

    // MARK: - linkAttachments

    public var linkAttachments: [LinkAttachment]?

    // MARK: - needsLinkAttachmentsUpdate

    public var needsLinkAttachmentsUpdate: Bool {
        get { return underlyingNeedsLinkAttachmentsUpdate }
        set(value) { underlyingNeedsLinkAttachmentsUpdate = value }
    }

    public var underlyingNeedsLinkAttachmentsUpdate: Bool!

    // MARK: - isSilenced

    public var isSilenced: Bool {
        get { return underlyingIsSilenced }
        set(value) { underlyingIsSilenced = value }
    }

    public var underlyingIsSilenced: Bool!

    // MARK: - isRestricted

    public var isRestricted: Bool {
        get { return underlyingIsRestricted }
        set(value) { underlyingIsRestricted = value }
    }

    public var underlyingIsRestricted: Bool!


    // MARK: - reactionsSortedByCreationDate

    public var reactionsSortedByCreationDate_Invocations: [Void] = []
    public var reactionsSortedByCreationDate_MockMethod: (() -> [ReactionData])?
    public var reactionsSortedByCreationDate_MockValue: [ReactionData]?

    public func reactionsSortedByCreationDate() -> [ReactionData] {
        reactionsSortedByCreationDate_Invocations.append(())

        if let mock = reactionsSortedByCreationDate_MockMethod {
            return mock()
        } else if let mock = reactionsSortedByCreationDate_MockValue {
            return mock
        } else {
            fatalError("no mock for `reactionsSortedByCreationDate`")
        }
    }

    // MARK: - resend

    public var resend_Invocations: [Void] = []
    public var resend_MockMethod: (() -> Void)?

    public func resend() {
        resend_Invocations.append(())

        guard let mock = resend_MockMethod else {
            fatalError("no mock for `resend`")
        }

        mock()
    }

    // MARK: - startSelfDestructionIfNeeded

    public var startSelfDestructionIfNeeded_Invocations: [Void] = []
    public var startSelfDestructionIfNeeded_MockMethod: (() -> Bool)?
    public var startSelfDestructionIfNeeded_MockValue: Bool?

    public func startSelfDestructionIfNeeded() -> Bool {
        startSelfDestructionIfNeeded_Invocations.append(())

        if let mock = startSelfDestructionIfNeeded_MockMethod {
            return mock()
        } else if let mock = startSelfDestructionIfNeeded_MockValue {
            return mock
        } else {
            fatalError("no mock for `startSelfDestructionIfNeeded`")
        }
    }

    // MARK: - markAsUnread

    public var markAsUnread_Invocations: [Void] = []
    public var markAsUnread_MockMethod: (() -> Void)?

    public func markAsUnread() {
        markAsUnread_Invocations.append(())

        guard let mock = markAsUnread_MockMethod else {
            fatalError("no mock for `markAsUnread`")
        }

        mock()
    }

}

// swiftlint:enable variable_name
// swiftlint:enable line_length
// swiftlint:enable vertical_whitespace
// swiftlint:enable superfluous_disable_command
