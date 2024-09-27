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

import WireUtilities
import XCTest
@testable import WireSyncEngine

final class UserProfileUpdateStatusTests: MessagingTest {
    // MARK: Internal

    var observerToken: Any?

    var sut: UserProfileUpdateStatus! = nil

    /// Number of time the new request callback was invoked
    var newRequestCallbackCount: Int {
        newRequestObserver.notifications.count
    }

    override func setUp() {
        super.setUp()
        newRequestObserver = OperationLoopNewRequestObserver()
        observer = TestUserProfileUpdateObserver()
        mockAnalytics = MockAnalytics()
        sut = UserProfileUpdateStatus(managedObjectContext: uiMOC, analytics: mockAnalytics)
        observerToken = sut.add(observer: observer)
    }

    override func tearDown() {
        newRequestObserver = nil
        observerToken = nil
        observer = nil
        mockAnalytics = nil
        sut = nil
        super.tearDown()
    }

    func testThatItDoesNotRetainObserver() {
        // GIVEN
        var observer: TestUserProfileUpdateObserver? = TestUserProfileUpdateObserver()

        // WHEN
        _ = sut.add(observer: observer!)

        weak var weakObserver = observer

        autoreleasepool {
            observer = nil
        }

        // THEN
        XCTAssertNil(weakObserver)
    }

    // MARK: - Changing email

    func testThatItReturnsErrorWhenPreparingForEmailChangeAndUserUserHasNoEmail() throws {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.setValue(nil, forKey: #keyPath(ZMUser.emailAddress))

        // WHEN
        try sut.requestEmailChange(email: "foo@example.com")
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case .emailUpdateDidFail(error: UserProfileUpdateError.emailNotSet):
            break
        default:
            XCTFail()
        }
    }

    func testThatItPreparesForEmailChangeIfSelfUserHasEmail() throws {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))

        // WHEN
        try sut.requestEmailChange(email: "foo@example.com")
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertTrue(sut.currentlyChangingEmail)
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
        XCTAssertEqual(newRequestCallbackCount, 1)
    }

    // MARK: - Set email and password

    func testThatItIsNotUpdatingEmail() {
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
        XCTAssertNil(sut.emailCredentials())
    }

    func testThatItPreparesForEmailAndPasswordChangeIfTheSelfUserHasNoEmail() throws {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        XCTAssertNil(selfUser.emailAddress)
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")

        // WHEN
        try sut.requestSettingEmailAndPassword(credentials: credentials)

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertTrue(sut.currentlySettingPassword)
        XCTAssertNil(sut.emailCredentials())
        XCTAssertEqual(newRequestCallbackCount, 1)
    }

    func testThatItReturnsErrorWhenPreparingForEmailAndPasswordChangeAndUserUserHasEmail() throws {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")

        // WHEN
        try sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case .emailUpdateDidFail(error: UserProfileUpdateError.emailAlreadySet):
            break
        default:
            XCTFail()
        }
    }

    func testThatItCanCancelSettingEmailAndPassword() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        sut.cancelSettingEmailAndPassword()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
        XCTAssertNil(sut.emailCredentials())
    }

    func testThatItNeedsToSetEmailAfterSuccessfullySettingPassword() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        sut.didUpdatePasswordSuccessfully()

        // THEN
        XCTAssertTrue(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
        XCTAssertNil(sut.emailCredentials())
    }

    func testThatItCompletesAfterSuccessfullySettingPasswordAndEmail() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        sut.didUpdatePasswordSuccessfully()
        sut.didUpdateEmailSuccessfully()

        // THEN
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
        XCTAssertEqual(sut.emailCredentials(), credentials)
    }

    func testThatItNotifiesAfterSuccessfullySettingEmail() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        sut.didUpdatePasswordSuccessfully()
        sut.didUpdateEmailSuccessfully()

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case .emailDidSendVerification:
            break
        default:
            XCTFail()
        }
    }

    func testThatItIsNotSettingEmailAnymoreAsSoonAsTheSelfUserHasEmail() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))

        // THEN
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
    }

    func testThatItIsNotSettingPasswordAnymoreAsSoonAsTheSelfUserHasEmail() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didUpdatePasswordSuccessfully()

        // WHEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.setValue("my@fo.example.com", forKey: #keyPath(ZMUser.emailAddress))

        // THEN
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
    }

    func testThatItIsNotSettingEmailAndPasswordAnymoreIfItFailsToUpdatePassword() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        sut.didFailPasswordUpdate()

        // THEN
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
        XCTAssertNil(sut.emailCredentials())
    }

    func testThatItNotifiesIfItFailsToUpdatePassword() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        sut.didFailPasswordUpdate()

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case .passwordUpdateDidFail:
            break
        default:
            XCTFail()
        }
    }

    func testThatItIsNotSettingEmailAnymoreIfItFailsToUpdateEmail() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        let error = NSError(domain: "WireSyncEngine", code: 100, userInfo: nil)

        // WHEN
        sut.didUpdatePasswordSuccessfully()
        sut.didFailEmailUpdate(error: error)

        // THEN
        XCTAssertFalse(sut.currentlySettingEmail)
        XCTAssertFalse(sut.currentlySettingPassword)
        XCTAssertNil(sut.emailCredentials())
    }

    func testThatItNotifiesIfItFailsToUpdateEmail() {
        // GIVEN
        let error = NSError(domain: "WireSyncEngine", code: 100, userInfo: nil)
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        sut.didUpdatePasswordSuccessfully()
        sut.didFailEmailUpdate(error: error)

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case let .emailUpdateDidFail(_error):
            XCTAssertEqual(error, _error as NSError)
        default:
            XCTFail()
        }
    }

    // MARK: - Credentials provider

    func testThatItDoesNotReturnCredentialsIfOnlyPasswordIsVerified() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")

        // WHEN
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didUpdatePasswordSuccessfully()

        // THEN
        XCTAssertNil(sut.emailCredentials())
    }

    func testThatItDoesNotReturnCredentialsIfOnlyEmailIsVerified() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")

        // WHEN
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didUpdateEmailSuccessfully()

        // THEN
        XCTAssertNil(sut.emailCredentials())
    }

    func testThatItReturnsCredentialsIfEmailAndPasswordAreVerified() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")

        // WHEN
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didUpdatePasswordSuccessfully()
        sut.didUpdateEmailSuccessfully()

        // THEN
        XCTAssertEqual(sut.emailCredentials(), credentials)
    }

    func testThatItDeletesCredentials() {
        // GIVEN
        let credentials = UserEmailCredentials(email: "foo@example.com", password: "%$#@11111")
        try? sut.requestSettingEmailAndPassword(credentials: credentials)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didUpdatePasswordSuccessfully()
        sut.didUpdateEmailSuccessfully()

        // WHEN
        sut.credentialsMayBeCleared()

        // THEN
        XCTAssertNil(sut.emailCredentials())
    }

    // MARK: - Check handle availability

    func testThatItIsNotCheckingAvailabilityAtCreation() {
        XCTAssertFalse(sut.currentlyCheckingHandleAvailability)
    }

    func testThatItPreparesForCheckingHandleAvailability() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.handleToCheck, handle)
        XCTAssertTrue(sut.currentlyCheckingHandleAvailability)
        XCTAssertEqual(newRequestObserver.notifications.count, 1)
    }

    func testThatItCompletesCheckingHandleAvailability_Available() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didNotFindHandle(handle: handle)

        // THEN
        XCTAssertNil(sut.handleToCheck)
        XCTAssertFalse(sut.currentlyCheckingHandleAvailability)
    }

    func testThatItCompletesCheckingHandleAvailability_NotAvailable() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didFetchHandle(handle: handle)

        // THEN
        XCTAssertNil(sut.handleToCheck)
        XCTAssertFalse(sut.currentlyCheckingHandleAvailability)
    }

    func testThatItFailsCheckingHandleAvailability() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didFailRequestToFetchHandle(handle: handle)

        // THEN
        XCTAssertNil(sut.handleToCheck)
        XCTAssertFalse(sut.currentlyCheckingHandleAvailability)
    }

    func testThatItDoesCompletesCheckingHandleAvailabilityIfDifferentHandle_Available() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didNotFindHandle(handle: "other")

        // THEN
        XCTAssertEqual(sut.handleToCheck, handle)
        XCTAssertTrue(sut.currentlyCheckingHandleAvailability)
    }

    func testThatItDoesCompletesCheckingHandleAvailabilityIfDifferentHandle_NotAvailable() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didFetchHandle(handle: "other")

        // THEN
        XCTAssertEqual(sut.handleToCheck, handle)
        XCTAssertTrue(sut.currentlyCheckingHandleAvailability)
    }

    func testThatItDoesCompletesCheckingHandleAvailabilityIfDifferentHandle_Failed() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestCheckHandleAvailability(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didFailRequestToFetchHandle(handle: "other")

        // THEN
        XCTAssertEqual(sut.handleToCheck, handle)
        XCTAssertTrue(sut.currentlyCheckingHandleAvailability)
    }

    func testThatItNotifiesAfterCheckingHandleAvailability_Available() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestCheckHandleAvailability(handle: "other")
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didNotFindHandle(handle: handle)

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case .didCheckAvailabilityOfHandle(handle: handle, available: true):
            break
        default:
            XCTFail()
        }
    }

    func testThatItNotifiesAfterCheckingHandleAvailability_NotAvailable() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestCheckHandleAvailability(handle: "other")
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didFetchHandle(handle: handle)

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case .didCheckAvailabilityOfHandle(handle: handle, available: false):
            break
        default:
            XCTFail()
        }
    }

    func testThatItNotifiesAfterFailingCheckingHandleAvailability() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestCheckHandleAvailability(handle: "other")
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didFailRequestToFetchHandle(handle: handle)

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case .didFailToCheckAvailabilityOfHandle(handle: handle):
            break
        default:
            XCTFail()
        }
    }

    func testThatItIsNotSettingHandleyAtCreation() {
        XCTAssertFalse(sut.currentlySettingHandle)
    }

    func testThatItPreparesForSettingHandle() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.handleToSet, handle)
        XCTAssertTrue(sut.currentlySettingHandle)
        XCTAssertEqual(newRequestObserver.notifications.count, 1)
    }

    func testThatItSetsHandleSuccessfully() {
        // GIVEN
        let handle = "foobar"
        let selfUser = ZMUser.selfUser(in: sut.managedObjectContext)
        XCTAssertNotNil(selfUser)

        // WHEN
        sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didSetHandle()

        // THEN
        XCTAssertNil(sut.handleToSet)
        XCTAssertFalse(sut.currentlySettingHandle)
        XCTAssertEqual(selfUser.handle, handle)
    }

    func testThatItCancelsSetHandle() {
        // GIVEN
        let handle = "foobar"
        let selfUser = ZMUser.selfUser(in: sut.managedObjectContext)

        // WHEN
        sut.requestSettingHandle(handle: handle)
        sut.cancelSettingHandle()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertNil(sut.handleToSet)
        XCTAssertFalse(sut.currentlySettingHandle)
        XCTAssertNil(selfUser.handle)
    }

    func testThatItFailsToSetHandle() {
        // GIVEN
        let handle = "foobar"
        let selfUser = ZMUser.selfUser(in: sut.managedObjectContext)

        // WHEN
        sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didFailToSetHandle()

        // THEN
        XCTAssertNil(sut.handleToSet)
        XCTAssertFalse(sut.currentlySettingHandle)
        XCTAssertNil(selfUser.handle)
    }

    func testThatItFailsToSetHandleBecauseExisting() {
        // GIVEN
        let handle = "foobar"
        let selfUser = ZMUser.selfUser(in: sut.managedObjectContext)

        // WHEN
        sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didFailToSetAlreadyExistingHandle()

        // THEN
        XCTAssertNil(sut.handleToSet)
        XCTAssertFalse(sut.currentlySettingHandle)
        XCTAssertNil(selfUser.handle)
    }

    func testThatItDoesNotSetTheHandleOnSelfUserIfCompletedAfterCancelling() {
        // GIVEN
        let handle = "foobar"
        let selfUser = ZMUser.selfUser(in: sut.managedObjectContext)

        // WHEN
        sut.requestSettingHandle(handle: handle)
        sut.cancelSettingHandle()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didSetHandle()

        // THEN
        XCTAssertNil(selfUser.handle)
    }

    func testThatItNotifyWhenSetingHandleSuccessfully() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didSetHandle()

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case .didSetHandle:
            break
        default:
            XCTFail()
        }
    }

    func testThatItNotifyWhenItFailsToSetHandle() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didFailToSetHandle()

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case .didFailToSetHandle:
            break
        default:
            XCTFail()
        }
    }

    func testThatItNotifiesWhenItFailsToSetHandleBecauseExisting() {
        // GIVEN
        let handle = "foobar"

        // WHEN
        sut.requestSettingHandle(handle: handle)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        sut.didFailToSetAlreadyExistingHandle()

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case .didFailToSetHandleBecauseExisting:
            break
        default:
            XCTFail()
        }
    }

    // MARK: - Find handle suggestions

    func testThatItIsNotGeneratingHandleSuggestionsAtCreation() {
        XCTAssertFalse(sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(sut.bestHandleSuggestion)
    }

    func testThatItPreparesForGeneratingHandleSuggestion() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: sut.managedObjectContext)
        selfUser.name = "Anna Luna"
        let normalized = "annaluna"

        // WHEN
        sut.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertTrue(sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(sut.bestHandleSuggestion)
        XCTAssertEqual(newRequestObserver.notifications.count, 1)
        XCTAssertEqual(sut.suggestedHandlesToCheck?.first, normalized)
    }

    func testThatItStopsGeneratingHandleSuggestionsIfHandleIsSet() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: sut.managedObjectContext)
        selfUser.name = "Anna Luna"

        // WHEN
        sut.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        XCTAssertTrue(sut.currentlyGeneratingHandleSuggestion)
        selfUser.handle = "annaluna"

        // THEN
        XCTAssertFalse(sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(sut.bestHandleSuggestion)
    }

    func testThatItPreparesForGeneratingHandleSuggestionWithInvalidDisplayName() {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: sut.managedObjectContext)
        selfUser.name = "-"

        // WHEN
        sut.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertTrue(sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(sut.bestHandleSuggestion)
        XCTAssertEqual(newRequestObserver.notifications.count, 1)
        XCTAssertNotNil(sut.suggestedHandlesToCheck?.first)
    }

    func testThatItCompletesGeneratingHandleSuggestions() {
        // GIVEN
        let handle = "funkymonkey34"
        sut.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        sut.didFindHandleSuggestion(handle: handle)

        // THEN
        XCTAssertFalse(sut.currentlyGeneratingHandleSuggestion)
        XCTAssertEqual(sut.bestHandleSuggestion, handle)
    }

    func testThatItStopsSearchingForHandleSuggestionsIfItHasHandle() {
        // GIVEN
        sut.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let selfUser = ZMUser.selfUser(in: sut.managedObjectContext)
        selfUser.handle = "cozypanda23"
        sut.didNotFindAvailableHandleSuggestion()

        // THEN
        XCTAssertFalse(sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(sut.bestHandleSuggestion)
    }

    func testThatItRestatsSearchingForHandleSuggestionsAfterNotFindingAvailableOne() {
        // GIVEN
        sut.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
        guard let previousHandle = sut.suggestedHandlesToCheck?.first else {
            XCTFail()
            return
        }

        // WHEN
        sut.didNotFindAvailableHandleSuggestion()

        // THEN
        XCTAssertTrue(sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(sut.bestHandleSuggestion)
        XCTAssertNotNil(sut.suggestedHandlesToCheck?.first)
        XCTAssertNotEqual(sut.suggestedHandlesToCheck?.first, previousHandle)
    }

    func testThatItFailsGeneratingHandleSuggestionsAndStopsIfItHasHandle() {
        // GIVEN
        sut.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        let selfUser = ZMUser.selfUser(in: sut.managedObjectContext)
        selfUser.handle = "cozypanda23"
        sut.didFailToFindHandleSuggestion()

        // THEN
        XCTAssertFalse(sut.currentlyGeneratingHandleSuggestion)
        XCTAssertNil(sut.bestHandleSuggestion)
        XCTAssertNil(sut.suggestedHandlesToCheck)
    }

    func testThatItNotifiesAfterFindingAHandleSuggestion() {
        // GIVEN
        let handle = "funkymokkey34"
        sut.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        sut.didFindHandleSuggestion(handle: handle)

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case let .didFindHandleSuggestion(_handle):
            XCTAssertEqual(handle, _handle)
        default:
            XCTFail()
        }
        XCTAssertEqual(sut.lastSuggestedHandle, handle)
    }

    func testThatIfItSuggestsAHandleAndRequestedToSuggestMoreItStartsBySuggestingTheSame() {
        // GIVEN
        let handle = "funkymokkey34"
        sut.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // WHEN
        sut.didFindHandleSuggestion(handle: handle)

        // THEN
        XCTAssertEqual(observer.invokedCallbacks.count, 1)
        guard let first = observer.invokedCallbacks.first else {
            return
        }
        switch first {
        case let .didFindHandleSuggestion(_handle):
            XCTAssertEqual(handle, _handle)
        default:
            XCTFail()
        }

        // AND WHEN
        sut.suggestHandles()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        XCTAssertEqual(sut.suggestedHandlesToCheck?.count, 1)
        XCTAssertEqual(sut.suggestedHandlesToCheck?.first, handle)
    }

    // MARK: Fileprivate

    fileprivate var observer: TestUserProfileUpdateObserver! = nil

    fileprivate var newRequestObserver: OperationLoopNewRequestObserver!

    fileprivate var mockAnalytics: MockAnalytics!
}
