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


@import WireSystem;
@import WireUtilities;

#import <WireTransport/WireTransport-Swift.h>

#import "ZMSessionCancelTimer.h"
#import "ZMURLSession.h"
#import "ZMBackgroundActivity.h"
#import "ZMTransportSession.h"

const NSTimeInterval ZMSessionCancelTimerDefaultTimeout = 5;


@interface ZMSessionCancelTimer () <ZMTimerClient>

@property (nonatomic) ZMURLSession *session;
@property (nonatomic) ZMTimer *timer;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic) ZMBackgroundActivity *activity;

@end


@implementation ZMSessionCancelTimer

ZM_EMPTY_ASSERTING_INIT();

- (instancetype)initWithURLSession:(ZMURLSession *)session timeout:(NSTimeInterval)timeout;
{
    self = [super init];
    if (self) {
        self.session = session;
        self.timer = [ZMTimer timerWithTarget:self];
        self.timeout = timeout;
    }
    return self;
}

- (void)start;
{
    self.activity = [[BackgroundActivityFactory sharedInstance] backgroundActivityWithName:NSStringFromClass(self.class)];
    [self.timer fireAfterTimeInterval:self.timeout];
}

- (void)cancel;
{
    [self.timer cancel];
    [self.activity endActivity];
    self.activity = nil;
}

- (void)timerDidFire:(ZMTimer *)timer
{
    NOT_USED(timer);
    ZMBackgroundActivity *activity = self.activity;
    self.activity = nil;
    [self.session cancelAllTasksWithCompletionHandler:^{
        [ZMTransportSession notifyNewRequestsAvailable:self];
        [activity endActivity];
    }];
}

@end
