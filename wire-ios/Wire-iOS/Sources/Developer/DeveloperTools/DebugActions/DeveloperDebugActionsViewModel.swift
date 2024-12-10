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
import WireLogging
import WireSyncEngine

final class DeveloperDebugActionsViewModel: ObservableObject {

    @Published var buttons: [DeveloperDebugActionsDisplayModel.ButtonItem] = []

    private var userSession: ZMUserSession? { ZMUserSession.shared() }

    private let selfClient: UserClient?

    private let logger = WireLogger(tag: "developer")

    // MARK: - Initialize

    init(selfClient: UserClient?) {
        self.selfClient = selfClient

        setupButtons()
    }

    private func setupButtons() {
        buttons = [
            .init(title: "Send debug logs", action: sendDebugLogs),
            .init(title: "Perform quick sync", action: performQuickSync),
            .init(title: "Resync resources", action: resyncResources),
            .init(title: "Break next quick sync", action: breakNextQuickSync),
            .init(title: "Update Conversation to mixed protocol", action: updateConversationProtocolToMixed),
            .init(title: "Update Conversation to MLS protocol", action: updateConversationProtocolToMLS),
            .init(title: "Update MLS migration status", action: updateMLSMigrationStatus),
            .init(title: "Delete domains in the database", action: deleteDomains)
        ]
    }

    // MARK: Send Logs

    private func sendDebugLogs() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let rootViewController = appDelegate.mainWindow?.rootViewController else {
            return
        }

        var presentingViewController = rootViewController
        while let presentedViewController = presentingViewController.presentedViewController {
            presentingViewController = presentedViewController
        }

        DebugLogSender.sendLogsByEmail(
            message: "Send logs",
            shareWithAVS: false,
            presentingViewController: presentingViewController,
            fallbackActivityPopoverConfiguration: .sourceView(
                sourceView: presentingViewController.view,
                sourceRect: .init(
                    origin: presentingViewController.view.safeAreaLayoutGuide.layoutFrame.origin,
                    size: .zero
                )
            )
        )
    }

    // MARK: Quick Sync

    private func breakNextQuickSync() {
        userSession?.setBogusLastEventID()
    }

    private func performQuickSync() {
        guard let userSession else { return }

        Task {
            await userSession.syncStatus.performQuickSync()
        }
    }

    // MARK: Resync resources

    private func resyncResources() {
        DebugActions.triggerResyncResources()
    }

    // MARK: Proteus to MLS migration

    private func updateMLSMigrationStatus() {
        guard let userSession else { return }

        Task {
            do {
                try await userSession.updateMLSMigrationStatus()
            } catch {
                WireLogger.mls.error("failed to update MLS migration status: \(error)")
            }
        }
    }

    // MARK: Protocol Change

    private func updateConversationProtocolToMixed() {
        updateConversationProtocol(to: .mixed)
    }

    private func updateConversationProtocolToMLS() {
        updateConversationProtocol(to: .mls)
    }

    private func updateConversationProtocol(to messageProtocol: MessageProtocol) {
        guard
            let selfClient,
            let context = selfClient.managedObjectContext,
            let userSession
        else { return }

        Task {
            guard let qualifiedID = await qualifiedIDOfFirstGroupConversation(of: selfClient, in: context) else {
                assertionFailure("no conversation found to update protocol change")
                return
            }

            do {
                var updateAction = UpdateConversationProtocolAction(
                    qualifiedID: qualifiedID,
                    messageProtocol: messageProtocol
                )
                try await updateAction.perform(in: userSession.notificationContext)

                var syncAction = SyncConversationAction(qualifiedID: qualifiedID)
                try await syncAction.perform(in: userSession.notificationContext)
            } catch {
                assertionFailure("failed with error: \(error)!")
            }
        }
    }

    private func qualifiedIDOfFirstGroupConversation(
        of userClient: UserClient,
        in context: NSManagedObjectContext
    ) async -> QualifiedID? {
        await context.perform {
            userClient.user?.conversations
                .filter { $0.conversationType == .group }
                .sorted { // sort descending by lastModifiedDate
                    guard
                        let lhsDate = $0.lastModifiedDate,
                        let rhsDate = $1.lastModifiedDate
                    else { return false }
                    return lhsDate > rhsDate
                }
                .first?
                .qualifiedID
        }
    }

    // MARK: Delete domains

    private func deleteDomains() {
        guard let syncContext = userSession?.syncContext else {
            logger.error("failed to delete domains: no sync context")
            return
        }

        syncContext.perform { [logger] in
            do {
                logger.debug("deleted domains of users...")
                let users = try syncContext.fetch(NSFetchRequest<ZMUser>(entityName: ZMUser.entityName()))

                for user in users where !user.isSelfUser {
                    user.domain = nil
                }

                logger.debug("deleted domains of conversations...")
                let conversations = try syncContext
                    .fetch(NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName()))

                for conversation in conversations where conversation.conversationType.isOne(of: .oneOnOne, .group) {
                    conversation.domain = nil
                }

                try syncContext.save()
                logger.debug("successfully deleted domains")

            } catch {
                logger.error("failed to delete domains: \(error.localizedDescription)")
            }
        }
    }

}
