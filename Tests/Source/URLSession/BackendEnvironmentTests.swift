//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import XCTest
@testable import WireTransport

class BackendEnvironmentTests: XCTestCase {
    
    var backendBundle: Bundle!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let mainBundle = Bundle(for: type(of: self))
        guard let backendBundlePath = mainBundle.path(forResource: "Backend", ofType: "bundle") else { XCTFail("Could not find Backend.bundle"); return }
        guard let backendBundle = Bundle(path: backendBundlePath) else { XCTFail("Could not load Backend.bundle"); return }

        self.backendBundle = backendBundle
        continueAfterFailure = true
    }
    
    override func tearDown() {
        backendBundle = nil
        super.tearDown()
    }
    
    func testThatWeCanLoadBackendEndpoints() {
        guard let environment = BackendEnvironment.from(environmentType: .production, configurationBundle: backendBundle) else { XCTFail("Could not read environment data from Backend.bundle"); return }

        XCTAssertEqual(environment.backendURL, URL(string: "https://prod-nginz-https.wire.com")!)
        XCTAssertEqual(environment.backendWSURL, URL(string: "https://prod-nginz-ssl.wire.com")!)
        XCTAssertEqual(environment.blackListURL, URL(string: "https://clientblacklist.wire.com/prod/ios")!)
        XCTAssertEqual(environment.frontendURL, URL(string: "https://wire.com")!)
    }
    
    func testThatWeCanLoadBackendTrust() {
        guard let environment = BackendEnvironment.from(environmentType: .production, configurationBundle: backendBundle) else { XCTFail("Could not read environment data from Backend.bundle"); return }
        
        guard let trust = environment.certificateTrust as? ServerCertificateTrust else {
            XCTFail(); return
        }
        
        XCTAssertEqual(trust.trustData.count, 1, "Should have one key")
        guard let data = trust.trustData.first else { XCTFail( ); return }
        
        let hosts = Set(data.hosts.map(\.value))
        XCTAssertEqual(hosts.count, 5)
        XCTAssertEqual(hosts, Set(["prod-nginz-https.wire.com", "prod-nginz-ssl.wire.com", "prod-assets.wire.com", "www.wire.com", "wire.com"]))        
    }
    
    func testThatWeCanWorkWithoutLoadingTrust() {
        guard let environment = BackendEnvironment.from(environmentType: .staging, configurationBundle: backendBundle) else { XCTFail("Could not read environment data from Backend.bundle"); return }
        
        guard let trust = environment.certificateTrust as? ServerCertificateTrust else {
            XCTFail(); return
        }
        
        XCTAssertEqual(trust.trustData.count, 0, "We should not have any keys")
    }

}
