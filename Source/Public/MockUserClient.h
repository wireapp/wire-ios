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
@import ZMTransport;

@class MockUser;
@class MockPreKey;
@class CBSessionMessage;

@interface MockUserClient : NSManagedObject

@property (nonatomic) MockUser *user;
@property (nonatomic) NSString *identifier;

/// Device label
@property (nonatomic) NSString *label;

/// Device type
@property (nonatomic) NSString *type;

/// IP address of registration
@property (nonatomic) NSString *address;

/// Device class
@property (nonatomic) NSString *deviceClass;

/// Registration location latitude
@property (nonatomic) double locationLatitude;

/// Registration location longitude
@property (nonatomic) double locationLongitude;

/// Device model
@property (nonatomic) NSString *model;

/// Registration time
@property (nonatomic) NSDate *time;

@property (nonatomic) NSSet *prekeys;
@property (nonatomic) MockPreKey *lastPrekey;

@property (nonatomic) NSString *mackey;
@property (nonatomic) NSString *enckey;

/// Returns a fetch request to fetch MockUserClients with the given predicate
+ (NSFetchRequest *)fetchRequestWithPredicate:(NSPredicate *)predicate;

+ (instancetype)insertClientWithPayload:(NSDictionary *)paylod contenxt:(NSManagedObjectContext *)context;
+ (instancetype)insertClientWithLabel:(NSString *)label type:(NSString *)type atLocation:(NSURL *)location inContext:(NSManagedObjectContext *)moc;
- (id<ZMTransportData>)transportData;

+ (NSData *)encryptedDataFromClient:(MockUserClient *)fromClient toClient:(MockUserClient *)toClient data:(NSData *)data;
+ (NSData *)sessionMessageDataForEncryptedDataFromClient:(MockUserClient *)fromClient toClient:(MockUserClient *)toClient data:(NSData *)data;
- (BOOL)establishConnectionWithClient:(MockUserClient *)client2;

@end

@interface NSString(RandomString)

+ (NSString *)createAlphanumericalString;

@end
