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
import WireSyncEngine

final class DeveloperDebugActionsViewModel: ObservableObject {

    @Published var buttons: [DeveloperDebugActionsDisplayModel.ButtonItem] = []

    private var userSession: ZMUserSession? { ZMUserSession.shared() }

    private let selfClient: UserClient?

    // MARK: - Initialize

    init(selfClient: UserClient?) {
        self.selfClient = selfClient

        setupButtons()
    }

    private func setupButtons() {
        buttons = [
            .init(title: "Send debug logs", action: sendDebugLogs),
            .init(title: "Perform quick sync", action: performQuickSync),
            .init(title: "Break next quick sync", action: breakNextQuickSync),
            .init(title: "Update Conversation to mixed protocol", action: updateConversationProtocolToMixed),
            .init(title: "Update Conversation to MLS protocol", action: updateConversationProtocolToMLS)
        ]
    }

    // MARK: Send Logs

    private func sendDebugLogs() {
        DebugLogSender.sendLogsByEmail(message: "Send logs")
    }

    // MARK: Quick Sync

    private func breakNextQuickSync() {
        userSession?.setBogusLastEventID()
    }

    private func performQuickSync() {
        guard let userSession = userSession else { return }

        Task {
            await userSession.syncStatus.performQuickSync()
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
            let selfClient = selfClient,
            let context = selfClient.managedObjectContext
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
                try await updateAction.perform(in: context.notificationContext)

                var syncAction = SyncConversationAction(qualifiedID: qualifiedID)
                try await syncAction.perform(in: context.notificationContext)
            } catch {
                assertionFailure("failed with error: \(error)!")
            }
        }
    }

    private func qualifiedIDOfFirstGroupConversation(of userClient: UserClient, in context: NSManagedObjectContext) async -> QualifiedID? {
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
}
