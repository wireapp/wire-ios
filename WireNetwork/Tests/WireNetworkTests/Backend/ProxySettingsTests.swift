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

@testable import WireNetwork

final class ProxySettingsTests: XCTestCase {

    func testProxyDictionary_whenUnauthenticated() throws {
        // GIVEN
        let sut = ProxySettings.unauthenticated(host: "Host", port: 10)

        // WHEN
        let result = sut.proxyDictionary()

        // THEN
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result["SOCKSEnable"] as? Int, 1)
        XCTAssertEqual(result["SOCKSProxy"] as? String, "Host")
        XCTAssertEqual(result["SOCKSPort"] as? Int, 10)
        XCTAssertEqual(result[kCFProxyTypeKey] as? String, kCFProxyTypeSOCKS as String)
        XCTAssertEqual(result[kCFStreamPropertySOCKSVersion] as? String, kCFStreamSocketSOCKSVersion5 as String)
    }

    func testProxyDictionary_whenAuthenticated() throws {
        // GIVEN
        let sut = ProxySettings.authenticated(host: "Host", port: 10, username: "User", password: "Password")

        // WHEN
        let result = sut.proxyDictionary()

        // THEN
        XCTAssertEqual(result.count, 7)
        XCTAssertEqual(result["SOCKSEnable"] as? Int, 1)
        XCTAssertEqual(result["SOCKSProxy"] as? String, "Host")
        XCTAssertEqual(result["SOCKSPort"] as? Int, 10)
        XCTAssertEqual(result[kCFProxyTypeKey] as? String, kCFProxyTypeSOCKS as String)
        XCTAssertEqual(result[kCFStreamPropertySOCKSVersion] as? String, kCFStreamSocketSOCKSVersion5 as String)
        XCTAssertEqual(result[kCFStreamPropertySOCKSUser] as? String, "User")
        XCTAssertEqual(result[kCFStreamPropertySOCKSPassword] as? String, "Password")
    }

}
