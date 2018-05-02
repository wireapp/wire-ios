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
import ziphy




class ziphyTests: ZiphyTestCase {
    
    var ziphyClient:ZiphyClient!
    
    override func setUp() {
        super.setUp()
        
        ZiphyClient.logLevel = ZiphyLogLevel.verbose
        self.ziphyClient = ZiphyClient(host:"api.giphy.com", requester:self.defaultRequester)
    }
    
    func testThatSeachReturnsResults() {
        
        //Set up
        

        let expectation = self.expectation(description: "did return some results")
        
        _ = self.ziphyClient.search(term:"cat", resultsLimit: 10, offset: 0) { (success, gifs, error) -> () in
            
            XCTAssert(success)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { (error) in

        }
    }
    
    func testThatTrendingReturnsResults() {
        
        //Set up
        
        
        let expectation = self.expectation(description: "did return some results")
        
        _ = self.ziphyClient.trending(resultsLimit: 10, offset: 0) { (success, gifs, error) -> () in
            XCTAssert(success)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { (error) in
            
        }
    }
    
    
    func testThatFunkyCharsWork() {
        
        let expectation = self.expectation(description: "did return some results")
        
        _ = self.ziphyClient.search(term:"cat\"=\"#%/<>?@\\^`{|}&:#[]@$'+;", resultsLimit: 10, offset: 0) { (success, gifs, error) -> () in
            
            XCTAssert(success)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20) { (error) in
            
        }
        
        
    }
    
    func testThatARandomGifIdIsReturned() {
        
        let ziphy = ZiphyClient(host:"api.giphy.com", requester:self.defaultRequester)
        let expectation = self.expectation(description: "did return a gifID")
        
        
        ziphy.randomGif { (success, gifId, error) -> () in
            
            if success && error == nil && gifId != "" {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 20) { (error) in

        }
        
    }
    
    func testThatGifsByIdReturnsAnArray() {
        
        let ziphy = ZiphyClient(host:"api.giphy.com", requester:self.defaultRequester)
        let expectation = self.expectation(description: "did return an array")
        
        ziphy.gifsById(ids:["feqkVgjJpYtjy", "7rzbxdu0ZEXLy"]) { (success, ziphs, error) -> () in
            
            if success && error == nil && ziphs.count == 2 {
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 20) { (error) in
            
        }
    }    
}
