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


#import "ZMConversationTests.h"
#import "ZMClientMessage.h"


@implementation ZMConversationTests (Messages)

- (void)testThatWeCanInsertATextMessage;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = NSUUID.createUUID;
        
        // when
        NSString *messageText = @"foo";
        id<ZMConversationMessage> message = [conversation appendMessageWithText:messageText];
        
        // then
        XCTAssertEqualObjects(message.messageText, messageText);
        XCTAssertEqual(message.conversation, conversation);
        XCTAssertTrue([conversation.messages containsObject:message]);
        XCTAssertEqualObjects(selfUser, message.sender);
    }];
}

- (void)testThatItUpdatesTheLastModificationDateWhenInsertingMessagesIntoAnEmptyConversation;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastModifiedDate = [[NSDate date] dateByAddingTimeInterval:-90000];
    ZMMessage *msg = [conversation appendMessageWithText:@"Foo"];
    
    // then
    XCTAssertNotNil(msg.serverTimestamp);
    XCTAssertEqualObjects(conversation.lastModifiedDate, msg.serverTimestamp);
}

- (void)testThatItUpdatesTheLastModificationDateWhenInsertingMessages;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *msg1 = [conversation appendMessageWithText:@"Foo"];
    msg1.serverTimestamp = [[NSDate date] dateByAddingTimeInterval:-90000];
    conversation.lastModifiedDate = msg1.serverTimestamp;
    
    // when
    ZMMessage *msg2 = [conversation appendMessageWithImageData:[self verySmallJPEGData]];
    
    // then
    XCTAssertNotNil(msg2.serverTimestamp);
    XCTAssertEqualObjects(conversation.lastModifiedDate, msg2.serverTimestamp);
}

- (void)testThatItIsSafeToPassInAMutableStringWhenCreatingATextMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    
    // when
    NSString *originalText = @"foo";
    NSMutableString *messageText = [NSMutableString stringWithString:originalText];
    id<ZMConversationMessage> message = [conversation appendMessageWithText:messageText];
    
    // then
    [messageText appendString:@"1234"];
    XCTAssertEqualObjects(message.messageText, originalText);
}

- (void)testThatInsertATextMessageWithNilTextDoesNotCreateANewMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    NSSet *start = [self.uiMOC.insertedObjects copy];
    
    // when
    __block ZMTextMessage *message;
    [self performIgnoringZMLogError:^{
        message = [conversation appendMessageWithText:nil];
    }];
    
    // then
    XCTAssertNil(message);
    XCTAssertEqualObjects(start, self.uiMOC.insertedObjects);
}

- (void)testThatWeCanInsertAnImageMessageFromAFileURL;
{
    // given
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    NSURL *imageFileURL = [self fileURLForResource:@"1900x1500" extension:@"jpg"];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    
    // when
    ZMImageMessage *message = (ZMImageMessage *)[conversation appendMessageWithImageAtURL:imageFileURL];
    
    // then
    XCTAssertNotNil(message);
    XCTAssertNotNil(message.nonce);
    XCTAssertTrue(CGSizeEqualToSize(message.originalSize, CGSizeMake(1900, 1500)));
    XCTAssertEqual(message.conversation, conversation);
    XCTAssertTrue([conversation.messages containsObject:message]);
    XCTAssertNotNil(message.nonce);
    NSData *expectedData = [NSData dataWithContentsOfURL:imageFileURL];
    XCTAssertNotNil(expectedData);
    AssertEqualData(message.originalImageData, expectedData);
    XCTAssertEqualObjects(selfUser, message.sender);
}

- (void)testThatNoMessageIsInsertedWhenTheImageFileURLIsPointingToSomethingThatIsNotAnImage;
{
    // given
    NSURL *imageFileURL = [self fileURLForResource:@"1900x1500" extension:@"jpg"];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    
    // when
    ZMImageMessage *message = (ZMImageMessage *)[conversation appendMessageWithImageAtURL:imageFileURL];
    
    // then
    XCTAssertNotNil(message);
    XCTAssertNotNil(message.nonce);
    AssertEqualSizes(message.originalSize, CGSizeMake(1900, 1500));
    XCTAssertEqual(message.conversation, conversation);
    XCTAssertTrue([conversation.messages containsObject:message]);
    XCTAssertNotNil(message.nonce);
    NSData *expectedData = [NSData dataWithContentsOfURL:imageFileURL];
    XCTAssertNotNil(expectedData);
    AssertEqualData(message.originalImageData, expectedData);
}

- (void)testThatNoMessageIsInsertedWhenTheImageFileURLIsNotAFileURL
{
    // given
    NSURL *imageURL = [NSURL URLWithString:@"http://www.placehold.it/350x150"];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    NSSet *start = [self.uiMOC.insertedObjects copy];
    
    // when
    __block ZMImageMessage *message;
    [self performIgnoringZMLogError:^{
        message = (ZMImageMessage *)[conversation appendMessageWithImageAtURL:imageURL];
    }];
    
    // then
    XCTAssertNil(message);
    XCTAssertEqualObjects(start, self.uiMOC.insertedObjects);
}

- (void)testThatNoMessageIsInsertedWhenTheImageFileURLIsNotPointingToAFile
{
    // given
    NSURL *textFileURL = [self fileURLForResource:@"Lorem Ipsum" extension:@"txt"];
    XCTAssertNotNil(textFileURL);
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    NSSet *start = [self.uiMOC.insertedObjects copy];
    
    // when
    __block ZMImageMessage *message;
    [self performIgnoringZMLogError:^{
        message = (ZMImageMessage *)[conversation appendMessageWithImageAtURL:textFileURL];
    }];
    
    // then
    XCTAssertNil(message);
    XCTAssertEqualObjects(start, self.uiMOC.insertedObjects);
}

- (void)testThatWeCanInsertAnImageMessageFromImageData;
{
    // given
    NSData *imageData = [self dataForResource:@"1900x1500" extension:@"jpg"];
    XCTAssertNotNil(imageData);
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    
    // when
    ZMImageMessage *message = (ZMImageMessage *)[conversation appendMessageWithImageData:imageData];
    
    // then
    XCTAssertNotNil(message);
    XCTAssertNotNil(message.nonce);
    XCTAssertTrue(CGSizeEqualToSize(message.originalSize, CGSizeMake(1900, 1500)));
    XCTAssertEqual(message.conversation, conversation);
    XCTAssertTrue([conversation.messages containsObject:message]);
    XCTAssertNotNil(message.nonce);
    AssertEqualData(message.originalImageData, imageData);
}

- (void)testThatItIsSafeToPassInMutableDataWhenCreatingAnImageMessage
{
    // given
    NSData *originalImageData = [self dataForResource:@"1900x1500" extension:@"jpg"];
    NSMutableData *imageData = [originalImageData mutableCopy];
    XCTAssertNotNil(imageData);
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    
    // when
    ZMImageMessage *message = (ZMImageMessage *)[conversation appendMessageWithImageData:imageData];
    
    // then
    [imageData appendBytes:((const char []) {1, 2}) length:2];
    AssertEqualData(message.originalImageData, originalImageData);
}

- (void)testThatNoMessageIsInsertedWhenTheImageDataIsNotAnImage;
{
    // given
    NSData *textData = [self dataForResource:@"Lorem Ipsum" extension:@"txt"];
    XCTAssertNotNil(textData);
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    NSSet *start = [self.uiMOC.insertedObjects copy];
    
    // when
    __block ZMImageMessage *message;
    [self performIgnoringZMLogError:^{
        message = (ZMImageMessage *)[conversation appendMessageWithImageData:textData];
    }];
    
    // then
    XCTAssertNil(message);
    XCTAssertEqualObjects(start, self.uiMOC.insertedObjects);
}

- (void)testThatLastReadUpdatesInSelfConversationDontExpire
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = NSUUID.createUUID;
        conversation.lastReadServerTimeStamp = [NSDate date];
        
        // when
        ZMClientMessage *message = [ZMConversation appendSelfConversationWithLastReadOfConversation:conversation];
        
        // then
        XCTAssertNotNil(message);
        XCTAssertNil(message.expirationDate);
    }];
}

- (void)testThatLastClearedUpdatesInSelfConversationDontExpire
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = NSUUID.createUUID;
        conversation.clearedTimeStamp = [NSDate date];
        
        // when
        ZMClientMessage *message = [ZMConversation appendSelfConversationWithClearedOfConversation:conversation];
        
        // then
        XCTAssertNotNil(message);
        XCTAssertNil(message.expirationDate);
    }];
}

@end // messages


