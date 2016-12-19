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

@testable import ZMCDataModel


class AssetColletionBatchedTests : ModelObjectsTests {
    
    var sut : AssetCollectionBatched!
    var delegate : MockAssetCollectionDelegate!
    var conversation : ZMConversation!
    
    override func setUp() {
        super.setUp()
        delegate = MockAssetCollectionDelegate()
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
    }
    
    override func tearDown() {
        delegate = nil
        if sut != nil {
            sut.tearDown()
            XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            sut = nil
        }
        super.tearDown()
    }
    
    func insertAssetMessages(count: Int) {
        var offset : TimeInterval = 0
        (0..<count).forEach{ _ in
            let message = conversation.appendMessage(withImageData: verySmallJPEGData()) as! ZMMessage
            offset = offset + 5
            message.setValue(Date().addingTimeInterval(offset), forKey: "serverTimestamp")
        }
        uiMOC.saveOrRollback()
    }
    
    func testThatItCanGetMessages_TotalMessageCountSmallerThanInitialFetchCount() {
        // given
        let totalMessageCount = AssetCollectionBatched.defaultFetchCount - 10
        XCTAssertGreaterThan(totalMessageCount, 0)
        insertAssetMessages(count: totalMessageCount)
        
        // when
        sut = AssetCollectionBatched(conversation: conversation, including: [.image], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(delegate.result, .success)
        XCTAssertEqual(delegate.messagesByFilter.count, 1)
        XCTAssertTrue(sut.doneFetching)
        
        let receivedMessageCount = delegate.messagesByFilter.first?[.image]?.count
        XCTAssertEqual(receivedMessageCount, totalMessageCount)
        
        guard let lastMessage =  delegate.messagesByFilter.last?[.image]?.last,
            let context = lastMessage.managedObjectContext else { return XCTFail() }
        XCTAssertTrue(context.zm_isUserInterfaceContext)
    }
    
    func testThatItCanGetMessages_TotalMessageCountEqualDefaultFetchCount() {
        // given
        let totalMessageCount = AssetCollectionBatched.defaultFetchCount
        insertAssetMessages(count: totalMessageCount)
        
        // when
        sut = AssetCollectionBatched(conversation: conversation, including: [.image], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(delegate.result, .success)
        XCTAssertEqual(delegate.messagesByFilter.count, 1)
        XCTAssertTrue(sut.doneFetching)
        
        let receivedMessageCount = delegate.messagesByFilter.first?[.image]?.count
        XCTAssertEqual(receivedMessageCount, totalMessageCount)
        
        guard let lastMessage =  delegate.messagesByFilter.last?[.image]?.last,
            let context = lastMessage.managedObjectContext else { return XCTFail() }
        XCTAssertTrue(context.zm_isUserInterfaceContext)
    }
    
    func testThatItCanGetMessages_TotalMessageCountGreaterThanInitialFetchCount() {
        // given
        let totalMessageCount = 2 * AssetCollectionBatched.defaultFetchCount
        insertAssetMessages(count: totalMessageCount)
        
        // when
        sut = AssetCollectionBatched(conversation: conversation, including: [.image], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        // messages were filtered in three batches
        XCTAssertEqual(delegate.result, .success)
        XCTAssertEqual(delegate.messagesByFilter.count, 2)
        XCTAssertTrue(sut.doneFetching)
        
        let receivedMessageCount = delegate.messagesByFilter.reduce(0){$0 + ($1[.image]?.count ?? 0)}
        XCTAssertEqual(receivedMessageCount, totalMessageCount)
        
        guard let lastMessage =  delegate.messagesByFilter.last?[.image]?.last,
            let context = lastMessage.managedObjectContext else { return XCTFail() }
        XCTAssertTrue(context.zm_isUserInterfaceContext)
    }
    
    func testThatItCallsTheDelegateWhenTheMessageCountIsZero() {
        // when
        sut = AssetCollectionBatched(conversation: self.conversation, including: [.image], delegate: self.delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(delegate.result, .noAssetsToFetch)
        XCTAssertTrue(delegate.didCallDelegate)
        XCTAssertTrue(sut.doneFetching)
    }
    
    func testThatItCanCancelFetchingMessages() {
        // given
        let totalMessageCount = 5 * AssetCollectionBatched.defaultFetchCount
        insertAssetMessages(count: totalMessageCount)
        
        // when
        sut = AssetCollectionBatched(conversation: conversation, including: [.image], delegate: delegate)
        sut.tearDown()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        // messages would filtered in three batches if the fetching was not cancelled
        XCTAssertNotEqual(delegate.messagesByFilter.count, 5)
        XCTAssertTrue(sut.doneFetching)
    }
    
    func testPerformanceOfMessageFetching() {
        // Before caching:
        // 1 category, 100 paging, messages: average: 0.270, relative standard deviation: 8.876%, values: [0.341864, 0.262725, 0.264362, 0.266097, 0.260730, 0.264372, 0.257983, 0.262659, 0.260060, 0.261362],
        // 1 category, 200 paging, messages: average: 0.273, relative standard deviation: 9.173%, values: [0.346403, 0.260432, 0.262388, 0.263736, 0.262131, 0.278030, 0.264735, 0.265317, 0.262637, 0.261326],
        // 1 category, 500 paging, messages: average: 0.286, relative standard deviation: 9.671%, values: [0.368397, 0.275279, 0.274547, 0.276134, 0.275657, 0.275912, 0.274775, 0.274407, 0.278609, 0.288635]
        // 1 category, 1000 paging, messages: average: 0.299, relative standard deviation: 10.070%, values: [0.388566, 0.289169, 0.283670, 0.287618, 0.287593, 0.287147, 0.296063, 0.292828, 0.287014, 0.288455]
        // 1 category, 1000 paging, messages: average: 0.286, relative standard deviation: 9.671%, values: [0.368397, 0.275279, 0.274547, 0.276134, 0.275657, 0.275912, 0.274775, 0.274407, 0.278609, 0.288635]
        // 2 categories, 200 paging - average: 0.512, relative standard deviation: 4.773%, values: [0.584575, 0.500881, 0.510514, 0.499623, 0.502749, 0.502768, 0.505693, 0.502528, 0.505087, 0.503482]
        // 10.000 messages, 1 category, 200 paging, average: 2.960, relative standard deviation: 5.543%, values: [3.370468, 2.725436, 2.806839, 2.851691, 3.032464, 2.910135, 3.004918, 2.986125, 2.953004, 2.957812]
        
        // given
        insertAssetMessages(count: 1000)
        uiMOC.registeredObjects.forEach{uiMOC.refresh($0, mergeChanges: false)}
        
        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) {
            
            // when
            self.startMeasuring()
            self.sut = AssetCollectionBatched(conversation: self.conversation, including: [.image], delegate: self.delegate)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            
            self.stopMeasuring()
            
            // then
            self.sut.tearDown()
            self.sut = nil
            self.uiMOC.registeredObjects.forEach{self.uiMOC.refresh($0, mergeChanges: false)}
        }
        
    }
    
    func testThatItReturnsPreCategorizedItems(){
        // given
        insertAssetMessages(count: 10)
        
        // when
        conversation.messages.forEach{_ = ($0 as? ZMMessage)?.cachedCategory}
        uiMOC.saveOrRollback()
        
        sut = AssetCollectionBatched(conversation: self.conversation, including: [.image], delegate: self.delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let receivedMessageCount = delegate.messagesByFilter.first?[.image]?.count
        XCTAssertEqual(receivedMessageCount, 10)
    }
    
    func testThatItExcludesDefinedCategories_PreCategorized(){
        // given
        let data = self.data(forResource: "animated", extension: "gif")!
        let message = ZMAssetClientMessage(originalImageData: data, nonce: .create(), managedObjectContext: uiMOC, expiresAfter: 0)
        message.isEncrypted = true
        let testProperties = ZMIImageProperties(size: CGSize(width: 33, height: 55), length: UInt(10), mimeType: "image/gif")
        message.imageAssetStorage!.setImageData(data, for: .medium, properties: testProperties)
        conversation.mutableMessages.add(message)
        uiMOC.saveOrRollback()
        
        // when
        conversation.messages.forEach{_ = ($0 as? ZMMessage)?.cachedCategory}
        uiMOC.saveOrRollback()
        
        sut = AssetCollectionBatched(conversation: self.conversation, including: [.image], excluding:[.GIF], delegate: self.delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        let receivedMessages = delegate.messagesByFilter.first?[.image]?.count
        XCTAssertNil(receivedMessages)
        
        XCTAssertTrue(delegate.didCallDelegate)
        XCTAssertEqual(delegate.result, .noAssetsToFetch)
    }
    
    func testThatItExcludesDefinedCategories_NotPreCategorized(){
        // given
        let data = self.data(forResource: "animated", extension: "gif")!
        let message = ZMAssetClientMessage(originalImageData: data, nonce: .create(), managedObjectContext: uiMOC, expiresAfter: 0)
        message.isEncrypted = true
        let testProperties = ZMIImageProperties(size: CGSize(width: 33, height: 55), length: UInt(10), mimeType: "image/gif")
        message.imageAssetStorage!.setImageData(data, for: .medium, properties: testProperties)
        conversation.mutableMessages.add(message)
        uiMOC.saveOrRollback()
        
        // when
        sut = AssetCollectionBatched(conversation: self.conversation, including: [.image], excluding:[.GIF], delegate: self.delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        let receivedMessages = delegate.messagesByFilter.first?[.image]?.count
        XCTAssertEqual(receivedMessages, 0)
        
        XCTAssertTrue(delegate.didCallDelegate)
        XCTAssertEqual(delegate.result, .success)
    }
    
    func testThatItFetchesImagesAndTextMessages(){
        // given
        insertAssetMessages(count: 10)
        conversation.appendMessage(withText: "foo")
        uiMOC.saveOrRollback()
        
        // when
        sut = AssetCollectionBatched(conversation: self.conversation, including: [.image, .text], delegate: self.delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        let receivedAssetCount = delegate.messagesByFilter.reduce(0){$0 + ($1[.image]?.count ?? 0)}
        XCTAssertEqual(receivedAssetCount, 10)
        
        let receivedTextCount = delegate.messagesByFilter.reduce(0){$0 + ($1[.text]?.count ?? 0)}
        XCTAssertEqual(receivedTextCount, 1)
        
        XCTAssertEqual(delegate.result, .success)
        XCTAssertTrue(delegate.finished.contains(.image))
        XCTAssertTrue(delegate.finished.contains(.text))
    }
}
