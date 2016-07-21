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


#import <XCTest/XCTest.h>
#import <zmessaging/zmessaging.h>
#import "ZMSnapshotTestCase.h"
#import "MockConversation.h"
#import "MockUser.h"
#import "ParticipantsChangedView.h"

@interface ParticipantsChangedViewTests : ZMSnapshotTestCase

@property (nonatomic) NSArray *mockUsers;

@end

@implementation ParticipantsChangedViewTests

- (void)setUp {
    [super setUp];
    self.mockUsers = [MockLoader mockObjectsOfClass:[MockUser class] fromFile:@"a_lot_of_people.json"];
}

- (ParticipantsChangedView *)participantChangedViewForAction:(ParticipantsChangedAction)action selfPerformedAction:(BOOL)selfPerformedAction userCount:(NSUInteger)userCount
{
    ParticipantsChangedView *participantsChangedView = [[ParticipantsChangedView alloc] init];
    participantsChangedView.userPerformingAction = (ZMUser *)(selfPerformedAction ? [MockUser mockSelfUser] : [self.mockUsers firstObject]);
    participantsChangedView.participants = [self.mockUsers subarrayWithRange:NSMakeRange(0, userCount)];
    participantsChangedView.action = action;
    
    if (! selfPerformedAction) {
        participantsChangedView.participants = [participantsChangedView.participants arrayByAddingObject:[MockUser mockSelfUser]];
    }
    
    participantsChangedView.bounds = CGRectMake(0.0, 0.0, 320.0, 9999);
    CGSize size = [participantsChangedView systemLayoutSizeFittingSize:CGSizeMake(320.0, 0.0) withHorizontalFittingPriority: UILayoutPriorityRequired verticalFittingPriority: UILayoutPriorityFittingSizeLevel];
    participantsChangedView.bounds = CGRectMake(0.0, 0.0, size.width, size.height);
    
    return participantsChangedView;
}

- (void)testYouStartedConversationWith_0_Participants
{
    ZMVerifyView([self participantChangedViewForAction:ParticipantsChangedActionStarted selfPerformedAction:YES userCount:0]);
}

- (void)testYouStartedConversationWith_1_Participants
{
    ZMVerifyView([self participantChangedViewForAction:ParticipantsChangedActionStarted selfPerformedAction:YES userCount:1]);
}

- (void)testYouStartedConversationWith_3_Participants
{
    ZMVerifyView([self participantChangedViewForAction:ParticipantsChangedActionStarted selfPerformedAction:YES userCount:3]);
}

- (void)testYouStartedConversationWith_10_Participants
{
    ZMVerifyView([self participantChangedViewForAction:ParticipantsChangedActionStarted selfPerformedAction:YES userCount:10]);
}

- (void)testOtherStartedConversationWith_3_Participants
{
    ZMVerifyView([self participantChangedViewForAction:ParticipantsChangedActionStarted selfPerformedAction:NO userCount:3]);
}

- (void)testOtherStartedConversationWith_10_Participants
{
    ZMVerifyView([self participantChangedViewForAction:ParticipantsChangedActionStarted selfPerformedAction:NO userCount:10]);
}

@end
