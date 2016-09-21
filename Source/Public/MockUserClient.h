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

@property (nonatomic, nonnull) MockUser *user;
@property (nonatomic, nonnull) NSString *identifier;

/// Device label
@property (nonatomic, nonnull) NSString *label;

/// Device type
@property (nonatomic, nonnull) NSString *type;

/// IP address of registration
@property (nonatomic, nonnull) NSString *address;

/// Device class
@property (nonatomic, nullable) NSString *deviceClass;

/// Registration location latitude
@property (nonatomic) double locationLatitude;

/// Registration location longitude
@property (nonatomic) double locationLongitude;

/// Device model
@property (nonatomic, nullable) NSString *model;

/// Registration time
@property (nonatomic, nonnull) NSDate *time;

@property (nonatomic, nonnull) NSSet *prekeys;
@property (nonatomic, nonnull) MockPreKey *lastPrekey;

@property (nonatomic, nonnull) NSString *mackey;
@property (nonatomic, nonnull) NSString *enckey;

/// Returns a fetch request to fetch MockUserClients with the given predicate
+ (nonnull NSFetchRequest *)fetchRequestWithPredicate:(nullable NSPredicate *)predicate;

+ (nullable instancetype)insertClientWithPayload:(nonnull NSDictionary *)paylod contenxt:(nonnull NSManagedObjectContext *)context;
+ (nullable instancetype)insertClientWithLabel:(nonnull NSString *)label type:(nonnull NSString *)type atLocation:(nonnull NSURL *)location inContext:(nonnull NSManagedObjectContext *)moc;
- (nonnull id<ZMTransportData>)transportData;

+ (nonnull NSData *)encryptedDataFromClient:(nonnull MockUserClient *)fromClient toClient:(nonnull MockUserClient *)toClient data:(nonnull NSData *)data;
+ (nonnull NSData *)sessionMessageDataForEncryptedDataFromClient:(nonnull MockUserClient *)fromClient toClient:(nonnull  MockUserClient *)toClient data:(nonnull  NSData *)data;
- (BOOL)establishConnectionWithClient:(nonnull MockUserClient *)client2;

@end

@interface NSString(RandomString)

+ (nonnull NSString *)createAlphanumericalString;

@end
