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


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol ZMTransportData;
@class MockUser;
@class MockConversation;

typedef NS_ENUM(int16_t, ZMTConnectionStatus) {
    ZMTConnectionStatusAccepted,
    ZMTConnectionStatusPending,
    ZMTConnectionStatusBlocked,
    ZMTConnectionStatusIgnored,
    ZMTConnectionStatusSent,
    ZMTConnectionStatusCancelled
};

@interface MockConnection : NSManagedObject

@property (nonatomic) NSString *status;
@property (nonatomic) MockConversation *conversation;
@property (nonatomic) MockUser *to;
@property (nonatomic) MockUser *from;
@property (nonatomic) NSDate *lastUpdate;
@property (nonatomic) NSString *message;

+ (NSString *)stringFromStatus:(ZMTConnectionStatus)status;
+ (ZMTConnectionStatus)statusFromString:(NSString *)string;

- (id<ZMTransportData>)transportData;

- (void)accept;
+ (NSFetchRequest *)sortedFetchRequest;

+ (MockConnection *)connectionInMOC:(NSManagedObjectContext *)moc from:(MockUser *)from to:(MockUser *)to message:(NSString *)message;

@end
