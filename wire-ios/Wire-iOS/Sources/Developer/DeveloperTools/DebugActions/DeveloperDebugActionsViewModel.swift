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
import WireDomain
import WireFoundation
import WireLogging
import WireNetwork
import WireSyncEngine

struct ConversationResult {
    var id: String
    var groupID: MLSGroupID?
    var name: String

    var description: String {
        id
    }
}

enum MLSGroupSearchItem: Identifiable {
    var id: String {
        switch self {
        case .result:
            "result"
        }
    }

    case result([ConversationResult], String)
}

final class DeveloperDebugActionsViewModel: ObservableObject {

    @Published var debugItems: [DeveloperDebugActionsDisplayModel.DebugItem] = []
    @Published var mlsGroupSearchItem: MLSGroupSearchItem?
    @Published var isAppVersionInputPresented = false

    private let userSession: ZMUserSession?
    private let selfClient: UserClient?
    private let onDismiss: (() -> Void)?
    private let shareDebugPresenter = ShareDebugReportPresenter()

    private let logger = WireLogger(tag: "developer")

    // MARK: - Initialize

    init(
        userSession: UserSession?,
        selfClient: UserClient?,
        onDismiss: (() -> Void)? = nil
    ) {
        self.userSession = userSession as? ZMUserSession
        self.selfClient = selfClient
        self.onDismiss = onDismiss

        setupButtons()
    }

    private func setupButtons() {
        func button(
            _ title: String,
            action: @escaping (DeveloperDebugActionsViewModel) -> Void
        ) -> DeveloperDebugActionsDisplayModel.ButtonItem {
            .init(title: title, action: { [weak self] in
                guard let self else { return }
                action(self)
            })
        }

        let buttonItems: [DeveloperDebugActionsDisplayModel.ButtonItem] = [
            button("Share debug logs") { viewModel in
                Task { @MainActor in viewModel.shareDebugLogs() }
            },
            button("Trigger incremental sync") { $0.triggerIncrementalSync() },
            button("Trigger resources sync") { $0.triggerResourcesSync() },
            button("Break next incremental sync") { $0.breakNextIncrementalSync() },
            button("Update Conversation to mixed protocol") { $0.updateConversationProtocolToMixed() },
            button("Update Conversation to MLS protocol") { $0.updateConversationProtocolToMLS() },
            button("Update MLS migration status") { $0.updateMLSMigrationStatus() },
            button("Delete domains in the database") { $0.deleteDomains() },
            button("Find Conversation with MLS Group") { $0.showSearchMLSConversations() },
            button("Clear collapsed messages cache") { $0.clearCollapsedMessagesCache() },
            button("Simulate access token failure") { $0.simulateAccessTokenFailure() },
            button("Invalidate all conversations") { $0.invalidateAllConversations() },
            button("Set last app version migration") { $0.requestAppVersionInput() },
            button("Initiate reset of first from top MLS") { $0.initiateResetBrokenMLSConversation() },
            button("Initiate reset of affected MLS groups") { $0.initiateRepairRemovalKeys() },
            button("Trigger 15s CC transaction") { $0.simulateLongCCTransaction(seconds: 15) },
            button("Trigger 60s CC transaction") { $0.simulateLongCCTransaction(seconds: 60) },
            button("Logout") { $0.logout() }
        ]

        let toggleItems: [DeveloperDebugActionsDisplayModel.ToggleItem] = [
            .init(title: "Use CallKit", isOn: Binding(
                get: { [weak self] in self?.isCallKitEnabled() ?? false },
                set: { [weak self] in self?.enableCallKit($0) }
            ), enabled: !UIDevice.isSimulator)
        ]

        debugItems = buttonItems.map { .button($0) } + toggleItems.map { .toggle($0) }
    }

    // MARK: - App version migration

    private func invalidateAllConversations() {
        guard let context = userSession?.syncContext else {
            return
        }

        context.perform {
            let request = ZMConversation.fetchRequest()
            let converstions = try! context.fetch(request) as! [ZMConversation]
            for conversation in converstions {
                conversation.conversationType = .invalid
            }
            try! context.save()
        }
    }

    private func requestAppVersionInput() {
        isAppVersionInputPresented = true
    }

    func setLastCompletedAppVersionMigration(version: String) {
        isAppVersionInputPresented = false

        guard let selfUser = userSession?.selfUser else {
            return
        }

        var journal = Journal(
            userID: selfUser.remoteIdentifier,
            storage: UserDefaults.shared()
        )

        journal.lastCompletedAppVersionMigration = SemanticVersion(stringLiteral: version)
    }

    // MARK: - CallKit

    private func isCallKitEnabled() -> Bool {
        SessionManager.shared?.callNotificationStyle == .callKit
    }

    private func enableCallKit(_ enabled: Bool) {
        SessionManager.shared?.callNotificationStyle = enabled ? .callKit : .pushNotifications
        onDismiss?()
    }

    // MARK: - Forces logout

    private func initiateResetBrokenMLSConversation() {
        guard
            let selfClient,
            let context = selfClient.managedObjectContext,
            let userSession
        else { return }

        Task { @MainActor in
            guard let conversation = await firstConversation(
                of: selfClient,
                in: context,
                isMLS: true,
                onlyGroups: false
            ),
                let mlsGroupID = conversation.mlsGroupID else {
                WireLogger.mls.info("No MLS conversation to trigger initiate reset")

                return
            }

            WireLogger.mls
                .info(
                    "Triggering initiate reset for conversation: \(conversation.name ?? "-"), mlsGroupID: \(mlsGroupID), conversationID: \(String(describing: conversation.remoteIdentifier))"
                )

            let qualifiedID = WireNetwork.QualifiedID(
                id: conversation.qualifiedID!.uuid,
                domain: conversation.qualifiedID!.domain
            )

            guard let remoteConversation = try? await userSession.clientSessionComponent?.conversationsAPI
                .getConversations(
                    for: [qualifiedID]
                ).found.first else {
                return
            }

            await userSession.clientSessionComponent?.initiateResetMLSConversationUseCase.invoke(
                groupID: MLSGroupID(base64Encoded: remoteConversation.mlsGroupID!)!,
                epoch: UInt64(remoteConversation.epoch ?? 0)
            )
        }

    }

    private func initiateRepairRemovalKeys() {
        guard let useCase = userSession?.clientSessionComponent?.repairFaultyRemovalKeysUsecase else {
            WireLogger.mls.warn(
                "unable to manually trigger to initiate repair removal keys because the usecase is not available",
                attributes: .safePublic
            )
            return
        }

        Task { @MainActor in
            WireLogger.mls.info(
                "manual trigger to initiate repair removal keys",
                attributes: .safePublic
            )
            do {
                let result = try await useCase.invoke()
                WireLogger.mls.info(
                    "manual trigger to initiate repair removal keys compete. Repaired initiated for \(result.conversationsRepaired)/\(result.faultyConversationsFound) affected conversations.",
                    attributes: .safePublic
                )
            } catch {
                WireLogger.mls.error(
                    "manual trigger to repair removal keys failed: \(String(describing: error))",
                    attributes: .safePublic
                )
            }
        }
    }

    func logout() {
        guard let userSession else { return }
        LogOutHelper(showLoading: {}, hideLoading: {}).logout(userSession: userSession)
    }

    private func simulateAccessTokenFailure() {
        guard let selfUserID = userSession?.managedObjectContext.performAndWait({
            userSession?.selfUser.remoteIdentifier
        }) else { return }

        let cookieStorage = CookieStorage(
            cookieEncryptionKey: UserDefaults.cookiesKey()
        )

        // Forces the access token request to fail with 403 (invalid credentials)

        let networkService = MockNetworkService()

        let httpURLResponse = HTTPURLResponse(
            url: URL(filePath: "https://someurl.com")!,
            statusCode: 403,
            httpVersion: nil,
            headerFields: [:]
        )!

        let payload = """
         {
            "code": 403,
            "label": "invalid-credentials",
            "message": ""
          }
        """

        let data = Data(payload.utf8)

        networkService.executeRequest_MockValue = (data, httpURLResponse)

        let authenticationManager = AuthenticationManager(
            userID: selfUserID,
            clientID: UUID().uuidString,
            cookieStorage: cookieStorage,
            networkService: networkService
        ) { [weak self] in
            // will log out the user when access token request fails
            self?.userSession?.onAuthenticationFailure()
        }

        Task {
            do {
                _ = try await authenticationManager.getValidAccessToken()
            } catch {}
        }

        onDismiss?()
    }

    private func clearCollapsedMessagesCache() {
        let defaults = PrivateUserDefaults<CollapseKey>(
            userID: selfClient!.user!.remoteIdentifier
        )
        defaults.removeObject(forKey: .uncollapsedMessages)
        onDismiss?()
    }

    // MARK: Share Logs

    @MainActor
    private func shareDebugLogs() {
        shareDebugPresenter.present(from: UIApplication.shared.topmostViewController(onlyFullScreen: false))
    }

    // MARK: Quick Sync

    private func breakNextIncrementalSync() {
        userSession?.setBogusLastEventID()
    }

    private func triggerIncrementalSync() {
        userSession?.triggerIncrementalSync()
    }

    // MARK: Resync resources

    private func triggerResourcesSync() {
        Task {
            await userSession?.triggerResourcesSync()
        }
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

    private func updateConversationProtocol(to messageProtocol: WireDataModel.MessageProtocol) {
        guard
            let selfClient,
            let context = selfClient.managedObjectContext,
            let userSession
        else { return }

        Task { @MainActor in
            guard let qualifiedID = await firstConversation(of: selfClient, in: context, onlyGroups: true)?.qualifiedID
            else {
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

    private func firstConversation(
        of userClient: UserClient,
        in context: NSManagedObjectContext,
        isMLS: Bool? = nil,
        onlyGroups: Bool
    ) async -> ZMConversation? {
        await context.perform {
            userClient.user?.conversations
                .filter {
                    onlyGroups ? $0.conversationType == .group : true
                }
                .filter { !$0.isSelfConversation }
                .filter {
                    !$0.isDeleted && !$0.isArchived && !$0.isDeletedRemotely
                }
                .filter {
                    if let isMLS {
                        return isMLS ? $0.messageProtocol == .mls : $0.messageProtocol != .mls
                    }
                    return true
                }
                .sorted { // sort descending by lastModifiedDate
                    guard
                        let lhsDate = $0.lastModifiedDate,
                        let rhsDate = $1.lastModifiedDate
                    else { return false }
                    return lhsDate > rhsDate
                }
                .first
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

    // MARK: Find conversation

    private func showSearchMLSConversations() {
        mlsGroupSearchItem = .result([], "")
    }

    @MainActor
    func findConversations(with mlsGroupID: String?) async {
        guard let strippedMLSGroupID = mlsGroupID?.replacingOccurrences(of: "*", with: "") else {
            showConversationInfo(results: [], term: "")
            return
        }

        guard let syncContext = userSession?.syncContext else {
            showConversationInfo(results: [], term: strippedMLSGroupID)
            return
        }

        let results = try? await syncContext.perform {
            let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
            fetchRequest.fetchBatchSize = 50
            // as we have a string and MLSGroupID is data we can't fetch with a predicate
            let conversations = try syncContext.fetch(fetchRequest)

            var matchedConversationInfos = [ConversationResult]()
            for conversation in conversations
                where conversation.mlsGroupID?.description.starts(with: strippedMLSGroupID) == true {
                matchedConversationInfos.append(
                    ConversationResult(
                        id: conversation.remoteIdentifier.uuidString,
                        groupID: conversation.mlsGroupID,
                        name: conversation.name ?? "-"
                    )
                )
            }
            return matchedConversationInfos
        }
        showConversationInfo(results: results ?? [], term: strippedMLSGroupID)
    }

    @MainActor
    private func showConversationInfo(results: [ConversationResult], term: String) {
        mlsGroupSearchItem = .result(results, term)
    }

    // MARK: - Simulate long CC transaction

    // Use this to trigger a long CC transaction and seeing how the app
    // and extensions behave when the app moves to the background.
    private func simulateLongCCTransaction(seconds: Int) {
        guard let userSession else {
            return
        }

        Task {
            try? await userSession._simulateLongCCTransaction(seconds: seconds)
        }
    }

}

/// Mock network to simulate an access token request failure with invalid credential errors and trigger a logout
private class MockNetworkService: NetworkServiceProtocol {
    public init() {}
    public var executeRequest_MockValue: (Data, HTTPURLResponse)?

    public func executeRequest(
        _ request: URLRequest
    ) async throws -> (Data, HTTPURLResponse) {
        if let mock = executeRequest_MockValue {
            mock
        } else {
            fatalError("no mock for `executeRequest`")
        }
    }
}
