#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class BackupMPBackup, BackupBackupQualifiedId, BackupBackupConversation, BackupBackupMetadata, BackupBackupUser, BackupKotlinArray<T>, BackupBackupMessage, BackupKotlinx_datetimeInstant, BackupBackupDateTime, BackupBackupMessageContent, BackupKotlinByteArray, BackupBackupMessageContentAssetEncryptionAlgorithm, BackupBackupMessageContentAssetAssetMetadata, BackupBackupMessageContentAsset, BackupBackupMessageContentAssetAssetMetadataAudio, BackupBackupMessageContentAssetAssetMetadataGeneric, BackupBackupMessageContentAssetAssetMetadataImage, BackupBackupMessageContentAssetAssetMetadataVideo, BackupKotlinEnumCompanion, BackupKotlinEnum<E>, BackupBackupMessageContentLocation, BackupBackupMessageContentText, BackupBackupQualifiedIdCompanion, BackupCommonMPBackupExporter, BackupBackupImportResult, BackupBackupImportResultParsingFailure, BackupBackupData, BackupBackupImportResultSuccess, BackupCommonMPBackupImporter, BackupKotlinx_datetimeInstantCompanion, BackupKotlinByteIterator, BackupKotlinx_serialization_coreSerializersModule, BackupKotlinx_serialization_coreSerialKind, BackupKotlinNothing;

@protocol BackupKotlinComparable, BackupKotlinx_serialization_coreKSerializer, BackupKotlinIterator, BackupKotlinx_serialization_coreEncoder, BackupKotlinx_serialization_coreSerialDescriptor, BackupKotlinx_serialization_coreSerializationStrategy, BackupKotlinx_serialization_coreDecoder, BackupKotlinx_serialization_coreDeserializationStrategy, BackupKotlinx_serialization_coreCompositeEncoder, BackupKotlinAnnotation, BackupKotlinx_serialization_coreCompositeDecoder, BackupKotlinx_serialization_coreSerializersModuleCollector, BackupKotlinKClass, BackupKotlinKDeclarationContainer, BackupKotlinKAnnotatedElement, BackupKotlinKClassifier;

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

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MPBackup")))
@interface BackupMPBackup : BackupBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)mPBackup __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) BackupMPBackup *shared __attribute__((swift_name("shared")));
@property (readonly) NSString *ZIP_ENTRY_DATA __attribute__((swift_name("ZIP_ENTRY_DATA")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupConversation")))
@interface BackupBackupConversation : BackupBase
- (instancetype)initWithId:(BackupBackupQualifiedId *)id name:(NSString *)name __attribute__((swift_name("init(id:name:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupConversation *)doCopyId:(BackupBackupQualifiedId *)id name:(NSString *)name __attribute__((swift_name("doCopy(id:name:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BackupBackupQualifiedId *id __attribute__((swift_name("id")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupData")))
@interface BackupBackupData : BackupBase
- (instancetype)initWithMetadata:(BackupBackupMetadata *)metadata users:(BackupKotlinArray<BackupBackupUser *> *)users conversations:(BackupKotlinArray<BackupBackupConversation *> *)conversations messages:(BackupKotlinArray<BackupBackupMessage *> *)messages __attribute__((swift_name("init(metadata:users:conversations:messages:)"))) __attribute__((objc_designated_initializer));
@property (readonly) NSArray<BackupBackupConversation *> *conversations __attribute__((swift_name("conversations")));
@property (readonly) BackupKotlinArray<BackupBackupConversation *> *conversations_ __attribute__((swift_private));
@property (readonly) NSArray<BackupBackupMessage *> *messages __attribute__((swift_name("messages")));
@property (readonly) BackupKotlinArray<BackupBackupMessage *> *messages_ __attribute__((swift_private));
@property (readonly) BackupBackupMetadata *metadata __attribute__((swift_name("metadata")));
@property (readonly) NSArray<BackupBackupUser *> *users __attribute__((swift_name("users")));
@property (readonly) BackupKotlinArray<BackupBackupUser *> *users_ __attribute__((swift_private));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupDateTime")))
@interface BackupBackupDateTime : BackupBase
- (instancetype)initWithInstant:(BackupKotlinx_datetimeInstant *)instant __attribute__((swift_name("init(instant:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupDateTime *)doCopyInstant:(BackupKotlinx_datetimeInstant *)instant __attribute__((swift_name("doCopy(instant:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BackupKotlinx_datetimeInstant *instant __attribute__((swift_name("instant")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupMessage")))
@interface BackupBackupMessage : BackupBase
- (instancetype)initWithId:(NSString *)id conversationId:(BackupBackupQualifiedId *)conversationId senderUserId:(BackupBackupQualifiedId *)senderUserId senderClientId:(NSString *)senderClientId creationDate:(BackupBackupDateTime *)creationDate content:(BackupBackupMessageContent *)content webPrimaryKey:(BackupInt * _Nullable)webPrimaryKey __attribute__((swift_name("init(id:conversationId:senderUserId:senderClientId:creationDate:content:webPrimaryKey:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupMessage *)doCopyId:(NSString *)id conversationId:(BackupBackupQualifiedId *)conversationId senderUserId:(BackupBackupQualifiedId *)senderUserId senderClientId:(NSString *)senderClientId creationDate:(BackupBackupDateTime *)creationDate content:(BackupBackupMessageContent *)content webPrimaryKey:(BackupInt * _Nullable)webPrimaryKey __attribute__((swift_name("doCopy(id:conversationId:senderUserId:senderClientId:creationDate:content:webPrimaryKey:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BackupBackupMessageContent *content __attribute__((swift_name("content")));
@property (readonly) BackupBackupQualifiedId *conversationId __attribute__((swift_name("conversationId")));
@property (readonly) BackupBackupDateTime *creationDate __attribute__((swift_name("creationDate")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) NSString *senderClientId __attribute__((swift_name("senderClientId")));
@property (readonly) BackupBackupQualifiedId *senderUserId __attribute__((swift_name("senderUserId")));
@property (readonly) BackupInt * _Nullable webPrimaryKey __attribute__((swift_name("webPrimaryKey"))) __attribute__((deprecated("Used only by the Webteam in order to simplify debugging")));
@end

__attribute__((swift_name("BackupMessageContent")))
@interface BackupBackupMessageContent : BackupBase
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupMessageContent.Asset")))
@interface BackupBackupMessageContentAsset : BackupBackupMessageContent
- (instancetype)initWithMimeType:(NSString *)mimeType size:(int32_t)size name:(NSString * _Nullable)name otrKey:(BackupKotlinByteArray *)otrKey sha256:(BackupKotlinByteArray *)sha256 assetId:(NSString *)assetId assetToken:(NSString * _Nullable)assetToken assetDomain:(NSString * _Nullable)assetDomain encryption:(BackupBackupMessageContentAssetEncryptionAlgorithm * _Nullable)encryption metaData:(BackupBackupMessageContentAssetAssetMetadata * _Nullable)metaData __attribute__((swift_name("init(mimeType:size:name:otrKey:sha256:assetId:assetToken:assetDomain:encryption:metaData:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupMessageContentAsset *)doCopyMimeType:(NSString *)mimeType size:(int32_t)size name:(NSString * _Nullable)name otrKey:(BackupKotlinByteArray *)otrKey sha256:(BackupKotlinByteArray *)sha256 assetId:(NSString *)assetId assetToken:(NSString * _Nullable)assetToken assetDomain:(NSString * _Nullable)assetDomain encryption:(BackupBackupMessageContentAssetEncryptionAlgorithm * _Nullable)encryption metaData:(BackupBackupMessageContentAssetAssetMetadata * _Nullable)metaData __attribute__((swift_name("doCopy(mimeType:size:name:otrKey:sha256:assetId:assetToken:assetDomain:encryption:metaData:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable assetDomain __attribute__((swift_name("assetDomain")));
@property (readonly) NSString *assetId __attribute__((swift_name("assetId")));
@property (readonly) NSString * _Nullable assetToken __attribute__((swift_name("assetToken")));
@property (readonly) BackupBackupMessageContentAssetEncryptionAlgorithm * _Nullable encryption __attribute__((swift_name("encryption")));
@property (readonly) BackupBackupMessageContentAssetAssetMetadata * _Nullable metaData __attribute__((swift_name("metaData")));
@property (readonly) NSString *mimeType __attribute__((swift_name("mimeType")));
@property (readonly) NSString * _Nullable name __attribute__((swift_name("name")));
@property (readonly) BackupKotlinByteArray *otrKey __attribute__((swift_name("otrKey")));
@property (readonly) BackupKotlinByteArray *sha256 __attribute__((swift_name("sha256")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((swift_name("BackupMessageContent.AssetAssetMetadata")))
@interface BackupBackupMessageContentAssetAssetMetadata : BackupBase
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupMessageContent.AssetAssetMetadataAudio")))
@interface BackupBackupMessageContentAssetAssetMetadataAudio : BackupBackupMessageContentAssetAssetMetadata
- (instancetype)initWithNormalization:(BackupKotlinByteArray * _Nullable)normalization duration:(BackupLong * _Nullable)duration __attribute__((swift_name("init(normalization:duration:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupMessageContentAssetAssetMetadataAudio *)doCopyNormalization:(BackupKotlinByteArray * _Nullable)normalization duration:(BackupLong * _Nullable)duration __attribute__((swift_name("doCopy(normalization:duration:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BackupLong * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) BackupKotlinByteArray * _Nullable normalization __attribute__((swift_name("normalization")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupMessageContent.AssetAssetMetadataGeneric")))
@interface BackupBackupMessageContentAssetAssetMetadataGeneric : BackupBackupMessageContentAssetAssetMetadata
- (instancetype)initWithName:(NSString * _Nullable)name __attribute__((swift_name("init(name:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupMessageContentAssetAssetMetadataGeneric *)doCopyName:(NSString * _Nullable)name __attribute__((swift_name("doCopy(name:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable name __attribute__((swift_name("name")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupMessageContent.AssetAssetMetadataImage")))
@interface BackupBackupMessageContentAssetAssetMetadataImage : BackupBackupMessageContentAssetAssetMetadata
- (instancetype)initWithWidth:(int32_t)width height:(int32_t)height tag:(NSString * _Nullable)tag __attribute__((swift_name("init(width:height:tag:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupMessageContentAssetAssetMetadataImage *)doCopyWidth:(int32_t)width height:(int32_t)height tag:(NSString * _Nullable)tag __attribute__((swift_name("doCopy(width:height:tag:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t height __attribute__((swift_name("height")));
@property (readonly) NSString * _Nullable tag __attribute__((swift_name("tag")));
@property (readonly) int32_t width __attribute__((swift_name("width")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupMessageContent.AssetAssetMetadataVideo")))
@interface BackupBackupMessageContentAssetAssetMetadataVideo : BackupBackupMessageContentAssetAssetMetadata
- (instancetype)initWithWidth:(BackupInt * _Nullable)width height:(BackupInt * _Nullable)height duration:(BackupLong * _Nullable)duration __attribute__((swift_name("init(width:height:duration:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupMessageContentAssetAssetMetadataVideo *)doCopyWidth:(BackupInt * _Nullable)width height:(BackupInt * _Nullable)height duration:(BackupLong * _Nullable)duration __attribute__((swift_name("doCopy(width:height:duration:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BackupLong * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) BackupInt * _Nullable height __attribute__((swift_name("height")));
@property (readonly) BackupInt * _Nullable width __attribute__((swift_name("width")));
@end

__attribute__((swift_name("KotlinComparable")))
@protocol BackupKotlinComparable
@required
- (int32_t)compareToOther:(id _Nullable)other __attribute__((swift_name("compareTo(other:)")));
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
__attribute__((swift_name("BackupMessageContent.AssetEncryptionAlgorithm")))
@interface BackupBackupMessageContentAssetEncryptionAlgorithm : BackupKotlinEnum<BackupBackupMessageContentAssetEncryptionAlgorithm *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) BackupBackupMessageContentAssetEncryptionAlgorithm *aesGcm __attribute__((swift_name("aesGcm")));
@property (class, readonly) BackupBackupMessageContentAssetEncryptionAlgorithm *aesCbc __attribute__((swift_name("aesCbc")));
+ (BackupKotlinArray<BackupBackupMessageContentAssetEncryptionAlgorithm *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<BackupBackupMessageContentAssetEncryptionAlgorithm *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupMessageContent.Location")))
@interface BackupBackupMessageContentLocation : BackupBackupMessageContent
- (instancetype)initWithLongitude:(float)longitude latitude:(float)latitude name:(NSString * _Nullable)name zoom:(BackupInt * _Nullable)zoom __attribute__((swift_name("init(longitude:latitude:name:zoom:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupMessageContentLocation *)doCopyLongitude:(float)longitude latitude:(float)latitude name:(NSString * _Nullable)name zoom:(BackupInt * _Nullable)zoom __attribute__((swift_name("doCopy(longitude:latitude:name:zoom:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) float latitude __attribute__((swift_name("latitude")));
@property (readonly) float longitude __attribute__((swift_name("longitude")));
@property (readonly) NSString * _Nullable name __attribute__((swift_name("name")));
@property (readonly) BackupInt * _Nullable zoom __attribute__((swift_name("zoom")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupMessageContent.Text")))
@interface BackupBackupMessageContentText : BackupBackupMessageContent
- (instancetype)initWithText:(NSString *)text __attribute__((swift_name("init(text:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupMessageContentText *)doCopyText:(NSString *)text __attribute__((swift_name("doCopy(text:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *text __attribute__((swift_name("text")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupMetadata")))
@interface BackupBackupMetadata : BackupBase
- (instancetype)initWithVersion:(NSString *)version userId:(BackupBackupQualifiedId *)userId creationTime:(BackupBackupDateTime *)creationTime clientId:(NSString * _Nullable)clientId __attribute__((swift_name("init(version:userId:creationTime:clientId:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupMetadata *)doCopyVersion:(NSString *)version userId:(BackupBackupQualifiedId *)userId creationTime:(BackupBackupDateTime *)creationTime clientId:(NSString * _Nullable)clientId __attribute__((swift_name("doCopy(version:userId:creationTime:clientId:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable clientId __attribute__((swift_name("clientId")));
@property (readonly) BackupBackupDateTime *creationTime __attribute__((swift_name("creationTime")));
@property (readonly) BackupBackupQualifiedId *userId __attribute__((swift_name("userId")));
@property (readonly) NSString *version __attribute__((swift_name("version")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupQualifiedId")))
@interface BackupBackupQualifiedId : BackupBase
- (instancetype)initWithId:(NSString *)id domain:(NSString *)domain __attribute__((swift_name("init(id:domain:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) BackupBackupQualifiedIdCompanion *companion __attribute__((swift_name("companion")));
- (BackupBackupQualifiedId *)doCopyId:(NSString *)id domain:(NSString *)domain __attribute__((swift_name("doCopy(id:domain:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
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
@property (readonly) NSString *id __attribute__((swift_name("id")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupQualifiedId.Companion")))
@interface BackupBackupQualifiedIdCompanion : BackupBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) BackupBackupQualifiedIdCompanion *shared __attribute__((swift_name("shared")));
- (BackupBackupQualifiedId * _Nullable)fromEncodedStringId:(NSString *)id __attribute__((swift_name("fromEncodedString(id:)")));
- (id<BackupKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupUser")))
@interface BackupBackupUser : BackupBase
- (instancetype)initWithId:(BackupBackupQualifiedId *)id name:(NSString *)name handle:(NSString *)handle __attribute__((swift_name("init(id:name:handle:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupUser *)doCopyId:(BackupBackupQualifiedId *)id name:(NSString *)name handle:(NSString *)handle __attribute__((swift_name("doCopy(id:name:handle:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *handle __attribute__((swift_name("handle")));
@property (readonly) BackupBackupQualifiedId *id __attribute__((swift_name("id")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@end

__attribute__((swift_name("CommonMPBackupExporter")))
@interface BackupCommonMPBackupExporter : BackupBase
- (instancetype)initWithSelfUserId:(BackupBackupQualifiedId *)selfUserId __attribute__((swift_name("init(selfUserId:)"))) __attribute__((objc_designated_initializer));
- (void)addConversation:(BackupBackupConversation *)conversation __attribute__((swift_name("add(conversation:)")));
- (void)addMessage:(BackupBackupMessage *)message __attribute__((swift_name("add(message:)")));
- (void)addUser:(BackupBackupUser *)user __attribute__((swift_name("add(user:)")));
- (BackupKotlinByteArray *)serialize __attribute__((swift_private));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MPBackupExporter")))
@interface BackupMPBackupExporter : BackupCommonMPBackupExporter
- (instancetype)initWithSelfUserId:(BackupBackupQualifiedId *)selfUserId __attribute__((swift_name("init(selfUserId:)"))) __attribute__((objc_designated_initializer));
@end

__attribute__((swift_name("BackupImportResult")))
@interface BackupBackupImportResult : BackupBase
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupImportResult.ParsingFailure")))
@interface BackupBackupImportResultParsingFailure : BackupBackupImportResult
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)parsingFailure __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) BackupBackupImportResultParsingFailure *shared __attribute__((swift_name("shared")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupImportResult.Success")))
@interface BackupBackupImportResultSuccess : BackupBackupImportResult
- (instancetype)initWithBackupData:(BackupBackupData *)backupData __attribute__((swift_name("init(backupData:)"))) __attribute__((objc_designated_initializer));
- (BackupBackupImportResultSuccess *)doCopyBackupData:(BackupBackupData *)backupData __attribute__((swift_name("doCopy(backupData:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BackupBackupData *backupData __attribute__((swift_name("backupData")));
@end

__attribute__((swift_name("CommonMPBackupImporter")))
@interface BackupCommonMPBackupImporter : BackupBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (BackupBackupImportResult *)importBackupData:(BackupKotlinByteArray *)data __attribute__((swift_private));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MPBackupImporter")))
@interface BackupMPBackupImporter : BackupCommonMPBackupImporter
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (BackupBackupImportResult *)importFileMultiplatformBackupFilePath:(NSString *)multiplatformBackupFilePath __attribute__((swift_name("importFile(multiplatformBackupFilePath:)")));
@end

@interface BackupBackupDateTime (Extensions)
- (int64_t)toLongMilliseconds __attribute__((swift_name("toLongMilliseconds()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("BackupDateTimeKt")))
@interface BackupBackupDateTimeKt : BackupBase
+ (BackupBackupDateTime *)BackupDateTimeTimestampMillis:(int64_t)timestampMillis __attribute__((swift_name("BackupDateTime(timestampMillis:)")));
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

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinByteArray")))
@interface BackupKotlinByteArray : BackupBase
+ (instancetype)arrayWithSize:(int32_t)size __attribute__((swift_name("init(size:)")));
+ (instancetype)arrayWithSize:(int32_t)size init:(BackupByte *(^)(BackupInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (int8_t)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (BackupKotlinByteIterator *)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(int8_t)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinEnumCompanion")))
@interface BackupKotlinEnumCompanion : BackupBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) BackupKotlinEnumCompanion *shared __attribute__((swift_name("shared")));
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

__attribute__((swift_name("KotlinIterator")))
@protocol BackupKotlinIterator
@required
- (BOOL)hasNext __attribute__((swift_name("hasNext()")));
- (id _Nullable)next __attribute__((swift_name("next()")));
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

__attribute__((swift_name("KotlinByteIterator")))
@interface BackupKotlinByteIterator : BackupBase <BackupKotlinIterator>
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (BackupByte *)next __attribute__((swift_name("next()")));
- (int8_t)nextByte __attribute__((swift_name("nextByte()")));
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
