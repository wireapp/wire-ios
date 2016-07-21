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


#import "AnalyticsSessionSummaryEvent.h"
#import "DefaultIntegerClusterizer.h"
#import "TimeIntervalClusterizer.h"



@implementation AnalyticsSessionSummaryEvent

- (NSString *)eventTag
{
    return @"session";
}

- (NSNumber *)customerValueIncrease
{
    return @(10.0f);
}

- (NSDictionary *)attributesDump
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:10];

    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(connectRequestsSent)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(connectRequestsAccepted)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(voiceCallsInitiated)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(incomingCallsAccepted)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(incomingCallsMuted)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(usersAddedToConversations)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(youtubeLinksSent)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(soundcloudLinksSent)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(pingsSent)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(imagesSent)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(imageContentsClicks)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(soundcloudContentClicks)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(youtubeContentClicks)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(unknownInlineContentClicks)) toDictionary:result];
    
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(conversationRenames)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(openedSearchAfterABIgnore)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(openedSearchAfterABUpload)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(openedSearchBeforeABDecision)) toDictionary:result];

    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(totalArchivedConversations)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(totalGroupConversations)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(totalSilencedConversations)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(totalContacts)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(totalIncomingConnectionRequests)) toDictionary:result];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(totalOutgoingConnectionRequests)) toDictionary:result];
    
    [result setObject:@(self.isFirstSession) forKey:NSStringFromSelector(@selector(isFirstSession))];
    [result setObject:@(self.searchedForPeople) forKey:NSStringFromSelector(@selector(searchedForPeople))];

    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(sessionDuration)) toDictionary:result forClusterizer:[TimeIntervalClusterizer defaultClusterizer]];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(textMessagesSent)) toDictionary:result forClusterizer:[DefaultIntegerClusterizer messageClusterizer]];

    return result;
}

@end
