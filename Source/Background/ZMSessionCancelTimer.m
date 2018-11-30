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
#import "ZMSessionCancelTimer+Internal.h"
#import "ZMURLSession.h"
#import "ZMTransportSession.h"

const NSTimeInterval ZMSessionCancelTimerDefaultTimeout = 5;

@interface ZMSessionCancelTimer () <ZMTimerClient>

@property (nonatomic) ZMURLSession *session;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic, readwrite) ZMTimer *timer;
@property (nonatomic, readwrite) BackgroundActivity *activity;

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
    self.activity = [[BackgroundActivityFactory sharedFactory] startBackgroundActivityWithName:NSStringFromClass(self.class)];

    // Configure the expiration timer to cancel the tasks if the app is being suspended
    __weak ZMSessionCancelTimer *weakSelf = self;
    self.activity.expirationHandler = ^{
        [weakSelf handleExpiration];
    };

    // If the app can perform background activites, start the timer, otherwise, cancel requests immediately
    if (self.activity) {
        [self.timer fireAfterTimeInterval:self.timeout];
    } else {
        [self handleExpiration];
    }
}

- (void)cancel;
{
    [self.timer cancel];
    if (self.activity) {
        [[BackgroundActivityFactory sharedFactory] endBackgroundActivity:self.activity];
    }
    self.activity = nil;
}

- (void)timerDidFire:(ZMTimer *)timer
{
    NOT_USED(timer);
    [self handleExpiration];
}

- (void)handleExpiration
{
    // Cancel the timer if the app is expiring
    if (self.timer.state == ZMTimerStateStarted) {
        [self.timer cancel];
    }

    // Cancel requests and end the background activity
    BackgroundActivity *activity = self.activity;
    self.activity = nil;

    [self.session cancelAllTasksWithCompletionHandler:^{
        [ZMTransportSession notifyNewRequestsAvailable:self];
        if (activity) {
            [[BackgroundActivityFactory sharedFactory] endBackgroundActivity:activity];
        }
    }];
}

@end
