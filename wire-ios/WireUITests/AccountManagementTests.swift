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

import WireFoundation
import XCTest

/// [core-messenger]
final class AccountManagementTests: WireUITestCase {

    var teamMember: UserInfo!

    @MainActor
    func testUpdateNameAndUsernameInfo_TC_8932_TC_8934() async throws {

        let user = try await UserHelper.default.createPersonalUser()

        let accountSettingPage = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openSettings()
            .openAccountSettings()
            .tapNameField()
            .updateName()
            .tapUsernameField()
            .updateUsernameAndSave()

        XCTAssertTrue(
            (accountSettingPage.nameField.value as? String)?.contains("-updated") == true,
            "Updated name was not visible"
        )

        XCTAssertTrue(
            accountSettingPage.usernameField.label.contains("@\(user.username)-updated"),
            "Updated username was not visible"
        )
    }

    @MainActor
    func testAccountManagementLockWithPasscode_TC_8950() async throws {

        let passcode = UserGenerator.generateAppPasscode()

        let user = try await UserHelper.default.createPersonalUser()

        let page = try await app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openSettings()
            .openOptionsMenu()
            .enableLockWithPasscode()
            .SetPasscode(passcode)
            .backgroundAndResume(app: app, forDelay: 2)

        XCTAssertFalse(
            page.conversationsButton.exists,
            "App incorrectly showing conversations page without app passcode"
        )

        _ = try page.enterPasscode(passcode)

    }

    @MainActor
    func testAccountManagementUpdateEmailAndResetPassword_TC_8933_TC_8931() async throws {

        let updatedUserDetails = UserGenerator.generateUniqueUserInfo()

        let user = try await UserHelper.default.createPersonalUser()

        let verifyEmailPage = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()
            .openSettings()
            .openAccountSettings()
            .tapEmailField()
            .updateEmailAndSave(with: updatedUserDetails.email)

        XCTAssertTrue(
            app.staticTexts["Resend to \(updatedUserDetails.email)"].exists,
            "Expected static text label 'Resend to \(updatedUserDetails.email)' to be visible, but it was missing."
        )

        let webViewPage = try verifyEmailPage.goBacktoAccountSetting()
            .tapOnResetPasswordButton()

        XCTAssertTrue(webViewPage.webViewOpened(), "WebView didn't open")

    }

    @MainActor
    func testViewLoggedInDevicesVerifyAndDeleteDevice_TC_8952_8953() async throws {
        // GIVEN
        let user = try await UserHelper.default.createPersonalUser()
        let deviceName = "device123"

        let conversationsPage = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup()

        _ = try await testServicesClient.getInstanceId(
            email: user.email,
            password: user.password,
            name: user.name,
            verificationCode: nil,
            deviceName: deviceName
        )
        // WHEN
        let deviceDetailsPage = try conversationsPage
            .openSettings()
            .openDevices()
            .verifyLoggedInDevicesListContains(deviceName)
            .openDeviceDetails(named: deviceName)

        // THEN
        _ = try await deviceDetailsPage
            .verifyDevice()
            .backgroundAndResume(app: app, forDelay: 2)
            .verifyDeviceIsStillVerified()
            .deleteDevice(password: user.password)
            .verifyDeviceIsDeleted(named: deviceName)
    }

    @MainActor
    func testDeleteDeviceWhenClientLimitReached_TC_8973() async throws {
        // GIVEN
        let user = try await UserHelper.default.createPersonalUser()
        // 7 instances to register 7 clients
        let deviceNames = (1 ... 7).map { "device-\($0)" }

        for deviceName in deviceNames {
            _ = try await testServicesClient.getInstanceId(
                email: user.email,
                password: user.password,
                name: user.name,
                verificationCode: nil,
                deviceName: deviceName,
                useCache: false
            )
        }

        // WHEN
        _ = try app.loginUser(email: user.email, password: user.password)

        // THEN
        _ = try ManagedDevicesPage()
            .removeFirstDeviceAndContinue(password: user.password)
    }
}
