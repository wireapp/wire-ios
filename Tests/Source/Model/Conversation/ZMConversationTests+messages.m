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


#import "ZMConversationTests.h"
#import "ZMClientMessage.h"
@import WireImages;

@interface ZMConversationMessagesTests : ZMConversationTestsBase
@end

@implementation ZMConversationMessagesTests

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
        XCTAssertEqualObjects(message.textMessageData.messageText, messageText);
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
    ZMMessage *msg = (id)[conversation appendMessageWithText:@"Foo"];
    
    // then
    XCTAssertNotNil(msg.serverTimestamp);
    XCTAssertEqualObjects(conversation.lastModifiedDate, msg.serverTimestamp);
}

- (void)testThatItUpdatesTheLastModificationDateWhenInsertingMessages;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *msg1 = (id) [conversation appendMessageWithText:@"Foo"];
    msg1.serverTimestamp = [[NSDate date] dateByAddingTimeInterval:-90000];
    conversation.lastModifiedDate = msg1.serverTimestamp;
    
    // when
    ZMMessage *msg2 = (id)[conversation appendMessageWithImageData:[self verySmallJPEGData]];
    
    // then
    XCTAssertNotNil(msg2.serverTimestamp);
    XCTAssertEqualObjects(conversation.lastModifiedDate, msg2.serverTimestamp);
}

- (void)testThatItDoesNotUpdateTheLastModifiedDateForRenameAndLeaveSystemMessages
{
    NSArray<NSNumber *> *types = @[@(ZMSystemMessageTypeTeamMemberLeave), @(ZMSystemMessageTypeConversationNameChanged)];
    for (NSNumber *type in types) {
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
        NSDate *lastModified = [NSDate dateWithTimeIntervalSince1970:10];
        conversation.lastModifiedDate = lastModified;

        ZMSystemMessage *systemMessage = [ZMSystemMessage insertNewObjectInManagedObjectContext:self.uiMOC];
        systemMessage.systemMessageType = (ZMSystemMessageType)type.intValue;
        systemMessage.serverTimestamp = [lastModified dateByAddingTimeInterval:100];

        // when
        [conversation sortedAppendMessage:systemMessage];

        // then
        XCTAssertEqualObjects(conversation.lastModifiedDate, lastModified);
    }
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
    XCTAssertEqualObjects(message.textMessageData.messageText, originalText);
}

- (void)testThatInsertATextMessageWithNilTextDoesNotCreateANewMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    NSSet *start = [self.uiMOC.insertedObjects copy];
    
    // when
    __block ZMMessage *message;
    [self performIgnoringZMLogError:^{
        message = (id)[conversation appendMessageWithText:nil];
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
    XCTAssertTrue(CGSizeEqualToSize(message.imageMessageData.originalSize, CGSizeMake(1900, 1500)));
    XCTAssertEqual(message.conversation, conversation);
    XCTAssertTrue([conversation.messages containsObject:message]);
    XCTAssertNotNil(message.nonce);
    NSData *expectedData = [[NSData dataWithContentsOfURL:imageFileURL] wr_imageDataWithoutMetadataAndReturnError:nil];
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
    AssertEqualSizes(message.imageMessageData.originalSize, CGSizeMake(1900, 1500));
    XCTAssertEqual(message.conversation, conversation);
    XCTAssertTrue([conversation.messages containsObject:message]);
    XCTAssertNotNil(message.nonce);
    NSData *expectedData = [[NSData dataWithContentsOfURL:imageFileURL] wr_imageDataWithoutMetadataAndReturnError:nil];
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
    NSData *imageData = [[self dataForResource:@"1900x1500" extension:@"jpg"] wr_imageDataWithoutMetadataAndReturnError:nil];
    XCTAssertNotNil(imageData);
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    
    // when
    ZMImageMessage *message = (ZMImageMessage *)[conversation appendMessageWithImageData:imageData];
    
    // then
    XCTAssertNotNil(message);
    XCTAssertNotNil(message.nonce);
    XCTAssertTrue(CGSizeEqualToSize(message.imageMessageData.originalSize, CGSizeMake(1900, 1500)));
    XCTAssertEqual(message.conversation, conversation);
    XCTAssertTrue([conversation.messages containsObject:message]);
    XCTAssertNotNil(message.nonce);
    XCTAssertEqual(message.originalImageData.length, imageData.length);
}

- (void)testThatItIsSafeToPassInMutableDataWhenCreatingAnImageMessage
{
    // given
    NSData *originalImageData = [[self dataForResource:@"1900x1500" extension:@"jpg"] wr_imageDataWithoutMetadataAndReturnError:nil];
    NSMutableData *imageData = [originalImageData mutableCopy];
    XCTAssertNotNil(imageData);
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    
    // when
    ZMImageMessage *message = (ZMImageMessage *)[conversation appendMessageWithImageData:imageData];
    
    // then
    [imageData appendBytes:((const char []) {1, 2}) length:2];
    XCTAssertEqual(message.originalImageData.length, originalImageData.length);
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

- (void)testThatWeCanInsertAFileMessage
{
    // given
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSURL *fileURL = [[NSURL fileURLWithPath:documents] URLByAppendingPathComponent:@"secret_file.txt"];
    NSData *data = [@"Some Data" dataUsingEncoding:NSUTF8StringEncoding];
    uint64_t size = (uint64_t) data.length;
    NSError *error;
    XCTAssertTrue([data writeToURL:fileURL options:0 error:&error]);
    XCTAssertNil(error);
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    
    // when
    ZMFileMetadata *fileMetadata = [[ZMFileMetadata alloc] initWithFileURL:fileURL thumbnail:nil];
    ZMAssetClientMessage *fileMessage = (id)[conversation appendMessageWithFileMetadata:fileMetadata];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(conversation.messages.count, 1lu);
    XCTAssertEqualObjects(conversation.messages.firstObject, fileMessage);
    
    XCTAssertTrue(fileMessage.isEncrypted);
    XCTAssertNotNil(fileMessage);
    XCTAssertNotNil(fileMessage.nonce);
    XCTAssertNotNil(fileMessage.fileMessageData);
    XCTAssertNotNil(fileMessage.genericAssetMessage);
    XCTAssertNil(fileMessage.assetId);
    XCTAssertNil(fileMessage.imageAssetStorage.previewGenericMessage);
    XCTAssertNil(fileMessage.imageAssetStorage.mediumGenericMessage);
    XCTAssertEqual(fileMessage.uploadState, ZMAssetUploadStateUploadingPlaceholder);
    XCTAssertFalse(fileMessage.delivered);
    XCTAssertTrue(fileMessage.hasDownloadedFile);
    XCTAssertEqual(fileMessage.size, size);
    XCTAssertEqual(fileMessage.progress, 0.f);
    XCTAssertEqualObjects(fileMessage.filename, @"secret_file.txt");
    XCTAssertEqualObjects(fileMessage.mimeType, @"text/plain");
    XCTAssertFalse(fileMessage.fileMessageData.isVideo);
    XCTAssertFalse(fileMessage.fileMessageData.isAudio);
}

- (void)testThatWeCanInsertALocationMessage
{
    // given
    float latitude = 48.53775f, longitude = 9.041169f;
    int32_t zoomLevel = 16;
    NSString *name = @"天津市 နေပြည်တော် Test";
    ZMLocationData *locationData = [ZMLocationData locationDataWithLatitude:latitude longitude:longitude name:name zoomLevel:zoomLevel];
    
    // when
    __block ZMConversation *conversation;
    __block id <ZMConversationMessage> message;
    
    [self.syncMOC performGroupedBlock:^{
        conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = NSUUID.createUUID;
        message = [conversation appendMessageWithLocationData:locationData];
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertNotNil(message);
    XCTAssertNotNil(conversation);
    
    // then
    [self.syncMOC performGroupedBlock:^{
        XCTAssertEqual(conversation.messages.count, 1lu);
        XCTAssertEqualObjects(conversation.messages.firstObject, message);
        XCTAssertTrue(message.isEncrypted);
        
        id <ZMLocationMessageData> locationMessageData = message.locationMessageData;
        XCTAssertNotNil(locationMessageData);
        XCTAssertEqual(locationMessageData.longitude, longitude);
        XCTAssertEqual(locationMessageData.latitude, latitude);
        XCTAssertEqual(locationMessageData.zoomLevel, zoomLevel);
        XCTAssertEqualObjects(locationMessageData.name, name);
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatWeCanInsertAVideoMessage
{
    // given
    NSString *fileName = @"video.mp4";
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSURL *fileURL = [[NSURL fileURLWithPath:documents] URLByAppendingPathComponent:fileName];
    NSData *videoData = [NSData secureRandomDataOfLength:500];
    NSData *thumbnailData = [NSData secureRandomDataOfLength:250];
    NSError *error;
    NSUInteger duration = 12333;
    CGSize dimensions = CGSizeMake(1900, 800);
    XCTAssertTrue([videoData writeToURL:fileURL options:0 error:&error]);
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    
    // when
    ZMVideoMetadata *videoMetadata = [[ZMVideoMetadata alloc] initWithFileURL:fileURL duration:duration dimensions:dimensions thumbnail:thumbnailData];
    ZMAssetClientMessage *fileMessage = (id)[conversation appendMessageWithFileMetadata:videoMetadata];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(conversation.messages.count, 1lu);
    XCTAssertEqualObjects(conversation.messages.firstObject, fileMessage);
    
    XCTAssertTrue(fileMessage.isEncrypted);
    XCTAssertNotNil(fileMessage);
    XCTAssertNotNil(fileMessage.nonce);
    XCTAssertNotNil(fileMessage.fileMessageData);
    XCTAssertNotNil(fileMessage.genericAssetMessage);
    XCTAssertNil(fileMessage.assetId);
    XCTAssertNil(fileMessage.imageAssetStorage.previewGenericMessage);
    XCTAssertNil(fileMessage.imageAssetStorage.mediumGenericMessage);
    XCTAssertEqual(fileMessage.uploadState, ZMAssetUploadStateUploadingPlaceholder);
    XCTAssertFalse(fileMessage.delivered);
    XCTAssertTrue(fileMessage.hasDownloadedFile);
    XCTAssertEqual(fileMessage.size, videoData.length);
    XCTAssertEqual(fileMessage.progress, 0.f);
    XCTAssertEqualObjects(fileMessage.filename, fileName);
    XCTAssertEqualObjects(fileMessage.mimeType, @"video/mp4");
    XCTAssertTrue(fileMessage.fileMessageData.isVideo);
    XCTAssertFalse(fileMessage.fileMessageData.isAudio);
    XCTAssertEqual(fileMessage.fileMessageData.durationMilliseconds, duration * 1000);
    XCTAssertEqual(fileMessage.fileMessageData.videoDimensions.height, dimensions.height);
    XCTAssertEqual(fileMessage.fileMessageData.videoDimensions.width, dimensions.width);
}

- (void)testThatWeCanInsertAnAudioMessage
{
    // given
    NSString *fileName = @"audio.m4a";
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSURL *fileURL = [[NSURL fileURLWithPath:documents] URLByAppendingPathComponent:fileName];
    NSData *videoData = [NSData secureRandomDataOfLength:500];
    NSData *thumbnailData = [NSData secureRandomDataOfLength:250];
    NSError *error;
    NSUInteger duration = 12333;
    XCTAssertTrue([videoData writeToURL:fileURL options:0 error:&error]);
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    
    // when
    ZMAudioMetadata *audioMetadata = [[ZMAudioMetadata alloc] initWithFileURL:fileURL duration:duration normalizedLoudness:@[] thumbnail:thumbnailData];
    ZMAssetClientMessage *fileMessage = (id)[conversation appendMessageWithFileMetadata:audioMetadata];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(conversation.messages.count, 1lu);
    XCTAssertEqualObjects(conversation.messages.firstObject, fileMessage);
    
    XCTAssertTrue(fileMessage.isEncrypted);
    XCTAssertNotNil(fileMessage);
    XCTAssertNotNil(fileMessage.nonce);
    XCTAssertNotNil(fileMessage.fileMessageData);
    XCTAssertNotNil(fileMessage.genericAssetMessage);
    XCTAssertNil(fileMessage.assetId);
    XCTAssertNil(fileMessage.imageAssetStorage.previewGenericMessage);
    XCTAssertNil(fileMessage.imageAssetStorage.mediumGenericMessage);
    XCTAssertEqual(fileMessage.uploadState, ZMAssetUploadStateUploadingPlaceholder);
    XCTAssertFalse(fileMessage.delivered);
    XCTAssertTrue(fileMessage.hasDownloadedFile);
    XCTAssertEqual(fileMessage.size, videoData.length);
    XCTAssertEqual(fileMessage.progress, 0.f);
    XCTAssertEqualObjects(fileMessage.filename, fileName);
    XCTAssertEqualObjects(fileMessage.mimeType, @"audio/x-m4a");
    XCTAssertFalse(fileMessage.fileMessageData.isVideo);
    XCTAssertTrue(fileMessage.fileMessageData.isAudio);
}

@end // messages


