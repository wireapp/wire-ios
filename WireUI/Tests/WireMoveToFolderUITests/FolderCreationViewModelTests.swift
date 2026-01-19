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

import WireMoveToFolderUISupport
import XCTest

@testable import WireMoveToFolderUI

final class FolderCreationViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: CreateFolderViewModel!
    private var mockUseCase: MockCreateConversationFolderUseCase!

    // MARK: - setUp

    override func setUp() {
        mockUseCase = MockCreateConversationFolderUseCase()
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockUseCase = nil
    }

    // MARK: - Creation State

    @MainActor
    func test_init_canCreateIsFalse() {
        // GIVEN & WHEN
        createSUT()

        // THEN
        XCTAssertFalse(sut.canCreate)
    }

    @MainActor
    func test_setEmptyName_canCreateIsFalse() {
        // GIVEN
        createSUT()

        // WHEN
        sut.name = ""

        // THEN
        XCTAssertFalse(sut.canCreate)
    }

    @MainActor
    func test_setWhitespaceName_canCreateIsFalse() {
        // GIVEN
        createSUT()

        // WHEN
        sut.name = "   "

        // THEN
        XCTAssertFalse(sut.canCreate)
    }

    @MainActor
    func test_setValidName_canCreateIsTrue() {
        // GIVEN
        createSUT()

        // WHEN
        sut.name = "Work"

        // THEN
        XCTAssertTrue(sut.canCreate)
    }

    // MARK: - Folder Creation

    @MainActor
    func test_createFolder_withEmptyName_throwsError() async {
        // GIVEN
        createSUT()
        sut.name = ""

        // WHEN & THEN
        do {
            _ = try await sut.createFolder()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? FolderCreationError, .emptyName)
        }
    }

    @MainActor
    func test_createFolder_withWhitespaceName_throwsError() async {
        // GIVEN
        createSUT()
        sut.name = "   "

        // WHEN & THEN
        do {
            _ = try await sut.createFolder()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? FolderCreationError, .emptyName)
        }
    }

    @MainActor
    func test_createFolder_withValidName_callsUseCase() async throws {
        // GIVEN
        createSUT()
        sut.name = "Work"
        let expectedFolder = Folder(identifier: UUID(), name: "Work")
        mockUseCase.invokeName_MockMethod = { (_: String) in expectedFolder }

        // WHEN
        let folder = try await sut.createFolder()

        // THEN
        XCTAssertEqual(mockUseCase.invokeName_Invocations.count, 1)
        XCTAssertEqual(mockUseCase.invokeName_Invocations.first, "Work")
        XCTAssertEqual(folder, expectedFolder)
    }

    @MainActor
    func test_createFolder_whenUseCaseThrows_propagatesError() async {
        // GIVEN
        createSUT()
        sut.name = "Work"
        struct TestError: Error {}
        let expectedError = TestError()
        mockUseCase.invokeName_MockError = expectedError

        // WHEN & THEN
        do {
            _ = try await sut.createFolder()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(mockUseCase.invokeName_Invocations.count, 1)
            XCTAssertEqual(mockUseCase.invokeName_Invocations.first, "Work")
        }
    }

    // MARK: - Helpers

    @MainActor
    private func createSUT() {
        sut = CreateFolderViewModel(useCase: mockUseCase)
    }
}
