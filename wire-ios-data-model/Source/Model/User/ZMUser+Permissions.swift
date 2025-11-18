//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

enum ConversationAction {
    case addConversationMember
    case removeConversationMember
    case modifyConversationName
    case modifyConversationMessageTimer
    case modifyConversationReceiptMode
    case modifyConversationAccess
    case modifyOtherConversationMember
    case leaveConversation
    case deleteConversation
    case modifyAddPermission

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
        case .deleteConversation: "delete_conversation"
        case .modifyAddPermission: "modify_add_permission"
        }
    }
}

public extension ZMUser {

    var teamRole: TeamRole {
        TeamRole(rawPermissions: permissions?.rawValue ?? 0)
    }

    private var permissions: Permissions? {
        membership?.permissions
    }

    @objc(canAddServiceToConversation:)
    func canAddService(to conversation: ZMConversation) -> Bool {
        guard !isGuest(in: conversation), conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.addConversationMember.name,
            conversation: conversation
        )
    }

    @objc(canRemoveServiceFromConversation:)
    func canRemoveService(from conversation: ZMConversation) -> Bool {
        guard !isGuest(in: conversation), conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.removeConversationMember.name,
            conversation: conversation
        )
    }

    @objc(canAddUserToConversation:)
    func canAddUser(to conversation: ConversationLike) -> Bool {
        guard conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.addConversationMember.name,
            conversation: conversation
        ) || isChannelAdmin(conversation)
            || (conversation.privateChannelPermission == .everyone && conversation.isChannel)
    }

    @objc(canRemoveUserFromConversation:)
    func canRemoveUser(from conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.removeConversationMember.name,
            conversation: conversation
        ) || isChannelAdmin(conversation)
    }

    @objc(canDeleteConversation:)
    func canDeleteConversation(_ conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return false }
        let selfUser = ZMUser.selfUser(in: managedObjectContext!)
        if isChannelAdmin(conversation) {
            return true
        }
        return hasRoleWithAction(
            actionName: ConversationAction.deleteConversation.name,
            conversation: conversation
        ) && conversation.creator == self
            && selfUser.hasTeam && selfUser.teamIdentifier == teamIdentifier
    }

    @objc(canModifyOtherMemberInConversation:)
    func canModifyOtherMember(in conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.modifyOtherConversationMember.name,
            conversation: conversation
        ) || isChannelAdmin(conversation)
    }

    @objc(canModifyReadReceiptSettingsInConversation:)
    func canModifyReadReceiptSettings(in conversation: ConversationLike) -> Bool {
        guard conversation.conversationType == .group else { return false }
        return hasRoleWithAction(
            actionName: ConversationAction.modifyConversationReceiptMode.name,
            conversation: conversation
        ) || isChannelAdmin(conversation)
    }

    @objc(canModifyEphemeralSettingsInConversation:)
    func canModifyEphemeralSettings(in conversation: ConversationLike) -> Bool {
        if conversation.conversationType == .group {
            return hasRoleWithAction(
                actionName: ConversationAction.modifyConversationMessageTimer.name,
                conversation: conversation
            ) || isChannelAdmin(conversation)
        } else {
            guard
                conversation.teamRemoteIdentifier == nil || !isGuest(in: conversation),
                conversation.isSelfAnActiveMember
            else { return false }
            return permissions?.contains(.modifyConversationMetaData) ?? true
        }
    }

    @objc(canModifyNotificationSettingsInConversation:)
    func canModifyNotificationSettings(in conversation: ConversationLike) -> Bool {
        guard conversation.isSelfAnActiveMember else { return false }

        return isTeamMember
    }

    @objc(canModifyChannelAccessLevelSettingsInConversation:)
    func canModifyChannelAccessLevelSettings(in conversation: ConversationLike) -> Bool {
        (conversation.isChannel && hasRoleWithAction(
            actionName: ConversationAction.modifyAddPermission.name,
            conversation: conversation
        )) || isChannelAdmin(conversation)
    }

    @objc(canModifyChannelHistoryDepthSettingsInConversation:)
    func canModifyChannelHistoryDepthSettings(in conversation: ConversationLike) -> Bool {
        (conversation.isChannel && hasRoleWithAction(
            actionName: ConversationAction.modifyAddPermission.name,
            conversation: conversation
        )) || isChannelAdmin(conversation)
    }

    @objc(canModifyGuestsAccessControlSettingsInConversation:)
    func canModifyGuestsAccessControlSettings(in conversation: ConversationLike) -> Bool {
        guard conversation.conversationType == .group,
              conversation.teamRemoteIdentifier != nil
        else { return false }

        return hasRoleWithAction(
            actionName: ConversationAction.modifyConversationAccess.name,
            conversation: conversation
        ) || isChannelAdmin(conversation)
    }

    @objc(canModifyTitleInConversation:)
    func canModifyTitle(in conversation: ConversationLike) -> Bool {
        guard conversation.conversationType == .group else { return false }

        return hasRoleWithAction(actionName: ConversationAction.modifyConversationName.name, conversation: conversation)
            || isChannelAdmin(conversation)
    }

    @objc(canLeave:)
    func canLeave(_ conversation: ZMConversation) -> Bool {
        guard conversation.conversationType == .group else { return true }
        return hasRoleWithAction(actionName: ConversationAction.leaveConversation.name, conversation: conversation)
    }

    @objc
    func canCreateConversation(type: ZMConversationType) -> Bool {
        switch type {
        case .oneOnOne:
            // all users are allow to open 1-on-1 conversation
            true
        default:
            // partner is not allowed to create non 1-on-1 convo
            permissions?.contains(.member) ?? true
        }
    }

    @objc var canCreateService: Bool {
        permissions?.contains(.member) ?? false
    }

    @objc var canManageTeam: Bool {
        permissions?.contains(.admin) ?? false
    }

    func canAccessCompanyInformation(of user: UserType) -> Bool {
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
    func _isGuest(in conversation: ConversationLike) -> Bool {
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

            return !isApp // Bots are never guests
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

    private func isChannelAdmin(_ conversation: ConversationLike) -> Bool {
        conversation.isChannel && canManageTeam && conversation.teamRemoteIdentifier == team?.remoteIdentifier
    }
}
