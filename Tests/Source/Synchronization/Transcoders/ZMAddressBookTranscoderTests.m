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


#import "MessagingTest.h"
#import "ZMAddressBook.h"
#import "ZMAddressBookSync.h"
#import "ZMEmptyAddressBookSync.h"

#import "ZMAddressBookTranscoder+Testing.h"

@interface ZMAddressBookTranscoderTests : MessagingTest
@property (nonatomic) id mockAddressBook;
@property (nonatomic) id mockAddressBookSync;
@property (nonatomic) id mockEmptyAddressBookSync;
@property (nonatomic) ZMAddressBookTranscoder *sut;
@end


@implementation ZMAddressBookTranscoderTests

- (void)setUp
{
    [super setUp];
    
    self.mockAddressBook = [OCMockObject niceMockForClass:[ZMAddressBook class]];
    
    self.mockAddressBookSync = [OCMockObject niceMockForClass:[ZMAddressBookSync class]];
    self.mockEmptyAddressBookSync = [OCMockObject niceMockForClass:[ZMEmptyAddressBookSync class]];
    
    [self verifyMockLater:self.mockAddressBookSync];
    [self verifyMockLater:self.mockEmptyAddressBookSync];
    
    self.sut = [[ZMAddressBookTranscoder alloc] initWithManagedObjectContext:self.uiMOC
                                                             addressBookSync:self.mockAddressBookSync
                                                        emptyAddressBookSync:self.mockEmptyAddressBookSync];
}

- (void)tearDown
{
    self.mockAddressBook = nil;
    self.mockAddressBookSync = nil;
    self.mockEmptyAddressBookSync = nil;
    [self.sut tearDown];
    [super tearDown];
}

- (void)testThatItOnlyProcessesAddressBookSyncBeforeEmptyAddressBookSync
{
    // when
    NSArray *generators = self.sut.requestGenerators;
    
    // then
    XCTAssertEqual(generators.count, 2u);
    XCTAssertEqual(generators.firstObject, self.mockAddressBookSync);
    XCTAssertEqual(generators.lastObject, self.mockEmptyAddressBookSync);
}

- (void)testThatItHasNotContextChangeTrackers;
{
    // when
    NSArray *trackers = self.sut.contextChangeTrackers;
    
    // then
    XCTAssertEqualObjects(trackers, @[]);
}

@end
