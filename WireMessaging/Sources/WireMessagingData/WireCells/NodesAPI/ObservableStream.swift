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
import Smithy

/// Wraps a `Smithy.Stream` allowing its progress to be observed. This is a workaround to enable reading upload progress
/// using the AWS SDK.

final class ObservableStream: Smithy.Stream, Sendable {

    private let wrappedStream: any Smithy.Stream
    private let readContinuation: AsyncStream<Int>.Continuation

    let readProgress: AsyncStream<Int>

    init(
        _ wrapped: any Smithy.Stream,
        bufferingPolicy: AsyncStream<Int>.Continuation.BufferingPolicy = .bufferingNewest(1)
    ) {
        let (progress, continuation) = AsyncStream.makeStream(of: Int.self, bufferingPolicy: bufferingPolicy)
        self.wrappedStream = wrapped
        self.readProgress = progress
        self.readContinuation = continuation
    }

    // MARK: - ReadableStream

    var position: Data.Index {
        wrappedStream.position
    }

    var length: Int? {
        wrappedStream.length
    }

    var isEmpty: Bool {
        wrappedStream.isEmpty
    }

    var isSeekable: Bool {
        wrappedStream.isSeekable
    }

    func read(upToCount count: Int) throws -> Data? {
        let result = try wrappedStream.read(upToCount: count)
        readContinuation.yield(position)
        return result
    }

    func readAsync(upToCount count: Int) async throws -> Data? {
        let result = try await wrappedStream.readAsync(upToCount: count)
        readContinuation.yield(position)
        return result
    }

    func readToEnd() throws -> Data? {
        let result = try wrappedStream.readToEnd()
        readContinuation.yield(position)
        return result
    }

    func readToEndAsync() async throws -> Data? {
        let result = try await wrappedStream.readToEndAsync()
        readContinuation.yield(position)
        return result
    }

    func seek(toOffset offset: Int) throws {
        try wrappedStream.seek(toOffset: offset)
        readContinuation.yield(position)
    }

    // MARK: - WriteableStream

    func write(contentsOf data: Data) throws {
        try wrappedStream.write(contentsOf: data)
    }

    func close() {
        wrappedStream.close()
    }

    func closeWithError(_ error: any Error) {
        wrappedStream.closeWithError(error)
    }
}
