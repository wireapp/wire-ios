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

import SwiftUI
import WireSyncEngine
import XCTest

@testable import Wire

final class URLActionRouterTests: XCTestCase {

    func testFirstMeetingPasswordPromptHasNoError() throws {
        let controller = try passwordPrompt(conversationName: nil, isMeeting: true)
        let sheet = try XCTUnwrap(controller as? UIHostingController<MeetingJoinPasswordView?>)

        XCTAssertNil(try XCTUnwrap(sheet.rootView).errorMessage)
    }

    func testConversationPasswordPromptKeepsConversationCopy() throws {
        let controller = try passwordPrompt(conversationName: "Test group")
        let alert = try XCTUnwrap(controller as? UIAlertController)

        XCTAssertEqual(alert.message, "This conversation is password protected")
        XCTAssertEqual(alert.textFields?.first?.placeholder, "Enter conversation password")
        XCTAssertEqual(alert.actions.first?.title, "Join conversation")
    }

    func testWrongMeetingPasswordShowsErrorInPasswordPrompt() throws {
        let controller = try passwordPrompt(conversationName: nil, isMeeting: true, incorrectPassword: true)
        let sheet = try XCTUnwrap(controller as? UIHostingController<MeetingJoinPasswordView?>)

        XCTAssertEqual(try XCTUnwrap(sheet.rootView).errorMessage, "Password is incorrect, please try again.")
    }

    func testInvalidMeetingLinkUsesMeetingError() throws {
        let delegate = MockURLActionRouterDelegate()
        let router = TestableURLActionRouter(viewController: UIViewController(), sessionManager: nil)
        router.delegate = delegate

        router.failedToPerformAction(
            .joinMeeting(domain: "example.com", key: "key", code: "code"),
            error: ConversationJoinError.invalidCode
        )

        let alert = try XCTUnwrap(router.presentedAlert)
        XCTAssertEqual(alert.title, "You could not join the meeting")
        XCTAssertEqual(alert.message, "The meeting link is invalid.")
    }

    func testUnexpectedMeetingFailureKeepsMeetingTitle() throws {
        let delegate = MockURLActionRouterDelegate()
        let router = TestableURLActionRouter(viewController: UIViewController(), sessionManager: nil)
        router.delegate = delegate

        router.failedToPerformAction(
            .joinMeeting(domain: "example.com", key: "key", code: "code"),
            error: NSError(domain: "URLActionRouterTests", code: 1)
        )

        let alert = try XCTUnwrap(router.presentedAlert)
        XCTAssertEqual(alert.title, "You could not join the meeting")
        XCTAssertEqual(alert.message, L10n.Localizable.Error.User.unkownError)
    }

    func testWrongConversationPasswordKeepsConversationError() throws {
        let delegate = MockURLActionRouterDelegate()
        let router = TestableURLActionRouter(viewController: UIViewController(), sessionManager: nil)
        router.delegate = delegate

        router.failedToPerformAction(
            .joinConversation(key: "key", code: "code"),
            error: ConversationJoinError.invalidConversationPassword
        )

        let alert = try XCTUnwrap(router.presentedAlert)
        XCTAssertEqual(alert.title, "You could not join the conversation")
        XCTAssertEqual(alert.message, "Password is incorrect, please try again.")
    }

    private func passwordPrompt(
        conversationName: String?,
        isMeeting: Bool = false,
        incorrectPassword: Bool = false
    ) throws -> UIViewController {
        let delegate = MockURLActionRouterDelegate()
        let router = TestableURLActionRouter(viewController: UIViewController(), sessionManager: nil)
        router.delegate = delegate
        delegate.canDisplayAlerts = false
        router
            .showPasswordPrompt(
                for: conversationName,
                isMeeting: isMeeting,
                incorrectPassword: incorrectPassword
            ) { _ in
            }
        delegate.canDisplayAlerts = true
        router.presentPendingAlert()
        XCTAssertEqual(router.presentedOverCurrentScreen, isMeeting)
        return try XCTUnwrap(router.presentedController)
    }

    // MARK: Presenting Alerts

    func testThatAlertIsPresented_WhenCanDisplayAlertsReturnsTrue() {
        // GIVEN
        let alert = UIAlertController(
            title: nil,
            message: "Hello World",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        let viewController = UIViewController()
        let delegate = MockURLActionRouterDelegate()
        let router = TestableURLActionRouter(viewController: viewController, sessionManager: .none)
        router.delegate = delegate

        // WHEN
        router.presentAlert(alert)

        // THEN
        XCTAssertEqual(router.presentedAlert, alert)
    }

    func testThatAlertIsNotPresented_WhenCanDisplayAlertsReturnsFalse() {
        // GIVEN
        let alert = UIAlertController(
            title: nil,
            message: "Hello World",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))
        let viewController = UIViewController()
        let delegate = MockURLActionRouterDelegate()
        delegate.canDisplayAlerts = false
        let router = TestableURLActionRouter(viewController: viewController, sessionManager: .none)
        router.delegate = delegate

        // WHEN
        router.presentAlert(alert)

        // THEN
        XCTAssertEqual(router.presentedAlert, nil)
    }

    func testThatPendingAlertIsPresented_WhenPerformPendingActionsIsCalled() {
        // GIVEN
        let alert = UIAlertController(
            title: nil,
            message: "Hello World",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))
        let viewController = UIViewController()
        let delegate = MockURLActionRouterDelegate()
        delegate.canDisplayAlerts = false
        let router = TestableURLActionRouter(viewController: viewController, sessionManager: .none)
        router.delegate = delegate
        router.presentAlert(alert)

        // WHEN
        delegate.canDisplayAlerts = true
        router.performPendingActions()

        // THEN
        XCTAssertEqual(router.presentedAlert, alert)
    }

    // MARK: Navigation

    func testThatNavigationPerformed_WhenAuthenticatedRouterIsAvailable() {
        // GIVEN
        let viewController = UIViewController()
        let authenticatedRouter = MockAuthenticatedRouter()
        let router = TestableURLActionRouter(viewController: viewController, sessionManager: .none)
        router.authenticatedRouter = authenticatedRouter

        // WHEN
        router.navigate(to: .conversationList)

        // THEN
        guard case .conversationList = authenticatedRouter.didNavigateToDestination else {
            return XCTFail("Failed to perform navigation")
        }
    }

    func testThatNavigationPerformed_WhenAuthenticatedRouterBecomesAvailable() {
        // GIVEN
        let viewController = UIViewController()
        let authenticatedRouter = MockAuthenticatedRouter()
        let router = TestableURLActionRouter(viewController: viewController, sessionManager: .none)
        router.navigate(to: .conversationList)

        // WHEN
        router.authenticatedRouter = authenticatedRouter
        router.performPendingActions()

        // THEN
        guard case .conversationList = authenticatedRouter.didNavigateToDestination else {
            return XCTFail("Failed to perform navigation")
        }
    }

    func testThatMeetingsNotificationNavigates_WhenAuthenticatedRouterIsAvailable() {
        // GIVEN
        let viewController = UIViewController()
        let authenticatedRouter = MockAuthenticatedRouter()
        let router = TestableURLActionRouter(viewController: viewController, sessionManager: .none)
        router.authenticatedRouter = authenticatedRouter

        // WHEN
        router.showMeetings()

        // THEN
        guard case .meetings = authenticatedRouter.didNavigateToDestination else {
            return XCTFail("Failed to perform navigation")
        }
    }

    func testThatMeetingsNotificationNavigates_WhenAuthenticatedRouterBecomesAvailable() {
        // GIVEN
        let viewController = UIViewController()
        let authenticatedRouter = MockAuthenticatedRouter()
        let router = TestableURLActionRouter(viewController: viewController, sessionManager: .none)
        router.showMeetings()

        // WHEN
        router.authenticatedRouter = authenticatedRouter
        router.performPendingActions()

        // THEN
        guard case .meetings = authenticatedRouter.didNavigateToDestination else {
            return XCTFail("Failed to perform navigation")
        }
    }

    func testThatMeetingCallNavigatesToLinkedMeeting() {
        let authenticatedRouter = MockAuthenticatedRouter()
        let router = TestableURLActionRouter(viewController: UIViewController(), sessionManager: nil)
        let conversationID = QualifiedID(uuid: UUID(), domain: "wire.com")
        let accountID = UUID()
        router.authenticatedRouter = authenticatedRouter

        router.joinMeetingCall(conversationID, accountID: accountID)

        guard case let .meetingCall(routedID, routedAccountID) = authenticatedRouter.didNavigateToDestination else {
            return XCTFail("Expected the meeting call destination")
        }
        XCTAssertEqual(routedID, conversationID)
        XCTAssertEqual(routedAccountID, accountID)
    }

    func testThatMeetingCallWaitsForAuthenticatedRouter() {
        let router = TestableURLActionRouter(viewController: UIViewController(), sessionManager: nil)
        let conversationID = QualifiedID(uuid: UUID(), domain: "wire.com")
        let accountID = UUID()
        router.joinMeetingCall(conversationID, accountID: accountID)

        let authenticatedRouter = MockAuthenticatedRouter()
        router.authenticatedRouter = authenticatedRouter
        router.performPendingActions()

        guard case let .meetingCall(routedID, routedAccountID) = authenticatedRouter.didNavigateToDestination else {
            return XCTFail("Expected the pending meeting call destination")
        }
        XCTAssertEqual(routedID, conversationID)
        XCTAssertEqual(routedAccountID, accountID)
    }
}

final class MockAuthenticatedRouter: AuthenticatedRouterProtocol {

    func updateActiveCallPresentationState() {}

    func minimizeCallOverlay(animated: Bool, completion: Completion?) {}

    var didNavigateToDestination: NavigationDestination?
    func navigate(to destination: NavigationDestination) {
        didNavigateToDestination = destination
    }
}

final class MockURLActionRouterDelegate: URLActionRouterDelegate {

    var didCallWillShowCompanyLoginError: Bool = false
    func urlActionRouterWillShowCompanyLoginError() {
        didCallWillShowCompanyLoginError = true
    }

    var canDisplayAlerts: Bool = true
    func urlActionRouterCanDisplayAlerts() -> Bool {
        canDisplayAlerts
    }

}

final class TestableURLActionRouter: URLActionRouter {

    var presentedController: UIViewController?
    var presentedOverCurrentScreen: Bool?
    var presentedAlert: UIAlertController? { presentedController as? UIAlertController }

    override func internalPresentAlert(_ alert: UIViewController, overCurrentScreen: Bool) {
        presentedController = alert
        presentedOverCurrentScreen = overCurrentScreen
    }
}
