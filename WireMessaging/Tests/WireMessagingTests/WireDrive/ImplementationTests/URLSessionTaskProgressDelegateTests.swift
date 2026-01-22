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
import os
import Testing

@testable import WireMessagingData

struct URLSessionTaskProgressDelegateTests {

    private var progresses = OSAllocatedUnfairLock<[Double]>(initialState: [])

    @Test
    func testURLSessionDidCreateTask() {
        // given
        let sut = URLSessionTaskProgressDelegate { [progresses] progress in
            progresses.withLock { $0.append(progress) }
        }
        let session = URLSession.shared
        let urlSessionTask = session.downloadTask(with: URL(string: "https://example.com")!)
        urlSessionTask.progress.totalUnitCount = 100

        // when
        sut.urlSession(URLSession.shared, didCreateTask: urlSessionTask)

        urlSessionTask.progress.completedUnitCount = 20
        urlSessionTask.progress.completedUnitCount = 50
        urlSessionTask.progress.completedUnitCount = 100

        // then
        #expect(progresses.withLock { $0 } == [0.0, 0.2, 0.5, 1.0])
    }

}
