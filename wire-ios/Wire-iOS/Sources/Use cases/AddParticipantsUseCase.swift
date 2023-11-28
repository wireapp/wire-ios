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

protocol AddParticipantsUseCaseProtocol {

    func invoke(
        with participants: [UserType],
        conversation: Conversation,
        in session: UserSession
    )
}

enum ConversationError: Error {
    case offline
    case invalidOperation
}

struct AddParticipantsUseCase: AddParticipantsUseCaseProtocol {

    func invoke(
        with participants: [UserType],
        conversation: Conversation,
        in session: UserSession
    ) {
        guard
            let conversation = conversation as? ZMConversation,
            let session = session as? ZMUserSession
        else {
            return showAlertForAdding(for: ConversationError.invalidOperation)
        }

        guard session.networkState != .offline else {
            return showAlertForAdding(for: ConversationError.offline)
        }

        let users = participants.materialize(in: session.viewContext)
        let syncContext = session.syncContext
        let service = ConversationParticipantsService(context: syncContext)

        Task {
            do {
                let users = await syncContext.perform {
                    users.compactMap {
                        ZMUser.existingObject(for: $0.objectID, in: syncContext)
                    }
                }

                let conversation = try await syncContext.perform {
                    return try ZMConversation.existingObject(for: conversation.objectID, in: syncContext)
                }

                try await service.addParticipants(users, to: conversation)
            } catch {
                await MainActor.run {
                    self.showAlertForAdding(for: error)
                }
            }
        }
    }

    private func showAlertForAdding(for error: Error) {
        typealias ErrorString = L10n.Localizable.Error.Conversation

        switch error {
        case ConversationAddParticipantsError.tooManyMembers:
            UIAlertController.showErrorAlert(title: ErrorString.title, message: ErrorString.tooManyMembers)
        case ConversationError.offline:
            UIAlertController.showErrorAlert(title: ErrorString.title, message: ErrorString.offline)
        case ConversationAddParticipantsError.missingLegalHoldConsent:
            UIAlertController.showErrorAlert(title: ErrorString.title, message: ErrorString.missingLegalholdConsent)
        default:
            UIAlertController.showErrorAlert(title: ErrorString.title, message: ErrorString.cannotAdd)
        }
    }
}
