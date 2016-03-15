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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


@import ZMCSystem;
@import ZMTransport;

#import "ZMConversationEventsTranscoder+Internal.h"
#import "ZMIncompleteConversationsCache.h"
#import "ZMConversation+Internal.h"
#import "ZMSyncStrategy.h"
#import "ZMUpdateEvent.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>
#import "ZMUser+Internal.h"

static NSTimeInterval const ZMLowPriorityEventsDownloadCooldown = 15; // secs
const NSUInteger ZMMaximumMessagesPageSize = 50;


@interface ZMConversationEventsTranscoder ()

@property (nonatomic) IncompleteConversationsDownstreamSync *conversationDownstreamSync;
@property (nonatomic) ZMIncompleteConversationsCache *conversationsCache;
@property (nonatomic, weak) ZMSyncStrategy *syncStrategy;

@end

@implementation ZMConversationEventsTranscoder


- (instancetype)initWithSyncStrategy:(ZMSyncStrategy *)syncStrategy historySynchronizationStatus:(id<HistorySynchronizationStatus>)historySynchronizationStatus;
{
    Require(syncStrategy != nil);
    ZMIncompleteConversationsCache *conversationsCache = [[ZMIncompleteConversationsCache alloc] initWithContext:syncStrategy.syncMOC];
    
    return [self initWithConversationsCache:conversationsCache
               historySynchronizationStatus:historySynchronizationStatus
                               syncStrategy:syncStrategy];
}

- (instancetype)initWithConversationsCache:(ZMIncompleteConversationsCache *)conversationsCache
              historySynchronizationStatus:(id<HistorySynchronizationStatus>)historySynchronizationStatus
                              syncStrategy:(ZMSyncStrategy *)syncStrategy;
{
    RequireString(syncStrategy != nil, "ZMSyncStrategy is <nil>.");
    self = [super initWithManagedObjectContext:syncStrategy.syncMOC];
    if (self) {
        RequireString(self.managedObjectContext != nil, "managed object context is <nil>.");
        self.syncStrategy = syncStrategy;
        
        IncompleteConversationsDownstreamSync *conversationDownstreamSync =
        [[IncompleteConversationsDownstreamSync alloc] initWithRequestEncoder:self
                                                               responseParser:self
                                                           conversationsCache:conversationsCache
                                                 historySynchronizationStatus:historySynchronizationStatus
                                          lowPriorityRequestsCooldownInterval:ZMLowPriorityEventsDownloadCooldown
                                                         managedObjectContext:syncStrategy.syncMOC];
        
        self.conversationDownstreamSync = conversationDownstreamSync;
        self.conversationsCache = conversationsCache;
    }
    return self;
}

- (void)tearDown;
{
    [super tearDown];
    [self.conversationsCache tearDown];
}

- (BOOL)isSlowSyncDone
{
    return YES;
}

- (void)setNeedsSlowSync
{
    // nop
}

- (void)downloadTopIncompleteConversations
{
    [self.conversationsCache whitelistTopConversationsIfIncomplete];
}

- (NSArray *)contextChangeTrackers
{
    return @[self.conversationsCache];
}

- (NSArray *)requestGenerators;
{
    return @[self.conversationDownstreamSync];
}

- (void)processEvents:(NSArray<ZMUpdateEvent *> *)events
           liveEvents:(BOOL __unused)liveEvents
       prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult;
{
    for(ZMUpdateEvent *event in events) {
        [self processSingleEventToFillGaps:event conversationsByRemoteIdentifier:prefetchResult.conversationsByRemoteIdentifier];
    }
}

/// returns YES if the event was parsed properly and contributed to fit a gap in a conversation
- (BOOL)processSingleEventToFillGaps:(ZMUpdateEvent *)event
     conversationsByRemoteIdentifier:(NSDictionary <NSUUID *, ZMConversation *>*)conversationsByRemoteIdentifier
{
    /// I need this to decide if an event payload was useful at all. If it was useless (no events parsed or
    /// used to fill gaps), I will end up requesting the same events again, and again. If no event is parsed,
    /// we just assume the gap is filled so that we stop requesting. This should happen only in case of protocol
    /// error.
    NSUUID *conversationID = event.conversationUUID;
    BOOL const isSelf = [conversationID isSelfConversationRemoteIdentifierInContext:self.managedObjectContext];
    if (isSelf) {
        return NO;
    }
    ZMEventID *convEventID = event.eventID;
    if(conversationID) {
        ZMConversation *conversation = conversationsByRemoteIdentifier[conversationID];
        if(conversation != nil && ![conversation.downloadedMessageIDs containsEvent:convEventID]) {
            [conversation addEventToDownloadedEvents:convEventID timeStamp:event.timeStamp];
            return YES;
        }
    }
    return NO;
}

/// returns YES if the event was parsed properly and contributed to fit a gap in a conversation
- (BOOL)processSingleEventToFillGaps:(ZMEventID *)eventID timeStamp:(NSDate *)timeStamp conversation:(ZMConversation *)conversation
{
    if(![conversation.downloadedMessageIDs containsEvent:eventID]) {
        [conversation addEventToDownloadedEvents:eventID timeStamp:timeStamp];
        return YES;
    }
    return NO;
    
}


@end



@implementation ZMConversationEventsTranscoder (ConversationEventsRequestEncoder)


- (ZMTransportRequest *)requestForFetchingRange:(ZMEventIDRange *)gap conversation:(ZMConversation *)conversation
{
    ZMEventID *lowerBound = gap.oldestMessage;
    ZMEventID *upperBound = gap.newestMessage;
    
    
    if ((upperBound.major - lowerBound.major) > ZMMaximumMessagesPageSize) {
        lowerBound = [ZMEventID eventIDWithMajor:upperBound.major - ZMMaximumMessagesPageSize minor:0];
    }

    NSURLComponents *urlComponent = [[NSURLComponents alloc] init];
    urlComponent.path = [NSString pathWithComponents:@[@"/", @"conversations", conversation.remoteIdentifier.transportString, @"events"]];
    
    NSArray *parameters = @[[NSString stringWithFormat:@"size=%lu", (unsigned long)ZMMaximumMessagesPageSize],
                            [NSString stringWithFormat:@"start=%@", lowerBound.transportString],
                            [NSString stringWithFormat:@"end=%@", upperBound.transportString]];
    urlComponent.query = [parameters componentsJoinedByString:@"&"];

    ZMTransportRequest *request = [ZMTransportRequest requestGetFromPath:urlComponent.string];
    return request;
}

@end

@implementation ZMConversationEventsTranscoder (DownloadedConversationEventsParser)

- (void)updateRange:(ZMEventIDRange *)gap conversation:(ZMConversation *)conversation response:(ZMTransportResponse *)response
{
    if(response.result == ZMTransportResponseStatusSuccess) {
        [self processEventData:response.payload forGap:gap conversation:conversation];
    }
    else if(response.result == ZMTransportResponseStatusPermanentError) {
        // Fill gap anyway, so that we don't download it again
        [conversation addEventRangeToDownloadedEvents:gap];
    }
}

- (void)processEventData:(id<ZMTransportData>)eventsData forGap:(ZMEventIDRange *)gap conversation:(ZMConversation *)conversation
{
    
    NSArray *eventsPayload = [[eventsData asDictionary] arrayForKey:@"events"];
    
    BOOL didUseAtLeastOneEventToFilGap = NO;
    
    if (eventsPayload != nil) {
        // Calling syncStrategy processEventData will instantly come back to this class to process these events.
        // But we also want to parse them now to check if they are contributing to fill any gap - if they are not,
        // there is an API/protocol error and we recover by just assuming the gap is filled.
        // Note that I can't just not implement the processEventData because I still need it for events coming through the push channel
        
        NSMutableArray *createdEvents = [NSMutableArray array];
        for(id<ZMTransportData> subData in eventsPayload) {
            ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:subData uuid:nil];
            ZMEventID *eventID;
            NSDate *timeStamp;
            if (event == nil) {
                // We might receive old events that we don't process anymore, e.g. hot knocks
                // we should still set the lastReadTimeStamp when processing those since they might be the lastRead event
                eventID = [[subData asDictionary] optionalEventForKey:@"id"];
                timeStamp = [[subData asDictionary] dateForKey:@"time"];
                if (eventID == nil) {
                    continue;
                }
            } else {
                eventID = event.eventID;
                timeStamp = event.timeStamp;
            }
            didUseAtLeastOneEventToFilGap |= [self processSingleEventToFillGaps:eventID timeStamp:timeStamp conversation:conversation];
            if (event != nil) {
                [createdEvents addObject:event];
            }
        }
        [self.syncStrategy processDownloadedEvents:createdEvents];
    }
    
    if(!didUseAtLeastOneEventToFilGap) {
        // protocol error, just fill that gap
        ZMLogError(@"Protocol error in conversation events?");
        [conversation addEventRangeToDownloadedEvents:gap];
    }
}

@end




