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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


#import "ZMConnection.h"
#import <zmessaging/ZMManagedObject+Internal.h>

#import <zmessaging/ZMConnection.h>

@class ZMConversation;
@class ZMUser;

extern NSString * const ZMConnectionStatusKey;

@interface ZMConnection (Internal)

@property (nonatomic) ZMConversation *conversation;
@property (nonatomic) ZMUser *to;
@property (nonatomic) BOOL existsOnBackend;
@property (nonatomic) NSDate *lastUpdateDateInGMT;

@property (nonatomic, readonly) NSString *statusAsString;

+ (ZMConnectionStatus)statusFromString:(NSString *)string;
+ (NSString *)stringForStatus:(ZMConnectionStatus)status;
/// Creates a connection for an already existing remote connection to the user with the given UUID. It also creates the user if it doesn't already exist and marks it for download.
+ (instancetype)connectionWithUserUUID:(NSUUID *)UUID inContext:(NSManagedObjectContext *)moc;
+ (ZMConnection *)connectionFromTransportData:(NSDictionary *)transportData managedObjectContext:(NSManagedObjectContext *)moc;

- (void)updateFromTransportData:(NSDictionary *)transportData;
- (void)updateConversationType;

@end
