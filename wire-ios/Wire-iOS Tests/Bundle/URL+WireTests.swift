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

@testable import Wire
import WireTransport
import XCTest

final class URL_WireTests: XCTestCase {

    var be: BackendEnvironment!

    override func setUp() {
        super.setUp()
        let bundle = Bundle.backendBundle
        let defaults = UserDefaults(suiteName: "URLWireTests")!
        EnvironmentType.production.save(in: defaults)
        be = BackendEnvironment(userDefaults: defaults, configurationBundle: bundle)
    }

    override func tearDown() {
        be = nil
        super.tearDown()
    }

    func testThatAccountURLsAreLoadedCorrectly() {
        let accountsURL = URL(string: "https://account.wire.com")!
        XCTAssertEqual(be.accountsURL, accountsURL)
    }
}
