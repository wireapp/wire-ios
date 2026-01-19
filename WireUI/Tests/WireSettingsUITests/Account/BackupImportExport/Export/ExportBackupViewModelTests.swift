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

import WireFoundation
import WireFoundationSupport
import WireLogging
import WireLoggingSupport
import WireTestingPackage
import XCTest

@testable import WireSettingsUI
@testable import WireSettingsUISupport

@MainActor
final class ExportBackupViewModelTests: XCTestCase {

    private var mockCreateBackupUseCase: CreateBackupUseCaseProtocolMock!
    private var mockCleanUpBackupsUseCase: MockCleanUpBackupsUseCaseProtocol!
    private var mockLogger: WireTaggedLoggerProtocolMock!
    private var sut: ExportBackupViewModel!

    override func setUp() async throws {
        mockCreateBackupUseCase = .init()

        mockCleanUpBackupsUseCase = .init()
        mockCleanUpBackupsUseCase.invoke_MockMethod = {}

        mockLogger = .init()

        sut = .init(
            createBackupUseCase: mockCreateBackupUseCase,
            cleanUpBackupsUseCase: mockCleanUpBackupsUseCase,
            logger: mockLogger
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockLogger = nil
        mockCleanUpBackupsUseCase = nil
        mockCreateBackupUseCase = nil
    }

    func testInitialValues() {
        XCTAssertFalse(sut.isCreatingBackupProgressPresented)
        XCTAssertFalse(sut.isSetBackupPasswordPresented)
        XCTAssertFalse(sut.isErrorAlertPresented)
    }

    func testProgressIsReported() {
        // Given
        var continuation: AsyncThrowingStream<CreateBackupProgress, any Error>.Continuation!
        mockCreateBackupUseCase.invokePasswordStringAsyncThrowingStreamCreateBackupProgressAnyErrorReturnValue = .init {
            continuation = $0
        }
        let url = URL(fileURLWithPath: "/")
        let sut = sut as ExportBackupViewModel

        // When / Then
        sut.showPasswordDialog()
        wait(forConditionToBeTrue: sut.isSetBackupPasswordPresented, timeout: 3)

        sut.createBackup(password: "pw")
        continuation.yield(.progress(1, 2))
        wait(forConditionToBeTrue: sut.backupProgress == .ongoing(current: 1, total: 2), timeout: 3)

        continuation.yield(.done(url))
        wait(forConditionToBeTrue: sut.backupProgress == .finished(url), timeout: 3)

        continuation.finish()
        sut.cancel()
        wait(forConditionToBeTrue: !self.mockCleanUpBackupsUseCase.invoke_Invocations.isEmpty, timeout: 3)
    }

    func testCancelTerminatesTask() {
        // Given
        var continuation: AsyncThrowingStream<CreateBackupProgress, any Error>.Continuation!
        mockCreateBackupUseCase.invokePasswordStringAsyncThrowingStreamCreateBackupProgressAnyErrorReturnValue = .init {
            continuation = $0
        }
        let sut = sut as ExportBackupViewModel
        let expectation = XCTestExpectation()
        continuation.onTermination = { @Sendable _ in expectation.fulfill() }

        // When
        sut.showPasswordDialog()
        sut.createBackup(password: "pw")
        continuation.yield(.progress(1, 2))
        wait(forConditionToBeTrue: sut.backupProgress == .ongoing(current: 1, total: 2), timeout: 3)
        sut.cancel()

        // Then
        wait(for: [expectation], timeout: 3)
    }

    func testErrorPresentsAlert() {
        // Given
        var continuation: AsyncThrowingStream<CreateBackupProgress, any Error>.Continuation!
        mockCreateBackupUseCase.invokePasswordStringAsyncThrowingStreamCreateBackupProgressAnyErrorReturnValue = .init {
            continuation = $0
        }
        let sut = sut as ExportBackupViewModel

        // When
        sut.showPasswordDialog()
        sut.createBackup(password: "pw")
        continuation.yield(.progress(1, 2))
        wait(forConditionToBeTrue: sut.backupProgress == .ongoing(current: 1, total: 2), timeout: 3)
        continuation.finish(throwing: NSError(domain: "ExportBackupViewModelTests", code: 987))

        // Then
        wait(forConditionToBeTrue: sut.isErrorAlertPresented, timeout: 3)
    }

}
