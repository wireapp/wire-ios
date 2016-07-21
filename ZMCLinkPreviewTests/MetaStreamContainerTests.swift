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

class MetaStreamContainerTests: XCTestCase {

    var sut: MetaStreamContainer! = nil

    override func setUp() {
        super.setUp()
        sut = MetaStreamContainer()
    }

    func testThatItAppendsBytes() {
        // given
        let first = "First".utf8Data
        let second = "Second".utf8Data

        // when
        sut.addData(first)

        // then
        XCTAssertEqual(sut.bytes, first)
        XCTAssertEqual(sut.stringContent, "First")

        // when
        sut.addData(second)

        // then
        let expected = "FirstSecond".utf8Data
        XCTAssertEqual(sut.bytes, expected)
        XCTAssertEqual(sut.stringContent, "FirstSecond")
    }

    func testThatItSets_rechaedEndOfHead_WhenDataContainsHead_Lowercase() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</head>")
    }
    
    func testThatItSets_rechaedEndOfHead_WhenDataContainsHead_Capitalized() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</Head>")
    }
    
    func testThatItSets_rechaedEndOfHead_WhenDataContainsHead_Uppercase() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</HEAD>")
    }
    
    func testThatItSets_rechaedEndOfHead_WhenDataContainsHead_WithSpaces() {
        assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead("</head >", shouldUpdate: false)
    }
    
    func testThatItExtractsTheHead_Twitter() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.twitterData())
    }
    
    func testThatItExtractsTheHead_TwitterWithImages() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.twitterDataWithImages())
    }
    
    func testThatItExtractsTheHead_Verge() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.vergeData())
    }
    
    func testThatItExtractsTheHead_Foursqaure() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.foursqaureData())
    }
    
    func testThatItExtractsTheHead_YouTube() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.youtubeData())
    }
    
    func testThatItExtractsTheHead_Guardian() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.guardianData())
    }
    
    func testThatItExtractsTheHead_Instagram() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.instagramData())
    }
    
    func testThatItExtractsTheHead_NYTimes() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.nytimesData())
    }
    
    func testThatItExtractsTheHead_Vimeo() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.vimeoData())
    }
    
    func testThatItExtractsTheHead_WashingtonPost() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.washingtonPostData())
    }
    
    func testThatItExtractsTheHead_Medium() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.mediumData())
    }
    
    func testThatItExtractsTheHead_Wire() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.wireData())
    }

    func testThatItExtractsTheHead_Polygon() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.polygonData())
    }

    func testThatItExtractsTheHead_iTunes() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.iTunesData())
    }
    
    func testThatItExtractsTheHead_yahooSports() {
        assertThatItExtractsTheCorrectHead(OpenGraphMockDataProvider.yahooSports())
    }
    
    // MARK: - Helper
    
    func assertThatItExtractsTheCorrectHead(mockData: OpenGraphMockData, line: UInt = #line) {
        // when
        sut.addData(mockData.full.utf8Data)
        
        // then
        XCTAssertTrue(sut.reachedEndOfHead)
        guard let head = sut.head else { return XCTFail("Head was nil", line: line) }
        XCTAssertEqual(head, mockData.head, line: line)
    }
    
    func assertThatItUpdatesReachedEndOfHeadWhenItReceivedHead(head: String, shouldUpdate: Bool = true, line: UInt = #line) {
        // given
        let first = "First".utf8Data
        let second = "Head".utf8Data
        let fourth = "End".utf8Data
        
        // when & then
        sut.addData(first)
        XCTAssertFalse(sut.reachedEndOfHead, line: line)
        
        // when & then
        sut.addData(second)
        XCTAssertFalse(sut.reachedEndOfHead, line: line)
        
        // when & then
        sut.addData(head.utf8Data)
        XCTAssertEqual(sut.reachedEndOfHead, shouldUpdate, line: line)
        
        // when & then
        sut.addData(fourth)
        XCTAssertEqual(sut.reachedEndOfHead, shouldUpdate, line: line)
    }

}

extension String {
    var utf8Data: NSData {
        return dataUsingEncoding(NSUTF8StringEncoding)!
    }
}
