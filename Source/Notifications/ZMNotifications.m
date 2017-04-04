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


@import WireSystem;
@import WireTransport;

#import "ZMNotifications+Internal.h"

static NSString *const ZMCallEndedNotificationName = @"ZMCallEndedNotification";
static NSString *const ZMInvitationStatusChangedNotificationName = @"ZMInvitationStatusChangedNotification";
NSString *const ZMDatabaseCorruptionNotificationName = @"ZMDatabaseCorruptionNotification";


@interface ZMNotification ()

@property (nonatomic, readonly) id baseObject;
@property (nonatomic, readonly, copy) NSString* baseName;

- (instancetype)initWithName:(NSString *)name object:(id)object;

@end



@implementation ZMNotification

- (instancetype)initWithName:(NSString *)name object:(id)object;
{
    // Don't call [super init], NSNotification can't handle that
    _baseObject = object;
    _baseName = name;
    return self;
}

- (id)object;
{
    return self.baseObject;
}

- (NSString *)name;
{
    return self.baseName;
}

- (NSDictionary *)userInfo;
{
    return nil;
}

@end



@implementation ZMMovedIndex

+ (instancetype)movedIndexFrom:(NSUInteger)from to:(NSUInteger)to
{
    ZMMovedIndex *movedIndex = [[self alloc] init];
    movedIndex->_from = from;
    movedIndex->_to = to;
    return movedIndex;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:ZMMovedIndex.class]) {
        return NO;
    }
    
    ZMMovedIndex *other = (ZMMovedIndex *)object;
    return other.from == self.from && other.to == self.to;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"From %lu to %lu", (unsigned long)self.from, (unsigned long)self.to];
}

- (NSString *)description {
    return self.debugDescription;
}

- (NSUInteger)hash
{
    return (13 * self.from + 541 * self.to);
}
@end



@implementation ZMInvitationStatusChangedNotification : ZMNotification

+ (instancetype)invitationStatusChangedNotificationForContactEmailAddress:(NSString *)emailAddress status:(ZMInvitationStatus)status
{
    ZMInvitationStatusChangedNotification *note = [self invitationStatusChangedNotificationForStatus:status];
    note.emailAddress = emailAddress;
    return note;
}

+ (instancetype)invitationStatusChangedNotificationForContactPhoneNumber:(NSString *)phoneNumber status:(ZMInvitationStatus)status
{
    ZMInvitationStatusChangedNotification *note = [self invitationStatusChangedNotificationForStatus:status];
    note.phoneNumber = phoneNumber;
    return note;
}

+ (instancetype)invitationStatusChangedNotificationForStatus:(ZMInvitationStatus)status
{
    ZMInvitationStatusChangedNotification *note = [[self alloc] initWithName:ZMInvitationStatusChangedNotificationName object:nil];
    note.newStatus = status;
    return note;
}

+ (void)addInvitationStatusObserver:(id<ZMInvitationStatusObserver>)observer
{
    ZM_ALLOW_MISSING_SELECTOR([[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(invitationStatusChanged:) name:ZMInvitationStatusChangedNotificationName object:nil]);
}

+ (void)removeInvitationStatusObserver:(id<ZMInvitationStatusObserver>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:ZMInvitationStatusChangedNotificationName object:nil];
}

@end


