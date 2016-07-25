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

    func testThatItParsesSampleDataTwitter_1_chunk() {
        let mockData = OpenGraphMockDataProvider.twitterData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }

    func testThatItParsesSampleDataTwitter_2_chunks() {
        let mockData = OpenGraphMockDataProvider.twitterData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 2)
    }

    func testThatItParsesSampleDataTwitter_3_chunks() {
        let mockData = OpenGraphMockDataProvider.twitterData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 3)
    }
    
    func testThatItParsesSampleDataTwitterWithImages() {
        let mockData = OpenGraphMockDataProvider.twitterDataWithImages()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }
    
    func testThatItParsesSampleDataTheVerge_4_chunks() {
        let mockData = OpenGraphMockDataProvider.vergeData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 4)
    }
    
    func testThatItParsesSampleDataWashingtonPost_5_chunks() {
        let mockData = OpenGraphMockDataProvider.washingtonPostData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 5)
    }
    
    func testThatItParsesSampleDataYouTube() {
        let mockData = OpenGraphMockDataProvider.youtubeData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }
    
    func testThatItParsesSampleDataGuardian() {
        let mockData = OpenGraphMockDataProvider.guardianData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }
    
    func testThatItParsesSampleDataInstagram() {
        let mockData = OpenGraphMockDataProvider.instagramData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }
    
    func testThatItParsesSampleDataVimeo() {
        let mockData = OpenGraphMockDataProvider.vimeoData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }
    
    func testThatItParsesSampleDataFoursqaure() {
        let mockData = OpenGraphMockDataProvider.foursqaureData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }
    
    func testThatItParsesSampleDataMedium() {
        let mockData = OpenGraphMockDataProvider.mediumData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }
    
    func testThatItParsesSampleDataWire() {
        let mockData = OpenGraphMockDataProvider.wireData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }
    
    func testThatItParsesSampleDataPolygon() {
        let mockData = OpenGraphMockDataProvider.polygonData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }

    func testThatItParsesSampleDataiTunes() {
        let mockData = OpenGraphMockDataProvider.iTunesData()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }

    func testThatItParsesSampleDataiTunesWithoutTitle_6_chunks() {
        let mockData = OpenGraphMockDataProvider.iTunesDataWithoutTitle()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 6)
    }
    
    func testThatItParsesSampleDataYahooSports() {
        let mockData = OpenGraphMockDataProvider.yahooSports()
        assertThatItCanParseSampleData(mockData, numberOfChunks: 1)
    }
    
    func assertThatItCanParseSampleData(mockData: OpenGraphMockData, numberOfChunks: Int, line: UInt = #line) {

        let expection = expectationWithDescription("It should parse the data")
        let task = MockURLSessionDataTask()
        let url = NSURL(string:mockData.urlString)!
        task.mockOriginalRequest = NSURLRequest(URL: url)
        let session = IntegrationTestSession(numberOfChunks: numberOfChunks, mockData: mockData, dataTask: task)
        let sut = PreviewDownloader(resultsQueue: .mainQueue(), parsingQueue: .mainQueue(), urlSession: session)

        var result: OpenGraphData?
        sut.requestOpenGraphData(fromURL: url) { data in
            result = data
            expection.fulfill()
        }

        session.responseParts().forEach {
            sut.processReceivedData($0, forTask: task, withIdentifier: task.taskIdentifier)
        }

        waitForExpectationsWithTimeout(0.5, handler: nil)
        XCTAssertEqual(result, mockData.expected, line: line)
    }

}

