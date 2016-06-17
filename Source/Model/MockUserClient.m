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


#import "MockUserClient+Internal.h"
#import "MockPreKey.h"


@implementation MockUserClient

@dynamic user;
@dynamic label;
@dynamic type;
@dynamic identifier;
@dynamic prekeys;
@dynamic lastPrekey;
@dynamic mackey;
@dynamic enckey;
@dynamic address;
@dynamic deviceClass;
@dynamic locationLatitude;
@dynamic locationLongitude;
@dynamic model;
@dynamic time;

@synthesize box;

+ (NSFetchRequest *)fetchRequestWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"UserClient"];
    request.predicate = predicate;
    return request;
}

+ (instancetype)insertClientWithPayload:(NSDictionary *)payload contenxt:(NSManagedObjectContext *)context
{
    NSString *type = [payload optionalStringForKey:@"type"];
    NSString *label = [payload optionalStringForKey:@"label"];
    NSDictionary *lastKeyPayload = [payload optionalDictionaryForKey:@"lastkey"];
    NSArray *prekyesPayload = [payload optionalArrayForKey:@"prekeys"];
    NSDictionary *sigkeysPayload = [payload optionalDictionaryForKey:@"sigkeys"];
    NSString *mackey = [sigkeysPayload optionalStringForKey:@"mackey"];
    NSString *enckey = [sigkeysPayload optionalStringForKey:@"enckey"];
    NSString *deviceClass = [payload optionalStringForKey:@"class"];
    NSString *model = [payload optionalStringForKey:@"model"];
    
    if (type == nil || !([type isEqualToString:@"temporary"] || [type isEqualToString:@"permanent"]) ||
        lastKeyPayload == nil || prekyesPayload == nil || mackey == nil || enckey == nil) {
        return nil;
    }
    
    if ([[lastKeyPayload numberForKey:@"id"] integerValue] != 0xFFFF) {
        return nil;
    }
    
    
    MockUserClient *newClient = [NSEntityDescription insertNewObjectForEntityForName:@"UserClient" inManagedObjectContext:context];
    newClient.label = label;
    newClient.type = type;
    newClient.identifier = [NSString createAlphanumericalString];
    newClient.mackey = mackey;
    newClient.enckey = enckey;
    newClient.deviceClass = deviceClass;
    newClient.model = model;
    newClient.locationLatitude = 52.5167;
    newClient.locationLongitude = 13.3833;
    newClient.address = @"62.96.148.44";
    newClient.time = [NSDate date];

    NSSet *prekeys = [MockPreKey insertNewKeysWithPayload:prekyesPayload context:context];
    for (MockPreKey *prekey in prekeys) {
        prekey.client = newClient;
    }
    MockPreKey *lastPreKey = [MockPreKey insertNewKeyWithPayload:lastKeyPayload context:context];
    lastPreKey.client = newClient;
    
    newClient.prekeys = prekeys;
    newClient.lastPrekey = lastPreKey;

    
    return newClient;
}

+ (instancetype)insertClientWithLabel:(NSString *)label type:(NSString *)type atLocation:(NSURL *)location inContext:(NSManagedObjectContext *)moc;
{
    MockUserClient *newClient = [NSEntityDescription insertNewObjectForEntityForName:@"UserClient" inManagedObjectContext:moc];

    newClient.identifier = [NSString createAlphanumericalString];
    newClient.label = label;
    newClient.type = type;
    
    newClient.time = [NSDate date];

    NSURL *clientOtrLocation = [location URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@", newClient.identifier, newClient.label]];
    [[NSFileManager defaultManager] createDirectoryAtURL:clientOtrLocation withIntermediateDirectories:YES attributes:nil error:nil];
    NSError *error;
    CBCryptoBox *box = [CBCryptoBox cryptoBoxWithPathURL:clientOtrLocation error:&error];
    if (error) NSLog(@"%@", error);
    VerifyReturnNil(box != nil && error == nil);
    newClient.box = box;
    
    
    NSArray <CBPreKey *> *prekeys = [box generatePreKeys:NSMakeRange(0, 100) error:&error];
    VerifyReturnNil([prekeys count] > 0 && error == nil);
    
    NSArray <MockPreKey *> *mockPrekeys = [MockPreKey insertMockPrekeysFromPrekeys:prekeys forClient:newClient inManagedObjectContext:moc];
    newClient.prekeys = [NSSet setWithArray:mockPrekeys];
    
    CBPreKey *lastprekey = [box lastPreKey:&error];
    MockPreKey *mockLastPrekey = [MockPreKey insertNewKeyWithPrekey:lastprekey forClient:newClient inManagedObjectContext:moc];
    newClient.lastPrekey = mockLastPrekey;
    
    VerifyReturnNil(prekeys);
    
    
    return newClient;
}

- (id<ZMTransportData>)transportData;
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"id"] = self.identifier;
    data[@"label"] = self.label ?: [NSNull null];
    data[@"type"] = self.type;
    data[@"time"] = self.time.transportString;
    if(self.model != nil) {
        data[@"model"] = self.model;
    }
    if(self.deviceClass != nil) {
        data[@"class"] = self.deviceClass;
    }
    data[@"address"] = self.address;
    data[@"location"] = @{
                           @"lat" : @(self.locationLatitude),
                           @"lon" : @(self.locationLongitude)
                           };
    return data;
}

+ (NSData *)encryptedDataFromClient:(MockUserClient *)fromClient toClient:(MockUserClient *)toClient identifier:(NSString *)identifier data:(NSData *)data;
{
    NSError *error;
    CBCryptoBox *box = fromClient.box;
    CBSession *session = [box sessionById:identifier error:&error];
    if (!session) {
        session = [box sessionWithId:identifier fromStringPreKey:toClient.lastPrekey.value error:&error];
    }
    
    NSData *encryptedData = [session encrypt:data error:&error];
    return encryptedData;
}


+ (NSData *)encryptedDataFromClient:(MockUserClient *)fromClient toClient:(MockUserClient *)toClient data:(NSData *)data;
{
    return [self encryptedDataFromClient:fromClient toClient:toClient identifier:toClient.identifier data:data];
}

+ (CBSessionMessage *)sessionMessageForEncryptedDataFromClient:(MockUserClient *)fromClient toClient:(MockUserClient *)toClient data:(NSData *)data;
{
    NSError *error;
    CBCryptoBox *box = toClient.box;
    CBSessionMessage *sessionMessage = [box sessionMessageWithId:fromClient.identifier fromMessage:data error:&error];
    return sessionMessage;
}

- (BOOL)establishConnectionWithClient:(MockUserClient *)client2;
{
    NSError *error = nil;
    if ([self.box sessionById:client2.identifier error:&error]) return YES;
    CBSession *session = [self.box sessionWithId:client2.identifier fromStringPreKey:client2.lastPrekey.value error:&error];
    
    return session != nil;
}


@end

@implementation NSString (RandomString)

+ (NSString *)createAlphanumericalString {
    u_int64_t number = 0;
    arc4random_buf(&number, sizeof(u_int64_t));
    NSString *string = [NSString stringWithFormat:@"%llx", number % LONG_LONG_MAX];
    return string;
}

@end
