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

    func testShareViaActivitySheet_invokesCreateReport() async {
        // GIVEN
        mockCreateReport.invokeReturnValue = URL(fileURLWithPath: "/tmp/logs.zip")
        let output = MockShareDebugReportViewModelOutput()
        sut.output = output

        // WHEN
        await sut.shareViaActivitySheet()

        // THEN
        XCTAssertEqual(mockCreateReport.invokeCallsCount, 1)
        XCTAssertEqual(output.presentActivityReportAtURLs, [URL(fileURLWithPath: "/tmp/logs.zip")])
        XCTAssertEqual(output.didStartCreatingReportCallsCount, 1)
        XCTAssertEqual(output.didFinishCreatingReportCallsCount, 1)
    }

    func testSendEmail_invokesCreateReportData() async {
        // GIVEN
        mockCreateReport.invokeDataReturnValue = Data([1, 2, 3])
        let output = MockShareDebugReportViewModelOutput()
        sut.output = output

        // WHEN
        await sut.sendEmail()

        // THEN
        XCTAssertEqual(mockCreateReport.invokeDataCallsCount, 1)
        XCTAssertEqual(sut.mailComposeItem?.attachmentData, Data([1, 2, 3]))
        XCTAssertEqual(output.didStartCreatingReportCallsCount, 1)
        XCTAssertEqual(output.didFinishCreatingReportCallsCount, 1)
    }
}

// MARK: - Mocks

final class MockCreateDebugReportUseCaseProtocol: CreateDebugReportUseCaseProtocol {

    var invokeCallsCount = 0
    var invokeReturnValue: URL!
    var invokeThrowableError: Error?
    var invokeDataCallsCount = 0
    var invokeDataReturnValue: Data!
    var invokeDataThrowableError: Error?

    func invoke() async throws -> URL {
        invokeCallsCount += 1
        if let error = invokeThrowableError { throw error }
        return invokeReturnValue
    }

    func invokeData() async throws -> Data {
        invokeDataCallsCount += 1
        if let error = invokeDataThrowableError { throw error }
        return invokeDataReturnValue
    }
}

final class MockShareDebugReportViewModelOutput: ShareDebugReportViewModelOutput {

    var didStartCreatingReportCallsCount = 0
    var didFinishCreatingReportCallsCount = 0
    var presentWireReportAtURLs = [URL]()
    var presentActivityReportAtURLs = [URL]()

    func shareDebugReportViewModelDidStartCreatingReport(_ viewModel: ShareDebugReportViewModel) {
        didStartCreatingReportCallsCount += 1
    }

    func shareDebugReportViewModelDidFinishCreatingReport(_ viewModel: ShareDebugReportViewModel) {
        didFinishCreatingReportCallsCount += 1
    }

    func shareDebugReportViewModel(_ viewModel: ShareDebugReportViewModel, presentWireReportAt url: URL) async {
        presentWireReportAtURLs.append(url)
    }

    func shareDebugReportViewModel(_ viewModel: ShareDebugReportViewModel, presentActivityReportAt url: URL) async {
        presentActivityReportAtURLs.append(url)
    }
}
