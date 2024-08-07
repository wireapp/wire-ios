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

import WireTesting
import WireTransport

final class TestSetup: NSObject, XCTestObservation {
    private let defaults: TestUserDefaults

    override init() {
        defaults = TestUserDefaults(suiteName: UUID().uuidString)!
        super.init()

        XCTestObservationCenter.shared.addTestObserver(self)
    }

    func testBundleWillStart(_ testBundle: Bundle) {
        BackendInfo.storage = defaults
        BackendInfo.apiVersion = .v0
        BackendInfo.domain = "wire.com"
        BackendInfo.isFederationEnabled = false

        defaults.shouldSet = { _, _ in
            XCTFail("BackendInfo was mutated outside of mocking")
            return false
        }
    }

    func testBundleDidFinish(_ testBundle: Bundle) {
        defaults.reset()
    }
}
