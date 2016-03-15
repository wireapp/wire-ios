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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import XCTest
import zmessaging

public class BaseAssetDirectoryTest : XCTestCase {
    
    /// Files in cache at the beginning of the test
    var filesInCacheAtSetUp : Set<NSURL> = Set()
    
    /// List of files created by the test
    var createdFilesInCache : Set<NSURL> {
        return (MessagingTest.filesInCache() as! Set<NSURL>).subtract(self.filesInCacheAtSetUp)
    }
    
    /// Generates unique test data in a deterministic way
    func testData() -> NSData {
        return NSData.secureRandomDataOfLength(2000);
    }
    
    override public func setUp() {
        super.setUp()
        self.filesInCacheAtSetUp = MessagingTest.filesInCache() as! Set<NSURL>
    }
}



class AssetDirectoryTests: BaseAssetDirectoryTest {
    
    func testThatStoringAndRetrievingAssetsWithDifferentOptionsRetrievesTheRightData() {
        
        // given
        let sut = AssetDirectory()
        let msg1 = NSUUID.createUUID()
        let msg2 = NSUUID.createUUID()
        let msg1_full_enc = "msg1_full_enc".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg2_full_enc = "msg2_full_enc".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg1_prev_enc = "msg1_prev_enc".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg2_prev_enc = "msg2_prev_enc".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg1_full = "msg1_full".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg2_full = "msg2_full".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg1_prev = "msg1_prev".dataUsingEncoding(NSUTF8StringEncoding)!
        let msg2_prev = "msg2_prev".dataUsingEncoding(NSUTF8StringEncoding)!
        
        sut.storeAssetData(msg1, format: .Medium, encrypted: true, data: msg1_full_enc)
        sut.storeAssetData(msg2, format: .Medium, encrypted: true, data: msg2_full_enc)
        sut.storeAssetData(msg1, format: .Preview, encrypted: true, data: msg1_prev_enc)
        sut.storeAssetData(msg2, format: .Preview, encrypted: true, data: msg2_prev_enc)
        sut.storeAssetData(msg1, format: .Medium, encrypted: false, data: msg1_full)
        sut.storeAssetData(msg2, format: .Medium, encrypted: false, data: msg2_full)
        sut.storeAssetData(msg1, format: .Preview, encrypted: false, data: msg1_prev)
        sut.storeAssetData(msg2, format: .Preview, encrypted: false, data: msg2_prev)
        
        
        // then
        AssertOptionalEqual(sut.assetData(msg1, format: .Medium, encrypted: true), expression2: msg1_full_enc, "msg1_full_enc does not match")
        AssertOptionalEqual(sut.assetData(msg2, format: .Medium, encrypted: true), expression2: msg2_full_enc, "msg2_full_enc does not match")
        AssertOptionalEqual(sut.assetData(msg1, format: .Preview, encrypted: true), expression2: msg1_prev_enc, "msg1_prev_enc does not match")
        AssertOptionalEqual(sut.assetData(msg2, format: .Preview, encrypted: true), expression2: msg2_prev_enc, "msg2_prev_enc does not match")
        AssertOptionalEqual(sut.assetData(msg1, format: .Medium, encrypted: false), expression2: msg1_full, "msg1_full does not match")
        AssertOptionalEqual(sut.assetData(msg2, format: .Medium, encrypted: false), expression2: msg2_full, "msg2_full does not match")
        AssertOptionalEqual(sut.assetData(msg1, format: .Preview, encrypted: false), expression2: msg1_prev, "msg1_prev does not match")
        AssertOptionalEqual(sut.assetData(msg2, format: .Preview, encrypted: false), expression2: msg2_prev, "msg2_prev does not match")
        
    }
    
    func testThatRetrievingMissingAssetsReturnsNil() {
        
        // given
        let sut = AssetDirectory()
        sut.storeAssetData(NSUUID.createUUID(), format: .Medium, encrypted: false, data: testData())
        
        // when
        let data = sut.assetData(NSUUID.createUUID(), format: .Medium, encrypted: false)
        
        // then
        XCTAssertNil(data)
    }
    
    func testThatItCreatesFilesInCacheWhenStoring() {
        
        // given
        let sut = AssetDirectory()
        
        // when
        sut.storeAssetData(NSUUID.createUUID(), format: .Medium, encrypted: false, data: testData())
        sut.storeAssetData(NSUUID.createUUID(), format: .Medium, encrypted: false, data: testData())
        sut.storeAssetData(NSUUID.createUUID(), format: .Medium, encrypted: false, data: testData())
        
        // then
        XCTAssertEqual(self.createdFilesInCache.count, 3)
    }
    
    func testThatItDoesNotCreateDuplicateFilesInCacheWhenStoring() {
        
        // given
        let sut = AssetDirectory()
        let msgID = NSUUID.createUUID()
        
        // when
        sut.storeAssetData(msgID, format: .Medium, encrypted: false, data: testData())
        sut.storeAssetData(msgID, format: .Medium, encrypted: false, data: testData())
        sut.storeAssetData(msgID, format: .Medium, encrypted: false, data: testData())
        
        // then
        XCTAssertEqual(self.createdFilesInCache.count, 1)
    }
    
    func testThatAssetsAreLoadedAcrossInstances() {
        // given
        let msgID = NSUUID.createUUID()
        let data = testData()
        let sut = AssetDirectory()
        sut.storeAssetData(msgID, format: .Medium, encrypted: false, data: data)
        
        // when
        let extractedData = AssetDirectory().assetData(msgID, format: .Medium, encrypted: false)
        
        // then
        AssertOptionalEqual(extractedData, expression2: data)
    }
    
    func testThatItDeletesAnExistingAssetData() {
        
        // given
        let msgID = NSUUID.createUUID()
        let data = testData()
        let sut = AssetDirectory()
        sut.storeAssetData(msgID, format: .Medium, encrypted: false, data: data)
        
        // when
        sut.deleteAssetData(msgID, format: .Medium, encrypted: false)
        let extractedData = sut.assetData(msgID, format: .Medium, encrypted: false)
        
        // then
        XCTAssertNil(extractedData)
        XCTAssertEqual(self.createdFilesInCache.count, 0)
    }
    
    func testThatItDeletesTheRightAssetData() {
        
        // given
        let msgID = NSUUID.createUUID()
        let data = testData()
        let sut = AssetDirectory()
        sut.storeAssetData(msgID, format: .Medium, encrypted: true, data: data)
        sut.storeAssetData(msgID, format: .Medium, encrypted: false, data: data)

        // when
        sut.deleteAssetData(msgID, format: .Medium, encrypted: false) // this one exists
        sut.deleteAssetData(NSUUID.createUUID(), format: .Medium, encrypted: false) // this one doesn't exist
        let expectedNilData = sut.assetData(msgID, format: .Medium, encrypted: false)
        let expectedNotNilData = sut.assetData(msgID, format: .Medium, encrypted: true)
        
        // then
        XCTAssertNil(expectedNilData)
        AssertOptionalEqual(expectedNotNilData, expression2: data)
        XCTAssertEqual(self.createdFilesInCache.count, 1)
    }
    
}
