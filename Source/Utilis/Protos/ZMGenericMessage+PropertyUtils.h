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


@import ZMProtos;


@interface ZMText (Utils)

+ (instancetype)textWithMessage:(NSString *)message linkPreview:(ZMLinkPreview *)linkPreview;

@end


@interface ZMLastRead (Utils)

+ (ZMLastRead *)lastReadWithTimestamp:(NSDate *)timeStamp
                  conversationRemoteIDString:(NSString *)conversationIDString;

@end



@interface ZMCleared (Utils)

+ (instancetype)clearedWithTimestamp:(NSDate *)timeStamp
          conversationRemoteIDString:(NSString *)conversationIDString;

@end




@interface ZMMessageHide (Utils)

+ (instancetype)messageHideWithMessageID:(NSString *)messageID
                          conversationID:(NSString *)conversationID;

@end




@interface ZMMessageDelete (Utils)

+ (instancetype)messageDeleteWithMessageID:(NSString *)messageID;

@end




@interface ZMMessageEdit (Utils)

+ (instancetype)messageEditWithMessageID:(NSString *)messageID newText:(NSString *)newText linkPreview:(ZMLinkPreview*)linkPreview;

@end


@interface ZMReaction (Utils)

+ (instancetype)reactionWithEmoji:(NSString *)emoji messageID:(NSString *)messageID;

@end

@interface ZMConfirmation (Utils)

+ (instancetype)messageWithMessageID:(NSString *)messageID confirmationType:(ZMConfirmationType)confirmationType;

@end

