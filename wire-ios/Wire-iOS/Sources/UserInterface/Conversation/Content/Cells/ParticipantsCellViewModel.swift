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

import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign

// MARK: - ConversationActionType

enum ConversationActionType {
    case none
    case started(withName: String?)
    case added(herself: Bool)
    case removed(reason: ZMParticipantsRemovedReason)
    case left
    case teamMemberLeave

    // MARK: Internal

    /// Some actions only involve the sender, others involve other users too.
    var involvesUsersOtherThanSender: Bool {
        switch self {
        case .added(herself: true), .left, .teamMemberLeave: false
        default:                                             true
        }
    }

    var allowsCollapsing: Bool {
        // Don't collapse when removing participants, since the collapsed
        // link is only used for participants in the conversation.
        switch self {
        case .removed:  false
        default:        true
        }
    }

    func image(with color: UIColor) -> UIImage {
        let icon: StyleKitIcon = switch self {
        case .none,                   .started: .conversation
        case .added:                            .plus
        case .left, .removed, .teamMemberLeave: .minus
        }

        return icon.makeImage(size: .tiny, color: color)
    }
}

extension ZMConversationMessage {
    var actionType: ConversationActionType {
        guard let systemMessage = systemMessageData else {
            return .none
        }
        switch systemMessage.systemMessageType {
        case .participantsRemoved:  return systemMessage.userIsTheSender
            ? .left
            : .removed(reason: systemMessage.participantsRemovedReason)

        case .participantsAdded:    return .added(herself: systemMessage.userIsTheSender)

        case .newConversation:      return .started(withName: systemMessage.text)

        case .teamMemberLeave:      return .teamMemberLeave

        default:                    return .none
        }
    }
}

// MARK: - ParticipantsCellViewModel

final class ParticipantsCellViewModel {
    // MARK: Lifecycle

    init(
        font: UIFont?,
        largeFont: UIFont?,
        textColor: UIColor,
        iconColor: UIColor,
        message: ZMConversationMessage
    ) {
        self.font = font
        self.largeFont = largeFont
        self.textColor = textColor
        self.iconColor = iconColor
        self.message = message
    }

    // MARK: Internal

    static let showMoreLinkURL = NSURL(string: "action://show-all")!

    let font, largeFont: UIFont?
    let textColor, iconColor: UIColor
    let message: ZMConversationMessage

    /// Users displayed in the system message, up to 17 when not collapsed
    /// but only 15 when there are more than 15 users and we collapse them.
    lazy var shownUsers: [UserType] = {
        let users = sortedUsersWithoutSelf
        let boundary = users.count > maxShownUsers && action.allowsCollapsing ? maxShownUsersWhenCollapsed : users.count
        let result = users[..<boundary]

        guard let selfUser = sortedUsers.first(where: \.isSelfUser) else {
            return users
        }
        return result + [selfUser]
    }()

    lazy var isSelfIncludedInUsers: Bool = sortedUsers.any(\.isSelfUser)

    /// The users involved in the conversation action sorted alphabetically by
    /// name.
    lazy var sortedUsers: [UserType] = {
        guard let sender = message.senderUser else {
            return []
        }
        guard action.involvesUsersOtherThanSender else {
            return [sender]
        }
        guard let systemMessage = message.systemMessageData else {
            return []
        }

        let usersWithoutSender: Set<AnyHashable> = if case let .removed(reason) = action,
                                                      reason == .federationTermination {
            systemMessage.userTypes
        } else if let hashableSender = sender as? AnyHashable {
            systemMessage.userTypes.subtracting([hashableSender])
        } else {
            systemMessage.userTypes
        }
        guard let users = Array(usersWithoutSender) as? [UserType] else {
            return []
        }

        return users.sorted { name(for: $0) < name(for: $1) }
    }()

    lazy var sortedUsersWithoutSelf: [UserType] = sortedUsers.filter { !$0.isSelfUser }

    /// The users to display when opening the participants details screen.
    var selectedUsers: [UserType] {
        switch action {
        case .added: sortedUsers
        default: []
        }
    }

    // ------------------------------------------------------------

    func image() -> UIImage? {
        action.image(with: iconColor)
    }

    func attributedHeading() -> NSAttributedString? {
        guard
            case let .started(withName: conversationName?) = action,
            let sender = message.senderUser,
            let formatter = formatter(for: message)
        else {
            return nil
        }

        let senderName = name(for: sender).capitalized
        return formatter.heading(senderName: senderName, senderIsSelf: sender.isSelfUser, convName: conversationName)
    }

    func attributedTitle() -> NSAttributedString? {
        guard
            let sender = message.senderUser,
            let formatter = formatter(for: message)
        else {
            return nil
        }

        let senderName = name(for: sender).capitalized

        if action.involvesUsersOtherThanSender {
            return formatter.title(
                senderName: senderName,
                senderIsSelf: sender.isSelfUser,
                names: nameList,
                isSelfIncludedInUsers: isSelfIncludedInUsers
            )
        } else {
            return formatter.title(senderName: senderName, senderIsSelf: sender.isSelfUser)
        }
    }

    func warning() -> String? {
        guard showServiceUserWarning else {
            return nil
        }
        return L10n.Localizable.Content.System.Services.warning
    }

    // MARK: Private

    private typealias NameList = ParticipantsStringFormatter.NameList

    /// Users not displayed in the system message but collapsed into a link.
    /// E.g. `and 5 others`.
    private lazy var collapsedUsers: [UserType] = {
        let users = sortedUsersWithoutSelf
        guard users.count > maxShownUsers, action.allowsCollapsing else {
            return []
        }
        return Array(users.dropFirst(maxShownUsersWhenCollapsed))
    }()

    private var action: ConversationActionType {
        message.actionType
    }

    private var maxShownUsers: Int {
        isSelfIncludedInUsers ? 16 : 17
    }

    private var maxShownUsersWhenCollapsed: Int {
        isSelfIncludedInUsers ? 14 : 15
    }

    private var showServiceUserWarning: Bool {
        guard case .added = action,
              let messageData = message.systemMessageData,
              let conversation = message.conversationLike else {
            return false
        }
        guard let users = Array(messageData.userTypes) as? [UserType] else {
            return false
        }

        let selfAddedToServiceConversation = users.any(\.isSelfUser) && conversation.areServicesPresent
        let serviceAdded = users.any(\.isServiceUser)
        return selfAddedToServiceConversation || serviceAdded
    }

    private var nameList: NameList {
        var userNames = shownUsers.map { name(for: $0) }
        /// If users were removed due to legal hold policy conflict and there is a selfUser in that list, we should only
        /// display selfUser
        if case .removed(reason: .legalHoldPolicyConflict) = action,
           let selfUser = sortedUsers.first(where: \.isSelfUser),
           !sortedUsersWithoutSelf.isEmpty {
            userNames = [name(for: selfUser)]
        }

        return NameList(names: userNames, collapsed: collapsedUsers.count, selfIncluded: isSelfIncludedInUsers)
    }

    private func name(for user: UserType) -> String {
        if user.isSelfUser {
            "content.system.you_\(grammaticalCase(for: user))".localized
        } else {
            user.name ?? L10n.Localizable.Conversation.Status.someone
        }
    }

    /// The user will, depending on the context, be in a specific case within the
    /// sentence. This is important for localization of "you".
    private func grammaticalCase(for user: UserType) -> String {
        // user is always the subject
        if message.isUserSender(user) {
            return "nominative"
        }
        // "started with ... user"
        if case .started = action {
            return "dative"
        }

        // If there is selfUser in the list, we should only display selfUser as "You"
        if case .removed(reason: .legalHoldPolicyConflict) = action,
           !sortedUsers.filter(\.isSelfUser).isEmpty {
            return "started"
        }

        return "accusative"
    }

    private func formatter(for message: ZMConversationMessage) -> ParticipantsStringFormatter? {
        guard let font, let largeFont else {
            return nil
        }

        return ParticipantsStringFormatter(
            message: message, font: font,
            largeFont: largeFont, textColor: textColor
        )
    }
}
