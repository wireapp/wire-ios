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

class IntegrationTests: XCTestCase {

    func testThatItParsesSampleDataTwitter() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Twitter", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.twitterData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataTwitterWithImages() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 4, type: "article", siteNameString: "Twitter", userGeneratedImage: true, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.twitterDataWithImages()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataTheVerge() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "The Verge", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.vergeData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataWashington() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Washington Post", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.washingtonPostData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataYouTube() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "video", siteNameString: "YouTube", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.youtubeData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataGuardian() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "the Guardian", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.guardianData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataInstagram() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "instapp:photo", siteNameString: "Instagram", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.instagramData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataVimeo() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "video", siteNameString: "Vimeo", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.vimeoData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataFoursquare() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 4, type: "playfoursquare:venue", siteNameString: "Foursquare", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: true)
        let mockData = OpenGraphMockDataProvider.foursqaureData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataMedium() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Medium", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.mediumData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataWire() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "website", siteNameString: nil, userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.wireData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataPolygon() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: "Polygon", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.polygonData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleDataiTunes() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "music.album", siteNameString: "Apple Music", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.iTunesData()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }

    func testThatItParsesSampleDataiTunesWithoutTitle() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "music.album", siteNameString: "Apple Music", userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.iTunesDataWithoutTitle()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    func testThatItParsesSampleDataYahooSports() {
        let expectation = OpenGraphDataExpectation(numberOfImages: 1, type: "article", siteNameString: nil, userGeneratedImage: false, hasDescription: true, hasFoursquareMetaData: false)
        let mockData = OpenGraphMockDataProvider.yahooSports()
        assertThatItCanParseSampleData(mockData, expected: expectation)
    }
    
    struct OpenGraphDataExpectation {
        let numberOfImages: Int
        let type: String?
        let siteNameString: String?
        let userGeneratedImage: Bool
        let hasDescription: Bool
        let hasFoursquareMetaData: Bool
    }
    
    func assertThatItCanParseSampleData(_ mockData: OpenGraphMockData, expected: OpenGraphDataExpectation, line: UInt = #line) {

        // given
        let completionExpectation = expectation(description: "It should parse the data")
        let sut = PreviewDownloader(resultsQueue: .main, parsingQueue: .main)

        // when
        var result: OpenGraphData?
        sut.requestOpenGraphData(fromURL: URL(string: mockData.urlString)!) { data in
            result = data
            XCTAssertNotNil(data)
            completionExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
        guard let data = result else {
            return XCTFail("Could not extract open graph data from \(mockData.urlString)", line: line)
        }
        
        // then
        XCTAssertEqual(data.content != nil, expected.hasDescription, line: line)
        XCTAssertEqual(data.foursquareMetaData != nil, expected.hasFoursquareMetaData, line: line)
        XCTAssertEqual(data.type, expected.type, line: line)
        XCTAssertEqual(data.siteNameString, expected.siteNameString, line: line)
        XCTAssertEqual(data.userGeneratedImage, expected.userGeneratedImage, line: line)
        XCTAssertTrue(data.imageUrls.count == expected.numberOfImages, line: line)
    }
    
}
