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

#import "ZMGenericMessage+PropertyUtils.h"



@implementation ZMText (Utils)

+ (instancetype)textWithMessage:(NSString *)message linkPreview:(ZMLinkPreview *)linkPreview
{
    return [self textWithMessage:message linkPreview:linkPreview mentions:@[]];
}

+ (instancetype)textWithMessage:(NSString *)message linkPreview:(ZMLinkPreview *)linkPreview mentions:(NSArray<ZMMention *> *)mentions
{
    ZMTextBuilder *textBuilder = [ZMText builder];
    textBuilder.content = message;
    if (linkPreview != nil) {
        [textBuilder addLinkPreview:linkPreview];
    }
    if (mentions != nil) {
        [textBuilder setMentionArray:mentions];
    }
    return [textBuilder build];
}

@end


@implementation ZMLastRead (Utils)

+ (instancetype)lastReadWithTimestamp:(NSDate *)timeStamp conversationRemoteID:(NSUUID *)conversationID;
{
    ZMLastReadBuilder *builder = [ZMLastRead builder];
    builder.conversationId = conversationID.transportString;
    builder.lastReadTimestamp = (long long) ([timeStamp timeIntervalSince1970] * 1000); // timestamps are stored in milliseconds
    return [builder build];
}

@end




@implementation ZMCleared (Utils)

+ (instancetype)clearedWithTimestamp:(NSDate *)timeStamp conversationRemoteID:(NSUUID *)conversationID;
{
    ZMClearedBuilder *builder = [ZMCleared builder];
    builder.conversationId = conversationID.transportString;
    builder.clearedTimestamp = (long long) ([timeStamp timeIntervalSince1970] * 1000); // timestamps are stored in milliseconds
    return [builder build];
}

@end

@implementation ZMMessageHide (Utils)

+ (instancetype)messageHideWithMessageID:(NSUUID *)messageID
                          conversationID:(NSUUID *)conversationID;
{
    ZMMessageHideBuilder *builder = [ZMMessageHide builder];
    builder.conversationId = conversationID.transportString;
    builder.messageId = messageID.transportString;
    return [builder build];
}

@end

@implementation ZMMessageDelete (Utils)

+ (instancetype)messageDeleteWithMessageID:(NSUUID *)messageID;
{
    ZMMessageDeleteBuilder *builder = [ZMMessageDelete builder];
    builder.messageId = messageID.transportString;
    return [builder build];
}

@end


@implementation ZMMessageEdit (Utils)

+ (instancetype)messageEditWithMessageID:(NSUUID *)messageID newText:(NSString *)newText linkPreview:(ZMLinkPreview*)linkPreview
{
    return [self messageEditWithMessageID:messageID newText:newText linkPreview:linkPreview mentions:@[]];
}

+ (instancetype)messageEditWithMessageID:(NSUUID *)messageID newText:(NSString *)newText linkPreview:(ZMLinkPreview*)linkPreview mentions:(NSArray<ZMMention *> *)mentions
{
    ZMMessageEditBuilder *builder = [ZMMessageEdit builder];
    builder.replacingMessageId = messageID.transportString;
    builder.text = [ZMText textWithMessage:newText linkPreview:linkPreview mentions: mentions];
    return [builder build];
}

@end

@implementation ZMReaction (Utils)

+ (instancetype)reactionWithEmoji:(NSString *)emoji messageID:(NSUUID *)messageID;
{
    ZMReactionBuilder *builder = [ZMReaction builder];
    builder.emoji = emoji;
    builder.messageId = messageID.transportString;
    return [builder build];
}


@end

@implementation ZMConfirmation (Utils)

+ (instancetype)messageWithMessageID:(NSUUID *)messageID confirmationType:(ZMConfirmationType)confirmationType;
{
    ZMConfirmationBuilder *builder = [ZMConfirmation builder];
    builder.firstMessageId = messageID.transportString;
    builder.type = confirmationType;
    return [builder build];
}

@end
