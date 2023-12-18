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
import WireCoreCrypto
import WireDataModel

// sourcery: AutoMockable
public protocol E2eIKeyPackageRotating {

    func rotateKeysAndMigrateConversations(
        e2eIService: E2eIServiceInterface,
        certificateChain: String
    ) async throws

}

public class E2eIKeyPackageRotator: E2eIKeyPackageRotating {

    // MARK: - Types

    enum Error: Swift.Error {
        case noSelfClient
        case invalidGroupID
        case invalidIdentity
    }

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let conversationEventProcessor: ConversationEventProcessorProtocol
    private let context: NSManagedObjectContext
    private let commitSender: CommitSending

    private var coreCrypto: SafeCoreCryptoProtocol {
        get throws {
            try coreCryptoProvider.coreCrypto(requireMLS: true)
        }
    }

    // MARK: - Life cycle

    public init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        conversationEventProcessor: ConversationEventProcessorProtocol,
        context: NSManagedObjectContext,
        commitSender: CommitSending? = nil
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.conversationEventProcessor = conversationEventProcessor
        self.context = context
        self.commitSender = commitSender ?? CommitSender(
            coreCryptoProvider: coreCryptoProvider,
            notificationContext: context.notificationContext
        )
    }

    // MARK: - Interface

    public func rotateKeysAndMigrateConversations(
        e2eIService: E2eIServiceInterface,
        certificateChain: String
    ) async throws {

        // We need to cast this to `WireE2eIdentity` because we only have access
        // to the protocol it conforms to (WireE2eiIdentityProtocol)
        guard let identity = e2eIService.e2eIdentity as? WireE2eIdentity else {
            throw Error.invalidIdentity
        }

        // Get the rotate bundle from core crypto
        let rotateBundle = try await coreCrypto.perform {
            try await $0.e2eiRotateAll(
                enrollment: identity,
                certificateChain: certificateChain,
                newKeyPackageCount: 100
            )
        }

        // Replace the key packages with the ones including the certificate
        try await replaceKeyPackages(rotateBundle: rotateBundle)

        // Send migration commits after key packages rotations
        for (groupID, commit) in rotateBundle.commits {
            do {
                try await migrateConversation(with: groupID, commit: commit)
            } catch {
                WireLogger.e2ei.warn("failed to rotate keys for group: \(String(describing: error))")
            }
        }

    }

    private func replaceKeyPackages(rotateBundle: RotateBundle) async throws {

        guard let clientID = await context.perform({ [self] in
            ZMUser.selfUser(in: context).selfClient()?.remoteIdentifier
        }) else {
            throw Error.noSelfClient
        }

        let newKeyPackages = rotateBundle.newKeyPackages.map { $0.data.base64String() }
        var action = ReplaceSelfMLSKeyPackagesAction(
            clientID: clientID,
            keyPackages: newKeyPackages
        )
        try await action.perform(in: context.notificationContext)
    }

    private func migrateConversation(with groupID: String, commit: CommitBundle) async throws {
        guard let groupID = MLSGroupID(base64Encoded: groupID) else {
            throw Error.invalidGroupID
        }

        let events = try await commitSender.sendCommitBundle(
            commit,
            for: groupID
        )

        await conversationEventProcessor.processConversationEvents(events)
    }

}

// TODO: Remove after core crypto update
// https://wearezeta.atlassian.net/browse/WPB-3384

public struct RotateBundle {
    /// An Update commit for each conversation
    public var commits: [String: CommitBundle]
    /// Fresh KeyPackages with the new Credential
    public var newKeyPackages: [[UInt8]]
    /// All the now deprecated KeyPackages. Once deleted remotely, delete them locally with ``CoreCrypto/deleteKeypackages``
    public var keyPackageRefsToRemove: [[UInt8]]

    public init(commits: [String: CommitBundle], newKeyPackages: [[UInt8]], keyPackageRefsToRemove: [[UInt8]]) {
        self.commits = commits
        self.newKeyPackages = newKeyPackages
        self.keyPackageRefsToRemove = keyPackageRefsToRemove
    }
}

extension CoreCryptoProtocol {
    public func e2eiRotateAll(enrollment: WireE2eIdentity, certificateChain: String, newKeyPackageCount: UInt32) async throws -> RotateBundle {
        return .init(commits: [:], newKeyPackages: [], keyPackageRefsToRemove: [])
    }
}
