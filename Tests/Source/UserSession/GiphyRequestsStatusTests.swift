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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import XCTest

class GiphyRequestsStatusTests: MessagingTest {
    
    private var sut: GiphyRequestsStatus!
    
    override func setUp() {
        super.setUp()
        self.sut = GiphyRequestsStatus()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testThatRequestIsAddedToPendingRequest() {

        let exp = self.expectationWithDescription("expected callback")

        //given
        let url = NSURL(string: "foo/bar", relativeToURL: nil)!
        let callback: (NSData!, NSHTTPURLResponse!, NSError!) -> Void = { (_, _, _) -> Void in
            exp.fulfill()
        }
        
        //when
        self.sut.addRequest(url, callback: callback)
        
        //then
        let request = self.sut.pendingRequests.last
        XCTAssert(request != nil)
        XCTAssertEqual(request!.url, url, "")
        XCTAssert(request!.callback != nil)
        if let receivedCallback = request!.callback {
            receivedCallback(nil, NSHTTPURLResponse(), nil)
        }
        else {
            XCTFail("No callback")
        }
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
    }
    
}


