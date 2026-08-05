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
import WireLogging
import WireSyncEngine
import WireUtilities

private enum AdminPromotionError: Error {
    case adminRoleNotFound
}

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
            let isPreventAdminlessGroupsEnabled: Bool = if DeveloperFlag.preventAdminlessGroups.isOn {
                true
            } else {
                await session.clientSessionComponent?
                    .featureConfigRepository.isFeatureEnabled(.preventAdminlessGroups) ?? false
            }

            guard isPreventAdminlessGroupsEnabled, self.isLastAdmin(in: conversation) else {
                self.request(LeaveResult.self) { result in
                    self.handleLeaveResult(result, for: conversation)
                }
                return
            }

            guard let zmSession = session as? ZMUserSession else { return }

            let eligibleCandidates = eligibleAdminCandidates(in: conversation)
            let hasEligibleCandidates = !eligibleCandidates.isEmpty
            let groupName = conversation.displayNameWithFallback
            let canSelfUserDeleteConversation = zmSession.selfUser.canDeleteConversation(conversation)

            switch (hasEligibleCandidates, canSelfUserDeleteConversation) {

            // no eligibles candidates and admin can delete group
            case (false, true):
                self.present(LastAdminLeaveAlert.deleteOnly(groupName: groupName) { [weak self] in
                    self?.requestDeleteGroupResult { [weak self] confirmed in
                        guard let self, confirmed else { return }
                        handleDeleteGroupResult(confirmed, conversation: conversation, in: zmSession)
                    }
                })

            // eligible candidates and admin can delete group
            case (true, true):
                self.present(LastAdminLeaveAlert.promoteOrDelete(groupName: groupName) { [weak self] in
                    self?.presentAdminSelection(for: conversation, candidates: eligibleCandidates)
                } onDelete: { [weak self] in
                    self?.requestDeleteGroupResult { [weak self] confirmed in
                        guard let self, confirmed else { return }
                        handleDeleteGroupResult(confirmed, conversation: conversation, in: zmSession)
                    }
                })

            // eligible candidates and admin cannot delete group
            case (true, false):
                self.present(LastAdminLeaveAlert.promoteOnly(groupName: groupName) { [weak self] in
                    self?.presentAdminSelection(for: conversation, candidates: eligibleCandidates)
                })

            // no eligible candidates and admin cannot delete group
            case (false, false):
                self.present(LastAdminLeaveAlert.cannotLeave(groupName: groupName))
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

    @MainActor
    private func presentAdminSelection(
        for conversation: ZMConversation,
        candidates: [UserType],
        showAlert: Bool = false
    ) {
        let session = userSession
        let viewModel = AdminSelectionViewModel(
            candidates: candidates,
            userSession: session,
            showError: showAlert,
            onPromote: { [weak self] user in
                guard let self else {
                    throw CancellationError()
                }
                do {
                    try await performAdminPromotion(user: user, in: conversation) { removeParticipantResult in
                        switch removeParticipantResult {
                        case .success:
                            break

                        case let .failure(ConversationRemoveParticipantError.requiresAdmin(eligibleMembers)):
                            let newEligibleCandidates: [UserType] = conversation.localParticipantsExcludingSelf
                                .filter { participant in
                                    guard let id = participant.qualifiedID else {
                                        return false
                                    }

                                    return eligibleMembers.contains {
                                        $0.id == id.uuid && $0.domain == id.domain
                                    }
                                }

                            self.presentAdminSelection(
                                for: conversation,
                                candidates: newEligibleCandidates,
                                showAlert: true
                            )

                        case let .failure(error):
                            // error alert displayed within `removeOrShowError` method, see `showAlertForRemoval`.
                            WireLogger.conversation.warn("remove participant failed: \(error)")
                        }
                    }
                } catch {
                    WireLogger.conversation.warn("admin promotion failed: \(error)")
                    // Re-throw so AdminSelectionViewModel can set `.failed`
                    throw error
                }
            }
        )
        let hostingController = UIHostingController(rootView: AdminSelectionView(viewModel: viewModel))
        present(hostingController)
    }

    private typealias RemoveParticipantResultHandler = (Result<Void, Error>) -> Void

    @MainActor
    private func performAdminPromotion(
        user: UserType,
        in conversation: ZMConversation,
        removeParticipantResultHandler: RemoveParticipantResultHandler? = nil
    ) async throws {
        let roles = conversation.getRoles()
        guard let adminRole = roles.first(where: { $0.name == ZMConversation.defaultAdminRoleName }) else {
            throw AdminPromotionError.adminRoleNotFound
        }
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                conversation.updateRole(of: user, to: adminRole) { result in
                    switch result {
                    case .success: continuation.resume()
                    case let .failure(error): continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            WireLogger.conversation.warn("admin promotion failed: \(error)")
            throw error
        }
        guard let selfUser = SelfUser.provider?.providedSelfUser else { return }
        conversation.removeOrShowError(participant: selfUser, completion: removeParticipantResultHandler)
    }

}
