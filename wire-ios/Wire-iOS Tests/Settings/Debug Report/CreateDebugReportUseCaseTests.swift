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
import XCTest

@testable import Wire

final class CreateDebugReportUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var sut: CreateDebugReportUseCase!
    private var mockLogsProvider: MockLogFilesProviding!
    private var tempDirectory: URL!

    // MARK: - setUp / tearDown

    override func setUp() async throws {
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        mockLogsProvider = MockLogFilesProviding()
        mockLogsProvider.infoSelfUserID_MockValue = "mock info"
    }

    override func tearDown() async throws {
        sut = nil
        mockLogsProvider = nil
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    // MARK: - Tests

    func test_invoke_throwsNoLogsError_whenNoLogFilesExist() async {
        // GIVEN
        mockLogsProvider.logFileURLs = []
        sut = CreateDebugReportUseCase(logsProvider: mockLogsProvider, selfUserID: nil)

        // WHEN / THEN
        do {
            _ = try await sut.invoke()
            XCTFail("Expected noLogs error to be thrown")
        } catch CreateDebugReportUseCase.UseCaseError.noLogs {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_invoke_returnsZipURL_whenLogsExist() async throws {
        // GIVEN
        let logFile = try makeTempLogFile(named: "app.log", content: "log content")
        mockLogsProvider.logFileURLs = [logFile]
        sut = CreateDebugReportUseCase(logsProvider: mockLogsProvider, selfUserID: nil)

        // WHEN
        let result = try await sut.invoke()

        // THEN
        XCTAssertEqual(result.pathExtension, "zip")
    }

    func test_invoke_createsZipFileOnDisk() async throws {
        // GIVEN
        let logFile = try makeTempLogFile(named: "app.log", content: "log content")
        mockLogsProvider.logFileURLs = [logFile]
        sut = CreateDebugReportUseCase(logsProvider: mockLogsProvider, selfUserID: nil)

        // WHEN
        let result = try await sut.invoke()

        // THEN
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
        let attributes = try FileManager.default.attributesOfItem(atPath: result.path)
        let fileSize = attributes[.size] as? Int ?? 0
        XCTAssertGreaterThan(fileSize, 0)
    }

    func test_invoke_passesCorrectSelfUserIDToInfoProvider() async throws {
        // GIVEN
        let userID = UUID()
        let logFile = try makeTempLogFile(named: "app.log", content: "content")
        mockLogsProvider.logFileURLs = [logFile]
        sut = CreateDebugReportUseCase(logsProvider: mockLogsProvider, selfUserID: userID)

        // WHEN
        _ = try await sut.invoke()

        // THEN
        XCTAssertEqual(mockLogsProvider.infoSelfUserID_Invocations.count, 1)
        XCTAssertEqual(mockLogsProvider.infoSelfUserID_Invocations[0], userID)
    }

    func test_invoke_passesNilSelfUserIDToInfoProvider_whenNoUserID() async throws {
        // GIVEN
        let logFile = try makeTempLogFile(named: "app.log", content: "content")
        mockLogsProvider.logFileURLs = [logFile]
        sut = CreateDebugReportUseCase(logsProvider: mockLogsProvider, selfUserID: nil)

        // WHEN
        _ = try await sut.invoke()

        // THEN
        XCTAssertEqual(mockLogsProvider.infoSelfUserID_Invocations.count, 1)
        XCTAssertNil(mockLogsProvider.infoSelfUserID_Invocations[0])
    }

    func test_invoke_handlesMultipleLogFiles() async throws {
        // GIVEN
        let logFile1 = try makeTempLogFile(named: "app1.log", content: "first log")
        let logFile2 = try makeTempLogFile(named: "app2.log", content: "second log")
        mockLogsProvider.logFileURLs = [logFile1, logFile2]
        sut = CreateDebugReportUseCase(logsProvider: mockLogsProvider, selfUserID: nil)

        // WHEN
        let result = try await sut.invoke()

        // THEN
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.path))
    }

    // MARK: - Helpers

    private func makeTempLogFile(named name: String, content: String) throws -> URL {
        let url = tempDirectory.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
