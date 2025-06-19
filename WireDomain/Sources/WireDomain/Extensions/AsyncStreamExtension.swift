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

extension AsyncThrowingStream {
    func collect(
        maxCount: Int,
        timeout: TimeInterval
    ) -> AsyncThrowingStream<[Element], Error> {
        AsyncThrowingStream<[Element], Error> { continuation in
            Task {
                var iterator = self.makeAsyncIterator()

                do {
                    while let first = try await iterator.next() {
                        var batch: [Element] = [first]
                        let deadline = ContinuousClock.now.advanced(by: .seconds(timeout))

                        while batch.count < maxCount {
                            let now = ContinuousClock.now
                            let remaining = now.duration(to: deadline)
                            if remaining <= .zero {
                                break
                            }

                            let next = try await withThrowingTaskGroup(of: Element?.self) { group in
                                group.addTask {
                                    try await iterator.next()
                                }

                                group.addTask {
                                    try await Task.sleep(nanoseconds: UInt64(remaining.components.seconds * 1_000_000_000))
                                    return nil
                                }

                                let result = try await group.next()
                                group.cancelAll()
                                return result
                            }

                            guard let element = next else {
                                break // timeout
                            }
                            if element != nil {
                                batch.append(element!)
                            }

                        }

                        continuation.yield(batch)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
