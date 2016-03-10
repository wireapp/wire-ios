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


@import ZMTransport;

#import "ZMKnockTranscoder.h"
#import "ZMMessage+Internal.h"
#import "ZMConversation+Internal.h"


@interface ZMKnockTranscoder ()

@end


@implementation ZMKnockTranscoder


- (NSArray *)contextChangeTrackers
{
    return @[];
}

- (void)setNeedsSlowSync {
    
}

- (BOOL)isSlowSyncDone {
    return YES;
}

- (NSArray *)requestGenerators;
{
    return @[];
}

- (void)processEvents:(NSArray<ZMUpdateEvent *> *)events
           liveEvents:(__unused BOOL)liveEvents
       prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult;
{
    NSArray *knockEvents = [events filterWithBlock:^BOOL(ZMUpdateEvent *event) {
        return event.type == ZMUpdateEventConversationKnock;
    }];
    
    NSMutableSet *conversationsToSort = [NSMutableSet set];
    
    for(ZMUpdateEvent *event in knockEvents) {
        ZMMessage *message = [ZMKnockMessage createOrUpdateMessageFromUpdateEvent:event
                                                           inManagedObjectContext:self.managedObjectContext
                                                                   prefetchResult:prefetchResult
                            ];
        
        if(message != nil) {
            [conversationsToSort addObject:message.conversation];
        }
    }
    
    for(ZMConversation *conversation in conversationsToSort) {
        [conversation sortMessages];
    }
}

- (NSSet<NSUUID *> *)messageNoncesToPrefetchToProcessEvents:(NSArray<ZMUpdateEvent *> *)events
{
    return [events mapWithBlock:^NSUUID *(ZMUpdateEvent *event) {
        switch (event.type) {
            case ZMUpdateEventConversationKnock:
                return event.messageNonce;
                
            default:
                return nil;
        }
    }].set;
}

@end

