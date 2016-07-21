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


@import ZMCSystem;
@import CoreGraphics;

#import "ZMManagedObject.h"

@class ZMEventID;

typedef void(^ObjectsEnumerationBlock)(ZMManagedObject *, BOOL *stop);
extern NSString * const ZMManagedObjectLocallyModifiedDataFieldsKey;



@interface ZMManagedObject (Internal)

+ (NSString *)entityName; ///< subclasses must implement this
+ (NSString *)sortKey; ///< subclasses must implement this or @c +defaultSortDescriptors
+ (NSString *)remoteIdentifierDataKey; ///< subclasses must implement this
+ (BOOL)hasLocallyModifiedDataFields;

+ (instancetype)insertNewObjectInManagedObjectContext:(NSManagedObjectContext *)moc;

/// Whether this object has all data from the backend
@property (nonatomic) BOOL needsToBeUpdatedFromBackend;

/// Handles conversion from and to ZMEventID and NSData in CoreData
- (ZMEventID *)transientEventIDForKey:(NSString *)key;
- (void)setTransientEventID:(ZMEventID *)newEventID forKey:(NSString *)key;

/// Handles conversion from and to NSUUID and NSData in CoreData
- (NSUUID *)transientUUIDForKey:(NSString *)key;
- (void)setTransientUUID:(NSUUID *)newUUID forKey:(NSString *)key;

/// Handles conversion from and to CGSize and NSData in CoreData
- (CGSize)transientCGSizeForKey:(NSString *)key;
- (void)setTransientCGSize:(CGSize)size forKey:(NSString *)key;

/// Defaults to a single sort descriptor based on @c sortKey
+ (NSArray *)defaultSortDescriptors;
/// The order in which objects are updated to / from the backend. ZMSyncOperationSet uses this.
+ (NSArray *)sortDescriptorsForUpdating;
+ (NSPredicate *)predicateForFilteringResults;
+ (NSFetchRequest *)sortedFetchRequest;
+ (NSFetchRequest *)sortedFetchRequestWithPredicate:(NSPredicate *)predicate;
+ (NSFetchRequest *)sortedFetchRequestWithPredicateFormat:(NSString *)format, ...;

+ (void)enumerateObjectsInContext:(NSManagedObjectContext *)moc withBlock:(ObjectsEnumerationBlock)block;

+ (instancetype)fetchObjectWithRemoteIdentifier:(NSUUID *)uuid inManagedObjectContext:(NSManagedObjectContext *)moc;
+ (NSOrderedSet *)fetchObjectsWithRemoteIdentifiers:(NSOrderedSet <NSUUID *> *)uuids inManagedObjectContext:(NSManagedObjectContext *)moc;

@end



/// This category is about persistent change tracking.
/// It tracks if changes to objects are made by the UI (and need to be pushed to the backend), or
/// are originating from the server, i.e. a given value is "up to date".
@interface ZMManagedObject (PersistentChangeTracking)

/// The keys that are not to be tracked. Subclasses can / should override this.
@property (nonatomic, readonly) NSSet *ignoredKeys;

/// Returns a predicate that will match objects which need additional data from the backend.
+ (NSPredicate *)predicateForNeedingToBeUpdatedFromBackend;

/// Returns a predicate that will match objects that have local modifications that need to be pushed to the backend
+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;

/// Returns a predicate that will match objects that we need to create on the backend
/// For most classes this will be "remoteIdentifier_data == nil"
+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream;

/// Returns the key (attributes) that have been locally modified (by the UI).
@property (nonatomic, readonly) NSSet *keysThatHaveLocalModifications;

/// Similar to keysThatHaveLocalModifications but allows passing in a snapshot as a dictionary.
/// Used for merging.
- (BOOL)hasLocalModificationsForKey:(NSString *)key withModifiedFlag:(NSNumber *)n;

/// Removes the given @c keys from the set of keys that have been modified by the UI
- (void)resetLocallyModifiedKeys:(NSSet *)keys;

/// Adds the given @c keys to the set of keys that have been modified by the UI
- (void)setLocallyModifiedKeys:(NSSet *)keys;

/// Returns @C YES if the receiver has local modifications for any of the given @c keys
- (BOOL)hasLocalModificationsForKeys:(NSSet *)keys;
- (BOOL)hasLocalModificationsForKey:(NSString *)key;


- (NSArray *)keysTrackedForLocalModifications ZM_REQUIRES_SUPER;
- (void)updateKeysThatHaveLocalModifications ZM_REQUIRES_SUPER;

@end

