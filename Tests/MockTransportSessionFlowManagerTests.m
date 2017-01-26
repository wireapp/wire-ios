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


#import "MockFlowManager.h"
#import "MockTransportSessionTests.h"
#import "MockUser.h"
#import "MockPushEvent.h"

@interface MockTransportSessionFlowManagerTests : MockTransportSessionTests

@end

@implementation MockTransportSessionFlowManagerTests

- (void)testThatItReturnsAMockFlowManager;
{
    // WHEN
    id flowManager1 = self.sut.flowManager;
    id flowManager2 = self.sut.flowManager;
    MockFlowManager *mockFlowManager = self.sut.mockFlowManager;
    
    // THEN
    XCTAssertNotNil(flowManager1);
    XCTAssertEqual(flowManager1, flowManager2);
    XCTAssertEqual((id) flowManager1, (id) mockFlowManager);
    XCTAssertTrue([flowManager1 isKindOfClass:[MockFlowManager class]]);
}

- (void)testThatTheFlowManagerCanAquireFlows;
{
    // GIVEN
    id flowManager = self.sut.flowManager;
    MockFlowManager *mockFlowManager = self.sut.mockFlowManager;
    NSString *identifier = [NSUUID createUUID].transportString;
    
    // WHEN
    XCTAssertTrue([(MockFlowManager *)flowManager acquireFlows:identifier]);
    
    // THEN
    XCTAssertEqualObjects(mockFlowManager.aquiredFlows, @[identifier]);
    XCTAssertEqualObjects(mockFlowManager.releasedFlows, @[]);
}

- (void)testThatTheFlowManagerCanReleaseFlows;
{
    // GIVEN
    id flowManager = self.sut.flowManager;
    MockFlowManager *mockFlowManager = self.sut.mockFlowManager;
    NSString *identifier = [NSUUID createUUID].transportString;
    
    // WHEN
    [flowManager releaseFlows:identifier];
    
    // THEN
    XCTAssertEqualObjects(mockFlowManager.aquiredFlows, @[]);
    XCTAssertEqualObjects(mockFlowManager.releasedFlows, @[identifier]);
}

- (void)testThatItSendsAnEventWhenSimulatingSendingVideo_YES
{
    // GIVEN
    __block  MockUser *user;
    __block  MockUser *selfUser;
    __block MockConversation *conversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"selfUser"];
        user = [session insertUserWithName:@"name"];
        conversation = [session insertOneOnOneConversationWithSelfUser:self.sut.selfUser otherUser:user];
        [conversation addUserToVideoCall:user];
        user.isSendingVideo = NO;
    }];
    
    NSUInteger eventCount = self.sut.updateEvents.count;
    
    // WHEN
    [self.sut.mockFlowManager simulateOther:user isSendingVideo:YES conv:nil];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertNotEqual(self.sut.updateEvents.count, eventCount);
    MockPushEvent *event =  self.sut.updateEvents.lastObject;
    NSDictionary *payload = @{@"participants": @{selfUser.identifier: @{@"state": @"idle", @"videod": @NO},
                                                 user.identifier: @{@"state": @"joined", @"videod": @YES}
                                                 },
                              @"conversation": conversation.identifier,
                              @"self": [NSNull null],
                              @"type": @"call.state"
                              };
    XCTAssertEqualObjects(event.payload, payload);
}

- (void)testThatItSendsAnEventWhenSimulatingSendingVideo_NO
{
    // GIVEN
    __block  MockUser *user;
    __block  MockUser *selfUser;
    __block MockConversation *conversation;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"selfUser"];
        user = [session insertUserWithName:@"name"];
        conversation = [session insertOneOnOneConversationWithSelfUser:self.sut.selfUser otherUser:user];
        [conversation addUserToVideoCall:user];
        user.isSendingVideo = YES;
    }];
    
    NSUInteger eventCount = self.sut.updateEvents.count;
    
    // WHEN
    [self.sut.mockFlowManager simulateOther:user isSendingVideo:NO conv:nil];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    XCTAssertNotEqual(self.sut.updateEvents.count, eventCount);
    MockPushEvent *event =  self.sut.updateEvents.lastObject;
    NSDictionary *payload = @{@"participants": @{selfUser.identifier: @{@"state": @"idle", @"videod": @NO},
                                                 user.identifier: @{@"state": @"joined", @"videod": @NO}
                                                 },
                              @"conversation": conversation.identifier,
                              @"self": [NSNull null],
                              @"type": @"call.state"
                              };
    XCTAssertEqualObjects(event.payload, payload);
}

@end
