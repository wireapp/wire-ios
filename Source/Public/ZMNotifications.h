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


@import Foundation;

#import "ZMUser.h"
#import "ZMSearchUser.h"
#import "ZMConversationMessageWindow.h"
#import "ZMConversationList.h"
#import "ZMAddressBookContact.h"

@class ZMConversation;

@class ZMInvitationStatusChangedNotification;


extern NSString * const ZMDatabaseCorruptionNotificationName;




@interface ZMNotification : NSNotification
@end

@interface ZMMovedIndex : NSObject

+ (instancetype)movedIndexFrom:(NSUInteger)from to:(NSUInteger)to;

@property (nonatomic, readonly) NSUInteger from;
@property (nonatomic, readonly) NSUInteger to;

@end



@protocol ZMInvitationStatusObserver <NSObject>
- (void)invitationStatusChanged:(ZMInvitationStatusChangedNotification *)note;
@end

@interface ZMInvitationStatusChangedNotification : ZMNotification

@property (nonatomic, readonly, copy) NSString *email;
@property (nonatomic, readonly, copy) NSString *phone;
@property (nonatomic, readonly) ZMInvitationStatus newStatus;

+ (void)addInvitationStatusObserver:(id<ZMInvitationStatusObserver>)observer;
+ (void)removeInvitationStatusObserver:(id<ZMInvitationStatusObserver>)observer;

@end
