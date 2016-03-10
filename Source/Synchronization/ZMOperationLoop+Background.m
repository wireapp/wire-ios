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


@import ZMTransport;
@import Cryptobox;

#import "ZMOperationLoop+Background.h"
#import "ZMOperationLoop+Private.h"

#import "ZMLocalNotificationDispatcher.h"
#import "ZMUpdateEvent.h"
#import "ZMSyncStrategy+Internal.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>
#import <zmessaging/zmessaging-Swift.h>

static char* const ZMLogTag ZM_UNUSED = "OperationLoop-Background";


static NSString * const PushChannelDataKey = @"data";
static NSString * const PushChannelIdentifierKey = @"id";
static NSString * const PushChannelNotificationTypeKey = @"type";

static NSString * const PushNotificationTypeCipher = @"cipher";
static NSString * const PushNotificationTypeNotice = @"notice";



@implementation ZMOperationLoop (Background)


- (void)saveEventsAndSendNotificationForPayload:(NSDictionary *)payload fetchCompletionHandler:(ZMPushResultHandler)completionHandler source:(ZMPushNotficationType)source;
{
    ZMBackgroundActivity *activity = [ZMBackgroundActivity beginBackgroundActivityWithName:@"send notification for payload"];
    [self.syncMOC performGroupedBlock:^(){
        
        EventsWithIdentifier *eventsWithID = [self eventsFromPushChannelData:payload];
        NSArray *events = eventsWithID.events;
        
        if (events.count > 0) {
            if (source == ZMPushNotficationTypeVoIP && nil != eventsWithID.identifier) {
                [self.backgroundAPNSPingBackStatus didReceiveVoIPNotification:eventsWithID handler:^(ZMPushPayloadResult result) {
                    [self forwardEvents:events andCallCompletionHandler:completionHandler withResult:result];
                }];
            }
            else {
                [self forwardEvents:events andCallCompletionHandler:completionHandler withResult:ZMPushPayloadResultSuccess];
            }
            [activity endActivity];
        }
        else if (completionHandler != nil) {
            ZMLogPushKit(@"ZMOperationLoop - calling completionHandler without creating notifications");
            [self.syncMOC.dispatchGroup notifyOnQueue:dispatch_get_main_queue() block:^{
                completionHandler(ZMPushPayloadResultSuccess);
                [activity endActivity];
            }]; 
        }
    }];
}

- (void)forwardEvents:(NSArray *)events andCallCompletionHandler:(ZMPushResultHandler)completionHandler withResult:(ZMPushPayloadResult)result
{
    NSArray *nonFlowEvents = [events filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ZMUpdateEvent *event, NSDictionary<NSString *,id> * _Nullable ZM_UNUSED bindings) {
        return !event.isFlowEvent;
    }]];
                              
    [self.syncStrategy consumeUpdateEvents:nonFlowEvents];
    [self.syncMOC saveOrRollback];
    [self.syncStrategy updateBadgeCount];
    if (completionHandler != nil) {
        [self.syncMOC.dispatchGroup notifyOnQueue:dispatch_get_main_queue() block:^{
            ZMLogPushKit(@"Calling CompletionHandler");
            completionHandler(result);
        }];
    }
}

- (EventsWithIdentifier *)eventsFromPushChannelData:(NSDictionary *)userInfo
{
    NSDictionary *userInfoData = [userInfo optionalDictionaryForKey:PushChannelDataKey];
    if (userInfoData == nil) {
        return nil;
    }
    
    NSArray <ZMUpdateEvent *>* events;
    NSUUID *identifier;
    
    id internalData = userInfoData[PushChannelDataKey];
    NSString *type = [userInfoData optionalStringForKey:PushChannelNotificationTypeKey];
    
    if (![internalData isKindOfClass:[NSDictionary class]]) {
        if (![internalData isKindOfClass:[NSString class]]) {
            events = [ZMUpdateEvent eventsArrayFromTransportData:userInfoData source:ZMUpdateEventSourcePushNotification];
            identifier = [userInfoData optionalUuidForKey:PushChannelIdentifierKey];
            return [[EventsWithIdentifier alloc] initWithEvents:events identifier:identifier];
        }

        if (![type isEqualToString:PushNotificationTypeCipher]) {
            ZMLogDebug(@"Unknown payload type: %@", type);
            return nil;
        }
        
        return [self eventArrayFromEncryptedMessage:userInfoData];
    }
    
    if (! [type isEqualToString:PushNotificationTypeNotice]) {
        events = [ZMUpdateEvent eventsArrayFromTransportData:internalData source:ZMUpdateEventSourcePushNotification];
    }

    identifier = [internalData optionalUuidForKey:PushChannelIdentifierKey];
    return [[EventsWithIdentifier alloc] initWithEvents:events identifier:identifier];;
}

- (EventsWithIdentifier *)eventArrayFromEncryptedMessage:(NSDictionary *)encryptedPayload
{
    VerifyStringReturnNil(self.apsSignalKeyStore != nil, "Could not initiate APSSignalingKeystore from Keychain");
    VerifyStringReturnNil(self.cryptoBox != nil, "Could not instantiate Cryptobox");
    
    //    @"aps" : @{ @"alert": @{@"loc-args": @[],
    //                          @"loc-key"   : @"push.notification.new_message"}
    //              },
    //    @"data": @{ @"data" : @"SomeEncryptedBase64EncodedString",
    //                @"mac"  : @"someMacHashToVerifyTheIntegrityOfTheEncodedPayload",
    //                @"type" : @"cipher"
    //              }
    
    NSDictionary *decodedData = [self.apsSignalKeyStore decryptDataDictionary:encryptedPayload];
    NSDictionary *dataPayload = [decodedData optionalDictionaryForKey:PushChannelDataKey];
    NSUUID *identifier = [dataPayload optionalUuidForKey:PushChannelIdentifierKey];
    NSArray *events = [ZMUpdateEvent eventsArrayFromTransportData:dataPayload source:ZMUpdateEventSourcePushNotification];
    
    NSArray *decryptedEvents = [events mapWithBlock:^id(ZMUpdateEvent *event) {
        return [self.cryptoBox decryptUpdateEventAndAddClient:event managedObjectContext:self.syncMOC];
    }];
    
    if(decryptedEvents.count == 0) {
        return nil;
    }
    
    return [[EventsWithIdentifier alloc] initWithEvents:decryptedEvents identifier:identifier];
}

- (void)startBackgroundFetchWithCompletionHandler:(ZMBackgroundFetchHandler)handler;
{
    [self.syncMOC performGroupedBlock:^(){
        [self.syncStrategy startBackgroundFetchWithCompletionHandler:handler];
    }];
}

- (void)startBackgroundTaskWithCompletionHandler:(ZMBackgroundTaskHandler)handler;
{
    [self.syncMOC performGroupedBlock:^(){
        [self.syncStrategy startBackgroundTaskWithCompletionHandler:handler];
    }];
}


@end
