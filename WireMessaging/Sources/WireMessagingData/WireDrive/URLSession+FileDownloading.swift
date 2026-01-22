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
public import WireMessagingDomain

extension URLSession: FileDownloading {

    func download(from url: URL) -> (progress: AsyncStream<Double>, download: Task<(URL, URLResponse), any Error>) {
        let (progressStream, progressContinuation) = AsyncStream.makeStream(of: Double.self)

        let delegate = URLSessionTaskProgressDelegate { fractionCompleted in
            progressContinuation.yield(fractionCompleted)
        }

        let downloadTask = Task {
            let result = try await download(from: url, delegate: delegate)
            progressContinuation.finish()
            return result
        }

        return (progress: progressStream, download: downloadTask)
    }

}
