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

import Foundation
import WireDataModel
import WireCoreCrypto

class MockCoreCrypto: CoreCryptoProtocol {

    // MARK: - mlsInit

    var mockMlsInit: ((ClientId, Ciphersuites) throws -> Void)?

    func mlsInit(clientId: ClientId, ciphersuites: Ciphersuites) throws {
        guard let mock = mockMlsInit else {
            fatalError("no mock for `mlsInit`")
        }

        try mock(clientId, ciphersuites)
    }

    // MARK: - mlsGenerateKeypair

    var mockMlsGenerateKeypair: ((Ciphersuites) throws -> [UInt8])?

    func mlsGenerateKeypair(ciphersuites: Ciphersuites) throws -> [UInt8] {
        guard let mock = mockMlsGenerateKeypair else {
            fatalError("no mock for `mlsGenerateKeypair`")
        }

        return try mock(ciphersuites)
    }

    // MARK: - mlsInitWithClientId

    var mockMlsInitWithClientId: ((ClientId, [[Byte]], Ciphersuites) throws -> Void)?

    func mlsInitWithClientId(clientId: ClientId, signaturePublicKeys: [[UInt8]], ciphersuites: Ciphersuites) throws {

        guard let mock = mockMlsInitWithClientId else {
            fatalError("no mock for `mlsInitWithClientId`")
        }

        try mock(clientId, signaturePublicKeys, ciphersuites)
    }

    // MARK: - setCallbacks

    func setCallbacks(callbacks: CoreCryptoCallbacks) throws {

    }

    // MARK: - clientPublicKey

    var mockClientPublicKey: ((Ciphersuite) throws -> [UInt8])?

    func clientPublicKey(ciphersuite: Ciphersuite) throws -> [UInt8] {
        guard let mock = mockClientPublicKey else {
            fatalError("no mock for `clientPublicKey`")
        }

        return try mock(ciphersuite)
    }

    // MARK: - clientKeypackages

    var mockClientKeypackages: ((Ciphersuite, UInt32) throws -> [[UInt8]])?

    func clientKeypackages(ciphersuite: Ciphersuite, amountRequested: UInt32) throws -> [[UInt8]] {
        guard let mock = mockClientKeypackages else {
            fatalError("no mock for `clientKeypackages`")
        }

        return try mock(ciphersuite, amountRequested)
    }

    // MARK: - clientValidKeypackagesCount

    var mockClientValidKeypackagesCount: ((Ciphersuite) throws -> UInt64)?

    func clientValidKeypackagesCount(ciphersuite: Ciphersuite) throws -> UInt64 {
        guard let mock = mockClientValidKeypackagesCount else {
            fatalError("no mock for `clientValidKeypackagesCount`")
        }

        return try mock(ciphersuite)
    }

    // MARK: - createConversation

    var mockCreateConversation: ((ConversationId, MlsCredentialType, ConversationConfiguration) throws -> Void)?
    var mockCreateConversationCount = 0

    func createConversation(conversationId: ConversationId, creatorCredentialType: MlsCredentialType, config: ConversationConfiguration) throws {
        guard let mock = mockCreateConversation else {
            fatalError("no mock for `createConversation`")
        }

        mockCreateConversationCount += 1
        return try mock(conversationId, creatorCredentialType, config)
    }

    // MARK: - conversationEpoch

    var mockConversationEpoch: ((ConversationId) throws -> UInt64)?

    func conversationEpoch(conversationId: ConversationId) throws -> UInt64 {
        guard let mock = mockConversationEpoch else {
            fatalError("no mock for `conversationEpoch`")
        }

        return try mock(conversationId)
    }

    // MARK: - conversationExists

    var mockConversationExists: ((ConversationId) -> Bool)?

    func conversationExists(conversationId: ConversationId) -> Bool {
        guard let mock = mockConversationExists else {
            fatalError("no mock for `conversationExists`")
        }

        return mock(conversationId)
    }

    // MARK: - processWelcomeMessage

    var mockProcessWelcomeMessage: (([UInt8], CustomConfiguration) throws -> ConversationId)?

    func processWelcomeMessage(welcomeMessage: [UInt8], customConfiguration: CustomConfiguration) throws -> ConversationId {
        guard let mock = mockProcessWelcomeMessage else {
            fatalError("no mock for `processWelcomeMessage`")
        }

        return try mock(welcomeMessage, customConfiguration)
    }

    // MARK: - addClientsToConversation

    var mockAddClientsToConversation: ((ConversationId, [Invitee]) throws -> MemberAddedMessages)?

    func addClientsToConversation(conversationId: ConversationId, clients: [Invitee]) throws -> MemberAddedMessages {
        guard let mock = mockAddClientsToConversation else {
            fatalError("no mock for `addClientsToConversation`")
        }

        return try mock(conversationId, clients)
    }

    // MARK: - removeClientsFromConversation

    var mockRemoveClientsFromConversation: ((ConversationId, [ClientId]) throws -> CommitBundle)?

    func removeClientsFromConversation(conversationId: ConversationId, clients: [ClientId]) throws -> CommitBundle {
        guard let mock = mockRemoveClientsFromConversation else {
            fatalError("no mock for `removeClientsFromConversation`")
        }

        return try mock(conversationId, clients)
    }

    // MARK: - updateKeyingMaterial

    var mockUpdateKeyingMaterial: ((ConversationId) throws -> CommitBundle)?

    func updateKeyingMaterial(conversationId: ConversationId) throws -> CommitBundle {
        guard let mock = mockUpdateKeyingMaterial else {
            fatalError("no mock for `updateKeyingMaterial`")
        }

        return try mock(conversationId)
    }

    // MARK: - commitPendingProposals

    var mockCommitPendingProposals: ((ConversationId) throws -> CommitBundle?)?

    func commitPendingProposals(conversationId: ConversationId) throws -> CommitBundle? {
        guard let mock = mockCommitPendingProposals else {
            fatalError("no mock for `commitPendingProposals`")
        }

        return try mock(conversationId)
    }

    // MARK: - wipeConversation

    var mockWipeConversation: ((ConversationId) throws -> Void)?

    func wipeConversation(conversationId: ConversationId) throws {
        guard let mock = mockWipeConversation else {
            fatalError("no mock for `wipeConversation`")
        }

        return try mock(conversationId)
    }

    // MARK: - decryptMessage

    var mockDecryptMessage: ((ConversationId, [UInt8]) throws -> DecryptedMessage)?

    func decryptMessage(conversationId: ConversationId, payload: [UInt8]) throws -> DecryptedMessage {
        guard let mock = mockDecryptMessage else {
            fatalError("no mock for `decryptMessage`")
        }

        return try mock(conversationId, payload)
    }

    // MARK: - encryptMessage

    var mockEncryptMessage: ((ConversationId, [UInt8]) throws -> [UInt8])?

    func encryptMessage(conversationId: ConversationId, message: [UInt8]) throws -> [UInt8] {
        guard let mock = mockEncryptMessage else {
            fatalError("no mock for `encryptMessage`")
        }

        return try mock(conversationId, message)
    }

    // MARK: - newAddProposal

    var mockNewAddProposal: ((ConversationId, [UInt8]) throws -> ProposalBundle)?

    func newAddProposal(conversationId: ConversationId, keyPackage: [UInt8]) throws -> ProposalBundle {
        guard let mock = mockNewAddProposal else {
            fatalError("no mock for `newAddProposal`")
        }

        return try mock(conversationId, keyPackage)
    }

    // MARK: - newUpdateProposal

    var mockNewUpdateProposal: ((ConversationId) throws -> ProposalBundle)?

    func newUpdateProposal(conversationId: ConversationId) throws -> ProposalBundle {
        guard let mock = mockNewUpdateProposal else {
            fatalError("no mock for `newUpdateProposal`")
        }

        return try mock(conversationId)
    }

    // MARK: - newRemoveProposal

    var mockNewRemoveProposal: ((ConversationId, ClientId) throws -> ProposalBundle)?

    func newRemoveProposal(conversationId: ConversationId, clientId: ClientId) throws -> ProposalBundle {
        guard let mock = mockNewRemoveProposal else {
            fatalError("no mock for `newRemoveProposal`")
        }

        return try mock(conversationId, clientId)
    }

    // MARK: - newExternalAddProposal

    var mockNewExternalAddProposal: ((ConversationId, UInt64, Ciphersuite, MlsCredentialType) throws -> [UInt8])?

    func newExternalAddProposal(conversationId: ConversationId, epoch: UInt64, ciphersuite: Ciphersuite, credentialType: MlsCredentialType) throws -> [UInt8] {

        guard let mock = mockNewExternalAddProposal else {
            fatalError("no mock for `newExternalAddProposal`")
        }

        return try mock(conversationId, epoch, ciphersuite, credentialType)
    }

    // MARK: - newExternalRemoveProposal

    var mockNewExternalRemoveProposal: ((ConversationId, UInt64, [UInt8]) throws -> [UInt8])?

    func newExternalRemoveProposal(conversationId: ConversationId, epoch: UInt64, keyPackageRef: [UInt8]) throws -> [UInt8] {
        guard let mock = mockNewExternalRemoveProposal else {
            fatalError("no mock for `newExternalRemoveProposal`")
        }

        return try mock(conversationId, epoch, keyPackageRef)
    }

    // MARK: - joinByExternalCommit

    var mockJoinByExternalCommit: (([Byte], CustomConfiguration, MlsCredentialType) throws -> ConversationInitBundle)?

    func joinByExternalCommit(groupInfo: [UInt8],
                              customConfiguration: CustomConfiguration,
                              credentialType: MlsCredentialType) throws -> ConversationInitBundle {

        guard let mock = mockJoinByExternalCommit else {
            fatalError("no mock for `joinByExternalCommit`")
        }

        return try mock(groupInfo, customConfiguration, credentialType)
    }

    // MARK: - exportGroupInfo

    var mockExportGroupInfo: ((ConversationId) throws -> [UInt8])?

    func exportGroupInfo(conversationId: ConversationId) throws -> [UInt8] {
        guard let mock = mockExportGroupInfo else {
            fatalError("no mock for `exportGroupInfo`")
        }

        return try mock(conversationId)
    }

    // MARK: - mergePendingGroupFromExternalCommit

    var mockMergePendingGroupFromExternalCommit: ((ConversationId) throws -> Void)?

    func mergePendingGroupFromExternalCommit(conversationId: ConversationId) throws {
        guard let mock = mockMergePendingGroupFromExternalCommit else {
            fatalError("no mock for `mergePendingGroupFromExternalCommit`")
        }

        return try mock(conversationId)
    }

    // MARK: - clearPendingGroupFromExternalCommit

    var mockClearPendingGroupFromExternalCommit: ((ConversationId) throws -> Void)?

    func clearPendingGroupFromExternalCommit(conversationId: ConversationId) throws {
        guard let mock = mockClearPendingGroupFromExternalCommit else {
            fatalError("no mock for `clearPendingGroupFromExternalCommit`")
        }

        return try mock(conversationId)
    }

    // MARK: - exportSecretKey

    var mockExportSecretKey: ((ConversationId, UInt32) throws -> [Byte])?

    func exportSecretKey(conversationId: ConversationId, keyLength: UInt32) throws -> [UInt8] {
        guard let mock = mockExportSecretKey else {
            fatalError("no mock for `exportSecretKey`")
        }

        return try mock(conversationId, keyLength)
    }

    // MARK: - getClientIds

    var mockGetClientIds: ((ConversationId) throws -> [ClientId])?

    func getClientIds(conversationId: ConversationId) throws -> [ClientId] {
        guard let mock = mockGetClientIds else {
            fatalError("no mock for `getClientIds`")
        }

        return try mock(conversationId)
    }

    // MARK: - randomBytes

    var mockRandomBytes: ((UInt32) throws -> [UInt8])?

    func randomBytes(length: UInt32) throws -> [UInt8] {
        guard let mock = mockRandomBytes else {
            fatalError("no mock for `randomBytes`")
        }

        return try mock(length)
    }

    // MARK: - reseedRng

    var mockReseedRng: (([UInt8]) throws -> Void)?

    func reseedRng(seed: [UInt8]) throws {
        guard let mock = mockReseedRng else {
            fatalError("no mock for `reseedRng`")
        }

        return try mock(seed)
    }

    // MARK: - commitAccepted

    var mockCommitAccepted: ((ConversationId) throws -> Void)?

    func commitAccepted(conversationId: ConversationId) throws {
        guard let mock = mockCommitAccepted else {
            fatalError("no mock for `commitAccepted`")
        }

        return try mock(conversationId)
    }

    // MARK: - clearPendingProposal

    var mockClearPendingProposal: ((ConversationId, [UInt8]) throws -> Void)?

    func clearPendingProposal(conversationId: ConversationId, proposalRef: [UInt8]) throws {
        guard let mock = mockClearPendingProposal else {
            fatalError("no mock for `clearPendingProposal`")
        }

        return try mock(conversationId, proposalRef)
    }

    // MARK: - clearPendingCommit

    var mockClearPendingCommit: ((ConversationId) throws -> Void)?

    func clearPendingCommit(conversationId: ConversationId) throws {
        guard let mock = mockClearPendingCommit else {
            fatalError("no mock for `clearPendingCommit`")
        }

        return try mock(conversationId)
    }

    // MARK: - proteusInit

    var mockProteusInit: (() throws -> Void)?

    func proteusInit() throws {
        guard let mock = mockProteusInit else {
            fatalError("no mock for `proteusInit`")
        }

        return try mock()
    }

    // MARK: - proteusSessionFromPrekey

    var mockProteusSessionFromPrekey: ((String, [Byte]) throws -> Void)?

    func proteusSessionFromPrekey(sessionId: String, prekey: [UInt8]) throws {
        guard let mock = mockProteusSessionFromPrekey else {
            fatalError("no mock for `proteusSessionFromPrekey`")
        }

        return try mock(sessionId, prekey)
    }

    // MARK: - proteusSessionFromMessage

    var mockProteusSessionFromMessage: ((String, [Byte]) throws -> [Byte])?

    func proteusSessionFromMessage(sessionId: String, envelope: [UInt8]) throws -> [UInt8] {
        guard let mock = mockProteusSessionFromMessage else {
            fatalError("no mock for `proteusSessionFromMessage`")
        }

        return try mock(sessionId, envelope)
    }

    // MARK: - proteusSessionSave

    var mockProteusSessionSave: ((String) throws -> Void)?

    func proteusSessionSave(sessionId: String) throws {
        guard let mock = mockProteusSessionSave else {
            fatalError("no mock for `proteusSessionSave`")
        }

        return try mock(sessionId)
    }

    // MARK: - proteusSessionDelete

    var mockProteusSessionDelete: ((String) throws -> Void)?

    func proteusSessionDelete(sessionId: String) throws {
        guard let mock = mockProteusSessionDelete else {
            fatalError("no mock for `proteusSessionDelete`")
        }

        return try mock(sessionId)
    }

    // MARK: - proteusDecrypt

    var mockProteusDecrypt: ((String, [Byte]) throws -> [Byte])?

    func proteusDecrypt(sessionId: String, ciphertext: [UInt8]) throws -> [UInt8] {
        guard let mock = mockProteusDecrypt else {
            fatalError("no mock for `proteusDecrypt`")
        }

        return try mock(sessionId, ciphertext)
    }

    // MARK: - proteusEncrypt

    var mockProteusEncrypt: ((String, [Byte]) throws -> [Byte])?

    func proteusEncrypt(sessionId: String, plaintext: [UInt8]) throws -> [UInt8] {
        guard let mock = mockProteusEncrypt else {
            fatalError("no mock for `proteusEncrypt`")
        }

        return try mock(sessionId, plaintext)
    }

    // MARK: - proteusEncryptBatched

    var mockProteusEncryptBatched: (([String], [Byte]) throws -> [String: [Byte]])?

    func proteusEncryptBatched(sessionId: [String], plaintext: [UInt8]) throws -> [String: [UInt8]] {
        guard let mock = mockProteusEncryptBatched else {
            fatalError("no mock for `proteusEncryptBatched`")
        }

        return try mock(sessionId, plaintext)
    }

    // MARK: - proteusNewPrekey

    var mockProteusNewPrekey: ((UInt16) throws -> [Byte])?

    func proteusNewPrekey(prekeyId: UInt16) throws -> [UInt8] {
        guard let mock = mockProteusNewPrekey else {
            fatalError("no mock for `proteusNewPrekey`")
        }

        return try mock(prekeyId)
    }

    // MARK: - proteusFingerprint

    var mockProteusFingerprint: (() throws -> String)?

    func proteusFingerprint() throws -> String {
        guard let mock = mockProteusFingerprint else {
            fatalError("no mock for `proteusFingerprint`")
        }

        return try mock()
    }

    // MARK: - proteusCryptoboxMigrate

    var mockProteusCryptoboxMigrate: ((String) throws -> Void)?

    func proteusCryptoboxMigrate(path: String) throws {
        guard let mock = mockProteusCryptoboxMigrate else {
            fatalError("no mock for `proteusCryptoboxMigrate`")
        }

        return try mock(path)
    }

    // MARK: - proteusSessionExists

    var mockProteusSessionExists: ((String) throws -> Bool)?

    func proteusSessionExists(sessionId: String) throws -> Bool {
        guard let mock = mockProteusSessionExists else {
            fatalError("no mock for `proteusSessionExists`")
        }

        return try mock(sessionId)
    }

    // MARK: - proteusNewPrekeyAuto

    var mockProteusNewPrekeyAuto: (() throws -> ProteusAutoPrekeyBundle)?

    func proteusNewPrekeyAuto() throws -> ProteusAutoPrekeyBundle {
        guard let mock = mockProteusNewPrekeyAuto else {
            fatalError("no mock for `proteusNewPrekeyAuto`")
        }

        return try mock()
    }

    // MARK: - proteusLastResortPrekey

    var mockProteusLastResortPrekey: (() throws -> [UInt8])?

    func proteusLastResortPrekey() throws -> [UInt8] {
        guard let mock = mockProteusLastResortPrekey else {
            fatalError("no mock for `proteusLastResortPrekey`")
        }

        return try mock()
    }

    // MARK: - proteusLastResortPrekeyId

    var mockProteusLastResortPrekeyId: (() throws -> UInt16)?

    func proteusLastResortPrekeyId() throws -> UInt16 {
        guard let mock = mockProteusLastResortPrekeyId else {
            fatalError("no mock for `proteusLastResortPrekeyId`")
        }

        return try mock()
    }

    // MARK: - proteusFingerprintLocal

    var mockProteusFingerprintLocal: ((String) throws -> String)?

    func proteusFingerprintLocal(sessionId: String) throws -> String {
        guard let mock = mockProteusFingerprintLocal else {
            fatalError("no mock for `proteusFingerprintLocal`")
        }

        return try mock(sessionId)
    }

    // MARK: - proteusFingerprintRemote

    var mockProteusFingerprintRemote: ((String) throws -> String)?

    func proteusFingerprintRemote(sessionId: String) throws -> String {
        guard let mock = mockProteusFingerprintRemote else {
            fatalError("no mock for `proteusFingerprintRemote`")
        }

        return try mock(sessionId)
    }

    // MARK: - proteusFingerprintPrekeybundle

    var mockProteusFingerprintPrekeybundle: (([UInt8]) throws -> String)?

    func proteusFingerprintPrekeybundle(prekey: [UInt8]) throws -> String {
        guard let mock = mockProteusFingerprintPrekeybundle else {
            fatalError("no mock for `proteusFingerprintPrekeybundle`")
        }

        return try mock(prekey)
    }

    // MARK: - proteusLastErrorCode

    var mockProteusLastErrorCode: (() -> (UInt32))?

    func proteusLastErrorCode() -> UInt32 {
        guard let mock = mockProteusLastErrorCode else {
            fatalError("no mock for `proteusLastErrorCode`")
        }

        return mock()
    }

    // MARK: - newAcmeEnrollment

    var mockNewAcmeEnrollment: ((String, String, String, UInt32, CiphersuiteName) throws -> WireE2eIdentity)?

    func newAcmeEnrollment(clientId: String, displayName: String, handle: String, expiryDays: UInt32, ciphersuite: CiphersuiteName) throws -> WireE2eIdentity {
        guard let mock = mockNewAcmeEnrollment else {
            fatalError("no mock for `newAcmeEnrollment")
        }

        return try mock(clientId, displayName, handle, expiryDays, ciphersuite)
    }

    // MARK: - restoreFromDisk

    var mockRestoreFromDisk: (() throws -> Void)?

    func restoreFromDisk() throws {
        guard let mock = mockRestoreFromDisk else {
            fatalError("no mock for `restoreFromDisk`")
        }

        try mock()
    }

    // MARK: - markConversationAsChildOf

    var mockMarkConversationAsChildOf: ((ConversationId, ConversationId) throws -> Void)?

    func markConversationAsChildOf(childId: ConversationId, parentId: ConversationId) throws {
        guard let mock = mockMarkConversationAsChildOf else {
            fatalError("no mock for `markConversationAsChildOf")
        }

        try mock(childId, parentId)
    }

    // MARK: - e2eiMlsInit

    var mockE2eiMlsInit: ((WireE2eIdentity, String) throws -> Void)?

    func e2eiMlsInit(enrollment: WireE2eIdentity, certificateChain: String) throws {
        guard let mock = mockE2eiMlsInit else {
            fatalError("no mock for `e2eiMlsInit")
        }

        try mock(enrollment, certificateChain)
    }

    // MARK: - mlsGenerateKeypairs

    var mockMlsGenerateKeypairs: ((Ciphersuites) throws -> [[UInt8]])?

    func mlsGenerateKeypairs(ciphersuites: Ciphersuites) throws -> [[UInt8]] {
        guard let mock = mockMlsGenerateKeypairs else {
            fatalError("no mock for `mlsGenerateKeypairs")
        }

        return try mock(ciphersuites)
    }

    // MARK: - e2eiNewEnrollment

    var mockE2eiNewEnrollment: ((String, String, String, UInt32, Ciphersuite) throws -> WireE2eIdentity)?

    func e2eiNewEnrollment(clientId: String, displayName: String, handle: String, expiryDays: UInt32, ciphersuite: Ciphersuite) throws -> WireE2eIdentity {
        guard let mock = mockE2eiNewEnrollment else {
            fatalError("no mock for `e2eiNewEnrollment")
        }

        return try mock(clientId, displayName, handle, expiryDays, ciphersuite)
    }

    // MARK: - e2eiEnrollmentStash

    var mockE2eiEnrollmentStash: ((WireE2eIdentity) throws -> [UInt8])?

    func e2eiEnrollmentStash(enrollment: WireE2eIdentity) throws -> [UInt8] {
        guard let mock = mockE2eiEnrollmentStash else {
            fatalError("no mock for `e2eiEnrollmentStash")
        }

        return try mock(enrollment)
    }

    // MARK: - e2eiEnrollmentStashPop

    var mockE2eiEnrollmentStashPop: (([UInt8]) throws -> WireE2eIdentity)?

    func e2eiEnrollmentStashPop(handle: [UInt8]) throws -> WireE2eIdentity {
        guard let mock = mockE2eiEnrollmentStashPop else {
            fatalError("no mock for `e2eiEnrollmentStash")
        }

        return try mock(handle)
    }

    // MARK: - e2eiIsDegraded

    var mockE2eiIsDegraded: ((ConversationId) -> Bool)?

    func e2eiIsDegraded(conversationId: WireCoreCrypto.ConversationId) throws -> Bool {
        guard let mock = mockE2eiIsDegraded else {
            fatalError("no mock for `e2eiIsDegraded")
        }

        return mock(conversationId)
    }

}
