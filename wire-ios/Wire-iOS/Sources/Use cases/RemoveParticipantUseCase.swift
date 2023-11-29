//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireSyncEngine

protocol RemoveParticipantUseCaseProtocol {

    func invoke(
        with user: UserType,
        conversation: Conversation,
        in session: UserSession,
        completion: ((VoidResult) -> Void)?
    )

}

struct RemoveParticipantUseCase: RemoveParticipantUseCaseProtocol {

    func invoke(
        with user: UserType,
        conversation: Conversation,
        in session: UserSession,
        completion: ((VoidResult) -> Void)?
    ) {
        @Sendable func fail(with error: Error) {
            showAlertForRemoval(for: error)
            completion?(.failure(error))
        }

        guard session.networkState != .offline else {
            return fail(with: ConversationError.offline)
        }

        guard
            let session = session as? ZMUserSession,
            let conversation = conversation as? ZMConversation,
            let user = user.materialize(in: session.viewContext)
        else {
            return fail(with: ConversationError.invalidOperation)
        }

        let syncContext = session.syncContext
        let service = ConversationParticipantsService(context: syncContext)

        Task {
            do {
                let user = try await syncContext.perform {
                    return try ZMUser.existingObject(for: user.objectID, in: syncContext)
                }

                let conversation = try await syncContext.perform {
                    return try ZMConversation.existingObject(for: conversation.objectID, in: syncContext)
                }

                try await service.removeParticipant(user, from: conversation)

                if await syncContext.perform({ user.isServiceUser }) {
                    Analytics.shared.tagDidRemoveService(user as ServiceUser)
                }

                await MainActor.run {
                    completion?(.success)
                }

            } catch {
                await MainActor.run {
                    fail(with: error)
                }
            }
        }
    }

    private func showAlertForRemoval(for error: Error) {
        typealias ErrorString = L10n.Localizable.Error.Conversation

        switch error {
        case ConversationError.offline:
            UIAlertController.showErrorAlert(title: ErrorString.title, message: ErrorString.offline)
        default:
            UIAlertController.showErrorAlert(title: ErrorString.title, message: ErrorString.cannotRemove)
        }
    }

}
