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

import WireAnalytics
import WireDataModel
import WireDataModelSupport
import WireFoundation
import WireFoundationSupport
import WireSyncEngineSupport
import XCTest

@testable import WireSyncEngine

final class AppendImageMessageUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var analyticsEventTracker: AnalyticsEventTrackerProtocolMock!
    private var mockConversation: MockMessageAppendableConversation!
    private var sut: AppendImageMessageUseCase!

    // MARK: - setUp

    override func setUp() {
        analyticsEventTracker = .init()
        mockConversation = .init()
        sut = AppendImageMessageUseCase(analyticsEventTracker: analyticsEventTracker)
    }

    // MARK: - tearDown

    override func tearDown() {
        sut = nil
        mockConversation = nil
        analyticsEventTracker = nil
    }

    // MARK: - Unit Tests

    func testInvoke_AppendImageContent_TracksEventCorrectly() throws {
        // GIVEN
        mockConversation.conversationType = .group
        mockConversation.localParticipants = []
        mockConversation.appendImage_MockMethod = { _, _ in
            MockZMConversationMessage()
        }
        analyticsEventTracker.trackEventEventAnalyticsEventVoidClosure = { _ in }

        let testImageData = Data("test image data".utf8)
        let image = SendableImage(name: "picture.jpg", utType: .jpeg, data: testImageData)

        // WHEN
        try sut.invoke(image: image, in: mockConversation)

        // THEN
        XCTAssertEqual(mockConversation.appendImage_Invocations.count, 1)
        let appendImageInvocation = try XCTUnwrap(mockConversation.appendImage_Invocations.first)
        XCTAssertEqual(appendImageInvocation.image.data, testImageData)
        XCTAssertNotNil(appendImageInvocation.nonce)

        let expectedEvent = AnalyticsEvent.Contributed.conversationContribution(
            .imageMessage,
            conversationType: .group,
            conversationSize: 0
        )

        XCTAssertEqual(
            analyticsEventTracker.trackEventEventAnalyticsEventVoidReceivedInvocations,
            [expectedEvent]
        )
    }
}
