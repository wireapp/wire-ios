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
@import WireDataModel;
@import WireSystem;

#import <WireRequestStrategy/ZMRequestGenerator.h>
#import <WireRequestStrategy/ZMContextChangeTracker.h>

@class ZMTransportRequest;
@class ZMSyncStrategy;
@class ZMUpdateEvent;
@class NSManagedObjectContext;
@protocol ZMTransportData;
@protocol ZMEventConsumer;
@class ZMConversation;

NS_ASSUME_NONNULL_BEGIN

@protocol ZMObjectStrategy <NSObject, ZMEventConsumer, ZMRequestGeneratorSource, ZMContextChangeTrackerSource>
@end


@interface ZMObjectSyncStrategy : NSObject <TearDownCapable>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly, weak) NSManagedObjectContext *managedObjectContext;

- (void)tearDown;

@end

NS_ASSUME_NONNULL_END
