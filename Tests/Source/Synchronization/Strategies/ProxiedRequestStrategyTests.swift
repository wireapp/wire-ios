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


import Foundation
import zmessaging

class ProxiedRequestStrategyTests: MessagingTest {

    private var sut : ProxiedRequestStrategy!
    private var requestsStatus : ProxiedRequestsStatus!
    
    override func setUp() {
        super.setUp()
        self.requestsStatus = ProxiedRequestsStatus()
        self.sut = ProxiedRequestStrategy(requestsStatus: self.requestsStatus, managedObjectContext: self.uiMOC)
    }
    
    override func tearDown() {
        self.sut = nil
        self.requestsStatus = nil
        super.tearDown()
    }
    
    func testThatItGeneratesNoRequestsIfTheStatusIsEmpty() {
        XCTAssertNil(self.sut.nextRequest())
    }
    
    func testThatItGeneratesAGiphyRequest() {
        
        // given
        requestsStatus.addRequest(.Giphy, path: "/foo/bar", method:.MethodGET, callback: { (_,_,_) -> Void in return})
        
        // when
        let request : ZMTransportRequest? = self.sut.nextRequest()
        
        // then
        if let request = request {
            XCTAssertEqual(request.method, ZMTransportRequestMethod.MethodGET)
            XCTAssertEqual(request.path, "/proxy/giphy/foo/bar")
            XCTAssertTrue(request.needsAuthentication)
        } else {
            XCTFail("Empty request")
        }
    }

    func testThatItGeneratesASoundcloudRequest() {
        
        // given
        requestsStatus.addRequest(.Soundcloud, path: "/foo/bar", method:.MethodGET, callback: { (_,_,_) -> Void in return})
        
        // when
        let request : ZMTransportRequest? = self.sut.nextRequest()
        
        // then
        if let request = request {
            XCTAssertEqual(request.method, ZMTransportRequestMethod.MethodGET)
            XCTAssertEqual(request.path, "/proxy/soundcloud/foo/bar")
            XCTAssertTrue(request.needsAuthentication)
            XCTAssertTrue(request.doesNotFollowRedirects)
        } else {
            XCTFail("Empty request")
        }
    }
    
    func testThatItGeneratesTwoRequestsInOrder() {
        
        // given
        requestsStatus.addRequest(.Giphy, path: "/foo/bar1", callback: {_,_,_ in return})
        requestsStatus.addRequest(.Giphy, path: "/foo/bar2", callback: {_,_,_ in return})
        
        // when
        let request1 : ZMTransportRequest? = self.sut.nextRequest()
        
        // then
        if let request1 = request1 {
            XCTAssertEqual(request1.path, "/proxy/giphy/foo/bar1")
        } else {
            XCTFail("Empty request")
        }
        
        // and when
        let request2 : ZMTransportRequest? = self.sut.nextRequest()
        
        // then
        if let request2 = request2 {
            XCTAssertEqual(request2.path, "/proxy/giphy/foo/bar2")
        }
    }

    func testThatItGeneratesARequestOnlyOnce() {
        
        // given
        requestsStatus.addRequest(.Giphy, path: "/foo/bar1", method:.MethodGET, callback: {_,_,_ in return})
        
        // when
        let request1 : ZMTransportRequest? = self.sut.nextRequest()
        let request2 : ZMTransportRequest? = self.sut.nextRequest()
        
        // then
        XCTAssertNotNil(request1)
        XCTAssertNil(request2)

    }
    
    func testThatItCallsTheCompletionHandlerWhenTheRequestIsCompleted() {
        
        // given
        let error = NSError(domain: "ZMTransportSession", code: 10, userInfo: nil)
        let data = "Foobar".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
        let HTTPResponse = NSHTTPURLResponse(URL: NSURL(string: "http://www.example.com/")!, statusCode:200, HTTPVersion:"HTTP/1.1", headerFields:[
                "Content-Length": "\(data.length)",
                "Server": "nginx"
            ]
        )!
        
        let response = ZMTransportResponse(HTTPURLResponse: HTTPResponse, data: data, error: error)
        let expectation = self.expectationWithDescription("Callback invoked")

        requestsStatus.addRequest(.Giphy, path: "/foo/bar1", method:.MethodGET, callback: {
            responseData,responseURLResponse,responseError in
            XCTAssertEqual(data, responseData)
            XCTAssertEqual(error, responseError)
            XCTAssertEqual(HTTPResponse, responseURLResponse)
            expectation.fulfill()
            
            return
        })

        
        // when
        let request : ZMTransportRequest? = self.sut.nextRequest()
        if let request = request {
            request.completeWithResponse(response)
        }
        
        // then
        self.spinMainQueueWithTimeout(0.2)
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
    }
    
    func testThatItMakesTheRequestExpireAfter20Seconds() {
        
        // given
        let ExpectedDelay : NSTimeInterval = 20
        requestsStatus.addRequest(.Giphy, path: "/foo/bar1", method:.MethodGET, callback: {_,_,_ in return})
        
        // when
        let request : ZMTransportRequest? = self.sut.nextRequest()
        
        // then
        if let request = request {
            XCTAssertNotNil(request.expirationDate)
            let delay = request.expirationDate.timeIntervalSinceNow
            XCTAssertLessThanOrEqual(delay, ExpectedDelay)
            XCTAssertGreaterThanOrEqual(delay, ExpectedDelay - 3)
            
        } else {
            XCTFail("Empty request")
        }
    }
}
