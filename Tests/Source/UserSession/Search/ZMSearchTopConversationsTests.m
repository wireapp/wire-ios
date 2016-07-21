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
#import "ZMSearchTopConversations.h"




@interface ZMSearchTopConversationsTests : MessagingTest

@end



@implementation ZMSearchTopConversationsTests

- (ZMConversation *)createConversation;
{
    ZMConversation *c = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    c.conversationType = ZMConversationTypeGroup;
    c.userDefinedName = [NSString stringWithFormat:@"Conversation %d", arc4random_uniform(99)];
    return c;
}

- (NSArray *)createConversations;
{
    NSMutableArray *c = [NSMutableArray array];
    for (size_t i = 0; i < 11; ++i) {
        [c addObject:self.createConversation];
    }
    [self.uiMOC saveOrRollback];
    return c;
}

- (void)testThatItHasNowAsTheCreationDate;
{
    // when
    ZMSearchTopConversations *sut = [[ZMSearchTopConversations alloc] initWithConversations:self.createConversations];
    
    // then
    AssertDateIsRecent(sut.creationDate);
}

- (void)testThatItHasNowAsTheCreationDateWhenCreatingAnEmptyInstance;
{
    // when
    ZMSearchTopConversations *sut = [[ZMSearchTopConversations alloc] init];
    
    // then
    AssertDateIsRecent(sut.creationDate);
}

- (void)testThatItCanBeEncodedAndDecoded;
{
    // given
    NSArray *conversations = self.createConversations;
    ZMSearchTopConversations *sut = [[ZMSearchTopConversations alloc] initWithConversations:conversations];

    // when
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:sut forKey:@"sut"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    unarchiver.requiresSecureCoding = YES;
    ZMSearchTopConversations *decoded = [unarchiver decodeObjectOfClass:ZMSearchTopConversations.class forKey:@"sut"];
    
    // then
    XCTAssertEqualObjects(sut.creationDate, decoded.creationDate);
    XCTAssertEqualObjects([sut conversationsInManagedObjectContext:self.uiMOC],
                          [decoded conversationsInManagedObjectContext:self.uiMOC]);
}

- (void)testThatItCanCompareIdenticalConversations;
{
    // given
    NSArray *conversations = self.createConversations;
    ZMSearchTopConversations *sut1 = [[ZMSearchTopConversations alloc] initWithConversations:conversations];
    ZMSearchTopConversations *sut2 = [[ZMSearchTopConversations alloc] initWithConversations:conversations];
    
    // then
    XCTAssertTrue([sut1 hasConversationsIdenticalTo:sut2]);
    XCTAssertTrue([sut2 hasConversationsIdenticalTo:sut1]);
}

- (void)testThatItCanCompareMismatchingConversations;
{
    // given
    NSArray *conversationsA = self.createConversations;
    NSArray *conversationsB = self.createConversations;
    ZMSearchTopConversations *sut1 = [[ZMSearchTopConversations alloc] initWithConversations:conversationsA];
    ZMSearchTopConversations *sut2 = [[ZMSearchTopConversations alloc] initWithConversations:conversationsB];
    
    // then
    XCTAssertFalse([sut1 hasConversationsIdenticalTo:sut2]);
    XCTAssertFalse([sut2 hasConversationsIdenticalTo:sut1]);
}

- (void)testThatItCanBeEncodedAndDecodedOnDifferentManagedObjectContexts;
{
    // given
    NSArray *conversations = self.createConversations;
    NSArray *moids = [conversations mapWithBlock:^id(ZMConversation *c) {
        return c.objectID;
    }];
    ZMSearchTopConversations *sut = [[ZMSearchTopConversations alloc] initWithConversations:conversations];
    
    // when
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:sut forKey:@"sut"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    unarchiver.requiresSecureCoding = YES;
    ZMSearchTopConversations *decoded = [unarchiver decodeObjectOfClass:ZMSearchTopConversations.class forKey:@"sut"];
    
    // then
    [self.syncMOC performGroupedBlockAndWait:^{
        NSArray *all = [decoded conversationsInManagedObjectContext:self.syncMOC];
        for (NSManagedObject *mo in all) {
            XCTAssertFalse(mo.isFault, @"%@", mo);
        }
        NSArray *result = [all mapWithBlock:^id(ZMConversation *c) {
            return c.objectID;
        }];
        XCTAssertEqualObjects(result, moids);
    }];
}

@end
