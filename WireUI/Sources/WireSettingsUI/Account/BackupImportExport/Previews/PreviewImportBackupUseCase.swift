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

import Foundation
import WireDomainPkg

struct PreviewImportBackupUseCase: ImportBackupUseCaseProtocol {

    func invoke(url: URL, password: String) -> AsyncThrowingStream<ImportBackupProgress, any Error> {
        AsyncThrowingStream { continuation in
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
                            throw ImportBackupError.allCases.randomElement()!
                        }

                        continuation.yield(.progress(Float(i) / Float(steps)))

                        try await Task.sleep(for: .milliseconds(.random(in: 50 ... 300)))
                    }

                    continuation.yield(.done)
                    continuation.finish()

                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

}
