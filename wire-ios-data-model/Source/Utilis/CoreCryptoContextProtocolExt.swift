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

import WireCoreCrypto

// sourcery: AutoMockable
public protocol CoreCryptoContextProtocol: WireCoreCryptoUniffi.CoreCryptoContextProtocol {

    /**
     * See [core_crypto::mls::conversation::conversation_guard::ConversationGuard::add_members]
     */
    func addClientsToConversation(conversationId: Data, keyPackages: [Data]) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints

    /**
     * See [core_crypto::context::CentralContext::get_or_create_client_keypackages]
     */
    func clientKeypackages(ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.MlsCredentialType, amountRequested: UInt32) async throws -> [Data]

    /**
     * See [core_crypto::mls::MlsCentral::client_public_key]
     */
    func clientPublicKey(ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.MlsCredentialType) async throws -> Data

    /**
     * See [core_crypto::context::CentralContext::client_valid_key_packages_count]
     */
    func clientValidKeypackagesCount(ciphersuite: WireCoreCryptoUniffi.Ciphersuite, credentialType: WireCoreCryptoUniffi.MlsCredentialType) async throws -> UInt64

    /**
     * See [core_crypto::mls::conversation::conversation_guard::ConversationGuard::commit_pending_proposals]
     */
    func commitPendingProposals(conversationId: Data) async throws

    /**
     * See [core_crypto::mls::conversation::ConversationGuard::ciphersuite]
     */
    func conversationCiphersuite(conversationId: Data) async throws -> WireCoreCryptoUniffi.Ciphersuite

    /**
     * See [core_crypto::mls::conversation::ConversationGuard::epoch]
     */
    func conversationEpoch(conversationId: Data) async throws -> UInt64

    /**
     * See [core_crypto::mls::MlsCentral::conversation_exists]
     */
    func conversationExists(conversationId: Data) async throws -> Bool

    /**
     * See [core_crypto::context::CentralContext::new_conversation]
     */
    func createConversation(conversationId: Data, creatorCredentialType: WireCoreCryptoUniffi.MlsCredentialType, config: WireCoreCryptoUniffi.ConversationConfiguration) async throws

    /**
     * See [core_crypto::mls::conversation::conversation_guard::ConversationGuard::decrypt_message]
     */
    func decryptMessage(conversationId: Data, payload: Data) async throws -> WireCoreCryptoUniffi.DecryptedMessage

    /**
     * See [core_crypto::context::CentralContext::delete_keypackages]
     */
    func deleteKeypackages(refs: [Data]) async throws

    /**
     * See [core_crypto::context::CentralContext::delete_stale_key_packages]
     */
    func deleteStaleKeyPackages(ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws

    /**
     * See [core_crypto::mls::conversation::conversation_guard::ConversationGuard::e2ei_conversation_state]
     */
    func e2eiConversationState(conversationId: Data) async throws -> WireCoreCryptoUniffi.E2eiConversationState

    func e2eiDumpPkiEnv() async throws -> WireCoreCryptoUniffi.E2eiDumpedPkiEnv?

    /**
     * See [core_crypto::context::CentralContext::e2ei_enrollment_stash]
     */
    func e2eiEnrollmentStash(enrollment: WireCoreCryptoUniffi.E2eiEnrollment) async throws -> Data

    /**
     * See [core_crypto::context::CentralContext::e2ei_enrollment_stash_pop]
     */
    func e2eiEnrollmentStashPop(handle: Data) async throws -> WireCoreCryptoUniffi.E2eiEnrollment

    /**
     * See [core_crypto::mls::MlsCentral::e2ei_is_enabled]
     */
    func e2eiIsEnabled(ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws -> Bool

    /**
     * See [core_crypto::mls::MlsCentral::e2ei_is_pki_env_setup]
     */
    func e2eiIsPkiEnvSetup() async throws -> Bool

    /**
     * See [core_crypto::context::CentralContext::e2ei_mls_init_only]
     */
    func e2eiMlsInitOnly(enrollment: WireCoreCryptoUniffi.E2eiEnrollment, certificateChain: String, nbKeyPackage: UInt32?) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints

    /**
     * See [core_crypto::context::CentralContext::e2ei_new_activation_enrollment]
     */
    func e2eiNewActivationEnrollment(displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws -> WireCoreCryptoUniffi.E2eiEnrollment

    /**
     * See [core_crypto::context::CentralContext::e2ei_new_enrollment]
     */
    func e2eiNewEnrollment(clientId: String, displayName: String, handle: String, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws -> WireCoreCryptoUniffi.E2eiEnrollment

    /**
     * See [core_crypto::context::CentralContext::e2ei_new_rotate_enrollment]
     */
    func e2eiNewRotateEnrollment(displayName: String?, handle: String?, team: String?, expirySec: UInt32, ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws -> WireCoreCryptoUniffi.E2eiEnrollment

    /**
     * See [core_crypto::context::CentralContext::e2ei_register_acme_ca]
     */
    func e2eiRegisterAcmeCa(trustAnchorPem: String) async throws

    /**
     * See [core_crypto::context::CentralContext::e2ei_register_crl]
     */
    func e2eiRegisterCrl(crlDp: String, crlDer: Data) async throws -> WireCoreCryptoUniffi.CrlRegistration

    /**
     * See [core_crypto::context::CentralContext::e2ei_register_intermediate_ca_pem]
     */
    func e2eiRegisterIntermediateCa(certPem: String) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints

    /**
     * See [core_crypto::mls::conversation::ConversationGuard::e2ei_rotate]
     */
    func e2eiRotate(conversationId: Data) async throws

    /**
     * See [core_crypto::mls::conversation::conversation_guard::ConversationGuard::encrypt_message]
     */
    func encryptMessage(conversationId: Data, message: Data) async throws -> Data

    /**
     * See [core_crypto::mls::conversation::ImmutableConversation::export_secret_key]
     */
    func exportSecretKey(conversationId: Data, keyLength: UInt32) async throws -> Data

    /**
     * See [core_crypto::mls::conversation::ImmutableConversation::get_client_ids]
     */
    func getClientIds(conversationId: Data) async throws -> [WireCoreCryptoUniffi.ClientId]

    /**
     * See [core_crypto::mls::MlsCentral::get_credential_in_use]
     */
    func getCredentialInUse(groupInfo: Data, credentialType: WireCoreCryptoUniffi.MlsCredentialType) async throws -> WireCoreCryptoUniffi.E2eiConversationState

    /**
     * See [core_crypto::context::CentralContext::get_data].
     */
    func getData() async throws -> Data?

    /**
     * See [core_crypto::mls::MlsCentral::get_device_identities]
     */
    func getDeviceIdentities(conversationId: Data, deviceIds: [WireCoreCryptoUniffi.ClientId]) async throws -> [WireCoreCryptoUniffi.WireIdentity]

    /**
     * See [core_crypto::mls::conversation::ImmutableConversation::get_external_sender]
     */
    func getExternalSender(conversationId: Data) async throws -> Data

    /**
     * See [core_crypto::mls::MlsCentral::get_user_identities]
     */
    func getUserIdentities(conversationId: Data, userIds: [String]) async throws -> [String : [WireCoreCryptoUniffi.WireIdentity]]

    /**
     * See [core_crypto::context::CentralContext::join_by_external_commit]
     */
    func joinByExternalCommit(groupInfo: Data, customConfiguration: WireCoreCryptoUniffi.CustomConfiguration, credentialType: WireCoreCryptoUniffi.MlsCredentialType) async throws -> WireCoreCryptoUniffi.WelcomeBundle

    /**
     * See [core_crypto::mls::conversation::ConversationGuard::mark_as_child_of]
     */
    func markConversationAsChildOf(childId: Data, parentId: Data) async throws

    /**
     * See [core_crypto::context::CentralContext::mls_generate_keypairs]
     */
    func mlsGenerateKeypairs(ciphersuites: WireCoreCryptoUniffi.Ciphersuites) async throws -> [WireCoreCryptoUniffi.ClientId]

    /**
     * See [core_crypto::context::CentralContext::mls_init]
     */
    func mlsInit(clientId: WireCoreCryptoUniffi.ClientId, ciphersuites: WireCoreCryptoUniffi.Ciphersuites, nbKeyPackage: UInt32?) async throws

    /**
     * See [core_crypto::context::CentralContext::mls_init_with_client_id]
     */
    func mlsInitWithClientId(clientId: WireCoreCryptoUniffi.ClientId, tmpClientIds: [WireCoreCryptoUniffi.ClientId], ciphersuites: WireCoreCryptoUniffi.Ciphersuites) async throws

    /**
     * See [core_crypto::context::CentralContext::process_raw_welcome_message]
     */
    func processWelcomeMessage(welcomeMessage: Data, customConfiguration: WireCoreCryptoUniffi.CustomConfiguration) async throws -> WireCoreCryptoUniffi.WelcomeBundle

    /**
     * See [core_crypto::context::CentralContext::proteus_cryptobox_migrate]
     */
    func proteusCryptoboxMigrate(path: String) async throws

    /**
     * See [core_crypto::context::CentralContext::proteus_decrypt]
     */
    func proteusDecrypt(sessionId: String, ciphertext: Data) async throws -> Data

    /**
     * See [core_crypto::context::CentralContext::proteus_encrypt]
     */
    func proteusEncrypt(sessionId: String, plaintext: Data) async throws -> Data

    /**
     * See [core_crypto::context::CentralContext::proteus_encrypt_batched]
     */
    func proteusEncryptBatched(sessions: [String], plaintext: Data) async throws -> [String : Data]

    /**
     * See [core_crypto::context::CentralContext::proteus_fingerprint]
     */
    func proteusFingerprint() async throws -> String

    /**
     * See [core_crypto::context::CentralContext::proteus_fingerprint_local]
     */
    func proteusFingerprintLocal(sessionId: String) async throws -> String

    /**
     * See [core_crypto::proteus::ProteusCentral::fingerprint_prekeybundle]
     * NOTE: uniffi doesn't support associated functions, so we have to have the self here
     */
    func proteusFingerprintPrekeybundle(prekey: Data) throws -> String

    /**
     * See [core_crypto::context::CentralContext::proteus_fingerprint_remote]
     */
    func proteusFingerprintRemote(sessionId: String) async throws -> String

    /**
     * See [core_crypto::proteus::ProteusCentral::try_new]
     */
    func proteusInit() async throws

    /**
     * See [core_crypto::context::CentralContext::proteus_last_resort_prekey]
     */
    func proteusLastResortPrekey() async throws -> Data

    /**
     * See [core_crypto::context::CentralContext::proteus_last_resort_prekey_id]
     */
    func proteusLastResortPrekeyId() throws -> UInt16

    /**
     * See [core_crypto::context::CentralContext::proteus_new_prekey]
     */
    func proteusNewPrekey(prekeyId: UInt16) async throws -> Data

    /**
     * See [core_crypto::context::CentralContext::proteus_new_prekey_auto]
     */
    func proteusNewPrekeyAuto() async throws -> WireCoreCryptoUniffi.ProteusAutoPrekeyBundle

    /**
     * See [core_crypto::context::CentralContext::proteus_reload_sessions]
     */
    func proteusReloadSessions() async throws

    /**
     * See [core_crypto::context::CentralContext::proteus_session_delete]
     */
    func proteusSessionDelete(sessionId: String) async throws

    /**
     * See [core_crypto::context::CentralContext::proteus_session_exists]
     */
    func proteusSessionExists(sessionId: String) async throws -> Bool

    /**
     * See [core_crypto::context::CentralContext::proteus_session_from_message]
     */
    func proteusSessionFromMessage(sessionId: String, envelope: Data) async throws -> Data

    /**
     * See [core_crypto::context::CentralContext::proteus_session_from_prekey]
     */
    func proteusSessionFromPrekey(sessionId: String, prekey: Data) async throws

    /**
     * See [core_crypto::context::CentralContext::proteus_session_save]
     * **Note**: This isn't usually needed as persisting sessions happens automatically when decrypting/encrypting messages and initializing Sessions
     */
    func proteusSessionSave(sessionId: String) async throws

    /**
     * See [core_crypto::context::CentralContext::remove_members_from_conversation]
     */
    func removeClientsFromConversation(conversationId: Data, clients: [WireCoreCryptoUniffi.ClientId]) async throws

    /**
     * See [core_crypto::context::CentralContext::save_x509_credential]
     */
    func saveX509Credential(enrollment: WireCoreCryptoUniffi.E2eiEnrollment, certificateChain: String) async throws -> WireCoreCryptoUniffi.NewCrlDistributionPoints

    /**
     * See [core_crypto::context::CentralContext::set_data].
     */
    func setData(data: Data) async throws

    /**
     * See [core_crypto::context::CentralContext::update_keying_material]
     */
    func updateKeyingMaterial(conversationId: Data) async throws

    /**
     * see [core_crypto::context::CentralContext::wipe_conversation]
     */
    func wipeConversation(conversationId: Data) async throws
}
