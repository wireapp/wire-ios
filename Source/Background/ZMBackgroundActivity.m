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


@import UIKit;
@import ZMCSystem;

#import "ZMBackgroundActivity.h"


@interface ZMBackgroundActivity ()

@property (nonatomic) UIBackgroundTaskIdentifier identifier;
@property (nonatomic) id<ZMSGroupQueue> mainGroupQueue;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, weak) UIApplication *application;
@property (atomic) BOOL ended;

@end



@implementation ZMBackgroundActivity

+ (instancetype)beginBackgroundActivityWithName:(NSString *)taskName groupQueue:(id<ZMSGroupQueue>)groupQueue application:(UIApplication *)application
{    
    ZMBackgroundActivity *activity = [[self alloc] init];
    activity.name           = taskName;
    activity.mainGroupQueue = groupQueue;
    activity.application = application;
    
    activity.identifier = [application beginBackgroundTaskWithName:activity.name expirationHandler:^(){
        [activity endActivity];
    }];
    return activity;
}

+ (instancetype)beginBackgroundActivityWithName:(NSString *)taskName
                                     groupQueue:(id<ZMSGroupQueue>)groupQueue
                              expirationHandler:(void (^)(void))handler
                                    application:(UIApplication *)application
{
    ZMBackgroundActivity *activity = [[self alloc] init];
    activity.name           = taskName;
    activity.mainGroupQueue = groupQueue;
    activity.application = application;
    
    activity.identifier = [application beginBackgroundTaskWithName:activity.name expirationHandler:^(){
        if (handler != nil) {
            handler();
        }
        [activity endActivity];
    }];
    return activity;
}

- (void)endActivity;
{
    if (! self.ended) {
        self.ended = YES;
        UIBackgroundTaskIdentifier localIdentifier = self.identifier;
        ZM_WEAK(self);
        [self.mainGroupQueue performGroupedBlock:^{
            ZM_STRONG(self);
            [self.application endBackgroundTask:localIdentifier];
        }];
        
    }
}

@end
