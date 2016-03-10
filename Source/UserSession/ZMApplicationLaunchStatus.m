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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


@import UIKit;
@import ZMUtilities;
@import ZMCSystem;

#import "ZMApplicationLaunchStatus.h"

@interface ZMApplicationLaunchStatus ()

@property (nonatomic) BOOL wasLaunchedFromBackgroundFetch;
@property (nonatomic) BOOL wasLaunchedFromVoIP;

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) BOOL tornDown;

@end

@implementation ZMApplicationLaunchStatus


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super init];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        self.wasLaunchedFromBackgroundFetch = NO;
        self.wasLaunchedFromVoIP = NO;
    }
    return self;
}


- (ZMApplicationLaunchState)currentState
{
    if (self.wasLaunchedFromBackgroundFetch) {
        return ZMApplicationLaunchStateBackgroundFetch;
    }
    if (self.wasLaunchedFromVoIP) {
        return ZMApplicationLaunchStateBackground;
    }
    return ZMApplicationLaunchStateForeground;
}


- (void)startedBackgroundFetch
{
    [self.managedObjectContext performGroupedBlock:^{
        self.wasLaunchedFromBackgroundFetch = YES;
    }];
}

- (void)finishedBackgroundFetch
{
    [self resetLaunchState];
}

- (void)appWillEnterForeground
{
    [self resetLaunchState];
}

- (void)resetLaunchState
{
    [self.managedObjectContext performGroupedBlock:^{
        self.wasLaunchedFromBackgroundFetch = NO;
        self.wasLaunchedFromVoIP = NO;
    }];
}

- (void)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    NOT_USED(launchOptions);
    self.wasLaunchedFromVoIP = (application.applicationState == UIApplicationStateBackground);
}

@end
