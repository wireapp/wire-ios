//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
@import WireUtilities;

@protocol ZMApplication;
@protocol FlowManagerType;
@protocol TransportSessionType;
@protocol RequestStrategy;
@protocol UpdateEventProcessor;

@class ZMPersistentCookieStorage;
@class OperationStatus;
@class ZMSyncStrategy;

@interface ZMOperationLoop : NSObject <TearDownCapable>

@property (nonatomic, readonly) id<ZMApplication> application;
@property (nonatomic, readonly) id<TransportSessionType> transportSession;
@property (nonatomic) BOOL isDeveloperModeEnabled;
@property (nonatomic) BOOL isSyncV2Enabled;
// Only used for multibackend support.
@property (nonatomic, strong, nullable) NSNumber *apiVersion;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTransportSession:(id<TransportSessionType>)transportSession
                         requestStrategy:(id<RequestStrategy>)requestStrategy
                         operationStatus:(OperationStatus *)operationStatus
                                   uiMOC:(NSManagedObjectContext *)uiMOC
                                 syncMOC:(NSManagedObjectContext *)syncMOC
                  isDeveloperModeEnabled:(BOOL)isDeveloperModeEnabled
                         isSyncV2Enabled:(BOOL)isSyncV2Enabled
                              apiVersion:(nullable NSNumber *)apiVersion;

- (void)tearDown;
- (void)resumeEnqueuing;

@end


