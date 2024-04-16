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

@import UIKit;
@import WireTransport;
@import WireSyncEngine;
@import WireDataModel;
@import WireRequestStrategy;
@import OCMock;

#import <WireSyncEngine/WireSyncEngine-Swift.h>
#import "MessagingTest.h"

@class MockSyncStateDelegate;
@class MockEventConsumer;
@class MockContextChangeTracker;


@interface ZMSyncStrategyTests : MessagingTest <ZMRequestCancellation>

@property (nonatomic) ZMSyncStrategy *sut;

@property (nonatomic) MockSyncStateDelegate *syncStateDelegate;
@property (nonatomic) OperationStatus *operationStatus;

@property (nonatomic) MockEventConsumer *mockEventConsumer;
@property (nonatomic) MockContextChangeTracker *mockContextChangeTracker;

@property (nonatomic) NSFetchRequest *fetchRequestForTrackedObjects1;
@property (nonatomic) NSFetchRequest *fetchRequestForTrackedObjects2;

@end

