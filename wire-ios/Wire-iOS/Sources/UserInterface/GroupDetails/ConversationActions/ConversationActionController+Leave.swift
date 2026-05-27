//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import SwiftUI
import WireDataModel
import WireLocators
import WireSyncEngine

enum LeaveResult: AlertResultConfiguration {
    case leave(delete: Bool)
    case cancel

    var title: String {
        switch self {
        case .cancel: L10n.Localizable.General.cancel
        case .leave(delete: true): L10n.Localizable.Meta.leaveConversationButtonLeaveAndDelete
        case .leave(delete: false): L10n.Localizable.Meta.leaveConversationButtonLeave
        }
    }

    private var style: UIAlertAction.Style {
        guard case .cancel = self else { return .destructive }
        return .cancel
    }

    func action(_ handler: @escaping (LeaveResult) -> Void) -> UIAlertAction {
        let action = UIAlertAction(title: title, style: style) { _ in handler(self) }
        let identifier: String? = switch self {
        case .leave(delete: true):
            Locators.ConversationsPage.leaveAndClearButtonOnBottomSheet.rawValue

        case .leave(delete: false):
            Locators.ConversationsPage.leaveButtonOnBottomSheet.rawValue

        case .cancel:
            nil
        }

        if let identifier {
            action.setValue(identifier, forKey: "accessibilityIdentifier")
        }
        return action

    }

    static var title: String {
        L10n.Localizable.Meta.leaveConversationDialogMessage
    }

    static var all: [LeaveResult] {
        [.leave(delete: true), .leave(delete: false), .cancel]
    }
}

extension ConversationActionController {

    func requestLeave(for conversation: ZMConversation) {
        let session = userSession
        Task { @MainActor in
            let isPreventAdminlessGroupsEnabled = await session.clientSessionComponent?
                .featureConfigRepository.isFeatureEnabled(.preventAdminlessGroups) ?? false

            guard isPreventAdminlessGroupsEnabled, self.isLastAdmin(in: conversation) else {
                self.request(LeaveResult.self) { result in
                    self.handleLeaveResult(result, for: conversation)
                }
                return
            }

            guard let zmSession = session as? ZMUserSession else { return }

            let eligibleCandidates = self.eligibleAdminCandidates(in: conversation)
            let groupName = conversation.displayNameWithFallback
            if eligibleCandidates.isEmpty {
                self.present(LastAdminLeaveAlert.deleteOnly(groupName: groupName) { [weak self] in
                    self?.requestDeleteGroupResult { [weak self] confirmed in
                        guard let self, confirmed else { return }
                        self.handleDeleteGroupResult(confirmed, conversation: conversation, in: zmSession)
                    }
                })
            } else {
                self.present(LastAdminLeaveAlert.promoteOrDelete(groupName: groupName) { [weak self] in
                    self?.presentAdminSelection(for: conversation, candidates: eligibleCandidates)
                } onDelete: { [weak self] in
                    self?.requestDeleteGroupResult { [weak self] confirmed in
                        guard let self, confirmed else { return }
                        self.handleDeleteGroupResult(confirmed, conversation: conversation, in: zmSession)
                    }
                })
            }
        }
    }

    func handleLeaveResult(_ result: LeaveResult, for conversation: ZMConversation) {
        guard case let .leave(delete: clearContent) = result else { return }
        guard let user = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        guard let conversationID = conversation.qualifiedID,
              let useCase = userSession.clientSessionComponent?
              .clearConversationContentUseCase(conversationID: conversationID) else {
            return
        }

        Task {
            if clearContent {
                await useCase.invoke()
            }
            await MainActor.run {
                userSession.enqueue {
                    conversation.removeOrShowError(participant: user)
                }
            }
        }
    }

    private func isLastAdmin(in conversation: ZMConversation) -> Bool {
        let admins = conversation.localParticipants.filter { $0.isGroupAdmin(in: conversation) }
        return admins.count == 1 && admins.first?.isSelfUser == true
    }

    private func eligibleAdminCandidates(in conversation: ZMConversation) -> [UserType] {
        conversation.localParticipantsExcludingSelf.filter {
            !$0.isGroupAdmin(in: conversation) &&
            !$0.isFederated &&
            !$0.isExternalPartner &&
            !$0.isTemporaryUser
        }
    }

    private func presentAdminSelection(for conversation: ZMConversation, candidates: [UserType]) {
        let session = userSession
        Task { @MainActor in
            let viewModel = AdminSelectionViewModel(
                candidates: candidates,
                userSession: session
            ) { [weak self] newAdmin in
                self?.promoteToAdmin(newAdmin, in: conversation)
            }
            let hostingController = UIHostingController(rootView: AdminSelectionView(viewModel: viewModel))
            self.present(hostingController)
        }
    }

    private func promoteToAdmin(_ user: UserType, in conversation: ZMConversation) {
        let groupRoles = conversation.getRoles()
        let adminRole = groupRoles.first { $0.name == ZMConversation.defaultAdminRoleName }
        guard let role = adminRole, let zmUser = (user as? ZMUser) ?? (user as? ZMSearchUser)?.user else {
            return
        }
        conversation.updateRole(of: zmUser, to: role) { [weak self] result in
            guard case .success = result else { return }
            self?.handleLeaveResult(.leave(delete: false), for: conversation)
        }
    }

}
