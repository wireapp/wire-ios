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
import WireAPI
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
            .init(title: "Update Conversation to MLS protocol", action: updateConversationProtocolToMLS),
            .init(title: "Update MLS migration status", action: updateMLSMigrationStatus)
        ]

        if #available(iOS 16.0, *) {
            buttons.append(.init(title: "Sync contacts using in batch", action: fetchContactsInBatch))
            buttons.append(.init(title: "Sync contacts using in parallel", action: fetchContactsInParallel))
        }
    }

    // MARK: Fetch users

    @available(iOS 16.0, *)
    private func fetchContactsInParallel() {
        fetchContactsInParallel(count: 30)
    }

    @available(iOS 16.0, *)
    private func fetchContactsInParallel(count: Int) {
        let usersAPI = ZMUserSession.shared()!.makeUsersAPI()
        let context = ZMUserSession.shared()!.viewContext

        let fetchRequest = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
        let users = try! context.fetch(fetchRequest)
        let userIDs = users.compactMap { $0.qualifiedID }.prefix(upTo: count)

        Task {
            let clock = ContinuousClock()
            let duration = await clock.measure {
                await withThrowingTaskGroup(of: User.self) { group in
                    for userID in userIDs {
                        group.addTask {
                            try await usersAPI.getUser(for: WireAPI.UserID(
                                uuid: userID.uuid,
                                domain: userID.domain
                            ))
                        }
                    }
                    do {
                        let names: [String] = try await group.reduce(into: [], { $0.append($1.name) })
                        WireLogger.sync.info("synced: \(names)")
                    } catch {
                        WireLogger.sync.error("failed: \(error)")
                    }
                }
            }
            let message = "It took \(duration) to fetch \(userIDs.count) contacts in a parallel"
            WireLogger.sync.info(message)

            await MainActor.run {
                DebugAlert.showGeneric(message: message)
            }
        }
    }

    @available(iOS 16.0, *)
    private func fetchContactsInBatch() {
        fetchContactsInBatch(count: 30)
    }

    @available(iOS 16.0, *)
    private func fetchContactsInBatch(count: Int) {
        let usersAPI = ZMUserSession.shared()!.makeUsersAPI()
        let context = ZMUserSession.shared()!.viewContext

        let fetchRequest = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
        let users = try! context.fetch(fetchRequest)
        let userIDs = users.compactMap { $0.qualifiedID }.prefix(upTo: count)

        Task {
            let clock = ContinuousClock()
            let duration = await clock.measure {
                do {
                    let result = try await usersAPI.getUsers(userIDs: userIDs.map {
                        WireAPI.UserID(uuid: $0.uuid, domain: $0.domain)
                    })
                    WireLogger.sync.info("synced: \(result.found.map(\.name))")
                } catch {
                    WireLogger.sync.error("failed: \(error)")
                }
            }
            let message = "It took \(duration) to fetch \(userIDs.count) contacts in a batch"
            WireLogger.sync.info(message)

            await MainActor.run {
                DebugAlert.showGeneric(message: message)
            }
        }
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
        guard let userSession else { return }

        Task {
            await userSession.syncStatus.performQuickSync()
        }
    }

    // MARK: Proteus to MLS migration

    private func updateMLSMigrationStatus() {
        guard let userSession else { return }

        Task {
            try await userSession.updateMLSMigrationStatus()
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

    private func qualifiedIDOfFirstGroupConversation(of userClient: UserClient, in context: NSManagedObjectContext) async -> WireDataModel.QualifiedID? {
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
