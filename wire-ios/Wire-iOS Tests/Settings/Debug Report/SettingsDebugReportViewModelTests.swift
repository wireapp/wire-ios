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

import WireDataModelSupport
import WireSyncEngineSupport
import XCTest

@testable import Wire

final class SettingsDebugReportViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: SettingsDebugReportViewModel!
    private var mockRouter: MockSettingsDebugReportRouterProtocol!
    private var mockShareFile: MockShareFileUseCaseProtocol!
    private var mockFetchShareableConversations: MockFetchShareableConversationsUseCaseProtocol!
    private var mockLogsProvider: MockLogFilesProviding!
    private var mockFileMetaDataGenerator: MockFileMetaDataGeneratorProtocol!

    private var coreDataStackHelper: CoreDataStackHelper!
    private var coreDataStack: CoreDataStack!

    // MARK: - setUp

    override func setUp() async throws {

        mockRouter = MockSettingsDebugReportRouterProtocol()
        mockShareFile = MockShareFileUseCaseProtocol()
        mockFetchShareableConversations = MockFetchShareableConversationsUseCaseProtocol()
        mockLogsProvider = MockLogFilesProviding()
        mockFileMetaDataGenerator = .init()

        sut = SettingsDebugReportViewModel(
            router: mockRouter,
            shareFile: mockShareFile,
            fetchShareableConversations: mockFetchShareableConversations,
            logsProvider: mockLogsProvider,
            fileMetaDataGenerator: mockFileMetaDataGenerator
        )

        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockRouter = nil
        mockShareFile = nil
        mockFetchShareableConversations = nil
        mockLogsProvider = nil
        mockFileMetaDataGenerator = nil
        coreDataStack = nil
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testShareReport() async {

        // GIVEN
        let conversation = await coreDataStack.viewContext.perform { [self] in
            ZMConversation.insertNewObject(in: coreDataStack.viewContext)
        }
        let mockURL = URL(fileURLWithPath: "mockURL")
        let mockMetadata = await coreDataStack.viewContext.perform {
            ZMFileMetadata(fileURL: mockURL)
        }
        let mockDebugReport = ShareableDebugReport(
            logFileMetadata: mockMetadata,
            shareFile: mockShareFile
        )

        // Set mock methods
        mockFetchShareableConversations.invoke_MockValue = [conversation]
        mockLogsProvider.generateLogFilesZip_MockValue = mockURL
        mockLogsProvider.clearLogsDirectory_MockMethod = {}
        mockFileMetaDataGenerator.metadataForFileAt_MockMethod = { url in
            XCTAssertEqual(url, mockURL)
            return mockMetadata
        }
        mockRouter.presentShareViewControllerDestinationsDebugReport_MockMethod = { destinations, debugReport in
            XCTAssertEqual(destinations.count, 1)
            XCTAssertEqual(destinations.first, conversation)
            XCTAssertEqual(debugReport, mockDebugReport)
        }

        // WHEN
        await sut.shareReport()

        // THEN
        XCTAssertEqual(mockFetchShareableConversations.invoke_Invocations.count, 1)
        XCTAssertEqual(mockLogsProvider.generateLogFilesZip_Invocations.count, 1)
        XCTAssertEqual(mockFileMetaDataGenerator.metadataForFileAt_Invocations.count, 1)
        XCTAssertEqual(mockRouter.presentShareViewControllerDestinationsDebugReport_Invocations.count, 1)
    }
}
