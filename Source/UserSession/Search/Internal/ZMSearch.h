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


@import CoreData;
@import Foundation;
#import "ZMSearchDirectory.h"
#import "ZMSearchState.h"



typedef void(^ZMSearchResultHandler)(ZMSearchResult *result);

@protocol ZMSearch <NSObject>

@property (nonatomic, readonly) ZMSearchToken token;
- (void)tearDown;

@end



@interface ZMSearch : NSObject <ZMSearch>

@property (nonatomic, readonly) ZMSearchRequest *request;

@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic) NSTimeInterval updateDelay;

@property (nonatomic, copy) ZMSearchResultHandler resultHandler;


- (instancetype)initWithRequest:(ZMSearchRequest *)request
                        context:(NSManagedObjectContext *)context
                    userSession:(ZMUserSession *)userSession
                    resultCache:(NSCache *)resultCache;

- (void)start;

+ (ZMSearchToken)tokenForRequest:(ZMSearchRequest *)request;

@end
