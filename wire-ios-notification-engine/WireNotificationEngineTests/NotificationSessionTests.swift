//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

@testable import WireNotificationEngine
import XCTest
import Foundation

final class NotificationSessionTests: BaseTest {

    // MARK: - Init errors

    func test_ItDoesNotInit_WhenCryptoboxMigrationIsPending() throws {
        do {
            // Given
            mockCryptoboxMigrationManager.isMigrationNeededAccountDirectory_MockValue = true

            // When
            _ = try createNotificationSession()
        } catch NotificationSession.InitializationError.pendingCryptoboxMigration {
            // Then
            return
        } catch {
            XCTFail("unexpected error: \(error.localizedDescription)")
        }

        XCTFail("unexpected success")
    }

}
