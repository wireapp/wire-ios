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
@class ZMAsset;
@class ZMAssetAudioMetaData;
@class ZMAssetAudioMetaDataBuilder;
@class ZMAssetBuilder;
@class ZMAssetImageMetaData;
@class ZMAssetImageMetaDataBuilder;
@class ZMAssetOriginal;
@class ZMAssetOriginalBuilder;
@class ZMAssetPreview;
@class ZMAssetPreviewBuilder;
@class ZMAssetRemoteData;
@class ZMAssetRemoteDataBuilder;
@class ZMAssetVideoMetaData;
@class ZMAssetVideoMetaDataBuilder;
@class ZMCalling;
@class ZMCallingBuilder;
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
@class ZMLocation;
@class ZMLocationBuilder;
@class ZMMention;
@class ZMMentionBuilder;
@class ZMMsgDeleted;
@class ZMMsgDeletedBuilder;
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

typedef NS_ENUM(SInt32, ZMAssetNotUploaded) {
  ZMAssetNotUploadedCANCELLED = 0,
  ZMAssetNotUploadedFAILED = 1,
};

BOOL ZMAssetNotUploadedIsValidValue(ZMAssetNotUploaded value);
NSString *NSStringFromZMAssetNotUploaded(ZMAssetNotUploaded value);


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
#define GenericMessage_calling @"calling"
#define GenericMessage_asset @"asset"
#define GenericMessage_deleted @"deleted"
#define GenericMessage_location @"location"
@interface ZMGenericMessage : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasMessageId_:1;
  BOOL hasText_:1;
  BOOL hasImage_:1;
  BOOL hasKnock_:1;
  BOOL hasLastRead_:1;
  BOOL hasCleared_:1;
  BOOL hasExternal_:1;
  BOOL hasCalling_:1;
  BOOL hasAsset_:1;
  BOOL hasDeleted_:1;
  BOOL hasLocation_:1;
  BOOL hasLiking_:1;
  BOOL hasClientAction_:1;
  NSString* messageId;
  ZMText* text;
  ZMImageAsset* image;
  ZMKnock* knock;
  ZMLastRead* lastRead;
  ZMCleared* cleared;
  ZMExternal* external;
  ZMCalling* calling;
  ZMAsset* asset;
  ZMMsgDeleted* deleted;
  ZMLocation* location;
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
- (BOOL) hasCalling;
- (BOOL) hasAsset;
- (BOOL) hasDeleted;
- (BOOL) hasLocation;
@property (readonly, strong) NSString* messageId;
@property (readonly, strong) ZMText* text;
@property (readonly, strong) ZMImageAsset* image;
@property (readonly, strong) ZMKnock* knock;
@property (readonly) ZMLikeAction liking;
@property (readonly, strong) ZMLastRead* lastRead;
@property (readonly, strong) ZMCleared* cleared;
@property (readonly, strong) ZMExternal* external;
@property (readonly) ZMClientAction clientAction;
@property (readonly, strong) ZMCalling* calling;
@property (readonly, strong) ZMAsset* asset;
@property (readonly, strong) ZMMsgDeleted* deleted;
@property (readonly, strong) ZMLocation* location;

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

- (BOOL) hasCalling;
- (ZMCalling*) calling;
- (ZMGenericMessageBuilder*) setCalling:(ZMCalling*) value;
- (ZMGenericMessageBuilder*) setCallingBuilder:(ZMCallingBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeCalling:(ZMCalling*) value;
- (ZMGenericMessageBuilder*) clearCalling;

- (BOOL) hasAsset;
- (ZMAsset*) asset;
- (ZMGenericMessageBuilder*) setAsset:(ZMAsset*) value;
- (ZMGenericMessageBuilder*) setAssetBuilder:(ZMAssetBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeAsset:(ZMAsset*) value;
- (ZMGenericMessageBuilder*) clearAsset;

- (BOOL) hasDeleted;
- (ZMMsgDeleted*) deleted;
- (ZMGenericMessageBuilder*) setDeleted:(ZMMsgDeleted*) value;
- (ZMGenericMessageBuilder*) setDeletedBuilder:(ZMMsgDeletedBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeDeleted:(ZMMsgDeleted*) value;
- (ZMGenericMessageBuilder*) clearDeleted;

- (BOOL) hasLocation;
- (ZMLocation*) location;
- (ZMGenericMessageBuilder*) setLocation:(ZMLocation*) value;
- (ZMGenericMessageBuilder*) setLocationBuilder:(ZMLocationBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeLocation:(ZMLocation*) value;
- (ZMGenericMessageBuilder*) clearLocation;
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

#define MsgDeleted_conversation_id @"conversationId"
#define MsgDeleted_message_id @"messageId"
@interface ZMMsgDeleted : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasConversationId_:1;
  BOOL hasMessageId_:1;
  NSString* conversationId;
  NSString* messageId;
}
- (BOOL) hasConversationId;
- (BOOL) hasMessageId;
@property (readonly, strong) NSString* conversationId;
@property (readonly, strong) NSString* messageId;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMMsgDeletedBuilder*) builder;
+ (ZMMsgDeletedBuilder*) builder;
+ (ZMMsgDeletedBuilder*) builderWithPrototype:(ZMMsgDeleted*) prototype;
- (ZMMsgDeletedBuilder*) toBuilder;

+ (ZMMsgDeleted*) parseFromData:(NSData*) data;
+ (ZMMsgDeleted*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMMsgDeleted*) parseFromInputStream:(NSInputStream*) input;
+ (ZMMsgDeleted*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMMsgDeleted*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMMsgDeleted*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMMsgDeletedBuilder : PBGeneratedMessageBuilder {
@private
  ZMMsgDeleted* resultMsgDeleted;
}

- (ZMMsgDeleted*) defaultInstance;

- (ZMMsgDeletedBuilder*) clear;
- (ZMMsgDeletedBuilder*) clone;

- (ZMMsgDeleted*) build;
- (ZMMsgDeleted*) buildPartial;

- (ZMMsgDeletedBuilder*) mergeFrom:(ZMMsgDeleted*) other;
- (ZMMsgDeletedBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMMsgDeletedBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasConversationId;
- (NSString*) conversationId;
- (ZMMsgDeletedBuilder*) setConversationId:(NSString*) value;
- (ZMMsgDeletedBuilder*) clearConversationId;

- (BOOL) hasMessageId;
- (NSString*) messageId;
- (ZMMsgDeletedBuilder*) setMessageId:(NSString*) value;
- (ZMMsgDeletedBuilder*) clearMessageId;
@end

#define Location_longitude @"longitude"
#define Location_latitude @"latitude"
#define Location_name @"name"
#define Location_zoom @"zoom"
@interface ZMLocation : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasLongitude_:1;
  BOOL hasLatitude_:1;
  BOOL hasZoom_:1;
  BOOL hasName_:1;
  Float32 longitude;
  Float32 latitude;
  SInt32 zoom;
  NSString* name;
}
- (BOOL) hasLongitude;
- (BOOL) hasLatitude;
- (BOOL) hasName;
- (BOOL) hasZoom;
@property (readonly) Float32 longitude;
@property (readonly) Float32 latitude;
@property (readonly, strong) NSString* name;
@property (readonly) SInt32 zoom;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMLocationBuilder*) builder;
+ (ZMLocationBuilder*) builder;
+ (ZMLocationBuilder*) builderWithPrototype:(ZMLocation*) prototype;
- (ZMLocationBuilder*) toBuilder;

+ (ZMLocation*) parseFromData:(NSData*) data;
+ (ZMLocation*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMLocation*) parseFromInputStream:(NSInputStream*) input;
+ (ZMLocation*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMLocation*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMLocation*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMLocationBuilder : PBGeneratedMessageBuilder {
@private
  ZMLocation* resultLocation;
}

- (ZMLocation*) defaultInstance;

- (ZMLocationBuilder*) clear;
- (ZMLocationBuilder*) clone;

- (ZMLocation*) build;
- (ZMLocation*) buildPartial;

- (ZMLocationBuilder*) mergeFrom:(ZMLocation*) other;
- (ZMLocationBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMLocationBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasLongitude;
- (Float32) longitude;
- (ZMLocationBuilder*) setLongitude:(Float32) value;
- (ZMLocationBuilder*) clearLongitude;

- (BOOL) hasLatitude;
- (Float32) latitude;
- (ZMLocationBuilder*) setLatitude:(Float32) value;
- (ZMLocationBuilder*) clearLatitude;

- (BOOL) hasName;
- (NSString*) name;
- (ZMLocationBuilder*) setName:(NSString*) value;
- (ZMLocationBuilder*) clearName;

- (BOOL) hasZoom;
- (SInt32) zoom;
- (ZMLocationBuilder*) setZoom:(SInt32) value;
- (ZMLocationBuilder*) clearZoom;
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

#define Asset_original @"original"
#define Asset_not_uploaded @"notUploaded"
#define Asset_uploaded @"uploaded"
#define Asset_preview @"preview"
@interface ZMAsset : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasOriginal_:1;
  BOOL hasUploaded_:1;
  BOOL hasPreview_:1;
  BOOL hasNotUploaded_:1;
  ZMAssetOriginal* original;
  ZMAssetRemoteData* uploaded;
  ZMAssetPreview* preview;
  ZMAssetNotUploaded notUploaded;
}
- (BOOL) hasOriginal;
- (BOOL) hasNotUploaded;
- (BOOL) hasUploaded;
- (BOOL) hasPreview;
@property (readonly, strong) ZMAssetOriginal* original;
@property (readonly) ZMAssetNotUploaded notUploaded;
@property (readonly, strong) ZMAssetRemoteData* uploaded;
@property (readonly, strong) ZMAssetPreview* preview;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMAssetBuilder*) builder;
+ (ZMAssetBuilder*) builder;
+ (ZMAssetBuilder*) builderWithPrototype:(ZMAsset*) prototype;
- (ZMAssetBuilder*) toBuilder;

+ (ZMAsset*) parseFromData:(NSData*) data;
+ (ZMAsset*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAsset*) parseFromInputStream:(NSInputStream*) input;
+ (ZMAsset*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAsset*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMAsset*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

#define Original_mime_type @"mimeType"
#define Original_size @"size"
#define Original_name @"name"
#define Original_image @"image"
#define Original_video @"video"
#define Original_audio @"audio"
@interface ZMAssetOriginal : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasSize_:1;
  BOOL hasMimeType_:1;
  BOOL hasName_:1;
  BOOL hasImage_:1;
  BOOL hasVideo_:1;
  BOOL hasAudio_:1;
  UInt64 size;
  NSString* mimeType;
  NSString* name;
  ZMAssetImageMetaData* image;
  ZMAssetVideoMetaData* video;
  ZMAssetAudioMetaData* audio;
}
- (BOOL) hasMimeType;
- (BOOL) hasSize;
- (BOOL) hasName;
- (BOOL) hasImage;
- (BOOL) hasVideo;
- (BOOL) hasAudio;
@property (readonly, strong) NSString* mimeType;
@property (readonly) UInt64 size;
@property (readonly, strong) NSString* name;
@property (readonly, strong) ZMAssetImageMetaData* image;
@property (readonly, strong) ZMAssetVideoMetaData* video;
@property (readonly, strong) ZMAssetAudioMetaData* audio;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMAssetOriginalBuilder*) builder;
+ (ZMAssetOriginalBuilder*) builder;
+ (ZMAssetOriginalBuilder*) builderWithPrototype:(ZMAssetOriginal*) prototype;
- (ZMAssetOriginalBuilder*) toBuilder;

+ (ZMAssetOriginal*) parseFromData:(NSData*) data;
+ (ZMAssetOriginal*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetOriginal*) parseFromInputStream:(NSInputStream*) input;
+ (ZMAssetOriginal*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetOriginal*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMAssetOriginal*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMAssetOriginalBuilder : PBGeneratedMessageBuilder {
@private
  ZMAssetOriginal* resultOriginal;
}

- (ZMAssetOriginal*) defaultInstance;

- (ZMAssetOriginalBuilder*) clear;
- (ZMAssetOriginalBuilder*) clone;

- (ZMAssetOriginal*) build;
- (ZMAssetOriginal*) buildPartial;

- (ZMAssetOriginalBuilder*) mergeFrom:(ZMAssetOriginal*) other;
- (ZMAssetOriginalBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMAssetOriginalBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasMimeType;
- (NSString*) mimeType;
- (ZMAssetOriginalBuilder*) setMimeType:(NSString*) value;
- (ZMAssetOriginalBuilder*) clearMimeType;

- (BOOL) hasSize;
- (UInt64) size;
- (ZMAssetOriginalBuilder*) setSize:(UInt64) value;
- (ZMAssetOriginalBuilder*) clearSize;

- (BOOL) hasName;
- (NSString*) name;
- (ZMAssetOriginalBuilder*) setName:(NSString*) value;
- (ZMAssetOriginalBuilder*) clearName;

- (BOOL) hasImage;
- (ZMAssetImageMetaData*) image;
- (ZMAssetOriginalBuilder*) setImage:(ZMAssetImageMetaData*) value;
- (ZMAssetOriginalBuilder*) setImageBuilder:(ZMAssetImageMetaDataBuilder*) builderForValue;
- (ZMAssetOriginalBuilder*) mergeImage:(ZMAssetImageMetaData*) value;
- (ZMAssetOriginalBuilder*) clearImage;

- (BOOL) hasVideo;
- (ZMAssetVideoMetaData*) video;
- (ZMAssetOriginalBuilder*) setVideo:(ZMAssetVideoMetaData*) value;
- (ZMAssetOriginalBuilder*) setVideoBuilder:(ZMAssetVideoMetaDataBuilder*) builderForValue;
- (ZMAssetOriginalBuilder*) mergeVideo:(ZMAssetVideoMetaData*) value;
- (ZMAssetOriginalBuilder*) clearVideo;

- (BOOL) hasAudio;
- (ZMAssetAudioMetaData*) audio;
- (ZMAssetOriginalBuilder*) setAudio:(ZMAssetAudioMetaData*) value;
- (ZMAssetOriginalBuilder*) setAudioBuilder:(ZMAssetAudioMetaDataBuilder*) builderForValue;
- (ZMAssetOriginalBuilder*) mergeAudio:(ZMAssetAudioMetaData*) value;
- (ZMAssetOriginalBuilder*) clearAudio;
@end

#define Preview_mime_type @"mimeType"
#define Preview_size @"size"
#define Preview_remote @"remote"
#define Preview_image @"image"
@interface ZMAssetPreview : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasSize_:1;
  BOOL hasMimeType_:1;
  BOOL hasRemote_:1;
  BOOL hasImage_:1;
  UInt64 size;
  NSString* mimeType;
  ZMAssetRemoteData* remote;
  ZMAssetImageMetaData* image;
}
- (BOOL) hasMimeType;
- (BOOL) hasSize;
- (BOOL) hasRemote;
- (BOOL) hasImage;
@property (readonly, strong) NSString* mimeType;
@property (readonly) UInt64 size;
@property (readonly, strong) ZMAssetRemoteData* remote;
@property (readonly, strong) ZMAssetImageMetaData* image;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMAssetPreviewBuilder*) builder;
+ (ZMAssetPreviewBuilder*) builder;
+ (ZMAssetPreviewBuilder*) builderWithPrototype:(ZMAssetPreview*) prototype;
- (ZMAssetPreviewBuilder*) toBuilder;

+ (ZMAssetPreview*) parseFromData:(NSData*) data;
+ (ZMAssetPreview*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetPreview*) parseFromInputStream:(NSInputStream*) input;
+ (ZMAssetPreview*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetPreview*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMAssetPreview*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMAssetPreviewBuilder : PBGeneratedMessageBuilder {
@private
  ZMAssetPreview* resultPreview;
}

- (ZMAssetPreview*) defaultInstance;

- (ZMAssetPreviewBuilder*) clear;
- (ZMAssetPreviewBuilder*) clone;

- (ZMAssetPreview*) build;
- (ZMAssetPreview*) buildPartial;

- (ZMAssetPreviewBuilder*) mergeFrom:(ZMAssetPreview*) other;
- (ZMAssetPreviewBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMAssetPreviewBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasMimeType;
- (NSString*) mimeType;
- (ZMAssetPreviewBuilder*) setMimeType:(NSString*) value;
- (ZMAssetPreviewBuilder*) clearMimeType;

- (BOOL) hasSize;
- (UInt64) size;
- (ZMAssetPreviewBuilder*) setSize:(UInt64) value;
- (ZMAssetPreviewBuilder*) clearSize;

- (BOOL) hasRemote;
- (ZMAssetRemoteData*) remote;
- (ZMAssetPreviewBuilder*) setRemote:(ZMAssetRemoteData*) value;
- (ZMAssetPreviewBuilder*) setRemoteBuilder:(ZMAssetRemoteDataBuilder*) builderForValue;
- (ZMAssetPreviewBuilder*) mergeRemote:(ZMAssetRemoteData*) value;
- (ZMAssetPreviewBuilder*) clearRemote;

- (BOOL) hasImage;
- (ZMAssetImageMetaData*) image;
- (ZMAssetPreviewBuilder*) setImage:(ZMAssetImageMetaData*) value;
- (ZMAssetPreviewBuilder*) setImageBuilder:(ZMAssetImageMetaDataBuilder*) builderForValue;
- (ZMAssetPreviewBuilder*) mergeImage:(ZMAssetImageMetaData*) value;
- (ZMAssetPreviewBuilder*) clearImage;
@end

#define ImageMetaData_width @"width"
#define ImageMetaData_height @"height"
#define ImageMetaData_tag @"tag"
@interface ZMAssetImageMetaData : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasWidth_:1;
  BOOL hasHeight_:1;
  BOOL hasTag_:1;
  SInt32 width;
  SInt32 height;
  NSString* tag;
}
- (BOOL) hasWidth;
- (BOOL) hasHeight;
- (BOOL) hasTag;
@property (readonly) SInt32 width;
@property (readonly) SInt32 height;
@property (readonly, strong) NSString* tag;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMAssetImageMetaDataBuilder*) builder;
+ (ZMAssetImageMetaDataBuilder*) builder;
+ (ZMAssetImageMetaDataBuilder*) builderWithPrototype:(ZMAssetImageMetaData*) prototype;
- (ZMAssetImageMetaDataBuilder*) toBuilder;

+ (ZMAssetImageMetaData*) parseFromData:(NSData*) data;
+ (ZMAssetImageMetaData*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetImageMetaData*) parseFromInputStream:(NSInputStream*) input;
+ (ZMAssetImageMetaData*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetImageMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMAssetImageMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMAssetImageMetaDataBuilder : PBGeneratedMessageBuilder {
@private
  ZMAssetImageMetaData* resultImageMetaData;
}

- (ZMAssetImageMetaData*) defaultInstance;

- (ZMAssetImageMetaDataBuilder*) clear;
- (ZMAssetImageMetaDataBuilder*) clone;

- (ZMAssetImageMetaData*) build;
- (ZMAssetImageMetaData*) buildPartial;

- (ZMAssetImageMetaDataBuilder*) mergeFrom:(ZMAssetImageMetaData*) other;
- (ZMAssetImageMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMAssetImageMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasWidth;
- (SInt32) width;
- (ZMAssetImageMetaDataBuilder*) setWidth:(SInt32) value;
- (ZMAssetImageMetaDataBuilder*) clearWidth;

- (BOOL) hasHeight;
- (SInt32) height;
- (ZMAssetImageMetaDataBuilder*) setHeight:(SInt32) value;
- (ZMAssetImageMetaDataBuilder*) clearHeight;

- (BOOL) hasTag;
- (NSString*) tag;
- (ZMAssetImageMetaDataBuilder*) setTag:(NSString*) value;
- (ZMAssetImageMetaDataBuilder*) clearTag;
@end

#define VideoMetaData_width @"width"
#define VideoMetaData_height @"height"
#define VideoMetaData_duration_in_millis @"durationInMillis"
@interface ZMAssetVideoMetaData : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasDurationInMillis_:1;
  BOOL hasWidth_:1;
  BOOL hasHeight_:1;
  UInt64 durationInMillis;
  SInt32 width;
  SInt32 height;
}
- (BOOL) hasWidth;
- (BOOL) hasHeight;
- (BOOL) hasDurationInMillis;
@property (readonly) SInt32 width;
@property (readonly) SInt32 height;
@property (readonly) UInt64 durationInMillis;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMAssetVideoMetaDataBuilder*) builder;
+ (ZMAssetVideoMetaDataBuilder*) builder;
+ (ZMAssetVideoMetaDataBuilder*) builderWithPrototype:(ZMAssetVideoMetaData*) prototype;
- (ZMAssetVideoMetaDataBuilder*) toBuilder;

+ (ZMAssetVideoMetaData*) parseFromData:(NSData*) data;
+ (ZMAssetVideoMetaData*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetVideoMetaData*) parseFromInputStream:(NSInputStream*) input;
+ (ZMAssetVideoMetaData*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetVideoMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMAssetVideoMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMAssetVideoMetaDataBuilder : PBGeneratedMessageBuilder {
@private
  ZMAssetVideoMetaData* resultVideoMetaData;
}

- (ZMAssetVideoMetaData*) defaultInstance;

- (ZMAssetVideoMetaDataBuilder*) clear;
- (ZMAssetVideoMetaDataBuilder*) clone;

- (ZMAssetVideoMetaData*) build;
- (ZMAssetVideoMetaData*) buildPartial;

- (ZMAssetVideoMetaDataBuilder*) mergeFrom:(ZMAssetVideoMetaData*) other;
- (ZMAssetVideoMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMAssetVideoMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasWidth;
- (SInt32) width;
- (ZMAssetVideoMetaDataBuilder*) setWidth:(SInt32) value;
- (ZMAssetVideoMetaDataBuilder*) clearWidth;

- (BOOL) hasHeight;
- (SInt32) height;
- (ZMAssetVideoMetaDataBuilder*) setHeight:(SInt32) value;
- (ZMAssetVideoMetaDataBuilder*) clearHeight;

- (BOOL) hasDurationInMillis;
- (UInt64) durationInMillis;
- (ZMAssetVideoMetaDataBuilder*) setDurationInMillis:(UInt64) value;
- (ZMAssetVideoMetaDataBuilder*) clearDurationInMillis;
@end

#define AudioMetaData_duration_in_millis @"durationInMillis"
#define AudioMetaData_normalized_loudness @"normalizedLoudness"
@interface ZMAssetAudioMetaData : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasDurationInMillis_:1;
  BOOL hasNormalizedLoudness_:1;
  UInt64 durationInMillis;
  NSData* normalizedLoudness;
}
- (BOOL) hasDurationInMillis;
- (BOOL) hasNormalizedLoudness;
@property (readonly) UInt64 durationInMillis;
@property (readonly, strong) NSData* normalizedLoudness;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMAssetAudioMetaDataBuilder*) builder;
+ (ZMAssetAudioMetaDataBuilder*) builder;
+ (ZMAssetAudioMetaDataBuilder*) builderWithPrototype:(ZMAssetAudioMetaData*) prototype;
- (ZMAssetAudioMetaDataBuilder*) toBuilder;

+ (ZMAssetAudioMetaData*) parseFromData:(NSData*) data;
+ (ZMAssetAudioMetaData*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetAudioMetaData*) parseFromInputStream:(NSInputStream*) input;
+ (ZMAssetAudioMetaData*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetAudioMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMAssetAudioMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMAssetAudioMetaDataBuilder : PBGeneratedMessageBuilder {
@private
  ZMAssetAudioMetaData* resultAudioMetaData;
}

- (ZMAssetAudioMetaData*) defaultInstance;

- (ZMAssetAudioMetaDataBuilder*) clear;
- (ZMAssetAudioMetaDataBuilder*) clone;

- (ZMAssetAudioMetaData*) build;
- (ZMAssetAudioMetaData*) buildPartial;

- (ZMAssetAudioMetaDataBuilder*) mergeFrom:(ZMAssetAudioMetaData*) other;
- (ZMAssetAudioMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMAssetAudioMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasDurationInMillis;
- (UInt64) durationInMillis;
- (ZMAssetAudioMetaDataBuilder*) setDurationInMillis:(UInt64) value;
- (ZMAssetAudioMetaDataBuilder*) clearDurationInMillis;

- (BOOL) hasNormalizedLoudness;
- (NSData*) normalizedLoudness;
- (ZMAssetAudioMetaDataBuilder*) setNormalizedLoudness:(NSData*) value;
- (ZMAssetAudioMetaDataBuilder*) clearNormalizedLoudness;
@end

#define RemoteData_otr_key @"otrKey"
#define RemoteData_sha256 @"sha256"
#define RemoteData_asset_id @"assetId"
#define RemoteData_asset_token @"assetToken"
@interface ZMAssetRemoteData : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasAssetId_:1;
  BOOL hasOtrKey_:1;
  BOOL hasSha256_:1;
  BOOL hasAssetToken_:1;
  NSString* assetId;
  NSData* otrKey;
  NSData* sha256;
  NSData* assetToken;
}
- (BOOL) hasOtrKey;
- (BOOL) hasSha256;
- (BOOL) hasAssetId;
- (BOOL) hasAssetToken;
@property (readonly, strong) NSData* otrKey;
@property (readonly, strong) NSData* sha256;
@property (readonly, strong) NSString* assetId;
@property (readonly, strong) NSData* assetToken;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMAssetRemoteDataBuilder*) builder;
+ (ZMAssetRemoteDataBuilder*) builder;
+ (ZMAssetRemoteDataBuilder*) builderWithPrototype:(ZMAssetRemoteData*) prototype;
- (ZMAssetRemoteDataBuilder*) toBuilder;

+ (ZMAssetRemoteData*) parseFromData:(NSData*) data;
+ (ZMAssetRemoteData*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetRemoteData*) parseFromInputStream:(NSInputStream*) input;
+ (ZMAssetRemoteData*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAssetRemoteData*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMAssetRemoteData*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMAssetRemoteDataBuilder : PBGeneratedMessageBuilder {
@private
  ZMAssetRemoteData* resultRemoteData;
}

- (ZMAssetRemoteData*) defaultInstance;

- (ZMAssetRemoteDataBuilder*) clear;
- (ZMAssetRemoteDataBuilder*) clone;

- (ZMAssetRemoteData*) build;
- (ZMAssetRemoteData*) buildPartial;

- (ZMAssetRemoteDataBuilder*) mergeFrom:(ZMAssetRemoteData*) other;
- (ZMAssetRemoteDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMAssetRemoteDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasOtrKey;
- (NSData*) otrKey;
- (ZMAssetRemoteDataBuilder*) setOtrKey:(NSData*) value;
- (ZMAssetRemoteDataBuilder*) clearOtrKey;

- (BOOL) hasSha256;
- (NSData*) sha256;
- (ZMAssetRemoteDataBuilder*) setSha256:(NSData*) value;
- (ZMAssetRemoteDataBuilder*) clearSha256;

- (BOOL) hasAssetId;
- (NSString*) assetId;
- (ZMAssetRemoteDataBuilder*) setAssetId:(NSString*) value;
- (ZMAssetRemoteDataBuilder*) clearAssetId;

- (BOOL) hasAssetToken;
- (NSData*) assetToken;
- (ZMAssetRemoteDataBuilder*) setAssetToken:(NSData*) value;
- (ZMAssetRemoteDataBuilder*) clearAssetToken;
@end

@interface ZMAssetBuilder : PBGeneratedMessageBuilder {
@private
  ZMAsset* resultAsset;
}

- (ZMAsset*) defaultInstance;

- (ZMAssetBuilder*) clear;
- (ZMAssetBuilder*) clone;

- (ZMAsset*) build;
- (ZMAsset*) buildPartial;

- (ZMAssetBuilder*) mergeFrom:(ZMAsset*) other;
- (ZMAssetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMAssetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasOriginal;
- (ZMAssetOriginal*) original;
- (ZMAssetBuilder*) setOriginal:(ZMAssetOriginal*) value;
- (ZMAssetBuilder*) setOriginalBuilder:(ZMAssetOriginalBuilder*) builderForValue;
- (ZMAssetBuilder*) mergeOriginal:(ZMAssetOriginal*) value;
- (ZMAssetBuilder*) clearOriginal;

- (BOOL) hasNotUploaded;
- (ZMAssetNotUploaded) notUploaded;
- (ZMAssetBuilder*) setNotUploaded:(ZMAssetNotUploaded) value;
- (ZMAssetBuilder*) clearNotUploaded;

- (BOOL) hasUploaded;
- (ZMAssetRemoteData*) uploaded;
- (ZMAssetBuilder*) setUploaded:(ZMAssetRemoteData*) value;
- (ZMAssetBuilder*) setUploadedBuilder:(ZMAssetRemoteDataBuilder*) builderForValue;
- (ZMAssetBuilder*) mergeUploaded:(ZMAssetRemoteData*) value;
- (ZMAssetBuilder*) clearUploaded;

- (BOOL) hasPreview;
- (ZMAssetPreview*) preview;
- (ZMAssetBuilder*) setPreview:(ZMAssetPreview*) value;
- (ZMAssetBuilder*) setPreviewBuilder:(ZMAssetPreviewBuilder*) builderForValue;
- (ZMAssetBuilder*) mergePreview:(ZMAssetPreview*) value;
- (ZMAssetBuilder*) clearPreview;
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

#define Calling_content @"content"
@interface ZMCalling : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasContent_:1;
  NSString* content;
}
- (BOOL) hasContent;
@property (readonly, strong) NSString* content;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMCallingBuilder*) builder;
+ (ZMCallingBuilder*) builder;
+ (ZMCallingBuilder*) builderWithPrototype:(ZMCalling*) prototype;
- (ZMCallingBuilder*) toBuilder;

+ (ZMCalling*) parseFromData:(NSData*) data;
+ (ZMCalling*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMCalling*) parseFromInputStream:(NSInputStream*) input;
+ (ZMCalling*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMCalling*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMCalling*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMCallingBuilder : PBGeneratedMessageBuilder {
@private
  ZMCalling* resultCalling;
}

- (ZMCalling*) defaultInstance;

- (ZMCallingBuilder*) clear;
- (ZMCallingBuilder*) clone;

- (ZMCalling*) build;
- (ZMCalling*) buildPartial;

- (ZMCallingBuilder*) mergeFrom:(ZMCalling*) other;
- (ZMCallingBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMCallingBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasContent;
- (NSString*) content;
- (ZMCallingBuilder*) setContent:(NSString*) value;
- (ZMCallingBuilder*) clearContent;
@end


// @@protoc_insertion_point(global_scope)
