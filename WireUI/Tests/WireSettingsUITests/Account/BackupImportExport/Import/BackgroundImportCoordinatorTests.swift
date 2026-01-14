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
import Testing
import WireDomainPackage
import WireFoundation
import WireFoundationSupport
import WireLogging
import WireTestingPackage

@testable import WireSettingsUI
@testable import WireSettingsUISupport

@Suite("Background Import Coordinator", .serialized)
@MainActor
struct BackgroundImportCoordinatorTests {

    let mockFactory: ImportBackupUseCaseFactoryMock
    let mockUseCase: ImportBackupUseCaseProtocolMock
    let sut: BackgroundImportCoordinator
    let testURL: URL

    init() async throws {
        testURL = URL(fileURLWithPath: "/tmp/test-backup.zip")
        mockUseCase = .init()
        mockFactory = ImportBackupUseCaseFactoryMock(useCase: mockUseCase)
        sut = BackgroundImportCoordinator(
            importUseCaseFactory: mockFactory,
            logger: WireLogger(tag: "test")
        )
    }

    // MARK: - Progress Streaming Tests

    @Test("Yields progress from use case")
    func yieldsProgressFromUseCase() async throws {
        // Given
        let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
        mockUseCase.invokePasswordStringAsyncThrowingStreamImportBackupProgressAnyErrorReturnValue = stream

        // When
        let progressStream = sut.startImport(for: testURL, password: "password123")

        let task = Task {
            var receivedProgress: [ImportBackupProgress] = []
            for try await progress in progressStream {
                receivedProgress.append(progress)
                if receivedProgress.count == 2 {
                    break // Stop after receiving 2 progress updates
                }
            }
            return receivedProgress
        }

        // Yield progress from mock
        continuation.yield(.progress(1, 10))
        continuation.yield(.progress(5, 10))

        // Then
        let receivedProgress = try await task.value
        #expect(receivedProgress.count == 2)

        guard case .progress(let current, let total) = receivedProgress[0] else {
            Issue.record("Expected progress but got: \(receivedProgress[0])")
            return
        }
        #expect(current == 1)
        #expect(total == 10)
    }

    @Test("Finishes stream when done received")
    func finishesStreamWhenDoneReceived() async throws {
        // Given
        let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
        mockUseCase.invokePasswordStringAsyncThrowingStreamImportBackupProgressAnyErrorReturnValue = stream

        // When
        let progressStream = sut.startImport(for: testURL, password: "password123")

        continuation.yield(.progress(5, 10))
        continuation.yield(.done)

        // Then
        var receivedProgress: [ImportBackupProgress] = []
        var streamFinished = false

        for try await progress in progressStream {
            receivedProgress.append(progress)
            if case .done = progress {
                streamFinished = true
            }
        }

        #expect(receivedProgress.count == 2)
        #expect(streamFinished, "Stream should finish after .done")

        guard case .done = receivedProgress.last else {
            Issue.record("Last progress should be .done")
            return
        }
    }

    @Test("Passes password to use case")
    func passesPasswordToUseCase() async throws {
        // Given
        var capturedPassword: String?
        mockUseCase.invokePasswordStringAsyncThrowingStreamImportBackupProgressAnyErrorClosure = { password in
            capturedPassword = password
            let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
            continuation.yield(.done)
            return stream
        }

        // When
        let progressStream = sut.startImport(for: testURL, password: "password123")

        // Consume the stream to completion
        for try await _ in progressStream { }

        // Then
        #expect(capturedPassword == "password123")
    }

    // MARK: - Error Handling Tests

    @Test("Throws error when use case fails")
    func throwsErrorWhenUseCaseFails() async throws {
        // Given
        let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
        mockUseCase.invokePasswordStringAsyncThrowingStreamImportBackupProgressAnyErrorReturnValue = stream

        let expectedError = ImportBackupError.invalidFileExtension

        // When
        let progressStream = sut.startImport(for: testURL, password: "password123")

        continuation.finish(throwing: expectedError)

        // Then
        await #expect(throws: ImportBackupError.self) {
            for try await _ in progressStream {
                // Should throw before completing
            }
        }
    }

    @Test("Finishes stream gracefully on cancellation")
    func finishesStreamOnCancellation() async throws {
        // Given
        let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
        mockUseCase.invokePasswordStringAsyncThrowingStreamImportBackupProgressAnyErrorReturnValue = stream

        // When
        let progressStream = sut.startImport(for: testURL, password: "password123")

        let task = Task {
            var progressCount = 0
            for try await _ in progressStream {
                progressCount += 1
            }
            return progressCount
        }

        // Finish with CancellationError
        continuation.finish(throwing: CancellationError())

        // Then
        let result = await task.result
        // CancellationError should finish the stream gracefully without throwing
        switch result {
        case .success(let count):
            #expect(count == 0, "Should not have received any progress before cancellation")
        case .failure:
            Issue.record("CancellationError should finish stream gracefully, not propagate as failure")
        }
    }

    // MARK: - Cancellation Tests

    @Test("Cancel import cancels current task")
    func cancelImportCancelsCurrentTask() async throws {
        // Given
        let (stream, continuation) = AsyncThrowingStream<ImportBackupProgress, any Error>.makeStream()
        mockUseCase.invokePasswordStringAsyncThrowingStreamImportBackupProgressAnyErrorReturnValue = stream

        let progressStream = sut.startImport(for: testURL, password: "password123")

        var didReceiveProgress = false
        var streamEnded = false
        let task = Task {
            for try await _ in progressStream {
                didReceiveProgress = true
            }
            streamEnded = true
        }

        // Yield one progress update to ensure stream is active
        continuation.yield(.progress(1, 10))

        // When
        sut.cancelImport()

        // Wait for task to be cancelled
        _ = await task.result

        // Then
        #expect(didReceiveProgress, "Should have received at least one progress update")
        #expect(task.isCancelled || streamEnded, "Task should be cancelled or stream ended")
    }

}


