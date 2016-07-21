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


#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, StartUISearchType){
    StartUISearchTypeUnknown = -1,
    StartUISearchTypeContactsAndConverastions = 0,
    StartUISearchTypeContacts,
    StartUISearchTypeDirectory,
    
    StartUISearchTypeMin = StartUISearchTypeUnknown,
    StartUISearchTypeMax = StartUISearchTypeDirectory,
};

@protocol ZMSearchToken;

@interface SearchTokenStore : NSObject
- (void)searchStarted:(StartUISearchType)searchType withToken:(id <ZMSearchToken>)token;
- (void)searchEndedWithToken:(id <ZMSearchToken>)token;
- (BOOL)isLatestSearchMatchingToken:(id <ZMSearchToken>)token;
- (StartUISearchType)searchTypeForSeachToken:(id<ZMSearchToken>)searchToken;
- (BOOL)isSearchRunning;
- (BOOL)isSearchRunningForSearchType:(StartUISearchType)searchType;
- (BOOL)isLatestSearchOfType:(StartUISearchType)searchType matchingToken:(id<ZMSearchToken>)searchToken;
@end
