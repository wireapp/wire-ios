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


#import "ZMDownstreamObjectSyncWithWhitelist.h"

@interface ZMDownstreamObjectSyncWithWhitelist ()

@property (nonatomic) NSPredicate *predicateForObjectsRequiringWhitelisting;
@property (nonatomic) NSMutableSet *whitelist;
@property (nonatomic, readonly) NSPredicate *predicateForObjectsRequiringWhitelistingAndMatchingEntityType;
@property (nonatomic, readonly) NSPredicate *predicateForObjectsWithObservedEntityType;
@property (nonatomic, readonly) NSPredicate *predicateForObjectsNotCurrentlyInWhitelist;

@end

@implementation ZMDownstreamObjectSyncWithWhitelist

- (instancetype)initWithTranscoder:(id<ZMDownstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
     predicateForObjectsToDownload:(NSPredicate *)predicateForObjectsToDownload
predicateForObjectsRequiringWhitelisting:(NSPredicate *)predicateForObjectsRequiringWhitelisting
              managedObjectContext:(NSManagedObjectContext *)moc
{
    return [self initWithTranscoder:transcoder entityName:entityName predicateForObjectsToDownload:predicateForObjectsToDownload predicateForObjectsRequiringWhitelisting:predicateForObjectsRequiringWhitelisting filter:nil managedObjectContext:moc];
}

- (instancetype)initWithTranscoder:(id<ZMDownstreamTranscoder>)transcoder
                        entityName:(NSString *)entityName
     predicateForObjectsToDownload:(NSPredicate *)predicateForObjectsToDownload
predicateForObjectsRequiringWhitelisting:(NSPredicate *)predicateForObjectsRequiringWhitelisting
                            filter:(NSPredicate *)filter
              managedObjectContext:(NSManagedObjectContext *)moc
{
    self = [self initWithTranscoder:transcoder entityName:entityName predicateForObjectsToDownload:predicateForObjectsToDownload filter:filter managedObjectContext:moc];
    if(self) {
        self.predicateForObjectsRequiringWhitelisting = predicateForObjectsRequiringWhitelisting;
        self.whitelist = [NSMutableSet set];
    }
    return self;
}

- (void)whiteListObject:(ZMManagedObject *)object;
{
    if([self.predicateForObjectsRequiringWhitelisting evaluateWithObject:object]) {
        [self.whitelist addObject:object];
        [self addTrackedObjects:[NSSet setWithObject:object]];
    }
}

- (NSPredicate *)predicateForObjectsNotCurrentlyInWhitelist
{
    return [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings __unused) {
        return ![self.whitelist containsObject:evaluatedObject];
    }];
}

- (NSPredicate *)predicateForObjectsWithObservedEntityType
{
    return [NSPredicate predicateWithFormat:@"entity == %@", self.entity];
}

- (NSPredicate *)predicateForObjectsRequiringWhitelistingAndMatchingEntityType
{
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[self.predicateForObjectsWithObservedEntityType,
                                                                self.predicateForObjectsRequiringWhitelisting]];
}

- (NSSet *)setWithoutObjectsThatNeedToBeWhitelisted:(NSSet *)objects
{
    NSPredicate *compoundPredicate = [NSCompoundPredicate notPredicateWithSubpredicate:
                                      [NSCompoundPredicate andPredicateWithSubpredicates:@[self.predicateForObjectsRequiringWhitelistingAndMatchingEntityType,
                                                                                           self.predicateForObjectsNotCurrentlyInWhitelist]]];
    return [objects filteredSetUsingPredicate:compoundPredicate];
}

- (void)objectsDidChange:(NSSet *)objects;
{
    [super objectsDidChange:[self setWithoutObjectsThatNeedToBeWhitelisted:objects]];
    [self.whitelist minusSet:[objects filteredSetUsingPredicate:[NSCompoundPredicate notPredicateWithSubpredicate:
                                                                 self.predicateForObjectsRequiringWhitelistingAndMatchingEntityType]]];
}

/// Adds tracked objects -- which have been retrieved by using the fetch request returned by -fetchRequestForTrackedObjects
- (void)addTrackedObjects:(NSSet *)objects;
{
    [super addTrackedObjects:[self setWithoutObjectsThatNeedToBeWhitelisted:objects]];
}

@end
