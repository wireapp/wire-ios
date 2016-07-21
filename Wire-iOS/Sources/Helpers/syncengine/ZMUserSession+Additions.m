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


#import "ZMUserSession+Additions.h"
#import "AppDelegate.h"
#import "NotificationWindowRootViewController.h"
#import "NetworkStatusViewController.h"
#import "ObjcAssociatedObjectHelpers.h"



@implementation ZMUserSession (Additions)

/// @return YES if network is offline
- (BOOL)checkNetworkAndFlashIndicatorIfNecessary
{
    return [self checkNetworkAndFlashIndicatorIfNecessaryAndShowAlert:NO];
}

/// @return YES if network is offline
- (BOOL)checkNetworkAndFlashIndicatorIfNecessaryAndShowAlert:(BOOL)showAlert
{
    if (self.networkState == ZMNetworkStateOffline) {
        [[AppDelegate sharedAppDelegate].notificationWindowController.networkStatusViewController flashNetworkStatusIfNecessaryAndShowAlert:showAlert];
        return YES;
    }
    return NO;
}

SYNTHESIZE_ASC_OBJ(initialSyncOnceCompleted, setInitialSyncOnceCompleted);

@end
