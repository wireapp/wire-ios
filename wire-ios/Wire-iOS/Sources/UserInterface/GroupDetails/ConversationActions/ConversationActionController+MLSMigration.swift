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

import UIKit
import WireDataModel
import WireLocators

extension ConversationActionController {

    func requestMLSMigration(for conversation: ZMConversation) {
        let controller = UIAlertController(
            title: "Migrate conversation to MLS?",
            message: "This internal action bypasses the normal MLS rollout conditions and immediately migrates this conversation.",
            preferredStyle: .alert
        )
        controller.addAction(.cancel())
        controller.addAction(
            UIAlertAction(
                title: "Migrate",
                style: .destructive,
                accessibilityIdentifier: Locators.ConversationDetailsActions.migrateToMLS.rawValue
            ) { [weak self] _ in
                self?.migrateConversationToMLS(conversation)
            }
        )
        present(controller)
    }

    private func migrateConversationToMLS(_ conversation: ZMConversation) {
        guard let conversationID = conversation.qualifiedID,
              let syncContext = conversation.managedObjectContext?.zm_sync
        else {
            presentMLSMigrationFailure(
                MigrateConversationToMLSUseCase.Failure.conversationNotFound
            )
            return
        }

        let useCase = MigrateConversationToMLSUseCase()

        Task { @MainActor [weak self] in
            do {
                try await useCase.invoke(
                    conversationID: conversationID,
                    syncContext: syncContext
                )
                self?.presentMLSMigrationSuccess()
            } catch {
                self?.presentMLSMigrationFailure(error)
            }
        }
    }

    private func presentMLSMigrationSuccess() {
        let controller = UIAlertController(
            title: "MLS migration completed",
            message: "The conversation now uses MLS.",
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(title: L10n.Localizable.General.ok, style: .default))
        present(controller)
    }

    private func presentMLSMigrationFailure(_ error: Error) {
        let controller = UIAlertController(
            title: "MLS migration failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(title: L10n.Localizable.General.ok, style: .default))
        present(controller)
    }

}
