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

extern NSString * const ZMUserClientTypePermanent;
extern NSString * const ZMUserClientTypeTemporary;

@class ZMUser;
@class Team;

@protocol UserClientType <NSObject>
@property (nonatomic) NSString *type;
@property (nonatomic) NSString *label;
@property (nonatomic) NSString *remoteIdentifier;
@property (nonatomic) ZMUser *user;
@property (nonatomic) NSString *activationAddress;
@property (nonatomic) NSDate *activationDate;
@property (nonatomic) NSString *model;
@property (nonatomic) NSString *deviceClass;
@property (nonatomic) double activationLatitude;
@property (nonatomic) double activationLongitude;
@property (nonatomic) NSData *fingerprint;
@property (nonatomic, readonly) BOOL verified;
- (void)resetSession;
@end
