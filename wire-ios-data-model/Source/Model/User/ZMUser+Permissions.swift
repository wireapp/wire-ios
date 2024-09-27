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

// MARK: - ConversationAction

enum ConversationAction {
    case addConversationMember
    case removeConversationMember
    case modifyConversationName
    case modifyConversationMessageTimer
    case modifyConversationReceiptMode
    case modifyConversationAccess
    case modifyOtherConversationMember
    case leaveConversation
    case deleteConvesation

    var name: String {
        switch self {
        case .addConversationMember: "add_conversation_member"
        case .removeConversationMember: "remove_conversation_member"
        case .modifyConversationName: "modify_conversation_name"
        case .modifyConversationMessageTimer: "modify_conversation_message_timer"
        case .modifyConversationReceiptMode: "modify_conversation_receipt_mode"
        case .modifyConversationAccess: "modify_conversation_access"
        case .modifyOtherConversationMember: "modify_other_conversation_member"
        case .leaveConversation: "leave_conversation"
        case .deleteConvesation: "delete_conversation"
        }
    }
}

extension ZMUser {
    public var teamRole: TeamRole {
        TeamRole(rawPermissions: permissions?.rawValue ?? 0)
    }

    private var permissions: Permissions? {
        membership?.permissions
    }

    @objc(canAddServiceToConversation:)
    public func canAddService(to conversation: ZMConversation) -> Bool {
        guard !isGuest(in: conversation), conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.addConversationMember.name,
            conversation: conversation
        )
    }

    @objc(canRemoveServiceFromConversation:)
    public func canRemoveService(from conversation: ZMConversation) -> Bool {
        guard !isGuest(in: conversation), conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.removeConversationMember.name,
            conversation: conversation
        )
    }

    @objc(canAddUserToConversation:)
    public func canAddUser(to conversation: ConversationLike) -> Bool {
        guard conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.addConversationMember.name,
            conversation: conversation
        )
    }

    @objc(canRemoveUserFromConversation:)
    public func canRemoveUser(from conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.removeConversationMember.name,
            conversation: conversation
        )
    }

    @objc(canDeleteConversation:)
    public func canDeleteConversation(_ conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return false }
        let selfUser = ZMUser.selfUser(in: managedObjectContext!)

        return hasRoleWithAction(
            actionName: ConversationAction.deleteConvesation.name,
            conversation: conversation
        ) && conversation.creator == self
            && selfUser.hasTeam && selfUser.teamIdentifier == teamIdentifier
    }

    @objc(canModifyOtherMemberInConversation:)
    public func canModifyOtherMember(in conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.modifyOtherConversationMember.name,
            conversation: conversation
        )
    }

    @objc(canModifyReadReceiptSettingsInConversation:)
    public func canModifyReadReceiptSettings(in conversation: ConversationLike) -> Bool {
        guard conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.modifyConversationReceiptMode.name,
            conversation: conversation
        )
    }

    @objc(canModifyEphemeralSettingsInConversation:)
    public func canModifyEphemeralSettings(in conversation: ConversationLike) -> Bool {
        if conversation.conversationType == .group {
            return hasRoleWithAction(
                actionName: ConversationAction.modifyConversationMessageTimer.name,
                conversation: conversation
            )
        } else {
            guard
                conversation.teamRemoteIdentifier == nil || !isGuest(in: conversation),
                conversation.isSelfAnActiveMember
            else { return false }
            return permissions?.contains(.modifyConversationMetaData) ?? true
        }
    }

    @objc(canModifyNotificationSettingsInConversation:)
    public func canModifyNotificationSettings(in conversation: ConversationLike) -> Bool {
        guard conversation.isSelfAnActiveMember else { return false }

        return isTeamMember
    }

    @objc(canModifyAccessControlSettingsInConversation:)
    public func canModifyAccessControlSettings(in conversation: ConversationLike) -> Bool {
        guard conversation.conversationType == .group,
              conversation.teamRemoteIdentifier != nil
        else { return false }

        return hasRoleWithAction(
            actionName: ConversationAction.modifyConversationAccess.name,
            conversation: conversation
        )
    }

    @objc(canModifyTitleInConversation:)
    public func canModifyTitle(in conversation: ConversationLike) -> Bool {
        guard conversation.conversationType == .group else { return false }

        return hasRoleWithAction(actionName: ConversationAction.modifyConversationName.name, conversation: conversation)
    }

    @objc(canLeave:)
    public func canLeave(_ conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return true }
        return hasRoleWithAction(actionName: ConversationAction.leaveConversation.name, conversation: conversation)
    }

    @objc
    public func canCreateConversation(type: ZMConversationType) -> Bool {
        switch type {
        case .oneOnOne:
            // all users are allow to open 1-on-1 conversation
            true
        default:
            // partner is not allowed to create non 1-on-1 convo
            permissions?.contains(.member) ?? true
        }
    }

    @objc public var canCreateService: Bool {
        permissions?.contains(.member) ?? false
    }

    @objc public var canManageTeam: Bool {
        permissions?.contains(.admin) ?? false
    }

    public func canAccessCompanyInformation(of user: UserType) -> Bool {
        guard
            let context = managedObjectContext,
            let otherUser = user.unbox(in: context),
            let otherUserTeamID = otherUser.team?.remoteIdentifier,
            let selfUserTeamID = team?.remoteIdentifier
        else {
            return false
        }

        return selfUserTeamID == otherUserTeamID && !isFederating(with: otherUser)
    }

    @objc
    public func _isGuest(in conversation: ConversationLike) -> Bool {
        guard let conversation = conversation as? ZMConversation else { return false }
        if isSelfUser {
            // In case the self user is a guest in a team conversation, the backend will
            // return a 404 when fetching said team and we will delete the team.
            // We store the teamRemoteIdentifier of the team to check if we don't have a local team,
            // but received a teamId in the conversation payload, which means we are a guest in the conversation.

            if conversation.creator == self {
                return false
            }

            if conversation.isFederating(with: self) {
                return true
            }

            if let team {
                // If the self user belongs to a team he/she's a guest in every non team conversation
                return conversation.teamRemoteIdentifier != team.remoteIdentifier
            } else {
                // If the self user doesn't belong to a team he/she's a guest in all team conversations
                return conversation.teamRemoteIdentifier != nil
            }
        } else {
            guard let context = managedObjectContext else {
                return false
            }

            return !isServiceUser // Bots are never guests
                && !isFederated // Federated users are never guests
                && ZMUser.selfUser(in: context).hasTeam // There can't be guests in a team that doesn't exist
                && conversation.localParticipantsContain(user: self)
                && membership == nil
        }
    }

    private func hasRoleWithAction(actionName: String, conversation: ConversationLike) -> Bool {
        guard conversation.isSelfAnActiveMember,
              let role = role(in: conversation)
        else { return false }
        return role.actions.contains(where: { $0.name == actionName })
    }
}
