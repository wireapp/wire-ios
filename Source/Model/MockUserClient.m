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

@synthesize encryptionContext;

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
    EncryptionContext *encryptionContext = [[EncryptionContext alloc] initWithPath:clientOtrLocation];
    VerifyReturnNil(encryptionContext != nil);
    newClient.encryptionContext = encryptionContext;
    
    __block NSArray *prekeys;
    __block NSString *lastPrekey;
    __block NSError *error;
    [encryptionContext perform:^(EncryptionSessionsDirectory * _Nonnull sessionsDirectory) {
        prekeys = [sessionsDirectory generatePrekeys:NSMakeRange(0, 100) error:&error];
        lastPrekey = [sessionsDirectory generateLastPrekeyAndReturnError:&error];
    }];
    VerifyReturnNil([prekeys count] > 0 && error == nil);
    NSArray *preKeyStrings = [prekeys mapWithBlock:^id(NSDictionary *keyInfo) {
        return keyInfo[@"prekey"];
    }];
    VerifyReturnNil([prekeys count] > 0 && error == nil);
    
    NSArray <MockPreKey *> *mockPrekeys = [MockPreKey insertMockPrekeysFromPrekeys:preKeyStrings forClient:newClient inManagedObjectContext:moc];
    newClient.prekeys = [NSSet setWithArray:mockPrekeys];
    
    MockPreKey *mockLastPrekey = [MockPreKey insertNewKeyWithPrekey:lastPrekey forClient:newClient inManagedObjectContext:moc];
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

+ (NSData *)encryptedDataFromClient:(MockUserClient *)fromClient toClient:(MockUserClient *)toClient data:(NSData *)data
{
    __block NSError *error;
    __block NSData *encryptedData;
    EncryptionContext *encryptionContext = fromClient.encryptionContext;
    [encryptionContext perform:^(EncryptionSessionsDirectory * _Nonnull sessionsDirectory) {
        if (![sessionsDirectory hasSessionForID:toClient.identifier]) {
            [sessionsDirectory createClientSession:toClient.identifier base64PreKeyString:toClient.lastPrekey.value error:&error];
        }
        encryptedData = [sessionsDirectory encrypt:data recipientClientId:toClient.identifier error:&error];
    }];
    return encryptedData;
}


+ (NSData *)sessionMessageDataForEncryptedDataFromClient:(MockUserClient *)fromClient toClient:(MockUserClient *)toClient data:(NSData *)data
{
    EncryptionContext *encryptionContext = toClient.encryptionContext;
    __block NSData *decryptedData;
    [encryptionContext perform:^(EncryptionSessionsDirectory * _Nonnull sessionsDirectory) {
        NSError *error;
        decryptedData = [sessionsDirectory createClientSessionAndReturnPlaintext:fromClient.identifier prekeyMessage:data error:&error];
    }];
    return decryptedData;
}

- (BOOL)establishConnectionWithClient:(MockUserClient *)client
{
    __block NSError *error = nil;
    __block BOOL hasSession = NO;
    [self.encryptionContext perform:^(EncryptionSessionsDirectory * _Nonnull sessionsDirectory) {
        if (! [sessionsDirectory hasSessionForID:client.identifier]) {
            [sessionsDirectory createClientSession:client.identifier base64PreKeyString:client.lastPrekey.value error:&error];
        }
        hasSession = [sessionsDirectory hasSessionForID:client.identifier];
    }];
    return hasSession;
}

- (void)dealloc
{
    self.encryptionContext = nil;
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
