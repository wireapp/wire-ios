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


@import zimages;
@import ZMTransport;
@import ZMCDataModel;

#import "ZMAssetRequestFactory.h"

@implementation ZMAssetRequestFactory


+ (ZMTransportRequest *)requestForImageOwner:(id<ZMImageOwner>)imageOwner
                                      format:(ZMImageFormat)format
                              conversationID:(NSUUID *)conversationID
                               correlationID:(NSUUID *)correlationID
                               resultHandler:(ZMCompletionHandler *)completionHandler;
{
    NSString * const path = @"/assets";
    NSData * const imageData = [imageOwner imageDataForFormat:format];
    if (imageData == nil) {
        return nil;
    }
    
    NSDictionary * const disposition = [self contentDispositionForImageOwner:imageOwner
                                                                      format:format
                                                              conversationID:conversationID
                                                               correlationID:correlationID];
    
    ZMTransportRequest *request = [ZMTransportRequest postRequestWithPath:path
                                                                imageData:imageData
                                                       contentDisposition:disposition];
    if (completionHandler) {
        [request addCompletionHandler:completionHandler];
    }
    return request;
}


+ (NSDictionary *)contentDispositionForImageOwner:(id<ZMImageOwner>)imageOwner
                                           format:(ZMImageFormat)imageFormat
                                   conversationID:(NSUUID *)conversationID
                                    correlationID:(NSUUID *)correlationID
{
    return [ZMAssetMetaDataEncoder contentDispositionForImageOwner:imageOwner
                                                            format:imageFormat
                                                    conversationID:conversationID
                                                     correlationID:correlationID];
}

@end
