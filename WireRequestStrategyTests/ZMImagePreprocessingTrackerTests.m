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


@import zimages;
@import ZMCDataModel;
@import ZMTesting;

#import <WireRequestStrategy/ZMImagePreprocessingTracker+Testing.h>


@interface ZMImagePreprocessingTrackerTests : ZMTBaseTest

@property (nonatomic) id preprocessor;
@property (nonatomic) ZMTestSession *testSession;
@property (nonatomic) NSOperationQueue *imagePreprocessingQueue;
@property (nonatomic) ZMImagePreprocessingTracker *sut;
@property (nonatomic) NSPredicate *fetchPredicate;
@property (nonatomic) NSPredicate *needsProcessingPredicate;

@property (nonatomic)  ZMAssetClientMessage *imageMessage1;
@property (nonatomic)  ZMAssetClientMessage *imageMessage2;
@property (nonatomic)  ZMAssetClientMessage *imageMessage3;
@property (nonatomic)  ZMAssetClientMessage *imageMessageExcludedByPredicate;

@end



@implementation ZMImagePreprocessingTrackerTests

- (void)setUp {
    [super setUp];
    
    self.testSession = [[ZMTestSession alloc] initWithDispatchGroup:self.dispatchGroup];
    [self.testSession prepareForTestNamed:self.name];
    
    self.imageMessage1 = [ZMAssetClientMessage insertNewObjectInManagedObjectContext:self.testSession.uiMOC];
    self.imageMessage1.nonce = [NSUUID createUUID];
    self.imageMessage2 = [ZMAssetClientMessage insertNewObjectInManagedObjectContext:self.testSession.uiMOC];
    self.imageMessage2.nonce = [NSUUID createUUID];
    self.imageMessage3 = [ZMAssetClientMessage insertNewObjectInManagedObjectContext:self.testSession.uiMOC];
    self.imageMessage3.nonce = [NSUUID createUUID];
    self.imageMessageExcludedByPredicate = [ZMAssetClientMessage insertNewObjectInManagedObjectContext:self.testSession.uiMOC];
    
    self.fetchPredicate = [NSPredicate predicateWithValue:NO];
    self.needsProcessingPredicate = [NSPredicate predicateWithFormat:@"nonce_data != nil"];
    self.preprocessor = [OCMockObject niceMockForClass:[ZMAssetsPreprocessor class]];
    self.imagePreprocessingQueue = [[NSOperationQueue alloc] init];
    self.sut = [[ZMImagePreprocessingTracker alloc] initWithManagedObjectContext:self.testSession.uiMOC
                                                            imageProcessingQueue:self.imagePreprocessingQueue
                                                                  fetchPredicate:self.fetchPredicate
                                                        needsProcessingPredicate:self.needsProcessingPredicate
                                                                     entityClass:[ZMAssetClientMessage class] preprocessor:self.preprocessor];
    
    [[[self.preprocessor stub] andReturn:@[[[NSOperation alloc] init]]] operationsForPreprocessingImageOwner:self.imageMessage1.imageAssetStorage];
    [[[self.preprocessor stub] andReturn:@[[[NSOperation alloc] init]]] operationsForPreprocessingImageOwner:self.imageMessage2.imageAssetStorage];
    [[[self.preprocessor stub] andReturn:@[[[NSOperation alloc] init]]] operationsForPreprocessingImageOwner:self.imageMessage3.imageAssetStorage];
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
    [self.testSession tearDown];
    [super tearDown];
}

- (void)testThatItReturnsTheCorrectFetchRequest
{
    // when
    NSFetchRequest *request = [self.sut fetchRequestForTrackedObjects];
    
    // then
    NSFetchRequest *expectedRequest = [ZMAssetClientMessage sortedFetchRequestWithPredicate:self.fetchPredicate];
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
    [self.imageMessage1.imageAssetStorage updateMessageWithImageData:[NSData dataWithBytes:"1" length:1] forFormat:ZMImageFormatOriginal];
    [self.imageMessage2.imageAssetStorage updateMessageWithImageData:[NSData dataWithBytes:"2" length:1] forFormat:ZMImageFormatOriginal];
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
    [self.imageMessage1.imageAssetStorage updateMessageWithImageData:[NSData dataWithBytes:"1" length:1] forFormat:ZMImageFormatOriginal];
    [self.imageMessage2.imageAssetStorage updateMessageWithImageData:[NSData dataWithBytes:"2" length:1] forFormat:ZMImageFormatOriginal];
    NSSet *objects = [NSSet setWithArray:@[self.imageMessage1, self.imageMessage2]];
    
    // when
    self.imagePreprocessingQueue.suspended = YES;
    [self.sut objectsDidChange:objects];
    [self.imageMessage1.imageAssetStorage updateMessageWithImageData:NSData.data forFormat:ZMImageFormatOriginal];
    [self.sut objectsDidChange:objects];
    
    // then
    XCTAssertTrue(self.sut.hasOutstandingItems, @"%u / %u",
                  (unsigned) self.sut.imageOwnersThatNeedPreprocessing.count, (unsigned) self.sut.imageOwnersBeingPreprocessed.count);
    self.imagePreprocessingQueue.suspended = NO;
}

- (void)testThatItHasNoOutstandingItemsWhenItemsAreAddedAndThenRemoved;
{
    // given
    [self.imageMessage1.imageAssetStorage updateMessageWithImageData:[NSData dataWithBytes:"1" length:1] forFormat:ZMImageFormatOriginal];
    [self.imageMessage2.imageAssetStorage updateMessageWithImageData:[NSData dataWithBytes:"2" length:1] forFormat:ZMImageFormatOriginal];
    NSSet *objects = [NSSet setWithArray:@[self.imageMessage1, self.imageMessage2]];
    
    // when
    self.imagePreprocessingQueue.suspended = YES;
    [self.sut objectsDidChange:objects];
    self.imagePreprocessingQueue.suspended = NO;
    [self.imagePreprocessingQueue waitUntilAllOperationsAreFinished];
    [self.imageMessage1.imageAssetStorage updateMessageWithImageData:NSData.data forFormat:ZMImageFormatOriginal];
    [self.imageMessage2.imageAssetStorage updateMessageWithImageData:NSData.data forFormat:ZMImageFormatOriginal];
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
