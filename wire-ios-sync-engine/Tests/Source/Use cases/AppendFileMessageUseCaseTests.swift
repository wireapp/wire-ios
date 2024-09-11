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

import WireAnalytics
import WireAnalyticsSupport
import WireDataModel
import WireDataModelSupport
import WireSyncEngineSupport
import XCTest

@testable import WireSyncEngine

final class AppendFileMessageUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var mockAnalyticsSessionProtocol: MockAnalyticsSessionProtocol!
    private var mockConversation: MockMessageAppendableConversation!
    private var sut: AppendFileMessageUseCase!

    // MARK: - setUp

    override func setUp() {
        mockAnalyticsSessionProtocol = .init()
        mockConversation = .init()
        sut = AppendFileMessageUseCase(analyticsSession: mockAnalyticsSessionProtocol)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockConversation = nil
        mockAnalyticsSessionProtocol = nil
    }

    func testInvoke_AppendsFileToGroupConversation_TracksEventCorrectly() throws {
        // GIVEN
        mockConversation.conversationType = .group
        mockConversation.localParticipants = []
        mockConversation.appendFile_MockMethod = { _, _ in
            MockZMConversationMessage()
        }
        mockAnalyticsSessionProtocol.trackEvent_MockMethod = { _ in }

        let fileMetadata = ZMFileMetadata(fileURL: URL(fileURLWithPath: "/path/to/file.pdf"), thumbnail: nil)

        // WHEN
        try sut.invoke(
            with: fileMetadata,
            in: mockConversation
        )

        // THEN
        XCTAssertEqual(mockConversation.appendFile_Invocations.count, 1)
        let appendFileInvocation = try XCTUnwrap(mockConversation.appendFile_Invocations.first)
        XCTAssertEqual(appendFileInvocation.fileMetadata, fileMetadata)

        XCTAssertEqual(mockAnalyticsSessionProtocol.trackEvent_Invocations.count, 1)
        let trackEventInvocation = try XCTUnwrap(mockAnalyticsSessionProtocol.trackEvent_Invocations.first as? ConversationContributionAnalyticsEvent)
        XCTAssertEqual(trackEventInvocation.contributionType, .fileMessage)
        XCTAssertEqual(trackEventInvocation.conversationType, .group)
    }
}
