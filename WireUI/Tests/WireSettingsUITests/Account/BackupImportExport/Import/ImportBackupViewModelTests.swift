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
import WireDomainPackage
import WireFoundation
import WireFoundationSupport
import WireLogging
import WireTestingPackage
import XCTest

@testable import WireSettingsUI
@testable import WireSettingsUISupport

@MainActor
final class ImportBackupViewModelTests: XCTestCase {

    private var temporaryDirectory: URL!
    private var temporaryFile: URL!
    private var mockImportBackupUseCase: ImportBackupUseCaseProtocolMock!
    private var mockCoordinator: MockBackgroundImportCoordinatorProtocol!
    private var mockLogger: (any LoggerProtocol)!
    private var mockFactory: ImportBackupUseCaseFactoryMock!
    private var sut: ImportBackupViewModel!

    private var fileManager: FileManager { .default }

    override func setUp() async throws {

        temporaryDirectory = try fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: Bundle(for: Self.self).bundleURL,
            create: true
        )
        temporaryFile = temporaryDirectory
            .appending(component: "someFile", directoryHint: .notDirectory)
        try Data("data".utf8).write(to: temporaryFile)

        mockImportBackupUseCase = .init()
        mockImportBackupUseCase.isImportDestructive = true

        mockFactory = .init(useCase: mockImportBackupUseCase)
        
        mockCoordinator = .init()
        mockCoordinator.startImportForPassword_MockMethod = { _, _ in
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            continuation.yield(.done)
            return stream
        }
        mockCoordinator.cancelImport_MockMethod = { }
        
        mockLogger = WireLogger(tag: "mock")

        sut = .init(
            importBackupUseCaseFactory: mockFactory,
            coordinator: mockCoordinator,
            logger: mockLogger
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockLogger = nil
        mockCoordinator = nil
        mockImportBackupUseCase = nil
        mockFactory = nil

        try fileManager.removeItem(at: temporaryDirectory)
    }

    func testConfirmationIsNeededBeforeProceeding() throws {
        // Given
        let sut = sut as ImportBackupViewModel

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))

        // Then
        wait(forConditionToBeTrue: sut.isImportConfirmationPresented, timeout: 3)
        XCTAssertFalse(sut.alertContent.title.isEmpty)
        XCTAssertFalse(sut.alertContent.message.isEmpty)
        XCTAssertFalse(sut.alertContent.cancel.isEmpty)
        XCTAssertFalse(sut.alertContent.action.isEmpty)
    }

    func testPasswordIsRequested() {
        // Given
        let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            return stream
        }
        let sut = sut as ImportBackupViewModel

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))
        wait(forConditionToBeTrue: sut.isImportConfirmationPresented, timeout: 3)
        sut.confirmOverwrite()
        continuation.finish(throwing: ImportBackupError.passwordRequired)

        // Then
        wait(forConditionToBeTrue: sut.isEnterBackupPasswordPresented, timeout: 3)
        XCTAssertFalse(sut.isBackupPasswordWrong)
    }

    func testProgressIsReported() {
        // Given
        var callCount = 0
        var capturedContinuation: AsyncThrowingStream<ImportBackupProgress, any Error>.Continuation?
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            callCount += 1
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            capturedContinuation = continuation

            if callCount == 1 {
                // First attempt: password required
                continuation.finish(throwing: ImportBackupError.passwordRequired)
            }
            // For second attempt, we'll yield progress later from the test

            return stream
        }
        let sut = sut as ImportBackupViewModel

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))
        wait(forConditionToBeTrue: sut.isImportConfirmationPresented, timeout: 3)
        sut.confirmOverwrite()
        wait(forConditionToBeTrue: sut.importProgress == (0, 0), timeout: 3)
        wait(forConditionToBeTrue: sut.isEnterBackupPasswordPresented, timeout: 3)
        sut.enterPassword("pw")

        // Then
        wait(forConditionToBeTrue: sut.importProgress == (0, 0), timeout: 3)
        capturedContinuation?.yield(.progress(1, 4))
        wait(forConditionToBeTrue: sut.importProgress == (1, 4), timeout: 3)
        capturedContinuation?.yield(.done)
        wait(forConditionToBeTrue: sut.importProgress == (1, 1), timeout: 3)
        wait(forConditionToBeTrue: sut.isAlertPresented, timeout: 3)
    }

    // MARK: - File Lifecycle Tests

    func testSuccessfulImport_CleansUpTemporaryCopy() {
        // Given
        let sut = sut as ImportBackupViewModel
        mockImportBackupUseCase.isImportDestructive = false
        
        // Set up coordinator mock for import
        var capturedContinuation: AsyncThrowingStream<ImportBackupProgress, any Error>.Continuation?
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            capturedContinuation = continuation
            return stream
        }

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))
        wait(forConditionToBeTrue: sut.isLoadingFile, timeout: 3)

        // Capture the copy URL and verify the temporary file exists
        var copyURL: URL?
        wait(forConditionToBeTrue: {
            copyURL = sut.currentBackupCopy
            return copyURL != nil
        }(), timeout: 3)
        XCTAssertNotNil(copyURL, "Temporary copy should be created")
        XCTAssertTrue(fileManager.fileExists(atPath: copyURL!.path), "Temp file should exist during import")

        // Finish the continuation to simulate the import completion
        capturedContinuation?.finish()

        // Then - Temporary copy should be cleaned up
        wait(forConditionToBeTrue: {
            sut.currentBackupCopy == nil
        }(), timeout: 3)
        XCTAssertFalse(fileManager.fileExists(atPath: copyURL!.path), "Temp file should be deleted")
    }

    func testPasswordRetry_PreservesTemporaryCopy() {
        // Given
        let sut = sut as ImportBackupViewModel
        mockImportBackupUseCase.isImportDestructive = false
        
        // Set up coordinator mock for import
        var callCount = 0
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            callCount += 1
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()

            if callCount == 1 {
                // First attempt: password required
                continuation.finish(throwing: ImportBackupError.passwordRequired)
            } else {
                // Second attempt: success
                continuation.yield(.done)
                continuation.finish()
            }
            return stream
        }

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))
        wait(forConditionToBeTrue: sut.isEnterBackupPasswordPresented, timeout: 3)

        // Verify copy still exists during password dialog
        XCTAssertNotNil(sut.currentBackupCopy, "Copy should be preserved for password retry")
        let copyURL = sut.currentBackupCopy!
        XCTAssertTrue(fileManager.fileExists(atPath: copyURL.path), "Temp file should exist during password retry")

        sut.enterPassword("password123")
        wait(forConditionToBeTrue: sut.isAlertPresented, timeout: 3)

        // Then - Same URL should be used for both attempts
        XCTAssertEqual(mockCoordinator.startImportForPassword_Invocations.count, 2, "Coordinator should be called twice")
        if mockCoordinator.startImportForPassword_Invocations.count >= 2 {
            let firstURL = mockCoordinator.startImportForPassword_Invocations[0].url
            let secondURL = mockCoordinator.startImportForPassword_Invocations[1].url
            XCTAssertEqual(firstURL, secondURL, "Should reuse same temporary copy URL")
            XCTAssertEqual(firstURL, copyURL, "Captured URL should match currentBackupCopy")
        }

        // Verify cleanup after successful import
        XCTAssertNil(sut.currentBackupCopy, "Copy reference should be nil after successful import")
        XCTAssertFalse(fileManager.fileExists(atPath: copyURL.path), "Temp file should be deleted after successful import")
    }

    func testReset_cleansUpTemporaryCopy() {
        // Given
        let sut = sut as ImportBackupViewModel
        mockImportBackupUseCase.isImportDestructive = false
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            let (stream, _) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            return stream
        }

        sut.pickedBackupFile(result: .success(temporaryFile))
        wait(forConditionToBeTrue: sut.isLoadingFile, timeout: 3)

        // Capture the copy URL
        var copyURL: URL?
        wait(forConditionToBeTrue: {
            copyURL = sut.currentBackupCopy
            return copyURL != nil
        }(), timeout: 3)
        XCTAssertNotNil(copyURL, "Temporary copy should be created")
        XCTAssertTrue(fileManager.fileExists(atPath: copyURL!.path), "Temp file should exist before reset")

        // When
        sut.reset()

        // Then
        XCTAssertNil(sut.currentBackupCopy, "Copy reference should be nil after reset")
        XCTAssertFalse(fileManager.fileExists(atPath: copyURL!.path), "Temp file should be deleted after reset")
    }

    // MARK: - Error Handling Tests

    func testInvalidFileExtension_showsAlert() {
        // Given
        let sut = sut as ImportBackupViewModel
        mockImportBackupUseCase.isImportDestructive = false
        var capturedContinuation: AsyncThrowingStream<ImportBackupProgress, any Error>.Continuation?
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            capturedContinuation = continuation
            return stream
        }

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))
        wait(forConditionToBeTrue: sut.isLoadingFile, timeout: 3)

        // Capture copy URL
        var copyURL: URL?
        wait(forConditionToBeTrue: {
            copyURL = sut.currentBackupCopy
            return copyURL != nil
        }(), timeout: 3)

        capturedContinuation?.finish(throwing: ImportBackupError.invalidFileExtension)

        // Then
        wait(forConditionToBeTrue: sut.isAlertPresented, timeout: 3)
        XCTAssertFalse(sut.alertContent.title.isEmpty)
        XCTAssertFalse(sut.alertContent.message.isEmpty)

        // Verify cleanup after error
        XCTAssertNil(sut.currentBackupCopy, "Copy should be cleaned up after error")
        if let copyURL {
            XCTAssertFalse(fileManager.fileExists(atPath: copyURL.path), "Temp file should be deleted after error")
        }
    }

    func testIncompatibleFormat_showsAlert() {
        // Given
        let sut = sut as ImportBackupViewModel
        mockImportBackupUseCase.isImportDestructive = false
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            continuation.finish(throwing: ImportBackupError.incompatibleFileFormat)
            return stream
        }

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))

        // Then
        wait(forConditionToBeTrue: sut.isAlertPresented, timeout: 3)
        XCTAssertFalse(sut.alertContent.title.isEmpty)
        XCTAssertFalse(sut.alertContent.message.isEmpty)
    }

    func testWrongAccount_showsAlert() {
        // Given
        let sut = sut as ImportBackupViewModel
        mockImportBackupUseCase.isImportDestructive = false
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            continuation.finish(throwing: ImportBackupError.selfUserIDMismatch)
            return stream
        }

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))

        // Then
        wait(forConditionToBeTrue: sut.isAlertPresented, timeout: 3)
        XCTAssertFalse(sut.alertContent.title.isEmpty)
        XCTAssertFalse(sut.alertContent.message.isEmpty)
    }

    func testLegacyPasswordRequired_showsPasswordDialog() {
        // Given
        let sut = sut as ImportBackupViewModel
        mockImportBackupUseCase.isImportDestructive = false
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            continuation.finish(throwing: ImportLegacyBackupError.passwordRequired)
            return stream
        }

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))

        // Then
        wait(forConditionToBeTrue: sut.isEnterBackupPasswordPresented, timeout: 3)
        XCTAssertFalse(sut.isBackupPasswordWrong)
    }

    func testLegacyDecryptionError_showsPasswordDialog() {
        // Given
        let sut = sut as ImportBackupViewModel
        mockImportBackupUseCase.isImportDestructive = false
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            continuation.finish(throwing: ImportLegacyBackupError.decryptionError)
            return stream
        }

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))

        // Then
        wait(forConditionToBeTrue: sut.isEnterBackupPasswordPresented, timeout: 3)
        XCTAssertTrue(sut.isBackupPasswordWrong, "Should indicate password was incorrect")
    }

    func testIncorrectPassword_showsPasswordDialogWithError() {
        // Given
        let sut = sut as ImportBackupViewModel
        mockImportBackupUseCase.isImportDestructive = false
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            continuation.finish(throwing: ImportBackupError.incorrectPassword)
            return stream
        }

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))

        // Then
        wait(forConditionToBeTrue: sut.isEnterBackupPasswordPresented, timeout: 3)
        XCTAssertTrue(sut.isBackupPasswordWrong, "Should indicate password was incorrect")
    }

    func testGenericError_showsAlert() {
        // Given
        let sut = sut as ImportBackupViewModel
        mockImportBackupUseCase.isImportDestructive = false
        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            continuation.finish(throwing: NSError(domain: "test", code: 999))
            return stream
        }

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))

        // Then
        wait(forConditionToBeTrue: sut.isAlertPresented, timeout: 3)
        XCTAssertFalse(sut.alertContent.title.isEmpty)
    }

    // MARK: - State Transition Tests

    func testEnterPassword_retriesWithCorrectPassword() {
        // Given
        let sut = sut as ImportBackupViewModel
        mockImportBackupUseCase.isImportDestructive = false
        var capturedPasswords: [String?] = []

        mockCoordinator.startImportForPassword_MockMethod = { url, password in
            capturedPasswords.append(password)
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()

            if capturedPasswords.count == 1 {
                continuation.finish(throwing: ImportBackupError.passwordRequired)
            } else {
                continuation.yield(.done)
            }
            return stream
        }

        sut.pickedBackupFile(result: .success(temporaryFile))
        wait(forConditionToBeTrue: sut.isEnterBackupPasswordPresented, timeout: 3)

        // When
        sut.enterPassword("password123")

        // Then
        wait(forConditionToBeTrue: sut.isAlertPresented, timeout: 3)
        XCTAssertEqual(capturedPasswords.count, 2)
        XCTAssertEqual(capturedPasswords[0], "")
        XCTAssertEqual(capturedPasswords[1], "password123")
    }

    func testPickBackupFileWithFailure_showsError() {
        // Given
        let sut = sut as ImportBackupViewModel
        let expectedError = NSError(domain: "test", code: 123, userInfo: nil)

        // When
        sut.pickedBackupFile(result: .failure(expectedError))

        // Then
        wait(forConditionToBeTrue: sut.isAlertPresented, timeout: 3)
    }

}
