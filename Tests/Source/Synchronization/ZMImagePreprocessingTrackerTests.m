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


@import zimages;
@import ZMCDataModel;

#import "MessagingTest.h"
#import "ZMImagePreprocessingTracker+Testing.h"


@interface ZMImagePreprocessingTrackerTests : MessagingTest

@property (nonatomic) id preprocessor;
@property (nonatomic) NSOperationQueue *imagePreprocessingQueue;
@property (nonatomic) ZMImagePreprocessingTracker *sut;
@property (nonatomic) NSPredicate *fetchPredicate;
@property (nonatomic) NSPredicate *needsProcessingPredicate;
@property (nonatomic) ZMImageMessage *imageMessage1;
@property (nonatomic) ZMImageMessage *imageMessage2;
@property (nonatomic) ZMImageMessage *imageMessage3;
@property (nonatomic) ZMImageMessage *imageMessageExcludedByPredicate;

@end



@implementation ZMImagePreprocessingTrackerTests

- (void)setUp {
    [super setUp];
    self.imageMessage1 = [ZMImageMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    self.imageMessage1.eventID = self.createEventID;
    self.imageMessage2 = [ZMImageMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    self.imageMessage2.eventID = self.createEventID;
    self.imageMessage3 = [ZMImageMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    self.imageMessage3.eventID = self.createEventID;
    self.imageMessageExcludedByPredicate = [ZMImageMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    self.imageMessageExcludedByPredicate.eventID = nil;
    
    self.fetchPredicate = [NSPredicate predicateWithValue:NO];
    self.needsProcessingPredicate = [NSPredicate predicateWithFormat:@"eventID_data != nil"];
    self.preprocessor = [OCMockObject niceMockForClass:[ZMAssetsPreprocessor class]];
    self.imagePreprocessingQueue = [[NSOperationQueue alloc] init];
    self.sut = [[ZMImagePreprocessingTracker alloc] initWithManagedObjectContext:self.uiMOC
                                                            imageProcessingQueue:self.imagePreprocessingQueue
                                                                  fetchPredicate:self.fetchPredicate
                                                        needsProcessingPredicate:self.needsProcessingPredicate
                                                                     entityClass:[ZMImageMessage class] preprocessor:self.preprocessor];
    
    [[[self.preprocessor stub] andReturn:@[[[NSOperation alloc] init]]] operationsForPreprocessingImageOwner:self.imageMessage1];
    [[[self.preprocessor stub] andReturn:@[[[NSOperation alloc] init]]] operationsForPreprocessingImageOwner:self.imageMessage2];
    [[[self.preprocessor stub] andReturn:@[[[NSOperation alloc] init]]] operationsForPreprocessingImageOwner:self.imageMessage3];
}

- (void)tearDown
{
    self.imagePreprocessingQueue.suspended = NO;
    WaitForAllGroupsToBeEmpty(0.5);
    self.imageMessage1 = nil;
    self.imageMessage2 = nil;
    self.imageMessage3 = nil;
    self.preprocessor = nil;
    self.imagePreprocessingQueue = nil;
    [self.sut tearDown];
    self.sut = nil;
    [super tearDown];
}

- (void)testThatItReturnsTheCorrectFetchRequest
{
    // when
    NSFetchRequest *request = [self.sut fetchRequestForTrackedObjects];
    
    // then
    NSFetchRequest *expectedRequest = [ZMImageMessage sortedFetchRequestWithPredicate:self.fetchPredicate];
    XCTAssertEqualObjects(request, expectedRequest);
}


- (void)testThatItAddsTrackedObjects
{
    // given
    NSSet *objects = [NSSet setWithArray:@[self.imageMessage1, self.imageMessage2]];
    
    // when
    self.imagePreprocessingQueue.suspended = YES;
    [self.sut addTrackedObjects:objects];
    
    // then
    XCTAssertTrue([self.sut.imageOwnersBeingPreprocessed containsObject:self.imageMessage1]);
    XCTAssertTrue([self.sut.imageOwnersBeingPreprocessed containsObject:self.imageMessage2]);
    self.imagePreprocessingQueue.suspended = NO;
}

- (void)testThatItDoesNotAddTrackedObjectsThatDoNotMatchPredicateForNeedToPreprocess
{
    // given
    NSSet *objects = [NSSet setWithObject:self.imageMessageExcludedByPredicate];
    
    // when
    self.imagePreprocessingQueue.suspended = YES;
    [self.sut addTrackedObjects:objects];
    
    // then
    XCTAssertFalse(self.sut.hasOutstandingItems);
    XCTAssertEqual(self.sut.imageOwnersThatNeedPreprocessing.count, 0u);
}

@end



@implementation ZMImagePreprocessingTrackerTests (OutstandingItems)

- (void)testThatItHasNoOutstandingItems;
{
    XCTAssertFalse(self.sut.hasOutstandingItems, @"%u / %u",
                   (unsigned) self.sut.imageOwnersThatNeedPreprocessing, (unsigned) self.sut.imageOwnersBeingPreprocessed);
}

- (void)testThatItHasOutstandingItemsWhenItemsAreAdded
{
    // given
    self.imageMessage1.originalImageData = [NSData dataWithBytes:"1" length:1];
    self.imageMessage2.originalImageData = [NSData dataWithBytes:"2" length:1];
    NSSet *objects = [NSSet setWithArray:@[self.imageMessage1, self.imageMessage2]];
    
    // when
    self.imagePreprocessingQueue.suspended = YES;
    [self.sut objectsDidChange:objects];

    // then
    XCTAssertTrue(self.sut.hasOutstandingItems, @"%u / %u",
                  (unsigned) self.sut.imageOwnersThatNeedPreprocessing.count, (unsigned) self.sut.imageOwnersBeingPreprocessed.count);
    self.imagePreprocessingQueue.suspended = NO;
}

- (void)testThatItHasOutstandingItemsWhenItemsAreAddedAndOneIsRemoved
{
    // given
    self.imageMessage1.originalImageData = [NSData dataWithBytes:"1" length:1];
    self.imageMessage2.originalImageData = [NSData dataWithBytes:"2" length:1];
    NSSet *objects = [NSSet setWithArray:@[self.imageMessage1, self.imageMessage2]];
    
    // when
    self.imagePreprocessingQueue.suspended = YES;
    [self.sut objectsDidChange:objects];
    self.imageMessage1.originalImageData = nil;
    [self.sut objectsDidChange:objects];
    
    // then
    XCTAssertTrue(self.sut.hasOutstandingItems, @"%u / %u",
                  (unsigned) self.sut.imageOwnersThatNeedPreprocessing.count, (unsigned) self.sut.imageOwnersBeingPreprocessed.count);
    self.imagePreprocessingQueue.suspended = NO;
}

- (void)testThatItHasNoOutstandingItemsWhenItemsAreAddedAndThenRemoved;
{
    // given
    self.imageMessage1.originalImageData = [NSData dataWithBytes:"1" length:1];
    self.imageMessage2.originalImageData = [NSData dataWithBytes:"2" length:1];
    NSSet *objects = [NSSet setWithArray:@[self.imageMessage1, self.imageMessage2]];
    
    // when
    self.imagePreprocessingQueue.suspended = YES;
    [self.sut objectsDidChange:objects];
    self.imagePreprocessingQueue.suspended = NO;
    [self.imagePreprocessingQueue waitUntilAllOperationsAreFinished];
    self.imageMessage1.originalImageData = nil;
    self.imageMessage2.originalImageData = nil;
    [self.sut objectsDidChange:objects];
    XCTAssert([self waitForAllGroupsToBeEmptyWithTimeout:0.3]);
    
    // then
    XCTAssertFalse(self.sut.hasOutstandingItems, @"%u / %u",
                   (unsigned) self.sut.imageOwnersThatNeedPreprocessing, (unsigned) self.sut.imageOwnersBeingPreprocessed);
}

- (void)testThatItHasNoOutstandingItemsWhenItemsNotMatchingThePredicateChange
{
    // given
    NSSet *objects = [NSSet setWithObject:self.imageMessageExcludedByPredicate];
    
    // when
    self.imagePreprocessingQueue.suspended = YES;
    [self.sut objectsDidChange:objects];
    
    // then
    XCTAssertFalse(self.sut.hasOutstandingItems);
    XCTAssertEqual(self.sut.imageOwnersThatNeedPreprocessing.count, 0u);
}

@end
