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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


#import <ProtocolBuffers/ProtocolBuffers.h>

// @@protoc_insertion_point(imports)

@class DescriptorProto;
@class DescriptorProtoBuilder;
@class DescriptorProtoExtensionRange;
@class DescriptorProtoExtensionRangeBuilder;
@class EnumDescriptorProto;
@class EnumDescriptorProtoBuilder;
@class EnumOptions;
@class EnumOptionsBuilder;
@class EnumValueDescriptorProto;
@class EnumValueDescriptorProtoBuilder;
@class EnumValueOptions;
@class EnumValueOptionsBuilder;
@class FieldDescriptorProto;
@class FieldDescriptorProtoBuilder;
@class FieldOptions;
@class FieldOptionsBuilder;
@class FileDescriptorProto;
@class FileDescriptorProtoBuilder;
@class FileDescriptorSet;
@class FileDescriptorSetBuilder;
@class FileOptions;
@class FileOptionsBuilder;
@class MessageOptions;
@class MessageOptionsBuilder;
@class MethodDescriptorProto;
@class MethodDescriptorProtoBuilder;
@class MethodOptions;
@class MethodOptionsBuilder;
@class ObjectiveCFileOptions;
@class ObjectiveCFileOptionsBuilder;
@class OneofDescriptorProto;
@class OneofDescriptorProtoBuilder;
@class ServiceDescriptorProto;
@class ServiceDescriptorProtoBuilder;
@class ServiceOptions;
@class ServiceOptionsBuilder;
@class SourceCodeInfo;
@class SourceCodeInfoBuilder;
@class SourceCodeInfoLocation;
@class SourceCodeInfoLocationBuilder;
@class UninterpretedOption;
@class UninterpretedOptionBuilder;
@class UninterpretedOptionNamePart;
@class UninterpretedOptionNamePartBuilder;
@class ZMCleared;
@class ZMClearedBuilder;
@class ZMExternal;
@class ZMExternalBuilder;
@class ZMGenericMessage;
@class ZMGenericMessageBuilder;
@class ZMImageAsset;
@class ZMImageAssetBuilder;
@class ZMKnock;
@class ZMKnockBuilder;
@class ZMLastRead;
@class ZMLastReadBuilder;
@class ZMMention;
@class ZMMentionBuilder;
@class ZMText;
@class ZMTextBuilder;


typedef NS_ENUM(SInt32, ZMLikeAction) {
  ZMLikeActionLIKE = 0,
  ZMLikeActionUNLIKE = 1,
};

BOOL ZMLikeActionIsValidValue(ZMLikeAction value);
NSString *NSStringFromZMLikeAction(ZMLikeAction value);

typedef NS_ENUM(SInt32, ZMClientAction) {
  ZMClientActionRESETSESSION = 0,
};

BOOL ZMClientActionIsValidValue(ZMClientAction value);
NSString *NSStringFromZMClientAction(ZMClientAction value);


@interface ZMMessagesRoot : NSObject {
}
+ (PBExtensionRegistry*) extensionRegistry;
+ (void) registerAllExtensions:(PBMutableExtensionRegistry*) registry;
@end

#define GenericMessage_message_id @"messageId"
#define GenericMessage_text @"text"
#define GenericMessage_image @"image"
#define GenericMessage_knock @"knock"
#define GenericMessage_liking @"liking"
#define GenericMessage_lastRead @"lastRead"
#define GenericMessage_cleared @"cleared"
#define GenericMessage_external @"external"
#define GenericMessage_clientAction @"clientAction"
@interface ZMGenericMessage : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasMessageId_:1;
  BOOL hasText_:1;
  BOOL hasImage_:1;
  BOOL hasKnock_:1;
  BOOL hasLastRead_:1;
  BOOL hasCleared_:1;
  BOOL hasExternal_:1;
  BOOL hasLiking_:1;
  BOOL hasClientAction_:1;
  NSString* messageId;
  ZMText* text;
  ZMImageAsset* image;
  ZMKnock* knock;
  ZMLastRead* lastRead;
  ZMCleared* cleared;
  ZMExternal* external;
  ZMLikeAction liking;
  ZMClientAction clientAction;
}
- (BOOL) hasMessageId;
- (BOOL) hasText;
- (BOOL) hasImage;
- (BOOL) hasKnock;
- (BOOL) hasLiking;
- (BOOL) hasLastRead;
- (BOOL) hasCleared;
- (BOOL) hasExternal;
- (BOOL) hasClientAction;
@property (readonly, strong) NSString* messageId;
@property (readonly, strong) ZMText* text;
@property (readonly, strong) ZMImageAsset* image;
@property (readonly, strong) ZMKnock* knock;
@property (readonly) ZMLikeAction liking;
@property (readonly, strong) ZMLastRead* lastRead;
@property (readonly, strong) ZMCleared* cleared;
@property (readonly, strong) ZMExternal* external;
@property (readonly) ZMClientAction clientAction;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMGenericMessageBuilder*) builder;
+ (ZMGenericMessageBuilder*) builder;
+ (ZMGenericMessageBuilder*) builderWithPrototype:(ZMGenericMessage*) prototype;
- (ZMGenericMessageBuilder*) toBuilder;

+ (ZMGenericMessage*) parseFromData:(NSData*) data;
+ (ZMGenericMessage*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMGenericMessage*) parseFromInputStream:(NSInputStream*) input;
+ (ZMGenericMessage*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMGenericMessage*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMGenericMessage*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMGenericMessageBuilder : PBGeneratedMessageBuilder {
@private
  ZMGenericMessage* resultGenericMessage;
}

- (ZMGenericMessage*) defaultInstance;

- (ZMGenericMessageBuilder*) clear;
- (ZMGenericMessageBuilder*) clone;

- (ZMGenericMessage*) build;
- (ZMGenericMessage*) buildPartial;

- (ZMGenericMessageBuilder*) mergeFrom:(ZMGenericMessage*) other;
- (ZMGenericMessageBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMGenericMessageBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasMessageId;
- (NSString*) messageId;
- (ZMGenericMessageBuilder*) setMessageId:(NSString*) value;
- (ZMGenericMessageBuilder*) clearMessageId;

- (BOOL) hasText;
- (ZMText*) text;
- (ZMGenericMessageBuilder*) setText:(ZMText*) value;
- (ZMGenericMessageBuilder*) setTextBuilder:(ZMTextBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeText:(ZMText*) value;
- (ZMGenericMessageBuilder*) clearText;

- (BOOL) hasImage;
- (ZMImageAsset*) image;
- (ZMGenericMessageBuilder*) setImage:(ZMImageAsset*) value;
- (ZMGenericMessageBuilder*) setImageBuilder:(ZMImageAssetBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeImage:(ZMImageAsset*) value;
- (ZMGenericMessageBuilder*) clearImage;

- (BOOL) hasKnock;
- (ZMKnock*) knock;
- (ZMGenericMessageBuilder*) setKnock:(ZMKnock*) value;
- (ZMGenericMessageBuilder*) setKnockBuilder:(ZMKnockBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeKnock:(ZMKnock*) value;
- (ZMGenericMessageBuilder*) clearKnock;

- (BOOL) hasLiking;
- (ZMLikeAction) liking;
- (ZMGenericMessageBuilder*) setLiking:(ZMLikeAction) value;
- (ZMGenericMessageBuilder*) clearLiking;

- (BOOL) hasLastRead;
- (ZMLastRead*) lastRead;
- (ZMGenericMessageBuilder*) setLastRead:(ZMLastRead*) value;
- (ZMGenericMessageBuilder*) setLastReadBuilder:(ZMLastReadBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeLastRead:(ZMLastRead*) value;
- (ZMGenericMessageBuilder*) clearLastRead;

- (BOOL) hasCleared;
- (ZMCleared*) cleared;
- (ZMGenericMessageBuilder*) setCleared:(ZMCleared*) value;
- (ZMGenericMessageBuilder*) setClearedBuilder:(ZMClearedBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeCleared:(ZMCleared*) value;
- (ZMGenericMessageBuilder*) clearCleared;

- (BOOL) hasExternal;
- (ZMExternal*) external;
- (ZMGenericMessageBuilder*) setExternal:(ZMExternal*) value;
- (ZMGenericMessageBuilder*) setExternalBuilder:(ZMExternalBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeExternal:(ZMExternal*) value;
- (ZMGenericMessageBuilder*) clearExternal;

- (BOOL) hasClientAction;
- (ZMClientAction) clientAction;
- (ZMGenericMessageBuilder*) setClientAction:(ZMClientAction) value;
- (ZMGenericMessageBuilder*) clearClientAction;
@end

#define Text_content @"content"
#define Text_mention @"mention"
@interface ZMText : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasContent_:1;
  NSString* content;
  NSMutableArray * mentionArray;
}
- (BOOL) hasContent;
@property (readonly, strong) NSString* content;
@property (readonly, strong) NSArray * mention;
- (ZMMention*)mentionAtIndex:(NSUInteger)index;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMTextBuilder*) builder;
+ (ZMTextBuilder*) builder;
+ (ZMTextBuilder*) builderWithPrototype:(ZMText*) prototype;
- (ZMTextBuilder*) toBuilder;

+ (ZMText*) parseFromData:(NSData*) data;
+ (ZMText*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMText*) parseFromInputStream:(NSInputStream*) input;
+ (ZMText*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMText*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMText*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMTextBuilder : PBGeneratedMessageBuilder {
@private
  ZMText* resultText;
}

- (ZMText*) defaultInstance;

- (ZMTextBuilder*) clear;
- (ZMTextBuilder*) clone;

- (ZMText*) build;
- (ZMText*) buildPartial;

- (ZMTextBuilder*) mergeFrom:(ZMText*) other;
- (ZMTextBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMTextBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasContent;
- (NSString*) content;
- (ZMTextBuilder*) setContent:(NSString*) value;
- (ZMTextBuilder*) clearContent;

- (NSMutableArray *)mention;
- (ZMMention*)mentionAtIndex:(NSUInteger)index;
- (ZMTextBuilder *)addMention:(ZMMention*)value;
- (ZMTextBuilder *)setMentionArray:(NSArray *)array;
- (ZMTextBuilder *)clearMention;
@end

#define Knock_hot_knock @"hotKnock"
@interface ZMKnock : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasHotKnock_:1;
  BOOL hotKnock_:1;
}
- (BOOL) hasHotKnock;
- (BOOL) hotKnock;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMKnockBuilder*) builder;
+ (ZMKnockBuilder*) builder;
+ (ZMKnockBuilder*) builderWithPrototype:(ZMKnock*) prototype;
- (ZMKnockBuilder*) toBuilder;

+ (ZMKnock*) parseFromData:(NSData*) data;
+ (ZMKnock*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMKnock*) parseFromInputStream:(NSInputStream*) input;
+ (ZMKnock*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMKnock*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMKnock*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMKnockBuilder : PBGeneratedMessageBuilder {
@private
  ZMKnock* resultKnock;
}

- (ZMKnock*) defaultInstance;

- (ZMKnockBuilder*) clear;
- (ZMKnockBuilder*) clone;

- (ZMKnock*) build;
- (ZMKnock*) buildPartial;

- (ZMKnockBuilder*) mergeFrom:(ZMKnock*) other;
- (ZMKnockBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMKnockBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasHotKnock;
- (BOOL) hotKnock;
- (ZMKnockBuilder*) setHotKnock:(BOOL) value;
- (ZMKnockBuilder*) clearHotKnock;
@end

#define Mention_user_id @"userId"
#define Mention_user_name @"userName"
@interface ZMMention : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasUserId_:1;
  BOOL hasUserName_:1;
  NSString* userId;
  NSString* userName;
}
- (BOOL) hasUserId;
- (BOOL) hasUserName;
@property (readonly, strong) NSString* userId;
@property (readonly, strong) NSString* userName;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMMentionBuilder*) builder;
+ (ZMMentionBuilder*) builder;
+ (ZMMentionBuilder*) builderWithPrototype:(ZMMention*) prototype;
- (ZMMentionBuilder*) toBuilder;

+ (ZMMention*) parseFromData:(NSData*) data;
+ (ZMMention*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMMention*) parseFromInputStream:(NSInputStream*) input;
+ (ZMMention*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMMention*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMMention*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMMentionBuilder : PBGeneratedMessageBuilder {
@private
  ZMMention* resultMention;
}

- (ZMMention*) defaultInstance;

- (ZMMentionBuilder*) clear;
- (ZMMentionBuilder*) clone;

- (ZMMention*) build;
- (ZMMention*) buildPartial;

- (ZMMentionBuilder*) mergeFrom:(ZMMention*) other;
- (ZMMentionBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMMentionBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasUserId;
- (NSString*) userId;
- (ZMMentionBuilder*) setUserId:(NSString*) value;
- (ZMMentionBuilder*) clearUserId;

- (BOOL) hasUserName;
- (NSString*) userName;
- (ZMMentionBuilder*) setUserName:(NSString*) value;
- (ZMMentionBuilder*) clearUserName;
@end

#define LastRead_conversation_id @"conversationId"
#define LastRead_last_read_timestamp @"lastReadTimestamp"
@interface ZMLastRead : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasLastReadTimestamp_:1;
  BOOL hasConversationId_:1;
  SInt64 lastReadTimestamp;
  NSString* conversationId;
}
- (BOOL) hasConversationId;
- (BOOL) hasLastReadTimestamp;
@property (readonly, strong) NSString* conversationId;
@property (readonly) SInt64 lastReadTimestamp;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMLastReadBuilder*) builder;
+ (ZMLastReadBuilder*) builder;
+ (ZMLastReadBuilder*) builderWithPrototype:(ZMLastRead*) prototype;
- (ZMLastReadBuilder*) toBuilder;

+ (ZMLastRead*) parseFromData:(NSData*) data;
+ (ZMLastRead*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMLastRead*) parseFromInputStream:(NSInputStream*) input;
+ (ZMLastRead*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMLastRead*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMLastRead*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMLastReadBuilder : PBGeneratedMessageBuilder {
@private
  ZMLastRead* resultLastRead;
}

- (ZMLastRead*) defaultInstance;

- (ZMLastReadBuilder*) clear;
- (ZMLastReadBuilder*) clone;

- (ZMLastRead*) build;
- (ZMLastRead*) buildPartial;

- (ZMLastReadBuilder*) mergeFrom:(ZMLastRead*) other;
- (ZMLastReadBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMLastReadBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasConversationId;
- (NSString*) conversationId;
- (ZMLastReadBuilder*) setConversationId:(NSString*) value;
- (ZMLastReadBuilder*) clearConversationId;

- (BOOL) hasLastReadTimestamp;
- (SInt64) lastReadTimestamp;
- (ZMLastReadBuilder*) setLastReadTimestamp:(SInt64) value;
- (ZMLastReadBuilder*) clearLastReadTimestamp;
@end

#define Cleared_conversation_id @"conversationId"
#define Cleared_cleared_timestamp @"clearedTimestamp"
@interface ZMCleared : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasClearedTimestamp_:1;
  BOOL hasConversationId_:1;
  SInt64 clearedTimestamp;
  NSString* conversationId;
}
- (BOOL) hasConversationId;
- (BOOL) hasClearedTimestamp;
@property (readonly, strong) NSString* conversationId;
@property (readonly) SInt64 clearedTimestamp;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMClearedBuilder*) builder;
+ (ZMClearedBuilder*) builder;
+ (ZMClearedBuilder*) builderWithPrototype:(ZMCleared*) prototype;
- (ZMClearedBuilder*) toBuilder;

+ (ZMCleared*) parseFromData:(NSData*) data;
+ (ZMCleared*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMCleared*) parseFromInputStream:(NSInputStream*) input;
+ (ZMCleared*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMCleared*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMCleared*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMClearedBuilder : PBGeneratedMessageBuilder {
@private
  ZMCleared* resultCleared;
}

- (ZMCleared*) defaultInstance;

- (ZMClearedBuilder*) clear;
- (ZMClearedBuilder*) clone;

- (ZMCleared*) build;
- (ZMCleared*) buildPartial;

- (ZMClearedBuilder*) mergeFrom:(ZMCleared*) other;
- (ZMClearedBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMClearedBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasConversationId;
- (NSString*) conversationId;
- (ZMClearedBuilder*) setConversationId:(NSString*) value;
- (ZMClearedBuilder*) clearConversationId;

- (BOOL) hasClearedTimestamp;
- (SInt64) clearedTimestamp;
- (ZMClearedBuilder*) setClearedTimestamp:(SInt64) value;
- (ZMClearedBuilder*) clearClearedTimestamp;
@end

#define ImageAsset_tag @"tag"
#define ImageAsset_width @"width"
#define ImageAsset_height @"height"
#define ImageAsset_original_width @"originalWidth"
#define ImageAsset_original_height @"originalHeight"
#define ImageAsset_mime_type @"mimeType"
#define ImageAsset_size @"size"
#define ImageAsset_otr_key @"otrKey"
#define ImageAsset_mac_key @"macKey"
#define ImageAsset_mac @"mac"
#define ImageAsset_sha256 @"sha256"
@interface ZMImageAsset : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasWidth_:1;
  BOOL hasHeight_:1;
  BOOL hasOriginalWidth_:1;
  BOOL hasOriginalHeight_:1;
  BOOL hasSize_:1;
  BOOL hasTag_:1;
  BOOL hasMimeType_:1;
  BOOL hasOtrKey_:1;
  BOOL hasMacKey_:1;
  BOOL hasMac_:1;
  BOOL hasSha256_:1;
  SInt32 width;
  SInt32 height;
  SInt32 originalWidth;
  SInt32 originalHeight;
  SInt32 size;
  NSString* tag;
  NSString* mimeType;
  NSData* otrKey;
  NSData* macKey;
  NSData* mac;
  NSData* sha256;
}
- (BOOL) hasTag;
- (BOOL) hasWidth;
- (BOOL) hasHeight;
- (BOOL) hasOriginalWidth;
- (BOOL) hasOriginalHeight;
- (BOOL) hasMimeType;
- (BOOL) hasSize;
- (BOOL) hasOtrKey;
- (BOOL) hasMacKey;
- (BOOL) hasMac;
- (BOOL) hasSha256;
@property (readonly, strong) NSString* tag;
@property (readonly) SInt32 width;
@property (readonly) SInt32 height;
@property (readonly) SInt32 originalWidth;
@property (readonly) SInt32 originalHeight;
@property (readonly, strong) NSString* mimeType;
@property (readonly) SInt32 size;
@property (readonly, strong) NSData* otrKey;
@property (readonly, strong) NSData* macKey;
@property (readonly, strong) NSData* mac;
@property (readonly, strong) NSData* sha256;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMImageAssetBuilder*) builder;
+ (ZMImageAssetBuilder*) builder;
+ (ZMImageAssetBuilder*) builderWithPrototype:(ZMImageAsset*) prototype;
- (ZMImageAssetBuilder*) toBuilder;

+ (ZMImageAsset*) parseFromData:(NSData*) data;
+ (ZMImageAsset*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMImageAsset*) parseFromInputStream:(NSInputStream*) input;
+ (ZMImageAsset*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMImageAsset*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMImageAsset*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMImageAssetBuilder : PBGeneratedMessageBuilder {
@private
  ZMImageAsset* resultImageAsset;
}

- (ZMImageAsset*) defaultInstance;

- (ZMImageAssetBuilder*) clear;
- (ZMImageAssetBuilder*) clone;

- (ZMImageAsset*) build;
- (ZMImageAsset*) buildPartial;

- (ZMImageAssetBuilder*) mergeFrom:(ZMImageAsset*) other;
- (ZMImageAssetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMImageAssetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasTag;
- (NSString*) tag;
- (ZMImageAssetBuilder*) setTag:(NSString*) value;
- (ZMImageAssetBuilder*) clearTag;

- (BOOL) hasWidth;
- (SInt32) width;
- (ZMImageAssetBuilder*) setWidth:(SInt32) value;
- (ZMImageAssetBuilder*) clearWidth;

- (BOOL) hasHeight;
- (SInt32) height;
- (ZMImageAssetBuilder*) setHeight:(SInt32) value;
- (ZMImageAssetBuilder*) clearHeight;

- (BOOL) hasOriginalWidth;
- (SInt32) originalWidth;
- (ZMImageAssetBuilder*) setOriginalWidth:(SInt32) value;
- (ZMImageAssetBuilder*) clearOriginalWidth;

- (BOOL) hasOriginalHeight;
- (SInt32) originalHeight;
- (ZMImageAssetBuilder*) setOriginalHeight:(SInt32) value;
- (ZMImageAssetBuilder*) clearOriginalHeight;

- (BOOL) hasMimeType;
- (NSString*) mimeType;
- (ZMImageAssetBuilder*) setMimeType:(NSString*) value;
- (ZMImageAssetBuilder*) clearMimeType;

- (BOOL) hasSize;
- (SInt32) size;
- (ZMImageAssetBuilder*) setSize:(SInt32) value;
- (ZMImageAssetBuilder*) clearSize;

- (BOOL) hasOtrKey;
- (NSData*) otrKey;
- (ZMImageAssetBuilder*) setOtrKey:(NSData*) value;
- (ZMImageAssetBuilder*) clearOtrKey;

- (BOOL) hasMacKey;
- (NSData*) macKey;
- (ZMImageAssetBuilder*) setMacKey:(NSData*) value;
- (ZMImageAssetBuilder*) clearMacKey;

- (BOOL) hasMac;
- (NSData*) mac;
- (ZMImageAssetBuilder*) setMac:(NSData*) value;
- (ZMImageAssetBuilder*) clearMac;

- (BOOL) hasSha256;
- (NSData*) sha256;
- (ZMImageAssetBuilder*) setSha256:(NSData*) value;
- (ZMImageAssetBuilder*) clearSha256;
@end

#define External_otr_key @"otrKey"
#define External_sha256 @"sha256"
@interface ZMExternal : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasOtrKey_:1;
  BOOL hasSha256_:1;
  NSData* otrKey;
  NSData* sha256;
}
- (BOOL) hasOtrKey;
- (BOOL) hasSha256;
@property (readonly, strong) NSData* otrKey;
@property (readonly, strong) NSData* sha256;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMExternalBuilder*) builder;
+ (ZMExternalBuilder*) builder;
+ (ZMExternalBuilder*) builderWithPrototype:(ZMExternal*) prototype;
- (ZMExternalBuilder*) toBuilder;

+ (ZMExternal*) parseFromData:(NSData*) data;
+ (ZMExternal*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMExternal*) parseFromInputStream:(NSInputStream*) input;
+ (ZMExternal*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMExternal*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMExternal*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMExternalBuilder : PBGeneratedMessageBuilder {
@private
  ZMExternal* resultExternal;
}

- (ZMExternal*) defaultInstance;

- (ZMExternalBuilder*) clear;
- (ZMExternalBuilder*) clone;

- (ZMExternal*) build;
- (ZMExternal*) buildPartial;

- (ZMExternalBuilder*) mergeFrom:(ZMExternal*) other;
- (ZMExternalBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMExternalBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasOtrKey;
- (NSData*) otrKey;
- (ZMExternalBuilder*) setOtrKey:(NSData*) value;
- (ZMExternalBuilder*) clearOtrKey;

- (BOOL) hasSha256;
- (NSData*) sha256;
- (ZMExternalBuilder*) setSha256:(NSData*) value;
- (ZMExternalBuilder*) clearSha256;
@end


// @@protoc_insertion_point(global_scope)
