//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

@import Foundation;
@import WireRequestStrategy;

@class SyncStatus;
@class OperationStatus;
@class PushNotificationStatus;
@class NotificationsTracker;
@class NSManagedObjectContext;
@protocol ZMApplicationStatus;
@protocol UpdateEventProcessor;

extern NSUInteger const ZMMissingUpdateEventsTranscoderListPageSize;

@interface ZMMissingUpdateEventsTranscoder : ZMAbstractRequestStrategy <ZMObjectStrategy>

@property (nonatomic, readonly) BOOL hasLastUpdateEventID;
@property (nonatomic, readonly) BOOL isDownloadingMissingNotifications;
@property (nonatomic, readonly) NSUUID * _Nullable lastUpdateEventID;

- (instancetype _Nonnull)initWithManagedObjectContext:(NSManagedObjectContext * _Nonnull)managedObjectContext
                        notificationsTracker:(NotificationsTracker * _Nullable)notificationsTracker
                              eventProcessor:(id<UpdateEventProcessor> _Nonnull)eventProcessor
                           applicationStatus:(id<ZMApplicationStatus> _Nonnull)applicationStatus
                      pushNotificationStatus:(PushNotificationStatus * _Nonnull)pushNotificationStatus
                                  syncStatus:(SyncStatus * _Nonnull)syncStatus
                             operationStatus:(OperationStatus * _Nonnull)operationStatus
                  useLegacyPushNotifications:(BOOL)useLegacyPushNotifications
                       lastEventIDRepository:(id<LastEventIDRepositoryInterface> _Nonnull)lastEventIDRepository;

- (void)startDownloadingMissingNotifications;

@end
