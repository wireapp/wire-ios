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

import WireSyncEngine

extension GroupDetailsConversation where Self: ZMConversation {
    var freeParticipantSlots: Int {
        return ZMConversation.maxParticipants - localParticipants.count
    }
}

extension ZMConversation {
    private enum ConversationError: Error {
        case offline
        case invalidOperation
    }

    static let legacyGroupVideoParticipantLimit: Int = 4

    static let maxParticipants: Int = 500

    static var maxParticipantsExcludingSelf: Int {
        return maxParticipants - 1
    }

    func addOrShowError(participants: [UserType]) {
        Flow.addParticipants.start()
        guard
            let session = ZMUserSession.shared(),
            session.networkState != .offline
        else {
            Flow.addParticipants.fail(ConversationError.offline)
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

                let conversation = try await syncContext.perform { [self] in
                    return try ZMConversation.existingObject(for: self.objectID, in: syncContext)
                }

                try await service.addParticipants(users, to: conversation)
            } catch {
                Flow.addParticipants.fail(error)
                await MainActor.run {
                    self.showAlertForAdding(for: error)
                }
            }
            Flow.addParticipants.succeed()
        }
    }

    func removeOrShowError(participant user: UserType, completion: ((Result<Void, Error>) -> Void)? = nil) {

        @Sendable func fail(with error: Error) {
            showAlertForRemoval(for: error)
            completion?(.failure(error))
        }

        guard
            let session = ZMUserSession.shared(),
            session.networkState != .offline
        else {
            return fail(with: ConversationError.offline)
        }

        guard let user = user.materialize(in: session.viewContext) else {
            return fail(with: ConversationError.invalidOperation)
        }

        let syncContext = session.syncContext
        let service = ConversationParticipantsService(context: syncContext)

        Task {
            do {
                let user = try await syncContext.perform {
                    return try ZMUser.existingObject(for: user.objectID, in: syncContext)
                }

                let conversation = try await syncContext.perform { [self] in
                    return try ZMConversation.existingObject(for: self.objectID, in: syncContext)
                }

                try await service.removeParticipant(user, from: conversation)

                await MainActor.run {
                    completion?(.success(()))
                }

            } catch {
                await MainActor.run {
                    fail(with: error)
                }
            }
        }
    }

    private func showAlertForAdding(for error: Error) {
        typealias ErrorString = L10n.Localizable.Error.Conversation

        switch error {
        case ConversationAddParticipantsError.tooManyMembers:
            showErrorAlert(title: ErrorString.title, message: ErrorString.tooManyMembers)
        case ConversationError.offline:
            showErrorAlert(title: ErrorString.title, message: ErrorString.offline)
        case ConversationAddParticipantsError.missingLegalHoldConsent:
            showErrorAlert(title: ErrorString.title, message: ErrorString.missingLegalholdConsent)
        default:
            showErrorAlert(title: ErrorString.title, message: ErrorString.cannotAdd)
        }
    }

    private func showAlertForRemoval(for error: Error) {
        typealias ErrorString = L10n.Localizable.Error.Conversation

        switch error {
        case ConversationError.offline:
            showErrorAlert(title: ErrorString.title, message: ErrorString.offline)
        default:
            showErrorAlert(title: ErrorString.title, message: ErrorString.cannotRemove)
        }
    }

    private func showErrorAlert(
        title: String,
        message: String
    ) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        let viewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)
        viewController?.present(alertController, animated: true)
    }
}
