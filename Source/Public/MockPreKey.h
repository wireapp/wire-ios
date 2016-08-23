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
@import Cryptobox;

@class MockUserClient;

@interface MockPreKey : NSManagedObject

@property (nonatomic) MockUserClient *client;
@property (nonatomic) MockUserClient *lastPrekeyOfClient;

@property (nonatomic) NSInteger identifier;
@property (nonatomic) NSString *value;

+ (instancetype)insertNewKeyWithPayload:(NSDictionary *)payload context:(NSManagedObjectContext *)context;;

+ (NSSet *)insertNewKeysWithPayload:(NSArray *)payload context:(NSManagedObjectContext *)context;;

+ (NSArray <MockPreKey *> *)insertMockPrekeysFromPrekeys:(NSArray <NSString *> *)prekeys forClient:(MockUserClient *)client inManagedObjectContext:(NSManagedObjectContext *)moc;
+ (MockPreKey *)insertNewKeyWithPrekey:(NSString *)prekey forClient:(MockUserClient *)client inManagedObjectContext:(NSManagedObjectContext *)moc;

@end
