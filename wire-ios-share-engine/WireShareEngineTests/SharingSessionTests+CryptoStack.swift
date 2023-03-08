//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

import XCTest
import Foundation
import WireDataModel
import WireTesting
import WireMockTransport
import CoreCryptoSwift
@testable import WireShareEngine

class SharingSessionTestsCryptoStack: BaseTest {

    private var proteusFlag = DeveloperFlag.proteusViaCoreCrypto
    private var mlsFlag = DeveloperFlag.enableMLSSupport

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()
        proteusFlag.isOn = false
        mlsFlag.isOn = false
    }

    override func tearDown() {
        proteusFlag.isOn = false
        mlsFlag.isOn = false
        super.tearDown()
    }

    // MARK: - Tests

    func test_CryptoStackSetup_OnInit_ProteusOnly() throws {
        // GIVEN
        proteusFlag.isOn = true

        let context = coreDataStack.syncContext

        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)

        // WHEN
        _ = try createSharingSession()

        // THEN
        XCTAssertNil(context.mlsController)
        XCTAssertNotNil(context.proteusService)
        XCTAssertNotNil(context.coreCrypto)
    }

    func test_CryptoStackSetup_OnInit_MLSOnly() throws {
        // GIVEN
        mlsFlag.isOn = true

        let context = coreDataStack.syncContext

        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)

        // WHEN
        _ = try createSharingSession()

        // THEN
        XCTAssertNotNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNotNil(context.coreCrypto)
    }

    func test_CryptoStackSetup_OnInit_ProteusAndMLS() throws {
        // GIVEN
        proteusFlag.isOn = true
        mlsFlag.isOn = true

        let context = coreDataStack.syncContext

        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)

        // WHEN
        _ = try createSharingSession()

        // THEN
        XCTAssertNotNil(context.mlsController)
        XCTAssertNotNil(context.proteusService)
        XCTAssertNotNil(context.coreCrypto)
    }

    func test_CryptoStackSetup_OnInit_AllFlagsDisabled() throws {
        // GIVEN
        XCTAssertFalse(proteusFlag.isOn)
        XCTAssertFalse(mlsFlag.isOn)

        let context = coreDataStack.syncContext

        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)

        // WHEN
        _ = try createSharingSession()

        // THEN
        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)
    }

}

class MockCoreCrypto: CoreCryptoProtocol {

    var calls = Calls()

    struct Calls {
        var commitPendingProposals: [ConversationId] = []
    }

    func mlsInit(clientId: ClientId) throws {

    }

    func mlsGenerateKeypair() throws -> [UInt8] {
        return []
    }

    func mlsInitWithClientId(clientId: ClientId, signaturePublicKey: [UInt8]) throws {

    }

    func restoreFromDisk() throws {

    }

    func setCallbacks(callbacks: CoreCryptoCallbacks) throws {

    }

    func clientPublicKey() throws -> [UInt8] {
        return []
    }

    func clientKeypackages(amountRequested: UInt32) throws -> [[UInt8]] {
        return []
    }

    func clientValidKeypackagesCount() throws -> UInt64 {
        return 0
    }

    func createConversation(conversationId: ConversationId, config: ConversationConfiguration) throws {

    }

    func conversationEpoch(conversationId: ConversationId) throws -> UInt64 {
        return 0
    }

    func conversationExists(conversationId: ConversationId) -> Bool {
        return false
    }

    func processWelcomeMessage(welcomeMessage: [UInt8], customConfiguration: CustomConfiguration) throws -> ConversationId {
        return []
    }

    func addClientsToConversation(conversationId: ConversationId, clients: [Invitee]) throws -> MemberAddedMessages {

        return .init(
            commit: [],
            welcome: [],
            publicGroupState: .init(
                encryptionType: .plaintext,
                ratchetTreeType: .full,
                payload: []
            )
        )
    }

    func removeClientsFromConversation(conversationId: ConversationId, clients: [ClientId]) throws -> CommitBundle {
        return .init(
            welcome: nil,
            commit: [],
            publicGroupState: .init(
                encryptionType: .plaintext,
                ratchetTreeType: .full,
                payload: []
            )
        )
    }

    func updateKeyingMaterial(conversationId: ConversationId) throws -> CommitBundle {
        return .init(
            welcome: nil,
            commit: [],
            publicGroupState: .init(
                encryptionType: .plaintext,
                ratchetTreeType: .full,
                payload: []
            )
        )
    }

    func commitPendingProposals(conversationId: ConversationId) throws -> CommitBundle? {
        calls.commitPendingProposals.append(conversationId)
        return .init(
            welcome: nil,
            commit: [],
            publicGroupState: .init(
                encryptionType: .plaintext,
                ratchetTreeType: .full,
                payload: []
            )
        )
    }

    func wipeConversation(conversationId: ConversationId) throws {

    }

    func decryptMessage(conversationId: ConversationId, payload: [UInt8]) throws -> DecryptedMessage {
        return .init(message: nil, proposals: [], isActive: false, commitDelay: nil, senderClientId: nil, hasEpochChanged: false)
    }

    func encryptMessage(conversationId: ConversationId, message: [UInt8]) throws -> [UInt8] {
        return []
    }

    func newAddProposal(conversationId: ConversationId, keyPackage: [UInt8]) throws -> ProposalBundle {
        return .init(proposal: [], proposalRef: [])
    }

    func newUpdateProposal(conversationId: ConversationId) throws -> ProposalBundle {
        return .init(proposal: [], proposalRef: [])
    }

    func newRemoveProposal(conversationId: ConversationId, clientId: ClientId) throws -> ProposalBundle {
        return .init(proposal: [], proposalRef: [])
    }

    func newExternalAddProposal(conversationId: ConversationId, epoch: UInt64) throws -> [UInt8] {
        return []
    }

    func newExternalRemoveProposal(conversationId: ConversationId, epoch: UInt64, keyPackageRef: [UInt8]) throws -> [UInt8] {
        return []
    }

    func joinByExternalCommit(
        publicGroupState: [UInt8],
        customConfiguration: CustomConfiguration
    ) throws -> ConversationInitBundle {
        return .init(
            conversationId: [],
            commit: [],
            publicGroupState: .init(
                encryptionType: .plaintext,
                ratchetTreeType: .full,
                payload: []
            )
        )
    }

    func exportGroupState(conversationId: ConversationId) throws -> [UInt8] {
        return []
    }

    func mergePendingGroupFromExternalCommit(conversationId: ConversationId) throws {

    }

    func clearPendingGroupFromExternalCommit(conversationId: ConversationId) throws {

    }

    func exportSecretKey(conversationId: ConversationId, keyLength: UInt32) throws -> [UInt8] {
        return []
    }

    func getClientIds(conversationId: ConversationId) throws -> [ClientId] {
        return []
    }

    func randomBytes(length: UInt32) throws -> [UInt8] {
        return []
    }

    func reseedRng(seed: [UInt8]) throws {

    }

    func commitAccepted(conversationId: ConversationId) throws {

    }

    func clearPendingProposal(conversationId: ConversationId, proposalRef: [UInt8]) throws {

    }

    func clearPendingCommit(conversationId: ConversationId) throws {

    }

    func proteusInit() throws {

    }

    func proteusSessionFromPrekey(sessionId: String, prekey: [UInt8]) throws {

    }

    func proteusSessionFromMessage(sessionId: String, envelope: [UInt8]) throws -> [UInt8] {
        return []
    }

    func proteusSessionSave(sessionId: String) throws {

    }

    func proteusSessionDelete(sessionId: String) throws {

    }

    func proteusSessionExists(sessionId: String) throws -> Bool {
        return false
    }

    func proteusDecrypt(sessionId: String, ciphertext: [UInt8]) throws -> [UInt8] {
        return []
    }

    func proteusEncrypt(sessionId: String, plaintext: [UInt8]) throws -> [UInt8] {
        return []
    }

    func proteusEncryptBatched(sessionId: [String], plaintext: [UInt8]) throws -> [String: [UInt8]] {
        return [:]
    }

    func proteusNewPrekey(prekeyId: UInt16) throws -> [UInt8] {
        return []
    }

    func proteusNewPrekeyAuto() throws -> [UInt8] {
        return []
    }

    func proteusLastResortPrekey() throws -> [UInt8] {
        return []
    }

    func proteusLastResortPrekeyId() throws -> UInt16 {
        return 0
    }

    func proteusFingerprint() throws -> String {
        return ""
    }

    func proteusFingerprintLocal(sessionId: String) throws -> String {
        return ""
    }

    func proteusFingerprintRemote(sessionId: String) throws -> String {
        return ""
    }

    func proteusFingerprintPrekeybundle(prekey: [UInt8]) throws -> String {
        return ""
    }

    func proteusCryptoboxMigrate(path: String) throws {

    }

    func newAcmeEnrollment(ciphersuite: CiphersuiteName) throws -> WireE2eIdentity {
        fatalError("not implemented")
    }

    func proteusLastErrorCode() -> UInt32 {
        return 0
    }

}
