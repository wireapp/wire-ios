//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireFoundation
import WireLogging

// sourcery: AutoMockable
public protocol CoreCryptoProviderProtocol {

    /// Retrieve the shared core crypto instance or create one if one does not yet exist.
    ///
    /// This function is safe to be called concurrently from multiple Tasks
    func coreCrypto() async throws -> SafeCoreCrypto

    func pkiEnvironment() async -> PkiEnvironment?

    /// Initialise a new MLS client with basic credentials
    ///
    /// - parameters:
    ///   - mlsClientID: qualified client ID of the self client
    func initialiseMLSWithBasicCredentials(mlsClientID: MLSClientID) async throws

    /// Initialise a new MLS client after completing end to end identity enrollment.
    @discardableResult
    func initialiseMLSWithEndToEndIdentity(mlsClientID: MLSClientID, credential: Credential) async throws
        -> CredentialRef

    /// Provide the mls transport which will be registered with the core crypto instance
    ///
    /// - parameters:
    ///   - transport: mls transport which sends mls messages to the backend
    func registerMlsTransport(_ transport: any MlsTransport)

    /// Provide PKI hooks
    func registerPkiEnvironmentHooks(_ hooks: any PkiEnvironmentHooks)

    /// Register observer of epochs
    ///
    /// - parameters:
    ///   - epochObserver: observer which will be informed on epoch changes
    func registerEpochObserver(_ epochObserver: any WireCoreCryptoUniffi.EpochObserver) async

}

private final class MlsTransportProxy: MlsTransport {

    var mlsTransport: (any MlsTransport)?

    func sendCommitBundle(commitBundle: WireCoreCryptoUniffi.CommitBundle) async throws {
        guard let mlsTransport else {
            throw CoreCryptoProviderError.mlsTransportNotSet
        }

        try await mlsTransport.sendCommitBundle(commitBundle: commitBundle)
    }

    func prepareForTransport(historySecret: WireCoreCryptoUniffi.HistorySecret) async -> WireCoreCryptoUniffi
        .MlsTransportData {
        guard let mlsTransport else {
            return historySecret.data
        }

        return await mlsTransport.prepareForTransport(historySecret: historySecret)
    }
}

private final class PkiEnvironmentHooksProxy: PkiEnvironmentHooks {

    var hooks: (any PkiEnvironmentHooks)?

    func httpRequest(
        method: WireCoreCryptoUniffi.HttpMethod,
        url: String,
        headers: [WireCoreCryptoUniffi.HttpHeader],
        body: Data
    ) async throws -> WireCoreCryptoUniffi.HttpResponse {
        guard let hooks else {
            throw CoreCryptoProviderError.pkiEnvironmentHooksNotSet
        }

        return try await hooks.httpRequest(method: method, url: url, headers: headers, body: body)
    }

    func authenticate(idp: String, keyAuth: String, acmeAud: String, acquisitionSnapshot: Data) async throws -> String {
        guard let hooks else {
            throw CoreCryptoProviderError.pkiEnvironmentHooksNotSet
        }

        return try await hooks.authenticate(
            idp: idp,
            keyAuth: keyAuth,
            acmeAud: acmeAud,
            acquisitionSnapshot: acquisitionSnapshot
        )
    }

    func getBackendNonce() async throws -> String {
        guard let hooks else {
            throw CoreCryptoProviderError.pkiEnvironmentHooksNotSet
        }

        return try await hooks.getBackendNonce()
    }

    func fetchBackendAccessToken(dpop: String) async throws -> String {
        guard let hooks else {
            throw CoreCryptoProviderError.pkiEnvironmentHooksNotSet
        }

        return try await hooks.fetchBackendAccessToken(dpop: dpop)
    }
}

public actor CoreCryptoProvider: CoreCryptoProviderProtocol {
    private let selfUserID: UUID
    private let sharedContainerURL: URL
    private let accountDirectory: URL
    private let sharedUserDefaults: UserDefaultsProtocol
    private var coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol
    private let featureRespository: LegacyFeatureRepositoryInterface
    private let syncContext: NSManagedObjectContext
    private let allowCreation: Bool
    private var coreCrypto: CoreCrypto?
    private var pkiEnvironment: PkiEnvironment?
    private var database: Database?
    private var loadingCoreCrypto = false
    private var hasRegisteredEpochObserver = false
    private var coreCryptoContinuations: [CheckedContinuation<CoreCrypto, Error>] = []
    private nonisolated(unsafe) var mlsTransport: MlsTransport?
    private let mlsTransportProxy: MlsTransportProxy
    private nonisolated(unsafe) var pkiEnvironmentHooks: PkiEnvironmentHooks?
    private let pkiEnvironmentHooksProxy: PkiEnvironmentHooksProxy
    private var epochObserver: WireCoreCryptoUniffi.EpochObserver?
    private let localDomain: String?

    private let backgroundTaskExecuter: any BackgroundTaskExecuter

    public init(
        selfUserID: UUID,
        sharedContainerURL: URL,
        accountDirectory: URL,
        sharedUserDefaults: UserDefaultsProtocol,
        syncContext: NSManagedObjectContext,
        coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManagerProtocol,
        allowCreation: Bool = true,
        localDomain: String?,
        backgroundTaskExecuter: any BackgroundTaskExecuter
    ) {
        self.selfUserID = selfUserID
        self.sharedContainerURL = sharedContainerURL
        self.accountDirectory = accountDirectory
        self.sharedUserDefaults = sharedUserDefaults
        self.syncContext = syncContext
        self.allowCreation = allowCreation
        self.coreCryptoKeyMigrationManager = coreCryptoKeyMigrationManager
        self.featureRespository = LegacyFeatureRepository(context: syncContext)
        self.localDomain = localDomain
        self.backgroundTaskExecuter = backgroundTaskExecuter
        self.mlsTransportProxy = MlsTransportProxy()
        self.pkiEnvironmentHooksProxy = PkiEnvironmentHooksProxy()

        let buildMetadata = WireCoreCrypto.buildMetadata()
        WireLogger.coreCrypto.info(
            "Build info timestamp: \(buildMetadata.timestamp), commit: \(buildMetadata.gitSha)",
            attributes: .safePublic
        )
    }

    public func coreCrypto() async throws -> SafeCoreCrypto {
        let coreCrypto = try await getCoreCrypto()
        return SafeCoreCrypto(
            backgroundTaskExecuter: backgroundTaskExecuter,
            coreCrypto: coreCrypto
        )
    }

    public func pkiEnvironment() async -> PkiEnvironment? {
        pkiEnvironment
    }

    public func initialiseMLSWithBasicCredentials(mlsClientID: MLSClientID) async throws {
        WireLogger.mls.info("Initialising MLS client with basic credentials")
        let defaultCiphersuite = await featureRespository.fetchMLS().config.defaultCipherSuite.coreCryptoCipherSuite
        let coreCrypto = try await getCoreCrypto()
        _ = try await coreCrypto.transaction { context in
            try await context.mlsInit(clientId: mlsClientID.cryptoId(), transport: self.mlsTransportProxy)
            let credential = try Credential.basic(cipherSuite: defaultCiphersuite, clientId: mlsClientID.cryptoId())
            _ = try await context.addCredential(credential: credential)
        }
        try await generateClientPublicKeys(with: coreCrypto, credentialType: .basic)
    }

    @discardableResult
    public func initialiseMLSWithEndToEndIdentity(
        mlsClientID: MLSClientID,
        credential: Credential
    ) async throws -> CredentialRef {
        WireLogger.mls.info("Initialising MLS client with end-to-end identity credentials")
        let coreCrypto = try await getCoreCrypto()
        let credentialRef = try await coreCrypto.transaction { context in
            try await context.mlsInit(clientId: mlsClientID.cryptoId(), transport: self.mlsTransportProxy)
            return try await context.addCredential(credential: credential)
        }

        try await generateClientPublicKeys(with: coreCrypto, credentialType: .x509)
        return credentialRef
    }

    public func registerEpochObserver(_ epochObserver: any EpochObserver) async {
        self.epochObserver = epochObserver

        do {
            try await registerEpochObserverIfNecessary(with: getCoreCrypto())
        } catch {
            WireLogger.mls.error("Failed to register epoch observer: \(error)")
        }
    }

    private func registerEpochObserverIfNecessary(with coreCrypto: CoreCrypto) async throws {
        guard let epochObserver, !hasRegisteredEpochObserver else {
            return
        }
        WireLogger.mls.debug("registerEpochObserver")
        try await coreCrypto.registerEpochObserver(epochObserver: epochObserver)
        hasRegisteredEpochObserver = true
    }

    public nonisolated func registerMlsTransport(_ transport: any MlsTransport) {
        mlsTransportProxy.mlsTransport = transport
    }

    public nonisolated func registerPkiEnvironmentHooks(_ hooks: any PkiEnvironmentHooks) {
        pkiEnvironmentHooksProxy.hooks = hooks
    }

    // Create an CoreCrypto instance with guranteees that only one task is performing
    // the operation while others wait for it to complete.
    //
    // Based on the structured caching in an actor:
    // https://forums.swift.org/t/structured-caching-in-an-actor/65501/13
    private func getCoreCrypto() async throws -> CoreCrypto {
        guard !loadingCoreCrypto else {
            WireLogger.coreCrypto.debug(
                "already loading CoreCrypto, waiting for continuation",
                attributes: .safePublic
            )
            return try await withCheckedThrowingContinuation { continuation in
                coreCryptoContinuations.append(continuation)
            }
        }

        if let coreCrypto {
            return coreCrypto
        } else {
            loadingCoreCrypto = true
            let cc: CoreCrypto
            do {
                cc = try await createCoreCrypto()
            } catch {
                resumeCoreCryptoContinuations(with: .failure(error))
                loadingCoreCrypto = false
                throw error
            }

            resumeCoreCryptoContinuations(with: .success(cc))
            loadingCoreCrypto = false
            coreCrypto = cc
            return cc
        }
    }

    private func resumeCoreCryptoContinuations(with result: Result<CoreCrypto, Error>) {
        for continuation in coreCryptoContinuations {
            WireLogger.coreCrypto.debug(
                "resuming continuations",
                attributes: .safePublic
            )
            continuation.resume(with: result)
        }
        coreCryptoContinuations = []
    }

    func createCoreCrypto() async throws -> CoreCrypto {
        let coreCryptoKeyProvider = CoreCryptoKeyProvider(
            coreCryptoKeyMigrationManager: coreCryptoKeyMigrationManager,
            userID: selfUserID,
            storage: sharedUserDefaults
        )
        let provider = CoreCryptoConfigProvider(coreCryptoKeyProvider: coreCryptoKeyProvider)

        WireLogger.coreCrypto.debug(
            "creating Core Crypto config",
            attributes: .safePublic
        )

        let configuration = try await provider.createInitialConfiguration(
            sharedContainerURL: sharedContainerURL,
            userID: selfUserID,
            allowKeyCreation: allowCreation
        )

        WireLogger.coreCrypto.info(
            "initializing Core Crypto \(WireCoreCryptoUniffiVersionNumber)",
            attributes: .safePublic
        )

        let database = try await Database.open(
            location: configuration.path,
            key: DatabaseKey(bytes: configuration.key)
        )
        self.database = database
        let coreCrypto = try CoreCrypto(database: database)

        let pkiEnvironment = try await PkiEnvironment(hooks: pkiEnvironmentHooksProxy, database: database)
        self.pkiEnvironment = pkiEnvironment
        await coreCrypto.setPkiEnvironment(pkiEnvironment: pkiEnvironment)

        updateKeychainItemAccess()

        try await configureProteusClient(coreCrypto: coreCrypto)
        try await configureMLSClient(coreCrypto: coreCrypto)

        return coreCrypto
    }

    private func configureProteusClient(coreCrypto: CoreCrypto) async throws {
        WireLogger.coreCrypto.debug(
            "configuring proteus client",
            attributes: .safePublic
        )

        try await coreCrypto.transaction {
            WireLogger.coreCrypto.debug(
                "proteus init",
                attributes: .safePublic
            )
            try await $0.proteusInit()
        }
    }

    private func configureMLSClient(coreCrypto: CoreCrypto) async throws {
        WireLogger.coreCrypto.debug(
            "configuring mls client",
            attributes: .safePublic
        )
        let mlsClientID: MLSClientID? = await syncContext.perform {
            WireLogger.coreCrypto.debug(
                "getting mls id",
                attributes: .safePublic
            )
            guard
                let selfClient = ZMUser.selfUser(in: self.syncContext).selfClient(),
                selfClient.hasRegisteredMLSClient
            else {
                return nil
            }
            return MLSClientID(
                userClient: selfClient,
                localDomain: self.localDomain
            )
        }

        // Initialise MLS if we have previously registered an MLS client
        if let mlsClientID {
            WireLogger.coreCrypto.debug(
                "checking ciphersuite",
                attributes: .safePublic
            )
            let cipherSuite = await featureRespository.fetchMLS().config.defaultCipherSuite.coreCryptoCipherSuite

            WireLogger.coreCrypto.debug(
                "core crypto transaction...",
                attributes: .safePublic
            )
            try await coreCrypto.transaction {
                WireLogger.coreCrypto.debug(
                    "mls init",
                    attributes: .safePublic
                )

                try await $0.mlsInit(clientId: mlsClientID.cryptoId(), transport: self.mlsTransportProxy)
            }
        }
    }

    // WORKAROUND:
    // Problem: Core Crypto stores an item in the keychain, but it doesn't provide an
    // access level. The default level is kSecAttrAccessibleWhenUnlocked. This means
    // that if Core Crypto is initialized while the phone is locked (e.g via the
    // notification extension or periodic background refresh) then it will fail due
    // to a keychain error thrown in Core Crypto.
    //
    // Ideal solution: Core Crypto stores the item with the appropriate access level.
    // Unfortunately it cannot do this at the moment due to Rust issues.
    //
    // Workaround: set the access level for the keychain item on our side.

    private func updateKeychainItemAccess() {
        WireLogger.coreCrypto.info("updating keychain item access")

        let accounts = accountsForAllItemsNeedingUpdates()

        WireLogger.coreCrypto.debug(
            "found \(accounts.count) accounts needing keychain access update",
            attributes: .safePublic
        )

        for (index, account) in accounts.enumerated() {
            WireLogger.coreCrypto.debug(
                "updating keychain item access for account #\(index + 1)",
                attributes: .safePublic
            )
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: "wire.com",
                kSecAttrAccount: account
            ] as CFDictionary

            let update = [
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
            ] as CFDictionary

            SecItemUpdate(query, update)
        }
    }

    private func accountsForAllItemsNeedingUpdates() -> [String] {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecReturnAttributes: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitAll
        ] as CFDictionary

        var result: AnyObject?

        guard SecItemCopyMatching(query, &result) == noErr else {
            return []
        }

        let items = result as? [[String: Any]] ?? []

        return items.compactMap { item in
            item[kSecAttrAccount as String] as? String
        }.filter { account in
            // Core Crypto says that the items are all prefixed with this.
            account.hasPrefix("keystore_salt")
        }
    }

    private func generateClientPublicKeys(
        with coreCrypto: CoreCryptoProtocol,
        credentialType: CredentialType
    ) async throws {
        let ciphersuite = await featureRespository.fetchMLS().config.defaultCipherSuite
        guard let credential = try await coreCrypto.findCredentials(
            clientId: nil,
            publicKey: nil,
            cipherSuite: ciphersuite.coreCryptoCipherSuite,
            credentialType: nil,
            earliestValidity: nil
        ).first else {
            return
        }
        WireLogger.mls.info("generating public key")

        let keyData = try await coreCrypto.publicKey(credentialRef: credential)

        await syncContext.perform {
            var keys = UserClient.MLSPublicKeys()

            switch ciphersuite {
            case .MLS_128_DHKEMP256_AES128GCM_SHA256_P256:
                keys.p256 = keyData.base64EncodedString()
            case .MLS_256_DHKEMP384_AES256GCM_SHA384_P384:
                keys.p384 = keyData.base64EncodedString()
            case .MLS_256_DHKEMP521_AES256GCM_SHA512_P521:
                keys.p521 = keyData.base64EncodedString()
            case .MLS_256_DHKEMX448_AES256GCM_SHA512_Ed448, .MLS_256_DHKEMX448_CHACHA20POLY1305_SHA512_Ed448:
                keys.ed448 = keyData.base64EncodedString()
            case .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519, .MLS_128_DHKEMX25519_CHACHA20POLY1305_SHA256_Ed25519:
                keys.ed25519 = keyData.base64EncodedString()
            }

            ZMUser.selfUser(in: self.syncContext).selfClient()?.mlsPublicKeys = keys
            self.syncContext.saveOrRollback()
        }
    }

}

enum CoreCryptoProviderError: Error {
    case missingDatabase
    case mlsTransportNotSet
    case pkiEnvironmentHooksNotSet
}
