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


#import "SearchTokenStore.h"

@interface SearchTokenStore ()
@property (nonatomic) NSMutableDictionary *searchTokensStore;

@end

@implementation SearchTokenStore

- (void)searchStarted:(StartUISearchType)searchType withToken:(id<ZMSearchToken>)token
{
    // create the store if needed
    if (! self.searchTokensStore) {
        self.searchTokensStore = [NSMutableDictionary dictionary];
    }
    // create the type stores if needed
    
    if (! self.searchTokensStore[@(searchType)]) {
        self.searchTokensStore[@(searchType)] = [NSMutableOrderedSet orderedSet];
    }
    
    [self.searchTokensStore[@(searchType)] addObject:token];
}

- (void)searchEndedWithToken:(id <ZMSearchToken>)token
{
    StartUISearchType searchType = [self searchTypeForSeachToken:token];

    [self removeSearchToken:token forSearchType:searchType];
}

- (BOOL)isLatestSearchMatchingToken:(id<ZMSearchToken>)token
{
    StartUISearchType searchType = [self searchTypeForSeachToken:token];
    return [self isLatestSearchOfType:searchType matchingToken:token];
}

- (BOOL)isSearchRunning
{
    BOOL running = YES;
    for (NSInteger i = StartUISearchTypeMin; i <= StartUISearchTypeMax; i++) {
        running &= [self isSearchRunningForSearchType:i];
    }
    return running;
}

- (BOOL)isSearchRunningForSearchType:(StartUISearchType)searchType
{
    NSMutableOrderedSet *typeStore = self.searchTokensStore[@(searchType)];
    if (typeStore) {
        return typeStore.count > 0;
    } else {
        return NO;
    }
}

- (StartUISearchType)searchTypeForSeachToken:(id<ZMSearchToken>)searchToken
{
    NSArray *allKeys = [self.searchTokensStore allKeys];
    
    for (id key in allKeys) {
        NSOrderedSet *typeStore = self.searchTokensStore[key];
        
        if ([typeStore containsObject:searchToken]){
            return [key integerValue];
        }
    }
    
    return StartUISearchTypeUnknown;
}

- (void)removeSearchToken:(id<ZMSearchToken>)searchToken forSearchType:(StartUISearchType)searchType
{
    NSMutableOrderedSet *typeStore = self.searchTokensStore[@(searchType)];
    [typeStore removeObject:searchToken];
}

- (BOOL)isLatestSearchOfType:(StartUISearchType)searchType matchingToken:(id<ZMSearchToken>)searchToken
{
    if (!searchToken) { return NO; }
    return [[self.searchTokensStore[@(searchType)] lastObject] isEqual:searchToken];
}

@end
