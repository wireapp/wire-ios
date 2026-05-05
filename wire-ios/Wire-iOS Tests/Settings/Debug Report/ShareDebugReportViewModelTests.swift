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

@testable import Wire

@MainActor
final class ShareDebugReportViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: ShareDebugReportViewModel!
    private var mockCreateReport: MockCreateDebugReportUseCaseProtocol!

    // MARK: - setUp

    override func setUp() async throws {
        mockCreateReport = MockCreateDebugReportUseCaseProtocol()
        sut = ShareDebugReportViewModel(
            userSession: nil,
            mainCoordinator: nil,
            createReport: mockCreateReport
        )
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockCreateReport = nil
    }

    // MARK: - Tests

    func testShowOptions_setsIsShowingOptionsTrue() {
        // WHEN
        sut.showOptions()

        // THEN
        XCTAssertTrue(sut.isShowingOptions)
    }

    func testShareViaActivitySheet_invokesCreateReport() async {
        // GIVEN
        mockCreateReport.invokeReturnValue = URL(fileURLWithPath: "/tmp/logs.zip")

        // WHEN
        await sut.shareViaActivitySheet()

        // THEN
        XCTAssertEqual(mockCreateReport.invokeCallsCount, 1)
    }

    func testShareViaActivitySheet_doesNotThrowOnCreateFailure() async {
        // GIVEN
        mockCreateReport.invokeThrowableError = NSError(domain: "test", code: 42)

        // WHEN — should not crash
        await sut.shareViaActivitySheet()

        // THEN
        XCTAssertEqual(mockCreateReport.invokeCallsCount, 1)
    }
}

// MARK: - Mocks

final class MockCreateDebugReportUseCaseProtocol: CreateDebugReportUseCaseProtocol {

    var invokeCallsCount = 0
    var invokeReturnValue: URL!
    var invokeThrowableError: Error?

    func invoke() async throws -> URL {
        invokeCallsCount += 1
        if let error = invokeThrowableError { throw error }
        return invokeReturnValue
    }
}
