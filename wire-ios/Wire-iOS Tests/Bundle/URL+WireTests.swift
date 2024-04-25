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

import XCTest
import WireTransport
@testable import Wire

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

    func testThatWebsiteURLsAreLoadedCorrectly() {
        let websiteURL = URL(string: "https://wire.com")!
        XCTAssertEqual(be.websiteURL, websiteURL)
        XCTAssertEqual(URL.wr_usernameLearnMore, websiteURL.appendingPathComponent("support/username"))
        XCTAssertEqual(URL.wr_privacyPolicy, websiteURL.appendingPathComponent("legal"))
        XCTAssertEqual(URL.wr_licenseInformation, websiteURL.appendingPathComponent("legal/licenses/embed"))
        XCTAssertEqual(URL.wr_cannotDecryptHelp, websiteURL.appendingPathComponent("privacy/error-1"))
        XCTAssertEqual(URL.wr_cannotDecryptNewRemoteIDHelp, websiteURL.appendingPathComponent("privacy/error-2"))
        XCTAssertEqual(URL.wr_createTeamFeatures, websiteURL.appendingPathComponent("teams/learnmore"))
        XCTAssertEqual(URL.wr_emailInUseLearnMore, websiteURL.appendingPathComponent("support/email-in-use"))
        XCTAssertEqual(URL.wr_termsOfServicesURL, websiteURL.appendingPathComponent("legal"))
    }

    func testThatSupportURLsAreLoadedCorrectly() {
        let supportURL = URL(string: "https://support.wire.com")!
        XCTAssertEqual(WireURL.shared.support, supportURL)
        XCTAssertEqual(URL.wr_emailAlreadyInUseLearnMore, supportURL.appendingPathComponent("hc/en-us/articles/115004082129-My-email-address-is-already-in-use-and-I-cannot-create-an-account-What-can-I-do-"))
        XCTAssertEqual(URL.wr_askSupport,
                       supportURL.appendingPathComponent("hc/requests/new"))
        XCTAssertEqual(URL.wr_fingerprintLearnMore,
                       supportURL.appendingPathComponent("hc/articles/207859815-Why-should-I-verify-my-conversations"))
        XCTAssertEqual(URL.wr_fingerprintHowToVerify,
                       supportURL.appendingPathComponent("hc/articles/207692235-How-can-I-compare-key-fingerprints-"))
        XCTAssertEqual(URL.wr_reportAbuse,
                       supportURL.appendingPathComponent("hc/requests/new"))

    }

    func testThatAccountURLsAreLoadedCorrectly() {
        let accountsURL = URL(string: "https://account.wire.com")!
        XCTAssertEqual(be.accountsURL, accountsURL)
        XCTAssertEqual(URL.wr_passwordReset, accountsURL.appendingPathComponent("forgot"))
    }
}
