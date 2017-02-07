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


@import ZMUtilities;
@import ZMCSystem;

#import "ZMUserDisplayNameGenerator.h"
#import "ZMDisplayNameGenerator+Internal.h"
#import "ZMUser+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"

@interface ZMUserDisplayNameGenerator ()
{
    dispatch_once_t _didGetUsers;
}

@property (nonatomic, copy) NSSet *allUsers;
@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

@end



@implementation ZMUserDisplayNameGenerator

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init;
{
    Require(NO);
    return nil;
}

- (instancetype)initWithIDToFullNameMap:(NSDictionary * __unused)map;
{
    Require(NO);
    return nil;
}
#pragma clang diagnostic pop



- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc;
{
    self = [super init];
    
    if (self) {
        self.managedObjectContext = moc;
    }
    return self;
}

- (instancetype)updatedWithUsers:(NSSet *)users managedObjectIDsForChangedUsers:(NSSet *__autoreleasing *)updated
{
    if (self.allUsers == nil) {
        return self;
    }
    Require(users != nil);
    ZMUserDisplayNameGenerator *generator = [[ZMUserDisplayNameGenerator alloc] initWithManagedObjectContext:self.managedObjectContext];
    NSDictionary *map = [self createIdToFullNameMapForUsers:users];
    generator = [self createCopyForGenerator:generator withMap:map updatedKeys:updated];
    // Keep a strong reference to all users:
    generator.allUsers = users;
    return generator;
}

- (NSSet *)fetchAllUsersInContext:(NSManagedObjectContext *)moc
{
    NSFetchRequest *fetchRequest = [ZMUser sortedFetchRequest];
//    fetchRequest.includesPendingChanges = NO;
    NSArray *allUsers = [moc executeFetchRequestOrAssert:fetchRequest];
    return [NSSet setWithArray:allUsers];
}

- (NSDictionary *)createIdToFullNameMapForUsers:(NSSet *)users
{
    NSMutableDictionary *idToFullNameMap = [NSMutableDictionary dictionary];
    for (ZMUser *user in users) {
        Require(user.objectID != nil);
        idToFullNameMap[user.objectID] = user.name ?: @"";
    }
    return idToFullNameMap;
}

- (NSString *)displayNameForUser:(ZMUser *)user;
{
    [self fetchAllUsers];
    return [self displayNameForKey:user.objectID];
}

- (NSString *)initialsForUser:(ZMUser *)user;
{
    [self fetchAllUsers];
    return [self initialsForKey:user.objectID];
}

- (void)fetchAllUsers;
{
    dispatch_once(&_didGetUsers, ^{
        if (self.allUsers == nil || self.idToFullNameMap == nil) {
            self.allUsers = [self fetchAllUsersInContext:self.managedObjectContext];
            self.idToFullNameMap = [self createIdToFullNameMapForUsers:self.allUsers];
        }
    });
}

@end

@implementation NSManagedObjectContext (ZMDisplayNameGenerator)

static NSString * const DisplayNameGeneratorKey = @"ZMUserDisplayNameGenerator";

- (ZMUserDisplayNameGenerator *)displayNameGenerator;
{
    ZMUserDisplayNameGenerator *generator = self.userInfo[DisplayNameGeneratorKey];
    return generator;
}

- (void)setDisplayNameGenerator:(ZMUserDisplayNameGenerator *)displayNameGenerator;
{
    if (displayNameGenerator == nil) {
        [self.userInfo removeObjectForKey:DisplayNameGeneratorKey];
    } else {
        self.userInfo[DisplayNameGeneratorKey] = displayNameGenerator;
    }
}

- (NSSet *)updateDisplayNameGeneratorWithUpdatedUsers:(NSSet<ZMUser *>*)updatedUsers
                                        insertedUsers:(NSSet<ZMUser *>*)insertedUsers
                                        deletedUsers:(NSSet<ZMUser *>*)deletedUsers;
{
    if (insertedUsers.count == 0 && deletedUsers.count == 0 && updatedUsers.count == 0) {
        return [NSSet set];
    }
    if (self.displayNameGenerator == nil) return [NSSet set];
    [self.displayNameGenerator fetchAllUsers];
    
    // loop through updated. If the user name changed then replace those users in the updatedSet
    NSMutableSet *updatedSet = [self.displayNameGenerator.allUsers mutableCopy];
    for (ZMUser *user in updatedSet) {
        ZMUser *oldUser = [updatedSet member:user];
        if(oldUser != nil && oldUser.name != user.name) {
            [updatedSet removeObject:oldUser];
            [updatedSet addObject:user];
        }
    }
    
    [updatedSet minusSet:deletedUsers];
    [updatedSet unionSet:insertedUsers];
    

    //At this point inserted users should have temporary id's, but after the save they will have permament id's.
    //Display name generator maps names to user id's so it needs permament id's to be able to match them on subsecquent changes.
    NSError *error;
    BOOL success = [self obtainPermanentIDsForObjects:updatedSet.allObjects error:&error];
    Require(success == YES && error == nil);
    
    NSSet *updatedMOIDs = [NSSet set];
    ZMUserDisplayNameGenerator *newGenerator = [self.displayNameGenerator updatedWithUsers:updatedSet managedObjectIDsForChangedUsers:&updatedMOIDs];
    // If the old one wasn't 'nil' the new one can't be nil either:
    Require((self.displayNameGenerator.allUsers == nil) || (newGenerator.allUsers != nil));
    self.displayNameGenerator = newGenerator;
    
    NSMutableSet *usersToReturn = [[updatedMOIDs mapWithBlock:^id(NSManagedObjectID *objectID) {
        return [self objectWithID:objectID];
    }] mutableCopy];
        
    [usersToReturn unionSet:insertedUsers];
    return usersToReturn;
}

@end


