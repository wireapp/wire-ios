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

@import  CoreData;

#import <WireRequestStrategy/ZMObjectSync.h>

@protocol ZMDownstreamTranscoder;
@class ZMManagedObject;

/// ZMDownstreamObjectSync with support for whitelisting. Only whitelisted objects matching the predicate will be downloaded

@interface ZMDownstreamObjectSyncWithWhitelist : NSObject <ZMObjectSync>

/// @param predicateForObjectsToDownload the predicate that will be used to select which object to download
- (instancetype _Nonnull )initWithTranscoder:(id<ZMDownstreamTranscoder>_Nonnull)transcoder
                        entityName:(NSString *_Nonnull)entityName
     predicateForObjectsToDownload:(NSPredicate *_Nonnull)predicateForObjectsToDownload
              managedObjectContext:(NSManagedObjectContext *_Nonnull)moc;

/// Adds an object to the whitelist. It will later be removed once downloaded and not matching the whitelist predicate
- (void)whiteListObject:(ZMManagedObject *_Nullable)object;

/// Returns a request to download the next object
- (void)nextRequestForAPIVersion:(APIVersion)apiVersion completion:(void (^ _Nonnull)(ZMTransportRequest * _Nullable))completionBlock;

@end
