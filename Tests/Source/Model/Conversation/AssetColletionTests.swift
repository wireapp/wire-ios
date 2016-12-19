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

class MockAssetCollectionDelegate : NSObject, AssetCollectionDelegate {
    
    var messagesByFilter = [[MessageCategory: [ZMMessage]]]()
    var didCallDelegate = false
    var result : AssetFetchResult?
    var finished: [MessageCategory] = []
    
    public func assetCollectionDidFinishFetching(collection: ZMCollection, result: AssetFetchResult) {
        self.result = result
        didCallDelegate = true
    }
    
    public func assetCollectionDidFetch(collection: ZMCollection, messages: [MessageCategory : [ZMMessage]], hasMore: Bool) {
        messagesByFilter.append(messages)
        didCallDelegate = true
        if !hasMore {
            finished = finished + messages.keys
        }
    }
}


class AssetColletionTests : ModelObjectsTests {

    var sut : AssetCollection!
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
        let totalMessageCount = AssetCollection.initialFetchCount - 10
        XCTAssertGreaterThan(totalMessageCount, 0)
        insertAssetMessages(count: totalMessageCount)
        
        // when
        sut = AssetCollection(conversation: conversation, including: [.image], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(delegate.result, .success)
        XCTAssertEqual(delegate.messagesByFilter.count, 1)
        XCTAssertTrue(sut.doneFetching)

        let receivedMessageCount = delegate.messagesByFilter.first?[.image]?.count
        XCTAssertEqual(receivedMessageCount, 90)
        
        guard let lastMessage =  delegate.messagesByFilter.last?[.image]?.last,
              let context = lastMessage.managedObjectContext else { return XCTFail() }
        XCTAssertTrue(context.zm_isUserInterfaceContext)
    }
    
    func testThatItCanGetMessages_TotalMessageCountEqualInitialFetchCount() {
        // given
        let totalMessageCount = AssetCollection.initialFetchCount
        insertAssetMessages(count: totalMessageCount)
        
        // when
        sut = AssetCollection(conversation: conversation, including: [.image], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(delegate.result, .success)
        XCTAssertEqual(delegate.messagesByFilter.count, 1)
        XCTAssertTrue(sut.doneFetching)
        
        let receivedMessageCount = delegate.messagesByFilter.first?[.image]?.count
        XCTAssertEqual(receivedMessageCount, 100)
        
        guard let lastMessage =  delegate.messagesByFilter.last?[.image]?.last,
            let context = lastMessage.managedObjectContext else { return XCTFail() }
        XCTAssertTrue(context.zm_isUserInterfaceContext)
    }
    
    func testThatItCanGetMessages_TotalMessageCountGreaterThanInitialFetchCount() {
        // given
        let totalMessageCount = 2 * AssetCollection.defaultFetchCount
        XCTAssertGreaterThan(totalMessageCount, AssetCollection.initialFetchCount)

        insertAssetMessages(count: totalMessageCount)
        
        // when
        sut = AssetCollection(conversation: conversation, including: [.image], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        // messages were filtered in three batches
        XCTAssertEqual(delegate.result, .success)
        XCTAssertEqual(delegate.messagesByFilter.count, 3)
        XCTAssertTrue(sut.doneFetching)
        
        let receivedMessageCount = delegate.messagesByFilter.reduce(0){$0 + ($1[.image]?.count ?? 0)}
        XCTAssertEqual(receivedMessageCount, 1000)
        
        guard let lastMessage =  delegate.messagesByFilter.last?[.image]?.last,
            let context = lastMessage.managedObjectContext else { return XCTFail() }
        XCTAssertTrue(context.zm_isUserInterfaceContext)
    }
    
    func testThatItCallsTheDelegateWhenTheMessageCountIsZero() {
        // when
        sut = AssetCollection(conversation: conversation, including: [.image], delegate: delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(delegate.result, .noAssetsToFetch)
        XCTAssertTrue(delegate.didCallDelegate)
        XCTAssertTrue(sut.doneFetching)
    }
    
    func testThatItCanCancelFetchingMessages() {
        // given
        let totalMessageCount = 2 * AssetCollection.defaultFetchCount
        insertAssetMessages(count: totalMessageCount)
        
        // when
        sut = AssetCollection(conversation: conversation, including: [.image], delegate: delegate)
        sut.tearDown()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        // messages would filtered in three batches if the fetching was not cancelled
        XCTAssertNotEqual(delegate.messagesByFilter.count, 3)
        XCTAssertTrue(sut.doneFetching)
    }
    
    func testPerformanceOfMessageFetching() {
        // Before caching:
        // 1000 messages, 1 category, 500 defaultpaging, average: 0.275, relative standard deviation: 8.967%, values: [0.348496, 0.263188, 0.266409, 0.268903, 0.265612, 0.265829, 0.271573, 0.265206, 0.268697, 0.264837]
        // 1000 messages, 1 category, 200 defaultpaging, average: 0.304, relative standard deviation: 9.818%, values: [0.390736, 0.285759, 0.293118, 0.290341, 0.293730, 0.281093, 0.292787, 0.305865, 0.306954, 0.302983]
        // 1000 messages, 2 categories, 500 defaultpaging, average: 0.570, relative standard deviation: 5.990%, values: [0.656057, 0.526296, 0.530267, 0.572129, 0.557102, 0.586183, 0.574734, 0.580168, 0.563595, 0.556718]
        // 10000 messages, average: 3.495, relative standard deviation: 7.352%, values: [4.259749, 3.372894, 3.389057, 3.404054, 3.363652, 3.400085, 3.416911, 3.417086, 3.442652, 3.488077],
        
        // given
        insertAssetMessages(count: 1000)
        uiMOC.registeredObjects.forEach{uiMOC.refresh($0, mergeChanges: false)}
        
        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) {
            
            // when
            self.startMeasuring()
            self.sut = AssetCollection(conversation: self.conversation, including: [.image], delegate: self.delegate)
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
        
        sut = AssetCollection(conversation: self.conversation, including: [.image], delegate: self.delegate)
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
        
        sut = AssetCollection(conversation: self.conversation, including: [.image], excluding:[.GIF], delegate: self.delegate)
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
        sut = AssetCollection(conversation: self.conversation, including: [.image], excluding:[.GIF], delegate: self.delegate)
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
        sut = AssetCollection(conversation: self.conversation, including: [.image, .text], delegate: self.delegate)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        let receivedAssetCount = delegate.messagesByFilter.reduce(0){$0 + ($1[.image]?.count ?? 0)}
        XCTAssertEqual(receivedAssetCount, 10)
        
        let receivedTextCount = delegate.messagesByFilter.reduce(0){$0 + ($1[.text]?.count ?? 0)}
        XCTAssertEqual(receivedTextCount, 1)
        
        XCTAssertEqual(delegate.result, .success)
    }
}
 

