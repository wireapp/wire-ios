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
import WireDataModel

extension ZMConversation {
    enum Action: Equatable {

        case deleteGroup
        case moveToFolder
        case removeFromFolder(folder: String)
        case clearContent
        case leave
        case configureNotifications
        case silence(isSilenced: Bool)
        case archive(isArchived: Bool)
        case cancelRequest
        case block(isBlocked: Bool)
        case markRead
        case markUnread
        case remove
        case favorite(isFavorite: Bool)

    }

    var listActions: [Action] {
        return actions.filter({ $0 != .deleteGroup })
    }

    var detailActions: [Action] {
        return actions.filter({ $0 != .configureNotifications })
    }

    private var actions: [Action] {
        switch conversationType {
        case .connection:
            return availablePendingActions()
        case .oneOnOne:
            return availableOneToOneActions()
        case .self,
             .group,
             .invalid:
            return availableGroupActions()
        }
    }

    private func availableOneToOneActions() -> [Action] {
        precondition(conversationType == .oneOnOne)
        var actions = [Action]()
        actions.append(contentsOf: availableStandardActions())
        actions.append(.clearContent)
        if teamRemoteIdentifier == nil, let connectedUser {
            actions.append(.block(isBlocked: connectedUser.isBlocked))
        }
        return actions
    }

    private func availablePendingActions() -> [Action] {
        precondition(conversationType == .connection)
        return [.archive(isArchived: isArchived), .cancelRequest]
    }

    private func availableGroupActions() -> [Action] {
        var actions = availableStandardActions()
        actions.append(.clearContent)

        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return actions
        }
        if localParticipants.contains(selfUser) {
            actions.append(.leave)
        }

        if selfUser.canDeleteConversation(self) {
            actions.append(.deleteGroup)
        }

        return actions
    }

    private func availableStandardActions() -> [Action] {
        var actions = [Action]()

        if let markReadAction = markAsReadAction() {
            actions.append(markReadAction)
        }

        if !isReadOnly {
            if ZMUser.selfUser()?.isTeamMember ?? false {
                actions.append(.configureNotifications)
            } else {
                let isSilenced = mutedMessageTypes != .none
                actions.append(.silence(isSilenced: isSilenced))
            }
        }

        actions.append(.archive(isArchived: isArchived))

        if !isArchived {
            actions.append(.favorite(isFavorite: isFavorite))
            actions.append(.moveToFolder)

            if let folderName = folder?.name {
                actions.append(.removeFromFolder(folder: folderName))
            }
        }

        return actions
    }

    private func markAsReadAction() -> Action? {
        guard Bundle.developerModeEnabled else { return nil }
        if unreadMessages.count > 0 {
            return .markRead
        } else if unreadMessages.count == 0 && canMarkAsUnread() {
            return .markUnread
        }
        return nil
    }
}

extension ZMConversation.Action {

    fileprivate var isDestructive: Bool {
        switch self {
        case .remove,
             .deleteGroup:
            return true
        default: return false
        }
    }

    var title: String {
        typealias MetaMenuLocale = L10n.Localizable.Meta.Menu
        typealias ProfileLocale = L10n.Localizable.Profile

        switch self {
        case .deleteGroup:
            return MetaMenuLocale.delete
        case .moveToFolder:
            return MetaMenuLocale.moveToFolder
        case .removeFromFolder(let folder):
            return MetaMenuLocale.removeFromFolder(folder)
        case .remove:
            return ProfileLocale.removeDialogButtonRemove
        case .clearContent:
            return MetaMenuLocale.clearContent
        case .leave:
            return MetaMenuLocale.leave
        case .markRead:
            return MetaMenuLocale.markRead
        case .markUnread:
            return MetaMenuLocale.markUnread
        case .configureNotifications:
            return MetaMenuLocale.configureNotifications
        case .silence(isSilenced: let muted):
            return muted ? MetaMenuLocale.Silence.unmute : MetaMenuLocale.Silence.mute
        case .archive(isArchived: let archived):
            return archived ? MetaMenuLocale.unarchive : MetaMenuLocale.archive
        case .cancelRequest:
            return MetaMenuLocale.cancelConnectionRequest
        case .block(isBlocked: let blocked):
            return blocked ? ProfileLocale.unblockButtonTitle : ProfileLocale.blockButtonTitle
        case .favorite(isFavorite: let favorited):
            return favorited ? ProfileLocale.unfavoriteButtonTitle : ProfileLocale.favoriteButtonTitle
        }
    }

    func alertAction(handler: @escaping () -> Void) -> UIAlertAction {
        return .init(title: title, style: isDestructive ? .destructive : .default) { _ in handler() }
    }

    @available(iOS, introduced: 9.0, deprecated: 13.0, message: "UIViewControllerPreviewing is deprecated. Please use UIContextMenuInteraction.")
    func previewAction(handler: @escaping () -> Void) -> UIPreviewAction {
        return .init(title: title, style: isDestructive ? .destructive : .default, handler: { _, _ in handler() })
    }
}
