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

import XCTest
@testable import WireDomain

final class PushChannelStateTests: XCTestCase {

    var sut: PushChannelState!
    var fileURL: URL!

    override func setUpWithError() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let clientID = UUID().uuidString
        fileURL = tempDir.appendingPathComponent(clientID)
        sut = PushChannelState(sharedContainerURL: tempDir, clientID: clientID)
    }

    override func tearDown() async throws {
        await sut.markAsClosed()
        sut = nil
        try FileManager.default.removeItem(at: fileURL)
        fileURL = nil
    }

    func test_markAsClosed() async throws {

        await sut.markAsClosed()

        try await sut.markAsOpen()
    }

    func test_markAsOpen_throwsWhenAlreadyOpened() async throws {
        try await sut.markAsOpen()

        await XCTAssertThrowsErrorAsync(PushChannelState.Failure.alreadyLocked(sameProcess: true)) {
            try await self.sut.markAsOpen()
        }

    }
}
