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

/**
 * The actions that can be performed from the profile details or devices.
 */

enum ProfileAction: Equatable {
    case createGroup
    case mute(isMuted: Bool)
    case manageNotifications
    case archive
    case deleteContents
    case block(isBlocked: Bool)
    case openOneToOne
    case startOneToOne
    case removeFromGroup
    case connect
    case cancelConnectionRequest
    case openSelfProfile
    case duplicateUser
    case duplicateTeam

    /// The text of the button for this action.
    var buttonText: String {
        switch self {
        case .createGroup: return L10n.Localizable.Profile.createConversationButtonTitle
        case .mute(let isMuted): return isMuted
            ? L10n.Localizable.Meta.Menu.Silence.unmute
            : L10n.Localizable.Meta.Menu.Silence.mute
        case .manageNotifications: return L10n.Localizable.Meta.Menu.configureNotifications
        case .archive: return L10n.Localizable.Meta.Menu.archive
        case .deleteContents: return L10n.Localizable.Meta.Menu.clearContent
        case .block(let isBlocked): return isBlocked
            ? L10n.Localizable.Profile.unblockButtonTitle
            : L10n.Localizable.Profile.blockButtonTitle
        case .openOneToOne: return L10n.Localizable.Profile.openConversationButtonTitle
        case .startOneToOne: return L10n.Localizable.Profile.startConversationButtonTitle
        case .removeFromGroup: return L10n.Localizable.Profile.removeDialogButtonRemove
        case .connect: return L10n.Localizable.Profile.ConnectionRequestDialog.buttonConnect
        case .cancelConnectionRequest: return L10n.Localizable.Meta.Menu.cancelConnectionRequest
        case .openSelfProfile: return L10n.Localizable.Meta.Menu.openSelfProfile
        case .duplicateUser: return "⚠️ DEBUG - Duplicate User"
        case .duplicateTeam: return "⚠️ DEBUG - Duplicate Team"
        }
    }

    /// The icon of the button for this action, if it's eligible to be a key action.
    var keyActionIcon: StyleKitIcon? {
        switch self {
        case .createGroup: return .createConversation
        case .manageNotifications, .mute: return nil
        case .archive: return nil
        case .deleteContents: return nil
        case .block: return nil
        case .openOneToOne: return .conversation
        case .startOneToOne: return .conversation
        case .removeFromGroup: return .minus
        case .connect: return .plus
        case .cancelConnectionRequest: return .undo
        case .openSelfProfile: return .personalProfile
        case .duplicateUser: return nil
        case .duplicateTeam: return nil
        }
    }

    /// Whether the action can be used as a key action.
    var isEligibleForKeyAction: Bool {
        return keyActionIcon != nil
    }

}

// sourcery: AutoMockable
protocol ProfileActionsFactoryProtocol {
    func makeActionsList(completion: @escaping ([ProfileAction]) -> Void)
}

/**
 * An object that returns the actions that a user can perform in the scope
 * of a conversation.
 */

final class ProfileActionsFactory: ProfileActionsFactoryProtocol {

    // MARK: - Environmemt

    /// The user that is displayed in the profile details.
    let user: UserType

    /// The user that wants to perform the actions.
    let viewer: UserType

    /// The conversation that the user wants to perform the actions in.
    let conversation: ZMConversation?

    /// The context of the Profile VC
    let context: ProfileViewControllerContext

    /// The user session, providing use cases
    let userSession: UserSession

    // MARK: - Initialization

    /**
     * Creates the action controller with the specified environment.
     * - parameter user: The user that is displayed in the profile details.
     * - parameter viewer: The user that wants to perform the actions.
     * - parameter conversation: The conversation that the user wants to
     * perform the actions in.
     */

    init(
        user: UserType,
        viewer: UserType,
        conversation: ZMConversation?,
        context: ProfileViewControllerContext,
        userSession: UserSession
    ) {
        self.user = user
        self.viewer = viewer
        self.conversation = conversation
        self.context = context
        self.userSession = userSession
    }

    // MARK: - Calculating the Actions

    /// Calculates the list of actions to display to the user.
    ///
    /// - Returns: array of availble actions
    func makeActionsList(completion: @escaping ([ProfileAction]) -> Void) {
        guard let userID = user.qualifiedID else {
            return completion([])
        }

        Task {
            let isOneOnOneReady = await isOneOnOneReady(userID: userID)

            await MainActor.run {
                let actionsList = makeActionsList(isOneOnOneReady: isOneOnOneReady)
                completion(actionsList)
            }
        }
    }

    private func isOneOnOneReady(userID: QualifiedID) async -> Bool {
        do {
            return try await userSession.checkOneOnOneConversationIsReady.invoke(userID: userID)
        } catch {
            // We assume the conversation is not ready and we log the error
            //
            // Note: It could be that the user wasn't found,
            // which is to be expected if it's an unconnected search user

            WireLogger.conversation.warn("failed to check 1:1 conversation readiness: \(error)")
            return false
        }
    }

    private func makeActionsList(isOneOnOneReady: Bool) -> [ProfileAction] {

        // Do nothing if the user was deleted
        if user.isAccountDeleted {
            return []
        }

        // if the user is viewing their own profile by tapping his name/icon of
        // a sent message, add the open self-profile screen button
        if viewer.isSelfUser && user.isSelfUser {
            return [.openSelfProfile]
        }

        // Do not show any action if the user is blocked
        if user.isBlocked {
            return user.canBeUnblocked ? [.block(isBlocked: true)] : []
        }

        var conversation: ZMConversation?

        // If there is no conversation and open profile from a conversation, offer to connect to the user if possible
        if let selfConversation = self.conversation {
            conversation = selfConversation
        } else if context == .profileViewer {
            conversation = nil
        } else if !user.isConnected {
            if user.isPendingApprovalByOtherUser {
                return [.cancelConnectionRequest]
            } else if !user.isPendingApprovalBySelfUser {
                return [.connect]
            }
        }

        var actions: [ProfileAction] = []

        switch (context, conversation?.conversationType) {
        case (_, .oneOnOne?):

            if viewer.canCreateConversation(type: .group) {
                actions.append(.createGroup)
            }

            // Notifications, Archive, Delete Contents if available for every 1:1
            if let conversation {
                let notificationAction: ProfileAction = viewer.isTeamMember ? .manageNotifications : .mute(isMuted: conversation.mutedMessageTypes != .none)
                actions.append(contentsOf: [notificationAction, .archive, .deleteContents])
            }

            // If the viewer is not on the same team as the other user, allow blocking
            if !viewer.canAccessCompanyInformation(of: user) && !user.isWirelessUser {
                actions.append(.block(isBlocked: false))
            }

            // only for debug
            if DeveloperFlag.debugDuplicateObjects.isOn {
                actions.append(.duplicateUser)
                if user.isTeamMember {
                    actions.append(.duplicateTeam)
                }
            }

        case (.profileViewer, .none),
            (.search, .none),
            (_, .group?):
            // Do nothing if the viewer is a wireless user because they can't have 1:1's
            if viewer.isWirelessUser {
                break
            }

            let isOnSameTeam = viewer.isOnSameTeam(otherUser: user)

            // Show connection request actions for unconnected users from different teams.
            if user.isPendingApprovalByOtherUser {
                actions.append(.cancelConnectionRequest)
            } else if (user.isConnected && !user.hasEmptyName) || isOnSameTeam {
                if isOneOnOneReady {
                    actions.append(.openOneToOne)
                } else {
                    actions.append(.startOneToOne)
                }
            } else if user.canBeConnected && !user.isPendingApprovalBySelfUser {
                actions.append(.connect)
            }

            // Only non-guests and non-partners are allowed to remove
            if let conversation, viewer.canRemoveUser(from: conversation) {
                actions.append(.removeFromGroup)
            }

            // If the user is not from the same team as the other user, allow blocking

            if user.isConnected && !isOnSameTeam && !user.isWirelessUser && !user.hasEmptyName {
                actions.append(.block(isBlocked: false))
            }

        default:
            break
        }

        return actions
    }
}

extension UserType {

    var canBeUnblocked: Bool {
        switch blockState {
        case .blockedMissingLegalholdConsent:
            return false
        default:
            return true
        }
    }

}
