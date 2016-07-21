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
#import "ziphy+iOS.h"

@class ZiphyClient;



@interface GiphySearchResultsController : NSObject

@property (nonatomic, strong, readonly) ZiphyClient *ziphyClient;
@property (nonatomic, copy, readonly) NSString *searchTerm;

@property (nonatomic, readonly) ZiphyImageType imageType;
@property (nonatomic, readonly) NSInteger pageSize;
@property (nonatomic, readonly) NSInteger maxImageSize;
@property (nonatomic, readonly) NSInteger totalPagesFetched;
@property (nonatomic, readonly) NSInteger numberOfResultsLastFetch;
@property (nonatomic, readonly) NSArray *searchResults;

@property (nonatomic, readonly) BOOL isFetchingNewPage;
@property (nonatomic, readonly) NSError *fetchPageError;

- (instancetype)initWithSearchTerm:(NSString *)searchTerm
                         imageType:(ZiphyImageType)imageType
                          pageSize:(NSInteger)pageSize
                      maxImageSize:(NSInteger)imageSize;
- (void)fetchNewPage:(void (^)(BOOL success, NSError *error))onCompletion;

- (void)fetchImageForSearchResult:(Ziph *)ziph
                           ofType:(ZiphyImageType)imageType
                       completion:(void (^)(BOOL success,
                                            ZiphyImageRep *ziphyImageRep,
                                            Ziph *ziph,
                                            NSData *imageData,
                                            NSError *error))completion;

@end
