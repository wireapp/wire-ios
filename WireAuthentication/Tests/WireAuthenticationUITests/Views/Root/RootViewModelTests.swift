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

import Foundation
import WireAuthenticationAPI
import WireNetwork
import XCTest

@testable import WireAuthenticationUI

final class RootViewModelTests: XCTestCase {

    @MainActor
    func test_authenticationFailed_event_resetsPathAndShowsAlert() {
        // given
        let bridge = WireAuthenticationBridge()
        let sut = RootViewModel(
            factory: FakeRootFactory(),
            bridge: bridge,
            environment: BackendEnvironment2.fixture(),
            authenticationType: .new,
            hasOtherAccountsProvider: { false }
        )
        sut.navigate(to: "some-destination")
        XCTAssertFalse(sut.path.isEmpty, "precondition: path should have a navigation item")

        // when
        bridge.sendInboundEvent(.authenticationFailed(title: "Error", message: "Something went wrong"))

        // then
        XCTAssertTrue(sut.path.isEmpty)
        XCTAssertEqual(sut.alert, Alert(title: "Error", message: "Something went wrong"))
    }

}
