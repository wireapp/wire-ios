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


#import "AnalyticsEvent.h"



@interface AnalyticsSessionSummaryEvent : AnalyticsEvent

// MARK: - defaultClusterizer
@property (assign, nonatomic) NSUInteger connectRequestsSent;
@property (assign, nonatomic) NSUInteger connectRequestsAccepted;
@property (assign, nonatomic) NSUInteger voiceCallsInitiated;
@property (assign, nonatomic) NSUInteger videoCallsInitiated;
@property (assign, nonatomic) NSUInteger incomingCallsAccepted;
@property (assign, nonatomic) NSUInteger incomingCallsMuted;
@property (assign, nonatomic) NSUInteger usersAddedToConversations;
@property (assign, nonatomic) NSUInteger youtubeLinksSent;
@property (assign, nonatomic) NSUInteger soundcloudLinksSent;
@property (assign, nonatomic) NSUInteger pingsSent;
@property (assign, nonatomic) NSUInteger imagesSent;
@property (assign, nonatomic) NSUInteger imageContentsClicks;

@property (assign, nonatomic) NSUInteger soundcloudContentClicks;
@property (assign, nonatomic) NSUInteger youtubeContentClicks;
@property (assign, nonatomic) NSUInteger unknownInlineContentClicks;

@property (assign, nonatomic) NSUInteger conversationRenames;

@property (assign, nonatomic) NSUInteger openedSearchAfterABUpload;
@property (assign, nonatomic) NSUInteger openedSearchAfterABIgnore;
@property (assign, nonatomic) NSUInteger openedSearchBeforeABDecision;

@property (assign, nonatomic) NSUInteger totalContacts;
@property (assign, nonatomic) NSUInteger totalGroupConversations;
@property (assign, nonatomic) NSUInteger totalArchivedConversations;
@property (assign, nonatomic) NSUInteger totalSilencedConversations;
@property (assign, nonatomic) NSUInteger totalIncomingConnectionRequests;
@property (assign, nonatomic) NSUInteger totalOutgoingConnectionRequests;

@property (assign, nonatomic) BOOL isFirstSession;
@property (assign, nonatomic) BOOL searchedForPeople;

// MARK: - timeintervalClusterizer
@property (assign, nonatomic) NSTimeInterval sessionDuration;

// MARK: - messageClusterizer
@property (assign, nonatomic) NSUInteger textMessagesSent;

@end
