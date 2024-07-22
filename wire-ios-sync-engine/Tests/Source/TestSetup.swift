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

import WireTransport

class TestSetup: NSObject {
    override init() {
        let defaults = FailingDefaults(suiteName: "failing")!
        defaults.failOnSet = false

        BackendInfo.storage = defaults
        BackendInfo.apiVersion = .v0
        BackendInfo.domain = "wire.com"
        BackendInfo.isFederationEnabled = false

        defaults.failOnSet = true

        super.init()

        BackendInfo.didSetStorage = { _ in
            XCTFail(">>>> Unexpectedly updated storage")
        }
    }
}

private class FailingDefaults: UserDefaults {
    var failOnSet = false

    override func set(_ value: Any?, forKey defaultName: String) {
        if failOnSet {
            XCTFail("Attempted to update storage when `failOnSet` is `true`")
        } else {
            super.set(value, forKey: defaultName)
        }
    }
}
