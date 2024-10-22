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

    private var analyticsEventTracker: MockAnalyticsEventTracker!
    private var mockConversation: MockMessageAppendableConversation!
    private var sut: AppendFileMessageUseCase!

    // MARK: - setUp

    override func setUp() {
        analyticsEventTracker = .init()
        mockConversation = .init()
        sut = AppendFileMessageUseCase(analyticsEventTracker: analyticsEventTracker)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockConversation = nil
        analyticsEventTracker = nil
    }

    func testInvoke_AppendsFileToGroupConversation_TracksEventCorrectly() throws {
        // GIVEN
        mockConversation.conversationType = .group
        mockConversation.localParticipants = []
        mockConversation.appendFile_MockMethod = { _, _ in
            MockZMConversationMessage()
        }
        analyticsEventTracker.trackEvent_MockMethod = { _ in }

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

        let expectedEvent = AnalyticsEvent.conversationContribution(
            .fileMessage,
            conversationType: .group,
            conversationSize: 0
        )

        XCTAssertEqual(
            analyticsEventTracker.trackEvent_Invocations,
            [expectedEvent]
        )
    }
}
