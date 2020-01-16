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


@import CoreData;

extern NSString * _Nonnull const ZMDataPropertySuffix;

@protocol ZMManagedObjectContextProvider;

@interface ZMManagedObject : NSManagedObject

@property (nonatomic, readonly) BOOL isZombieObject;

+ (nullable NSManagedObjectID *)objectIDForURIRepresentation:(nullable NSURL *)url inUserSession:(nullable id<ZMManagedObjectContextProvider>)userSession;
+ (nullable instancetype)existingObjectWithID:(nullable NSManagedObjectID *)identifier inUserSession:(nullable id<ZMManagedObjectContextProvider>)userSession;
+ (nullable instancetype)existingObjectWithObjectIdentifier:(nullable NSString *)identifier inManagedObjectContext:(nullable NSManagedObjectContext *)context;

- (nullable NSString *)objectIDURLString;

@end

@interface ZMManagedObject (NonpersistedObjectIdentifer)

@property (nonatomic, readonly, nonnull) NSString *nonpersistedObjectIdentifer;

+ (nullable instancetype)existingObjectWithNonpersistedObjectIdentifer:(nullable NSString *)identifier inUserSession:(nonnull id<ZMManagedObjectContextProvider>)userSession;

@end
