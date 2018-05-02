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
        
        ZiphyClient.logLevel = ZiphyLogLevel.verbose
        self.ziphyClient = ZiphyClient(host:"api.giphy.com", requester:self.defaultRequester)
        self.paginationController = ZiphyPaginationController()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func fetchBlockForSearch(_ paginationController:ZiphyPaginationController, searchTerm:String, resultsLimit:Int) -> FetchBlock {
        
        let fetchBlock:FetchBlock = { [weak paginationController, weak self](offset) in
            
            self?.ziphyClient.search(term: searchTerm, resultsLimit: resultsLimit, offset: offset, onCompletion: { (success, ziphs, error) -> () in
                paginationController?.updatePagination(success, ziphs: ziphs, error: error)
            })
        }
        
        return fetchBlock
    }

    func testThatFistPageIsFetched() {
        // This is an example of a functional test case.
        
        let expectation = self.expectation(description: "That a page is fetched")

        let completionBlock:SuccessOrErrorCallback = { [weak paginationController](success, ziphs, error) in
            
            expectation.fulfill()
            
            if (success) {
                XCTAssertTrue(ziphs.count > 0 , "Paged fetched but no ziphs")
            }
            else {
                
                XCTFail(String(describing: error?.localizedDescription))
            }
        }
        
        self.paginationController.fetchBlock = self.fetchBlockForSearch(paginationController, searchTerm: "cat", resultsLimit: 25)
        self.paginationController.completionBlock = completionBlock
        
        _ = self.paginationController.fetchNewPage()
        
        waitForExpectations(timeout: 10, handler:nil)
    }
    
    func testThatSeveralPagesAreFetched() {
        
        let expectation = self.expectation(description: "That several pages are fetched")
        
        self.paginationController.fetchBlock = self.fetchBlockForSearch(self.paginationController, searchTerm: "cat", resultsLimit: 25)
        self.paginationController.completionBlock = { [weak self](success, ziphs, error) in
            
            if (success && (self?.paginationController.totalPagesFetched)! < 3) {
                _ = self?.paginationController.fetchNewPage()
            }
            else if (success && self?.paginationController.totalPagesFetched == 3) {
                expectation.fulfill()
                XCTAssertTrue(ziphs.count == 25*3, "Did not fetch enough gifs")
            }
            else {
                expectation.fulfill()
                XCTFail("Error fetching a page")
            }
        }
        
        _ = self.paginationController.fetchNewPage()
        
        waitForExpectations(timeout: 10, handler:nil)
    }
    
    func testThatFechingEndsIfNoMorePages () {
        
        let expectation = self.expectation(description: "That several pages are fetched")
        
        self.paginationController.fetchBlock = self.fetchBlockForSearch(self.paginationController, searchTerm: "awg", resultsLimit: 10)
        self.paginationController.completionBlock = { [weak self](success, ziphs, error) in
            
            if (success) {
                _ = self?.paginationController.fetchNewPage()
            }
            else if (!success) {
                expectation.fulfill()

                let isNoMorePagesError = (error as NSError?)?.code == ZiphyError.noMorePages.rawValue
                
                XCTAssertTrue(isNoMorePagesError, "Failed because of some other error")
            }
        }
        
        _ = self.paginationController.fetchNewPage()
        
        waitForExpectations(timeout: 10, handler:nil)
    
    }
}
