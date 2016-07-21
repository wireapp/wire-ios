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


@import ZMTransport;
@import ZMCDataModel;

#import "MessagingTest.h"



@interface ZMDownstreamObjectSyncOrderingTests : MessagingTest

@property (nonatomic) ZMConversation *conversation1;
@property (nonatomic) ZMConversation *conversation2;

@property (nonatomic) ZMImageMessage *imageMessage1;
@property (nonatomic) ZMImageMessage *imageMessage2;

@end



@implementation ZMDownstreamObjectSyncOrderingTests

- (void)setUp
{
    [super setUp];

    self.conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    self.conversation1.conversationType = ZMConversationTypeGroup;
    self.conversation1.lastModifiedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:417006000];
    self.conversation1.isArchived = NO;
    
    // c2 is newer, but archived
    self.conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    self.conversation2.conversationType = ZMConversationTypeGroup;
    self.conversation2.lastModifiedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:417007000];
    self.conversation2.isArchived = YES;
    
    // message 2 is never than message 1
    self.imageMessage1 = [ZMImageMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    self.imageMessage1.eventID = [ZMEventID eventIDWithMajor:12 minor:12];
    self.imageMessage2 = [ZMImageMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    self.imageMessage2.eventID = [ZMEventID eventIDWithMajor:45 minor:45];
    self.imageMessage2.serverTimestamp = [self.imageMessage1.serverTimestamp dateByAddingTimeInterval:0.1];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSComparator)comparatorFromSearchDescriptors:(NSArray *)descriptors;
{
    NSComparator comparator = ^NSComparisonResult(id obj1, id obj2){
        for (NSSortDescriptor *sd in descriptors) {
            NSComparisonResult const r = [sd compareObject:obj1 toObject:obj2];
            if (r != NSOrderedSame) {
                return r;
            }
        }
        return NSOrderedSame;
    };
    return [comparator copy];
}

- (void)testThatArchivedConversationsAreDownloadedLast;
{
    // given
    NSComparator sut = [self comparatorFromSearchDescriptors:ZMConversation.sortDescriptorsForUpdating];
    
    // then
    XCTAssertEqual(sut(self.conversation1, self.conversation2), NSOrderedAscending);
    XCTAssertEqual(sut(self.conversation2, self.conversation1), NSOrderedDescending);
}

- (void)testThatNewestConversationsAreDownloadedFirst;
{
    // given
    NSComparator sut = [self comparatorFromSearchDescriptors:ZMConversation.sortDescriptorsForUpdating];
    self.conversation2.isArchived = NO;
    
    // then
    XCTAssertEqual(sut(self.conversation1, self.conversation2), NSOrderedDescending);
    XCTAssertEqual(sut(self.conversation2, self.conversation1), NSOrderedAscending);
}

- (void)testThatNewerImagesAreDownloadedFirst;
{
    // given
    NSComparator sut = [self comparatorFromSearchDescriptors:ZMImageMessage.sortDescriptorsForUpdating];
    self.imageMessage1.visibleInConversation = self.conversation1;
    self.imageMessage2.visibleInConversation = self.conversation1;
    
    // then
    //
    // Message 2 is newer than message 1:
    XCTAssertEqual(sut(self.imageMessage2, self.imageMessage1), NSOrderedAscending);
    XCTAssertEqual(sut(self.imageMessage1, self.imageMessage2), NSOrderedDescending);
}

- (void)testThatImagesInNonArchivedConversationsAreDownloadedFirst;
{
    // given
    NSComparator sut = [self comparatorFromSearchDescriptors:ZMImageMessage.sortDescriptorsForUpdating];
    self.imageMessage1.visibleInConversation = self.conversation1;
    self.imageMessage2.visibleInConversation = self.conversation2;

    // then
    //
    // Conversation 2 is archived, hence we should pick up message 1 in conv 1 first:
    XCTAssertEqual(sut(self.imageMessage1, self.imageMessage2), NSOrderedAscending);
    XCTAssertEqual(sut(self.imageMessage2, self.imageMessage1), NSOrderedDescending);
}

@end
