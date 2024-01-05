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
import Combine
import WireCoreCrypto

// sourcery: AutoMockable
public protocol CommitSending {

    func sendCommitBundle(
        _ bundle: CommitBundle,
        for groupID: MLSGroupID
    ) async throws -> [ZMUpdateEvent]

    func sendExternalCommitBundle(
        _ bundle: CommitBundle,
        for groupID: MLSGroupID
    ) async throws -> [ZMUpdateEvent]

    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never>

}

public actor CommitSender: CommitSending {

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let notificationContext: NotificationContext
    private let actionsProvider: MLSActionsProviderProtocol
    private let onEpochChangedSubject = PassthroughSubject<MLSGroupID, Never>()

    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto(requireMLS: true)
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

            throw CommitError.failedToSendCommit(recovery: recoveryStrategy)
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

            throw ExternalCommitError.failedToSendCommit(recovery: recoveryStrategy)
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
            try await coreCrypto.perform {
                try $0.commitAccepted(conversationId: groupID.bytes)
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
                try $0.clearPendingCommit(conversationId: groupID.bytes)
            }
        } catch {
            WireLogger.mls.error("failed to discard pending commit for group (\(groupID.safeForLoggingDescription))")
            throw CommitError.failedToClearCommit
        }
    }

    private func mergePendingGroup(in groupID: MLSGroupID) async throws {
        do {
            WireLogger.mls.info("merging pending group (\(groupID.safeForLoggingDescription))")
            try await coreCrypto.perform {
                try $0.mergePendingGroupFromExternalCommit(
                    conversationId: groupID.bytes
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
                try $0.clearPendingGroupFromExternalCommit(conversationId: groupID.bytes)
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
            self = .commitPendingProposalsAfterQuickSync
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
        data.append(Data(commit))
        data.append(Data(welcome ?? []))
        data.append(Data(groupInfo.payload))
        return data
    }

}
