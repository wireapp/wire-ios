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

@testable import WireSyncEngine
import XCTest

final class CRLURLBuilderTests: XCTestCase {

    var sut: CRLURLBuilder!
    var distributionPoint: URL!

    override func setUp() {
        super.setUp()

        sut = CRLURLBuilder(shouldUseProxy: true, proxyURLString: "")
        distributionPoint = URL(string: "https://acme.diya.link/crl")
    }

    override func tearDown() {
        sut = nil
        distributionPoint = nil

        super.tearDown()
    }

    func testThatItConstructsProxyCrlURL_ShouldUseProxy() {
        // GIVEN
        sut = CRLURLBuilder(shouldUseProxy: true, proxyURLString: "https://something.link/proxyCrl")

        // WHEN
        let urlToUse = sut.getURL(from: distributionPoint)

        // THEN
        XCTAssertEqual(URL(string: "https://something.link/proxyCrl/acme.diya.link"), urlToUse)
    }

    func testThatItReturnsDistributionPoint_ShouldNotUseProxy() {
        // GIVEN
        sut = CRLURLBuilder(shouldUseProxy: false, proxyURLString: "https://something.link/proxyCrl")

        // WHEN
        let urlToUse = sut.getURL(from: distributionPoint)

        // THEN
        XCTAssertEqual(distributionPoint, urlToUse)
    }

    func testThatItReturnsDistributionPoint_ProxyURLIsNil() {
        // GIVEN
        sut = CRLURLBuilder(shouldUseProxy: true, proxyURLString: nil)

        // WHEN
        let urlToUse = sut.getURL(from: distributionPoint)

        // THEN
        XCTAssertEqual(distributionPoint, urlToUse)
    }

}
