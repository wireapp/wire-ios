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

class ZiphyPaginationControllerTests: ZiphyTestCase {

    var ziphyClient:ZiphyClient!
    var paginationController:ZiphyPaginationController!
    
    override func setUp() {
        super.setUp()
        
        ZiphyClient.logLevel = ZiphyLogLevel.Verbose
        self.ziphyClient = ZiphyClient(host:"api.giphy.com", requester:self.defaultRequester)
        self.paginationController = ZiphyPaginationController()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func fetchBlockForSearch(paginationController:ZiphyPaginationController, searchTerm:String, resultsLimit:Int) -> FetchBlock {
        
        let fetchBlock:FetchBlock = { [weak paginationController, weak self](offset) in
            
            self?.ziphyClient.search(term: searchTerm, resultsLimit: resultsLimit, offset: offset, onCompletion: { (success, ziphs, error) -> () in
                paginationController?.updatePagination(success, ziphs: ziphs, error: error)
            })
        }
        
        return fetchBlock
    }

    func testThatFistPageIsFetched() {
        // This is an example of a functional test case.
        
        let expectation = expectationWithDescription("That a page is fetched")

        let completionBlock:SuccessOrErrorCallback = { [weak paginationController](success, error) in
            
            expectation.fulfill()
            
            if (success) {
                
                let _ = paginationController?.ziphs?.first
                XCTAssertTrue(paginationController?.ziphs?.count > 0 , "Paged fetched but no ziphs")
            }
            else {
                
                XCTFail("\(error?.localizedDescription)")
            }
        }
        
        self.paginationController.fetchBlock = self.fetchBlockForSearch(paginationController, searchTerm: "cat", resultsLimit: 25)
        self.paginationController.completionBlock = completionBlock
        
        self.paginationController.fetchNewPage()
        
        waitForExpectationsWithTimeout(10, handler:nil)
    }
    
    func testThatSeveralPagesAreFetched() {
        
        let expectation = expectationWithDescription("That several pages are fetched")
        
        self.paginationController.fetchBlock = self.fetchBlockForSearch(self.paginationController, searchTerm: "cat", resultsLimit: 25)
        self.paginationController.completionBlock = { [weak self](success, error) in
            
            if (success && self?.paginationController.totalPagesFetched < 3) {
                self?.paginationController.fetchNewPage()
            }
            else if (success && self?.paginationController.totalPagesFetched == 3) {
                expectation.fulfill()
                XCTAssertTrue(self?.paginationController.ziphs?.count == 25*3, "Did not fetch enough gifs")
            }
            else {
                expectation.fulfill()
                XCTFail("Error fetching a page")
            }
        }
        
        self.paginationController.fetchNewPage()
        
        waitForExpectationsWithTimeout(10, handler:nil)
    }
    
    func testThatFechingEndsIfNoMorePages () {
        
        let expectation = expectationWithDescription("That several pages are fetched")
        
        //There are only 13 results for this search term so this should not trigger more than 2 requests of 10 each
        self.paginationController.fetchBlock = self.fetchBlockForSearch(self.paginationController, searchTerm: "awg", resultsLimit: 10)
        self.paginationController.completionBlock = { [weak self](success, error) in
            
            if (success && self?.paginationController.totalPagesFetched < 3) {
                self?.paginationController.fetchNewPage()
            }
            else if (success && self?.paginationController.totalPagesFetched == 3) {
                expectation.fulfill()
                XCTFail("Too many fetch requests where fired.")
            }
            else if (!success) {
                expectation.fulfill()
                
                let isNoMorePagesError = error?.code == ZiphyError.NoMorePages.rawValue
                
                XCTAssertTrue(isNoMorePagesError && self?.paginationController.totalPagesFetched < 3, "Failed because of some other error")
            }
        }
        
        self.paginationController.fetchNewPage()
        
        waitForExpectationsWithTimeout(10, handler:nil)
    
    }
}
