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


@import Foundation;

#import "ZMSyncStateDelegate.h"

extern NSString *const ZMApplicationDidEnterEventProcessingStateNotificationName;

@class ZMSyncState;

@protocol ZMStateMachineDelegate <ZMSyncStateDelegate>

@property (nonatomic, readonly) ZMSyncState *unauthenticatedState; ///< need to log in. Will sturtup timer to try to login while waiting for email verification.
@property (nonatomic, readonly) ZMSyncState *unauthenticatedBackgroundState; ///< need to log in, but we are in the background. In background we don't keep trying to login on timer waiting for email verification.
@property (nonatomic, readonly) ZMSyncState *eventProcessingState; ///< can normally process events

///Hard sync is performd if application was not in use for 3 days (setup on backend) or more and we don't know exact last notification id, so we need to sync everything.

@property (nonatomic, readonly) ZMSyncState *slowSyncPhaseOneState; ///< first part of the hard sync. Gets all conversations (with only last event id and meta data) and connections and builds users lists using conversations and connections meta data.
@property (nonatomic, readonly) ZMSyncState *slowSyncPhaseTwoState; ///< second part of the hard sync. Fetches all users you are connected with.

@property (nonatomic, readonly) ZMSyncState *updateEventsCatchUpPhaseOneState; ///< start procedure to catch up with missing notifications
@property (nonatomic, readonly) ZMSyncState *updateEventsCatchUpPhaseTwoState; ///< finish catching up with missing notifications

@property (nonatomic, readonly) ZMSyncState *downloadLastUpdateEventIDState; ///< handle getting the last notification ID. Sent before doing slow sync. After that we don't do slow sync and only update on noe event (updateEventsCatchUpPhaseOneState, updateEventsCatchUpPhaseTwoState).

@property (nonatomic, readonly) ZMSyncState *preBackgroundState; ///< waits until we are ready to go to background
@property (nonatomic, readonly) ZMSyncState *backgroundState; ///< handles background requests

@property (nonatomic, readonly) ZMSyncState *backgroundFetchState;  ///< does background fetching on iOS. Fetches new notifications since last that we have.

- (void)startQuickSync; ///< go to the first state of the quick sync chain (quick sync = updateEventsCatchUp)
- (void)startSlowSync; ///< go to the first state of the slow sync chain

@property (nonatomic, readonly) BOOL isUpdateEventStreamActive;
@property (nonatomic, readonly) ZMSyncState *currentState;

- (void)goToState:(ZMSyncState *)state;
- (void)didStartSlowSync;

@end
