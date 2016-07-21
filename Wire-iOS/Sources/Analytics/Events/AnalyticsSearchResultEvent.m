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


#import "AnalyticsSearchResultEvent.h"



@implementation AnalyticsSearchResultEvent

+ (instancetype)eventForSearchResultUsed:(BOOL)created participantCount:(NSUInteger)participantCount
{
    return [[AnalyticsSearchResultEvent alloc] initForSearchResultUsed:created participantCount:participantCount];
}

- (NSString *)eventTag
{
    return @"searchResultsUsed";
}

- (instancetype)initForSearchResultUsed:(BOOL)created participantCount:(NSUInteger)participantCount
{
    self = [super init];
    if (self) {
        self.groupConversationCreated = created;
        self.numberOfContactsAdded = participantCount;
    }
    return self;
}

- (NSDictionary *)attributesDump
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:6];
    [self dumpIntegerClusterizedValueForKey:NSStringFromSelector(@selector(numberOfContactsAdded)) toDictionary:result];
    
    [result setObject:@(self.groupConversationCreated) forKey:NSStringFromSelector(@selector(groupConversationCreated))];
    
    return result;
}

@end
