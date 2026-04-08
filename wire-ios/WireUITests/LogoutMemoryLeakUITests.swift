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

import XCTest

/// UI tests to verify UserSession memory cleanup after logout
/// These tests help catch memory leaks in the logout flow
final class LogoutMemoryLeakUITests: WireUITestCase {

    override class var defaultArguments: [String] {
        super.defaultArguments + ["-EnableMemoryTracking"]
    }

    /// Test that UserSession is deallocated after logout
    /// testiny: Add link when created
    @MainActor
    func testUserSessionDeallocatedAfterLogout() async throws {
        // Given
        let user = try await userHelper.createPersonalUser()

        let conversationsPage = try app.loginUser(email: user.email, password: user.password)
            .acceptPopup(with: self)
    
        try checkUserSessionExists(true)
                
        // When
        try performLogout(password: user.password)
        XCTAssertNoThrow(try WelcomePage())

        // Then
        try checkUserSessionExists(false)
    }

    private func checkUserSessionExists(_ exists: Bool) throws {
        try DeveloperToolsPage.show(from: app)
            .isUserSessionMemoryStatus(deallocated: !exists)
            .hide()
    }

    private func performLogout(password: String) throws {
        let conversationPage = try ConversationsPage()
        _ = try conversationPage
            .openSettings()
            .openAccountSettings()
            .logout()
            .enterPassword(password)
    }

}
