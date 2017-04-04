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


@import WireTransport;
@import WireTesting;
@import WireProtos;
#import "MockTransportSession+assets.h"
#import "MockTransportSession+OTR.h"
#import "MockAsset.h"
#import <WireMockTransport/WireMockTransport-Swift.h>



@implementation MockTransportSession (Assets)

/// Handles /assets
- (ZMTransportResponse *)processAssetRequest:(ZMTransportRequest *)request;
{
    if([request matchesWithPath:@"/conversations/*/assets/*" method:ZMMethodGET]) {
        return [self processAssetGetRequestInConversation:[request RESTComponentAtIndex:1] asset:[request RESTComponentAtIndex:3]];
    }
    else if([request matchesWithPath:@"/assets/v3/*" method:ZMMethodGET]) {
        return [self processAssetGetRequestInConversation:request.queryParameters[@"conv_id"] asset:[request RESTComponentAtIndex:2]];
    }
    else if([request matchesWithPath:@"/assets/*" method:ZMMethodGET]) {
        return [self processAssetGetRequestInConversation:request.queryParameters[@"conv_id"] asset:[request RESTComponentAtIndex:1]];
    }
    else if ([request matchesWithPath:@"/conversations/*/assets" method:ZMMethodPOST]) {
        return [self processAssetUploadRequestInConversation:[request RESTComponentAtIndex:1] multipartData:request.multipartBodyItemsFromRequestOrFile];
    }
    else if ([request matchesWithPath:@"/assets/v3" method:ZMMethodPOST]) {
        return [self processAssetUploadRequestFromDisposition:request];
    }
    else if ([request matchesWithPath:@"/assets" method:ZMMethodPOST]) {
        return [self processAssetUploadRequestFromDisposition:request];
    }
    else if ([request matchesWithPath:@"/conversations/*/assets" method:ZMMethodPOST]) {
        return [self processAssetUploadRequestFromDisposition:request];
    }
    else if ([request matchesWithPath:@"/conversations/*/otr/assets/*" method:ZMMethodGET]) {
        return [self processAssetGetRequestInConversation:[request RESTComponentAtIndex:1] asset:[request RESTComponentAtIndex:4]];
    }
    else if ([request matchesWithPath:@"/conversations/*/otr/assets" method:ZMMethodPOST]) {
        return [self processAddOTRAssetToConversation:[request RESTComponentAtIndex:1]
                                         mutipartBody:request.multipartBodyItemsFromRequestOrFile
                                              assetId:nil
                ];
    }
    else if ([request matchesWithPath:@"/conversations/*/otr/assets/*" method:ZMMethodPOST]) { // reupload
        return [self processAddOTRAssetToConversation:[request RESTComponentAtIndex:1]
                                         mutipartBody:request.multipartBodyItemsFromRequestOrFile
                                              assetId:[request RESTComponentAtIndex:4]
                ];
    }
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
}

- (ZMTransportResponse *)sampleImageResponse {
    NSData *data =  [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:@"medium"withExtension:@"jpg"]];
    return [[ZMTransportResponse alloc ] initWithImageData:data HTTPStatus:200 transportSessionError:nil headers:nil];
}

- (ZMTransportResponse *)processAssetUploadRequestInConversation:(NSString *)conversationID multipartData:(NSArray *)multipartData
{
    if (multipartData.count == 2) {
        ZMMultipartBodyItem *metaDataItem = multipartData.firstObject;
        ZMMultipartBodyItem *imageDataItem = multipartData.lastObject;
        
        NSError *error;
        NSDictionary *disposition = [NSJSONSerialization JSONObjectWithData:metaDataItem.data options:0 error:&error];
        if (error) {
            return [ZMTransportResponse responseWithPayload:@{@"error":@"no-disposition"} HTTPStatus:400 transportSessionError:nil];
        }
        
        return [self processAssetUploadRequestInConversation:conversationID imageData:imageDataItem.data disposition:disposition mimeType:imageDataItem.contentType];

    }
    else {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
}

- (ZMTransportResponse *)processAssetUploadRequestFromDisposition:(ZMTransportRequest *)request {

    NSDictionary *disposition = request.contentDisposition;
    NSString *conversationID = disposition[@"conv_id"];
    return [self processAssetUploadRequestInConversation:conversationID imageData:request.binaryData disposition:disposition mimeType:request.binaryDataTypeAsMIME];
}

- (ZMTransportResponse *)processAssetUploadRequestInConversation:(NSString *)conversationID imageData:(NSData *)imageData disposition:(NSDictionary *)disposition mimeType:(NSString *)mimeType {
    
    BOOL inlineData = [disposition[@"inline"] boolValue];
    MockConversation *conversation = [self fetchConversationWithIdentifier:conversationID];
    if (conversation == nil) {
        return [ZMTransportResponse responseWithPayload:@{@"error":@"not found"} HTTPStatus:404 transportSessionError:nil];
    }
    
    MockEvent *event = [conversation insertAssetUploadEventForUser:self.selfUser data:imageData disposition:disposition dataTypeAsMIME:mimeType assetID:[NSUUID createUUID].transportString];
    
    if(!inlineData) {
        [self createAssetWithData:imageData identifier:event.data[@"id"] contentType:mimeType forConversation:conversation.identifier];
    }
    
    return [ZMTransportResponse responseWithPayload:event.transportData HTTPStatus:201 transportSessionError:nil];
}

- (ZMTransportResponse *)processAssetGetRequestInConversation:(NSString *)conversationID asset:(NSString *)identifier
{
    MockAsset *asset = [MockAsset assetInContext:self.managedObjectContext forID:identifier];
    if([asset.conversation isEqualToString:conversationID]) {
        return [[ZMTransportResponse alloc ] initWithImageData:asset.data HTTPStatus:200 transportSessionError:nil headers:nil];
    }
    else {
        return [ZMTransportResponse responseWithPayload:@{@"error":@"mismatching conversation"} HTTPStatus:404 transportSessionError:nil];
    }
        
    return [ZMTransportResponse responseWithPayload:@{@"error":@"not found"} HTTPStatus:404 transportSessionError:nil];
}

// POST /conversations/<id>/otr/assets
- (ZMTransportResponse *)processAddOTRAssetToConversation:(NSString *)conversationId
                                             mutipartBody:(NSArray *)bodyItems
                                                  assetId:(NSString *)assetId
{
    BOOL containsAsset = assetId == nil;
    if (((bodyItems.count != 2 && containsAsset) || (bodyItems.count != 1 && !containsAsset))) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    ZMMultipartBodyItem *metaDataItem = bodyItems.firstObject;
    
    MockConversation *conversation = [self fetchConversationWithIdentifier:conversationId];
    NSAssert(conversation, @"No conv found");
    
    NSAssert(self.selfUser != nil, @"No self user in mock transport session");

    NSError *error;
    ZMOtrAssetMeta *otrMetadata;
    
    NSDictionary *payload = [NSJSONSerialization JSONObjectWithData:metaDataItem.data options:0 error:&error];
    if (error) {
        otrMetadata = (ZMOtrAssetMeta *)[[[ZMOtrAssetMeta builder] mergeFromData:metaDataItem.data] build];
        if (otrMetadata == nil) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
        }
        else {
            return [self responseForAddOTRAssetWithProtobufData:otrMetadata
                                                        assetId:assetId
                                                   conversation:conversation
                                                  containsAsset:containsAsset
                                                      bodyItems:bodyItems];
        }
    }
    else {
        return [self responseForAddOTRAssetWithJSONPayload:payload
                                                   assetId:assetId
                                              conversation:conversation
                                             containsAsset:containsAsset
                                                 bodyItems:bodyItems];
    }
}

- (ZMTransportResponse *)responseForAddOTRAssetWithJSONPayload:(NSDictionary *)payload
                                                       assetId:(NSString *)assetId
                                                  conversation:(MockConversation *)conversation
                                                 containsAsset:(BOOL)containsAsset
                                                     bodyItems:(NSArray *)bodyItems
{
    MockUserClient *senderClient = [self otrMessageSender:payload];
    if (senderClient == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    NSDictionary *recipients = payload[@"recipients"];
    
    NSDictionary *missedClients = [self missedClients:recipients conversation:conversation sender:senderClient onlyForUserId:nil];
    NSDictionary * redundantClients = [self redundantClients:recipients conversation:conversation];
    
    BOOL inlineData = [payload[@"inline"] boolValue];
    
    NSDictionary *responsePayload = @{@"missing": missedClients, @"redundant": redundantClients, @"time": [NSDate date].transportString};
    
    NSUUID *assetID = containsAsset ? [NSUUID createUUID] : [NSUUID uuidWithTransportString:assetId];
    NSDictionary *headers;
    
    NSInteger statusCode = 412;
    if (missedClients.count == 0) {
        statusCode = 201;
        headers = @{@"Location": assetID.transportString};
        
        NSData *imageData = payload[@"data"] ? [[NSData alloc] initWithBase64EncodedString:payload[@"data"] options:0]: nil;
        
        [self insertOTRMessageEventsToConversation:conversation requestPayload:payload createEventBlock:^MockEvent *(MockUserClient *recipient, NSData *messageData) {
            return [conversation insertOTRAssetFromClient:senderClient
                                                 toClient:recipient
                                                 metaData:messageData
                                                imageData:imageData
                                                  assetId:assetID
                                                 isInline:inlineData];
        }];
    }
    
    if (!inlineData && containsAsset) {
        
        ZMMultipartBodyItem *imageDataItem = bodyItems.lastObject;
        NSData *imageData = imageDataItem.data;
        NSString *mimeType = imageDataItem.contentType;
        
        [self createAssetWithData:imageData identifier:assetID.transportString contentType:mimeType forConversation:conversation.identifier];
    }
    
    return [[ZMTransportResponse alloc] initWithPayload:responsePayload HTTPStatus:statusCode transportSessionError:nil headers:headers];
}

- (ZMTransportResponse *)responseForAddOTRAssetWithProtobufData:(ZMOtrAssetMeta *)otrMetadata
                                                        assetId:(NSString *)assetId
                                                   conversation:(MockConversation *)conversation
                                                  containsAsset:(BOOL)containsAsset
                                                      bodyItems:(NSArray *)bodyItems
{
    MockUserClient *senderClient = [self otrMessageSenderFromClientId:otrMetadata.sender];
    if (senderClient == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    NSDictionary *missedClients = [self missedClientsFromRecipients:otrMetadata.recipients conversation:conversation sender:senderClient onlyForUserId:nil];
    NSDictionary *redundantClients = [self redundantClientsFromRecipients:otrMetadata.recipients conversation:conversation];
    
    BOOL inlineData = otrMetadata.isInline;
    
    NSDictionary *responsePayload = @{@"missing": missedClients, @"redundant": redundantClients, @"time": [NSDate date].transportString};
    
    NSUUID *assetID = containsAsset ? [NSUUID createUUID] : [NSUUID uuidWithTransportString:assetId];
    NSDictionary *headers;
    
    NSInteger statusCode = 412;
    if (missedClients.count == 0) {
        statusCode = 201;
        headers = @{@"Location": assetID.transportString};
        
        ZMMultipartBodyItem *imageDataItem = bodyItems.lastObject;
        NSData *imageData = imageDataItem.data;
        
        [self insertOTRMessageEventsToConversation:conversation
                                 requestRecipients:otrMetadata.recipients
                                      senderClient:senderClient
                                  createEventBlock:^MockEvent *(MockUserClient *recipient, NSData *messageData, NSData *decrypted) {
                                      MockEvent *event = [conversation insertOTRAssetFromClient:senderClient
                                                                                       toClient:recipient
                                                                                       metaData:messageData
                                                                                      imageData:imageData
                                                                                        assetId:assetID
                                                                                       isInline:inlineData];
                                      event.decryptedOTRData = decrypted;
                                      return event;
        }];
    }
    
    if (!inlineData && containsAsset) {
        
        ZMMultipartBodyItem *imageDataItem = bodyItems.lastObject;
        NSData *imageData = imageDataItem.data;
        NSString *mimeType = imageDataItem.contentType;
        
        [self createAssetWithData:imageData identifier:assetID.transportString contentType:mimeType forConversation:conversation.identifier];
    }
    
    return [[ZMTransportResponse alloc] initWithPayload:responsePayload HTTPStatus:statusCode transportSessionError:nil headers:headers];
}


#pragma mark - Asset v3

- (ZMTransportResponse *)processAssetV3Request:(ZMTransportRequest *)request
{
    if ([request matchesWithPath:@"/assets/v3" method:ZMMethodPOST]) {
        return [self processAssetV3PostWithMultipartData:[request multipartBodyItemsFromRequestOrFile]];
    } else if ([request matchesWithPath:@"/assets/v3/*" method:ZMMethodGET]) {
        return [self processAssetV3GetWithKey:[request RESTComponentAtIndex:2]];
    }
    return nil;
}

- (ZMTransportResponse *)processAssetV3PostWithMultipartData:(NSArray *)multipart;
{    
    if (multipart.count == 2) {
        
        ZMMultipartBodyItem *jsonObject = [multipart firstObject];
        ZMMultipartBodyItem *imageData  = [multipart lastObject];
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonObject.data options:NSJSONReadingAllowFragments error:nil];
        BOOL isPublic = [json[@"public"] boolValue];
        
        NSData *data        = imageData.data;
        NSString *mimeType  = imageData.contentType;
        
        MockAsset *asset = [MockAsset insertIntoManagedObjectContext:self.managedObjectContext];
        asset.data = data;
        asset.contentType = mimeType;
        asset.identifier = [NSUUID createUUID].transportString;
        if (!isPublic) {
            asset.token = [NSUUID createUUID].transportString;
        }
        
        NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:@{@"key" : asset.identifier, @"expires" : [[NSDate date] dateByAddingTimeInterval:1000000].transportString}];
        if (asset.token) {
            payload[@"token"] = asset.token;
        }
        
        return [[ZMTransportResponse alloc] initWithPayload:[payload copy] HTTPStatus:201 transportSessionError:nil headers:@{@"Location" : [NSString stringWithFormat:@"/asset/v3/%@", asset.identifier]}];
    }
    
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil];
}

- (ZMTransportResponse *)processAssetV3GetWithKey:(NSString *)key;
{
    MockAsset *asset = [MockAsset assetInContext:self.managedObjectContext forID:key];
    if (asset != nil) {
        
        return [[ZMTransportResponse alloc] initWithImageData:asset.data HTTPStatus:200 transportSessionError:nil headers:nil];
    }
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
}


@end
