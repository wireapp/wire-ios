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
import WireCrypto
import WireDataModel
import WireDomainPackage
import WireFoundation
import WireLogging
import WireSystem
import WireUtilitiesPackage

struct ImportLegacyBackupUseCase: ImportBackupUseCaseProtocol {

    // using WireFoundation.QualifiedID leads to linking errors
    private typealias QualifiedID = WireDataModel.QualifiedID

    let url: URL
    let userSession: @Sendable () -> UserSession?
    let dispatchGroup: ZMSDispatchGroup
    let streamDecryptor: ImportLegacyBackupStreamDecryptorProtocol
    let fileUnarchiver: FileUnarchiverProtocol
    let entityStorage: ImportBackupEntityStorageProtocol
    let appStateUpdater: ImportBackupAppStateUpdaterProtocol

    let sharedContainerURL: URL
    let logger: WireLogger

    let isImportDestructive = true

    func invoke(password: String) -> AsyncThrowingStream<ImportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task<Void, Never> { @MainActor in
                do {

                    // to start with we need an active user session, later the session will be torn down
                    guard let account = userSession()?.contextProvider.account else {
                        throw ImportLegacyBackupError.noActiveAccountForImport
                    }

                    // before we start the first operation let the user know, the progress has started
                    continuation.yield(.progress(current: 1, total: 4))

                    let unzippedURL = try decryptAndUnzipBackup(
                        url: url,
                        password: password,
                        accountID: account.userIdentifier
                    )

                    continuation.yield(.progress(current: 2, total: 4))

                    logger.debug("creating backup of user client")

                    // backup the self user and the self client
                    let selfUserQualifiedID: WireDataModel.QualifiedID?
                    let selfClientBackup: [String: Any]
                    // we want to avoid keeping a strong reference to the user
                    // session, the managed object context and the user client
                    if let userSession = userSession(),
                       let (qualifiedID, backup) = await userSession.contextProvider.viewContext.perform({
                           userSession.selfUserClient.map { ($0.user?.qualifiedID, $0.backup()) } }) {
                        selfUserQualifiedID = qualifiedID
                        selfClientBackup = backup
                    } else {
                        throw ImportLegacyBackupError.failedToBackUpUserClient
                    }

                    logger.debug("reporting migration required")

                    // user session needs to be torn down
                    await appStateUpdater.reportMigrationNeeded()
                    // TODO: [WPB-16136] ensure incoming notifications are not processed meanwhile

                    logger.debug("replacing persistent store")

                    // the imported file replaces the existing persistent store
                    try await entityStorage.replacePersistentStore(
                        accountIdentifier: account.userIdentifier,
                        from: unzippedURL,
                        applicationContainer: sharedContainerURL,
                    )

                    logger.debug("opening a temporary context")

                    let metadata = userSession()?.resolvedBackendMetadata

                    // import the self client from the backup and set the correct self user relation
                    // TODO: [WPB-15714] causes warning: we should try to initialize the model only once
                    let temporaryStack = try await entityStorage
                        .createContextProvider(
                            account: account,
                            applicationContainer: sharedContainerURL,
                            dispatchGroup: dispatchGroup,
                            localDomain: metadata?.domain,
                            isFederationEnabled: metadata?.isFederationEnabled ?? false
                        )

                    logger.debug("restoring backup of userclient")

                    try await temporaryStack.viewContext.perform {
                        let context = temporaryStack.viewContext
                        let userID = selfUserQualifiedID?.uuid
                        let domain = selfUserQualifiedID?.domain

                        var selfUser: ZMUser?
                        if let userID {
                            selfUser = ZMUser.fetch(with: userID, domain: domain, in: context)
                        }

                        let userClient = UserClient.restore(from: selfClientBackup, context: context)
                        userClient.user = selfUser
                        userClient.markAsSelfClient()
                        try context.save()
                    }

                    logger.debug("select account and start the main UI again")

                    await appStateUpdater.selectAccountAndTriggerSlowSync(account)

                    logger.debug("done")

                    continuation.yield(.done)
                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func decryptAndUnzipBackup(url: URL, password: String, accountID: UUID) throws -> URL {
        logger.debug("coordinated file access at: \(url.absoluteString)")

        let decryptedURL = decryptedURL(for: url)
        let unzippedURL = unzippedURL(for: url)

        guard
            let inputStream = InputStream(url: url),
            let outputStream = OutputStream(url: decryptedURL, append: false)
        else { throw ImportLegacyBackupError.failedToCreateStreamForDecryption }

        do {
            try streamDecryptor.decrypt(
                input: inputStream,
                output: outputStream,
                accountID: accountID,
                password: password
            )
        } catch WireCrypto.ChaCha20Poly1305.StreamEncryption.EncryptionError.mismatchingUUID {
            throw ImportLegacyBackupError.invalidAccountID
        }

        try fileUnarchiver.unzipFile(at: decryptedURL, to: unzippedURL)
        return unzippedURL
    }

    private func decryptedURL(for url: URL) -> URL {
        let randomPathComponent = UUID().uuidString
        return url.deletingLastPathComponent().appendingPathComponent(randomPathComponent)
    }

    private func unzippedURL(for url: URL) -> URL {
        let filename = url.deletingPathExtension().lastPathComponent
        return entityStorage.importsDirectory.appendingPathComponent(filename)
    }

}

// MARK: -

private extension UserClient {

    func backup() -> [String: Any] {
        var dict: [String: Any] = [:]
        for key in entity.attributesByName.keys {
            dict[key] = value(forKey: key)
        }
        return dict
    }

    static func restore(from dict: [String: Any], context: NSManagedObjectContext) -> Self {
        let userClient = insertNewObject(in: context)
        for (key, value) in dict {
            userClient.setValue(value, forKey: key)
        }
        return userClient
    }
}
