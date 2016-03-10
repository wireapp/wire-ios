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


@import UIKit;
@import ZMTransport;

#import "MessagingTest.h"
#import "ZMSharableConversations.h"
#import "ZMConversationListDirectory.h"
#import "ZMConversation+Internal.h"
#import "ZMManagedObject+Internal.h"
#import "ZMUser+Internal.h"

@interface ZMTBaseTest()

- (NSArray *)allDispatchGroups;

@end

@interface ZMSharableConversations(Testing)

@property (nonatomic, readonly) ZMSDispatchGroup *privateGroup;

@end

@interface ZMSharableConversationsTests : MessagingTest

@property (nonatomic) ZMSharableConversations *sut;
@property (nonatomic) ZMConversation *initialConversation;

@end

@implementation ZMSharableConversationsTests

- (void)setUp
{
    [super setUp];
    
    [[NSFileManager defaultManager] removeItemAtURL:[self conversationsURL] error:nil];
    [[NSFileManager defaultManager] removeItemAtURL:[self userImageURL:nil] error:nil];

    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser.name = @"Ilya";
    otherUser.remoteIdentifier = NSUUID.createUUID;
    NSString *imageURL = [[NSBundle bundleForClass:[self class]] pathForResource:@"1900x1500_smallProfile" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imageURL];
    otherUser.smallProfileRemoteIdentifier = [NSUUID createUUID];
    otherUser.imageSmallProfileData = UIImageJPEGRepresentation(image, 0.8f);
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    conversation.userDefinedName = @"initial";
    conversation.conversationType = ZMConversationTypeOneOnOne;
    [conversation.mutableOtherActiveParticipants addObject:otherUser];
    self.initialConversation = conversation;
    
    self.sut = [[self.uiMOC conversationListDirectory] sharableConversations];
    
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5f]);
}

- (NSArray *)allDispatchGroups;
{
    NSArray *allDispatchGroups = [super allDispatchGroups];
    if (self.sut.privateGroup) {
        return [allDispatchGroups arrayByAddingObject:self.sut.privateGroup];
    }
    return allDispatchGroups;
}


- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];

    [[NSFileManager defaultManager] removeItemAtURL:[self conversationsURL] error:nil];
    [[NSFileManager defaultManager] removeItemAtURL:[self userImageURL:nil] error:nil];
}

- (NSURL *)conversationsURL
{
    NSURL *url = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[NSUserDefaults groupName]];
    NSURL *conversationsURL = [url URLByAppendingPathComponent:@"conversations"];
    return conversationsURL;
}

- (NSURL *)userImageURL:(NSString *)filename
{
    NSURL *url = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[NSUserDefaults groupName]];
    url = [url URLByAppendingPathComponent:@"profile_images"];
    if (filename != nil) {
        url = [url URLByAppendingPathComponent:filename];
    }
    return url;
}

- (void)testThatItDumpsConversationsOnInit
{
    NSArray *conversations = [NSArray arrayWithContentsOfURL:[self conversationsURL]];
    XCTAssertNotNil(conversations);
    XCTAssertEqual(conversations.count, 1u);
    NSDictionary *conversation = conversations.firstObject;
    XCTAssertEqualObjects(conversation[@"remoteIdentifier"], self.initialConversation.remoteIdentifier.UUIDString);
}

- (void)testThatItDumpsConversationsWhenConversationListChanges
{
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser.remoteIdentifier = NSUUID.createUUID;

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    conversation.conversationType = ZMConversationTypeOneOnOne;
    [conversation.mutableOtherActiveParticipants addObject:otherUser];

    [self spinMainQueueWithTimeout:0.5f];
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5f]);

    NSArray *conversations = [NSArray arrayWithContentsOfURL:[self conversationsURL]];
    XCTAssertNotNil(conversations);
    XCTAssertEqual(conversations.count, 2u);
    NSDictionary *firstConversation = conversations.firstObject;
    XCTAssertEqualObjects(firstConversation[@"remoteIdentifier"], self.initialConversation.remoteIdentifier.UUIDString);
    
    NSDictionary *secondConversation = conversations.lastObject;
    XCTAssertEqualObjects(secondConversation[@"remoteIdentifier"], conversation.remoteIdentifier.UUIDString);
}

- (void)testThatItDumpsUserImagesOnInit
{
    [self spinMainQueueWithTimeout:0.5f];

    NSURL *imageURL = [self userImageURL:self.initialConversation.remoteIdentifier.transportString];
    NSData *data = [NSData dataWithContentsOfURL:imageURL];
    XCTAssertNotNil(data);
    XCTAssertEqualObjects(data, [self.initialConversation.otherActiveParticipants.firstObject imageSmallProfileData]);
    UIImage *image = [UIImage imageWithData:data];
    XCTAssertNotNil(image);
}

- (void)testThatItDumpsUserImagesWhenNewConversationAdded
{
    [self spinMainQueueWithTimeout:0.5f];

    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser.remoteIdentifier = NSUUID.createUUID;
    NSString *imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"1900x1500_smallProfile" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    otherUser.smallProfileRemoteIdentifier = [NSUUID createUUID];
    otherUser.imageSmallProfileData = UIImageJPEGRepresentation(image, 0.8f);

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    conversation.conversationType = ZMConversationTypeOneOnOne;
    [conversation.mutableOtherActiveParticipants addObject:otherUser];
    
    [self spinMainQueueWithTimeout:0.5f];
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5f]);

    NSURL *imageURL = [self userImageURL:conversation.remoteIdentifier.transportString];
    NSData *data = [NSData dataWithContentsOfURL:imageURL];
    XCTAssertNotNil(data);
    XCTAssertEqualObjects(data, [conversation.otherActiveParticipants.firstObject imageSmallProfileData]);
    image = [UIImage imageWithData:data];
    XCTAssertNotNil(image);
}

- (void)testThatItDumpsUserImagesWhenTheyChange
{
    ZMUser *otherUser = self.initialConversation.otherActiveParticipants.firstObject;
    NSString *imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Mersey00036992_smallProfile" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    otherUser.imageSmallProfileData = UIImageJPEGRepresentation(image, 0.8f);
    
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5f]);
    [self spinMainQueueWithTimeout:0.5f];

    NSURL *imageURL = [self userImageURL:self.initialConversation.remoteIdentifier.transportString];
    NSData *data = [NSData dataWithContentsOfURL:imageURL];
    XCTAssertNotNil(data);
    XCTAssertEqualObjects(data, otherUser.imageSmallProfileData);
    image = [UIImage imageWithData:data];
    XCTAssertNotNil(image);
}

- (void)testThatItUpdatesConversationsWhenUserAccentColorChanges
{
    [self spinMainQueueWithTimeout:0.5f];

    ZMUser *otherUser = self.initialConversation.otherActiveParticipants.firstObject;
    otherUser.accentColorValue = otherUser.accentColorValue + 1;
    
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5f]);
    [self spinMainQueueWithTimeout:0.5f];

    NSArray *conversations = [NSArray arrayWithContentsOfURL:[self conversationsURL]];
    NSDictionary *firstConversation = conversations.firstObject;
    XCTAssertEqualObjects(firstConversation[@"user_data"][@"accent_id"], @(otherUser.accentColorValue));
}

- (void)testThatItUpdatesConversationsWhenUserNameChanges
{
    [self spinMainQueueWithTimeout:0.5f];

    ZMUser *otherUser = self.initialConversation.otherActiveParticipants.firstObject;
    otherUser.name = @"IlyaIlya";
    
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5f]);
    [self spinMainQueueWithTimeout:0.5f];

    NSArray *conversations = [NSArray arrayWithContentsOfURL:[self conversationsURL]];
    NSDictionary *firstConversation = conversations.firstObject;
    XCTAssertEqualObjects(firstConversation[@"user_data"][@"name"], otherUser.displayName);
}


@end
