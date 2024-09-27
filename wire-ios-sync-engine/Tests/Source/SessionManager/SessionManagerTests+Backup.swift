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

import WireTesting
import XCTest
@testable import WireSyncEngine

// MARK: - SessionManagerBackupTests

final class SessionManagerBackupTests: IntegrationTest {
    // MARK: Internal

    override var useInMemoryStore: Bool {
        false
    }

    override func setUp() {
        super.setUp()
        createSelfUserAndConversation()
        createExtraUsersAndConversations()
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        backupURL = directory.appendingPathComponent("BackupTests")
        unzippedURL = directory.appendingPathComponent("BackupTests_Unzipped")

        do {
            try FileManager.default.createDirectory(
                atPath: backupURL.path,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try FileManager.default.createDirectory(
                atPath: unzippedURL.path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            XCTFail("Unable to create directories: \(error)")
        }
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: backupURL)
        try? FileManager.default.removeItem(at: unzippedURL)
        backupURL = nil
        unzippedURL = nil
        super.tearDown()
    }

    func testThatItReturnsAnErrorWhenThereIsNoSelectedAccount() {
        // given
        // when
        let result = backupActiveAcount(password: name)

        // then
        XCTAssertThrowsError(try result.get()) { error in
            switch error as? SessionManager.BackupError {
            case .noActiveAccount:
                break
            default:
                XCTFail("expected error '.noActiveAccount'")
            }
        }
    }

    func testThatItCreatesABackupIncludingMetadataAndZipsIt() throws {
        // Given
        XCTAssert(login())

        // When
        let result = backupActiveAcount(password: "12345678")
        let url = try result.get()

        let decryptedURL = createTemporaryURL()
        let moc = sessionManager!.activeUserSession!.managedObjectContext
        try SessionManager.decrypt(
            from: url,
            to: decryptedURL,
            password: "12345678",
            accountId: ZMUser.selfUser(in: moc).remoteIdentifier!
        )

        guard decryptedURL.unzip(to: unzippedURL) else { return XCTFail("Decompression failed") }

        // Then
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let expectedName = "Wire-\(selfUser!.handle!)-Backup_\(formatter.string(from: .init())).ios_wbu"

        XCTAssertEqual(url.lastPathComponent, expectedName)
        let dataURL = unzippedURL.appendingPathComponent("data")
        let metadataURL = unzippedURL.appendingPathComponent("export.json")
        let metadata = try BackupMetadata(url: metadataURL)

        XCTAssertEqual(metadata.platform, .iOS)
        XCTAssertEqual(metadata.appVersion, Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
        XCTAssertEqual(metadata.userIdentifier, sessionManager?.accountManager.selectedAccount?.userIdentifier)
        XCTAssert(FileManager.default.fileExists(atPath: dataURL.path))
    }

    func testThatItReturnsAnErrorWhenUserIsNotAuthenticated() throws {
        sessionManager?.logoutCurrentSession()
        do {
            try restoreAcount(password: name, from: createTemporaryURL()).get()
        } catch SessionManager.BackupError.notAuthenticated {
            // expected
        }
    }

    func testThatItImportsAZippedBackup() throws {
        // Given
        XCTAssert(login())
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory)
        else { return XCTFail() }

        let backupResult = backupActiveAcount(password: name)
        let url = try backupResult.get()

        let moc = sessionManager!.activeUserSession!.managedObjectContext
        let userId = ZMUser.selfUser(in: moc).remoteIdentifier!
        let accountFolder = CoreDataStack.accountDataFolder(
            accountIdentifier: userId,
            applicationContainer: sharedContainer
        )
        let fm = FileManager.default
        try fm.removeItem(at: accountFolder)
        let storePath = accountFolder.appendingPathComponent("store").path
        XCTAssertFalse(fm.fileExists(atPath: storePath))

        // When
        let result = restoreAcount(password: name, from: url)

        // Then
        try result.get()
        XCTAssert(fm.fileExists(atPath: storePath))
    }

    func testThatItReturnsAnErrorWhenImportingFileWithWrongPathExtension() throws {
        // Given
        XCTAssert(login())

        try FileManager.default.createDirectory(
            atPath: backupURL.path,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let dataURL = backupURL.appendingPathComponent("invalid_backup.zip")
        let randomData = Data.secureRandomData(length: 1024)
        try randomData.write(to: dataURL)
        let encryptedURL = createTemporaryURL()
        let moc = sessionManager!.activeUserSession!.managedObjectContext
        try SessionManager.encrypt(
            from: dataURL,
            to: encryptedURL,
            password: "notsorandom",
            accountId: ZMUser.selfUser(in: moc).remoteIdentifier!
        )

        do {
            // When
            try restoreAcount(password: "notsorandom", from: encryptedURL).get()
        } catch SessionManager.BackupError.invalidFileExtension {
            // Then
        }
    }

    func testThatItCanRestoreFileWithAHyphenInTheFileExtension() throws {
        // Given
        XCTAssert(login())

        let backupResult = backupActiveAcount(password: name)
        let url = try backupResult.get()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let fileExtensionWithHyphen = "Wire-\(selfUser!.handle!)-Backup_\(formatter.string(from: .init())).ios-wbu"

        let fm = FileManager.default
        try fm.createDirectory(atPath: backupURL.path, withIntermediateDirectories: true, attributes: nil)
        let dataURL = backupURL.appendingPathComponent(fileExtensionWithHyphen)
        try? fm.copyItem(at: url, to: dataURL)

        // When
        XCTAssertEqual(dataURL.lastPathComponent, fileExtensionWithHyphen)
        let result = restoreAcount(password: name, from: dataURL)

        // Then
        try result.get()
    }

    func testThatItReturnsAnErrorWhenImportingFileWithWrongPassword() throws {
        // Given
        XCTAssert(login())
        let backupResult = backupActiveAcount(password: "correctpassword")
        let url = try backupResult.get()

        do {
            // When
            try restoreAcount(password: "wrongpassword!!11!", from: url).get()
        } catch SessionManager.BackupError.decryptionError {
            // Then
        }
    }

    func testThatItDeletesABackup() throws {
        // Given
        let sessionManager = try XCTUnwrap(sessionManager)
        XCTAssert(login())

        let result = backupActiveAcount(password: "idontneednopassword")
        let url = try result.get()
        try restoreAcount(password: "idontneednopassword", from: url).get()
        XCTAssert(FileManager.default.fileExists(atPath: CoreDataStack.backupsDirectory.path))
        XCTAssert(FileManager.default.fileExists(atPath: CoreDataStack.importsDirectory.path))

        // When
        sessionManager.clearPreviousBackups()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // Then
        XCTAssertFalse(FileManager.default.fileExists(atPath: CoreDataStack.backupsDirectory.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: CoreDataStack.importsDirectory.path))
    }

    func DISABLED_testThatItDeletesOldEphemeralMessagesWhenRestoringFromABackup() throws {
        // Given
        XCTAssert(login())

        let nonce = UUID.create()

        do {
            let conversation = conversation(for: selfToUser1Conversation)!
            conversation.setMessageDestructionTimeoutValue(.custom(0.5), for: .selfUser)
            let moc = sessionManager!.activeUserSession!.managedObjectContext

            let message = try! conversation.appendText(content: "foo") as! ZMClientMessage
            message.nonce = nonce
            message.sender = ZMUser.insertNewObject(in: moc)
            message.sender?.remoteIdentifier = .create()
            XCTAssert(message.startSelfDestructionIfNeeded())
            XCTAssertNotNil(message.destructionDate)
            XCTAssertNotNil(message.textMessageData?.messageText)
            XCTAssertNotNil(message.sender)
            XCTAssert(moc.saveOrRollback())
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // When
        let result = backupActiveAcount(password: "12345678")
        let url = try result.get()
        deleteAuthenticationCookie()
        recreateSessionManagerAndDeleteLocalData()
        XCTAssert(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        try restoreAcount(password: "12345678", from: url).get()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssert(login())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        spinMainQueue(withTimeout: 2)

        // Then
        wait(forConditionToBeTrue: {
            guard let moc = self.sessionManager?.activeUserSession?.managedObjectContext else { return false }
            guard let conversation = self.conversation(for: self.selfToUser1Conversation) else { return false }
            let message = ZMMessage.fetch(withNonce: nonce, for: conversation, in: moc)
            return message?.textMessageData?.messageText == nil && message?.sender == nil
        }(), timeout: 5)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    // MARK: Private

    private var backupURL: URL!
    private var unzippedURL: URL!

    private func createTemporaryURL() -> URL {
        backupURL.appendingPathComponent(UUID().uuidString)
    }

    // MARK: - Helper

    private func backupActiveAcount(
        password: String,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Result<URL, Error> {
        var result: Result<URL, Error> = .failure(TestError.uninitialized)
        sessionManager?.backupActiveAccount(password: password) { result = $0 }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
        return result
    }

    private func restoreAcount(
        password: String,
        from url: URL,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Result<Void, Error> {
        var result: Result<Void, Error> = .failure(TestError.uninitialized)
        sessionManager?.restoreFromBackup(at: url, password: password) { result = $0 }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        return result
    }
}

// MARK: - TestError

private enum TestError: Error {
    case uninitialized
}
