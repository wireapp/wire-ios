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

import Testing
import Foundation
import SmithyStreams

@testable import WireCellsImplementation

final class ObservableStreamTests {

    private let fileURL = URL.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).txt")
    private let fileHandle: FileHandle
    private let sut: ObservableStream

    init() throws{
        let data = "12345".data(using: .utf8)!
        try data.write(to: fileURL)

        self.fileHandle = try FileHandle(forReadingFrom: fileURL)
        self.sut = ObservableStream(FileStream(fileHandle: fileHandle), bufferingPolicy: .unbounded)
    }

    deinit {
        try? FileManager.default.removeItem(at: fileURL)
    }

    @Test func readUpToCount() async throws {
        // Given
        let progressesTask = Task { [sut] in
            var progresses: [Int] = []
            for await progress in sut.readProgress.prefix(3) {
                progresses.append(progress)
            }
            return progresses
        }

        // When
        _ = try sut.read(upToCount: 2)
        _ = try sut.read(upToCount: 2)
        _ = try sut.read(upToCount: 2)

        // Then
        #expect(await progressesTask.value == [2, 4, 5])
    }

    @Test func readAsyncUpToCount() async throws {
        // Given
        let progressesTask = Task { [sut] in
            var progresses: [Int] = []
            for await progress in sut.readProgress.prefix(3) {
                progresses.append(progress)
            }
            return progresses
        }

        // When
        _ = try await sut.readAsync(upToCount: 2)
        _ = try await sut.readAsync(upToCount: 2)
        _ = try await sut.readAsync(upToCount: 2)

        // Then
        #expect(await progressesTask.value == [2, 4, 5])
    }

    @Test func readToEnd() async throws {
        // Given
        let progressesTask = Task { [sut] in
            var progresses: [Int] = []
            for await progress in sut.readProgress.prefix(2) {
                progresses.append(progress)
            }
            return progresses
        }

        // When
        _ = try sut.read(upToCount: 2)
        _ = try sut.readToEnd()

        // Then
        #expect(await progressesTask.value == [2, 5])
    }

    @Test func readToEndAsync() async throws {
        // Given
        let progressesTask = Task { [sut] in
            var progresses: [Int] = []
            for await progress in sut.readProgress.prefix(2) {
                progresses.append(progress)
            }
            return progresses
        }

        // When
        _ = try await sut.readAsync(upToCount: 2)
        _ = try await sut.readToEndAsync()

        // Then
        #expect(await progressesTask.value == [2, 5])
    }
}
