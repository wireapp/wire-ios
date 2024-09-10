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
import WireTransportSupport
import XCTest

/// This class is set as NSPrincipalClass in test suite info.plist
/// XCTest makes sure to initialise it only once and we can add all global
/// test setup code here
final class TestSetup: NSObject {

    override init() {
        super.init()

        XCTestObservationCenter.shared.addTestObserver(
            makeBackendInfoTestObserver(
                apiVersion: .v0,
                preferredAPIVersion: nil,
                domain: "wire.com",
                isFederationEnabled: false
            )
        )

        // The snapshot tests expect to be run with CET time zone
        // We make sure that is the case if e.g. tests run on cloud CI provider
        if let timezone = TimeZone(abbreviation: "CET") {
            NSTimeZone.default = timezone
        }
    }

}
