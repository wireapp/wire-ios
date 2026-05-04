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
    private var mockShareReport: MockShareDebugReportUseCaseProtocol!
    private var viewController: UIViewController!

    // MARK: - setUp

    override func setUp() async throws {
        mockCreateReport = MockCreateDebugReportUseCaseProtocol()
        mockShareReport = MockShareDebugReportUseCaseProtocol()
        sut = ShareDebugReportViewModel(createReport: mockCreateReport, shareReport: mockShareReport)
        viewController = UIViewController()
        viewController.view.frame = UIScreen.main.bounds
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockCreateReport = nil
        mockShareReport = nil
        viewController = nil
    }

    // MARK: - Tests

    func testShareCallsCreateThenShare() async throws {
        // GIVEN
        let expectedURL = URL(fileURLWithPath: "/tmp/logs.zip")
        mockCreateReport.invokeReturnValue = expectedURL
        mockShareReport.invokeCalled = false

        // WHEN
        await sut.share(from: viewController)

        // THEN
        XCTAssertTrue(mockCreateReport.invokeCallsCount == 1)
        XCTAssertEqual(mockShareReport.invokeLogFileURLFromCallsCount, 1)
        XCTAssertEqual(mockShareReport.invokeLogFileURLFromReceivedArguments?.logFileURL, expectedURL)
    }

    func testShareDoesNotCallShareOnCreateFailure() async throws {
        // GIVEN
        mockCreateReport.invokeThrowableError = NSError(domain: "test", code: 42)

        // WHEN
        await sut.share(from: viewController)

        // THEN
        XCTAssertTrue(mockCreateReport.invokeCallsCount == 1)
        XCTAssertEqual(mockShareReport.invokeLogFileURLFromCallsCount, 0)
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

@MainActor
final class MockShareDebugReportUseCaseProtocol: ShareDebugReportUseCaseProtocol {

    var invokeLogFileURLFromCallsCount = 0
    var invokeCalled = false
    var invokeLogFileURLFromReceivedArguments: (logFileURL: URL, viewController: UIViewController)?

    func invoke(logFileURL: URL, from viewController: UIViewController) async {
        invokeCalled = true
        invokeLogFileURLFromCallsCount += 1
        invokeLogFileURLFromReceivedArguments = (logFileURL: logFileURL, viewController: viewController)
    }
}
