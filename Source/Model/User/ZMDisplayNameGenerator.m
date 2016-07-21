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


#import "ZMDisplayNameGenerator.h"
#import "ZMPersonName.h"

#import "ZMUser.h"

@interface ZMDisplayNameGenerator ()
@property (nonatomic, copy) NSDictionary *idToFullNameMap;
@property (nonatomic, copy) NSDictionary *idToPersonNameMap;
@property (nonatomic, copy) NSDictionary *fullNameToPersonNameMap;
@property (nonatomic, copy) NSDictionary *idToDisplayNameMap;
@property (nonatomic, copy) NSDictionary *idToInitialsMap;

@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation ZMDisplayNameGenerator


- (instancetype)createCopyWithMap:(NSDictionary *)map updatedKeys:(NSSet **)updated
{
    ZMDisplayNameGenerator *newGenerator = [[ZMDisplayNameGenerator alloc] init];
    newGenerator = [self createCopyForGenerator:newGenerator withMap:map updatedKeys:updated];
    return newGenerator;
}

- (instancetype)createCopyForGenerator:(ZMDisplayNameGenerator *)generator withMap:(NSDictionary *)map updatedKeys:(NSSet **)updated
{
    generator.idToFullNameMap = map;
    generator.fullNameToPersonNameMap  = [self fullNameToPersonNameMapForGenerator:generator];
    [self translateMapsForGenerator:generator];
    *updated = [self updatedUserManagedObjectIDsForGenerator:generator];
    return generator;
}

# pragma mark - Setters and Getters

- (void)setIdToFullNameMap:(NSDictionary *)idToFullNameMap
{
    _idToFullNameMap = idToFullNameMap;
    [self mapIDsAndFullNameToPersonName];
}

- (NSDictionary *)fullNameToPersonNameMap
{
    if (!_fullNameToPersonNameMap) {
        [self mapIDsAndFullNameToPersonName];
    }
    
    return _fullNameToPersonNameMap;
}

- (NSDictionary *)idToPersonNameMap
{
    if (!_idToPersonNameMap) {
        [self mapIDsAndFullNameToPersonName];
    }
    
    return _idToPersonNameMap;
}

- (NSDictionary *)idToInitialsMap
{
    if (!_idToInitialsMap) {
        [self mapIDsAndFullNameToPersonName];
    }
    
    return _idToInitialsMap;
}

- (void)mapIDsAndFullNameToPersonName
{
    if (self.idToFullNameMap == nil) {
        self.idToPersonNameMap = nil;
        self.fullNameToPersonNameMap = nil;
        self.idToInitialsMap = nil;
    }
    
    NSMutableDictionary *idToPersonNameMap = [NSMutableDictionary dictionary];
    NSMutableDictionary *fullNameToPersonNameMap = [NSMutableDictionary dictionary];
    NSMutableDictionary *idToInitialsMap = [NSMutableDictionary dictionary];
    
    [self.idToFullNameMap enumerateKeysAndObjectsUsingBlock:^(id key, NSString *fullName, BOOL *__unused stop) {
        ZMPersonName *personName = [ZMPersonName personWithName:fullName];
        fullNameToPersonNameMap[fullName] = personName;
        idToPersonNameMap[key] =  personName;
        idToInitialsMap[key] = personName.initials;
    }];
    
    self.idToPersonNameMap = [NSDictionary dictionaryWithDictionary:idToPersonNameMap];
    self.fullNameToPersonNameMap = [NSDictionary dictionaryWithDictionary:fullNameToPersonNameMap];
    self.idToInitialsMap = [NSDictionary dictionaryWithDictionary:idToInitialsMap];
}


# pragma mark - Copying from other Generator

- (NSDictionary *)fullNameToPersonNameMapForGenerator:(ZMDisplayNameGenerator *)newGenerator
{
    // Reuse the existing mapping to reduce the expensive generation of personNames
    
    NSDictionary *oldMap = self.fullNameToPersonNameMap;
    NSMutableDictionary *newMap = [NSMutableDictionary dictionary];
    
    for (NSString *fullName in newGenerator.idToFullNameMap.allValues) {
        ZMPersonName *oldPersonName = oldMap[fullName];
        if (oldPersonName) {
            newMap[fullName] = oldPersonName;
        }
        else {
            ZMPersonName *newPersonName = [ZMPersonName personWithName:fullName];
            newMap[fullName] = newPersonName;
        }
    }
    return newMap;
}

- (void)translateMapsForGenerator:(ZMDisplayNameGenerator *)generator
{
    // Loop through the existing maps, if the existing name does not exist in the old idToPersonNameMap, create the personName and add it
    
    NSMutableDictionary *idToPersonNameMap = [NSMutableDictionary dictionary];
    NSMutableDictionary *idToInitialsMap = [NSMutableDictionary dictionary];
    
    [generator.idToFullNameMap enumerateKeysAndObjectsUsingBlock:^(id key, NSString *fullName, BOOL *__unused stop) {
        ZMPersonName *personName = generator.fullNameToPersonNameMap[fullName];
        if (personName != nil) {
            idToPersonNameMap[key] = personName;
            idToInitialsMap[key] = personName.initials;
        }
        else {
            ZMPersonName *newPersonName = [ZMPersonName personWithName:fullName];
            idToPersonNameMap[key] = newPersonName;
            idToInitialsMap[key] = newPersonName.initials;
        }
    }];
    
    generator.idToPersonNameMap = [idToPersonNameMap copy];
    generator.idToInitialsMap = [idToInitialsMap copy];
}


- (NSString *)displayNameForKey:(id<NSCopying>)key
{
    if (self.idToDisplayNameMap == nil) {
        self.idToDisplayNameMap = [self idToDisplayNameMapWithIdToPersonNameMap:self.idToPersonNameMap];
    }
    return self.idToDisplayNameMap[key] ?: @"";
}

- (NSString *)initialsForKey:(id<NSCopying>)key
{
    return self.idToInitialsMap[key];
}

- (NSDictionary *)idToDisplayNameMapWithIdToPersonNameMap:(NSDictionary *)idToPersonNameMap
{
    // count the givenNames and abbreviatedNames in idToPersonNameMap
    NSCountedSet *givenNameCounts = [[NSCountedSet alloc] init];
    NSCountedSet *abbreviatedNameCounts = [[NSCountedSet alloc] init];
    
    for (ZMPersonName *name in idToPersonNameMap.allValues) {
        [givenNameCounts addObject:name.givenName];
        [abbreviatedNameCounts addObject:name.abbreviatedName];
    }
    
    NSMutableDictionary *namesDict = [NSMutableDictionary dictionary];
    
    [idToPersonNameMap enumerateKeysAndObjectsUsingBlock:^(id key, ZMPersonName *personName, BOOL *__unused stop) {
        NSString *givenName = personName.givenName;
        NSString *abbreviatedName = personName.abbreviatedName;
        if ([givenName isEqualToString:abbreviatedName]) {
            namesDict[key] = givenName;
        } else {
            if ([givenNameCounts countForObject:givenName] < 2) {
                namesDict[key] = givenName;
            } else if ([abbreviatedNameCounts countForObject:abbreviatedName] < 2) {
                namesDict[key] = abbreviatedName;
            } else {
                namesDict[key] = personName.fullName;
            }
        }
    }];
    return namesDict;
}


- (NSSet *)updatedUserManagedObjectIDsForGenerator:(ZMDisplayNameGenerator *)newGenerator
{
    newGenerator.idToDisplayNameMap = [self idToDisplayNameMapWithIdToPersonNameMap:newGenerator.idToPersonNameMap];

    if (self.idToDisplayNameMap == nil ){
        self.idToDisplayNameMap = [self idToDisplayNameMapWithIdToPersonNameMap:self.idToPersonNameMap];
    }
    
    NSMutableSet *updated = [NSMutableSet set];
    
    // if the new displayName is the same as the old one or when the old map did not contain the user, add it to updated
    [newGenerator.idToFullNameMap enumerateKeysAndObjectsUsingBlock:^(id userManagedObjectID, NSString *newFullName, BOOL *__unused stop) {
        NSString *oldFullName = self.idToFullNameMap[userManagedObjectID];
        if (![newFullName isEqualToString:oldFullName]) {
            [updated addObject:userManagedObjectID];
        }
        
        NSString *oldDisplayName = self.idToDisplayNameMap[userManagedObjectID];
        NSString *newDisplayName = newGenerator.idToDisplayNameMap[userManagedObjectID];
        if (![newDisplayName isEqualToString:oldDisplayName]) {
            [updated addObject:userManagedObjectID];
        }
    }];

    return updated;
}


@end

