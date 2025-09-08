//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import XCTest

final class MultiBackendSupportTests: WireUITestCase {

    @MainActor
    func test_Add_MultiBackend_Accounts() async throws {
        let user_Backend1 = try await userHelper.createPersonalUser()

        let firstTimePage = try app.loginUser(email: user_Backend1.email, password: user_Backend1.password)
        var conversationsPage = try  firstTimePage.acceptPopup()

        _ = try conversationsPage.openUserAccountPageForUser(with: user_Backend1.name)
            .tapAddAccountOrTeamButton()

        let deeplink = try EnvironmentVariables().antaDeepLinkURL
        setCustomBackend(byDeeplink: deeplink)
        BackendContext.current = .anta
        
        //Register for backend2
        let user_Backend2 = UserGenerator.generateUniqueUserInfo()

        let welcomePage = try WelcomePage()

        let createPersonalAccountFormPage = try welcomePage
            .enterEmailOrSSO(user_Backend2.email)
            .tapCreatePersonalAccountLink()

        let verificationPage = try createPersonalAccountFormPage
            .enterName(user_Backend2.name)
            .enterPassword(user_Backend2.password)
            .enterConfirmPassword(user_Backend2.password)
            .tapContinueButton()
            .tapAcceptButton()

        let verificationCode = try await InbucketClient.getVerificationCode(email: user_Backend2.email)

        let setUsernamePage = try verificationPage
            .enterVerificationCodeAndConfirm(verificationCode)

         conversationsPage = try setUsernamePage
            .setUsername(user_Backend2.username)

        let settingsPage = try conversationsPage
            .openSettings()

        let accountPage = try settingsPage
            .openAccountSettings()

    }
}
