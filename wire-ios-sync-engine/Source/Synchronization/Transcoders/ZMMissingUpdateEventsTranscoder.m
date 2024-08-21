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

@import WireUtilities;
@import WireTransport;
@import WireRequestStrategy;
@import WireDataModel;
#import "ZMMissingUpdateEventsTranscoder+Internal.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>
#import "WireSyncEngineLogs.h"


static NSString * const LastUpdateEventIDStoreKey = @"LastUpdateEventID";
static NSString * const NotificationsKey = @"notifications";
static NSString * const NotificationsPath = @"/notifications";
static NSString * const StartKey = @"since";

NSUInteger const ZMMissingUpdateEventsTranscoderListPageSize = 500;

@interface ZMMissingUpdateEventsTranscoder ()

@property (nonatomic, weak) id<UpdateEventProcessor> eventProcessor;
@property (nonatomic) PushNotificationStatus *pushNotificationStatus;
@property (nonatomic, weak) SyncStatus* syncStatus;
@property (nonatomic, weak) OperationStatus* operationStatus;
@property (nonatomic, weak) id<ClientRegistrationDelegate> clientRegistrationDelegate;
@property (nonatomic) NotificationsTracker *notificationsTracker;
@property (nonatomic) BOOL useLegacyPushNotifications;
@property (nonatomic) id<LastEventIDRepositoryInterface> lastEventIDRepository;
@property (nonatomic) BOOL isProcessingEvents;


- (void)appendPotentialGapSystemMessageIfNeededWithResponse:(ZMTransportResponse *)response;

@end


@interface ZMMissingUpdateEventsTranscoder (Pagination) <ZMSimpleListRequestPaginatorSync>
@end


@implementation ZMMissingUpdateEventsTranscoder

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                        notificationsTracker:(NotificationsTracker *)notificationsTracker
                              eventProcessor:(id<UpdateEventProcessor>)eventProcessor
                           applicationStatus:(id<ZMApplicationStatus>)applicationStatus
                      pushNotificationStatus:(PushNotificationStatus *)pushNotificationStatus
                                  syncStatus:(SyncStatus *)syncStatus
                             operationStatus:(OperationStatus *)operationStatus
                  useLegacyPushNotifications:(BOOL)useLegacyPushNotifications
                       lastEventIDRepository:(id<LastEventIDRepositoryInterface> _Nonnull)lastEventIDRepository

{
    self = [super initWithManagedObjectContext:managedObjectContext applicationStatus:applicationStatus];
    if(self) {
        self.eventProcessor = eventProcessor;
        self.notificationsTracker = notificationsTracker;
        self.pushNotificationStatus = pushNotificationStatus;
        self.syncStatus = syncStatus;
        self.operationStatus = operationStatus;
        self.useLegacyPushNotifications = useLegacyPushNotifications;
        self.lastEventIDRepository = lastEventIDRepository;

        self.listPaginator = [[ZMSimpleListRequestPaginator alloc] initWithBasePath:NotificationsPath
                                                                           startKey:StartKey
                                                                           pageSize:ZMMissingUpdateEventsTranscoderListPageSize
                                                               managedObjectContext:self.managedObjectContext
                                                                         transcoder:self];
    }
    return self;
}

- (ZMStrategyConfigurationOption)configuration
{
    return ZMStrategyConfigurationOptionAllowsRequestsDuringQuickSync
         | ZMStrategyConfigurationOptionAllowsRequestsWhileInBackground
         | ZMStrategyConfigurationOptionAllowsRequestsWhileOnline
         | ZMStrategyConfigurationOptionAllowsRequestsWhileWaitingForWebsocket;
}

- (BOOL)isDownloadingMissingNotifications
{
    return self.listPaginator.hasMoreToFetch;
}

- (BOOL)isFetchingStreamForAPNS
{
    return self.pushNotificationStatus.hasEventsToFetch;
}

- (BOOL)isFetchingStreamInBackground
{
    return self.operationStatus.operationState == SyncEngineOperationStateBackgroundFetch;
}

- (NSUUID *)lastUpdateEventID
{
    return [self.lastEventIDRepository fetchLastEventID];
}

- (void)appendPotentialGapSystemMessageIfNeededWithResponse:(ZMTransportResponse *)response
{
    // A 404 by the BE means we can't get all notifications as they are not stored anymore
    // and we want to issue a system message. We still might have a payload with notifications that are newer
    // than the commissioning time, the system message should be inserted between the old messages and the potentional
    // newly received ones in the payload.
    if (response.HTTPStatus == 404) {
        NSDate *timestamp = nil;
        const NSTimeInterval offset = 0.1f;
        
        NSArray *eventsDictionaries = [ZMMissingUpdateEventsTranscoder eventDictionariesFromPayload:response.payload];
        if (nil != eventsDictionaries && nil != eventsDictionaries.firstObject) {
            ZMUpdateEvent *event = [ZMUpdateEvent eventsArrayFromPushChannelData:eventsDictionaries.firstObject].firstObject;
            // In case we receive a payload together with the 404 we set the timestamp of the system message
            // to be 1/10th of a second older than the oldest received notification for it to appear above it.
            timestamp = [event.timestamp dateByAddingTimeInterval:-offset];
        }
        
        NSArray <ZMConversation *> *conversations = (NSArray <ZMConversation *> *) [self.managedObjectContext executeFetchRequestOrAssert:[ZMConversation sortedFetchRequest]];
        for (ZMConversation *conversation in conversations) {
            if (nil == timestamp) {
                // In case we did not receive a payload we will add 1/10th to the last modified date of
                // the conversation to make sure it appears below the last message
                timestamp = [conversation.lastModifiedDate dateByAddingTimeInterval:offset] ?: [NSDate date];
            }
            [conversation appendNewPotentialGapSystemMessageWithUsers:conversation.localParticipants
                                                            timestamp:timestamp];
        }
    }
}

- (void)updateServerTimeDeltaWithTimestamp:(NSString *)timestamp {
    NSDate *serverTime = [NSDate dateWithTransportString:timestamp];
    NSTimeInterval serverTimeDelta = [serverTime timeIntervalSinceNow];
    self.managedObjectContext.serverTimeDelta = serverTimeDelta;
}

+ (NSArray<NSDictionary *> *)eventDictionariesFromPayload:(id<ZMTransportData>)payload
{
    return [payload.asDictionary optionalArrayForKey:@"notifications"].asDictionaries;
}

- (NSUUID *)processUpdateEventsAndReturnLastNotificationIDFromResponse:(ZMTransportResponse *)response
{
    NSString *tpLabel = NSStringFromClass(self.class);
    ZMSTimePoint *tp = [[ZMSTimePoint alloc] initWithInterval:10 label:tpLabel];
    NSArray *eventsDictionaries = [self.class eventDictionariesFromPayload:response.payload];

    NSMutableArray<ZMUpdateEvent *> *parsedEvents = [NSMutableArray array];
    NSMutableArray<NSUUID *> *eventIds = [NSMutableArray array];
    NSUUID *latestEventId = nil;
    ZMUpdateEventSource source = self.isFetchingStreamForAPNS || self.isFetchingStreamInBackground ? ZMUpdateEventSourcePushNotification : ZMUpdateEventSourceDownload;
    for (NSDictionary *eventDictionary in eventsDictionaries) {
        NSArray *events = [ZMUpdateEvent eventsArrayFromTransportData:eventDictionary source:source];
        
        for (ZMUpdateEvent *event in events) {
            [event appendDebugInformation:@"From missing update events transcoder, processUpdateEventsAndReturnLastNotificationIDFromPayload"];
            [parsedEvents addObject:event];
            [eventIds addObject:event.uuid];
            
            if (!event.isTransient) {
                latestEventId = event.uuid;
            }
            [WireLoggerObjc logReceivedUpdateEventWithId:[event safeUUID]];
        }
    }
    
    ZMLogWithLevelAndTag(ZMLogLevelInfo, ZMTAG_EVENT_PROCESSING, @"Downloaded %lu event(s)", (unsigned long)parsedEvents.count);

    BOOL finished = !self.listPaginator.hasMoreToFetch;
    NSDate *fetchDate = self.listPaginator.lastResetFetchDate;
    NSArray<ZMSDispatchGroup *> *groups = [self.managedObjectContext enterAllGroupsExceptSecondary];
    self.isProcessingEvents = YES;
    SyncStatus *syncStatus = self.syncStatus;

    NSLog(@"ZMMissingUpdateEventsTranscoder process %lu events", (unsigned long)parsedEvents.count);
    [self.eventProcessor processEvents:parsedEvents completionHandler:^(NSError * _Nullable error) {
        [self.managedObjectContext performBlock:^{
            if (error != nil) {
                NSLog(@"ZMMissingUpdateEventsTranscoder error processing events: %@", error);
                [self.pushNotificationStatus didFailToFetchEventsWithRecoverable:NO];
                self.isProcessingEvents = NO;
                [self.listPaginator resetFetching];
                [self.managedObjectContext leaveAllGroups:groups];
                return;
            }

            [self.pushNotificationStatus didFetchEventIds:eventIds lastEventId:latestEventId finished:finished];

            if (finished) {
                [syncStatus completedFetchingNotificationStreamFetchBeganAt:fetchDate];

                if (self.operationStatus.operationState == SyncEngineOperationStateBackgroundFetch) {
                    [self updateBackgroundFetchResultWithResponse:response];
                }

                self.isProcessingEvents = NO;
            }

            [self.managedObjectContext leaveAllGroups:groups];
        }];
    }];

    [tp warnIfLongerThanInterval];
    return latestEventId;
}

- (void)updateBackgroundFetchResultWithResponse:(ZMTransportResponse *)response {
    UIBackgroundFetchResult result;
    if (response.result == ZMTransportResponseStatusSuccess) {
        if ([self.class eventDictionariesFromPayload:response.payload].count > 0) {
            result = UIBackgroundFetchResultNewData;
        } else {
            result = UIBackgroundFetchResultNoData;
        }
    } else {
        result = UIBackgroundFetchResultFailed;
    }
    
    [self.operationStatus finishBackgroundFetchWithFetchResult:result];
}

- (BOOL)hasLastUpdateEventID
{
    return self.lastUpdateEventID != nil;
}

- (void)startDownloadingMissingNotifications
{
    [self.listPaginator resetFetching];
}

- (NSArray *)contextChangeTrackers
{
    return @[];
}

- (NSArray *)requestGenerators;
{
    return @[self.listPaginator];
}

- (void)processEvents:(nonnull NSArray<ZMUpdateEvent *> *)events liveEvents:(BOOL)liveEvents prefetchResult:(ZMFetchRequestBatchResult * _Nullable)prefetchResult
{

}

- (ZMTransportRequest *)nextRequestIfAllowedForAPIVersion:(APIVersion)apiVersion
{
    /// There are multiple scenarios in which this class will create a new request:
    ///
    /// 1.) We received a push notification and want to fetch the notification stream (if we use the old implementation without the Notification service extension).
    /// 2.) The OS awoke the application to perform a background fetch (the operation state will indicate this).
    /// 3.) The application came to the foreground and is performing a quick-sync (c.f. `isSyncing`).

    // We want to create a new request if we are either currently fetching the paginated stream
    // or if we have a new notification ID that requires a pingback.
   
    if ((self.isFetchingStreamForAPNS && self.useLegacyPushNotifications) || self.isFetchingStreamInBackground || 
        self.isSyncing) {

        // We only reset the paginator if it is neither in progress nor has more pages to fetch.
        if (self.listPaginator.status != ZMSingleRequestInProgress &&
            !self.listPaginator.hasMoreToFetch &&
            !self.isProcessingEvents
        ) {
            [self.listPaginator resetFetching];
        }

        ZMTransportRequest *request = [self.listPaginator nextRequestForAPIVersion:apiVersion];

        if (self.isFetchingStreamForAPNS && nil != request) {
            [self.pushNotificationStatus didStartFetching];
            [self.notificationsTracker registerStartStreamFetching];
            [request addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:self.managedObjectContext block:^(__unused ZMTransportResponse * _Nonnull response) {
                [self.notificationsTracker registerFinishStreamFetching];
            }]];
        }

        return request;
    } else {
        return nil;
    }
}

- (SyncPhase)expectedSyncPhase
{
    return SyncPhaseFetchingMissedEvents;
}

- (BOOL)isSyncing
{
    return self.syncStatus.currentSyncPhase == self.expectedSyncPhase;
}

@end


@implementation ZMMissingUpdateEventsTranscoder (Pagination)

- (NSString *)selfClientID
{
    ZMUser* selfUser = [ZMUser selfUserInContext:super.managedObjectContext];
    return [[selfUser selfClient] remoteIdentifier];
}

- (NSUUID *)nextUUIDFromResponse:(ZMTransportResponse *)response forListPaginator:(ZMSimpleListRequestPaginator *)paginator
{

    NOT_USED(paginator);
    SyncStatus *syncStatus = self.syncStatus;
    
    NSString *timestamp = ((NSString *) response.payload.asDictionary[@"time"]);
    if (timestamp) {
        [self updateServerTimeDeltaWithTimestamp:timestamp];
    }

    NSUUID *latestEventId = [self processUpdateEventsAndReturnLastNotificationIDFromResponse:response];

    [self appendPotentialGapSystemMessageIfNeededWithResponse:response];

    if (response.result == ZMTransportResponseStatusPermanentError) {
        [syncStatus failedFetchingNotificationStream];
    }
    
    return latestEventId;
}

- (NSUUID *)startUUID
{
    return self.lastUpdateEventID;
}

- (BOOL)shouldParseErrorForResponse:(ZMTransportResponse *)response
{
    [self.pushNotificationStatus didFailToFetchEventsWithRecoverable:NO];

    if (response.apiVersion >= APIVersionV3) {
        return NO;
    }
    if (response.HTTPStatus == 404) {
        return YES;
    }
    
    return NO;
}

- (void)parseTemporaryErrorForResponse:(ZMTransportResponse *)response
{
    [self.pushNotificationStatus didFailToFetchEventsWithRecoverable:YES];
}

- (BOOL)shouldStartSlowSync:(ZMTransportResponse *)response
{
    return self.operationStatus.operationState == SyncEngineOperationStateForeground &&
            response.apiVersion >= APIVersionV3 &&
            (response.HTTPStatus == 404 || response.HTTPStatus == 400);
}

- (void)startSlowSync
{
    SyncStatus* status = self.syncStatus;
    [status removeLastUpdateEventID];
    [status forceSlowSync];
}
@end
