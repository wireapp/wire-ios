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


@import WireTransport;
@import WireUtilities;

#import "ZMSearchUser+Internal.h"

#import "NSManagedObjectContext+zmessaging.h"
#import "ZMUser+Internal.h"
#import "ZMConnection+Internal.h"
#import "ZMAddressBookContact.h"

#import <WireDataModel/WireDataModel-Swift.h>

static NSCache *searchUserToSmallProfileImageCache;
static NSCache *searchUserToMediumImageCache;
static NSCache *searchUserToMediumAssetIDCache;

NSString *const ZMSearchUserTotalMutualFriendsKey = @"total_mutual_friends";

@interface ZMSearchUser ()
{
    NSData *_imageSmallProfileData;
    NSString *_imageSmallProfileIdentifier;

    NSData *_imageMediumData;
}

@property (nonatomic) NSString *displayName;
@property (nonatomic) NSString *initials;
@property (nonatomic) NSString *name; //< name received from BE
@property (nonatomic) NSString *handle;

@property (nonatomic) BOOL isConnected;
@property (nonatomic) ZMAccentColor accentColorValue;

@property (nonatomic, copy) NSString *connectionRequestMessage;
@property (nonatomic) BOOL isPendingApprovalByOtherUser;

@property (weak, nonatomic, readonly) NSManagedObjectContext *syncMOC;
@property (weak, nonatomic, readonly) NSManagedObjectContext *uiMOC;

@property (nonatomic) ZMUser *user;
@property (nonatomic) ZMAddressBookContact *contact;

@end



@interface ZMSearchUser (MediumImage_Private)

- (void)privateRequestMediumProfileImageInUserSession:(id<ZMManagedObjectContextProvider>)userSession;

@end



@implementation ZMSearchUser

- (instancetype)initWithName:(NSString *)name
                      handle:(NSString *)handle
                 accentColor:(ZMAccentColor)color
                    remoteID:(NSUUID *)remoteID
                        user:(ZMUser *)user
    syncManagedObjectContext:(NSManagedObjectContext *)syncMOC
      uiManagedObjectContext:(NSManagedObjectContext *)uiMOC;
{
    self = [super init];
    if (self) {
        _user = user;
        _syncMOC = syncMOC;
        _uiMOC = uiMOC;

        if (self.user == nil) {
            _name = name.stringByRemovingExtremeCombiningCharacters;
            _handle = handle.stringByRemovingExtremeCombiningCharacters;
            
            PersonName *personName = [PersonName personWithName:name schemeTagger:nil];
            _initials = personName.initials;
            _accentColorValue =  color;
            _isConnected = NO;
            _remoteIdentifier = remoteID;
        } else {
            [self.user updateWithSearchResultName:name handle:handle];
        }
    }

    return self;
}

- (instancetype)initWithName:(NSString *)name
                      handle:(NSString *)handle
                 accentColor:(ZMAccentColor)color
                    remoteID:(NSUUID *)remoteID
                        user:(ZMUser *)user
                 userSession:(id<ZMManagedObjectContextProvider>)userSession;
{
    return [self initWithName:name
                       handle:handle
                  accentColor:color
                     remoteID:remoteID
                         user:user
     syncManagedObjectContext:userSession.syncManagedObjectContext
       uiManagedObjectContext:userSession.managedObjectContext];
}

- (instancetype)initWithUser:(ZMUser *)user
                 userSession:(id<ZMManagedObjectContextProvider>)userSession
{
    self = [self initWithName:user.name
                       handle:user.handle
                  accentColor:user.accentColorValue
                     remoteID:user.remoteIdentifier
                         user:user
                  userSession:userSession];
    if (nil != self) {
        self.totalCommonConnections = user.totalCommonConnections;
    }
    return self;
}

+ (NSArray <ZMSearchUser *> *)usersWithUsers:(NSArray <ZMUser *> *)users userSession:(id<ZMManagedObjectContextProvider>)userSession;
{
    NSMutableArray <ZMSearchUser *> *searchUsers = [[NSMutableArray alloc] init];
    
    for (ZMUser *user in users) {
        ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithUser:user userSession:userSession];
        if (searchUser != nil) {
            [searchUsers addObject:searchUser];
        }
    }
    
    return searchUsers;
}

- (instancetype)initWithPayload:(NSDictionary *)payload userSession:(id<ZMManagedObjectContextProvider>)userSession
{
    NSUUID *identifier = [payload optionalUuidForKey:@"id"];
    NSNumber *accentId = [payload optionalNumberForKey:@"accent_id"];
    ZMUser *existingUser = [ZMUser userWithRemoteID:identifier
                                     createIfNeeded:NO
                                          inContext:userSession.managedObjectContext];

    self = [self initWithName:payload[@"name"]
                       handle:payload[@"handle"]
                  accentColor:[ZMUser accentColorFromPayloadValue:accentId]
                     remoteID:identifier
                         user:existingUser
                  userSession:userSession];
    
    
    if (nil != self) {
        self.totalCommonConnections = [[payload optionalNumberForKey:ZMSearchUserTotalMutualFriendsKey] unsignedIntegerValue];
    }
    return self;
}

+ (NSArray <ZMSearchUser *> *)usersWithPayloadArray:(NSArray <NSDictionary *> *)payloadArray userSession:(id<ZMManagedObjectContextProvider>)userSession;
{
    NSMutableArray <ZMSearchUser *> *searchUsers = [[NSMutableArray alloc] init];
    
    for (NSDictionary *payload in payloadArray) {
        VerifyReturnNil([payload isKindOfClass:[NSDictionary class]]);
        VerifyReturnNil([payload uuidForKey:@"id"] != nil);
        ZMSearchUser *searchUser = [[ZMSearchUser alloc] initWithPayload:payload userSession:userSession];
        if (searchUser != nil) {
            [searchUsers addObject:searchUser];
        }
    }
    
    return searchUsers;
}

- (instancetype)initWithContact:(ZMAddressBookContact *)contact
                           user:(ZMUser *)user
                    userSession:(id<ZMManagedObjectContextProvider>)userSession
{
    self = [self initWithName:contact.name
                       handle:user.handle
                  accentColor:ZMAccentColorUndefined
                     remoteID:nil
                         user:user
                  userSession:userSession];
    
    if (self != nil) {
        _contact = contact;
    }
    
    return self;
}

- (NSString *)name
{
    return self.user ? self.user.name : _name;
}

- (NSString *)handle
{
    return self.user ? self.user.handle : _handle;
}

- (NSString *)displayName
{
    return self.user ? self.user.displayName : _name;
}

- (NSString *)initials
{
    return self.user ? self.user.initials : _initials;
}

- (BOOL)isTeamMember
{
    return self.user ? self.user.isTeamMember : NO;
}

- (BOOL)isGuestInConversation:(ZMConversation *)conversation
{
    return self.user ? [self.user isGuestInConversation:conversation] : NO;
}

- (BOOL)isConnected;
{
    return self.user ? self.user.isConnected : _isConnected;
}

+ (NSSet *)keyPathsForValuesAffectingIsConnected
{
    return [NSSet setWithObjects:@"user", @"user.isConnected", nil];
}

- (ZMAccentColor)accentColorValue;
{
    return self.user ? self.user.accentColorValue : _accentColorValue;
}


- (NSUUID *)remoteIdentifier
{
    return self.user ? self.user.remoteIdentifier : _remoteIdentifier;
}

- (BOOL)hasCachedMediumAssetIDOrData
{
    return (self.imageMediumData != nil || self.mediumLegacyId != nil || self.completeAssetKey != nil);
}

- (BOOL)isLocalOrHasCachedProfileImageData;
{
    return (self.user != nil) || (self.imageSmallProfileData != nil && self.hasCachedMediumAssetIDOrData);
}

@synthesize isPendingApprovalByOtherUser = _isPendingApprovalByOtherUser;
- (BOOL)isPendingApprovalByOtherUser;
{
    return (self.user != nil) ? self.user.isPendingApprovalByOtherUser : _isPendingApprovalByOtherUser;
}

+ (NSSet *)keyPathsForValuesAffectingIsPendingApprovalByOtherUser
{
    return [NSSet setWithObjects:@"user.isPendingApprovalByOtherUser", @"user", nil];
}

- (void)connectWithMessageText:(NSString *)text completionHandler:(dispatch_block_t)handler;
{
    dispatch_block_t completionHandler = ^(){
        [self.uiMOC.searchUserObserverCenter notifyUpdatedSearchUser:self];
        if (handler != nil) {
            handler();
        }
    };
    
    // Copy before switching thread / queue:
    handler = [handler copy];
    text = [text copy];
    
    if (! [self canBeConnected]) {
        if (handler != nil) {
            handler();
        }
        return;
    }
    
    self.isPendingApprovalByOtherUser = YES;
    self.connectionRequestMessage = text;
    
    if (self.user != nil) {
        [self.user connectWithMessageText:text completionHandler:completionHandler];
    } else {
        NSManagedObjectContext *syncMOC = self.syncMOC;
        CheckString(syncMOC != nil,
                    "No user session / sync context.");
        NSString *name = [self.name copy];
        ZMAccentColor accentColorValue = self.accentColorValue;
        [syncMOC performGroupedBlock:^{
            ZMUser *user = [ZMUser userWithRemoteID:self.remoteIdentifier createIfNeeded:YES inContext:syncMOC];
            user.name = name;
            user.accentColorValue = accentColorValue;
            user.needsToBeUpdatedFromBackend = YES;
            ZMConnection *connection = [ZMConnection insertNewSentConnectionToUser:user];
            connection.message = text;
            
            [syncMOC saveOrRollback];
            
            // Do a delayed save and run the handler on the main queue, once it's done:
            ZMSDispatchGroup * g = [ZMSDispatchGroup groupWithLabel:@"ZMSearchUser"];
            [self.syncMOC enqueueDelayedSaveWithGroup:g];
            
            [self.uiMOC.dispatchGroup enter];
            ZM_WEAK(self);
            [g notifyOnQueue:dispatch_get_main_queue() block:^{
                NSError *uiObjectError = nil;
                self.user = [self.uiMOC existingObjectWithID:user.objectID error:&uiObjectError];
                Require(uiObjectError == nil);
                
                ZM_STRONG(self);
                completionHandler();
                [self.uiMOC.dispatchGroup leave];
            }];
        }];
    }
}

- (BOOL)isSelfUser
{
    return self.user.isSelfUser;
}

- (BOOL)canBeConnected
{
    return ((self.user == nil) ?
            (!self.isConnected && self.remoteIdentifier != nil) :
            self.user.canBeConnected);
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: %p> (ID: %@, name: %@, accent: %d, connected: %@), user: ",
                                    self.class, self, self.remoteIdentifier.transportString, self.displayName, self.accentColorValue,
                                    self.isConnected ? @"YES" : @"NO"];
    if (self.user != nil) {
        [description appendFormat:@"<%@: %p> %@", self.user.class, self.user, self.user.objectID.URIRepresentation];
    } else {
        [description appendString:@" nil"];
    }
    return description;
}

- (NSUInteger)hash;
{
    union {
        NSUInteger hash;
        uuid_t uuid;
    } u;
    u.hash = 0;
    [self.remoteIdentifier getUUIDBytes:u.uuid];
    return u.hash;
}

- (BOOL)isEqual:(id)object;
{
    if (! [object isKindOfClass:[ZMSearchUser class]]) {
        return NO;
    }
    ZMSearchUser *other = object;
    
    if  (self.remoteIdentifier == nil) {
        return [self.contact isEqual:other.contact] && other.user == nil;
    } else {
        return other.remoteIdentifier == self.remoteIdentifier || [other.remoteIdentifier isEqual:self.remoteIdentifier];
    }
}


+ (NSCache *)searchUserToSmallProfileImageCache;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        searchUserToSmallProfileImageCache = [[NSCache alloc] init];
    });
    return searchUserToSmallProfileImageCache;
}

+ (NSCache *)searchUserToMediumImageCache;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        searchUserToMediumImageCache = [[NSCache alloc] init];
        searchUserToMediumImageCache.countLimit = 10;
    });
    return searchUserToMediumImageCache;
}

+ (NSCache <NSUUID *, SearchUserAssetObjC* > *)searchUserToMediumAssetIDCache;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        searchUserToMediumAssetIDCache = [[NSCache alloc] init];
    });
    return searchUserToMediumAssetIDCache;
}


- (NSData *)cachedSmallProfileData
{
    return [[ZMSearchUser searchUserToSmallProfileImageCache] objectForKey:self.remoteIdentifier];
}

- (NSData *)cachedMediumProfileData
{
    return [[ZMSearchUser searchUserToMediumImageCache] objectForKey:self.remoteIdentifier];
}

- (NSUUID *)cachedMediumLegacyId
{
    return self.cachedMediumAsset.legacyID;
}

- (NSString *)cachedCompleteAssetKey
{
    return self.cachedMediumAsset.assetKey;
}

- (SearchUserAssetObjC *)cachedMediumAsset
{
    return [ZMSearchUser.searchUserToMediumAssetIDCache objectForKey:self.remoteIdentifier];
}

- (NSData *)imageSmallProfileData
{
    if (self.user != nil) {
        return self.user.imageSmallProfileData;
    }
    if (_imageSmallProfileData == nil) {
        _imageSmallProfileData = [self cachedSmallProfileData];
        if (_imageSmallProfileData != nil) {
            _imageSmallProfileIdentifier = self.remoteIdentifier.transportString;
        };
    }
    return _imageSmallProfileData;
}


+ (NSSet *)keyPathsForValuesAffectingImageSmallProfileData
{
    return [NSSet setWithObjects:@"user.imageSmallProfileData", nil];
}

- (NSData *)imageMediumData
{
    if (self.user != nil) {
        return self.user.imageMediumData;
    }
    if (_imageMediumData == nil) {
        _imageMediumData = [self cachedMediumProfileData];
    }
    return _imageMediumData;
}


- (NSUUID *)mediumLegacyId
{
    if (_mediumLegacyId == nil) {
        _mediumLegacyId = [self cachedMediumLegacyId];
    }
    return _mediumLegacyId;
}

- (NSString *)completeAssetKey
{
    if (_completeAssetKey == nil) {
        _completeAssetKey = [self cachedCompleteAssetKey];
    }
    return _completeAssetKey;
}

- (NSString *)imageSmallProfileIdentifier
{
    if (self.user != nil) {
        return self.user.imageSmallProfileIdentifier;
    }
    if (_imageSmallProfileIdentifier != nil) {
        return _imageSmallProfileIdentifier;
    }
    if ([self cachedSmallProfileData] != nil) {
        return self.remoteIdentifier.transportString;
    }
    return nil;
}


- (NSString *)imageMediumIdentifier
{
    if (self.user != nil) {
        return self.user.imageMediumIdentifier;
    }
    if (self.completeAssetKey != nil) {
        return self.completeAssetKey;
    }
    if (self.mediumLegacyId != nil) {
        return self.mediumLegacyId.transportString;
    }
    if ([self cachedMediumProfileData] != nil) {
        return self.remoteIdentifier.transportString;
    }
    return nil;
}

- (NSString *)smallProfileImageCacheKey
{
    if (self.user != nil) {
        return self.user.smallProfileImageCacheKey;
    }
    return self.imageSmallProfileIdentifier;
}

- (NSString *)mediumProfileImageCacheKey
{
    if (self.user != nil) {
        return self.user.mediumProfileImageCacheKey;
    }
    return self.imageMediumIdentifier;
}


- (void)notifyNewSmallImageData:(NSData *)data searchUserObserverCenter:(SearchUserObserverCenter *)searchUserObserverCenter;
{
    _imageSmallProfileData = data;
    [searchUserObserverCenter notifyUpdatedSearchUser:self];
}

- (void)setAndNotifyNewMediumImageData:(NSData *)data searchUserObserverCenter:(SearchUserObserverCenter *)searchUserObserverCenter;
{
    if (_imageMediumData == nil || ![_imageMediumData isEqualToData:data]) {
        _imageMediumData = data;
    }
    [searchUserObserverCenter notifyUpdatedSearchUser:self];
}

- (void)refreshData {
    [self.user refreshData];
}

@end




@implementation ZMSearchUser (Connections)

@dynamic isPendingApprovalByOtherUser; // This is implemented above

@end

