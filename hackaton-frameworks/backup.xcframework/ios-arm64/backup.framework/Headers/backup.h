#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class BackupDataQualifiedID, BackupBackupDataConversation, BackupKotlinx_datetimeInstant, BackupBackupDataMessageText, BackupBackupMetadataCompanion, BackupBackupMetadata, BackupDataConversation, BackupDataQualifiedIDCompanion, BackupKotlinx_datetimeInstantCompanion, BackupKotlinThrowable, BackupKotlinArray<T>, BackupKotlinException, BackupKotlinRuntimeException, BackupKotlinIllegalStateException, BackupDataConversationType, BackupDataMutedConversationStatus, BackupDataConversationAccess, BackupDataConversationAccessRole, BackupDataConversationReceiptMode, BackupDataConversationVerificationStatus, BackupDataConversationLegalHoldStatus, BackupDataConversationCompanion, BackupKotlinx_serialization_coreSerializersModule, BackupKotlinx_serialization_coreSerialKind, BackupKotlinNothing, BackupKotlinEnumCompanion, BackupKotlinEnum<E>;

@protocol BackupBackupData, BackupBackupDataMessage, BackupKotlinx_serialization_coreKSerializer, BackupKotlinComparable, BackupKotlinx_serialization_coreEncoder, BackupKotlinx_serialization_coreSerialDescriptor, BackupKotlinx_serialization_coreSerializationStrategy, BackupKotlinx_serialization_coreDecoder, BackupKotlinx_serialization_coreDeserializationStrategy, BackupDataConversationProtocolInfo, BackupKotlinx_serialization_coreCompositeEncoder, BackupKotlinAnnotation, BackupKotlinx_serialization_coreCompositeDecoder, BackupKotlinIterator, BackupKotlinx_serialization_coreSerializersModuleCollector, BackupKotlinKClass, BackupKotlinKDeclarationContainer, BackupKotlinKAnnotatedElement, BackupKotlinKClassifier;

NS_ASSUME_NONNULL_BEGIN
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunknown-warning-option"
#pragma clang diagnostic ignored "-Wincompatible-property-type"
#pragma clang diagnostic ignored "-Wnullability"

#pragma push_macro("_Nullable_result")
#if !__has_feature(nullability_nullable_result)
#undef _Nullable_result
#define _Nullable_result _Nullable
#endif

__attribute__((swift_name("KotlinBase")))
@interface BackupBase : NSObject
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
+ (void)initialize __attribute__((objc_requires_super));
@end

@interface BackupBase (BackupBaseCopying) <NSCopying>
@end

__attribute__((swift_name("KotlinMutableSet")))
@interface BackupMutableSet<ObjectType> : NSMutableSet<ObjectType>
@end

__attribute__((swift_name("KotlinMutableDictionary")))
@interface BackupMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
@end

@interface NSError (NSErrorBackupKotlinException)
@property (readonly) id _Nullable kotlinException;
@end

__attribute__((swift_name("KotlinNumber")))
@interface BackupNumber : NSNumber
- (instancetype)initWithChar:(char)value __attribute__((unavailable));
- (instancetype)initWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
- (instancetype)initWithShort:(short)value __attribute__((unavailable));
- (instancetype)initWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
- (instancetype)initWithInt:(int)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
- (instancetype)initWithLong:(long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
- (instancetype)initWithLongLong:(long long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
- (instancetype)initWithFloat:(float)value __attribute__((unavailable));
- (instancetype)initWithDouble:(double)value __attribute__((unavailable));
- (instancetype)initWithBool:(BOOL)value __attribute__((unavailable));
- (instancetype)initWithInteger:(NSInteger)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
+ (instancetype)numberWithChar:(char)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
+ (instancetype)numberWithShort:(short)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
+ (instancetype)numberWithInt:(int)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
+ (instancetype)numberWithLong:(long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
+ (instancetype)numberWithLongLong:(long long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
+ (instancetype)numberWithFloat:(float)value __attribute__((unavailable));
+ (instancetype)numberWithDouble:(double)value __attribute__((unavailable));
+ (instancetype)numberWithBool:(BOOL)value __attribute__((unavailable));
+ (instancetype)numberWithInteger:(NSInteger)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
@end

__attribute__((swift_name("KotlinByte")))
@interface BackupByte : BackupNumber
- (instancetype)initWithChar:(char)value;
+ (instancetype)numberWithChar:(char)value;
@end

__attribute__((swift_name("KotlinUByte")))
@interface BackupUByte : BackupNumber
- (instancetype)initWithUnsignedChar:(unsigned char)value;
+ (instancetype)numberWithUnsignedChar:(unsigned char)value;
@end

__attribute__((swift_name("KotlinShort")))
@interface BackupShort : BackupNumber
- (instancetype)initWithShort:(short)value;
+ (instancetype)numberWithShort:(short)value;
@end

__attribute__((swift_name("KotlinUShort")))
@interface BackupUShort : BackupNumber
- (instancetype)initWithUnsignedShort:(unsigned short)value;
+ (instancetype)numberWithUnsignedShort:(unsigned short)value;
@end

__attribute__((swift_name("KotlinInt")))
@interface BackupInt : BackupNumber
- (instancetype)initWithInt:(int)value;
+ (instancetype)numberWithInt:(int)value;
@end

__attribute__((swift_name("KotlinUInt")))
@interface BackupUInt : BackupNumber
- (instancetype)initWithUnsignedInt:(unsigned int)value;
+ (instancetype)numberWithUnsignedInt:(unsigned int)value;
@end

__attribute__((swift_name("KotlinLong")))
@interface BackupLong : BackupNumber
- (instancetype)initWithLongLong:(long long)value;
+ (instancetype)numberWithLongLong:(long long)value;
@end

__attribute__((swift_name("KotlinULong")))
@interface BackupULong : BackupNumber
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value;
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value;
@end

__attribute__((swift_name("KotlinFloat")))
@interface BackupFloat : BackupNumber
- (instancetype)initWithFloat:(float)value;
+ (instancetype)numberWithFloat:(float)value;
@end

__attribute__((swift_name("KotlinDouble")))
@interface BackupDouble : BackupNumber
- (instancetype)initWithDouble:(double)value;
+ (instancetype)numberWithDouble:(double)value;
@end

__attribute__((swift_name("KotlinBoolean")))
@interface BackupBoolean : BackupNumber
- (instancetype)initWithBool:(BOOL)value;
+ (instancetype)numberWithBool:(BOOL)value;
@end

__attribute__((swift_name("BackupData")))
@protocol BackupBackupData
@required
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupDataConversation")))
@interface BackupBackupDataConversation : BackupBase <BackupBackupData>
- (instancetype)initWithConversationId:(BackupDataQualifiedID *)conversationId name:(NSString *)name __attribute__((swift_name("init(conversationId:name:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupDataConversation *)doCopyConversationId:(BackupDataQualifiedID *)conversationId name:(NSString *)name __attribute__((swift_name("doCopy(conversationId:name:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BackupDataQualifiedID *conversationId __attribute__((swift_name("conversationId")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@end

__attribute__((swift_name("BackupDataMessage")))
@protocol BackupBackupDataMessage <BackupBackupData>
@required
@property (readonly) BackupDataQualifiedID *conversationId __attribute__((swift_name("conversationId")));
@property (readonly) NSString *messageId __attribute__((swift_name("messageId")));
@property (readonly) NSString *senderClientId __attribute__((swift_name("senderClientId")));
@property (readonly) BackupDataQualifiedID *senderUserId __attribute__((swift_name("senderUserId")));
@property (readonly) BackupKotlinx_datetimeInstant *time __attribute__((swift_name("time")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupDataMessageText")))
@interface BackupBackupDataMessageText : BackupBase <BackupBackupDataMessage>
- (instancetype)initWithMessageId:(NSString *)messageId conversationId:(BackupDataQualifiedID *)conversationId senderUserId:(BackupDataQualifiedID *)senderUserId time:(BackupKotlinx_datetimeInstant *)time senderClientId:(NSString *)senderClientId textValue:(NSString *)textValue __attribute__((swift_name("init(messageId:conversationId:senderUserId:time:senderClientId:textValue:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupDataMessageText *)doCopyMessageId:(NSString *)messageId conversationId:(BackupDataQualifiedID *)conversationId senderUserId:(BackupDataQualifiedID *)senderUserId time:(BackupKotlinx_datetimeInstant *)time senderClientId:(NSString *)senderClientId textValue:(NSString *)textValue __attribute__((swift_name("doCopy(messageId:conversationId:senderUserId:time:senderClientId:textValue:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BackupDataQualifiedID *conversationId __attribute__((swift_name("conversationId")));
@property (readonly) NSString *messageId __attribute__((swift_name("messageId")));
@property (readonly) NSString *senderClientId __attribute__((swift_name("senderClientId")));
@property (readonly) BackupDataQualifiedID *senderUserId __attribute__((swift_name("senderUserId")));
@property (readonly) NSString *textValue __attribute__((swift_name("textValue")));
@property (readonly) BackupKotlinx_datetimeInstant *time __attribute__((swift_name("time")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupMetadata")))
@interface BackupBackupMetadata : BackupBase
- (instancetype)initWithPlatform:(NSString *)platform version:(NSString *)version userId:(NSString *)userId creationTime:(NSString *)creationTime clientId:(NSString * _Nullable)clientId __attribute__((swift_name("init(platform:version:userId:creationTime:clientId:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) BackupBackupMetadataCompanion *companion __attribute__((swift_name("companion")));
- (BackupBackupMetadata *)doCopyPlatform:(NSString *)platform version:(NSString *)version userId:(NSString *)userId creationTime:(NSString *)creationTime clientId:(NSString * _Nullable)clientId __attribute__((swift_name("doCopy(platform:version:userId:creationTime:clientId:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="client_id")
*/
@property (readonly) NSString * _Nullable clientId __attribute__((swift_name("clientId")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="creation_time")
*/
@property (readonly) NSString *creationTime __attribute__((swift_name("creationTime")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="platform")
*/
@property (readonly) NSString *platform __attribute__((swift_name("platform")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="user_id")
*/
@property (readonly) NSString *userId __attribute__((swift_name("userId")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="version")
*/
@property (readonly) NSString *version __attribute__((swift_name("version")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupMetadata.Companion")))
@interface BackupBackupMetadataCompanion : BackupBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) BackupBackupMetadataCompanion *shared __attribute__((swift_name("shared")));
- (id<BackupKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MPBackupExporter")))
@interface BackupMPBackupExporter : BackupBase
- (instancetype)initWithExportPath:(NSString *)exportPath metaData:(BackupBackupMetadata *)metaData __attribute__((swift_name("init(exportPath:metaData:)"))) __attribute__((objc_designated_initializer));
- (void)addMessage:(id<BackupBackupDataMessage>)message __attribute__((swift_name("add(message:)")));
- (void)addConversation:(BackupDataConversation *)conversation __attribute__((swift_name("add(conversation:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)flushToFileWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("flushToFile(completionHandler:)")));
@property (readonly) BackupBackupMetadata *metaData __attribute__((swift_name("metaData")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MPBackupImporter")))
@interface BackupMPBackupImporter : BackupBase
- (instancetype)initWithPathToFile:(NSString *)pathToFile selfUserDomain:(NSString *)selfUserDomain __attribute__((swift_name("init(pathToFile:selfUserDomain:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)importOnDataImported:(void (^)(id<BackupBackupData>))onDataImported completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("import(onDataImported:completionHandler:)")));
@property (readonly) NSString *selfUserDomain __attribute__((swift_name("selfUserDomain")));
@end

@interface BackupBackupMetadata (Extensions)
- (BOOL)isWebBackup __attribute__((swift_name("isWebBackup()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DataQualifiedID")))
@interface BackupDataQualifiedID : BackupBase
- (instancetype)initWithValue:(NSString *)value domain:(NSString *)domain __attribute__((swift_name("init(value:domain:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) BackupDataQualifiedIDCompanion *companion __attribute__((swift_name("companion")));
- (BackupDataQualifiedID *)doCopyValue:(NSString *)value domain:(NSString *)domain __attribute__((swift_name("doCopy(value:domain:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)toLogString __attribute__((swift_name("toLogString()")));
- (id)toPlainID __attribute__((swift_name("toPlainID()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="domain")
*/
@property (readonly) NSString *domain __attribute__((swift_name("domain")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="id")
*/
@property (readonly) NSString *value __attribute__((swift_name("value")));
@end

__attribute__((swift_name("KotlinComparable")))
@protocol BackupKotlinComparable
@required
- (int32_t)compareToOther:(id _Nullable)other __attribute__((swift_name("compareTo(other:)")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable(with=NormalClass(value=kotlinx/datetime/serializers/InstantIso8601Serializer))
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Kotlinx_datetimeInstant")))
@interface BackupKotlinx_datetimeInstant : BackupBase <BackupKotlinComparable>
@property (class, readonly, getter=companion) BackupKotlinx_datetimeInstantCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(BackupKotlinx_datetimeInstant *)other __attribute__((swift_name("compareTo(other:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (BackupKotlinx_datetimeInstant *)minusDuration:(int64_t)duration __attribute__((swift_name("minus(duration:)")));
- (int64_t)minusOther:(BackupKotlinx_datetimeInstant *)other __attribute__((swift_name("minus(other:)")));
- (BackupKotlinx_datetimeInstant *)plusDuration:(int64_t)duration __attribute__((swift_name("plus(duration:)")));
- (int64_t)toEpochMilliseconds __attribute__((swift_name("toEpochMilliseconds()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t epochSeconds __attribute__((swift_name("epochSeconds")));
@property (readonly) int32_t nanosecondsOfSecond __attribute__((swift_name("nanosecondsOfSecond")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerializationStrategy")))
@protocol BackupKotlinx_serialization_coreSerializationStrategy
@required
- (void)serializeEncoder:(id<BackupKotlinx_serialization_coreEncoder>)encoder value:(id _Nullable)value __attribute__((swift_name("serialize(encoder:value:)")));
@property (readonly) id<BackupKotlinx_serialization_coreSerialDescriptor> descriptor __attribute__((swift_name("descriptor")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreDeserializationStrategy")))
@protocol BackupKotlinx_serialization_coreDeserializationStrategy
@required
- (id _Nullable)deserializeDecoder:(id<BackupKotlinx_serialization_coreDecoder>)decoder __attribute__((swift_name("deserialize(decoder:)")));
@property (readonly) id<BackupKotlinx_serialization_coreSerialDescriptor> descriptor __attribute__((swift_name("descriptor")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreKSerializer")))
@protocol BackupKotlinx_serialization_coreKSerializer <BackupKotlinx_serialization_coreSerializationStrategy, BackupKotlinx_serialization_coreDeserializationStrategy>
@required
@end

__attribute__((swift_name("KotlinThrowable")))
@interface BackupKotlinThrowable : BackupBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(BackupKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(BackupKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));

/**
 * @note annotations
 *   kotlin.experimental.ExperimentalNativeApi
*/
- (BackupKotlinArray<NSString *> *)getStackTrace __attribute__((swift_name("getStackTrace()")));
- (void)printStackTrace __attribute__((swift_name("printStackTrace()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BackupKotlinThrowable * _Nullable cause __attribute__((swift_name("cause")));
@property (readonly) NSString * _Nullable message __attribute__((swift_name("message")));
- (NSError *)asError __attribute__((swift_name("asError()")));
@end

__attribute__((swift_name("KotlinException")))
@interface BackupKotlinException : BackupKotlinThrowable
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(BackupKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(BackupKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
@end

__attribute__((swift_name("KotlinRuntimeException")))
@interface BackupKotlinRuntimeException : BackupKotlinException
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(BackupKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(BackupKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
@end

__attribute__((swift_name("KotlinIllegalStateException")))
@interface BackupKotlinIllegalStateException : BackupKotlinRuntimeException
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(BackupKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(BackupKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
@end


/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
__attribute__((swift_name("KotlinCancellationException")))
@interface BackupKotlinCancellationException : BackupKotlinIllegalStateException
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(BackupKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(BackupKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DataConversation")))
@interface BackupDataConversation : BackupBase
- (instancetype)initWithId:(BackupDataQualifiedID *)id name:(NSString * _Nullable)name type:(BackupDataConversationType *)type teamId:(id _Nullable)teamId protocol:(id<BackupDataConversationProtocolInfo>)protocol mutedStatus:(BackupDataMutedConversationStatus *)mutedStatus removedBy:(BackupDataQualifiedID * _Nullable)removedBy lastNotificationDate:(BackupKotlinx_datetimeInstant * _Nullable)lastNotificationDate lastModifiedDate:(BackupKotlinx_datetimeInstant * _Nullable)lastModifiedDate lastReadDate:(BackupKotlinx_datetimeInstant *)lastReadDate access:(NSArray<BackupDataConversationAccess *> *)access accessRole:(NSArray<BackupDataConversationAccessRole *> *)accessRole creatorId:(NSString * _Nullable)creatorId receiptMode:(BackupDataConversationReceiptMode *)receiptMode messageTimer:(id _Nullable)messageTimer userMessageTimer:(id _Nullable)userMessageTimer archived:(BOOL)archived archivedDateTime:(BackupKotlinx_datetimeInstant * _Nullable)archivedDateTime mlsVerificationStatus:(BackupDataConversationVerificationStatus *)mlsVerificationStatus proteusVerificationStatus:(BackupDataConversationVerificationStatus *)proteusVerificationStatus legalHoldStatus:(BackupDataConversationLegalHoldStatus *)legalHoldStatus __attribute__((swift_name("init(id:name:type:teamId:protocol:mutedStatus:removedBy:lastNotificationDate:lastModifiedDate:lastReadDate:access:accessRole:creatorId:receiptMode:messageTimer:userMessageTimer:archived:archivedDateTime:mlsVerificationStatus:proteusVerificationStatus:legalHoldStatus:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) BackupDataConversationCompanion *companion __attribute__((swift_name("companion")));
- (BackupDataConversation *)doCopyId:(BackupDataQualifiedID *)id name:(NSString * _Nullable)name type:(BackupDataConversationType *)type teamId:(id _Nullable)teamId protocol:(id<BackupDataConversationProtocolInfo>)protocol mutedStatus:(BackupDataMutedConversationStatus *)mutedStatus removedBy:(BackupDataQualifiedID * _Nullable)removedBy lastNotificationDate:(BackupKotlinx_datetimeInstant * _Nullable)lastNotificationDate lastModifiedDate:(BackupKotlinx_datetimeInstant * _Nullable)lastModifiedDate lastReadDate:(BackupKotlinx_datetimeInstant *)lastReadDate access:(NSArray<BackupDataConversationAccess *> *)access accessRole:(NSArray<BackupDataConversationAccessRole *> *)accessRole creatorId:(NSString * _Nullable)creatorId receiptMode:(BackupDataConversationReceiptMode *)receiptMode messageTimer:(id _Nullable)messageTimer userMessageTimer:(id _Nullable)userMessageTimer archived:(BOOL)archived archivedDateTime:(BackupKotlinx_datetimeInstant * _Nullable)archivedDateTime mlsVerificationStatus:(BackupDataConversationVerificationStatus *)mlsVerificationStatus proteusVerificationStatus:(BackupDataConversationVerificationStatus *)proteusVerificationStatus legalHoldStatus:(BackupDataConversationLegalHoldStatus *)legalHoldStatus __attribute__((swift_name("doCopy(id:name:type:teamId:protocol:mutedStatus:removedBy:lastNotificationDate:lastModifiedDate:lastReadDate:access:accessRole:creatorId:receiptMode:messageTimer:userMessageTimer:archived:archivedDateTime:mlsVerificationStatus:proteusVerificationStatus:legalHoldStatus:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (BOOL)isGuestAllowed __attribute__((swift_name("isGuestAllowed()")));
- (BOOL)isNonTeamMemberAllowed __attribute__((swift_name("isNonTeamMemberAllowed()")));
- (BOOL)isServicesAllowed __attribute__((swift_name("isServicesAllowed()")));
- (BOOL)isTeamGroup __attribute__((swift_name("isTeamGroup()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<BackupDataConversationAccess *> *access __attribute__((swift_name("access")));
@property (readonly) NSArray<BackupDataConversationAccessRole *> *accessRole __attribute__((swift_name("accessRole")));
@property (readonly) BOOL archived __attribute__((swift_name("archived")));
@property (readonly) BackupKotlinx_datetimeInstant * _Nullable archivedDateTime __attribute__((swift_name("archivedDateTime")));
@property (readonly) NSString * _Nullable creatorId __attribute__((swift_name("creatorId")));
@property (readonly) BackupDataQualifiedID *id __attribute__((swift_name("id")));
@property (readonly) BackupKotlinx_datetimeInstant * _Nullable lastModifiedDate __attribute__((swift_name("lastModifiedDate")));
@property (readonly) BackupKotlinx_datetimeInstant * _Nullable lastNotificationDate __attribute__((swift_name("lastNotificationDate")));
@property (readonly) BackupKotlinx_datetimeInstant *lastReadDate __attribute__((swift_name("lastReadDate")));
@property (readonly) BackupDataConversationLegalHoldStatus *legalHoldStatus __attribute__((swift_name("legalHoldStatus")));
@property (readonly) id _Nullable messageTimer __attribute__((swift_name("messageTimer")));
@property (readonly) BackupDataConversationVerificationStatus *mlsVerificationStatus __attribute__((swift_name("mlsVerificationStatus")));
@property (readonly) BackupDataMutedConversationStatus *mutedStatus __attribute__((swift_name("mutedStatus")));
@property (readonly) NSString * _Nullable name __attribute__((swift_name("name")));
@property (readonly) BackupDataConversationVerificationStatus *proteusVerificationStatus __attribute__((swift_name("proteusVerificationStatus")));
@property (readonly) id<BackupDataConversationProtocolInfo> protocol __attribute__((swift_name("protocol")));
@property (readonly) BackupDataConversationReceiptMode *receiptMode __attribute__((swift_name("receiptMode")));
@property (readonly) BackupDataQualifiedID * _Nullable removedBy __attribute__((swift_name("removedBy")));
@property (readonly) BOOL supportsUnreadMessageCount __attribute__((swift_name("supportsUnreadMessageCount")));
@property (readonly) id _Nullable teamId __attribute__((swift_name("teamId")));
@property (readonly) BackupDataConversationType *type __attribute__((swift_name("type")));
@property (readonly) id _Nullable userMessageTimer __attribute__((swift_name("userMessageTimer")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DataQualifiedID.Companion")))
@interface BackupDataQualifiedIDCompanion : BackupBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) BackupDataQualifiedIDCompanion *shared __attribute__((swift_name("shared")));
- (id<BackupKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Kotlinx_datetimeInstant.Companion")))
@interface BackupKotlinx_datetimeInstantCompanion : BackupBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) BackupKotlinx_datetimeInstantCompanion *shared __attribute__((swift_name("shared")));
- (BackupKotlinx_datetimeInstant *)fromEpochMillisecondsEpochMilliseconds:(int64_t)epochMilliseconds __attribute__((swift_name("fromEpochMilliseconds(epochMilliseconds:)")));
- (BackupKotlinx_datetimeInstant *)fromEpochSecondsEpochSeconds:(int64_t)epochSeconds nanosecondAdjustment:(int32_t)nanosecondAdjustment __attribute__((swift_name("fromEpochSeconds(epochSeconds:nanosecondAdjustment:)")));
- (BackupKotlinx_datetimeInstant *)fromEpochSecondsEpochSeconds:(int64_t)epochSeconds nanosecondAdjustment_:(int64_t)nanosecondAdjustment __attribute__((swift_name("fromEpochSeconds(epochSeconds:nanosecondAdjustment_:)")));
- (BackupKotlinx_datetimeInstant *)now __attribute__((swift_name("now()"))) __attribute__((unavailable("Use Clock.System.now() instead")));
- (BackupKotlinx_datetimeInstant *)parseIsoString:(NSString *)isoString __attribute__((swift_name("parse(isoString:)")));
- (id<BackupKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@property (readonly) BackupKotlinx_datetimeInstant *DISTANT_FUTURE __attribute__((swift_name("DISTANT_FUTURE")));
@property (readonly) BackupKotlinx_datetimeInstant *DISTANT_PAST __attribute__((swift_name("DISTANT_PAST")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreEncoder")))
@protocol BackupKotlinx_serialization_coreEncoder
@required
- (id<BackupKotlinx_serialization_coreCompositeEncoder>)beginCollectionDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor collectionSize:(int32_t)collectionSize __attribute__((swift_name("beginCollection(descriptor:collectionSize:)")));
- (id<BackupKotlinx_serialization_coreCompositeEncoder>)beginStructureDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("beginStructure(descriptor:)")));
- (void)encodeBooleanValue:(BOOL)value __attribute__((swift_name("encodeBoolean(value:)")));
- (void)encodeByteValue:(int8_t)value __attribute__((swift_name("encodeByte(value:)")));
- (void)encodeCharValue:(unichar)value __attribute__((swift_name("encodeChar(value:)")));
- (void)encodeDoubleValue:(double)value __attribute__((swift_name("encodeDouble(value:)")));
- (void)encodeEnumEnumDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)enumDescriptor index:(int32_t)index __attribute__((swift_name("encodeEnum(enumDescriptor:index:)")));
- (void)encodeFloatValue:(float)value __attribute__((swift_name("encodeFloat(value:)")));
- (id<BackupKotlinx_serialization_coreEncoder>)encodeInlineDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("encodeInline(descriptor:)")));
- (void)encodeIntValue:(int32_t)value __attribute__((swift_name("encodeInt(value:)")));
- (void)encodeLongValue:(int64_t)value __attribute__((swift_name("encodeLong(value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNotNullMark __attribute__((swift_name("encodeNotNullMark()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNull __attribute__((swift_name("encodeNull()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNullableSerializableValueSerializer:(id<BackupKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeNullableSerializableValue(serializer:value:)")));
- (void)encodeSerializableValueSerializer:(id<BackupKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeSerializableValue(serializer:value:)")));
- (void)encodeShortValue:(int16_t)value __attribute__((swift_name("encodeShort(value:)")));
- (void)encodeStringValue:(NSString *)value __attribute__((swift_name("encodeString(value:)")));
@property (readonly) BackupKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerialDescriptor")))
@protocol BackupKotlinx_serialization_coreSerialDescriptor
@required

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (NSArray<id<BackupKotlinAnnotation>> *)getElementAnnotationsIndex:(int32_t)index __attribute__((swift_name("getElementAnnotations(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<BackupKotlinx_serialization_coreSerialDescriptor>)getElementDescriptorIndex:(int32_t)index __attribute__((swift_name("getElementDescriptor(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (int32_t)getElementIndexName:(NSString *)name __attribute__((swift_name("getElementIndex(name:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (NSString *)getElementNameIndex:(int32_t)index __attribute__((swift_name("getElementName(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)isElementOptionalIndex:(int32_t)index __attribute__((swift_name("isElementOptional(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) NSArray<id<BackupKotlinAnnotation>> *annotations __attribute__((swift_name("annotations")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) int32_t elementsCount __attribute__((swift_name("elementsCount")));
@property (readonly) BOOL isInline __attribute__((swift_name("isInline")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) BOOL isNullable __attribute__((swift_name("isNullable")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) BackupKotlinx_serialization_coreSerialKind *kind __attribute__((swift_name("kind")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) NSString *serialName __attribute__((swift_name("serialName")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreDecoder")))
@protocol BackupKotlinx_serialization_coreDecoder
@required
- (id<BackupKotlinx_serialization_coreCompositeDecoder>)beginStructureDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("beginStructure(descriptor:)")));
- (BOOL)decodeBoolean __attribute__((swift_name("decodeBoolean()")));
- (int8_t)decodeByte __attribute__((swift_name("decodeByte()")));
- (unichar)decodeChar __attribute__((swift_name("decodeChar()")));
- (double)decodeDouble __attribute__((swift_name("decodeDouble()")));
- (int32_t)decodeEnumEnumDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)enumDescriptor __attribute__((swift_name("decodeEnum(enumDescriptor:)")));
- (float)decodeFloat __attribute__((swift_name("decodeFloat()")));
- (id<BackupKotlinx_serialization_coreDecoder>)decodeInlineDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeInline(descriptor:)")));
- (int32_t)decodeInt __attribute__((swift_name("decodeInt()")));
- (int64_t)decodeLong __attribute__((swift_name("decodeLong()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)decodeNotNullMark __attribute__((swift_name("decodeNotNullMark()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BackupKotlinNothing * _Nullable)decodeNull __attribute__((swift_name("decodeNull()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id _Nullable)decodeNullableSerializableValueDeserializer:(id<BackupKotlinx_serialization_coreDeserializationStrategy>)deserializer __attribute__((swift_name("decodeNullableSerializableValue(deserializer:)")));
- (id _Nullable)decodeSerializableValueDeserializer:(id<BackupKotlinx_serialization_coreDeserializationStrategy>)deserializer __attribute__((swift_name("decodeSerializableValue(deserializer:)")));
- (int16_t)decodeShort __attribute__((swift_name("decodeShort()")));
- (NSString *)decodeString __attribute__((swift_name("decodeString()")));
@property (readonly) BackupKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinArray")))
@interface BackupKotlinArray<T> : BackupBase
+ (instancetype)arrayWithSize:(int32_t)size init:(T _Nullable (^)(BackupInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (T _Nullable)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (id<BackupKotlinIterator>)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(T _Nullable)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("KotlinEnum")))
@interface BackupKotlinEnum<E> : BackupBase <BackupKotlinComparable>
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) BackupKotlinEnumCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(E)other __attribute__((swift_name("compareTo(other:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) int32_t ordinal __attribute__((swift_name("ordinal")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DataConversation.Type_")))
@interface BackupDataConversationType : BackupKotlinEnum<BackupDataConversationType *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) BackupDataConversationType *self __attribute__((swift_name("self")));
@property (class, readonly) BackupDataConversationType *oneOnOne __attribute__((swift_name("oneOnOne")));
@property (class, readonly) BackupDataConversationType *group __attribute__((swift_name("group")));
@property (class, readonly) BackupDataConversationType *connectionPending __attribute__((swift_name("connectionPending")));
+ (BackupKotlinArray<BackupDataConversationType *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<BackupDataConversationType *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((swift_name("DataConversationProtocolInfo")))
@protocol BackupDataConversationProtocolInfo
@required
- (NSString *)name_ __attribute__((swift_name("name()")));
- (NSDictionary<NSString *, id> *)toLogMap __attribute__((swift_name("toLogMap()")));
@end

__attribute__((swift_name("DataMutedConversationStatus")))
@interface BackupDataMutedConversationStatus : BackupBase
@property (readonly) int32_t status __attribute__((swift_name("status")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DataConversation.Access")))
@interface BackupDataConversationAccess : BackupKotlinEnum<BackupDataConversationAccess *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) BackupDataConversationAccess *private_ __attribute__((swift_name("private_")));
@property (class, readonly) BackupDataConversationAccess *invite __attribute__((swift_name("invite")));
@property (class, readonly) BackupDataConversationAccess *selfInvite __attribute__((swift_name("selfInvite")));
@property (class, readonly) BackupDataConversationAccess *link __attribute__((swift_name("link")));
@property (class, readonly) BackupDataConversationAccess *code __attribute__((swift_name("code")));
+ (BackupKotlinArray<BackupDataConversationAccess *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<BackupDataConversationAccess *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DataConversation.AccessRole")))
@interface BackupDataConversationAccessRole : BackupKotlinEnum<BackupDataConversationAccessRole *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) BackupDataConversationAccessRole *teamMember __attribute__((swift_name("teamMember")));
@property (class, readonly) BackupDataConversationAccessRole *nonTeamMember __attribute__((swift_name("nonTeamMember")));
@property (class, readonly) BackupDataConversationAccessRole *guest __attribute__((swift_name("guest")));
@property (class, readonly) BackupDataConversationAccessRole *service __attribute__((swift_name("service")));
@property (class, readonly) BackupDataConversationAccessRole *external __attribute__((swift_name("external")));
+ (BackupKotlinArray<BackupDataConversationAccessRole *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<BackupDataConversationAccessRole *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DataConversation.ReceiptMode")))
@interface BackupDataConversationReceiptMode : BackupKotlinEnum<BackupDataConversationReceiptMode *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) BackupDataConversationReceiptMode *disabled __attribute__((swift_name("disabled")));
@property (class, readonly) BackupDataConversationReceiptMode *enabled __attribute__((swift_name("enabled")));
+ (BackupKotlinArray<BackupDataConversationReceiptMode *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<BackupDataConversationReceiptMode *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DataConversation.VerificationStatus")))
@interface BackupDataConversationVerificationStatus : BackupKotlinEnum<BackupDataConversationVerificationStatus *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) BackupDataConversationVerificationStatus *verified __attribute__((swift_name("verified")));
@property (class, readonly) BackupDataConversationVerificationStatus *notVerified __attribute__((swift_name("notVerified")));
@property (class, readonly) BackupDataConversationVerificationStatus *degraded __attribute__((swift_name("degraded")));
+ (BackupKotlinArray<BackupDataConversationVerificationStatus *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<BackupDataConversationVerificationStatus *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DataConversation.LegalHoldStatus")))
@interface BackupDataConversationLegalHoldStatus : BackupKotlinEnum<BackupDataConversationLegalHoldStatus *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) BackupDataConversationLegalHoldStatus *enabled __attribute__((swift_name("enabled")));
@property (class, readonly) BackupDataConversationLegalHoldStatus *disabled __attribute__((swift_name("disabled")));
@property (class, readonly) BackupDataConversationLegalHoldStatus *degraded __attribute__((swift_name("degraded")));
@property (class, readonly) BackupDataConversationLegalHoldStatus *unknown __attribute__((swift_name("unknown")));
+ (BackupKotlinArray<BackupDataConversationLegalHoldStatus *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<BackupDataConversationLegalHoldStatus *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DataConversation.Companion")))
@interface BackupDataConversationCompanion : BackupBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) BackupDataConversationCompanion *shared __attribute__((swift_name("shared")));
- (NSSet<BackupDataConversationAccess *> *)accessForGuestsAllowed:(BOOL)guestsAllowed __attribute__((swift_name("accessFor(guestsAllowed:)")));
- (NSSet<BackupDataConversationAccessRole *> *)accessRolesForGuestAllowed:(BOOL)guestAllowed servicesAllowed:(BOOL)servicesAllowed nonTeamMembersAllowed:(BOOL)nonTeamMembersAllowed __attribute__((swift_name("accessRolesFor(guestAllowed:servicesAllowed:nonTeamMembersAllowed:)")));
@property (readonly) NSSet<BackupDataConversationAccess *> *defaultGroupAccess __attribute__((swift_name("defaultGroupAccess")));
@property (readonly) NSSet<BackupDataConversationAccessRole *> *defaultGroupAccessRoles __attribute__((swift_name("defaultGroupAccessRoles")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreCompositeEncoder")))
@protocol BackupKotlinx_serialization_coreCompositeEncoder
@required
- (void)encodeBooleanElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(BOOL)value __attribute__((swift_name("encodeBooleanElement(descriptor:index:value:)")));
- (void)encodeByteElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int8_t)value __attribute__((swift_name("encodeByteElement(descriptor:index:value:)")));
- (void)encodeCharElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(unichar)value __attribute__((swift_name("encodeCharElement(descriptor:index:value:)")));
- (void)encodeDoubleElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(double)value __attribute__((swift_name("encodeDoubleElement(descriptor:index:value:)")));
- (void)encodeFloatElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(float)value __attribute__((swift_name("encodeFloatElement(descriptor:index:value:)")));
- (id<BackupKotlinx_serialization_coreEncoder>)encodeInlineElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("encodeInlineElement(descriptor:index:)")));
- (void)encodeIntElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int32_t)value __attribute__((swift_name("encodeIntElement(descriptor:index:value:)")));
- (void)encodeLongElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int64_t)value __attribute__((swift_name("encodeLongElement(descriptor:index:value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNullableSerializableElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index serializer:(id<BackupKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeNullableSerializableElement(descriptor:index:serializer:value:)")));
- (void)encodeSerializableElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index serializer:(id<BackupKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeSerializableElement(descriptor:index:serializer:value:)")));
- (void)encodeShortElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int16_t)value __attribute__((swift_name("encodeShortElement(descriptor:index:value:)")));
- (void)encodeStringElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(NSString *)value __attribute__((swift_name("encodeStringElement(descriptor:index:value:)")));
- (void)endStructureDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("endStructure(descriptor:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)shouldEncodeElementDefaultDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("shouldEncodeElementDefault(descriptor:index:)")));
@property (readonly) BackupKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerializersModule")))
@interface BackupKotlinx_serialization_coreSerializersModule : BackupBase

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)dumpToCollector:(id<BackupKotlinx_serialization_coreSerializersModuleCollector>)collector __attribute__((swift_name("dumpTo(collector:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<BackupKotlinx_serialization_coreKSerializer> _Nullable)getContextualKClass:(id<BackupKotlinKClass>)kClass typeArgumentsSerializers:(NSArray<id<BackupKotlinx_serialization_coreKSerializer>> *)typeArgumentsSerializers __attribute__((swift_name("getContextual(kClass:typeArgumentsSerializers:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<BackupKotlinx_serialization_coreSerializationStrategy> _Nullable)getPolymorphicBaseClass:(id<BackupKotlinKClass>)baseClass value:(id)value __attribute__((swift_name("getPolymorphic(baseClass:value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<BackupKotlinx_serialization_coreDeserializationStrategy> _Nullable)getPolymorphicBaseClass:(id<BackupKotlinKClass>)baseClass serializedClassName:(NSString * _Nullable)serializedClassName __attribute__((swift_name("getPolymorphic(baseClass:serializedClassName:)")));
@end

__attribute__((swift_name("KotlinAnnotation")))
@protocol BackupKotlinAnnotation
@required
@end


/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
__attribute__((swift_name("Kotlinx_serialization_coreSerialKind")))
@interface BackupKotlinx_serialization_coreSerialKind : BackupBase
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreCompositeDecoder")))
@protocol BackupKotlinx_serialization_coreCompositeDecoder
@required
- (BOOL)decodeBooleanElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeBooleanElement(descriptor:index:)")));
- (int8_t)decodeByteElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeByteElement(descriptor:index:)")));
- (unichar)decodeCharElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeCharElement(descriptor:index:)")));
- (int32_t)decodeCollectionSizeDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeCollectionSize(descriptor:)")));
- (double)decodeDoubleElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeDoubleElement(descriptor:index:)")));
- (int32_t)decodeElementIndexDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeElementIndex(descriptor:)")));
- (float)decodeFloatElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeFloatElement(descriptor:index:)")));
- (id<BackupKotlinx_serialization_coreDecoder>)decodeInlineElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeInlineElement(descriptor:index:)")));
- (int32_t)decodeIntElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeIntElement(descriptor:index:)")));
- (int64_t)decodeLongElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeLongElement(descriptor:index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id _Nullable)decodeNullableSerializableElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index deserializer:(id<BackupKotlinx_serialization_coreDeserializationStrategy>)deserializer previousValue:(id _Nullable)previousValue __attribute__((swift_name("decodeNullableSerializableElement(descriptor:index:deserializer:previousValue:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)decodeSequentially __attribute__((swift_name("decodeSequentially()")));
- (id _Nullable)decodeSerializableElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index deserializer:(id<BackupKotlinx_serialization_coreDeserializationStrategy>)deserializer previousValue:(id _Nullable)previousValue __attribute__((swift_name("decodeSerializableElement(descriptor:index:deserializer:previousValue:)")));
- (int16_t)decodeShortElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeShortElement(descriptor:index:)")));
- (NSString *)decodeStringElementDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeStringElement(descriptor:index:)")));
- (void)endStructureDescriptor:(id<BackupKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("endStructure(descriptor:)")));
@property (readonly) BackupKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinNothing")))
@interface BackupKotlinNothing : BackupBase
@end

__attribute__((swift_name("KotlinIterator")))
@protocol BackupKotlinIterator
@required
- (BOOL)hasNext __attribute__((swift_name("hasNext()")));
- (id _Nullable)next __attribute__((swift_name("next()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinEnumCompanion")))
@interface BackupKotlinEnumCompanion : BackupBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) BackupKotlinEnumCompanion *shared __attribute__((swift_name("shared")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
__attribute__((swift_name("Kotlinx_serialization_coreSerializersModuleCollector")))
@protocol BackupKotlinx_serialization_coreSerializersModuleCollector
@required
- (void)contextualKClass:(id<BackupKotlinKClass>)kClass provider:(id<BackupKotlinx_serialization_coreKSerializer> (^)(NSArray<id<BackupKotlinx_serialization_coreKSerializer>> *))provider __attribute__((swift_name("contextual(kClass:provider:)")));
- (void)contextualKClass:(id<BackupKotlinKClass>)kClass serializer:(id<BackupKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("contextual(kClass:serializer:)")));
- (void)polymorphicBaseClass:(id<BackupKotlinKClass>)baseClass actualClass:(id<BackupKotlinKClass>)actualClass actualSerializer:(id<BackupKotlinx_serialization_coreKSerializer>)actualSerializer __attribute__((swift_name("polymorphic(baseClass:actualClass:actualSerializer:)")));
- (void)polymorphicDefaultBaseClass:(id<BackupKotlinKClass>)baseClass defaultDeserializerProvider:(id<BackupKotlinx_serialization_coreDeserializationStrategy> _Nullable (^)(NSString * _Nullable))defaultDeserializerProvider __attribute__((swift_name("polymorphicDefault(baseClass:defaultDeserializerProvider:)"))) __attribute__((deprecated("Deprecated in favor of function with more precise name: polymorphicDefaultDeserializer")));
- (void)polymorphicDefaultDeserializerBaseClass:(id<BackupKotlinKClass>)baseClass defaultDeserializerProvider:(id<BackupKotlinx_serialization_coreDeserializationStrategy> _Nullable (^)(NSString * _Nullable))defaultDeserializerProvider __attribute__((swift_name("polymorphicDefaultDeserializer(baseClass:defaultDeserializerProvider:)")));
- (void)polymorphicDefaultSerializerBaseClass:(id<BackupKotlinKClass>)baseClass defaultSerializerProvider:(id<BackupKotlinx_serialization_coreSerializationStrategy> _Nullable (^)(id))defaultSerializerProvider __attribute__((swift_name("polymorphicDefaultSerializer(baseClass:defaultSerializerProvider:)")));
@end

__attribute__((swift_name("KotlinKDeclarationContainer")))
@protocol BackupKotlinKDeclarationContainer
@required
@end

__attribute__((swift_name("KotlinKAnnotatedElement")))
@protocol BackupKotlinKAnnotatedElement
@required
@end


/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.1")
*/
__attribute__((swift_name("KotlinKClassifier")))
@protocol BackupKotlinKClassifier
@required
@end

__attribute__((swift_name("KotlinKClass")))
@protocol BackupKotlinKClass <BackupKotlinKDeclarationContainer, BackupKotlinKAnnotatedElement, BackupKotlinKClassifier>
@required

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.1")
*/
- (BOOL)isInstanceValue:(id _Nullable)value __attribute__((swift_name("isInstance(value:)")));
@property (readonly) NSString * _Nullable qualifiedName __attribute__((swift_name("qualifiedName")));
@property (readonly) NSString * _Nullable simpleName __attribute__((swift_name("simpleName")));
@end

#pragma pop_macro("_Nullable_result")
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
