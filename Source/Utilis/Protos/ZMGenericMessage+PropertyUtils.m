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


#import "ZMGenericMessage+PropertyUtils.h"



@implementation ZMText (Utils)

+ (instancetype)textWithMessage:(NSString *)message linkPreview:(ZMLinkPreview *)linkPreview;
{
    ZMTextBuilder *textBuilder = [ZMText builder];
    textBuilder.content = message;
    if (linkPreview != nil) {
        [textBuilder addLinkPreview:linkPreview];
    }
    return [textBuilder build];
}

@end


@implementation ZMLastRead (Utils)

+ (instancetype)lastReadWithTimestamp:(NSDate *)timeStamp conversationRemoteIDString:(NSString *)conversationIDString;
{
    ZMLastReadBuilder *builder = [ZMLastRead builder];
    builder.conversationId = conversationIDString;
    builder.lastReadTimestamp = (long long) ([timeStamp timeIntervalSince1970] * 1000); // timestamps are stored in milliseconds
    return [builder build];
}

@end




@implementation ZMCleared (Utils)

+ (instancetype)clearedWithTimestamp:(NSDate *)timeStamp conversationRemoteIDString:(NSString *)conversationIDString;
{
    ZMClearedBuilder *builder = [ZMCleared builder];
    builder.conversationId = conversationIDString;
    builder.clearedTimestamp = (long long) ([timeStamp timeIntervalSince1970] * 1000); // timestamps are stored in milliseconds
    return [builder build];
}

@end

@implementation ZMMessageHide (Utils)

+ (instancetype)messageHideWithMessageID:(NSString *)messageID
                          conversationID:(NSString *)conversationID;
{
    ZMMessageHideBuilder *builder = [ZMMessageHide builder];
    builder.conversationId = conversationID;
    builder.messageId = messageID;
    return [builder build];
}

@end

@implementation ZMMessageDelete (Utils)

+ (instancetype)messageDeleteWithMessageID:(NSString *)messageID;
{
    ZMMessageDeleteBuilder *builder = [ZMMessageDelete builder];
    builder.messageId = messageID;
    return [builder build];
}

@end


@implementation ZMMessageEdit (Utils)

+ (instancetype)messageEditWithMessageID:(NSString *)messageID newText:(NSString *)newText linkPreview:(ZMLinkPreview*)linkPreview;
{
    ZMMessageEditBuilder *builder = [ZMMessageEdit builder];
    builder.replacingMessageId = messageID;
    builder.text = [ZMText textWithMessage:newText linkPreview:linkPreview];
    return [builder build];
}

@end

@implementation ZMReaction (Utils)

+ (instancetype)reactionWithEmoji:(NSString *)emoji messageID:(NSString *)messageID;
{
    ZMReactionBuilder *builder = [ZMReaction builder];
    builder.emoji = emoji;
    builder.messageId = messageID;
    return [builder build];
}


@end

@implementation ZMConfirmation (Utils)

+ (instancetype)messageWithMessageID:(NSString *)messageID confirmationType:(ZMConfirmationType)confirmationType;
{
    ZMConfirmationBuilder *builder = [ZMConfirmation builder];
    builder.messageId = messageID;
    builder.type = confirmationType;
    return [builder build];
}

@end
