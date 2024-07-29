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

#import <Foundation/Foundation.h>
#import <WireTransport/WireTransport.h>
#import <WireRequestStrategy/ZMSingleRequestSync.h>
#import <WireRequestStrategy/ZMRequestGenerator.h>

@protocol ZMSimpleListRequestPaginatorSync;


@interface ZMSimpleListRequestPaginator : NSObject <ZMRequestGenerator>

/// YES if more requests should be made before to fetch the full list
@property (nonatomic, readonly) BOOL hasMoreToFetch;

/// Status of the underlying singleRequestTranscoder
@property (nonatomic, readonly) ZMSingleRequestProgress status;

/// Date of last call to `resetFetching`
@property (nonatomic, readonly, nullable) NSDate *lastResetFetchDate;


- (nonnull instancetype)initWithBasePath:(nonnull NSString *)basePath
                                startKey:(nonnull NSString *)startKey
                                pageSize:(NSUInteger)pageSize
                    managedObjectContext:(nonnull NSManagedObjectContext *)moc
                              transcoder:(nullable id<ZMSimpleListRequestPaginatorSync>)transcoder;

- (nullable ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion;

/// this will cause the fetch to restart at the nextPaginatedRequest
- (void)resetFetching;

@end



@protocol ZMSimpleListRequestPaginatorSync <NSObject>

- (nullable NSString *)selfClientID;

/// returns the next UUID to be used as the starting point for the next request
- (nullable NSUUID *)nextUUIDFromResponse:(nonnull ZMTransportResponse *)response forListPaginator:(nonnull ZMSimpleListRequestPaginator *)paginator;


/// Returns an NSUUID to start with after calling resetFetching
@optional
- (nullable NSUUID *)startUUID;

/// Returns YES, if the error response for a specific statusCode should be parsed (e.g. if the payload contains content that needs to be processed)
@optional
- (BOOL)shouldParseErrorForResponse:(nonnull ZMTransportResponse*)response;

@optional
- (void)parseTemporaryErrorForResponse:(nonnull ZMTransportResponse*)response;

@optional
- (void)startSlowSync;

@optional
- (BOOL)shouldStartSlowSync:(nonnull ZMTransportResponse *)response;

@end

