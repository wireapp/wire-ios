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


#import "ZMDownstreamObjectSync.h"

/// ZMDownstreamObjectSync with support for whitelisting. Only whitelisted objects matching the predicate will be downloaded

@interface ZMDownstreamObjectSyncWithWhitelist : ZMDownstreamObjectSync

/// @param predicateForObjectsToDownload the predicate that will be used to select which object to download
/// @param predicateForObjectsRequiringWhitelisting if an object matches this predicate and the @c predicateForObjectsToDownload, it will be donwloaded only if whitelisted,
///    if it doesn't match this predicate it will be downloaded even if not whitelisted
- (instancetype)initWithTranscoder:(id<ZMDownstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
     predicateForObjectsToDownload:(NSPredicate *)predicateForObjectsToDownload
predicateForObjectsRequiringWhitelisting:(NSPredicate *)predicateForObjectsRequiringWhitelisting
              managedObjectContext:(NSManagedObjectContext *)moc;

/// @param predicateForObjectsToDownload the predicate that will be used to select which object to download
/// @param predicateForObjectsRequiringWhitelisting if an object matches this predicate and the @c predicateForObjectsToDownload, it will be donwloaded only if whitelisted,
///    if it doesn't match this predicate it will be downloaded even if not whitelisted
- (instancetype)initWithTranscoder:(id<ZMDownstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
     predicateForObjectsToDownload:(NSPredicate *)predicateForObjectsToDownload
predicateForObjectsRequiringWhitelisting:(NSPredicate *)predicateForObjectsRequiringWhitelisting
                            filter:(NSPredicate *)filter
              managedObjectContext:(NSManagedObjectContext *)moc;

/// Adds an object to the whitelist. It will later be removed once downloaded and not matching the whitelist predicate
- (void)whiteListObject:(ZMManagedObject *)object;

/// See the @c init description
@property (nonatomic, readonly) NSPredicate *predicateForObjectsRequiringWhitelisting;

@end
