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
#import "ZMManagedObject.h"

@class ZMGenericMessage;
@class ZMClientMessage;
@class ZMAssetClientMessage;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const ZMGenericMessageDataMessageKey;
extern NSString * const ZMGenericMessageDataAssetKey;

NS_ASSUME_NONNULL_END

@interface ZMGenericMessageData: ZMManagedObject

@property (nonatomic, nonnull) NSData *data;
@property (nonatomic, readonly, nullable) ZMGenericMessage *genericMessage;
@property (nonatomic, nullable) ZMClientMessage *message;
@property (nonatomic, nullable) ZMAssetClientMessage *asset;

+ (NSString * _Nonnull)entityName;

@end
