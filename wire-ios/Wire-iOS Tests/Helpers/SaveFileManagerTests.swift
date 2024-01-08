//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
@testable import Wire

final class SaveFileManagerTests: XCTestCase {

    func testWhenSaveFileIsCalledThenSystemSaveFilePresenterIsCalled() {
        let expectation = expectation(description: "System Save File presenter should be called")
        let mockSystemSaveFilePresenter = MockSystemFileSavePresenter()
        mockSystemSaveFilePresenter.presentSystemPromptToSaveIsCalled = { _, _ in
            expectation.fulfill()
        }
        let saveFileManager = SaveFileManager(
            systemFileSavePresenter: mockSystemSaveFilePresenter,
            logger: MockLogger()
        )
        saveFileManager.save(
            value: .random(length: 10),
            fileName: .random(length: 10),
            type: .random(length: 3)
        )
        wait(for: [expectation], timeout: 0.5)
    }

}
