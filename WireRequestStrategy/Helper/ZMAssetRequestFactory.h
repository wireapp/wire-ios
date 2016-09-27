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


@import Foundation;
@import zimages;
@import ZMTransport;

@class ZMConversation;

@interface ZMAssetRequestFactory : NSObject


+ (ZMTransportRequest *)requestForImageOwner:(id<ZMImageOwner>)imageOwner
                                      format:(ZMImageFormat)format
                              conversationID:(NSUUID *)conversationID
                               correlationID:(NSUUID *)correlationID
                               resultHandler:(ZMCompletionHandler *)completionHandler;


@end
