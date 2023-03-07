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
import WireUtilities

class NotificationSessionTests_CryptoStack: BaseTest {

    func test_CryptoStackSetup_OnInit() throws {
        // GIVEN
        var flag = DeveloperFlag.proteusViaCoreCrypto
        flag.isOn = true

        let context = coreDataStack.syncContext

        XCTAssertNil(context.mlsController)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)

        // WHEN
        _ = try createNotificationSession()

        // THEN
        XCTAssertNotNil(context.mlsController)
        XCTAssertNotNil(context.proteusService)
        XCTAssertNotNil(context.coreCrypto)

        flag.isOn = false
    }

}
