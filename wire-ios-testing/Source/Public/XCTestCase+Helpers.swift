//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension XCTestCase {
    
    public func waitForGroupsToBeEmpty(_ groups: [DispatchGroup], timeout: TimeInterval = 5) -> Bool {
        
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        var groupCounter = groups.count
        
        groups.forEach { (group) in
            group.notify(queue: DispatchQueue.main, execute: {
                groupCounter -= 1
            })
        }
        
        while (groupCounter > 0 && timeoutDate.timeIntervalSinceNow > 0) {
            if !RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.002)) {
                Thread.sleep(forTimeInterval: 0.002)
            }
        }
        
        return groupCounter == 0
    }


    public func createTempFolder() -> URL {
        let url = URL(fileURLWithPath: [NSTemporaryDirectory(), UUID().uuidString].joined(separator: "/"))
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
        return url
    }

    public typealias AsyncThrowingBlock = () async throws -> Void
    public typealias ThrowingBlock = () throws -> Void
    public typealias EquatableError = Error & Equatable

    public func assertItThrows<T: EquatableError>(error expectedError: T, block: AsyncThrowingBlock) async {
        do {
            try await block()
            XCTFail("No error was thrown")
        } catch {
            assertError(error, equals: expectedError)
        }
    }

    public func assertItThrows<T: EquatableError>(error expectedError: T, block: ThrowingBlock) {
        XCTAssertThrowsError(try block()) { error in
            assertError(error, equals: expectedError)
        }
    }

    public func assertError<T: EquatableError>(_ error: Error, equals expectedError: T) {
        guard let error = error as? T else {
            return XCTFail("Unexpected error: \(String(describing: error))")
        }

        XCTAssertEqual(error, expectedError)
    }
}
