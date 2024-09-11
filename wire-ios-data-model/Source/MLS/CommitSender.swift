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

import Combine
import Foundation
import WireCoreCrypto

// sourcery: AutoMockable
public protocol CommitSending {

    /// Sends a commit bundle.
    ///
    /// - Parameters:
    ///   - bundle: The commit bundle to send.
    ///   - groupID: The group ID of the group to send the commit to.
    /// - Returns: Any update events returned by the backend.
    /// - Throws: `CommitError` if the operation fails.
    ///
    /// If the commit is sent successfully, it will be merged and the new epoch will be published.
    /// New epochs can be observed with ``onEpochChanged()``.
    ///
    /// If the commit fails to send, the error will contain a recovery strategy to handle the failure.
    /// The pending commit may be discarded based on the recovery strategy.

    func sendCommitBundle(
        _ bundle: CommitBundle,
        for groupID: MLSGroupID
    ) async throws -> [ZMUpdateEvent]

    /// Sends an external commit bundle.
    ///
    /// -  Parameters:
    ///   - bundle: The commit bundle to send.
    ///   - groupID: The group ID of the group to send the commit to.
    /// - Returns: Any update events returned by the backend.
    /// - Throws: `ExternalCommitError` if the operation fails.
    ///
    /// If the commit is sent successfully, the pending group will be merged.
    /// 
    /// If the commit fails to send, the error will contain a recovery strategy to handle the failure.
    /// If the recovery strategy is to give up, then the pending group will be cleared.

    func sendExternalCommitBundle(
        _ bundle: CommitBundle,
        for groupID: MLSGroupID
    ) async throws -> [ZMUpdateEvent]

    /// Returns a publisher that emits the group ID of the group when the epoch changes.

    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never>

}

/// An actor responsible for sending commits and external commits and handling the results.
/// In case of failures, it will provide a recovery strategy to handle the failure.

public actor CommitSender: CommitSending {

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let notificationContext: NotificationContext
    private let actionsProvider: MLSActionsProviderProtocol
    private let onEpochChangedSubject = PassthroughSubject<MLSGroupID, Never>()

    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto()
        }
    }

    // MARK: - Life cycle

    public init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        notificationContext: NotificationContext
    ) {
        self.init(
            coreCryptoProvider: coreCryptoProvider,
            notificationContext: notificationContext,
            actionsProvider: nil
        )
    }

    init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        notificationContext: NotificationContext,
        actionsProvider: MLSActionsProviderProtocol? = nil
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.notificationContext = notificationContext
        self.actionsProvider = actionsProvider ?? MLSActionsProvider()
    }

    // MARK: - Public interface

    public func sendCommitBundle(
        _ bundle: CommitBundle,
        for groupID: MLSGroupID
    ) async throws -> [ZMUpdateEvent] {

        do {
            WireLogger.mls.info("sending commit bundle for group (\(groupID.safeForLoggingDescription))")
            let events = try await sendCommitBundle(bundle)

            WireLogger.mls.info("merging commit for group (\(groupID.safeForLoggingDescription))")
            try await mergeCommit(in: groupID)

            return events

        } catch let error as SendCommitBundleAction.Failure {
            WireLogger.mls.warn("failed to send commit bundle: \(String(describing: error))")

            let recoveryStrategy = CommitError.RecoveryStrategy(from: error)

            if recoveryStrategy.shouldDiscardCommit {
                try await discardPendingCommit(in: groupID)
            }

            throw CommitError.failedToSendCommit(recovery: recoveryStrategy, cause: error)
        }
    }

    public func sendExternalCommitBundle(
        _ bundle: CommitBundle,
        for groupID: MLSGroupID
    ) async throws -> [ZMUpdateEvent] {

        do {
            WireLogger.mls.info("sending external commit bundle for group (\(groupID.safeForLoggingDescription))")
            let events = try await sendCommitBundle(bundle)

            WireLogger.mls.info("merging pending group for (\(groupID.safeForLoggingDescription))")
            try await mergePendingGroup(in: groupID)

            return events

        } catch let error as SendCommitBundleAction.Failure {
            WireLogger.mls.warn("failed to send external commit bundle: \(String(describing: error))")

            let recoveryStrategy = ExternalCommitError.RecoveryStrategy(from: error)

            if recoveryStrategy.shouldClearPendingGroup {
                try await clearPendingGroup(in: groupID)
            }

            throw ExternalCommitError.failedToSendCommit(recovery: recoveryStrategy, cause: error)
        }
    }

    nonisolated
    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        return onEpochChangedSubject.eraseToAnyPublisher()
    }

    // MARK: - Helpers

    private func sendCommitBundle(_ bundle: CommitBundle) async throws -> [ZMUpdateEvent] {
        return try await actionsProvider.sendCommitBundle(
            bundle.transportData(),
            in: notificationContext
        )
    }

    // MARK: - Post sending

    private func mergeCommit(in groupID: MLSGroupID) async throws {
        do {
            WireLogger.mls.info("merging commit for group (\(groupID.safeForLoggingDescription))")
            // No need to handle buffered messages here. We will not run into a scenario where we need to handle
            // buffered decrypted messages, because sending a commit and decrypting a message are non-rentrant
            // operations and therefore we will never attempt to decrypt a message while sending a commit.
            _ = try await coreCrypto.perform {
                try await $0.commitAccepted(conversationId: groupID.data)
            }
            onEpochChangedSubject.send(groupID)
        } catch {
            WireLogger.mls.error("failed to merge commit for group (\(groupID.safeForLoggingDescription))")
            throw CommitError.failedToMergeCommit
        }
    }

    private func discardPendingCommit(in groupID: MLSGroupID) async throws {
        do {
            WireLogger.mls.info("discarding pending commit for group (\(groupID.safeForLoggingDescription))")
            try await coreCrypto.perform {
                try await $0.clearPendingCommit(conversationId: groupID.data)
            }
        } catch {
            WireLogger.mls.error("failed to discard pending commit for group (\(groupID.safeForLoggingDescription))")
            throw CommitError.failedToClearCommit
        }
    }

    private func mergePendingGroup(in groupID: MLSGroupID) async throws {
        do {
            WireLogger.mls.info("merging pending group (\(groupID.safeForLoggingDescription))")
            // No need to handle buffered messages here. We will not run into a scenario where we need to handle
            // buffered decrypted messages, because sending a commit and decrypting a message are non-rentrant
            // operations and therefore we will never attempt to decrypt a message while sending a commit.
            _ = try await coreCrypto.perform {
                try await $0.mergePendingGroupFromExternalCommit(
                    conversationId: groupID.data
                )
            }
        } catch {
            WireLogger.mls.error("failed to merge pending group (\(groupID.safeForLoggingDescription))")
            throw ExternalCommitError.failedToMergePendingGroup
        }
    }

    private func clearPendingGroup(in groupID: MLSGroupID) async throws {
        do {
            WireLogger.mls.info("clearing pending group (\(groupID.safeForLoggingDescription))")
            try await coreCrypto.perform {
                try await $0.clearPendingGroupFromExternalCommit(conversationId: groupID.data)
            }
        } catch {
            WireLogger.mls.error("failed to clear pending group (\(groupID.safeForLoggingDescription))")
            throw ExternalCommitError.failedToClearPendingGroup
        }
    }
}

private extension CommitError.RecoveryStrategy {

    init(from error: SendCommitBundleAction.Failure) {
        switch error {
        case .mlsClientMismatch:
            self = .retryAfterQuickSync
        case .mlsCommitMissingReferences:
            self = .retryAfterQuickSync
        case .mlsStaleMessage:
            self = .retryAfterRepairingGroup
        default:
            self = .giveUp
        }
    }

}

private extension ExternalCommitError.RecoveryStrategy {

    init(from error: SendCommitBundleAction.Failure) {
        switch error {
        case .mlsStaleMessage:
            self = .retry
        default:
            self = .giveUp
        }

    }
}

extension CommitBundle {

    func transportData() -> Data {
        var data = Data()
        data.append(commit)
        if let welcome {
            data.append(welcome)
        }
        data.append(groupInfo.payload)
        return data
    }

}
