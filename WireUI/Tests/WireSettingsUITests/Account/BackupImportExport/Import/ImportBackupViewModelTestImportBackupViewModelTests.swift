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
    private var mockLogger: (any LoggerProtocol)!
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

        mockLogger = WireLogger(tag: "mock")

        sut = .init(
            importBackupUseCaseFactory: ImportBackupUseCaseFactory(useCase: mockImportBackupUseCase),
            logger: mockLogger
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockLogger = nil
        mockImportBackupUseCase = nil

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
        mockImportBackupUseCase.invokePasswordStringAsyncThrowingStreamImportBackupProgressAnyErrorClosure = { _ in
            stream
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
        var (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
        mockImportBackupUseCase.invokePasswordStringAsyncThrowingStreamImportBackupProgressAnyErrorReturnValue = stream
        let sut = sut as ImportBackupViewModel

        // When
        sut.pickedBackupFile(result: .success(temporaryFile))
        wait(forConditionToBeTrue: sut.isImportConfirmationPresented, timeout: 3)
        sut.confirmOverwrite()
        wait(forConditionToBeTrue: sut.importProgress == (0, 0), timeout: 3)
        continuation.finish(throwing: ImportBackupError.passwordRequired)
        wait(forConditionToBeTrue: sut.isEnterBackupPasswordPresented, timeout: 3)
        (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
        mockImportBackupUseCase.invokePasswordStringAsyncThrowingStreamImportBackupProgressAnyErrorReturnValue = stream
        sut.enterPassword("pw")

        // Then
        wait(forConditionToBeTrue: sut.importProgress == (0, 0), timeout: 3)
        continuation.yield(.progress(1, 4))
        wait(forConditionToBeTrue: sut.importProgress == (1, 4), timeout: 3)
        continuation.yield(.done)
        wait(forConditionToBeTrue: sut.importProgress == (1, 1), timeout: 3)
        wait(forConditionToBeTrue: sut.isAlertPresented, timeout: 3)
    }

}

private struct ImportBackupUseCaseFactory: ImportBackupUseCaseFactoryProtocol {
    var useCase: any ImportBackupUseCaseProtocol
    func importBackupUseCase(for url: URL) throws -> any ImportBackupUseCaseProtocol { useCase }
}
