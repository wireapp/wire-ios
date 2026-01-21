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

import Combine
import Foundation

final class URLSessionTaskProgressDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {

    private let progress: @Sendable (Double) -> Void
    private var cancellables: Set<AnyCancellable> = []

    init(progress: @Sendable @escaping (Double) -> Void) {
        self.progress = progress
    }

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        precondition(cancellables.isEmpty, "Delegate must not be reused across multiple tasks.")

        task.progress.publisher(for: \.fractionCompleted)
            .sink { [progress] in progress($0) }
            .store(in: &cancellables)
    }

}
