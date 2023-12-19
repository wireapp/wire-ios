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
import XCTest
import WireCoreCrypto
@testable import WireDataModel
@testable import WireDataModelSupport

class CommitSenderTests: ZMBaseManagedObjectTest {

    // MARK: - Properties

    private var sut: CommitSender!
    private var mockActionsProvider: MockMLSActionsProviderProtocol!
    private var mockCoreCrypto: MockCoreCryptoProtocol!
    private var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    private var mockClearPendingCommitInvocations: [[Byte]]!
    private var mockClearPendingGroupInvocations: [[Byte]]!

    private lazy var groupID: MLSGroupID = .random()
    private lazy var commitBundle = CommitBundle(
        welcome: nil,
        commit: .random(),
        groupInfo: .init(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
    )

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()

        mockCoreCrypto = MockCoreCryptoProtocol()
        mockActionsProvider = MockMLSActionsProviderProtocol()
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCryptoRequireMLS_MockValue = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)

        sut = CommitSender(
            coreCryptoProvider: mockCoreCryptoProvider,
            notificationContext: syncMOC.notificationContext,
            actionsProvider: mockActionsProvider
        )

        mockClearPendingCommitInvocations = []
        mockCoreCrypto.mockClearPendingCommit = { [self] groupID in
            mockClearPendingCommitInvocations.append(groupID)
        }

        mockClearPendingGroupInvocations = []
        mockCoreCrypto.mockClearPendingGroupFromExternalCommit = { [self] groupID in
            mockClearPendingGroupInvocations.append(groupID)
        }
    }

    override func tearDown() {
        mockCoreCrypto = nil
        mockCoreCryptoProvider = nil
        mockActionsProvider = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Send Commit

    func test_SendCommitBundle_Success() async throws {
        // Given
        let event = ZMUpdateEvent()

        // Mock action provider
        mockActionsProvider.sendCommitBundleIn_MockMethod = { _, _ in
            return [event]
        }

        // Mock core crypto
        var commitAcceptedInvocations = [[Byte]]()
        mockCoreCrypto.mockCommitAccepted = { groupID in
            commitAcceptedInvocations.append(groupID)
        }

        // When
        let receivedEvents = try await sut.sendCommitBundle(commitBundle, for: groupID)

        // Then
        // Send commit bundle was called on the action provider
        XCTAssertEqual(mockActionsProvider.sendCommitBundleIn_Invocations.count, 1)
        XCTAssertEqual(mockActionsProvider.sendCommitBundleIn_Invocations.first?.bundle, commitBundle.transportData())

        // Commit accepted was called
        XCTAssertEqual(commitAcceptedInvocations.count, 1)
        XCTAssertEqual(commitAcceptedInvocations.first, groupID.bytes)

        // Events were received
        XCTAssertEqual(receivedEvents, [event])
    }

    func test_SendCommitBundle_ThrowsWithRecoveryStrategy_RetryAfterQuickSync() async {
        await assertSendCommitBundleThrows(
            withRecovery: .retryAfterQuickSync,
            for: .mlsClientMismatch,
            shouldClearPendingCommit: true
        )
    }

    func test_SendCommitBundle_ThrowsWithRecoveryStrategy_CommitPendingProposalsAfterQuickSync() async {
        await assertSendCommitBundleThrows(
            withRecovery: .commitPendingProposalsAfterQuickSync,
            for: .mlsCommitMissingReferences,
            shouldClearPendingCommit: false
        )
    }

    func test_SendCommitBundle_ThrowsWithRecoveryStrategy_RetryAfterRepairingGroup() async {
        await assertSendCommitBundleThrows(
            withRecovery: .retryAfterRepairingGroup,
            for: .mlsStaleMessage,
            shouldClearPendingCommit: true
        )
    }

    func test_SendCommitBundle_ThrowsWithRecoveryStrategy_GiveUp() async {
        await assertSendCommitBundleThrows(
            withRecovery: .giveUp,
            for: .unknown(status: 400, label: "", message: ""),
            shouldClearPendingCommit: true
        )
    }

    private func assertSendCommitBundleThrows(
        withRecovery recovery: CommitError.RecoveryStrategy,
        for error: SendCommitBundleAction.Failure,
        shouldClearPendingCommit: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        // Given
        // Mock action provider throwing an error
        mockActionsProvider.sendCommitBundleIn_MockMethod = { _, _ in
            throw error
        }

        // Then
        await assertItThrows(error: CommitError.failedToSendCommit(recovery: recovery)) {
            // When
            _ = try await sut.sendCommitBundle(commitBundle, for: groupID)
        }

        if shouldClearPendingCommit {
            // It clears pending commit
            XCTAssertEqual(mockClearPendingCommitInvocations.count, 1)
            XCTAssertEqual(mockClearPendingCommitInvocations.first, groupID.bytes)
        } else {
            // It doesn't clear pending commit
            XCTAssertEqual(mockClearPendingCommitInvocations.count, 0)
        }
    }

    // MARK: - Send External Commit

    func test_SendExternalCommitBundle_Success() async throws {
        // Given
        let event = ZMUpdateEvent()

        // Mock action provider
        mockActionsProvider.sendCommitBundleIn_MockMethod = { _, _ in
            return [event]
        }

        // Mock core crypto
        var mergePendingGroupInvocations = [[Byte]]()
        mockCoreCrypto.mockMergePendingGroupFromExternalCommit = { groupID in
            mergePendingGroupInvocations.append(groupID)
        }

        // When
        let receivedEvents = try await sut.sendExternalCommitBundle(commitBundle, for: groupID)

        // Then
        // Send commit bundle was called on the action provider
        XCTAssertEqual(mockActionsProvider.sendCommitBundleIn_Invocations.count, 1)
        XCTAssertEqual(mockActionsProvider.sendCommitBundleIn_Invocations.first?.bundle, commitBundle.transportData())

        // Commit accepted was called
        XCTAssertEqual(mergePendingGroupInvocations.count, 1)
        XCTAssertEqual(mergePendingGroupInvocations.first, groupID.bytes)

        // Events were received
        XCTAssertEqual(receivedEvents, [event])
    }

    func test_SendExternalCommitBundle_ThrowsWithRecoveryStrategy_Retry() async {
        await assertSendExternalCommitBundleThrows(
            withRecovery: .retry,
            for: .mlsStaleMessage,
            shouldClearPendingGroup: false
        )
    }

    func test_SendExternalCommitBundle_ThrowsWithRecoveryStrategy_GiveUp() async {
        await assertSendExternalCommitBundleThrows(
            withRecovery: .giveUp,
            for: .unknown(status: 400, label: "", message: ""),
            shouldClearPendingGroup: true
        )
    }

    private func assertSendExternalCommitBundleThrows(
        withRecovery recovery: ExternalCommitError.RecoveryStrategy,
        for error: SendCommitBundleAction.Failure,
        shouldClearPendingGroup: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        // Given
        // Mock action provider throwing an error
        mockActionsProvider.sendCommitBundleIn_MockMethod = { _, _ in
            throw error
        }

        // Then
        await assertItThrows(error: ExternalCommitError.failedToSendCommit(recovery: recovery)) {
            // When
            _ = try await sut.sendExternalCommitBundle(commitBundle, for: groupID)
        }

        if shouldClearPendingGroup {
            // It clears pending commit
            XCTAssertEqual(mockClearPendingGroupInvocations.count, 1, file: file, line: line)
            XCTAssertEqual(mockClearPendingGroupInvocations.first, groupID.bytes, file: file, line: line)
        } else {
            // It doesn't clear pending commit
            XCTAssertEqual(mockClearPendingGroupInvocations.count, 0, file: file, line: line)
        }
    }

    // MARK: - Epoch change

    func test_OnEpochChanged() async throws {
        // Given

        // Mock action provider
        mockActionsProvider.sendCommitBundleIn_MockMethod = { _, _ in
            return []
        }

        // Mock commit accepted
        mockCoreCrypto.mockCommitAccepted = { _ in }

        // Set up expectation
        let expectation = XCTestExpectation(description: "observed epoch change")
        var receivedGroupIDs = [MLSGroupID]()
        let token = sut.onEpochChanged().collect(1).sink {
            receivedGroupIDs = $0
            expectation.fulfill()
        }

        // When
        _ = try await sut.sendCommitBundle(commitBundle, for: groupID)

        // Then
        await fulfillment(of: [expectation])
        XCTAssertEqual(receivedGroupIDs, [groupID])
    }
}
