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
import SmithyStreams
import Testing

@testable import WireMessagingData

final class ObservableStreamTests {

    private let fileURL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    private let fileHandle: FileHandle
    private let sut: ObservableStream

    init() throws {
        let data = Data(repeating: 0, count: 5)
        try data.write(to: fileURL)

        self.fileHandle = try FileHandle(forReadingFrom: fileURL)
        self.sut = ObservableStream(FileStream(fileHandle: fileHandle), bufferingPolicy: .unbounded)
    }

    deinit {
        try? FileManager.default.removeItem(at: fileURL)
    }

    @Test
    func readUpToCount() async throws {
        // Given
        let progressesTask = makeObservationProgressTask(readingCount: 3)

        // When
        _ = try sut.read(upToCount: 2)
        _ = try sut.read(upToCount: 2)
        _ = try sut.read(upToCount: 2)

        // Then
        #expect(await progressesTask.value == [2, 4, 5])
    }

    @Test
    func readAsyncUpToCount() async throws {
        // Given
        let progressesTask = makeObservationProgressTask(readingCount: 3)

        // When
        _ = try await sut.readAsync(upToCount: 2)
        _ = try await sut.readAsync(upToCount: 2)
        _ = try await sut.readAsync(upToCount: 2)

        // Then
        #expect(await progressesTask.value == [2, 4, 5])
    }

    @Test
    func readToEnd() async throws {
        // Given
        let progressesTask = makeObservationProgressTask(readingCount: 2)

        // When
        _ = try sut.read(upToCount: 2)
        _ = try sut.readToEnd()

        // Then
        #expect(await progressesTask.value == [2, 5])
    }

    @Test
    func readToEndAsync() async throws {
        // Given
        let progressesTask = makeObservationProgressTask(readingCount: 2)

        // When
        _ = try await sut.readAsync(upToCount: 2)
        _ = try await sut.readToEndAsync()

        // Then
        #expect(await progressesTask.value == [2, 5])
    }

    @Test
    func seekToOffset() async throws {
        // Given
        let progressesTask = makeObservationProgressTask(readingCount: 2)

        // When
        try sut.seek(toOffset: 2)
        try sut.seek(toOffset: 5)

        // Then
        #expect(await progressesTask.value == [2, 5])
    }

    @Test
    func cancellation() async throws {
        // Given, When
        sut.cancel()

        // Then
        #expect(try sut.read(upToCount: 1) == nil)
        #expect(try await sut.readAsync(upToCount: 1) == nil)
        #expect(try sut.readToEnd() == nil)
        #expect(try await sut.readToEndAsync() == nil)
        #expect(throws: CancellationError.self) {
            try sut.seek(toOffset: 0)
        }
    }

    private func makeObservationProgressTask(readingCount: Int) -> Task<[Int], Never> {
        Task { [sut] in
            var progresses: [Int] = []
            for await progress in sut.readProgress.prefix(readingCount) {
                progresses.append(progress)
            }
            return progresses
        }
    }
}
