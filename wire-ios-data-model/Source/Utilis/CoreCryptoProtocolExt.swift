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

import WireCoreCrypto

// A copy of `WireCoreCrypto.CoreCryptoProtocol` in order to be able to auto-generate a mock for it.
// Keep the protocol updated with any changes on the WireCoreCrypto side.
// This file is not member of any target!

// sourcery: AutoMockable
public protocol CoreCryptoProtocol: WireCoreCrypto.CoreCryptoProtocol {

    func addClientsToConversation(conversationId: Data, keyPackages: [Data]) async throws -> WireCoreCrypto.MemberAddedMessages

    func clearPendingCommit(conversationId: Data) async throws

    func clearPendingGroupFromExternalCommit(conversationId: Data) async throws

    func clearPendingProposal(conversationId: Data, proposalRef: Data) async throws

    func clientKeypackages(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType, amountRequested: UInt32) async throws -> [Data]

    func clientPublicKey(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> Data

    func clientValidKeypackagesCount(ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> UInt64

    func commitAccepted(conversationId: Data) async throws -> [WireCoreCrypto.BufferedDecryptedMessage]?

    func commitPendingProposals(conversationId: Data) async throws -> WireCoreCrypto.CommitBundle?

    func conversationCiphersuite(conversationId: Data) async throws -> WireCoreCrypto.Ciphersuite

    func conversationEpoch(conversationId: Data) async throws -> UInt64

    func conversationExists(conversationId: Data) async -> Bool

    func createConversation(conversationId: Data, creatorCredentialType: WireCoreCrypto.MlsCredentialType, config: WireCoreCrypto.ConversationConfiguration) async throws

    func decryptMessage(conversationId: Data, payload: Data) async throws -> WireCoreCrypto.DecryptedMessage

    func deleteKeypackages(refs: [Data]) async throws

    func e2eiConversationState(conversationId: Data) async throws -> WireCoreCrypto.E2eiConversationState

    func e2eiDumpPkiEnv() async throws -> WireCoreCrypto.E2eiDumpedPkiEnv?

    func e2eiEnrollmentStash(enrollment: WireCoreCrypto.E2eiEnrollment) async throws -> Data

    func e2eiEnrollmentStashPop(handle: Data) async throws -> WireCoreCrypto.E2eiEnrollment

    func e2eiIsEnabled(ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> Bool

    func e2eiIsPkiEnvSetup() async -> Bool

    func e2eiMlsInitOnly(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?) async throws -> [String]?

    func e2eiNewActivationEnrollment(displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment

    func e2eiNewEnrollment(clientId: String, displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment

    func e2eiNewRotateEnrollment(displayName: String?, handle: String?, team: String?, expirySec: UInt32, ciphersuite: WireCoreCrypto.Ciphersuite) async throws -> WireCoreCrypto.E2eiEnrollment

    func e2eiRegisterAcmeCa(trustAnchorPem: String) async throws

    func e2eiRegisterCrl(crlDp: String, crlDer: Data) async throws -> WireCoreCrypto.CrlRegistration

    func e2eiRegisterIntermediateCa(certPem: String) async throws -> [String]?

    func e2eiRotateAll(enrollment: WireCoreCrypto.E2eiEnrollment, certificateChain: String, newKeyPackagesCount: UInt32) async throws -> WireCoreCrypto.RotateBundle

    func encryptMessage(conversationId: Data, message: Data) async throws -> Data

    func exportSecretKey(conversationId: Data, keyLength: UInt32) async throws -> Data

    func getClientIds(conversationId: Data) async throws -> [WireCoreCrypto.ClientId]

    func getCredentialInUse(groupInfo: Data, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> WireCoreCrypto.E2eiConversationState

    func getDeviceIdentities(conversationId: Data, deviceIds: [WireCoreCrypto.ClientId]) async throws -> [WireCoreCrypto.WireIdentity]

    func getExternalSender(conversationId: Data) async throws -> Data

    func getUserIdentities(conversationId: Data, userIds: [String]) async throws -> [String: [WireCoreCrypto.WireIdentity]]

    func joinByExternalCommit(groupInfo: Data, customConfiguration: WireCoreCrypto.CustomConfiguration, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> WireCoreCrypto.ConversationInitBundle

    func markConversationAsChildOf(childId: Data, parentId: Data) async throws

    func mergePendingGroupFromExternalCommit(conversationId: Data) async throws -> [WireCoreCrypto.BufferedDecryptedMessage]?

    func mlsGenerateKeypairs(ciphersuites: WireCoreCrypto.Ciphersuites) async throws -> [WireCoreCrypto.ClientId]

    func mlsInit(clientId: WireCoreCrypto.ClientId, ciphersuites: WireCoreCrypto.Ciphersuites, nbKeyPackage: UInt32?) async throws

    func mlsInitWithClientId(clientId: WireCoreCrypto.ClientId, tmpClientIds: [WireCoreCrypto.ClientId], ciphersuites: WireCoreCrypto.Ciphersuites) async throws

    func newAddProposal(conversationId: Data, keypackage: Data) async throws -> WireCoreCrypto.ProposalBundle

    func newExternalAddProposal(conversationId: Data, epoch: UInt64, ciphersuite: WireCoreCrypto.Ciphersuite, credentialType: WireCoreCrypto.MlsCredentialType) async throws -> Data

    func newRemoveProposal(conversationId: Data, clientId: WireCoreCrypto.ClientId) async throws -> WireCoreCrypto.ProposalBundle

    func newUpdateProposal(conversationId: Data) async throws -> WireCoreCrypto.ProposalBundle

    func processWelcomeMessage(welcomeMessage: Data, customConfiguration: WireCoreCrypto.CustomConfiguration) async throws -> WireCoreCrypto.WelcomeBundle

    func proteusCryptoboxMigrate(path: String) async throws

    func proteusDecrypt(sessionId: String, ciphertext: Data) async throws -> Data

    func proteusEncrypt(sessionId: String, plaintext: Data) async throws -> Data

    func proteusEncryptBatched(sessions: [String], plaintext: Data) async throws -> [String: Data]

    func proteusFingerprint() async throws -> String

    func proteusFingerprintLocal(sessionId: String) async throws -> String

    func proteusFingerprintPrekeybundle(prekey: Data) throws -> String

    func proteusFingerprintRemote(sessionId: String) async throws -> String

    func proteusInit() async throws

    func proteusLastErrorCode() -> UInt32

    func proteusLastResortPrekey() async throws -> Data

    func proteusLastResortPrekeyId() throws -> UInt16

    func proteusNewPrekey(prekeyId: UInt16) async throws -> Data

    func proteusNewPrekeyAuto() async throws -> WireCoreCrypto.ProteusAutoPrekeyBundle

    func proteusSessionDelete(sessionId: String) async throws

    func proteusSessionExists(sessionId: String) async throws -> Bool

    func proteusSessionFromMessage(sessionId: String, envelope: Data) async throws -> Data

    func proteusSessionFromPrekey(sessionId: String, prekey: Data) async throws

    func proteusSessionSave(sessionId: String) async throws

    func randomBytes(len: UInt32) async throws -> Data

    func removeClientsFromConversation(conversationId: Data, clients: [WireCoreCrypto.ClientId]) async throws -> WireCoreCrypto.CommitBundle

    func reseedRng(seed: Data) async throws

    func restoreFromDisk() async throws

    func setCallbacks(callbacks: any WireCoreCrypto.CoreCryptoCallbacks) async throws

    func unload() async throws

    func updateKeyingMaterial(conversationId: Data) async throws -> WireCoreCrypto.CommitBundle

    func wipe() async throws

    func wipeConversation(conversationId: Data) async throws
}
