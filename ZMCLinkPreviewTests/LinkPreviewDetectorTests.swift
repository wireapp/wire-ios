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
@testable import ZMCLinkPreview



class LinkPreviewDetectorTests: XCTestCase {
    
    var sut: LinkPreviewDetector!
    var mockImageTask: MockURLSessionDataTask!
    var imageDownloader: MockImageDownloader!
    var previewDownloader: MockPreviewDownloader!
    
    override func setUp() {
        super.setUp()
        mockImageTask = MockURLSessionDataTask()
        previewDownloader = MockPreviewDownloader()
        imageDownloader = MockImageDownloader()
        sut = LinkPreviewDetector(
            previewDownloader: previewDownloader,
            imageDownloader: imageDownloader,
            resultsQueue: .mainQueue(),
            workerQueue: .mainQueue()
        )
    }
    
    func testThatItReturnsTheDetectedLinkAndOffsetInAText() {
        // given
        let text = "This is a sample containig a link: www.example.com"
        
        // when
        let links = sut.containedLinks(inText: text)
        
        // then
        XCTAssertEqual(links.count, 1)
        let linkWithOffset = links.first
        XCTAssertEqual(linkWithOffset?.URL, NSURL(string: "http://www.example.com")!)
        XCTAssertEqual(linkWithOffset?.range.location, 35)
    }
    
    func testThatItReturnsTheURLsAndOffsetsOfMultipleLinksInAText() {
        // given
        let text = "This is a sample containig a link: www.example.com"
        
        // when
        let links = sut.containedLinks(inText: text)
        
        // then
        XCTAssertEqual(links.count, 1)
        let linkWithOffset = links.first
        XCTAssertEqual(linkWithOffset?.URL, NSURL(string: "http://www.example.com")!)
        XCTAssertEqual(linkWithOffset?.range.location, 35)
    }
    
    func testThatItDoesNotReturnALinkIfThereIsNoneInAText() {
        // given
        let text = "First: www.example.com/first and second: www.example.com/second"
        
        // when
        let links = sut.containedLinks(inText: text)
        
        // then
        XCTAssertEqual(links.count, 2)
        let (first, second) = (links.first, links.last)
        XCTAssertEqual(first?.URL, NSURL(string: "http://www.example.com/first")!)
        XCTAssertEqual(first?.range.location, 7)
        XCTAssertEqual(second?.URL, NSURL(string: "http://www.example.com/second")!)
        XCTAssertEqual(second?.range.location, 41)
    }
    
    func testThatItCallsTheCompletionWithAnEmptyArrayWhenThereIsNoLinkInTheText() {
        // given
        let text = "This is a sample containig no link"
        let expectation = expectationWithDescription("It calls the completion closure")

        // when
        var result = [LinkPreview]()
        sut.downloadLinkPreviews(inText: text) {
            result = $0
            expectation.fulfill()
        }

        // then
        waitForExpectationsWithTimeout(0.2, handler: nil)
        XCTAssertEqual(previewDownloader.requestOpenGraphDataCallCount, 0)
        XCTAssertEqual(result, [])
    }
    
    func testThatItRequestsToDownloadTheOpenGraphDataWhenThereIsALink() {
        // given
        let text = "This is a sample containig a link: www.example.com"
        
        // when
        sut.downloadLinkPreviews(inText: text) { _ in }
        
        // then
        XCTAssertEqual(previewDownloader.requestOpenGraphDataCallCount, 1)
        XCTAssertEqual(previewDownloader.requestOpenGraphDataURLs, [NSURL(string: "http://www.example.com")!])
    }
    
    func testThatItReturnsAnEmptyArrayIfThePreviewDownloaderReturnsANilOpenGraphData() {
        // given
        let text = "This is a sample containig a link: www.example.com"
        let expectation = expectationWithDescription("It calls the completion closure")
        
        // when
        var result = [LinkPreview]()
        sut.downloadLinkPreviews(inText: text) {
            result = $0
            expectation.fulfill()
        }
        
        // then
        waitForExpectationsWithTimeout(0.2, handler: nil)
        XCTAssertEqual(previewDownloader.requestOpenGraphDataCallCount, 1)
        XCTAssertEqual(previewDownloader.requestOpenGraphDataURLs, [NSURL(string: "http://www.example.com")!])
        XCTAssertEqual(result, [])
    }
    
    func testThatItRequestsToDownloadTheImageDataWhenThereIsALinkAndThePreviewDownloaderReturnsOpenGraphData() {
        // given
        let text = "This is a sample containig a link: example.com"
        let expectation = expectationWithDescription("It calls the completion closure")
        let openGraphData = OpenGraphMockDataProvider.nytimesData().expected!
        previewDownloader.mockOpenGraphData = openGraphData
        
        // when
        var result = [LinkPreview]()
        sut.downloadLinkPreviews(inText: text) {
            result = $0
            expectation.fulfill()
        }
        
        // then
        waitForExpectationsWithTimeout(0.2, handler: nil)
        XCTAssertEqual(imageDownloader.downloadImageCallCount, 1)
        XCTAssertEqual(result.first?.imageURLs.first?.absoluteString, openGraphData.imageUrls.first)
        guard let article = result.first as? Article else { return XCTFail("Wrong preview type") }
        XCTAssertEqual(article.permanentURL?.absoluteString, openGraphData.url)
        XCTAssertEqual(article.originalURLString, "example.com")
        XCTAssertEqual(article.characterOffsetInText, 35)
        XCTAssertTrue(article.imageData.isEmpty)
    }
    
    func testThatItRequestsToDownloadOnlyTheFirstImageDataWhenThereIsALinkAndThePreviewDownloaderReturnsOpenGraphData() {
        // given
        let text = "This is a sample containig a link: www.example.com"
        let expectation = expectationWithDescription("It calls the completion closure")
        let openGraphData = OpenGraphMockDataProvider.twitterDataWithImages().expected!
        previewDownloader.mockOpenGraphData = openGraphData
        
        // when
        var result = [LinkPreview]()
        sut.downloadLinkPreviews(inText: text) {
            result = $0
            expectation.fulfill()
        }
        
        // then
        waitForExpectationsWithTimeout(0.2, handler: nil)
        XCTAssertEqual(imageDownloader.downloadImageCallCount, 1)
        XCTAssertEqual(imageDownloader.downloadImagesCallCount, 0)

        guard let twitterStatus = result.first as? TwitterStatus else { return XCTFail("Wrong preview type") }
        XCTAssertEqual(twitterStatus.imageURLs.count, 4)
        XCTAssertEqual(twitterStatus.imageURLs.map { $0.absoluteString }, openGraphData.imageUrls)
        XCTAssertEqual(twitterStatus.characterOffsetInText, 35)
        XCTAssertEqual(twitterStatus.permanentURL?.absoluteString, openGraphData.url)
        XCTAssertEqual(twitterStatus.originalURLString, "www.example.com")
        XCTAssertTrue(twitterStatus.imageData.isEmpty)
    }
    
    func testThatItCallsTheCompletionClosureOnTheResultsQueue_LinkInText_NoData() {
        let text = "This is a sample containig a link: www.example.com"
        assertThatItCallsTheCompletionClosureOnTheResultsQueue(withText: text)
    }
    
    func testThatItCallsTheCompletionClosureOnTheResultsQueue_LinkInText_Data() {
        let text = "This is a sample containig a link: www.example.com"
        previewDownloader.mockOpenGraphData = OpenGraphMockDataProvider.guardianData().expected!
        assertThatItCallsTheCompletionClosureOnTheResultsQueue(withText: text)
    }
    
    func testThatItCallsTheCompletionClosureOnTheResultsQueue_NoLinkInText() {
        let text = "This is a sample not containig a link"
        assertThatItCallsTheCompletionClosureOnTheResultsQueue(withText: text)
    }
    
    func testThatItImmediatelyCallsTheCompletionHandlerForHostsOnTheBlacklist() {
        // given
        let url = "www.soundcloud.com"
        let expectation = expectationWithDescription("It calls the completion closure")
        var result = [LinkPreview]()
        
        // when
        sut.downloadLinkPreviews(inText: url) {
            result = $0
            expectation.fulfill()
        }
        
        // then
        waitForExpectationsWithTimeout(0.2, handler: nil)
        XCTAssertTrue(result.isEmpty)
    }
    
    func assertThatItCallsTheCompletionClosureOnTheResultsQueue(withText text: String, line: UInt = #line) {
        // given
        let queue = NSOperationQueue()
        sut = LinkPreviewDetector(previewDownloader: previewDownloader, imageDownloader: imageDownloader, resultsQueue: queue, workerQueue: queue)
        let expectation = expectationWithDescription("It calls the completion closure")
        
        // when
        sut.downloadLinkPreviews(inText: text) { _ in
            XCTAssertEqual(NSOperationQueue.currentQueue(), queue, line: line)
            expectation.fulfill()
        }
        
        // then
        waitForExpectationsWithTimeout(0.2, handler: nil)
    }
    
}