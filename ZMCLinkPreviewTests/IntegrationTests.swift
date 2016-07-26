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

class IntegrationTests: XCTestCase {

    func testThatItParsesSampleDataTwitter() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Twitter", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.twitterData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataTwitterWithImages() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 4, type: "article", siteNameString: "Twitter", userGeneratedImage: true, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.twitterDataWithImages()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataTheVerge() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "The Verge", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.vergeData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataWashington() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Washington Post", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.washingtonPostData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataYouTube() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "video", siteNameString: "YouTube", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.youtubeData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataGuardian() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "the Guardian", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.guardianData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataInstagram() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "instapp:photo", siteNameString: "Instagram", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.instagramData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataVimeo() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "video", siteNameString: "Vimeo", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.vimeoData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataFoursquare() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 4, type: "playfoursquare:venue", siteNameString: "Foursquare", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: true)
        let mockData = OpenGraphMockDataProvider.foursqaureData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataMedium() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Medium", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.mediumData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataWire() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "website", siteNameString: nil, userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.wireData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataPolygon() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "website", siteNameString: "Polygon", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.polygonData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }

    func testThatItParsesSampleDataiTunes() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "website", siteNameString: "iTunes", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.iTunesData()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }

    func testThatItParsesSampleDataiTunesWithoutTitle() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "website", siteNameString: "iTunes", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.iTunesDataWithoutTitle()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    func testThatItParsesSampleDataYahooSports() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Yahoo Sport", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.yahooSports()
        assertThatItCanParseSampleData(mockData, expectation: expectation)
    }
    
    struct OpenGraphDataExpectation {
        let numberOfImages: Int
        let type: String?
        let siteNameString: String?
        let userGeneratedImage: Bool
        let hasDescription: Bool
        let hasFoursquareMetaData: Bool
    }
    
    func assertThatItCanParseSampleData(mockData: OpenGraphMockData, expectation: OpenGraphDataExpectation, line: UInt = #line) {

        // given
        let expection = expectationWithDescription("It should parse the data")
        let sut = PreviewDownloader(resultsQueue: .mainQueue(), parsingQueue: .mainQueue())

        // when
        var result: OpenGraphData?
        sut.requestOpenGraphData(fromURL: NSURL(string: mockData.urlString)!) { data in
            result = data
            if (data != nil) {
                expection.fulfill()
            }
        }

        waitForExpectationsWithTimeout(10, handler: nil)
        
        guard let data = result else {
            return XCTFail("Could not extract open graph data from \(mockData.urlString)")
        }
        
        // then
        XCTAssertEqual(data.description != nil, expectation.hasDescription)
        XCTAssertEqual(data.foursquareMetaData != nil, expectation.hasFoursquareMetaData)
        XCTAssertEqual(data.type, expectation.type)
        XCTAssertEqual(data.siteNameString, expectation.siteNameString)
        XCTAssertEqual(data.userGeneratedImage, expectation.userGeneratedImage)
        XCTAssertTrue(data.imageUrls.count == expectation.numberOfImages)
    }
    
}
