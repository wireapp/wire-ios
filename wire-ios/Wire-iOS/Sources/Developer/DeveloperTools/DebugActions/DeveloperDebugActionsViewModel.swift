//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireAPI
import WireDataModel
import WireFoundation
import WireLogging
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

    private var userSession: ZMUserSession? { ZMUserSession.shared() }

    private let selfClient: UserClient?
    private let onDismiss: (() -> Void)?

    private let logger = WireLogger(tag: "developer")

    // MARK: - Initialize

    init(
        selfClient: UserClient?,
        onDismiss: (() -> Void)? = nil
    ) {
        self.selfClient = selfClient
        self.onDismiss = onDismiss

        setupButtons()
    }

    private func setupButtons() {
        let buttonItems: [DeveloperDebugActionsDisplayModel.ButtonItem] = [
            .init(title: "Send debug logs", action: sendDebugLogs),
            .init(title: "Trigger incremental sync", action: triggerIncrementalSync),
            .init(title: "Trigger resources sync", action: triggerResourcesSync),
            .init(title: "Break next incremental sync", action: breakNextIncrementalSync),
            .init(title: "Update Conversation to mixed protocol", action: updateConversationProtocolToMixed),
            .init(title: "Update Conversation to MLS protocol", action: updateConversationProtocolToMLS),
            .init(title: "Update MLS migration status", action: updateMLSMigrationStatus),
            .init(title: "Delete domains in the database", action: deleteDomains),
            .init(title: "Find Conversation with MLS Group", action: showSearchMLSConversations),
            .init(title: "Simulate access token failure", action: simulateAccessTokenFailure)
        ]

        let toggleItems: [DeveloperDebugActionsDisplayModel.ToggleItem] = [
            .init(title: "Use CallKit", isOn: Binding(
                get: { self.isCallKitEnabled() },
                set: { self.enableCallKit($0) }
            ), enabled: !UIDevice.isSimulator)
        ]

        debugItems = buttonItems.map { .button($0) } + toggleItems.map { .toggle($0) }
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

    private func simulateAccessTokenFailure() {
        guard let selfUserID = userSession?.managedObjectContext.performAndWait({
            userSession?.selfUser.remoteIdentifier
        }) else { return }

        let cookieStorage = CookieStorage(
            userID: selfUserID,
            cookieEncryptionKey: UserDefaults.cookiesKey(),
            keychain: WireFoundation.Keychain()
        )

        // Forces the access token request to fail with 403 (invalid credentials)

        let networkService = MockNetworkService()

        let httpURLResponse = HTTPURLResponse(
            url: URL(filePath: "https://someurl.com")!,
            statusCode: 403,
            httpVersion: nil,
            headerFields: [:]
        )!

        let jsonData = """
         {
            "code": 403,
            "label": "invalid-credentials",
            "message": ""
          }
        """.data(using: .utf8)!

        networkService.executeRequest_MockValue = (jsonData, httpURLResponse)

        let authenticationManager = AuthenticationManager(
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

    private func breakNextIncrementalSync() {
        userSession?.setBogusLastEventID()
    }

    private func triggerIncrementalSync() {
        userSession?.triggerIncrementalSync()
    }

    // MARK: Resync resources

    private func triggerResourcesSync() {
        userSession?.triggerResourcesSync()
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
    ) async -> WireDataModel.QualifiedID? {
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

}

/// Debug helper to simulate an access token request failure with invalid credential errors and trigger a logout
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
