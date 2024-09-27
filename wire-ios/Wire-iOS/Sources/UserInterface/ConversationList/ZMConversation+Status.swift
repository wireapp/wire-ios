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
import WireCommonComponents
import WireDataModel
import WireDesign
import WireSyncEngine

// MARK: - ConversationStatusIcon

// Describes the icon to be shown for the conversation in the list.
enum ConversationStatusIcon: Equatable {
    case pendingConnection

    case typing

    case unreadMessages(count: Int)
    case unreadPing
    case missedCall
    case mention
    case reply

    case silenced

    case playingMedia

    case activeCall(showJoin: Bool)
}

// MARK: - ConversationStatus

// Describes the status of the conversation.
struct ConversationStatus {
    let isGroup: Bool

    let hasMessages: Bool
    let hasUnsentMessages: Bool

    let messagesRequiringAttention: [ZMConversationMessage]
    let messagesRequiringAttentionByType: [StatusMessageType: UInt]
    let isTyping: Bool
    let mutedMessageTypes: MutedMessageTypes
    let isOngoingCall: Bool
    let isBlocked: Bool
    let isSelfAnActiveMember: Bool
    let hasSelfMention: Bool
    let hasSelfReply: Bool
}

// MARK: - StatusMessageType

// Describes the conversation message.
enum StatusMessageType: Int, CaseIterable {
    case mention
    case reply
    case missedCall
    case knock
    case text
    case link
    case image
    case location
    case audio
    case video
    case file
    case addParticipants
    case removeParticipants
    case newConversation

    // MARK: Internal

    var localizationKey: String? {
        guard let localizationKey = localizationKeySuffix else {
            return nil
        }

        return localizationSilencedRootPath + "." + localizationKey
    }

    func localizedString(with count: UInt) -> String? {
        guard let localizationKey else { return nil }

        return String(format: localizationKey.localized, count)
    }

    // MARK: Private

    private var localizationSilencedRootPath: String {
        "conversation.silenced.status.message"
    }

    private var localizationKeySuffix: String? {
        switch self {
        case .mention:
            "mention"
        case .reply:
            "reply"
        case .missedCall:
            "missedcall"
        case .knock:
            "knock"
        case .text:
            "generic_message"
        default:
            nil
        }
    }
}

extension StatusMessageType {
    /// Types of statuses that can be included in a status summary.
    static let summaryTypes: [StatusMessageType] = [
        .mention,
        .reply,
        .missedCall,
        .knock,
        .text,
        .link,
        .image,
        .location,
        .audio,
        .video,
        .file,
    ]

    var parentSummaryType: StatusMessageType? {
        switch self {
        case .audio, .file, .image, .link, .location, .video: .text
        default: nil
        }
    }

    private static let conversationSystemMessageTypeToStatusMessageType: [ZMSystemMessageType: StatusMessageType] = [
        .participantsAdded: .addParticipants,
        .participantsRemoved: .removeParticipants,
        .missedCall: .missedCall,
        .newConversation: .newConversation,
    ]

    init?(message: ZMConversationMessage) {
        if message.isText, let textMessage = message.textMessageData {
            if textMessage.isMentioningSelf {
                self = .mention
            } else if textMessage.isQuotingSelf {
                self = .reply
            } else if textMessage.linkPreview != nil {
                self = .link
            } else {
                self = .text
            }
        } else if message.isImage {
            self = .image
        } else if message.isLocation {
            self = .location
        } else if message.isAudio {
            self = .audio
        } else if message.isVideo {
            self = .video
        } else if message.isFile {
            self = .file
        } else if message.isKnock {
            self = .knock
        } else if message.isSystem, let system = message.systemMessageData {
            if let statusMessageType = StatusMessageType
                .conversationSystemMessageTypeToStatusMessageType[system.systemMessageType] {
                self = statusMessageType
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

// MARK: - ConversationStatusMatcher

// Describes object that is able to match and describe the conversation.
// Provides rich description and status icon.
protocol ConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool
    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString?
    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon?

    // An array of matchers that are compatible with the current one. Leads to display the description of all matching
    // in one row, like "description1 | description2"
    var combinesWith: [ConversationStatusMatcher] { get }
}

// MARK: - TypedConversationStatusMatcher

protocol TypedConversationStatusMatcher: ConversationStatusMatcher {
    var matchedTypes: [StatusMessageType] { get }
}

extension TypedConversationStatusMatcher {
    func isMatching(with status: ConversationStatus) -> Bool {
        let matches: [UInt] = matchedTypes.compactMap { status.messagesRequiringAttentionByType[$0] }
        return matches.reduce(0, +) > 0
    }
}

extension ConversationStatusMatcher {
    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        nil
    }

    func addEmphasis(to string: NSAttributedString, for substring: String) -> NSAttributedString {
        string.setAttributes(type(of: self).emphasisStyle, toSubstring: substring)
    }
}

// MARK: - ContentSizeCategoryUpdater

final class ContentSizeCategoryUpdater {
    // MARK: Lifecycle

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    init(callback: @escaping () -> Void) {
        self.callback = callback
        callback()
        self.observer = NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.callback()
        }
    }

    // MARK: Private

    private let callback: () -> Void
    private var observer: NSObjectProtocol!
}

// MARK: - ConversationStatusStyle

final class ConversationStatusStyle {
    // MARK: Lifecycle

    init() {
        self.contentSizeStyleUpdater = ContentSizeCategoryUpdater { [weak self] in
            guard let self else {
                return
            }

            self.regularStyle = [
                .font: FontSpec(.medium, .none).font!,
                .foregroundColor: UIColor(white: 1.0, alpha: 0.64),
            ]
            self.emphasisStyle = [
                .font: FontSpec(.medium, .medium).font!,
                .foregroundColor: UIColor(white: 1.0, alpha: 0.64),
            ]
        }
    }

    // MARK: Internal

    private(set) var regularStyle: [NSAttributedString.Key: AnyObject] = [:]
    private(set) var emphasisStyle: [NSAttributedString.Key: AnyObject] = [:]

    // MARK: Private

    private var contentSizeStyleUpdater: ContentSizeCategoryUpdater!
}

private let statusStyle = ConversationStatusStyle()

extension ConversationStatusMatcher {
    static var regularStyle: [NSAttributedString.Key: AnyObject] {
        statusStyle.regularStyle
    }

    static var emphasisStyle: [NSAttributedString.Key: AnyObject] {
        statusStyle.emphasisStyle
    }
}

extension ZMConversation {
    static func statusRegularStyle() -> [NSAttributedString.Key: AnyObject] {
        statusStyle.regularStyle
    }
}

// MARK: - SelfUserLeftMatcher

// "You left"
final class SelfUserLeftMatcher: ConversationStatusMatcher {
    var combinesWith: [ConversationStatusMatcher] = []

    func isMatching(with status: ConversationStatus) -> Bool {
        !status.hasMessages && status.isGroup && !status.isSelfAnActiveMember
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        L10n.Localizable.Conversation.Status.youLeft && type(of: self).regularStyle
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        nil
    }
}

// MARK: - BlockedMatcher

// "Blocked"
final class BlockedMatcher: ConversationStatusMatcher {
    var combinesWith: [ConversationStatusMatcher] = []

    func isMatching(with status: ConversationStatus) -> Bool {
        status.isBlocked
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        L10n.Localizable.Conversation.Status.blocked && type(of: self).regularStyle
    }
}

// MARK: - CallingMatcher

// "Active Call"
final class CallingMatcher: ConversationStatusMatcher {
    var combinesWith: [ConversationStatusMatcher] = []

    static func icon(for state: CallState?, conversation: ConversationStatusProvider?) -> ConversationStatusIcon? {
        guard let state else {
            return nil
        }

        if state.canJoinCall {
            return .activeCall(showJoin: true)
        } else if state.isCallOngoing {
            return .activeCall(showJoin: false)
        }

        return nil
    }

    func isMatching(with status: ConversationStatus) -> Bool {
        status.isOngoingCall
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        if conversation.voiceChannel?.state.canJoinCall == true {
            if let callerDisplayName = conversation.voiceChannel?.initiator?.name {
                return L10n.Localizable.Conversation.Status.incomingCall(callerDisplayName) && type(of: self)
                    .regularStyle
            } else {
                return L10n.Localizable.Conversation.Status.someone && type(of: self).regularStyle
            }
        }
        return .none
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        CallingMatcher.icon(for: conversation.voiceChannel?.state, conversation: conversation)
    }
}

// MARK: - SecurityAlertMatcher

final class SecurityAlertMatcher: ConversationStatusMatcher {
    var combinesWith: [ConversationStatusMatcher] = []

    func isMatching(with status: ConversationStatus) -> Bool {
        status.messagesRequiringAttention.contains(where: \.isComposite)
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        guard let message = status.messagesRequiringAttention.reversed().first(where: {
            $0.isComposite
        }) else {
            return nil
        }

        let textItem = (message as? ConversationCompositeMessage)?.compositeMessageData?.items.first(where: {
            if case .text = $0 {
                return true
            }
            return false
        })

        let text: String = if let textItem,
                              case let .text(data) = textItem,
                              let messageText = data.messageText {
            messageText
        } else {
            ""
        }

        return text && Swift.type(of: self).regularStyle
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: icon for poll message
        nil
    }
}

// MARK: - TypingMatcher

// "A, B, C: typing a message..."
final class TypingMatcher: ConversationStatusMatcher {
    var combinesWith: [ConversationStatusMatcher] = []

    func isMatching(with status: ConversationStatus) -> Bool {
        status.isTyping && status.showingAllMessages
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        let statusString: NSAttributedString
        if status.isGroup {
            let typingUsersString = conversation.typingUsers.compactMap(\.name).joined(separator: ", ")
            let resultString = L10n.Localizable.Conversation.Status.Typing.group(typingUsersString)
            let intermediateString = NSAttributedString(string: resultString, attributes: type(of: self).regularStyle)
            statusString = addEmphasis(to: intermediateString, for: typingUsersString)
        } else {
            statusString = L10n.Localizable.Conversation.Status.typing && type(of: self).regularStyle
        }
        return statusString
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        .typing
    }
}

// MARK: - SilencedMatcher

// "Silenced"
final class SilencedMatcher: ConversationStatusMatcher {
    var combinesWith: [ConversationStatusMatcher] = []

    func isMatching(with status: ConversationStatus) -> Bool {
        !status.showingAllMessages
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        .none
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        if status.showingOnlyMentionsAndReplies {
            if status.hasSelfMention {
                return .mention
            } else if status.hasSelfReply {
                return .reply
            }
        }

        return .silenced
    }
}

extension ConversationStatus {
    var showingAllMessages: Bool {
        mutedMessageTypes == .none
    }

    var showingOnlyMentionsAndReplies: Bool {
        mutedMessageTypes == .regular
    }

    var completelyMuted: Bool {
        mutedMessageTypes == .all
    }

    var shouldSummarizeMessages: Bool {
        if completelyMuted {
            // Always summarize for completely muted conversation
            return true
        } else if showingOnlyMentionsAndReplies, !hasSelfMention, !hasSelfReply {
            // Summarize when there is no mention
            return true
        } else if hasSelfMention {
            // Summarize if there is at least one mention and another activity that can be inside a summary
            return StatusMessageType.summaryTypes
                .reduce(into: UInt(0)) { $0 += (messagesRequiringAttentionByType[$1] ?? 0) } > 1
        } else if hasSelfReply {
            // Summarize if there is at least one reply and another activity that can be inside a summary

            let count = StatusMessageType.summaryTypes
                .reduce(into: UInt(0)) { $0 += (messagesRequiringAttentionByType[$1] ?? 0) }

            // if all activities are replies, do not summarize
            if messagesRequiringAttentionByType[.reply] == count {
                return false
            } else {
                return count > 1
            }
        } else {
            // Never summarize in other cases
            return false
        }
    }
}

// MARK: - NewMessagesMatcher

// In silenced "N (text|image|link|...) message, ..."
// In not silenced: "[Sender:] <message text>"
// Ephemeral: "Ephemeral message"
final class NewMessagesMatcher: TypedConversationStatusMatcher {
    let localizationRootPath = "conversation.status.message"

    let matchedTypesDescriptions: [StatusMessageType: String] = [
        .mention: "mention",
        .reply: "reply",
        .missedCall: "missedcall",
        .knock: "knock",
        .text: "text",
        .link: "link",
        .image: "image",
        .location: "location",
        .audio: "audio",
        .video: "video",
        .file: "file",
    ]

    var combinesWith: [ConversationStatusMatcher] = []

    var matchedTypes: [StatusMessageType] {
        StatusMessageType.summaryTypes
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        if status.shouldSummarizeMessages {
            // Get the count of each category we can summarize, and group them under their parent type
            let flattenedCount: [StatusMessageType: UInt] = matchedTypes
                .reduce(into: [StatusMessageType: UInt]()) {
                    guard let count = status.messagesRequiringAttentionByType[$1], count > 0 else {
                        return
                    }

                    if let parentType = $1.parentSummaryType {
                        $0[parentType, default: 0] += count
                    } else {
                        $0[$1, default: 0] += count
                    }
                }

            // For each top-level summary type, generate the subtitle fragment
            let localizedMatchedItems: [String] = flattenedCount.keys.lazy
                .sorted { $0.rawValue < $1.rawValue }
                .reduce(into: []) {
                    guard let count = flattenedCount[$1], let string = $1.localizedString(with: count) else {
                        return
                    }

                    $0.append(string)
                }

            let resultString = localizedMatchedItems.joined(separator: ", ")
            return resultString && type(of: self).regularStyle
        } else {
            guard let message = status.messagesRequiringAttention.reversed().first(where: {
                if $0.senderUser != nil,
                   let type = StatusMessageType(message: $0),
                   matchedTypesDescriptions[type] != nil {
                    true
                } else {
                    false
                }
            }),
                let sender = message.senderUser,
                let type = StatusMessageType(message: message),
                let localizationKey = matchedTypesDescriptions[type] else {
                return "" && Swift.type(of: self).regularStyle
            }

            let messageDescription: String

            if message.isEphemeral {
                var typeSuffix = ".ephemeral"
                if type == .mention {
                    typeSuffix += status.isGroup ? ".mention.group" : ".mention"
                } else if type == .reply {
                    typeSuffix += status.isGroup ? ".reply.group" : ".reply"
                } else if type == .knock {
                    typeSuffix += status.isGroup ? ".knock.group" : ".knock"
                } else if status.isGroup {
                    typeSuffix += ".group"
                }
                messageDescription = (localizationRootPath + typeSuffix).localized
            } else {
                var format = localizationRootPath + "." + localizationKey

                if status.isGroup, type == .missedCall {
                    format += ".groups"
                    return format.localized(args: sender.name ?? "") && Swift.type(of: self).regularStyle
                }

                messageDescription = String(format: format.localized, message.textMessageData?.messageText ?? "")
            }

            if status.isGroup, !message.isEphemeral {
                return (((sender.name ?? "") + ": ") && Swift.type(of: self).emphasisStyle) +
                    (messageDescription && Swift.type(of: self).regularStyle)
            } else {
                return messageDescription && Swift.type(of: self).regularStyle
            }
        }
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        if status.hasSelfMention {
            return .mention
        } else if status.hasSelfReply {
            return .reply
        }

        guard let message = status.messagesRequiringAttention.reversed().first(where: {
            if $0.senderUser != nil,
               let type = StatusMessageType(message: $0),
               matchedTypesDescriptions[type] != nil {
                true
            } else {
                false
            }
        }),
            let type = StatusMessageType(message: message) else {
            return nil
        }

        switch type {
        case .knock:
            return .unreadPing
        case .missedCall:
            return .missedCall
        default:
            return .unreadMessages(
                count: status.messagesRequiringAttention
                    .compactMap { StatusMessageType(message: $0) }.filter { matchedTypes.firstIndex(of: $0) != .none }
                    .count
            )
        }
    }
}

// MARK: - FailedSendMatcher

// ! Failed to send
final class FailedSendMatcher: ConversationStatusMatcher {
    var combinesWith: [ConversationStatusMatcher] = []

    func isMatching(with status: ConversationStatus) -> Bool {
        status.hasUnsentMessages
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        L10n.Localizable.Conversation.Status.unsent && type(of: self).regularStyle
    }
}

// MARK: - GroupActivityMatcher

// "[You|User] [added|removed|left] [_|users|you]"
final class GroupActivityMatcher: TypedConversationStatusMatcher {
    // MARK: Internal

    let matchedTypes: [StatusMessageType] = [.addParticipants, .removeParticipants]

    var combinesWith: [ConversationStatusMatcher] = []

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        var allStatusMessagesByType: [StatusMessageType: [ZMConversationMessage]] = [:]

        for type in matchedTypes {
            allStatusMessagesByType[type] = status.messagesRequiringAttention.filter {
                StatusMessageType(message: $0) == type
            }
        }

        return [
            addedString(for: allStatusMessagesByType[.addParticipants] ?? [], in: conversation),
            removedString(for: allStatusMessagesByType[.removeParticipants] ?? [], in: conversation),
        ]
        .compactMap { $0 }.joined(separator: "; " && type(of: self).regularStyle)
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        .unreadMessages(
            count: status.messagesRequiringAttention
                .compactMap { StatusMessageType(message: $0) }
                .filter { matchedTypes.contains($0) }
                .count
        )
    }

    // MARK: Private

    private func addedString(
        for messages: [ZMConversationMessage],
        in conversation: MatcherConversation
    ) -> NSAttributedString? {
        if let message = messages.last,
           let systemMessage = message.systemMessageData,
           let sender = message.senderUser,
           !sender.isSelfUser {
            if systemMessage.userTypes.contains(where: { ($0 as? UserType)?.isSelfUser == true }) {
                let fullName = sender.name ?? ""
                let result = L10n.Localizable.Conversation.Status.youWasAdded(fullName) && type(of: self).regularStyle
                return addEmphasis(to: result, for: fullName)
            }
        }
        return .none
    }

    private func removedString(
        for messages: [ZMConversationMessage],
        in conversation: MatcherConversation
    ) -> NSAttributedString? {
        if let message = messages.last,
           let systemMessage = message.systemMessageData,
           let sender = message.senderUser,
           !sender.isSelfUser {
            if systemMessage.userTypes.contains(where: { ($0 as? UserType)?.isSelfUser == true }) {
                return L10n.Localizable.Conversation.Status.youWereRemoved && type(of: self).regularStyle
            }
        }
        return .none
    }
}

// MARK: - StartConversationMatcher

// [Someone] started a conversation
final class StartConversationMatcher: TypedConversationStatusMatcher {
    let matchedTypes: [StatusMessageType] = [.newConversation]

    var combinesWith: [ConversationStatusMatcher] = []

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        guard let message = status.messagesRequiringAttention
            .first(where: { StatusMessageType(message: $0) == .newConversation }),
            let sender = message.senderUser,
            !sender.isSelfUser
        else {
            return .none
        }

        let senderString = sender.name ?? ""
        let resultString = L10n.Localizable.Conversation.Status.startedConversation(senderString)

        return (resultString && type(of: self).regularStyle).addAttributes(
            type(of: self).emphasisStyle,
            toSubstring: senderString
        )
    }

    func icon(with status: ConversationStatus, conversation: MatcherConversation) -> ConversationStatusIcon? {
        ConversationStatusIcon.unreadMessages(count: 1)
    }
}

// MARK: - UsernameMatcher

// Fallback for empty conversations: showing the handle.
final class UsernameMatcher: ConversationStatusMatcher {
    var combinesWith: [ConversationStatusMatcher] = []

    func isMatching(with status: ConversationStatus) -> Bool {
        !status.hasMessages
    }

    func description(with status: ConversationStatus, conversation: MatcherConversation) -> NSAttributedString? {
        guard
            let user = conversation.connectedUserType,
            let handle = user.handleDisplayString(withDomain: user.isFederated)
        else { return .none }

        return handle && type(of: self).regularStyle
    }
}

// Matchers priorities (highest first):
//
// (SecurityAlert)
// (SelfUserLeftMatcher)
// (Blocked)
// (Calling)
// (Typing)
// (Silenced)
// (New message / call)
// (Unsent message combines with (Group activity), (New message / call), (Silenced))
// (Group activity)
// (Started conversation)
// (Username)
private var allMatchers: [ConversationStatusMatcher] = {
    let silencedMatcher = SilencedMatcher()
    let newMessageMatcher = NewMessagesMatcher()
    let groupActivityMatcher = GroupActivityMatcher()

    let failedSendMatcher = FailedSendMatcher()
    failedSendMatcher.combinesWith = [silencedMatcher, newMessageMatcher, groupActivityMatcher]

    return [
        SecurityAlertMatcher(),
        SelfUserLeftMatcher(),
        BlockedMatcher(),
        CallingMatcher(),
        silencedMatcher,
        TypingMatcher(),
        newMessageMatcher,
        failedSendMatcher,
        groupActivityMatcher,
        StartConversationMatcher(),
        UsernameMatcher(),
    ]
}()

extension ConversationStatus {
    func appliedMatchersForDescription(for conversation: MatcherConversation) -> [ConversationStatusMatcher] {
        guard let topMatcher = allMatchers.first(where: { $0.isMatching(with: self) && $0.description(
            with: self,
            conversation: conversation
        ) != .none }) else {
            return []
        }

        return [topMatcher] + topMatcher.combinesWith.filter { $0.isMatching(with: self) && $0.description(
            with: self,
            conversation: conversation
        ) != .none }
    }

    func appliedMatcherForIcon(for conversation: MatcherConversation) -> ConversationStatusMatcher? {
        for matcher in allMatchers.filter({ $0.isMatching(with: self) }) {
            let icon = matcher.icon(with: self, conversation: conversation)
            switch icon {
            case .none:
                break
            default:
                return matcher
            }
        }

        return .none
    }

    func description(for conversation: MatcherConversation) -> NSAttributedString {
        let allMatchers = appliedMatchersForDescription(for: conversation)
        guard !allMatchers.isEmpty else {
            return "" && [:]
        }
        let allStrings = allMatchers.compactMap { $0.description(with: self, conversation: conversation) }
        return allStrings.joined(separator: " | " && CallingMatcher.regularStyle)
    }

    func icon(for conversation: MatcherConversation) -> ConversationStatusIcon? {
        guard let topMatcher = appliedMatcherForIcon(for: conversation) else {
            return nil
        }

        return topMatcher.icon(with: self, conversation: conversation)
    }
}

extension ZMConversation {
    var status: ConversationStatus {
        let messagesRequiringAttention = estimatedUnreadCount > 0 ? unreadMessages : []

        let messagesRequiringAttentionByType: [StatusMessageType: UInt] = messagesRequiringAttention
            .reduce(into: [:]) { histogram, element in
                guard let messageType = StatusMessageType(message: element) else {
                    return
                }

                histogram[messageType, default: 0] += 1
            }

        let isOngoingCall: Bool = {
            guard let state = voiceChannel?.state else { return false }
            switch state {
            case .none, .terminating: return false
            case .incoming: return true
            default: return true
            }
        }()

        return ConversationStatus(
            isGroup: conversationType == .group,
            hasMessages: estimatedHasMessages,
            hasUnsentMessages: hasUnreadUnsentMessage,
            messagesRequiringAttention: messagesRequiringAttention,
            messagesRequiringAttentionByType: messagesRequiringAttentionByType,
            isTyping: !typingUsers.isEmpty,
            mutedMessageTypes: mutedMessageTypes,
            isOngoingCall: isOngoingCall,
            isBlocked: connectedUser?.isBlocked ?? false,
            isSelfAnActiveMember: isSelfAnActiveMember,
            hasSelfMention: estimatedUnreadSelfMentionCount > 0,
            hasSelfReply: estimatedUnreadSelfReplyCount > 0
        )
    }
}
