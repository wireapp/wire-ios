//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import SnapshotTesting
@testable import Wire

final class AppLockModuleViewTests: XCTestCase {

    private var sut: AppLockModule.View!
    private var presenter: AppLockModule.MockPresenter!

    override func setUp() {
        super.setUp()
        sut = .init()
        presenter = .init()

        sut.presenter = presenter
    }

    override func tearDown() {
        sut = nil
        presenter = nil
        super.tearDown()
    }

    // MARK: - Event sending

    func test_ItSendsEvent_WhenViewAppears() {
        // When
        sut.viewDidAppear(false)

        // Then
        XCTAssertEqual(presenter.events, [.viewDidAppear])
    }

    // @SF.Locking @TSFI.FS-IOS @S0.1
    // Make sure that the presenter got event from view if unlock happened through reauthentication
    func test_ItSendsEvent_WhenLockViewRequestReauthentication() {
        // Given
        sut.loadViewIfNeeded()

        // When
        sut.refresh(withModel: .locked(.faceID))
        sut.lockView.actionRequested?()

        // Then
        XCTAssertEqual(presenter.events, [.unlockButtonTapped])
    }

    func test_ItSendsEvent_WhenLockViewRequestOpenDeviceSettings() {
        // Given
        sut.loadViewIfNeeded()

        // When
        sut.refresh(withModel: .locked(.unavailable))
        sut.lockView.actionRequested?()

        // Then
        XCTAssertEqual(presenter.events, [.openDeviceSettingsButtonTapped])
    }

    func test_ItSendsEvent_WhenPasscodeSetupFinishes() {
        // When
        sut.passcodeSetupControllerDidFinish()

        // Then
        XCTAssertEqual(presenter.events, [.passcodeSetupCompleted])
    }

    func test_ItSendsEvent_WhenCustomPasscodeIsVerified() {
        // When
        sut.unlockViewControllerDidUnlock()

        // Then
        XCTAssertEqual(presenter.events, [.customPasscodeVerified])
    }

    func test_ItSendsEvent_WhenConfigChangeWarningIsDismissed() {
        // When
        sut.appLockChangeWarningViewControllerDidDismiss()

        // Then
        XCTAssertEqual(presenter.events, [.configChangeAcknowledged])
    }

    // @SF.Locking @TSFI.FS-IOS @S0.1
    // Make sure presenter gets event when app enters foreground
    func test_ItSendsEvent_WhenApplicationWillEnterForeground() {
        // When
        sut.applicationWillEnterForeground()

        // Then
        XCTAssertEqual(presenter.events, [.applicationWillEnterForeground])
    }

    // MARK: - View states

    func test_ViewState_Locked() {
        // Given
        for type in AuthenticationType.allCases {
            sut.refresh(withModel: .locked(type))

            // Then
            verify(matching: sut)
        }
    }

    func test_ViewState_Authenticating() {
        // Given
        sut.refresh(withModel: .authenticating)

        // Then
        verify(matching: sut)
    }

}
