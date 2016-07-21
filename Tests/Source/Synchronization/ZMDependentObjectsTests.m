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

@import ZMCDataModel;

#import "MessagingTest.h"
#import "ZMDependentObjects.h"


@interface ZMDependentObjectsTests : MessagingTest

@property (nonatomic) ZMDependentObjects *sut;
@property (nonatomic) ZMConversation *conversation1;
@property (nonatomic) ZMConversation *conversation2;
@property (nonatomic) ZMTextMessage *messageA;
@property (nonatomic) ZMTextMessage *messageB;
@property (nonatomic) ZMTextMessage *messageC;
@property (nonatomic) ZMTextMessage *messageD;

@end



@implementation ZMDependentObjectsTests

- (void)setUp
{
    [super setUp];
    self.sut = [[ZMDependentObjects alloc] init];
    self.conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    self.conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    self.messageA = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    self.messageB = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    self.messageC = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    self.messageD = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
}

- (void)tearDown
{
    self.sut = nil;
    [super tearDown];
}

- (void)testThatItEnumeratesAllObjectsInTheOrderTheyWereAdded
{
    // when
    [self.sut addManagedObject:self.messageA withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageB withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageC withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageD withDependency:self.conversation1];
    NSMutableArray *result = [NSMutableArray array];
    [self.sut enumerateManagedObjectsForDependency:self.conversation1 withBlock:^BOOL(ZMManagedObject *mo) {
        [result addObject:mo];
        return YES;
    }];
    
    // then
    NSArray *expected = @[self.messageA, self.messageB, self.messageC, self.messageD];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatItOnlyReturnsAnObjectOnceWhenItIsAddedMultipleTimes
{
    // when
    [self.sut addManagedObject:self.messageA withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageA withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageA withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageA withDependency:self.conversation1];
    NSMutableArray *result = [NSMutableArray array];
    [self.sut enumerateManagedObjectsForDependency:self.conversation1 withBlock:^BOOL(ZMManagedObject *mo) {
        [result addObject:mo];
        return YES;
    }];
    
    // then
    NSArray *expected = @[self.messageA];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatItEnumeratesAllObjectsAgainIfTheyWereNotToBeRemoved;
{
    // when
    [self.sut addManagedObject:self.messageA withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageB withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageC withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageD withDependency:self.conversation1];
    [self.sut enumerateManagedObjectsForDependency:self.conversation1 withBlock:^BOOL(ZMManagedObject *mo) {
        NOT_USED(mo);
        return NO;
    }];
    NSMutableArray *result = [NSMutableArray array];
    [self.sut enumerateManagedObjectsForDependency:self.conversation1 withBlock:^BOOL(ZMManagedObject *mo) {
        [result addObject:mo];
        return YES;
    }];

    NSArray *expected = @[self.messageA, self.messageB, self.messageC, self.messageD];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatItRemovesObjects
{
    // when
    [self.sut addManagedObject:self.messageA withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageB withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageC withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageD withDependency:self.conversation1];
    [self.sut enumerateManagedObjectsForDependency:self.conversation1 withBlock:^BOOL(ZMManagedObject *mo) {
        return (mo == self.messageA);
    }];
    NSMutableArray *result = [NSMutableArray array];
    [self.sut enumerateManagedObjectsForDependency:self.conversation1 withBlock:^BOOL(ZMManagedObject *mo) {
        [result addObject:mo];
        return YES;
    }];
    
    NSArray *expected = @[self.messageB, self.messageC, self.messageD];
    XCTAssertEqualObjects(result, expected);
}

- (void)testThatItEnumeratesObjectsForTheCorrectDependency;
{
    // when
    [self.sut addManagedObject:self.messageA withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageB withDependency:self.conversation1];
    [self.sut addManagedObject:self.messageC withDependency:self.conversation2];
    [self.sut addManagedObject:self.messageD withDependency:self.conversation2];
    NSMutableArray *result1 = [NSMutableArray array];
    [self.sut enumerateManagedObjectsForDependency:self.conversation1 withBlock:^BOOL(ZMManagedObject *mo) {
        [result1 addObject:mo];
        return YES;
    }];
    NSMutableArray *result2 = [NSMutableArray array];
    [self.sut enumerateManagedObjectsForDependency:self.conversation2 withBlock:^BOOL(ZMManagedObject *mo) {
        [result2 addObject:mo];
        return YES;
    }];
    
    // then
    NSArray *expected = @[self.messageA, self.messageB];
    XCTAssertEqualObjects(result1, expected);
    expected = @[self.messageC, self.messageD];
    XCTAssertEqualObjects(result2, expected);
}

- (void)testThatItDoesNotEnumerateWhenNoObjectsAreAdded;
{
    [self.sut enumerateManagedObjectsForDependency:self.conversation1 withBlock:^BOOL(ZMManagedObject *mo) {
        NOT_USED(mo);
        XCTFail();
        return YES;
    }];
}

@end
