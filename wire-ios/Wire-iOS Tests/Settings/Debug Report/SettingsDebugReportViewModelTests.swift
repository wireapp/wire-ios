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

class SettingsDebugReportViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: SettingsDebugReportViewModel!
    private var mockRouter: MockSettingsDebugReportRouterProtocol!
    private var mockShareFile: MockShareFileUseCaseProtocol!
    private var mockFetchShareableConversations: MockFetchShareableConversationsUseCaseProtocol!
    private var mockLogsProvider: MockLogFilesProviding!
    private var mockFileMetaDataGenerator: MockFileMetaDataGenerating!

    private var coreDataStackHelper: CoreDataStackHelper!
    private var coreDataStack: CoreDataStack!

    // MARK: - setUp

    override func setUp() async throws {
        try await super.setUp()

        mockRouter = MockSettingsDebugReportRouterProtocol()
        mockShareFile = MockShareFileUseCaseProtocol()
        mockFetchShareableConversations = MockFetchShareableConversationsUseCaseProtocol()
        mockLogsProvider = MockLogFilesProviding()
        mockFileMetaDataGenerator = MockFileMetaDataGenerating()

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
        super.tearDown()
    }

    // MARK: - Tests

    func testShareReport() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: coreDataStack.viewContext)
        let mockURL = URL(fileURLWithPath: "mockURL")
        let mockMetadata = ZMFileMetadata(fileURL: mockURL)
        let mockDebugReport = ShareableDebugReport(
            logFileMetadata: mockMetadata,
            shareFile: mockShareFile
        )

        // Set mock methods
        mockFetchShareableConversations.invoke_MockValue = [conversation]
        mockLogsProvider.generateLogFilesZip_MockValue = mockURL
        mockLogsProvider.clearLogsDirectory_MockMethod = {}
        mockFileMetaDataGenerator.metadataForFileAtURLUTINameCompletion_MockMethod = { url, uti, name, completion in

            XCTAssertEqual(url, mockURL)
            XCTAssertEqual(uti, mockURL.UTI())
            XCTAssertEqual(name, mockURL.lastPathComponent)

            completion(mockMetadata)
        }
        mockRouter.presentShareViewControllerDestinationsDebugReport_MockMethod = { destinations, debugReport in

            XCTAssertEqual(destinations.count, 1)
            XCTAssertEqual(destinations.first, conversation)
            XCTAssertEqual(debugReport, mockDebugReport)

        }

        // WHEN
        sut.shareReport()

        // THEN
        XCTAssertEqual(mockFetchShareableConversations.invoke_Invocations.count, 1)
        XCTAssertEqual(mockLogsProvider.generateLogFilesZip_Invocations.count, 1)
        XCTAssertEqual(mockFileMetaDataGenerator.metadataForFileAtURLUTINameCompletion_Invocations.count, 1)
        XCTAssertEqual(mockRouter.presentShareViewControllerDestinationsDebugReport_Invocations.count, 1)
    }

}
