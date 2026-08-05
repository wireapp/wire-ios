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

import WireLocators
import XCTest

/// User Account/profile page
class UserProfilePage: PageModel {

    override var pageMainElement: XCUIElement {
        userProfilePicture
    }

    enum UserAvailabilityStatus: String {
        case none = "None"
        case available = "Available"
        case busy = "Busy"
        case away = "Away"

        var identifier: String {
            switch self {
            case .none:
                Locators.UserProfileStatusPicker.none.rawValue
            case .available:
                Locators.UserProfileStatusPicker.available.rawValue
            case .busy:
                Locators.UserProfileStatusPicker.busy.rawValue
            case .away:
                Locators.UserProfileStatusPicker.away.rawValue
            }
        }

        var expectedValue: String {
            self == .none ? "" : rawValue
        }
    }

    var qrCodeButton: XCUIElement {
        app.buttons[Locators.UserProfilePage.qrCodeButton.rawValue]
    }

    var nameInfo: XCUIElement {
        app.descendants(matching: .any)[Locators.UserProfilePage.name.rawValue].firstMatch
    }

    var usernameInfo: XCUIElement {
        app.descendants(matching: .any)[Locators.UserProfilePage.username.rawValue].firstMatch
    }

    var userProfilePicture: XCUIElement {
        app.buttons[Locators.UserProfilePage.userProfilePicture.rawValue]
    }

    var createTeamButton: XCUIElement {
        app.otherElements.buttons[Locators.UserProfilePage.createWireTeamButton.rawValue].firstMatch
    }

    var teamNameOnAccountPage: XCUIElement {
        app.descendants(matching: .staticText)[Locators.UserProfilePage.teamName.rawValue].firstMatch
    }

    var manageTeamButton: XCUIElement {
        app.buttons[Locators.UserProfilePage.addAccountOrTeamButton.rawValue].firstMatch
    }

    var closeButton: XCUIElement {
        app.descendants(matching: .button)[Locators.UserProfilePage.close.rawValue].firstMatch
    }

    var addAccountOrTeamButton: XCUIElement {
        app.descendants(matching: .button)[Locators.UserProfilePage.addAccountOrTeamButton.rawValue].firstMatch
    }

    var statusButton: XCUIElement {
        app.descendants(matching: .any)[Locators.UserProfilePage.status.rawValue].firstMatch
    }

    var profileQRCodeImage: XCUIElement {
        app.images[Locators.UserProfileQRCodePage.qrCodeImage.rawValue].firstMatch
    }

    var profileQRCodeUsername: XCUIElement {
        app.staticTexts[Locators.UserProfileQRCodePage.username.rawValue].firstMatch
    }

    var shareProfileLinkButton: XCUIElement {
        app.buttons[Locators.UserProfileQRCodePage.shareProfileLinkButton.rawValue].firstMatch
    }

    var shareQRCodeButton: XCUIElement {
        app.buttons[Locators.UserProfileQRCodePage.shareQRCodeButton.rawValue].firstMatch
    }

    var okButton: XCUIElement {
        app.buttons[Locators.UserProfileStatusPicker.okButton.rawValue].firstMatch
    }

    func tapCreateTeamButton() throws -> TeamSetupStepsPage {
        createTeamButton.tap()
        return try TeamSetupStepsPage()
    }

    func closeAccountPage() throws -> ConversationsPage {
        closeButton.tap()
        return try ConversationsPage()
    }

    func getTeamName() -> String? {
        teamNameOnAccountPage.value as? String
    }

    @discardableResult
    func verifyName(
        _ name: String,
    ) -> UserProfilePage {

        XCTAssertEqual(
            nameInfo.value as? String ?? nameInfo.label,
            name,
            "Name did not match \(name)",

        )
        return self
    }

    @discardableResult
    func verifyUsername(
        _ username: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UserProfilePage {
        let expectedUsername = "@\(username)"

        XCTAssertEqual(
            usernameInfo.value as? String ?? usernameInfo.label,
            expectedUsername,
            "Username did not match \(expectedUsername)",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func verifyAddedAccountInfo(
        for name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UserProfilePage {
        let predicate = NSPredicate(format: "label BEGINSWITH %@", name)
        let accountButton = app.buttons.containing(predicate).firstMatch

        XCTAssertTrue(
            accountButton.waitForExistence(timeout: 5),
            "Added account info did not appear for \(name)",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func verifyProfileQRCode(
        username: String,
    ) -> UserProfilePage {
        let expectedUsername = "@\(username)"

        XCTAssertTrue(
            qrCodeButton.waitAndTap(),
            "Profile QR code button is not showing",
        )

        XCTAssertTrue(
            profileQRCodeImage.waitForExistence(timeout: 5),
            "Profile QR code is not showing",
        )

        XCTAssertEqual(
            profileQRCodeUsername.value as? String ?? profileQRCodeUsername.label,
            expectedUsername,
            "Profile QR code username did not match \(expectedUsername)",
        )

        XCTAssertTrue(
            shareProfileLinkButton.waitForExistence(timeout: 3),
            "Share profile link button is not showing",
        )

        XCTAssertTrue(
            shareQRCodeButton.waitForExistence(timeout: 3),
            "Share QR code button is not showing",
        )

        return self
    }

    @discardableResult
    func verifyProfilePictureIsSet(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UserProfilePage {
        let actualValue = userProfilePicture.value as? String
        let expectedValue = "image"

        XCTAssertEqual(
            actualValue,
            expectedValue,
            "User profile picture did not show selected image",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func setUserStatus(
        _ status: UserAvailabilityStatus,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UserProfilePage {
        XCTAssertTrue(
            statusButton.waitAndTap(),
            "Status button did not appear",
            file: file,
            line: line
        )

        let statusOption = app.buttons[status.identifier].firstMatch
        XCTAssertTrue(
            statusOption.waitAndTap(),
            "\(status.rawValue) option did not appear",
            file: file,
            line: line
        )

        return dismissStatusConfirmationPopup(for: status)
    }

    @discardableResult
    func verifyUserStatus(
        _ status: UserAvailabilityStatus,
    ) -> UserProfilePage {
        XCTAssertEqual(
            statusButton.value as? String ?? "",
            status.expectedValue,
            "Selected status did not match \(status.rawValue)",
        )

        return self
    }

    @discardableResult
    private func dismissStatusConfirmationPopup(for status: UserAvailabilityStatus) -> UserProfilePage {
        let confirmationPopup = app.alerts.firstMatch
        XCTAssertTrue(confirmationPopup.waitForExistence(timeout: 3), "Status confirmation popup did not appear")
        XCTAssertTrue(
            okButton.waitAndTap(),
            "Could not dismiss \(status.rawValue) popup"
        )

        return self
    }

    func tapAddAccountOrTeamButton() throws -> WelcomePage {
        addAccountOrTeamButton.tap()
        return try WelcomePage()
    }

    @discardableResult
    func switchUserAccountForUser(withName name: String) throws -> ConversationsPage {
        let predicate = NSPredicate(format: "label BEGINSWITH %@", name)
        let button = app.buttons.containing(predicate).firstMatch
        button.tap()
        return try ConversationsPage()
    }

}
