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


#import "ZMGenericMessage+UpdateEvent.h"
#import "ZMGenericMessage+External.h"
#import "ZMGenericMessage+Utils.h"
#import "WireDataModel/WireDataModel-Swift.h"

@implementation ZMGenericMessage (UpdateEvent)

+ (ZMGenericMessage *)genericMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
{
    ZMGenericMessage *message;
    
    switch (updateEvent.type) {
        case ZMUpdateEventTypeConversationClientMessageAdd: {
            NSString *base64Content = [updateEvent.payload stringForKey:@"data"];
            message = [self genericMessageWithBase64String:base64Content updateEvent:updateEvent];
        }
            break;
        case ZMUpdateEventTypeConversationOtrMessageAdd: {
            NSString *base64Content = [[updateEvent.payload dictionaryForKey:@"data"] stringForKey:@"text"];
            message = [self genericMessageWithBase64String:base64Content updateEvent:updateEvent];
        }
            break;
            
        case ZMUpdateEventTypeConversationOtrAssetAdd: {
            NSString *base64Content = [[updateEvent.payload dictionaryForKey:@"data"] stringForKey:@"info"];
            VerifyReturnNil(base64Content != nil);
            @try {
                message = [ZMGenericMessage messageWithBase64String:base64Content];
            }
            @catch(NSException *e) {
                message = nil;
            }
        }
            break;
            
        default:
            break;
    }

    if (message.hasExternal) {
        return [self genericMessageFromUpdateEventWithExternal:updateEvent external:message.external];
    }
    
    return message;
}

+ (ZMGenericMessage *)genericMessageWithBase64String:(NSString *)string updateEvent:(ZMUpdateEvent *)event
{
    VerifyReturnNil(nil != string);
    ZMGenericMessage *message;
    @try {
        message = [ZMGenericMessage messageWithBase64String:string];
    } @catch (NSException *exception) {
        ZMLogError(@"Cannot create message from protobuffer: %@ event: %@", exception, event);
        return nil;
    }
    return message;
}

+ (Class)entityClassForGenericMessage:(ZMGenericMessage *)genericMessage
{
    if (genericMessage.imageAssetData != nil || genericMessage.assetData != nil) {
        return [ZMAssetClientMessage class];
    }
    
    return ZMClientMessage.class;
}

+ (Class)entityClassForPlainMessageForGenericMessage:(ZMGenericMessage *)genericMessage
{
    if (genericMessage.hasText) {
        return ZMTextMessage.class;
    }
    
    if (genericMessage.hasImage) {
        return ZMImageMessage.class;
    }
    
    if (genericMessage.hasKnock) {
        return ZMKnockMessage.class;
    }
    
    return nil;
}


@end
