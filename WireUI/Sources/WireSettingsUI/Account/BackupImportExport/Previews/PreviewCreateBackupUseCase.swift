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
import WireFoundation

struct PreviewCreateBackupUseCase: CreateBackupUseCaseProtocol {

    func invoke(password: String) -> AsyncThrowingStream<CreateBackupProgress, any Error> {
        let (stream, continuation) = AsyncThrowingStream<CreateBackupProgress, any Error>
            .makeStream(bufferingPolicy: .unbounded)

        let task = Task<Void, Never>.detached {
            do {
                let steps = 10

                var failAtIndex: Int?
                if .random() {
                    failAtIndex = .random(in: 0 ... steps)
                }

                for i in 0 ... steps {

                    try Task.checkCancellation()

                    if i == failAtIndex {
                        throw PreviewExportBackupError()
                    }

                    continuation.yield(.progress(i, steps))

                    try await Task.sleep(for: .milliseconds(.random(in: 50 ... 300)))
                }

                let fileURL = URL(fileURLWithPath: "/path/to/final/backup.zip")
                continuation.yield(.done(fileURL))
                continuation.finish()

            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in
            task.cancel()
        }

        return stream
    }

    struct PreviewExportBackupError: Error {}

}
