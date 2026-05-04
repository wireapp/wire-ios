//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

#import "MockTransportSessionTests.h"
@import WireMockTransport;

@interface MockTransportSessionAddressBookTests : MockTransportSessionTests

@end

@implementation MockTransportSessionAddressBookTests

- (void)testThatWhenPostingAddressBookItReturnsAllUserIDsThatAreNotSelf
{
    // GIVEN
    __block MockUser *user1;
    __block MockUser *user2;
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"SelfUser"];
        user1 = [session insertUserWithName:@"User1 AAAA"];
        user2 = [session insertUserWithName:@"User2 AABB"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

@end
