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

import WireCommonComponents
import WireTestingPackage
import XCTest

@testable import Wire
import WireSyncEngineSupport

final class CallQualityControllerTests: XCTestCase, CoreDataFixtureTestHelper {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper!
    private var sut: MockCallQualityController!
    var coreDataFixture: CoreDataFixture!
    private var router: MockCallQualityRouterProtocol!
    private var conversation: ZMConversation!
    private var callConversationProvider: MockCallConversationProvider!
    private var callQualityViewController: CallQualityViewController!
    private var callQualitySurvey: MockSubmitCallQualitySurveyUseCaseProtocol!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        router = .init()
        coreDataFixture = CoreDataFixture()
        conversation = ZMConversation.createOtherUserConversation(
            moc: coreDataFixture.uiMOC,
            otherUser: otherUser
        )
        callConversationProvider = MockCallConversationProvider()
<<<<<<< HEAD
        sut = MockCallQualityController(mainWindow: .init())
=======

        callQualitySurvey = MockSubmitCallQualitySurveyUseCaseProtocol()
        callQualitySurvey.invoke_MockMethod = { _ in }

        // NOTE: the sut is not really a mock it's just the real implementation
        // but with canPresentCallQualitySurvey set to true for testing the callQualitySurvey
        sut = MockCallQualityController(rootViewController: .init(), callQualitySurvey: callQualitySurvey)
>>>>>>> aba5b2dca4 (feat: analytics milestone 1 - WPB-8911 (#1825))
        sut.router = router
        sut.usesCallSurveyBudget = false

        let questionLabelText = L10n.Localizable.Calling.QualitySurvey.question
        callQualityViewController = CallQualityViewController(questionLabelText: questionLabelText, callDuration: 10)
        callQualityViewController?.delegate = sut
<<<<<<< HEAD

        Analytics.shared = Analytics(optedOut: true)
=======
>>>>>>> aba5b2dca4 (feat: analytics milestone 1 - WPB-8911 (#1825))
    }

    // MARK: - teardown

    override func tearDown() {
        snapshotHelper = nil
        coreDataFixture = nil
        sut = nil
        router = nil
        conversation = nil
        callConversationProvider = nil
        callQualityViewController = nil
        callQualitySurvey = nil

        super.tearDown()
    }

    // MARK: - SurveyRequestValidation Tests

    func testSurveyRequestValidation() {
        sut.usesCallSurveyBudget = true

        // When the survey was never presented, it is possible to request it
        let initialDate = Date()
        CallQualityController.resetSurveyMuteFilter()
        XCTAssertTrue(sut.canRequestSurvey(at: initialDate))

        CallQualityController.updateLastSurveyDate(initialDate)

        // During the mute time interval, it is not possible to request it
        let mutedRequestDate = Date()
        XCTAssertFalse(sut.canRequestSurvey(at: mutedRequestDate))

        // After the mute time interval, it is not possible to request it
        let postMuteDate = mutedRequestDate.addingTimeInterval(2)
        XCTAssertTrue(sut.canRequestSurvey(at: postMuteDate, muteInterval: 1))

    }

    // MARK: - SnapshotTests

    func testSurveyInterface() {
        CallQualityController.resetSurveyMuteFilter()
        snapshotHelper.verify(matching: callQualityViewController.view)
    }

    // MARK: - CallQualitySurvey Presentation Tests
    func testThatCallQualitySurveyIsPresented_WhenCallStateIsTerminating_AndReasonIsNormal() {

        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .normal)
        conversation.remoteIdentifier = UUID()
        callConversationProvider.priorityCallConversation = conversation
        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)
        router.presentCallQualitySurveyWith_MockMethod = { _ in }

        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)

        // THEN
        XCTAssertFalse(router.presentCallQualitySurveyWith_Invocations.isEmpty)
    }

    func testThatCallQualitySurveyIsPresented_WhenCallStateIsTerminating_AndReasonIsStillOngoing() {

        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .stillOngoing)
        conversation.remoteIdentifier = UUID()
        callConversationProvider.priorityCallConversation = conversation
        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)
        router.presentCallQualitySurveyWith_MockMethod = { _ in }

        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)

        // THEN
        XCTAssertFalse(router.presentCallQualitySurveyWith_Invocations.isEmpty)
    }

    func testThatCallQualitySurveyIsNotPresented_WhenCallStateIsTerminating_AndReasonIsNotNormanlOrStillOngoing() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .timeout)
        conversation.remoteIdentifier = UUID()
        callConversationProvider.priorityCallConversation = conversation
        router.presentCallFailureDebugAlertMainWindow_MockMethod = { _ in }

        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)

        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)

        // THEN
        XCTAssertTrue(router.presentCallQualitySurveyWith_Invocations.isEmpty)
    }

    func testThatCallQualitySurveyIsDismissed() {

        // Given
        router.dismissCallQualitySurveyCompletion_MockMethod = { _ in }

        // WHEN
        callQualityViewController.delegate?.callQualityControllerDidFinishWithoutScore(callQualityViewController)

        // THEN
        XCTAssertFalse(router.dismissCallQualitySurveyCompletion_Invocations.isEmpty)
    }

    // MARK: - CallFailureDebugAlert Presentation Tests

    func testThatCallFailureDebugAlertIsPresented_WhenCallIsTerminated() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .internalError)
        conversation.remoteIdentifier = UUID()
        callConversationProvider.priorityCallConversation = conversation
        router.presentCallFailureDebugAlertMainWindow_MockMethod = { _ in }

        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)

        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)

        // THEN
        XCTAssertFalse(router.presentCallFailureDebugAlertMainWindow_Invocations.isEmpty)
    }

    func testThatCallFailureDebugAlertIsNotPresented_WhenCallIsTerminated() {
        // GIVEN
        let establishedCallState: CallState = .established
        let terminatingCallState: CallState = .terminating(reason: .answeredElsewhere)
        conversation.remoteIdentifier = UUID()
        callConversationProvider.priorityCallConversation = conversation

        callQualityController_callCenterDidChange(callState: establishedCallState, conversation: conversation)

        // WHEN
        callQualityController_callCenterDidChange(callState: terminatingCallState, conversation: conversation)

        // THEN
        XCTAssertTrue(router.presentCallFailureDebugAlertMainWindow_Invocations.isEmpty)
    }

}

// MARK: - Helpers
extension CallQualityControllerTests {
    private func configure(view: UIView, isTablet: Bool) {
        callQualityViewController?.dimmingView.alpha = 1
        callQualityViewController?.updateLayout(isRegular: isTablet)
    }

    private func callQualityController_callCenterDidChange(callState: CallState, conversation: ZMConversation) {
        sut.callCenterDidChange(callState: callState,
                                conversation: conversation,
                                caller: otherUser,
                                timestamp: nil,
                                previousCallState: nil)
    }
}

// MARK: - ActiveCallRouterMock
final class MockCallQualityController: CallQualityController {
    override var canPresentCallQualitySurvey: Bool {
        return true
    }
}
