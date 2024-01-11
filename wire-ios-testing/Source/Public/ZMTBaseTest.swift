//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension ZMTBaseTest {
    @objc
    public static func checkForMemoryLeaksAfterTestClassCompletes() {
        if MemoryReferenceDebugger.aliveObjects.count > 0 {
            print("Leaked: \(MemoryReferenceDebugger.aliveObjectsDescription)")
            assert(false)
        }
    }

    public func wait(timeout: TimeInterval = 0.5,
                     file: StaticString = #filePath,
                     line: UInt = #line,
                     forAsyncBlock block: @escaping () async throws -> Void) {
        let expectation = self.customExpectation(description: "isDone")

        Task {
            do {
                try await block()
            } catch {
                XCTFail("test failed: \(String(describing: error))", file: file, line: line)
            }

            expectation.fulfill()
        }

        XCTAssert(waitForCustomExpectations(withTimeout: timeout), file: file, line: line)
    }

}
