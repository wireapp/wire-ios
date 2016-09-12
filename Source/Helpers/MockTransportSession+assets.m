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


@import ZMTransport;
@import ZMTesting;
@import ZMProtos;
#import "MockTransportSession+assets.h"
#import "MockTransportSession+OTR.h"
#import "MockAsset.h"


@implementation MockTransportSession (Assets)

/// Handles /assets
- (ZMTransportResponse *)processAssetRequest:(TestTransportSessionRequest *)sessionRequest;
{
    if ((sessionRequest.method == ZMMethodGET) && ((sessionRequest.pathComponents.count == 3) || sessionRequest.pathComponents.count == 1)) {
        return [self processAssetGetRequest:sessionRequest];
    }
    else if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 2 || sessionRequest.pathComponents.count == 0)) {
        return [self processAssetUploadRequest:sessionRequest];
    }
    else if ([sessionRequest.pathComponents[1] isEqual:@"otr"]) {
        //GET /conversations/:id/otr/assets
        if (sessionRequest.method == ZMMethodGET) {
            return [self processAssetGetRequest:sessionRequest];
        }
        //POST /conversations/otr/assets
        else if (sessionRequest.method == ZMMethodPOST && sessionRequest.pathComponents.count == 3) {
            return [self processAddOTRAssetToConversationWithRequest:sessionRequest containsAsset:YES];
        }
        //POST /conversations/:id/otr/assets/:id (reupload)
        else if (sessionRequest.method == ZMMethodPOST && sessionRequest.pathComponents.count == 4) {
            return [self processAddOTRAssetToConversationWithRequest:sessionRequest containsAsset:NO];
        }
    }
    
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
}

- (ZMTransportResponse *)sampleImageResponse {
    NSData *data =  [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:self.class] URLForResource:@"medium"withExtension:@"jpg"]];
    return [[ZMTransportResponse alloc ] initWithImageData:data HTTPStatus:200 transportSessionError:nil headers:nil];
}

- (ZMTransportResponse *)processAssetUploadRequest:(TestTransportSessionRequest *)sessionRequest;
{
    NSString *conversationId;
    NSDictionary *disposition;
    NSData *imageData;
    NSString *mimeType;
    
    if (sessionRequest.pathComponents.count == 2) {
        conversationId = sessionRequest.pathComponents.firstObject;
        
        NSArray *bodyItems = [sessionRequest.embeddedRequest multipartBodyItems];
        if (bodyItems.count == 2) {
            ZMMultipartBodyItem *metaDataItem = bodyItems.firstObject;
            ZMMultipartBodyItem *imageDataItem = bodyItems.lastObject;
            
            NSError *error;
            disposition = [NSJSONSerialization JSONObjectWithData:metaDataItem.data options:0 error:&error];
            if (error) {
                return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
            }
            
            imageData = imageDataItem.data;
            mimeType = imageDataItem.contentType;
        }
        else {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
        }
    }
    else {
        disposition = sessionRequest.embeddedRequest.contentDisposition;
        imageData = sessionRequest.embeddedRequest.binaryData;
        mimeType = sessionRequest.binaryDataTypeAsMIME;
        conversationId = disposition[@"conv_id"];
    }
    
    MockConversation *conversation = [self fetchConversationWithIdentifier:conversationId];
    NSAssert(conversation, @"No conv found");
    
    BOOL const inlineData = [disposition[@"inline"] boolValue];
    MockEvent *event = [conversation insertAssetUploadEventForUser:self.selfUser data:imageData disposition:disposition dataTypeAsMIME:mimeType assetID:[NSUUID createUUID].transportString];
    
    if(!inlineData) {
        [self createAssetWithData:imageData identifier:event.data[@"id"] contentType:mimeType forConversation:conversation.identifier];
    }
    
    return [ZMTransportResponse responseWithPayload:event.transportData HTTPStatus:201 transportSessionError:nil];
}

- (ZMTransportResponse *)processAssetGetRequest:(TestTransportSessionRequest *)request
{
    NSString *identifier;
    NSString *conversationID;
    
    if (request.pathComponents.count == 3 ||
        (request.pathComponents.count == 4 && [request.pathComponents[1] isEqualToString:@"otr"])) {
        conversationID = request.pathComponents.firstObject;
        identifier = request.pathComponents.lastObject;
    }
    else {
        identifier = request.pathComponents[0];
        conversationID = request.query[@"conv_id"];
    }

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
- (ZMTransportResponse *)processAddOTRAssetToConversationWithRequest:(TestTransportSessionRequest *)sessionRequest containsAsset:(BOOL)containsAsset;
{    
    NSString *conversationId = sessionRequest.pathComponents.firstObject;
    
    NSArray *bodyItems = [sessionRequest.embeddedRequest multipartBodyItems];
    
    // We need to check if we are dealing with a fileUpload, in that case the request data is located at the fileUploadURL
    if (nil == bodyItems && nil != sessionRequest.embeddedRequest.fileUploadURL) {
        NSData *requestData = [NSData dataWithContentsOfFile:sessionRequest.embeddedRequest.fileUploadURL.path];
        bodyItems = [requestData multipartDataItemsSeparatedWithBoundary:@"frontier"];
    }
    
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
                                                        request:sessionRequest
                                                   conversation:conversation
                                                  containsAsset:containsAsset
                                                      bodyItems:bodyItems];
        }
    }
    else {
        return [self responseForAddOTRAssetWithJSONPayload:payload
                                                   request:sessionRequest
                                              conversation:conversation
                                             containsAsset:containsAsset
                                                 bodyItems:bodyItems];
    }
}

- (ZMTransportResponse *)responseForAddOTRAssetWithJSONPayload:(NSDictionary *)payload
                                                       request:(TestTransportSessionRequest *)sessionRequest
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
    
    NSUUID *assetID = containsAsset ? [NSUUID createUUID] : sessionRequest.pathComponents.lastObject;
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
                                                        request:(TestTransportSessionRequest *)sessionRequest
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
    
    NSUUID *assetID = containsAsset ? [NSUUID createUUID] : sessionRequest.pathComponents.lastObject;
    NSDictionary *headers;
    
    NSInteger statusCode = 412;
    if (missedClients.count == 0) {
        statusCode = 201;
        headers = @{@"Location": assetID.transportString};
        
        ZMMultipartBodyItem *imageDataItem = bodyItems.lastObject;
        NSData *imageData = imageDataItem.data;
        
        [self insertOTRMessageEventsToConversation:conversation requestRecipients:otrMetadata.recipients createEventBlock:^MockEvent *(MockUserClient *recipient, NSData *messageData) {
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


#pragma mark - Asset v3

- (ZMTransportResponse *)processAssetV3Request:(TestTransportSessionRequest *)sessionRequest
{
    if (sessionRequest.method == ZMMethodPOST && sessionRequest.pathComponents.count == 0) { //Post new asset
        return [self processAssetV3Post:sessionRequest];
        
        
    } else if (sessionRequest.method == ZMMethodGET && sessionRequest.pathComponents.count == 1) {
        // doesn't handle Asset-token, need access to request header
        return [self processAssetV3GetWithKey: (NSString *)sessionRequest.pathComponents[0]];
    } else if (sessionRequest.method == ZMMethodPOST && sessionRequest.pathComponents.count == 2) {
        //TODO: Implement this when actually needed
    } else if (sessionRequest.method == ZMMethodDELETE && sessionRequest.pathComponents.count == 2) {
        //TODO: Implement this when actually needed
    }
    
    return nil;
}

- (ZMTransportResponse *)processAssetV3Post:(TestTransportSessionRequest *)sessionRequest;
{
    
    NSArray *multipart = [sessionRequest.embeddedRequest multipartBodyItems];
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
