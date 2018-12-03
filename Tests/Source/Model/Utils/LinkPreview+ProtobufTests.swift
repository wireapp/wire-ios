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
import WireDataModel
import WireLinkPreview

class LinkPreview_ProtobufTests: XCTestCase {

    func testThatItCreatesAValidArticle_OldStyleProtos() {
        // given
        let builder = ZMLinkPreview.builder()!
        builder.setUrlOffset(42)
        builder.setUrl("www.example.com/original")
        builder.setArticle(.article(
            withPermanentURL: "www.example.com/permanent",
            title: "title",
            summary: "summary",
            imageAsset: nil
            )
        )
        
        // when
        let protos = builder.build()!
        let preview = ArticleMetadata(protocolBuffer: protos)
        
        // then
        XCTAssertEqual(preview.title, "title")
        XCTAssertEqual(preview.summary, "summary")
        XCTAssertEqual(preview.permanentURL?.absoluteString, "www.example.com/permanent")
        XCTAssertEqual(preview.originalURLString, "www.example.com/original")
        XCTAssertEqual(preview.characterOffsetInText, 42)
        
        // when
        let buffer = preview.protocolBuffer
        
        // then
        XCTAssertEqual(buffer.title, "title")
        XCTAssertEqual(buffer.article.title, "title")
        XCTAssertEqual(buffer.summary, "summary")
        XCTAssertEqual(buffer.article.summary, "summary")
        XCTAssertEqual(buffer.permanentUrl, "www.example.com/permanent")
        XCTAssertEqual(buffer.article.permanentUrl, "www.example.com/permanent")
        XCTAssertEqual(buffer.url, "www.example.com/original")
        XCTAssertEqual(buffer.urlOffset, 42)
    }
    
    func testThatItCreatesAValidArticle_NewStyleProtos() {
        // given
        let builder = ZMLinkPreview.builder()!
        builder.setUrlOffset(42)
        builder.setUrl("www.example.com/original")
        builder.setTitle("title")
        builder.setSummary("summary")
        builder.setPermanentUrl("www.example.com/permanent")
        
        // when
        let protos = builder.build()!
        let preview = ArticleMetadata(protocolBuffer: protos)
        
        // then
        XCTAssertEqual(preview.title, "title")
        XCTAssertEqual(preview.summary, "summary")
        XCTAssertEqual(preview.permanentURL?.absoluteString, "www.example.com/permanent")
        XCTAssertEqual(preview.originalURLString, "www.example.com/original")
        XCTAssertEqual(preview.characterOffsetInText, 42)
        
        // when
        let buffer = preview.protocolBuffer
        
        // then
        XCTAssertEqual(buffer.title, "title")
        XCTAssertEqual(buffer.article.title, "title")
        XCTAssertEqual(buffer.summary, "summary")
        XCTAssertEqual(buffer.article.summary, "summary")
        XCTAssertEqual(buffer.permanentUrl, "www.example.com/permanent")
        XCTAssertEqual(buffer.article.permanentUrl, "www.example.com/permanent")
        XCTAssertEqual(buffer.url, "www.example.com/original")
        XCTAssertEqual(buffer.urlOffset, 42)
    }
    
    func testThatItCreatesAValidArticleWithTweet_NewStyle() {
        // given
        let builder = ZMLinkPreview.builder()!
        builder.setUrlOffset(42)
        builder.setUrl("www.example.com/original")
        builder.setTitle("title")
        builder.setPermanentUrl("www.example.com/permanent")
        builder.setTweet(.tweet(withAuthor: "author", username: "username"))
        
        // when
        let protos = builder.build()!
        let preview = TwitterStatusMetadata(protocolBuffer: protos)
        
        // then
        XCTAssertEqual(preview.message, "title")
        XCTAssertEqual(preview.permanentURL?.absoluteString, "www.example.com/permanent")
        XCTAssertEqual(preview.originalURLString, "www.example.com/original")
        XCTAssertEqual(preview.characterOffsetInText, 42)
        XCTAssertEqual(preview.author, "author")
        XCTAssertEqual(preview.username, "username")
        
        // when
        let buffer = preview.protocolBuffer
        
        // then
        XCTAssertEqual(buffer.title, "title")
        XCTAssertEqual(buffer.article.title, "title")
        XCTAssertFalse(buffer.hasSummary())
        XCTAssertFalse(buffer.article.hasSummary())
        XCTAssertEqual(buffer.permanentUrl, "www.example.com/permanent")
        XCTAssertEqual(buffer.article.permanentUrl, "www.example.com/permanent")
        XCTAssertEqual(buffer.url, "www.example.com/original")
        XCTAssertEqual(buffer.urlOffset, 42)
        
        XCTAssertEqual(buffer.tweet.author, "author")
        XCTAssertEqual(buffer.tweet.username, "username")
    }
    
}
