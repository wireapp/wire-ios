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

import Combine
import Foundation

final class URLSessionTaskProgressDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {

    private let progress: @Sendable (Double) -> Void
    private var cancellables: Set<AnyCancellable> = []

    init(progress: @Sendable @escaping (Double) -> Void) {
        self.progress = progress
    }

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        task.progress.publisher(for: \.fractionCompleted)
            .sink { [progress] in progress($0) }
            .store(in: &cancellables)
    }

}

extension URLSession: FileDownloading {

    func download(from url: URL) -> (progress: AsyncStream<Double>, getResult: () async throws -> (URL, URLResponse)) {
        let (progressStream, progressContinuation) = AsyncStream.makeStream(of: Double.self)

        let delegate = URLSessionTaskProgressDelegate { fractionCompleted in
            progressContinuation.yield(fractionCompleted)
        }

        let downloadTask = Task {
            let result = try await download(from: url, delegate: delegate)
            progressContinuation.finish()
            return result
        }

        return (
            progress: progressStream,
            getResult: { try await downloadTask.value }
        )
    }

}
