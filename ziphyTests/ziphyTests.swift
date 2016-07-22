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
        
        ZiphyClient.logLevel = ZiphyLogLevel.Verbose
        self.ziphyClient = ZiphyClient(host:"api.giphy.com", requester:self.defaultRequester)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatSeachReturnsResults() {
        
        //Set up
        
        
        let expectation = expectationWithDescription("did return some results")
        
        self.ziphyClient.search(term:"cat", resultsLimit: 10, offset: 0) { (success, gifs, error) -> () in
            
            XCTAssert(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10) { (error) in
            
        }
    }
    
    func testThatFunkyCharsWork() {
        
        let expectation = expectationWithDescription("did return some results")
        
        self.ziphyClient.search(term:"cat\"=\"#%/<>?@\\^`{|}&:#[]@$'+;", resultsLimit: 10, offset: 0) { (success, gifs, error) -> () in
            
            XCTAssert(success)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10) { (error) in
            
        }
        
        
    }
    
    func testThatAnImageIsFetched() {
        
        let expectation = expectationWithDescription("did download an image")
        
        let imageFetcher = ZiphyImageFetcher(term: "cat", sizeLimit: 1024*1024, imageType:ZiphyImageType.Downsized, requester:self.defaultRequester)
        
        imageFetcher.nextImage { (image, ziph, error) -> () in
            
            if image != nil && ziph != nil {
                
                expectation.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(10) { (error) in
            
        }
    }
    
    func testThatNoImageIsFetchedWhenSizeLimitIsZero() {
        
        let expectation = expectationWithDescription("did not download an image")
        let imageFetcher = ZiphyImageFetcher(term:"cat", sizeLimit: 0, imageType:ZiphyImageType.Downsized, requester:self.defaultRequester)
        
        imageFetcher.nextImage { (image, ziph,  error) -> () in
            
            XCTAssertNil(image, "Returned image should be nill")
            
            if image == nil && ziph == nil {
                
                print(error?.localizedDescription)
                expectation.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(10) { (error) in
            
        }
    }
    
    func testThatNoImageIsFecthedIfSearchReturnsNoResults() {
        
        let expectation = expectationWithDescription("did not download an image")
        let imageFetcher = ZiphyImageFetcher(term: "29581298512h0nsawaowi 82251 1wjhfa wa9tru2jas fw9a29h12n2nsaf 0242145",
            sizeLimit: 1024*1024,
            imageType:ZiphyImageType.Downsized,
            requester:self.defaultRequester)
        
        imageFetcher.nextImage { (image, ziph, error) -> () in
            
            XCTAssertNil(image, "Returned image should be nill")
            
            if image == nil && ziph == nil {
                print(error?.localizedDescription)
                expectation.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(10) { (error) in
            
        }
    }
    
    func testThatSearchTemsWithSpacesReturnResults() {
        
        _ = GiphyRequester(apiKey:"")
        let expectation = expectationWithDescription("did download an image")
        let imageFetcher = ZiphyImageFetcher(term:"Silent Bob",
            sizeLimit: 1024*1024*3,
            resultslimit:50,
            imageType:ZiphyImageType.Downsized,
            requester:self.defaultRequester)
        
        imageFetcher.nextImage { (image, ziph, error) -> () in
            
            if image != nil && ziph != nil {
                
                expectation.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(10) { (error) in
            
        }
        
    }
    
    func testThatPaginationWorks() {
        
        let expectation = expectationWithDescription("did download an image")
        let imageFetcher = ZiphyImageFetcher(term: "funny cat",
            sizeLimit: 1024*1024,
            resultslimit:2,
            imageType:ZiphyImageType.Downsized,
            requester:self.defaultRequester)
        
        imageFetcher.nextImage { (image, ziph, error) -> () in
            
            if image != nil {
                
                imageFetcher.nextImage { (otherImage, otherZiph, error) -> () in
                    
                    if otherImage != nil  && otherZiph != nil {
                        
                        imageFetcher.nextImage { (otherOtherImage, otherOtherZiph, error) -> () in
                            
                            if otherOtherImage != nil && otherOtherZiph != nil {
                                
                                expectation.fulfill()
                            }
                        }
                    }
                }
            }
            else {
                
                print(error?.localizedDescription)
            }
        }
        
        waitForExpectationsWithTimeout(20) { (error) in
            
        }
    }
    
    func testThatAResultSetSmallerThanTheResultLimitDoesNotTriggerAdditionalPagination() {
        
        let expectation1 = expectationWithDescription("first download an image")
        let expectation2 = expectationWithDescription("did not download an image")
        var expectation1Fulfilled = false
        
        let imageFetcher = ZiphyImageFetcher(term: "mjh",
            sizeLimit: 1024*1024*3,
            resultslimit:50,
            imageType:ZiphyImageType.Downsized,
            requester:self.defaultRequester)
        
        var fetchImage : (() -> ()) = {}
        
        fetchImage = {
            imageFetcher.nextImage { (image, ziph, error) -> () in
                
                if image != nil {
                    if !expectation1Fulfilled {
                        expectation1.fulfill()
                        expectation1Fulfilled = true
                    }
                    fetchImage()
                }
                else {
                    print(error?.localizedDescription)
                    expectation2.fulfill()
                }
            }
        }
        
        fetchImage()
        
        waitForExpectationsWithTimeout(20) { (error) in
            
        }
    }
    
    func testThatRecursiveCalls() {
        
        let expectation = expectationWithDescription("did not download an image")
        let imageFetcher = ZiphyImageFetcher(term: "Silent Bob",
            sizeLimit: 1024*1024*3,
            resultslimit: 50,
            imageType:ZiphyImageType.Downsized,
            requester:self.defaultRequester)
        
        var recurse:(stopAt:Int, currentCallIndex:Int, forceStop:Bool)->() = { (_, index, _) in  return }
        
        recurse = { (stop, index, forceStop) in
            
            if forceStop {
                return
            }
            
            if index >= stop {
                expectation.fulfill()
                return
            }
            
            imageFetcher.nextImage { (otherImage, otherZiph, error) -> () in
                
                if otherImage != nil && otherZiph != nil {
                    
                    recurse(stopAt: stop, currentCallIndex: index+1, forceStop: false)
                }
                else {
                    recurse(stopAt: index+1, currentCallIndex: index+1, forceStop: true)
                }
            }
        }
        
        imageFetcher.nextImage { (imageData, otherZiph, error) -> () in
            
            if imageData != nil && otherZiph != nil {
                recurse(stopAt: 10, currentCallIndex: 1, forceStop: false)
            }
            else {
                print(error?.localizedDescription)
            }
        }
        
        waitForExpectationsWithTimeout(40) { (error) in
            
        }
    }
    
    
    func testThatARandomGifIdIsReturned() {
        
        let ziphy = ZiphyClient(host:"api.giphy.com", requester:self.defaultRequester)
        let expectation = expectationWithDescription("did return a gifID")
        
        
        ziphy.randomGif { (success, gifId, error) -> () in
            
            if success && error == nil && gifId != "" {
                expectation.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(10) { (error) in
            
        }
        
    }
    
    func testThatGifsByIdReturnsAnArray() {
        
        let ziphy = ZiphyClient(host:"api.giphy.com", requester:self.defaultRequester)
        let expectation = expectationWithDescription("did return an array")
        
        ziphy.gifsById(ids:["feqkVgjJpYtjy", "7rzbxdu0ZEXLy"]) { (success, ziphs, error) -> () in
            
            if success && error == nil && ziphs.count == 2 {
                expectation.fulfill()
            }
            else {
                print(error?.localizedDescription)
            }
        }
        
        waitForExpectationsWithTimeout(10) { (error) in
            
        }
    }
    
    func testThatARandomGifIsFetched() {
        
        let expectation = expectationWithDescription("did download an image")
        let imageFetcher = ZiphyImageFetcher(term: "", sizeLimit: 1024*1024*3, imageType:ZiphyImageType.Downsized, requester:self.defaultRequester)
        
        imageFetcher.nextImage { (image, ziph, error) -> () in
            
            if image != nil && ziph != nil {
                expectation.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(10) { (error) in
            
        }
    }
    
}
