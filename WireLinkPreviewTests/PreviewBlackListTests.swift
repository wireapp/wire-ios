// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
@testable import WireLinkPreview

class PreviewBlackListTests: XCTestCase {
    
    var sut: PreviewBlacklist!
    
    override func setUp() {
        super.setUp()
        sut = PreviewBlacklist()
    }
    
    func testThatCorrectHostsAreAllBlacklisted() {
        let hosts = ["soundcloud", "spotify", "youtube", "giphy", "youtu.be", "y2u.be"]

        for host in hosts {
            assertThatHostIsBlacklisted(host)
        }
    }
    
    func assertThatHostIsBlacklisted(_ host: String, line: UInt = #line) {
        let url = URL(string: "www.\(host).com/example")!
        XCTAssertTrue(sut.isBlacklisted(url), "\(host) was not blacklisted", line: line)
    }
    
}
