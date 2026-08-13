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
            title: L10n.Localizable.Meta.Menu.MlsMigration.Confirmation.title,
            message: L10n.Localizable.Meta.Menu.MlsMigration.Confirmation.message,
            preferredStyle: .alert
        )
        controller.addAction(.cancel())
        controller.addAction(
            UIAlertAction(
                title: L10n.Localizable.Meta.Menu.MlsMigration.Confirmation.button,
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

        Task { [weak self] in
            do {
                try await useCase.invoke(
                    conversationID: conversationID,
                    syncContext: syncContext
                )
                await MainActor.run { self?.presentMLSMigrationSuccess() }
            } catch {
                await MainActor.run { self?.presentMLSMigrationFailure(error) }
            }
        }
    }

    private func presentMLSMigrationSuccess() {
        let controller = UIAlertController(
            title: L10n.Localizable.Meta.Menu.MlsMigration.Success.title,
            message: L10n.Localizable.Meta.Menu.MlsMigration.Success.message,
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(title: L10n.Localizable.General.ok, style: .default))
        present(controller)
    }

    private func presentMLSMigrationFailure(_ error: Error) {
        let controller = UIAlertController(
            title: L10n.Localizable.Meta.Menu.MlsMigration.Failure.title,
            message: localizedDescription(for: error),
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(title: L10n.Localizable.General.ok, style: .default))
        present(controller)
    }

    private func localizedDescription(for error: Error) -> String {
        guard let failure = error as? MigrateConversationToMLSUseCase.Failure else {
            return error.localizedDescription
        }

        return switch failure {
        case .conversationNotFound:
            L10n.Localizable.Meta.Menu.MlsMigration.Failure.conversationNotFound
        case .unsupportedConversation:
            L10n.Localizable.Meta.Menu.MlsMigration.Failure.unsupportedConversation
        case .missingMLSService:
            L10n.Localizable.Meta.Menu.MlsMigration.Failure.missingMlsService
        case .missingMLSGroupID:
            L10n.Localizable.Meta.Menu.MlsMigration.Failure.missingMlsGroupId
        }
    }

}
