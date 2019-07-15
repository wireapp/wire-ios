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
@class ZMArticle;
@class ZMArticleBuilder;
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
@class ZMAvailability;
@class ZMAvailabilityBuilder;
@class ZMCalling;
@class ZMCallingBuilder;
@class ZMCleared;
@class ZMClearedBuilder;
@class ZMConfirmation;
@class ZMConfirmationBuilder;
@class ZMEphemeral;
@class ZMEphemeralBuilder;
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
@class ZMLinkPreview;
@class ZMLinkPreviewBuilder;
@class ZMLocation;
@class ZMLocationBuilder;
@class ZMMention;
@class ZMMentionBuilder;
@class ZMMessageDelete;
@class ZMMessageDeleteBuilder;
@class ZMMessageEdit;
@class ZMMessageEditBuilder;
@class ZMMessageHide;
@class ZMMessageHideBuilder;
@class ZMQuote;
@class ZMQuoteBuilder;
@class ZMReaction;
@class ZMReactionBuilder;
@class ZMText;
@class ZMTextBuilder;
@class ZMTweet;
@class ZMTweetBuilder;


typedef NS_ENUM(SInt32, ZMClientAction) {
  ZMClientActionRESETSESSION = 0,
};

BOOL ZMClientActionIsValidValue(ZMClientAction value);
NSString *NSStringFromZMClientAction(ZMClientAction value);

typedef NS_ENUM(SInt32, ZMEncryptionAlgorithm) {
  ZMEncryptionAlgorithmAESCBC = 0,
  ZMEncryptionAlgorithmAESGCM = 1,
};

BOOL ZMEncryptionAlgorithmIsValidValue(ZMEncryptionAlgorithm value);
NSString *NSStringFromZMEncryptionAlgorithm(ZMEncryptionAlgorithm value);

typedef NS_ENUM(SInt32, ZMLegalHoldStatus) {
  ZMLegalHoldStatusUNKNOWN = 0,
  ZMLegalHoldStatusDISABLED = 1,
  ZMLegalHoldStatusENABLED = 2,
};

BOOL ZMLegalHoldStatusIsValidValue(ZMLegalHoldStatus value);
NSString *NSStringFromZMLegalHoldStatus(ZMLegalHoldStatus value);

typedef NS_ENUM(SInt32, ZMAvailabilityType) {
  ZMAvailabilityTypeNONE = 0,
  ZMAvailabilityTypeAVAILABLE = 1,
  ZMAvailabilityTypeAWAY = 2,
  ZMAvailabilityTypeBUSY = 3,
};

BOOL ZMAvailabilityTypeIsValidValue(ZMAvailabilityType value);
NSString *NSStringFromZMAvailabilityType(ZMAvailabilityType value);

typedef NS_ENUM(SInt32, ZMConfirmationType) {
  ZMConfirmationTypeDELIVERED = 0,
  ZMConfirmationTypeREAD = 1,
};

BOOL ZMConfirmationTypeIsValidValue(ZMConfirmationType value);
NSString *NSStringFromZMConfirmationType(ZMConfirmationType value);

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
#define GenericMessage_lastRead @"lastRead"
#define GenericMessage_cleared @"cleared"
#define GenericMessage_external @"external"
#define GenericMessage_clientAction @"clientAction"
#define GenericMessage_calling @"calling"
#define GenericMessage_asset @"asset"
#define GenericMessage_hidden @"hidden"
#define GenericMessage_location @"location"
#define GenericMessage_deleted @"deleted"
#define GenericMessage_edited @"edited"
#define GenericMessage_confirmation @"confirmation"
#define GenericMessage_reaction @"reaction"
#define GenericMessage_ephemeral @"ephemeral"
#define GenericMessage_availability @"availability"
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
  BOOL hasHidden_:1;
  BOOL hasLocation_:1;
  BOOL hasDeleted_:1;
  BOOL hasEdited_:1;
  BOOL hasConfirmation_:1;
  BOOL hasReaction_:1;
  BOOL hasEphemeral_:1;
  BOOL hasAvailability_:1;
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
  ZMMessageHide* hidden;
  ZMLocation* location;
  ZMMessageDelete* deleted;
  ZMMessageEdit* edited;
  ZMConfirmation* confirmation;
  ZMReaction* reaction;
  ZMEphemeral* ephemeral;
  ZMAvailability* availability;
  ZMClientAction clientAction;
}
- (BOOL) hasMessageId;
- (BOOL) hasText;
- (BOOL) hasImage;
- (BOOL) hasKnock;
- (BOOL) hasLastRead;
- (BOOL) hasCleared;
- (BOOL) hasExternal;
- (BOOL) hasClientAction;
- (BOOL) hasCalling;
- (BOOL) hasAsset;
- (BOOL) hasHidden;
- (BOOL) hasLocation;
- (BOOL) hasDeleted;
- (BOOL) hasEdited;
- (BOOL) hasConfirmation;
- (BOOL) hasReaction;
- (BOOL) hasEphemeral;
- (BOOL) hasAvailability;
@property (readonly, strong) NSString* messageId;
@property (readonly, strong) ZMText* text;
@property (readonly, strong) ZMImageAsset* image;
@property (readonly, strong) ZMKnock* knock;
@property (readonly, strong) ZMLastRead* lastRead;
@property (readonly, strong) ZMCleared* cleared;
@property (readonly, strong) ZMExternal* external;
@property (readonly) ZMClientAction clientAction;
@property (readonly, strong) ZMCalling* calling;
@property (readonly, strong) ZMAsset* asset;
@property (readonly, strong) ZMMessageHide* hidden;
@property (readonly, strong) ZMLocation* location;
@property (readonly, strong) ZMMessageDelete* deleted;
@property (readonly, strong) ZMMessageEdit* edited;
@property (readonly, strong) ZMConfirmation* confirmation;
@property (readonly, strong) ZMReaction* reaction;
@property (readonly, strong) ZMEphemeral* ephemeral;
@property (readonly, strong) ZMAvailability* availability;

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

- (BOOL) hasHidden;
- (ZMMessageHide*) hidden;
- (ZMGenericMessageBuilder*) setHidden:(ZMMessageHide*) value;
- (ZMGenericMessageBuilder*) setHiddenBuilder:(ZMMessageHideBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeHidden:(ZMMessageHide*) value;
- (ZMGenericMessageBuilder*) clearHidden;

- (BOOL) hasLocation;
- (ZMLocation*) location;
- (ZMGenericMessageBuilder*) setLocation:(ZMLocation*) value;
- (ZMGenericMessageBuilder*) setLocationBuilder:(ZMLocationBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeLocation:(ZMLocation*) value;
- (ZMGenericMessageBuilder*) clearLocation;

- (BOOL) hasDeleted;
- (ZMMessageDelete*) deleted;
- (ZMGenericMessageBuilder*) setDeleted:(ZMMessageDelete*) value;
- (ZMGenericMessageBuilder*) setDeletedBuilder:(ZMMessageDeleteBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeDeleted:(ZMMessageDelete*) value;
- (ZMGenericMessageBuilder*) clearDeleted;

- (BOOL) hasEdited;
- (ZMMessageEdit*) edited;
- (ZMGenericMessageBuilder*) setEdited:(ZMMessageEdit*) value;
- (ZMGenericMessageBuilder*) setEditedBuilder:(ZMMessageEditBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeEdited:(ZMMessageEdit*) value;
- (ZMGenericMessageBuilder*) clearEdited;

- (BOOL) hasConfirmation;
- (ZMConfirmation*) confirmation;
- (ZMGenericMessageBuilder*) setConfirmation:(ZMConfirmation*) value;
- (ZMGenericMessageBuilder*) setConfirmationBuilder:(ZMConfirmationBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeConfirmation:(ZMConfirmation*) value;
- (ZMGenericMessageBuilder*) clearConfirmation;

- (BOOL) hasReaction;
- (ZMReaction*) reaction;
- (ZMGenericMessageBuilder*) setReaction:(ZMReaction*) value;
- (ZMGenericMessageBuilder*) setReactionBuilder:(ZMReactionBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeReaction:(ZMReaction*) value;
- (ZMGenericMessageBuilder*) clearReaction;

- (BOOL) hasEphemeral;
- (ZMEphemeral*) ephemeral;
- (ZMGenericMessageBuilder*) setEphemeral:(ZMEphemeral*) value;
- (ZMGenericMessageBuilder*) setEphemeralBuilder:(ZMEphemeralBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeEphemeral:(ZMEphemeral*) value;
- (ZMGenericMessageBuilder*) clearEphemeral;

- (BOOL) hasAvailability;
- (ZMAvailability*) availability;
- (ZMGenericMessageBuilder*) setAvailability:(ZMAvailability*) value;
- (ZMGenericMessageBuilder*) setAvailabilityBuilder:(ZMAvailabilityBuilder*) builderForValue;
- (ZMGenericMessageBuilder*) mergeAvailability:(ZMAvailability*) value;
- (ZMGenericMessageBuilder*) clearAvailability;
@end

#define Availability_type @"type"
@interface ZMAvailability : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasType_:1;
  ZMAvailabilityType type;
}
- (BOOL) hasType;
@property (readonly) ZMAvailabilityType type;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMAvailabilityBuilder*) builder;
+ (ZMAvailabilityBuilder*) builder;
+ (ZMAvailabilityBuilder*) builderWithPrototype:(ZMAvailability*) prototype;
- (ZMAvailabilityBuilder*) toBuilder;

+ (ZMAvailability*) parseFromData:(NSData*) data;
+ (ZMAvailability*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAvailability*) parseFromInputStream:(NSInputStream*) input;
+ (ZMAvailability*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMAvailability*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMAvailability*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMAvailabilityBuilder : PBGeneratedMessageBuilder {
@private
  ZMAvailability* resultAvailability;
}

- (ZMAvailability*) defaultInstance;

- (ZMAvailabilityBuilder*) clear;
- (ZMAvailabilityBuilder*) clone;

- (ZMAvailability*) build;
- (ZMAvailability*) buildPartial;

- (ZMAvailabilityBuilder*) mergeFrom:(ZMAvailability*) other;
- (ZMAvailabilityBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMAvailabilityBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasType;
- (ZMAvailabilityType) type;
- (ZMAvailabilityBuilder*) setType:(ZMAvailabilityType) value;
- (ZMAvailabilityBuilder*) clearType;
@end

#define Ephemeral_expire_after_millis @"expireAfterMillis"
#define Ephemeral_text @"text"
#define Ephemeral_image @"image"
#define Ephemeral_knock @"knock"
#define Ephemeral_asset @"asset"
#define Ephemeral_location @"location"
@interface ZMEphemeral : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasExpireAfterMillis_:1;
  BOOL hasText_:1;
  BOOL hasImage_:1;
  BOOL hasKnock_:1;
  BOOL hasAsset_:1;
  BOOL hasLocation_:1;
  SInt64 expireAfterMillis;
  ZMText* text;
  ZMImageAsset* image;
  ZMKnock* knock;
  ZMAsset* asset;
  ZMLocation* location;
}
- (BOOL) hasExpireAfterMillis;
- (BOOL) hasText;
- (BOOL) hasImage;
- (BOOL) hasKnock;
- (BOOL) hasAsset;
- (BOOL) hasLocation;
@property (readonly) SInt64 expireAfterMillis;
@property (readonly, strong) ZMText* text;
@property (readonly, strong) ZMImageAsset* image;
@property (readonly, strong) ZMKnock* knock;
@property (readonly, strong) ZMAsset* asset;
@property (readonly, strong) ZMLocation* location;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMEphemeralBuilder*) builder;
+ (ZMEphemeralBuilder*) builder;
+ (ZMEphemeralBuilder*) builderWithPrototype:(ZMEphemeral*) prototype;
- (ZMEphemeralBuilder*) toBuilder;

+ (ZMEphemeral*) parseFromData:(NSData*) data;
+ (ZMEphemeral*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMEphemeral*) parseFromInputStream:(NSInputStream*) input;
+ (ZMEphemeral*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMEphemeral*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMEphemeral*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMEphemeralBuilder : PBGeneratedMessageBuilder {
@private
  ZMEphemeral* resultEphemeral;
}

- (ZMEphemeral*) defaultInstance;

- (ZMEphemeralBuilder*) clear;
- (ZMEphemeralBuilder*) clone;

- (ZMEphemeral*) build;
- (ZMEphemeral*) buildPartial;

- (ZMEphemeralBuilder*) mergeFrom:(ZMEphemeral*) other;
- (ZMEphemeralBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMEphemeralBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasExpireAfterMillis;
- (SInt64) expireAfterMillis;
- (ZMEphemeralBuilder*) setExpireAfterMillis:(SInt64) value;
- (ZMEphemeralBuilder*) clearExpireAfterMillis;

- (BOOL) hasText;
- (ZMText*) text;
- (ZMEphemeralBuilder*) setText:(ZMText*) value;
- (ZMEphemeralBuilder*) setTextBuilder:(ZMTextBuilder*) builderForValue;
- (ZMEphemeralBuilder*) mergeText:(ZMText*) value;
- (ZMEphemeralBuilder*) clearText;

- (BOOL) hasImage;
- (ZMImageAsset*) image;
- (ZMEphemeralBuilder*) setImage:(ZMImageAsset*) value;
- (ZMEphemeralBuilder*) setImageBuilder:(ZMImageAssetBuilder*) builderForValue;
- (ZMEphemeralBuilder*) mergeImage:(ZMImageAsset*) value;
- (ZMEphemeralBuilder*) clearImage;

- (BOOL) hasKnock;
- (ZMKnock*) knock;
- (ZMEphemeralBuilder*) setKnock:(ZMKnock*) value;
- (ZMEphemeralBuilder*) setKnockBuilder:(ZMKnockBuilder*) builderForValue;
- (ZMEphemeralBuilder*) mergeKnock:(ZMKnock*) value;
- (ZMEphemeralBuilder*) clearKnock;

- (BOOL) hasAsset;
- (ZMAsset*) asset;
- (ZMEphemeralBuilder*) setAsset:(ZMAsset*) value;
- (ZMEphemeralBuilder*) setAssetBuilder:(ZMAssetBuilder*) builderForValue;
- (ZMEphemeralBuilder*) mergeAsset:(ZMAsset*) value;
- (ZMEphemeralBuilder*) clearAsset;

- (BOOL) hasLocation;
- (ZMLocation*) location;
- (ZMEphemeralBuilder*) setLocation:(ZMLocation*) value;
- (ZMEphemeralBuilder*) setLocationBuilder:(ZMLocationBuilder*) builderForValue;
- (ZMEphemeralBuilder*) mergeLocation:(ZMLocation*) value;
- (ZMEphemeralBuilder*) clearLocation;
@end

#define Text_content @"content"
#define Text_link_preview @"linkPreview"
#define Text_mentions @"mentions"
#define Text_quote @"quote"
#define Text_expects_read_confirmation @"expectsReadConfirmation"
#define Text_legal_hold_status @"legalHoldStatus"
@interface ZMText : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasExpectsReadConfirmation_:1;
  BOOL hasContent_:1;
  BOOL hasQuote_:1;
  BOOL hasLegalHoldStatus_:1;
  BOOL expectsReadConfirmation_:1;
  NSString* content;
  ZMQuote* quote;
  ZMLegalHoldStatus legalHoldStatus;
  NSMutableArray * linkPreviewArray;
  NSMutableArray * mentionsArray;
}
- (BOOL) hasContent;
- (BOOL) hasQuote;
- (BOOL) hasExpectsReadConfirmation;
- (BOOL) hasLegalHoldStatus;
@property (readonly, strong) NSString* content;
@property (readonly, strong) NSArray<ZMLinkPreview*> * linkPreview;
@property (readonly, strong) NSArray<ZMMention*> * mentions;
@property (readonly, strong) ZMQuote* quote;
- (BOOL) expectsReadConfirmation;
@property (readonly) ZMLegalHoldStatus legalHoldStatus;
- (ZMLinkPreview*)linkPreviewAtIndex:(NSUInteger)index;
- (ZMMention*)mentionsAtIndex:(NSUInteger)index;

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

- (NSMutableArray<ZMLinkPreview*> *)linkPreview;
- (ZMLinkPreview*)linkPreviewAtIndex:(NSUInteger)index;
- (ZMTextBuilder *)addLinkPreview:(ZMLinkPreview*)value;
- (ZMTextBuilder *)setLinkPreviewArray:(NSArray<ZMLinkPreview*> *)array;
- (ZMTextBuilder *)clearLinkPreview;

- (NSMutableArray<ZMMention*> *)mentions;
- (ZMMention*)mentionsAtIndex:(NSUInteger)index;
- (ZMTextBuilder *)addMentions:(ZMMention*)value;
- (ZMTextBuilder *)setMentionsArray:(NSArray<ZMMention*> *)array;
- (ZMTextBuilder *)clearMentions;

- (BOOL) hasQuote;
- (ZMQuote*) quote;
- (ZMTextBuilder*) setQuote:(ZMQuote*) value;
- (ZMTextBuilder*) setQuoteBuilder:(ZMQuoteBuilder*) builderForValue;
- (ZMTextBuilder*) mergeQuote:(ZMQuote*) value;
- (ZMTextBuilder*) clearQuote;

- (BOOL) hasExpectsReadConfirmation;
- (BOOL) expectsReadConfirmation;
- (ZMTextBuilder*) setExpectsReadConfirmation:(BOOL) value;
- (ZMTextBuilder*) clearExpectsReadConfirmation;

- (BOOL) hasLegalHoldStatus;
- (ZMLegalHoldStatus) legalHoldStatus;
- (ZMTextBuilder*) setLegalHoldStatus:(ZMLegalHoldStatus) value;
- (ZMTextBuilder*) clearLegalHoldStatus;
@end

#define Knock_hot_knock @"hotKnock"
#define Knock_expects_read_confirmation @"expectsReadConfirmation"
#define Knock_legal_hold_status @"legalHoldStatus"
@interface ZMKnock : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasHotKnock_:1;
  BOOL hasExpectsReadConfirmation_:1;
  BOOL hasLegalHoldStatus_:1;
  BOOL hotKnock_:1;
  BOOL expectsReadConfirmation_:1;
  ZMLegalHoldStatus legalHoldStatus;
}
- (BOOL) hasHotKnock;
- (BOOL) hasExpectsReadConfirmation;
- (BOOL) hasLegalHoldStatus;
- (BOOL) hotKnock;
- (BOOL) expectsReadConfirmation;
@property (readonly) ZMLegalHoldStatus legalHoldStatus;

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

- (BOOL) hasExpectsReadConfirmation;
- (BOOL) expectsReadConfirmation;
- (ZMKnockBuilder*) setExpectsReadConfirmation:(BOOL) value;
- (ZMKnockBuilder*) clearExpectsReadConfirmation;

- (BOOL) hasLegalHoldStatus;
- (ZMLegalHoldStatus) legalHoldStatus;
- (ZMKnockBuilder*) setLegalHoldStatus:(ZMLegalHoldStatus) value;
- (ZMKnockBuilder*) clearLegalHoldStatus;
@end

#define LinkPreview_url @"url"
#define LinkPreview_url_offset @"urlOffset"
#define LinkPreview_article @"article"
#define LinkPreview_permanent_url @"permanentUrl"
#define LinkPreview_title @"title"
#define LinkPreview_summary @"summary"
#define LinkPreview_image @"image"
#define LinkPreview_tweet @"tweet"
@interface ZMLinkPreview : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasUrlOffset_:1;
  BOOL hasUrl_:1;
  BOOL hasPermanentUrl_:1;
  BOOL hasTitle_:1;
  BOOL hasSummary_:1;
  BOOL hasArticle_:1;
  BOOL hasImage_:1;
  BOOL hasTweet_:1;
  SInt32 urlOffset;
  NSString* url;
  NSString* permanentUrl;
  NSString* title;
  NSString* summary;
  ZMArticle* article;
  ZMAsset* image;
  ZMTweet* tweet;
}
- (BOOL) hasUrl;
- (BOOL) hasUrlOffset;
- (BOOL) hasArticle;
- (BOOL) hasPermanentUrl;
- (BOOL) hasTitle;
- (BOOL) hasSummary;
- (BOOL) hasImage;
- (BOOL) hasTweet;
@property (readonly, strong) NSString* url;
@property (readonly) SInt32 urlOffset;
@property (readonly, strong) ZMArticle* article;
@property (readonly, strong) NSString* permanentUrl;
@property (readonly, strong) NSString* title;
@property (readonly, strong) NSString* summary;
@property (readonly, strong) ZMAsset* image;
@property (readonly, strong) ZMTweet* tweet;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMLinkPreviewBuilder*) builder;
+ (ZMLinkPreviewBuilder*) builder;
+ (ZMLinkPreviewBuilder*) builderWithPrototype:(ZMLinkPreview*) prototype;
- (ZMLinkPreviewBuilder*) toBuilder;

+ (ZMLinkPreview*) parseFromData:(NSData*) data;
+ (ZMLinkPreview*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMLinkPreview*) parseFromInputStream:(NSInputStream*) input;
+ (ZMLinkPreview*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMLinkPreview*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMLinkPreview*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMLinkPreviewBuilder : PBGeneratedMessageBuilder {
@private
  ZMLinkPreview* resultLinkPreview;
}

- (ZMLinkPreview*) defaultInstance;

- (ZMLinkPreviewBuilder*) clear;
- (ZMLinkPreviewBuilder*) clone;

- (ZMLinkPreview*) build;
- (ZMLinkPreview*) buildPartial;

- (ZMLinkPreviewBuilder*) mergeFrom:(ZMLinkPreview*) other;
- (ZMLinkPreviewBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMLinkPreviewBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasUrl;
- (NSString*) url;
- (ZMLinkPreviewBuilder*) setUrl:(NSString*) value;
- (ZMLinkPreviewBuilder*) clearUrl;

- (BOOL) hasUrlOffset;
- (SInt32) urlOffset;
- (ZMLinkPreviewBuilder*) setUrlOffset:(SInt32) value;
- (ZMLinkPreviewBuilder*) clearUrlOffset;

- (BOOL) hasArticle;
- (ZMArticle*) article;
- (ZMLinkPreviewBuilder*) setArticle:(ZMArticle*) value;
- (ZMLinkPreviewBuilder*) setArticleBuilder:(ZMArticleBuilder*) builderForValue;
- (ZMLinkPreviewBuilder*) mergeArticle:(ZMArticle*) value;
- (ZMLinkPreviewBuilder*) clearArticle;

- (BOOL) hasPermanentUrl;
- (NSString*) permanentUrl;
- (ZMLinkPreviewBuilder*) setPermanentUrl:(NSString*) value;
- (ZMLinkPreviewBuilder*) clearPermanentUrl;

- (BOOL) hasTitle;
- (NSString*) title;
- (ZMLinkPreviewBuilder*) setTitle:(NSString*) value;
- (ZMLinkPreviewBuilder*) clearTitle;

- (BOOL) hasSummary;
- (NSString*) summary;
- (ZMLinkPreviewBuilder*) setSummary:(NSString*) value;
- (ZMLinkPreviewBuilder*) clearSummary;

- (BOOL) hasImage;
- (ZMAsset*) image;
- (ZMLinkPreviewBuilder*) setImage:(ZMAsset*) value;
- (ZMLinkPreviewBuilder*) setImageBuilder:(ZMAssetBuilder*) builderForValue;
- (ZMLinkPreviewBuilder*) mergeImage:(ZMAsset*) value;
- (ZMLinkPreviewBuilder*) clearImage;

- (BOOL) hasTweet;
- (ZMTweet*) tweet;
- (ZMLinkPreviewBuilder*) setTweet:(ZMTweet*) value;
- (ZMLinkPreviewBuilder*) setTweetBuilder:(ZMTweetBuilder*) builderForValue;
- (ZMLinkPreviewBuilder*) mergeTweet:(ZMTweet*) value;
- (ZMLinkPreviewBuilder*) clearTweet;
@end

#define Tweet_author @"author"
#define Tweet_username @"username"
@interface ZMTweet : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasAuthor_:1;
  BOOL hasUsername_:1;
  NSString* author;
  NSString* username;
}
- (BOOL) hasAuthor;
- (BOOL) hasUsername;
@property (readonly, strong) NSString* author;
@property (readonly, strong) NSString* username;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMTweetBuilder*) builder;
+ (ZMTweetBuilder*) builder;
+ (ZMTweetBuilder*) builderWithPrototype:(ZMTweet*) prototype;
- (ZMTweetBuilder*) toBuilder;

+ (ZMTweet*) parseFromData:(NSData*) data;
+ (ZMTweet*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMTweet*) parseFromInputStream:(NSInputStream*) input;
+ (ZMTweet*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMTweet*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMTweet*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMTweetBuilder : PBGeneratedMessageBuilder {
@private
  ZMTweet* resultTweet;
}

- (ZMTweet*) defaultInstance;

- (ZMTweetBuilder*) clear;
- (ZMTweetBuilder*) clone;

- (ZMTweet*) build;
- (ZMTweet*) buildPartial;

- (ZMTweetBuilder*) mergeFrom:(ZMTweet*) other;
- (ZMTweetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMTweetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasAuthor;
- (NSString*) author;
- (ZMTweetBuilder*) setAuthor:(NSString*) value;
- (ZMTweetBuilder*) clearAuthor;

- (BOOL) hasUsername;
- (NSString*) username;
- (ZMTweetBuilder*) setUsername:(NSString*) value;
- (ZMTweetBuilder*) clearUsername;
@end

#define Article_permanent_url @"permanentUrl"
#define Article_title @"title"
#define Article_summary @"summary"
#define Article_image @"image"
@interface ZMArticle : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasPermanentUrl_:1;
  BOOL hasTitle_:1;
  BOOL hasSummary_:1;
  BOOL hasImage_:1;
  NSString* permanentUrl;
  NSString* title;
  NSString* summary;
  ZMAsset* image;
}
- (BOOL) hasPermanentUrl;
- (BOOL) hasTitle;
- (BOOL) hasSummary;
- (BOOL) hasImage;
@property (readonly, strong) NSString* permanentUrl;
@property (readonly, strong) NSString* title;
@property (readonly, strong) NSString* summary;
@property (readonly, strong) ZMAsset* image;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMArticleBuilder*) builder;
+ (ZMArticleBuilder*) builder;
+ (ZMArticleBuilder*) builderWithPrototype:(ZMArticle*) prototype;
- (ZMArticleBuilder*) toBuilder;

+ (ZMArticle*) parseFromData:(NSData*) data;
+ (ZMArticle*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMArticle*) parseFromInputStream:(NSInputStream*) input;
+ (ZMArticle*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMArticle*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMArticle*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMArticleBuilder : PBGeneratedMessageBuilder {
@private
  ZMArticle* resultArticle;
}

- (ZMArticle*) defaultInstance;

- (ZMArticleBuilder*) clear;
- (ZMArticleBuilder*) clone;

- (ZMArticle*) build;
- (ZMArticle*) buildPartial;

- (ZMArticleBuilder*) mergeFrom:(ZMArticle*) other;
- (ZMArticleBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMArticleBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasPermanentUrl;
- (NSString*) permanentUrl;
- (ZMArticleBuilder*) setPermanentUrl:(NSString*) value;
- (ZMArticleBuilder*) clearPermanentUrl;

- (BOOL) hasTitle;
- (NSString*) title;
- (ZMArticleBuilder*) setTitle:(NSString*) value;
- (ZMArticleBuilder*) clearTitle;

- (BOOL) hasSummary;
- (NSString*) summary;
- (ZMArticleBuilder*) setSummary:(NSString*) value;
- (ZMArticleBuilder*) clearSummary;

- (BOOL) hasImage;
- (ZMAsset*) image;
- (ZMArticleBuilder*) setImage:(ZMAsset*) value;
- (ZMArticleBuilder*) setImageBuilder:(ZMAssetBuilder*) builderForValue;
- (ZMArticleBuilder*) mergeImage:(ZMAsset*) value;
- (ZMArticleBuilder*) clearImage;
@end

#define Mention_start @"start"
#define Mention_length @"length"
#define Mention_user_id @"userId"
@interface ZMMention : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasStart_:1;
  BOOL hasLength_:1;
  BOOL hasUserId_:1;
  SInt32 start;
  SInt32 length;
  NSString* userId;
}
- (BOOL) hasStart;
- (BOOL) hasLength;
- (BOOL) hasUserId;
@property (readonly) SInt32 start;
@property (readonly) SInt32 length;
@property (readonly, strong) NSString* userId;

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

- (BOOL) hasStart;
- (SInt32) start;
- (ZMMentionBuilder*) setStart:(SInt32) value;
- (ZMMentionBuilder*) clearStart;

- (BOOL) hasLength;
- (SInt32) length;
- (ZMMentionBuilder*) setLength:(SInt32) value;
- (ZMMentionBuilder*) clearLength;

- (BOOL) hasUserId;
- (NSString*) userId;
- (ZMMentionBuilder*) setUserId:(NSString*) value;
- (ZMMentionBuilder*) clearUserId;
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

#define MessageHide_conversation_id @"conversationId"
#define MessageHide_message_id @"messageId"
@interface ZMMessageHide : PBGeneratedMessage<GeneratedMessageProtocol> {
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
- (ZMMessageHideBuilder*) builder;
+ (ZMMessageHideBuilder*) builder;
+ (ZMMessageHideBuilder*) builderWithPrototype:(ZMMessageHide*) prototype;
- (ZMMessageHideBuilder*) toBuilder;

+ (ZMMessageHide*) parseFromData:(NSData*) data;
+ (ZMMessageHide*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMMessageHide*) parseFromInputStream:(NSInputStream*) input;
+ (ZMMessageHide*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMMessageHide*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMMessageHide*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMMessageHideBuilder : PBGeneratedMessageBuilder {
@private
  ZMMessageHide* resultMessageHide;
}

- (ZMMessageHide*) defaultInstance;

- (ZMMessageHideBuilder*) clear;
- (ZMMessageHideBuilder*) clone;

- (ZMMessageHide*) build;
- (ZMMessageHide*) buildPartial;

- (ZMMessageHideBuilder*) mergeFrom:(ZMMessageHide*) other;
- (ZMMessageHideBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMMessageHideBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasConversationId;
- (NSString*) conversationId;
- (ZMMessageHideBuilder*) setConversationId:(NSString*) value;
- (ZMMessageHideBuilder*) clearConversationId;

- (BOOL) hasMessageId;
- (NSString*) messageId;
- (ZMMessageHideBuilder*) setMessageId:(NSString*) value;
- (ZMMessageHideBuilder*) clearMessageId;
@end

#define MessageDelete_message_id @"messageId"
@interface ZMMessageDelete : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasMessageId_:1;
  NSString* messageId;
}
- (BOOL) hasMessageId;
@property (readonly, strong) NSString* messageId;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMMessageDeleteBuilder*) builder;
+ (ZMMessageDeleteBuilder*) builder;
+ (ZMMessageDeleteBuilder*) builderWithPrototype:(ZMMessageDelete*) prototype;
- (ZMMessageDeleteBuilder*) toBuilder;

+ (ZMMessageDelete*) parseFromData:(NSData*) data;
+ (ZMMessageDelete*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMMessageDelete*) parseFromInputStream:(NSInputStream*) input;
+ (ZMMessageDelete*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMMessageDelete*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMMessageDelete*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMMessageDeleteBuilder : PBGeneratedMessageBuilder {
@private
  ZMMessageDelete* resultMessageDelete;
}

- (ZMMessageDelete*) defaultInstance;

- (ZMMessageDeleteBuilder*) clear;
- (ZMMessageDeleteBuilder*) clone;

- (ZMMessageDelete*) build;
- (ZMMessageDelete*) buildPartial;

- (ZMMessageDeleteBuilder*) mergeFrom:(ZMMessageDelete*) other;
- (ZMMessageDeleteBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMMessageDeleteBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasMessageId;
- (NSString*) messageId;
- (ZMMessageDeleteBuilder*) setMessageId:(NSString*) value;
- (ZMMessageDeleteBuilder*) clearMessageId;
@end

#define MessageEdit_replacing_message_id @"replacingMessageId"
#define MessageEdit_text @"text"
@interface ZMMessageEdit : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasReplacingMessageId_:1;
  BOOL hasText_:1;
  NSString* replacingMessageId;
  ZMText* text;
}
- (BOOL) hasReplacingMessageId;
- (BOOL) hasText;
@property (readonly, strong) NSString* replacingMessageId;
@property (readonly, strong) ZMText* text;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMMessageEditBuilder*) builder;
+ (ZMMessageEditBuilder*) builder;
+ (ZMMessageEditBuilder*) builderWithPrototype:(ZMMessageEdit*) prototype;
- (ZMMessageEditBuilder*) toBuilder;

+ (ZMMessageEdit*) parseFromData:(NSData*) data;
+ (ZMMessageEdit*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMMessageEdit*) parseFromInputStream:(NSInputStream*) input;
+ (ZMMessageEdit*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMMessageEdit*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMMessageEdit*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMMessageEditBuilder : PBGeneratedMessageBuilder {
@private
  ZMMessageEdit* resultMessageEdit;
}

- (ZMMessageEdit*) defaultInstance;

- (ZMMessageEditBuilder*) clear;
- (ZMMessageEditBuilder*) clone;

- (ZMMessageEdit*) build;
- (ZMMessageEdit*) buildPartial;

- (ZMMessageEditBuilder*) mergeFrom:(ZMMessageEdit*) other;
- (ZMMessageEditBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMMessageEditBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasReplacingMessageId;
- (NSString*) replacingMessageId;
- (ZMMessageEditBuilder*) setReplacingMessageId:(NSString*) value;
- (ZMMessageEditBuilder*) clearReplacingMessageId;

- (BOOL) hasText;
- (ZMText*) text;
- (ZMMessageEditBuilder*) setText:(ZMText*) value;
- (ZMMessageEditBuilder*) setTextBuilder:(ZMTextBuilder*) builderForValue;
- (ZMMessageEditBuilder*) mergeText:(ZMText*) value;
- (ZMMessageEditBuilder*) clearText;
@end

#define Quote_quoted_message_id @"quotedMessageId"
#define Quote_quoted_message_sha256 @"quotedMessageSha256"
@interface ZMQuote : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasQuotedMessageId_:1;
  BOOL hasQuotedMessageSha256_:1;
  NSString* quotedMessageId;
  NSData* quotedMessageSha256;
}
- (BOOL) hasQuotedMessageId;
- (BOOL) hasQuotedMessageSha256;
@property (readonly, strong) NSString* quotedMessageId;
@property (readonly, strong) NSData* quotedMessageSha256;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMQuoteBuilder*) builder;
+ (ZMQuoteBuilder*) builder;
+ (ZMQuoteBuilder*) builderWithPrototype:(ZMQuote*) prototype;
- (ZMQuoteBuilder*) toBuilder;

+ (ZMQuote*) parseFromData:(NSData*) data;
+ (ZMQuote*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMQuote*) parseFromInputStream:(NSInputStream*) input;
+ (ZMQuote*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMQuote*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMQuote*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMQuoteBuilder : PBGeneratedMessageBuilder {
@private
  ZMQuote* resultQuote;
}

- (ZMQuote*) defaultInstance;

- (ZMQuoteBuilder*) clear;
- (ZMQuoteBuilder*) clone;

- (ZMQuote*) build;
- (ZMQuote*) buildPartial;

- (ZMQuoteBuilder*) mergeFrom:(ZMQuote*) other;
- (ZMQuoteBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMQuoteBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasQuotedMessageId;
- (NSString*) quotedMessageId;
- (ZMQuoteBuilder*) setQuotedMessageId:(NSString*) value;
- (ZMQuoteBuilder*) clearQuotedMessageId;

- (BOOL) hasQuotedMessageSha256;
- (NSData*) quotedMessageSha256;
- (ZMQuoteBuilder*) setQuotedMessageSha256:(NSData*) value;
- (ZMQuoteBuilder*) clearQuotedMessageSha256;
@end

#define Confirmation_type @"type"
#define Confirmation_first_message_id @"firstMessageId"
#define Confirmation_more_message_ids @"moreMessageIds"
@interface ZMConfirmation : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasFirstMessageId_:1;
  BOOL hasType_:1;
  NSString* firstMessageId;
  ZMConfirmationType type;
  NSMutableArray * moreMessageIdsArray;
}
- (BOOL) hasType;
- (BOOL) hasFirstMessageId;
@property (readonly) ZMConfirmationType type;
@property (readonly, strong) NSString* firstMessageId;
@property (readonly, strong) NSArray * moreMessageIds;
- (NSString*)moreMessageIdsAtIndex:(NSUInteger)index;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMConfirmationBuilder*) builder;
+ (ZMConfirmationBuilder*) builder;
+ (ZMConfirmationBuilder*) builderWithPrototype:(ZMConfirmation*) prototype;
- (ZMConfirmationBuilder*) toBuilder;

+ (ZMConfirmation*) parseFromData:(NSData*) data;
+ (ZMConfirmation*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMConfirmation*) parseFromInputStream:(NSInputStream*) input;
+ (ZMConfirmation*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMConfirmation*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMConfirmation*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMConfirmationBuilder : PBGeneratedMessageBuilder {
@private
  ZMConfirmation* resultConfirmation;
}

- (ZMConfirmation*) defaultInstance;

- (ZMConfirmationBuilder*) clear;
- (ZMConfirmationBuilder*) clone;

- (ZMConfirmation*) build;
- (ZMConfirmation*) buildPartial;

- (ZMConfirmationBuilder*) mergeFrom:(ZMConfirmation*) other;
- (ZMConfirmationBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMConfirmationBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasType;
- (ZMConfirmationType) type;
- (ZMConfirmationBuilder*) setType:(ZMConfirmationType) value;
- (ZMConfirmationBuilder*) clearType;

- (BOOL) hasFirstMessageId;
- (NSString*) firstMessageId;
- (ZMConfirmationBuilder*) setFirstMessageId:(NSString*) value;
- (ZMConfirmationBuilder*) clearFirstMessageId;

- (NSMutableArray *)moreMessageIds;
- (NSString*)moreMessageIdsAtIndex:(NSUInteger)index;
- (ZMConfirmationBuilder *)addMoreMessageIds:(NSString*)value;
- (ZMConfirmationBuilder *)setMoreMessageIdsArray:(NSArray *)array;
- (ZMConfirmationBuilder *)clearMoreMessageIds;
@end

#define Location_longitude @"longitude"
#define Location_latitude @"latitude"
#define Location_name @"name"
#define Location_zoom @"zoom"
#define Location_expects_read_confirmation @"expectsReadConfirmation"
#define Location_legal_hold_status @"legalHoldStatus"
@interface ZMLocation : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasExpectsReadConfirmation_:1;
  BOOL hasLongitude_:1;
  BOOL hasLatitude_:1;
  BOOL hasZoom_:1;
  BOOL hasName_:1;
  BOOL hasLegalHoldStatus_:1;
  BOOL expectsReadConfirmation_:1;
  Float32 longitude;
  Float32 latitude;
  SInt32 zoom;
  NSString* name;
  ZMLegalHoldStatus legalHoldStatus;
}
- (BOOL) hasLongitude;
- (BOOL) hasLatitude;
- (BOOL) hasName;
- (BOOL) hasZoom;
- (BOOL) hasExpectsReadConfirmation;
- (BOOL) hasLegalHoldStatus;
@property (readonly) Float32 longitude;
@property (readonly) Float32 latitude;
@property (readonly, strong) NSString* name;
@property (readonly) SInt32 zoom;
- (BOOL) expectsReadConfirmation;
@property (readonly) ZMLegalHoldStatus legalHoldStatus;

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

- (BOOL) hasExpectsReadConfirmation;
- (BOOL) expectsReadConfirmation;
- (ZMLocationBuilder*) setExpectsReadConfirmation:(BOOL) value;
- (ZMLocationBuilder*) clearExpectsReadConfirmation;

- (BOOL) hasLegalHoldStatus;
- (ZMLegalHoldStatus) legalHoldStatus;
- (ZMLocationBuilder*) setLegalHoldStatus:(ZMLegalHoldStatus) value;
- (ZMLocationBuilder*) clearLegalHoldStatus;
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
#define Asset_expects_read_confirmation @"expectsReadConfirmation"
#define Asset_legal_hold_status @"legalHoldStatus"
@interface ZMAsset : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasExpectsReadConfirmation_:1;
  BOOL hasOriginal_:1;
  BOOL hasUploaded_:1;
  BOOL hasPreview_:1;
  BOOL hasNotUploaded_:1;
  BOOL hasLegalHoldStatus_:1;
  BOOL expectsReadConfirmation_:1;
  ZMAssetOriginal* original;
  ZMAssetRemoteData* uploaded;
  ZMAssetPreview* preview;
  ZMAssetNotUploaded notUploaded;
  ZMLegalHoldStatus legalHoldStatus;
}
- (BOOL) hasOriginal;
- (BOOL) hasNotUploaded;
- (BOOL) hasUploaded;
- (BOOL) hasPreview;
- (BOOL) hasExpectsReadConfirmation;
- (BOOL) hasLegalHoldStatus;
@property (readonly, strong) ZMAssetOriginal* original;
@property (readonly) ZMAssetNotUploaded notUploaded;
@property (readonly, strong) ZMAssetRemoteData* uploaded;
@property (readonly, strong) ZMAssetPreview* preview;
- (BOOL) expectsReadConfirmation;
@property (readonly) ZMLegalHoldStatus legalHoldStatus;

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
#define Original_source @"source"
#define Original_caption @"caption"
@interface ZMAssetOriginal : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasSize_:1;
  BOOL hasMimeType_:1;
  BOOL hasName_:1;
  BOOL hasSource_:1;
  BOOL hasCaption_:1;
  BOOL hasImage_:1;
  BOOL hasVideo_:1;
  BOOL hasAudio_:1;
  UInt64 size;
  NSString* mimeType;
  NSString* name;
  NSString* source;
  NSString* caption;
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
- (BOOL) hasSource;
- (BOOL) hasCaption;
@property (readonly, strong) NSString* mimeType;
@property (readonly) UInt64 size;
@property (readonly, strong) NSString* name;
@property (readonly, strong) ZMAssetImageMetaData* image;
@property (readonly, strong) ZMAssetVideoMetaData* video;
@property (readonly, strong) ZMAssetAudioMetaData* audio;
@property (readonly, strong) NSString* source;
@property (readonly, strong) NSString* caption;

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

- (BOOL) hasSource;
- (NSString*) source;
- (ZMAssetOriginalBuilder*) setSource:(NSString*) value;
- (ZMAssetOriginalBuilder*) clearSource;

- (BOOL) hasCaption;
- (NSString*) caption;
- (ZMAssetOriginalBuilder*) setCaption:(NSString*) value;
- (ZMAssetOriginalBuilder*) clearCaption;
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
#define RemoteData_encryption @"encryption"
@interface ZMAssetRemoteData : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasAssetId_:1;
  BOOL hasAssetToken_:1;
  BOOL hasOtrKey_:1;
  BOOL hasSha256_:1;
  BOOL hasEncryption_:1;
  NSString* assetId;
  NSString* assetToken;
  NSData* otrKey;
  NSData* sha256;
  ZMEncryptionAlgorithm encryption;
}
- (BOOL) hasOtrKey;
- (BOOL) hasSha256;
- (BOOL) hasAssetId;
- (BOOL) hasAssetToken;
- (BOOL) hasEncryption;
@property (readonly, strong) NSData* otrKey;
@property (readonly, strong) NSData* sha256;
@property (readonly, strong) NSString* assetId;
@property (readonly, strong) NSString* assetToken;
@property (readonly) ZMEncryptionAlgorithm encryption;

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
- (NSString*) assetToken;
- (ZMAssetRemoteDataBuilder*) setAssetToken:(NSString*) value;
- (ZMAssetRemoteDataBuilder*) clearAssetToken;

- (BOOL) hasEncryption;
- (ZMEncryptionAlgorithm) encryption;
- (ZMAssetRemoteDataBuilder*) setEncryption:(ZMEncryptionAlgorithm) value;
- (ZMAssetRemoteDataBuilder*) clearEncryption;
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

- (BOOL) hasExpectsReadConfirmation;
- (BOOL) expectsReadConfirmation;
- (ZMAssetBuilder*) setExpectsReadConfirmation:(BOOL) value;
- (ZMAssetBuilder*) clearExpectsReadConfirmation;

- (BOOL) hasLegalHoldStatus;
- (ZMLegalHoldStatus) legalHoldStatus;
- (ZMAssetBuilder*) setLegalHoldStatus:(ZMLegalHoldStatus) value;
- (ZMAssetBuilder*) clearLegalHoldStatus;
@end

#define External_otr_key @"otrKey"
#define External_sha256 @"sha256"
#define External_encryption @"encryption"
@interface ZMExternal : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasOtrKey_:1;
  BOOL hasSha256_:1;
  BOOL hasEncryption_:1;
  NSData* otrKey;
  NSData* sha256;
  ZMEncryptionAlgorithm encryption;
}
- (BOOL) hasOtrKey;
- (BOOL) hasSha256;
- (BOOL) hasEncryption;
@property (readonly, strong) NSData* otrKey;
@property (readonly, strong) NSData* sha256;
@property (readonly) ZMEncryptionAlgorithm encryption;

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

- (BOOL) hasEncryption;
- (ZMEncryptionAlgorithm) encryption;
- (ZMExternalBuilder*) setEncryption:(ZMEncryptionAlgorithm) value;
- (ZMExternalBuilder*) clearEncryption;
@end

#define Reaction_emoji @"emoji"
#define Reaction_message_id @"messageId"
#define Reaction_legal_hold_status @"legalHoldStatus"
@interface ZMReaction : PBGeneratedMessage<GeneratedMessageProtocol> {
@private
  BOOL hasEmoji_:1;
  BOOL hasMessageId_:1;
  BOOL hasLegalHoldStatus_:1;
  NSString* emoji;
  NSString* messageId;
  ZMLegalHoldStatus legalHoldStatus;
}
- (BOOL) hasEmoji;
- (BOOL) hasMessageId;
- (BOOL) hasLegalHoldStatus;
@property (readonly, strong) NSString* emoji;
@property (readonly, strong) NSString* messageId;
@property (readonly) ZMLegalHoldStatus legalHoldStatus;

+ (instancetype) defaultInstance;
- (instancetype) defaultInstance;

- (BOOL) isInitialized;
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output;
- (ZMReactionBuilder*) builder;
+ (ZMReactionBuilder*) builder;
+ (ZMReactionBuilder*) builderWithPrototype:(ZMReaction*) prototype;
- (ZMReactionBuilder*) toBuilder;

+ (ZMReaction*) parseFromData:(NSData*) data;
+ (ZMReaction*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMReaction*) parseFromInputStream:(NSInputStream*) input;
+ (ZMReaction*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
+ (ZMReaction*) parseFromCodedInputStream:(PBCodedInputStream*) input;
+ (ZMReaction*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;
@end

@interface ZMReactionBuilder : PBGeneratedMessageBuilder {
@private
  ZMReaction* resultReaction;
}

- (ZMReaction*) defaultInstance;

- (ZMReactionBuilder*) clear;
- (ZMReactionBuilder*) clone;

- (ZMReaction*) build;
- (ZMReaction*) buildPartial;

- (ZMReactionBuilder*) mergeFrom:(ZMReaction*) other;
- (ZMReactionBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input;
- (ZMReactionBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry;

- (BOOL) hasEmoji;
- (NSString*) emoji;
- (ZMReactionBuilder*) setEmoji:(NSString*) value;
- (ZMReactionBuilder*) clearEmoji;

- (BOOL) hasMessageId;
- (NSString*) messageId;
- (ZMReactionBuilder*) setMessageId:(NSString*) value;
- (ZMReactionBuilder*) clearMessageId;

- (BOOL) hasLegalHoldStatus;
- (ZMLegalHoldStatus) legalHoldStatus;
- (ZMReactionBuilder*) setLegalHoldStatus:(ZMLegalHoldStatus) value;
- (ZMReactionBuilder*) clearLegalHoldStatus;
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
