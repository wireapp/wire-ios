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

import Smithy
import Foundation

/// Wraps a `Smithy.Stream` allowing its progress to be observed. This is a workaround to enable reading upload progress
/// using the AWS SDK.

final class ObservableStream: Smithy.Stream, Sendable {

    private let wrapped: any Smithy.Stream
    private let readContinuation: AsyncStream<Int>.Continuation

    let readProgress: AsyncStream<Int>

    init(
        _ wrapped: any Smithy.Stream,
        bufferingPolicy: AsyncStream<Int>.Continuation.BufferingPolicy = .bufferingNewest(1)
    ) {
        let (progress, continuation) = AsyncStream.makeStream(of: Int.self, bufferingPolicy: bufferingPolicy)
        self.wrapped = wrapped
        self.readProgress = progress
        self.readContinuation = continuation
    }

    // MARK: - ReadableStream

    var position: Data.Index {
        wrapped.position
    }

    var length: Int? {
        wrapped.length
    }

    var isEmpty: Bool {
        wrapped.isEmpty
    }

    var isSeekable: Bool {
        wrapped.isSeekable
    }

    func read(upToCount count: Int) throws -> Data? {
        let result = try wrapped.read(upToCount: count)
        readContinuation.yield(position)
        return result
    }
    
    func readAsync(upToCount count: Int) async throws -> Data? {
        let result = try await wrapped.readAsync(upToCount: count)
        readContinuation.yield(position)
        return result
    }
    
    func readToEnd() throws -> Data? {
        let result = try wrapped.readToEnd()
        readContinuation.yield(position)
        return result
    }
    
    func readToEndAsync() async throws -> Data? {
        let result = try await wrapped.readToEndAsync()
        readContinuation.yield(position)
        return result
    }

    // MARK: - WriteableStream

    func write(contentsOf data: Data) throws {
        try wrapped.write(contentsOf: data)
    }
    
    func close() {
        wrapped.close()
    }
    
    func closeWithError(_ error: any Error) {
        wrapped.closeWithError(error)
    }
}
