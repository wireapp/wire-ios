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

// MARK: - MutedMessageOptionValue

@objc
public enum MutedMessageOptionValue: Int32 {
    case none = 0
    case regular = 1
    case mentionsAndReplies = 2
    case all = 3
}

// MARK: - MutedMessageTypes

/// Defines what kind of messages are muted.
/// +--------------------+----------------+----------------------------------------+--------+
/// | mutedStatus        | Normal Message | Message that contains mention or reply |  Call  |
/// +--------------------+----------------+----------------------------------------+--------+
/// | none               | Notify         | Notify                                 | Notify |
/// | regular            | X              | Notify                                 | X      |
/// | mentionsAndReplies | Notify         | X                                      | Notify |
/// | all                | X              | X                                      | X      |
/// +--------------------+----------------+----------------------------------------+--------+
public struct MutedMessageTypes: OptionSet {
    // MARK: Lifecycle

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    // MARK: Public

    /// None of the messages are muted.
    public static let none = MutedMessageTypes(rawValue: MutedMessageOptionValue.none.rawValue)

    /// All messages, including mentions and replies, are muted.
    public static let all: MutedMessageTypes = [.regular, .mentionsAndReplies]

    /// Only regular messages (no mentions nor replies) are muted.
    public static let regular = MutedMessageTypes(rawValue: MutedMessageOptionValue.regular.rawValue)

    /// Only mentions and replies are muted. Only used to check the bits in the bitmask.
    /// Please do not set this as the value on the conversation.
    public static let mentionsAndReplies = MutedMessageTypes(
        rawValue: MutedMessageOptionValue.mentionsAndReplies
            .rawValue
    )

    public let rawValue: Int32
}

extension ZMConversation {
    @NSManaged public var mutedStatus: Int32

    /// Returns an option set of messages types which should be muted
    public var mutedMessageTypes: MutedMessageTypes {
        get {
            guard let managedObjectContext else {
                return .none
            }

            let selfUser = ZMUser.selfUser(in: managedObjectContext)

            if selfUser.hasTeam {
                return MutedMessageTypes(rawValue: mutedStatus)
            } else {
                return mutedStatus == MutedMessageOptionValue.none.rawValue ? MutedMessageTypes.none : MutedMessageTypes
                    .all
            }
        }
        set {
            guard let managedObjectContext else {
                return
            }

            let selfUser = ZMUser.selfUser(in: managedObjectContext)

            if selfUser.hasTeam {
                mutedStatus = newValue.rawValue
            } else {
                mutedStatus = (newValue == .none) ? MutedMessageOptionValue.none
                    .rawValue : (MutedMessageOptionValue.all.rawValue)
            }

            if managedObjectContext.zm_isUserInterfaceContext,
               let lastServerTimestamp = lastServerTimeStamp {
                updateMuted(lastServerTimestamp, synchronize: true)
            }
        }
    }

    /// Returns an option set of messages types which should be muted when also considering the
    /// the availability status of the self user.
    public var mutedMessageTypesIncludingAvailability: MutedMessageTypes {
        guard let managedObjectContext else {
            return .none
        }

        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        return selfUser.mutedMessagesTypes.union(mutedMessageTypes)
    }
}

extension ZMUser {
    var mutedMessagesTypes: MutedMessageTypes {
        switch availability {
        case .available,
             .none:
            .none
        case .busy:
            .regular
        case .away:
            .all
        }
    }
}

extension ZMConversation {
    public func isMessageSilenced(_ message: GenericMessage?, senderID: UUID?) -> Bool {
        guard let managedObjectContext else {
            return false
        }

        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        if let senderID,
           let sender = ZMUser.fetch(with: senderID, in: managedObjectContext), sender.isSelfUser {
            return true
        }

        if mutedMessageTypesIncludingAvailability == .none {
            return false
        }

        // We assume that all composite messages are alarming messages
        guard message?.compositeData == nil else {
            return false
        }

        guard let textMessageData = message?.textData else {
            return true
        }

        let quotedMessageId = UUID(uuidString: textMessageData.quote.quotedMessageID)
        let quotedMessage = ZMOTRMessage.fetch(withNonce: quotedMessageId, for: self, in: managedObjectContext)

        if mutedMessageTypesIncludingAvailability == .regular,
           textMessageData.isMentioningSelf(selfUser) || textMessageData.isQuotingSelf(quotedMessage) {
            return false
        } else {
            return true
        }
    }
}
