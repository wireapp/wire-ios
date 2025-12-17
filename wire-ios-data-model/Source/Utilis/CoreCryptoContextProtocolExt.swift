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
public protocol CoreCryptoContextProtocol: AnyObject, Sendable {

    /// See [core_crypto::mls::conversation::ConversationGuard::add_members]
    func addClientsToConversation(
        conversationId: WireCoreCryptoUniffi.ConversationId,
        keyPackages: [WireCoreCryptoUniffi.KeyPackage]
    ) async throws -> [String]?

    /// See [core_crypto::transaction_context::TransactionContext::get_or_create_client_keypackages]
    func clientKeypackages(
        ciphersuite: WireCoreCryptoUniffi.Ciphersuite,
        credentialType: WireCoreCryptoUniffi.CredentialType,
        amountRequested: UInt32
    ) async throws -> [WireCoreCryptoUniffi.KeyPackage]

    /// See [core_crypto::transaction_context::TransactionContext::client_public_key]
    func clientPublicKey(
        ciphersuite: WireCoreCryptoUniffi.Ciphersuite,
        credentialType: WireCoreCryptoUniffi.CredentialType
    ) async throws -> Data

    /// See [core_crypto::transaction_context::TransactionContext::client_valid_key_packages_count]
    func clientValidKeypackagesCount(
        ciphersuite: WireCoreCryptoUniffi.Ciphersuite,
        credentialType: WireCoreCryptoUniffi.CredentialType
    ) async throws -> UInt64

    /// See [core_crypto::mls::conversation::ConversationGuard::commit_pending_proposals]
    func commitPendingProposals(conversationId: WireCoreCryptoUniffi.ConversationId) async throws

    /// See [core_crypto::mls::conversation::Conversation::ciphersuite]
    func conversationCiphersuite(conversationId: WireCoreCryptoUniffi.ConversationId) async throws
        -> WireCoreCryptoUniffi.Ciphersuite

    /// See [core_crypto::mls::conversation::Conversation::epoch]
    func conversationEpoch(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> UInt64

    /// See [core_crypto::prelude::Session::conversation_exists]
    func conversationExists(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> Bool

    /// See [core_crypto::transaction_context::TransactionContext::new_conversation]
    func createConversation(
        conversationId: WireCoreCryptoUniffi.ConversationId,
        creatorCredentialType: WireCoreCryptoUniffi.CredentialType,
        config: WireCoreCryptoUniffi.ConversationConfiguration
    ) async throws

    /// See [core_crypto::mls::conversation::ConversationGuard::decrypt_message]
    func decryptMessage(conversationId: WireCoreCryptoUniffi.ConversationId, payload: Data) async throws
        -> WireCoreCryptoUniffi.DecryptedMessage

    /// See [core_crypto::transaction_context::TransactionContext::delete_stale_key_packages]
    func deleteStaleKeyPackages(ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws

    /// See [core_crypto::mls::conversation::ConversationGuard::disable_history_sharing]
    func disableHistorySharing(conversationId: WireCoreCryptoUniffi.ConversationId) async throws

    /// See [core_crypto::mls::conversation::Conversation::e2ei_conversation_state]
    func e2eiConversationState(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi
        .E2eiConversationState

    /// See [core_crypto::transaction_context::TransactionContext::e2ei_enrollment_stash]
    ///
    /// Note that this can only succeed if the enrollment is unique and there are no other hard refs to it.
    func e2eiEnrollmentStash(enrollment: WireCoreCryptoUniffi.E2eiEnrollment) async throws -> Data

    /// See [core_crypto::transaction_context::TransactionContext::e2ei_enrollment_stash_pop]
    func e2eiEnrollmentStashPop(handle: Data) async throws -> WireCoreCryptoUniffi.E2eiEnrollment

    /// See [core_crypto::prelude::Session::e2ei_is_enabled]
    func e2eiIsEnabled(ciphersuite: WireCoreCryptoUniffi.Ciphersuite) async throws -> Bool

    /// See [core_crypto::prelude::Session::e2ei_is_pki_env_setup]
    func e2eiIsPkiEnvSetup() async throws -> Bool

    /// See [core_crypto::transaction_context::TransactionContext::e2ei_mls_init_only]
    func e2eiMlsInitOnly(
        enrollment: WireCoreCryptoUniffi.E2eiEnrollment,
        certificateChain: String,
        nbKeyPackage: UInt32?
    ) async throws -> [String]?

    /// See [core_crypto::transaction_context::TransactionContext::e2ei_new_activation_enrollment]
    func e2eiNewActivationEnrollment(
        displayName: String,
        handle: String,
        team: String?,
        expirySec: UInt32,
        ciphersuite: WireCoreCryptoUniffi.Ciphersuite
    ) async throws -> WireCoreCryptoUniffi.E2eiEnrollment

    /// See [core_crypto::transaction_context::TransactionContext::e2ei_new_enrollment]
    func e2eiNewEnrollment(
        clientId: String,
        displayName: String,
        handle: String,
        team: String?,
        expirySec: UInt32,
        ciphersuite: WireCoreCryptoUniffi.Ciphersuite
    ) async throws -> WireCoreCryptoUniffi.E2eiEnrollment

    /// See [core_crypto::transaction_context::TransactionContext::e2ei_new_rotate_enrollment]
    func e2eiNewRotateEnrollment(
        displayName: String?,
        handle: String?,
        team: String?,
        expirySec: UInt32,
        ciphersuite: WireCoreCryptoUniffi.Ciphersuite
    ) async throws -> WireCoreCryptoUniffi.E2eiEnrollment

    /// See [core_crypto::transaction_context::TransactionContext::e2ei_register_acme_ca]
    func e2eiRegisterAcmeCa(trustAnchorPem: String) async throws

    /// See [core_crypto::transaction_context::TransactionContext::e2ei_register_crl]
    func e2eiRegisterCrl(crlDp: String, crlDer: Data) async throws -> WireCoreCryptoUniffi.CrlRegistration

    /// See [core_crypto::transaction_context::TransactionContext::e2ei_register_intermediate_ca_pem]
    func e2eiRegisterIntermediateCa(certPem: String) async throws -> [String]?

    /// See [core_crypto::mls::conversation::ConversationGuard::e2ei_rotate]
    func e2eiRotate(conversationId: WireCoreCryptoUniffi.ConversationId) async throws

    /// See [core_crypto::mls::conversation::ConversationGuard::enable_history_sharing]
    func enableHistorySharing(conversationId: WireCoreCryptoUniffi.ConversationId) async throws

    /// See [core_crypto::mls::conversation::ConversationGuard::encrypt_message]
    func encryptMessage(conversationId: WireCoreCryptoUniffi.ConversationId, message: Data) async throws -> Data

    /// See [core_crypto::mls::conversation::Conversation::export_secret_key]
    func exportSecretKey(conversationId: WireCoreCryptoUniffi.ConversationId, keyLength: UInt32) async throws
        -> WireCoreCryptoUniffi.SecretKey

    /// See [core_crypto::mls::conversation::Conversation::get_client_ids]
    func getClientIds(conversationId: WireCoreCryptoUniffi.ConversationId) async throws
        -> [WireCoreCryptoUniffi.ClientId]

    /// See [core_crypto::transaction_context::TransactionContext::get_data]
    func getData() async throws -> Data?

    /// See [core_crypto::mls::conversation::Conversation::get_device_identities]
    func getDeviceIdentities(
        conversationId: WireCoreCryptoUniffi.ConversationId,
        deviceIds: [WireCoreCryptoUniffi.ClientId]
    ) async throws -> [WireCoreCryptoUniffi.WireIdentity]

    /// See [core_crypto::mls::conversation::Conversation::get_external_sender]
    func getExternalSender(conversationId: WireCoreCryptoUniffi.ConversationId) async throws -> WireCoreCryptoUniffi
        .ExternalSenderKey

    /// See [core_crypto::mls::conversation::Conversation::get_user_identities]
    func getUserIdentities(conversationId: WireCoreCryptoUniffi.ConversationId, userIds: [String]) async throws
        -> [String: [WireCoreCryptoUniffi.WireIdentity]]

    /// See [core_crypto::transaction_context::TransactionContext::join_by_external_commit]
    func joinByExternalCommit(
        groupInfo: WireCoreCryptoUniffi.GroupInfo,
        customConfiguration: WireCoreCryptoUniffi.CustomConfiguration,
        credentialType: WireCoreCryptoUniffi.CredentialType
    ) async throws -> WireCoreCryptoUniffi.WelcomeBundle

    /// See [core_crypto::mls::conversation::ConversationGuard::mark_as_child_of]
    func markConversationAsChildOf(
        childId: WireCoreCryptoUniffi.ConversationId,
        parentId: WireCoreCryptoUniffi.ConversationId
    ) async throws

    /// See [core_crypto::transaction_context::TransactionContext::mls_init]
    func mlsInit(
        clientId: WireCoreCryptoUniffi.ClientId,
        ciphersuites: [WireCoreCryptoUniffi.Ciphersuite],
        nbKeyPackage: UInt32?
    ) async throws

    /// See [core_crypto::transaction_context::TransactionContext::process_raw_welcome_message]
    func processWelcomeMessage(
        welcomeMessage: WireCoreCryptoUniffi.Welcome,
        customConfiguration: WireCoreCryptoUniffi.CustomConfiguration
    ) async throws -> WireCoreCryptoUniffi.WelcomeBundle

    /// See [core_crypto::transaction_context::TransactionContext::proteus_decrypt]
    func proteusDecrypt(sessionId: String, ciphertext: Data) async throws -> Data

    /// Decrypt a message whether or not the proteus session already exists, and saves the session.
    /// 
    /// This is intended to replace simple usages of `proteusDecrypt`.
    /// 
    /// However, when decrypting large numbers of messages in a single session, the existing methods
    /// may be more efficient.
    func proteusDecryptSafe(sessionId: String, ciphertext: Data) async throws -> Data

    /// See [core_crypto::transaction_context::TransactionContext::proteus_encrypt]
    func proteusEncrypt(sessionId: String, plaintext: Data) async throws -> Data

    /// See [core_crypto::transaction_context::TransactionContext::proteus_encrypt_batched]
    func proteusEncryptBatched(sessions: [String], plaintext: Data) async throws -> [String: Data]

    /// See [core_crypto::transaction_context::TransactionContext::proteus_fingerprint]
    func proteusFingerprint() async throws -> String

    /// See [core_crypto::transaction_context::TransactionContext::proteus_fingerprint_local]
    func proteusFingerprintLocal(sessionId: String) async throws -> String

    /// See [core_crypto::proteus::ProteusCentral::fingerprint_prekeybundle]
    func proteusFingerprintPrekeybundle(prekey: Data) throws -> String

    /// See [core_crypto::transaction_context::TransactionContext::proteus_fingerprint_remote]
    func proteusFingerprintRemote(sessionId: String) async throws -> String

    /// See [core_crypto::proteus::ProteusCentral::try_new]
    func proteusInit() async throws

    /// See [core_crypto::transaction_context::TransactionContext::proteus_last_resort_prekey]
    func proteusLastResortPrekey() async throws -> Data

    /// See [core_crypto::proteus::ProteusCentral::last_resort_prekey_id]
    func proteusLastResortPrekeyId() throws -> UInt16

    /// Creates a new Proteus prekey with the given id and returns the CBOR-serialized version of the prekey bundle
    /// 
    /// Warning: The Proteus client **MUST** be initialized with `proteus_init` first or an error will be returned
    /// 
    /// See [core_crypto::transaction_context::TransactionContext::proteus_new_prekey]
    func proteusNewPrekey(prekeyId: UInt16) async throws -> Data

    /// Creates a new Proteus prekey with an automatically incremented ID and returns the CBOR-serialized version of the
    /// prekey bundle
    /// 
    /// Warning: The Proteus client **MUST** be initialized with `proteus_init` first or an error will be returned
    /// 
    /// See [core_crypto::transaction_context::TransactionContext::proteus_new_prekey_auto]
    func proteusNewPrekeyAuto() async throws -> WireCoreCryptoUniffi.ProteusAutoPrekeyBundle

    /// See [core_crypto::transaction_context::TransactionContext::proteus_reload_sessions]
    func proteusReloadSessions() async throws

    /// See [core_crypto::transaction_context::TransactionContext::proteus_session_delete]
    func proteusSessionDelete(sessionId: String) async throws

    /// See [core_crypto::transaction_context::TransactionContext::proteus_session_exists]
    func proteusSessionExists(sessionId: String) async throws -> Bool

    /// See [core_crypto::transaction_context::TransactionContext::proteus_session_from_message]
    func proteusSessionFromMessage(sessionId: String, envelope: Data) async throws -> Data

    /// See [core_crypto::transaction_context::TransactionContext::proteus_session_from_prekey]
    func proteusSessionFromPrekey(sessionId: String, prekey: Data) async throws

    /// See [core_crypto::transaction_context::TransactionContext::proteus_session_save]
    ///
    /// **Note**: This isn't usually needed as persisting sessions happens automatically when
    /// decrypting/encrypting messages and initializing Sessions
    func proteusSessionSave(sessionId: String) async throws

    /// See [core_crypto::prelude::Session::random_bytes].
    func randomBytes(len: UInt32) async throws -> Data

    /// See [core_crypto::mls::conversation::ConversationGuard::remove_members]
    func removeClientsFromConversation(
        conversationId: WireCoreCryptoUniffi.ConversationId,
        clients: [WireCoreCryptoUniffi.ClientId]
    ) async throws

    /// See [core_crypto::transaction_context::TransactionContext::save_x509_credential]
    func saveX509Credential(enrollment: WireCoreCryptoUniffi.E2eiEnrollment, certificateChain: String) async throws
        -> [String]?

    /// See [core_crypto::transaction_context::TransactionContext::set_data]
    func setData(data: Data) async throws

    /// See [core_crypto::mls::conversation::ConversationGuard::update_key_material]
    func updateKeyingMaterial(conversationId: WireCoreCryptoUniffi.ConversationId) async throws

    /// See [core_crypto::mls::conversation::ConversationGuard::wipe]
    func wipeConversation(conversationId: WireCoreCryptoUniffi.ConversationId) async throws
}
