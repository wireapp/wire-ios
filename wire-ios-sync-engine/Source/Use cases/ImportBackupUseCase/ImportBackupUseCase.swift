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

import Foundation
import WireCrypto
import WireDataModel
import WireLogging
import WireSystem
import ZipArchive
import WireDomainPkg

struct ImportBackupUseCase: ImportBackupUseCaseProtocol {

    let userSession: () -> UserSession?
    let dispatchGroup: ZMSDispatchGroup
    let streamDecryptor: ImportBackupStreamDecryptorProtocol
    let fileArchiver: ImportBackupFileArchiverProtocol
    let entityStorage: ImportBackupEntityStorageProtocol
    let appStateUpdater: ImportBackupAppStateUpdaterProtocol

    let sharedContainerURL: URL
    let logger: WireLogger

    func invoke(url: URL, password: String) async throws {

        switch BackupFileExtensions(rawValue: url.pathExtension.lowercased()) {

        case .fileExtensionWithUnderscore, .fileExtensionWithHyphen:
            try await importIOSBackup(url, password)

        case nil:
            throw BackupRestoreError.invalidFileExtension
        }
    }

    private func importIOSBackup(_ url: URL, _ password: String) async throws {

        // to start with we need an active user session, later the session will be torn down
        weak var userSession = userSession()
        guard let account = userSession?.contextProvider.account else {
            throw BackupRestoreError.noActiveAccount
        }

        // before we start the first operation let the user know, the progress has started
        appStateUpdater.reportImportProgress(progress: 0.25)

        let unzippedURL = try decryptAndUnzipBackup(
            url: url,
            password: password,
            accountID: account.userIdentifier
        )

        appStateUpdater.reportImportProgress(progress: 0.5)

        // backup the self user and the self client
        let selfUserQualifiedID: QualifiedID?
        let selfClientBackup: [String: Any]
        // we want to avoid keeping a strong reference to the user
        // session, the managed object context and the user client
        if let userSession, let (qualifiedID, backup) = await userSession.contextProvider.viewContext.perform({
            userSession.selfUserClient.map { ($0.user?.qualifiedID, $0.backup()) } }) {
            selfUserQualifiedID = qualifiedID
            selfClientBackup = backup
        } else {
            throw BackupRestoreError.unknown
        }

        // user session needs to be torn down
        await appStateUpdater.reportMigrationNeeded()

        // the imported file replaces the existing persistent store
        try await entityStorage.replacePersistentStore(
            accountIdentifier: account.userIdentifier,
            from: unzippedURL,
            applicationContainer: sharedContainerURL,
            dispatchGroup: dispatchGroup
        )

        // import the self client from the backup and set the correct self user relation
        // TODO: [WPB-15714] causes warning: we should try to initialize the model only once
        let temporaryStack = try await entityStorage
            .createContextProvider(
                account: account,
                applicationContainer: sharedContainerURL,
                dispatchGroup: dispatchGroup
            )
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

        await appStateUpdater.selectAccountAndTriggerSlowSync(account)
    }

    private func decryptAndUnzipBackup(url: URL, password: String, accountID: UUID) throws -> URL {
        logger.debug("coordinated file access at: \(url.absoluteString)")

        let decryptedURL = decryptedURL(for: url)
        let unzippedURL = unzippedURL(for: url)

        guard
            let inputStream = InputStream(url: url),
            let outputStream = OutputStream(url: decryptedURL, append: false)
        else { throw BackupRestoreError.unknown }

        try streamDecryptor.decrypt(
            input: inputStream,
            output: outputStream,
            accountID: accountID,
            password: password
        )

        try fileArchiver.unzipFile(at: decryptedURL, to: unzippedURL)
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

/// There are some external apps that users can use to transfer backup files, which can modify their attachments and
/// change the underscore with a dash. For this reason, we accept 2 types of file extensions to restore conversations.
private enum BackupFileExtensions: String, CaseIterable {
    case fileExtensionWithUnderscore = "ios_wbu"
    case fileExtensionWithHyphen = "ios-wbu"
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
