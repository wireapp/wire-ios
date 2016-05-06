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


#import "Messages.pb.h"
// @@protoc_insertion_point(imports)

@implementation ZMMessagesRoot
static PBExtensionRegistry* extensionRegistry = nil;
+ (PBExtensionRegistry*) extensionRegistry {
  return extensionRegistry;
}

+ (void) initialize {
  if (self == [ZMMessagesRoot class]) {
    PBMutableExtensionRegistry* registry = [PBMutableExtensionRegistry registry];
    [self registerAllExtensions:registry];
    [ObjectivecDescriptorRoot registerAllExtensions:registry];
    extensionRegistry = registry;
  }
}
+ (void) registerAllExtensions:(PBMutableExtensionRegistry*) registry {
}
@end

BOOL ZMLikeActionIsValidValue(ZMLikeAction value) {
  switch (value) {
    case ZMLikeActionLIKE:
    case ZMLikeActionUNLIKE:
      return YES;
    default:
      return NO;
  }
}
NSString *NSStringFromZMLikeAction(ZMLikeAction value) {
  switch (value) {
    case ZMLikeActionLIKE:
      return @"ZMLikeActionLIKE";
    case ZMLikeActionUNLIKE:
      return @"ZMLikeActionUNLIKE";
    default:
      return nil;
  }
}

BOOL ZMClientActionIsValidValue(ZMClientAction value) {
  switch (value) {
    case ZMClientActionRESETSESSION:
      return YES;
    default:
      return NO;
  }
}
NSString *NSStringFromZMClientAction(ZMClientAction value) {
  switch (value) {
    case ZMClientActionRESETSESSION:
      return @"ZMClientActionRESETSESSION";
    default:
      return nil;
  }
}

@interface ZMGenericMessage ()
@property (strong) NSString* messageId;
@property (strong) ZMText* text;
@property (strong) ZMImageAsset* image;
@property (strong) ZMKnock* knock;
@property ZMLikeAction liking;
@property (strong) ZMLastRead* lastRead;
@property (strong) ZMCleared* cleared;
@property (strong) ZMExternal* external;
@property ZMClientAction clientAction;
@property (strong) ZMCalling* calling;
@property (strong) ZMAsset* asset;
@property (strong) ZMMsgDeleted* deleted;
@end

@implementation ZMGenericMessage

- (BOOL) hasMessageId {
  return !!hasMessageId_;
}
- (void) setHasMessageId:(BOOL) _value_ {
  hasMessageId_ = !!_value_;
}
@synthesize messageId;
- (BOOL) hasText {
  return !!hasText_;
}
- (void) setHasText:(BOOL) _value_ {
  hasText_ = !!_value_;
}
@synthesize text;
- (BOOL) hasImage {
  return !!hasImage_;
}
- (void) setHasImage:(BOOL) _value_ {
  hasImage_ = !!_value_;
}
@synthesize image;
- (BOOL) hasKnock {
  return !!hasKnock_;
}
- (void) setHasKnock:(BOOL) _value_ {
  hasKnock_ = !!_value_;
}
@synthesize knock;
- (BOOL) hasLiking {
  return !!hasLiking_;
}
- (void) setHasLiking:(BOOL) _value_ {
  hasLiking_ = !!_value_;
}
@synthesize liking;
- (BOOL) hasLastRead {
  return !!hasLastRead_;
}
- (void) setHasLastRead:(BOOL) _value_ {
  hasLastRead_ = !!_value_;
}
@synthesize lastRead;
- (BOOL) hasCleared {
  return !!hasCleared_;
}
- (void) setHasCleared:(BOOL) _value_ {
  hasCleared_ = !!_value_;
}
@synthesize cleared;
- (BOOL) hasExternal {
  return !!hasExternal_;
}
- (void) setHasExternal:(BOOL) _value_ {
  hasExternal_ = !!_value_;
}
@synthesize external;
- (BOOL) hasClientAction {
  return !!hasClientAction_;
}
- (void) setHasClientAction:(BOOL) _value_ {
  hasClientAction_ = !!_value_;
}
@synthesize clientAction;
- (BOOL) hasCalling {
  return !!hasCalling_;
}
- (void) setHasCalling:(BOOL) _value_ {
  hasCalling_ = !!_value_;
}
@synthesize calling;
- (BOOL) hasAsset {
  return !!hasAsset_;
}
- (void) setHasAsset:(BOOL) _value_ {
  hasAsset_ = !!_value_;
}
@synthesize asset;
- (BOOL) hasDeleted {
  return !!hasDeleted_;
}
- (void) setHasDeleted:(BOOL) _value_ {
  hasDeleted_ = !!_value_;
}
@synthesize deleted;
- (instancetype) init {
  if ((self = [super init])) {
    self.messageId = @"";
    self.text = [ZMText defaultInstance];
    self.image = [ZMImageAsset defaultInstance];
    self.knock = [ZMKnock defaultInstance];
    self.liking = ZMLikeActionLIKE;
    self.lastRead = [ZMLastRead defaultInstance];
    self.cleared = [ZMCleared defaultInstance];
    self.external = [ZMExternal defaultInstance];
    self.clientAction = ZMClientActionRESETSESSION;
    self.calling = [ZMCalling defaultInstance];
    self.asset = [ZMAsset defaultInstance];
    self.deleted = [ZMMsgDeleted defaultInstance];
  }
  return self;
}
static ZMGenericMessage* defaultZMGenericMessageInstance = nil;
+ (void) initialize {
  if (self == [ZMGenericMessage class]) {
    defaultZMGenericMessageInstance = [[ZMGenericMessage alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMGenericMessageInstance;
}
- (instancetype) defaultInstance {
  return defaultZMGenericMessageInstance;
}
- (BOOL) isInitialized {
  if (!self.hasMessageId) {
    return NO;
  }
  if (self.hasText) {
    if (!self.text.isInitialized) {
      return NO;
    }
  }
  if (self.hasImage) {
    if (!self.image.isInitialized) {
      return NO;
    }
  }
  if (self.hasKnock) {
    if (!self.knock.isInitialized) {
      return NO;
    }
  }
  if (self.hasLastRead) {
    if (!self.lastRead.isInitialized) {
      return NO;
    }
  }
  if (self.hasCleared) {
    if (!self.cleared.isInitialized) {
      return NO;
    }
  }
  if (self.hasExternal) {
    if (!self.external.isInitialized) {
      return NO;
    }
  }
  if (self.hasCalling) {
    if (!self.calling.isInitialized) {
      return NO;
    }
  }
  if (self.hasAsset) {
    if (!self.asset.isInitialized) {
      return NO;
    }
  }
  if (self.hasDeleted) {
    if (!self.deleted.isInitialized) {
      return NO;
    }
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasMessageId) {
    [output writeString:1 value:self.messageId];
  }
  if (self.hasText) {
    [output writeMessage:2 value:self.text];
  }
  if (self.hasImage) {
    [output writeMessage:3 value:self.image];
  }
  if (self.hasKnock) {
    [output writeMessage:4 value:self.knock];
  }
  if (self.hasLiking) {
    [output writeEnum:5 value:self.liking];
  }
  if (self.hasLastRead) {
    [output writeMessage:6 value:self.lastRead];
  }
  if (self.hasCleared) {
    [output writeMessage:7 value:self.cleared];
  }
  if (self.hasExternal) {
    [output writeMessage:8 value:self.external];
  }
  if (self.hasClientAction) {
    [output writeEnum:9 value:self.clientAction];
  }
  if (self.hasCalling) {
    [output writeMessage:10 value:self.calling];
  }
  if (self.hasAsset) {
    [output writeMessage:11 value:self.asset];
  }
  if (self.hasDeleted) {
    [output writeMessage:12 value:self.deleted];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasMessageId) {
    size_ += computeStringSize(1, self.messageId);
  }
  if (self.hasText) {
    size_ += computeMessageSize(2, self.text);
  }
  if (self.hasImage) {
    size_ += computeMessageSize(3, self.image);
  }
  if (self.hasKnock) {
    size_ += computeMessageSize(4, self.knock);
  }
  if (self.hasLiking) {
    size_ += computeEnumSize(5, self.liking);
  }
  if (self.hasLastRead) {
    size_ += computeMessageSize(6, self.lastRead);
  }
  if (self.hasCleared) {
    size_ += computeMessageSize(7, self.cleared);
  }
  if (self.hasExternal) {
    size_ += computeMessageSize(8, self.external);
  }
  if (self.hasClientAction) {
    size_ += computeEnumSize(9, self.clientAction);
  }
  if (self.hasCalling) {
    size_ += computeMessageSize(10, self.calling);
  }
  if (self.hasAsset) {
    size_ += computeMessageSize(11, self.asset);
  }
  if (self.hasDeleted) {
    size_ += computeMessageSize(12, self.deleted);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMGenericMessage*) parseFromData:(NSData*) data {
  return (ZMGenericMessage*)[[[ZMGenericMessage builder] mergeFromData:data] build];
}
+ (ZMGenericMessage*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMGenericMessage*)[[[ZMGenericMessage builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMGenericMessage*) parseFromInputStream:(NSInputStream*) input {
  return (ZMGenericMessage*)[[[ZMGenericMessage builder] mergeFromInputStream:input] build];
}
+ (ZMGenericMessage*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMGenericMessage*)[[[ZMGenericMessage builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMGenericMessage*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMGenericMessage*)[[[ZMGenericMessage builder] mergeFromCodedInputStream:input] build];
}
+ (ZMGenericMessage*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMGenericMessage*)[[[ZMGenericMessage builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMGenericMessageBuilder*) builder {
  return [[ZMGenericMessageBuilder alloc] init];
}
+ (ZMGenericMessageBuilder*) builderWithPrototype:(ZMGenericMessage*) prototype {
  return [[ZMGenericMessage builder] mergeFrom:prototype];
}
- (ZMGenericMessageBuilder*) builder {
  return [ZMGenericMessage builder];
}
- (ZMGenericMessageBuilder*) toBuilder {
  return [ZMGenericMessage builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasMessageId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"messageId", self.messageId];
  }
  if (self.hasText) {
    [output appendFormat:@"%@%@ {\n", indent, @"text"];
    [self.text writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasImage) {
    [output appendFormat:@"%@%@ {\n", indent, @"image"];
    [self.image writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasKnock) {
    [output appendFormat:@"%@%@ {\n", indent, @"knock"];
    [self.knock writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasLiking) {
    [output appendFormat:@"%@%@: %@\n", indent, @"liking", NSStringFromZMLikeAction(self.liking)];
  }
  if (self.hasLastRead) {
    [output appendFormat:@"%@%@ {\n", indent, @"lastRead"];
    [self.lastRead writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasCleared) {
    [output appendFormat:@"%@%@ {\n", indent, @"cleared"];
    [self.cleared writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasExternal) {
    [output appendFormat:@"%@%@ {\n", indent, @"external"];
    [self.external writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasClientAction) {
    [output appendFormat:@"%@%@: %@\n", indent, @"clientAction", NSStringFromZMClientAction(self.clientAction)];
  }
  if (self.hasCalling) {
    [output appendFormat:@"%@%@ {\n", indent, @"calling"];
    [self.calling writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasAsset) {
    [output appendFormat:@"%@%@ {\n", indent, @"asset"];
    [self.asset writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasDeleted) {
    [output appendFormat:@"%@%@ {\n", indent, @"deleted"];
    [self.deleted writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasMessageId) {
    [dictionary setObject: self.messageId forKey: @"messageId"];
  }
  if (self.hasText) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.text storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"text"];
  }
  if (self.hasImage) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.image storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"image"];
  }
  if (self.hasKnock) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.knock storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"knock"];
  }
  if (self.hasLiking) {
    [dictionary setObject: @(self.liking) forKey: @"liking"];
  }
  if (self.hasLastRead) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.lastRead storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"lastRead"];
  }
  if (self.hasCleared) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.cleared storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"cleared"];
  }
  if (self.hasExternal) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.external storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"external"];
  }
  if (self.hasClientAction) {
    [dictionary setObject: @(self.clientAction) forKey: @"clientAction"];
  }
  if (self.hasCalling) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.calling storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"calling"];
  }
  if (self.hasAsset) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.asset storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"asset"];
  }
  if (self.hasDeleted) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.deleted storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"deleted"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMGenericMessage class]]) {
    return NO;
  }
  ZMGenericMessage *otherMessage = other;
  return
      self.hasMessageId == otherMessage.hasMessageId &&
      (!self.hasMessageId || [self.messageId isEqual:otherMessage.messageId]) &&
      self.hasText == otherMessage.hasText &&
      (!self.hasText || [self.text isEqual:otherMessage.text]) &&
      self.hasImage == otherMessage.hasImage &&
      (!self.hasImage || [self.image isEqual:otherMessage.image]) &&
      self.hasKnock == otherMessage.hasKnock &&
      (!self.hasKnock || [self.knock isEqual:otherMessage.knock]) &&
      self.hasLiking == otherMessage.hasLiking &&
      (!self.hasLiking || self.liking == otherMessage.liking) &&
      self.hasLastRead == otherMessage.hasLastRead &&
      (!self.hasLastRead || [self.lastRead isEqual:otherMessage.lastRead]) &&
      self.hasCleared == otherMessage.hasCleared &&
      (!self.hasCleared || [self.cleared isEqual:otherMessage.cleared]) &&
      self.hasExternal == otherMessage.hasExternal &&
      (!self.hasExternal || [self.external isEqual:otherMessage.external]) &&
      self.hasClientAction == otherMessage.hasClientAction &&
      (!self.hasClientAction || self.clientAction == otherMessage.clientAction) &&
      self.hasCalling == otherMessage.hasCalling &&
      (!self.hasCalling || [self.calling isEqual:otherMessage.calling]) &&
      self.hasAsset == otherMessage.hasAsset &&
      (!self.hasAsset || [self.asset isEqual:otherMessage.asset]) &&
      self.hasDeleted == otherMessage.hasDeleted &&
      (!self.hasDeleted || [self.deleted isEqual:otherMessage.deleted]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasMessageId) {
    hashCode = hashCode * 31 + [self.messageId hash];
  }
  if (self.hasText) {
    hashCode = hashCode * 31 + [self.text hash];
  }
  if (self.hasImage) {
    hashCode = hashCode * 31 + [self.image hash];
  }
  if (self.hasKnock) {
    hashCode = hashCode * 31 + [self.knock hash];
  }
  if (self.hasLiking) {
    hashCode = hashCode * 31 + self.liking;
  }
  if (self.hasLastRead) {
    hashCode = hashCode * 31 + [self.lastRead hash];
  }
  if (self.hasCleared) {
    hashCode = hashCode * 31 + [self.cleared hash];
  }
  if (self.hasExternal) {
    hashCode = hashCode * 31 + [self.external hash];
  }
  if (self.hasClientAction) {
    hashCode = hashCode * 31 + self.clientAction;
  }
  if (self.hasCalling) {
    hashCode = hashCode * 31 + [self.calling hash];
  }
  if (self.hasAsset) {
    hashCode = hashCode * 31 + [self.asset hash];
  }
  if (self.hasDeleted) {
    hashCode = hashCode * 31 + [self.deleted hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMGenericMessageBuilder()
@property (strong) ZMGenericMessage* resultGenericMessage;
@end

@implementation ZMGenericMessageBuilder
@synthesize resultGenericMessage;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultGenericMessage = [[ZMGenericMessage alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultGenericMessage;
}
- (ZMGenericMessageBuilder*) clear {
  self.resultGenericMessage = [[ZMGenericMessage alloc] init];
  return self;
}
- (ZMGenericMessageBuilder*) clone {
  return [ZMGenericMessage builderWithPrototype:resultGenericMessage];
}
- (ZMGenericMessage*) defaultInstance {
  return [ZMGenericMessage defaultInstance];
}
- (ZMGenericMessage*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMGenericMessage*) buildPartial {
  ZMGenericMessage* returnMe = resultGenericMessage;
  self.resultGenericMessage = nil;
  return returnMe;
}
- (ZMGenericMessageBuilder*) mergeFrom:(ZMGenericMessage*) other {
  if (other == [ZMGenericMessage defaultInstance]) {
    return self;
  }
  if (other.hasMessageId) {
    [self setMessageId:other.messageId];
  }
  if (other.hasText) {
    [self mergeText:other.text];
  }
  if (other.hasImage) {
    [self mergeImage:other.image];
  }
  if (other.hasKnock) {
    [self mergeKnock:other.knock];
  }
  if (other.hasLiking) {
    [self setLiking:other.liking];
  }
  if (other.hasLastRead) {
    [self mergeLastRead:other.lastRead];
  }
  if (other.hasCleared) {
    [self mergeCleared:other.cleared];
  }
  if (other.hasExternal) {
    [self mergeExternal:other.external];
  }
  if (other.hasClientAction) {
    [self setClientAction:other.clientAction];
  }
  if (other.hasCalling) {
    [self mergeCalling:other.calling];
  }
  if (other.hasAsset) {
    [self mergeAsset:other.asset];
  }
  if (other.hasDeleted) {
    [self mergeDeleted:other.deleted];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMGenericMessageBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMGenericMessageBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setMessageId:[input readString]];
        break;
      }
      case 18: {
        ZMTextBuilder* subBuilder = [ZMText builder];
        if (self.hasText) {
          [subBuilder mergeFrom:self.text];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setText:[subBuilder buildPartial]];
        break;
      }
      case 26: {
        ZMImageAssetBuilder* subBuilder = [ZMImageAsset builder];
        if (self.hasImage) {
          [subBuilder mergeFrom:self.image];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setImage:[subBuilder buildPartial]];
        break;
      }
      case 34: {
        ZMKnockBuilder* subBuilder = [ZMKnock builder];
        if (self.hasKnock) {
          [subBuilder mergeFrom:self.knock];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setKnock:[subBuilder buildPartial]];
        break;
      }
      case 40: {
        ZMLikeAction value = (ZMLikeAction)[input readEnum];
        if (ZMLikeActionIsValidValue(value)) {
          [self setLiking:value];
        } else {
          [unknownFields mergeVarintField:5 value:value];
        }
        break;
      }
      case 50: {
        ZMLastReadBuilder* subBuilder = [ZMLastRead builder];
        if (self.hasLastRead) {
          [subBuilder mergeFrom:self.lastRead];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setLastRead:[subBuilder buildPartial]];
        break;
      }
      case 58: {
        ZMClearedBuilder* subBuilder = [ZMCleared builder];
        if (self.hasCleared) {
          [subBuilder mergeFrom:self.cleared];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setCleared:[subBuilder buildPartial]];
        break;
      }
      case 66: {
        ZMExternalBuilder* subBuilder = [ZMExternal builder];
        if (self.hasExternal) {
          [subBuilder mergeFrom:self.external];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setExternal:[subBuilder buildPartial]];
        break;
      }
      case 72: {
        ZMClientAction value = (ZMClientAction)[input readEnum];
        if (ZMClientActionIsValidValue(value)) {
          [self setClientAction:value];
        } else {
          [unknownFields mergeVarintField:9 value:value];
        }
        break;
      }
      case 82: {
        ZMCallingBuilder* subBuilder = [ZMCalling builder];
        if (self.hasCalling) {
          [subBuilder mergeFrom:self.calling];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setCalling:[subBuilder buildPartial]];
        break;
      }
      case 90: {
        ZMAssetBuilder* subBuilder = [ZMAsset builder];
        if (self.hasAsset) {
          [subBuilder mergeFrom:self.asset];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setAsset:[subBuilder buildPartial]];
        break;
      }
      case 98: {
        ZMMsgDeletedBuilder* subBuilder = [ZMMsgDeleted builder];
        if (self.hasDeleted) {
          [subBuilder mergeFrom:self.deleted];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setDeleted:[subBuilder buildPartial]];
        break;
      }
    }
  }
}
- (BOOL) hasMessageId {
  return resultGenericMessage.hasMessageId;
}
- (NSString*) messageId {
  return resultGenericMessage.messageId;
}
- (ZMGenericMessageBuilder*) setMessageId:(NSString*) value {
  resultGenericMessage.hasMessageId = YES;
  resultGenericMessage.messageId = value;
  return self;
}
- (ZMGenericMessageBuilder*) clearMessageId {
  resultGenericMessage.hasMessageId = NO;
  resultGenericMessage.messageId = @"";
  return self;
}
- (BOOL) hasText {
  return resultGenericMessage.hasText;
}
- (ZMText*) text {
  return resultGenericMessage.text;
}
- (ZMGenericMessageBuilder*) setText:(ZMText*) value {
  resultGenericMessage.hasText = YES;
  resultGenericMessage.text = value;
  return self;
}
- (ZMGenericMessageBuilder*) setTextBuilder:(ZMTextBuilder*) builderForValue {
  return [self setText:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeText:(ZMText*) value {
  if (resultGenericMessage.hasText &&
      resultGenericMessage.text != [ZMText defaultInstance]) {
    resultGenericMessage.text =
      [[[ZMText builderWithPrototype:resultGenericMessage.text] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.text = value;
  }
  resultGenericMessage.hasText = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearText {
  resultGenericMessage.hasText = NO;
  resultGenericMessage.text = [ZMText defaultInstance];
  return self;
}
- (BOOL) hasImage {
  return resultGenericMessage.hasImage;
}
- (ZMImageAsset*) image {
  return resultGenericMessage.image;
}
- (ZMGenericMessageBuilder*) setImage:(ZMImageAsset*) value {
  resultGenericMessage.hasImage = YES;
  resultGenericMessage.image = value;
  return self;
}
- (ZMGenericMessageBuilder*) setImageBuilder:(ZMImageAssetBuilder*) builderForValue {
  return [self setImage:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeImage:(ZMImageAsset*) value {
  if (resultGenericMessage.hasImage &&
      resultGenericMessage.image != [ZMImageAsset defaultInstance]) {
    resultGenericMessage.image =
      [[[ZMImageAsset builderWithPrototype:resultGenericMessage.image] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.image = value;
  }
  resultGenericMessage.hasImage = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearImage {
  resultGenericMessage.hasImage = NO;
  resultGenericMessage.image = [ZMImageAsset defaultInstance];
  return self;
}
- (BOOL) hasKnock {
  return resultGenericMessage.hasKnock;
}
- (ZMKnock*) knock {
  return resultGenericMessage.knock;
}
- (ZMGenericMessageBuilder*) setKnock:(ZMKnock*) value {
  resultGenericMessage.hasKnock = YES;
  resultGenericMessage.knock = value;
  return self;
}
- (ZMGenericMessageBuilder*) setKnockBuilder:(ZMKnockBuilder*) builderForValue {
  return [self setKnock:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeKnock:(ZMKnock*) value {
  if (resultGenericMessage.hasKnock &&
      resultGenericMessage.knock != [ZMKnock defaultInstance]) {
    resultGenericMessage.knock =
      [[[ZMKnock builderWithPrototype:resultGenericMessage.knock] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.knock = value;
  }
  resultGenericMessage.hasKnock = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearKnock {
  resultGenericMessage.hasKnock = NO;
  resultGenericMessage.knock = [ZMKnock defaultInstance];
  return self;
}
- (BOOL) hasLiking {
  return resultGenericMessage.hasLiking;
}
- (ZMLikeAction) liking {
  return resultGenericMessage.liking;
}
- (ZMGenericMessageBuilder*) setLiking:(ZMLikeAction) value {
  resultGenericMessage.hasLiking = YES;
  resultGenericMessage.liking = value;
  return self;
}
- (ZMGenericMessageBuilder*) clearLiking {
  resultGenericMessage.hasLiking = NO;
  resultGenericMessage.liking = ZMLikeActionLIKE;
  return self;
}
- (BOOL) hasLastRead {
  return resultGenericMessage.hasLastRead;
}
- (ZMLastRead*) lastRead {
  return resultGenericMessage.lastRead;
}
- (ZMGenericMessageBuilder*) setLastRead:(ZMLastRead*) value {
  resultGenericMessage.hasLastRead = YES;
  resultGenericMessage.lastRead = value;
  return self;
}
- (ZMGenericMessageBuilder*) setLastReadBuilder:(ZMLastReadBuilder*) builderForValue {
  return [self setLastRead:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeLastRead:(ZMLastRead*) value {
  if (resultGenericMessage.hasLastRead &&
      resultGenericMessage.lastRead != [ZMLastRead defaultInstance]) {
    resultGenericMessage.lastRead =
      [[[ZMLastRead builderWithPrototype:resultGenericMessage.lastRead] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.lastRead = value;
  }
  resultGenericMessage.hasLastRead = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearLastRead {
  resultGenericMessage.hasLastRead = NO;
  resultGenericMessage.lastRead = [ZMLastRead defaultInstance];
  return self;
}
- (BOOL) hasCleared {
  return resultGenericMessage.hasCleared;
}
- (ZMCleared*) cleared {
  return resultGenericMessage.cleared;
}
- (ZMGenericMessageBuilder*) setCleared:(ZMCleared*) value {
  resultGenericMessage.hasCleared = YES;
  resultGenericMessage.cleared = value;
  return self;
}
- (ZMGenericMessageBuilder*) setClearedBuilder:(ZMClearedBuilder*) builderForValue {
  return [self setCleared:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeCleared:(ZMCleared*) value {
  if (resultGenericMessage.hasCleared &&
      resultGenericMessage.cleared != [ZMCleared defaultInstance]) {
    resultGenericMessage.cleared =
      [[[ZMCleared builderWithPrototype:resultGenericMessage.cleared] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.cleared = value;
  }
  resultGenericMessage.hasCleared = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearCleared {
  resultGenericMessage.hasCleared = NO;
  resultGenericMessage.cleared = [ZMCleared defaultInstance];
  return self;
}
- (BOOL) hasExternal {
  return resultGenericMessage.hasExternal;
}
- (ZMExternal*) external {
  return resultGenericMessage.external;
}
- (ZMGenericMessageBuilder*) setExternal:(ZMExternal*) value {
  resultGenericMessage.hasExternal = YES;
  resultGenericMessage.external = value;
  return self;
}
- (ZMGenericMessageBuilder*) setExternalBuilder:(ZMExternalBuilder*) builderForValue {
  return [self setExternal:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeExternal:(ZMExternal*) value {
  if (resultGenericMessage.hasExternal &&
      resultGenericMessage.external != [ZMExternal defaultInstance]) {
    resultGenericMessage.external =
      [[[ZMExternal builderWithPrototype:resultGenericMessage.external] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.external = value;
  }
  resultGenericMessage.hasExternal = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearExternal {
  resultGenericMessage.hasExternal = NO;
  resultGenericMessage.external = [ZMExternal defaultInstance];
  return self;
}
- (BOOL) hasClientAction {
  return resultGenericMessage.hasClientAction;
}
- (ZMClientAction) clientAction {
  return resultGenericMessage.clientAction;
}
- (ZMGenericMessageBuilder*) setClientAction:(ZMClientAction) value {
  resultGenericMessage.hasClientAction = YES;
  resultGenericMessage.clientAction = value;
  return self;
}
- (ZMGenericMessageBuilder*) clearClientAction {
  resultGenericMessage.hasClientAction = NO;
  resultGenericMessage.clientAction = ZMClientActionRESETSESSION;
  return self;
}
- (BOOL) hasCalling {
  return resultGenericMessage.hasCalling;
}
- (ZMCalling*) calling {
  return resultGenericMessage.calling;
}
- (ZMGenericMessageBuilder*) setCalling:(ZMCalling*) value {
  resultGenericMessage.hasCalling = YES;
  resultGenericMessage.calling = value;
  return self;
}
- (ZMGenericMessageBuilder*) setCallingBuilder:(ZMCallingBuilder*) builderForValue {
  return [self setCalling:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeCalling:(ZMCalling*) value {
  if (resultGenericMessage.hasCalling &&
      resultGenericMessage.calling != [ZMCalling defaultInstance]) {
    resultGenericMessage.calling =
      [[[ZMCalling builderWithPrototype:resultGenericMessage.calling] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.calling = value;
  }
  resultGenericMessage.hasCalling = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearCalling {
  resultGenericMessage.hasCalling = NO;
  resultGenericMessage.calling = [ZMCalling defaultInstance];
  return self;
}
- (BOOL) hasAsset {
  return resultGenericMessage.hasAsset;
}
- (ZMAsset*) asset {
  return resultGenericMessage.asset;
}
- (ZMGenericMessageBuilder*) setAsset:(ZMAsset*) value {
  resultGenericMessage.hasAsset = YES;
  resultGenericMessage.asset = value;
  return self;
}
- (ZMGenericMessageBuilder*) setAssetBuilder:(ZMAssetBuilder*) builderForValue {
  return [self setAsset:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeAsset:(ZMAsset*) value {
  if (resultGenericMessage.hasAsset &&
      resultGenericMessage.asset != [ZMAsset defaultInstance]) {
    resultGenericMessage.asset =
      [[[ZMAsset builderWithPrototype:resultGenericMessage.asset] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.asset = value;
  }
  resultGenericMessage.hasAsset = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearAsset {
  resultGenericMessage.hasAsset = NO;
  resultGenericMessage.asset = [ZMAsset defaultInstance];
  return self;
}
- (BOOL) hasDeleted {
  return resultGenericMessage.hasDeleted;
}
- (ZMMsgDeleted*) deleted {
  return resultGenericMessage.deleted;
}
- (ZMGenericMessageBuilder*) setDeleted:(ZMMsgDeleted*) value {
  resultGenericMessage.hasDeleted = YES;
  resultGenericMessage.deleted = value;
  return self;
}
- (ZMGenericMessageBuilder*) setDeletedBuilder:(ZMMsgDeletedBuilder*) builderForValue {
  return [self setDeleted:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeDeleted:(ZMMsgDeleted*) value {
  if (resultGenericMessage.hasDeleted &&
      resultGenericMessage.deleted != [ZMMsgDeleted defaultInstance]) {
    resultGenericMessage.deleted =
      [[[ZMMsgDeleted builderWithPrototype:resultGenericMessage.deleted] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.deleted = value;
  }
  resultGenericMessage.hasDeleted = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearDeleted {
  resultGenericMessage.hasDeleted = NO;
  resultGenericMessage.deleted = [ZMMsgDeleted defaultInstance];
  return self;
}
@end

@interface ZMText ()
@property (strong) NSString* content;
@property (strong) NSMutableArray * mentionArray;
@end

@implementation ZMText

- (BOOL) hasContent {
  return !!hasContent_;
}
- (void) setHasContent:(BOOL) _value_ {
  hasContent_ = !!_value_;
}
@synthesize content;
@synthesize mentionArray;
@dynamic mention;
- (instancetype) init {
  if ((self = [super init])) {
    self.content = @"";
  }
  return self;
}
static ZMText* defaultZMTextInstance = nil;
+ (void) initialize {
  if (self == [ZMText class]) {
    defaultZMTextInstance = [[ZMText alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMTextInstance;
}
- (instancetype) defaultInstance {
  return defaultZMTextInstance;
}
- (NSArray *)mention {
  return mentionArray;
}
- (ZMMention*)mentionAtIndex:(NSUInteger)index {
  return [mentionArray objectAtIndex:index];
}
- (BOOL) isInitialized {
  if (!self.hasContent) {
    return NO;
  }
  __block BOOL isInitmention = YES;
   [self.mention enumerateObjectsUsingBlock:^(ZMMention *element, NSUInteger idx, BOOL *stop) {
    if (!element.isInitialized) {
      isInitmention = NO;
      *stop = YES;
    }
  }];
  if (!isInitmention) return isInitmention;
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasContent) {
    [output writeString:1 value:self.content];
  }
  [self.mentionArray enumerateObjectsUsingBlock:^(ZMMention *element, NSUInteger idx, BOOL *stop) {
    [output writeMessage:2 value:element];
  }];
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasContent) {
    size_ += computeStringSize(1, self.content);
  }
  [self.mentionArray enumerateObjectsUsingBlock:^(ZMMention *element, NSUInteger idx, BOOL *stop) {
    size_ += computeMessageSize(2, element);
  }];
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMText*) parseFromData:(NSData*) data {
  return (ZMText*)[[[ZMText builder] mergeFromData:data] build];
}
+ (ZMText*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMText*)[[[ZMText builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMText*) parseFromInputStream:(NSInputStream*) input {
  return (ZMText*)[[[ZMText builder] mergeFromInputStream:input] build];
}
+ (ZMText*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMText*)[[[ZMText builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMText*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMText*)[[[ZMText builder] mergeFromCodedInputStream:input] build];
}
+ (ZMText*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMText*)[[[ZMText builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMTextBuilder*) builder {
  return [[ZMTextBuilder alloc] init];
}
+ (ZMTextBuilder*) builderWithPrototype:(ZMText*) prototype {
  return [[ZMText builder] mergeFrom:prototype];
}
- (ZMTextBuilder*) builder {
  return [ZMText builder];
}
- (ZMTextBuilder*) toBuilder {
  return [ZMText builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasContent) {
    [output appendFormat:@"%@%@: %@\n", indent, @"content", self.content];
  }
  [self.mentionArray enumerateObjectsUsingBlock:^(ZMMention *element, NSUInteger idx, BOOL *stop) {
    [output appendFormat:@"%@%@ {\n", indent, @"mention"];
    [element writeDescriptionTo:output
                     withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }];
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasContent) {
    [dictionary setObject: self.content forKey: @"content"];
  }
  for (ZMMention* element in self.mentionArray) {
    NSMutableDictionary *elementDictionary = [NSMutableDictionary dictionary];
    [element storeInDictionary:elementDictionary];
    [dictionary setObject:[NSDictionary dictionaryWithDictionary:elementDictionary] forKey:@"mention"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMText class]]) {
    return NO;
  }
  ZMText *otherMessage = other;
  return
      self.hasContent == otherMessage.hasContent &&
      (!self.hasContent || [self.content isEqual:otherMessage.content]) &&
      [self.mentionArray isEqualToArray:otherMessage.mentionArray] &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasContent) {
    hashCode = hashCode * 31 + [self.content hash];
  }
  [self.mentionArray enumerateObjectsUsingBlock:^(ZMMention *element, NSUInteger idx, BOOL *stop) {
    hashCode = hashCode * 31 + [element hash];
  }];
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMTextBuilder()
@property (strong) ZMText* resultText;
@end

@implementation ZMTextBuilder
@synthesize resultText;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultText = [[ZMText alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultText;
}
- (ZMTextBuilder*) clear {
  self.resultText = [[ZMText alloc] init];
  return self;
}
- (ZMTextBuilder*) clone {
  return [ZMText builderWithPrototype:resultText];
}
- (ZMText*) defaultInstance {
  return [ZMText defaultInstance];
}
- (ZMText*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMText*) buildPartial {
  ZMText* returnMe = resultText;
  self.resultText = nil;
  return returnMe;
}
- (ZMTextBuilder*) mergeFrom:(ZMText*) other {
  if (other == [ZMText defaultInstance]) {
    return self;
  }
  if (other.hasContent) {
    [self setContent:other.content];
  }
  if (other.mentionArray.count > 0) {
    if (resultText.mentionArray == nil) {
      resultText.mentionArray = [[NSMutableArray alloc] initWithArray:other.mentionArray];
    } else {
      [resultText.mentionArray addObjectsFromArray:other.mentionArray];
    }
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMTextBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMTextBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setContent:[input readString]];
        break;
      }
      case 18: {
        ZMMentionBuilder* subBuilder = [ZMMention builder];
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self addMention:[subBuilder buildPartial]];
        break;
      }
    }
  }
}
- (BOOL) hasContent {
  return resultText.hasContent;
}
- (NSString*) content {
  return resultText.content;
}
- (ZMTextBuilder*) setContent:(NSString*) value {
  resultText.hasContent = YES;
  resultText.content = value;
  return self;
}
- (ZMTextBuilder*) clearContent {
  resultText.hasContent = NO;
  resultText.content = @"";
  return self;
}
- (NSMutableArray *)mention {
  return resultText.mentionArray;
}
- (ZMMention*)mentionAtIndex:(NSUInteger)index {
  return [resultText mentionAtIndex:index];
}
- (ZMTextBuilder *)addMention:(ZMMention*)value {
  if (resultText.mentionArray == nil) {
    resultText.mentionArray = [[NSMutableArray alloc]init];
  }
  [resultText.mentionArray addObject:value];
  return self;
}
- (ZMTextBuilder *)setMentionArray:(NSArray *)array {
  resultText.mentionArray = [[NSMutableArray alloc]initWithArray:array];
  return self;
}
- (ZMTextBuilder *)clearMention {
  resultText.mentionArray = nil;
  return self;
}
@end

@interface ZMKnock ()
@property BOOL hotKnock;
@end

@implementation ZMKnock

- (BOOL) hasHotKnock {
  return !!hasHotKnock_;
}
- (void) setHasHotKnock:(BOOL) _value_ {
  hasHotKnock_ = !!_value_;
}
- (BOOL) hotKnock {
  return !!hotKnock_;
}
- (void) setHotKnock:(BOOL) _value_ {
  hotKnock_ = !!_value_;
}
- (instancetype) init {
  if ((self = [super init])) {
    self.hotKnock = NO;
  }
  return self;
}
static ZMKnock* defaultZMKnockInstance = nil;
+ (void) initialize {
  if (self == [ZMKnock class]) {
    defaultZMKnockInstance = [[ZMKnock alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMKnockInstance;
}
- (instancetype) defaultInstance {
  return defaultZMKnockInstance;
}
- (BOOL) isInitialized {
  if (!self.hasHotKnock) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasHotKnock) {
    [output writeBool:1 value:self.hotKnock];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasHotKnock) {
    size_ += computeBoolSize(1, self.hotKnock);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMKnock*) parseFromData:(NSData*) data {
  return (ZMKnock*)[[[ZMKnock builder] mergeFromData:data] build];
}
+ (ZMKnock*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMKnock*)[[[ZMKnock builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMKnock*) parseFromInputStream:(NSInputStream*) input {
  return (ZMKnock*)[[[ZMKnock builder] mergeFromInputStream:input] build];
}
+ (ZMKnock*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMKnock*)[[[ZMKnock builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMKnock*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMKnock*)[[[ZMKnock builder] mergeFromCodedInputStream:input] build];
}
+ (ZMKnock*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMKnock*)[[[ZMKnock builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMKnockBuilder*) builder {
  return [[ZMKnockBuilder alloc] init];
}
+ (ZMKnockBuilder*) builderWithPrototype:(ZMKnock*) prototype {
  return [[ZMKnock builder] mergeFrom:prototype];
}
- (ZMKnockBuilder*) builder {
  return [ZMKnock builder];
}
- (ZMKnockBuilder*) toBuilder {
  return [ZMKnock builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasHotKnock) {
    [output appendFormat:@"%@%@: %@\n", indent, @"hotKnock", [NSNumber numberWithBool:self.hotKnock]];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasHotKnock) {
    [dictionary setObject: [NSNumber numberWithBool:self.hotKnock] forKey: @"hotKnock"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMKnock class]]) {
    return NO;
  }
  ZMKnock *otherMessage = other;
  return
      self.hasHotKnock == otherMessage.hasHotKnock &&
      (!self.hasHotKnock || self.hotKnock == otherMessage.hotKnock) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasHotKnock) {
    hashCode = hashCode * 31 + [[NSNumber numberWithBool:self.hotKnock] hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMKnockBuilder()
@property (strong) ZMKnock* resultKnock;
@end

@implementation ZMKnockBuilder
@synthesize resultKnock;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultKnock = [[ZMKnock alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultKnock;
}
- (ZMKnockBuilder*) clear {
  self.resultKnock = [[ZMKnock alloc] init];
  return self;
}
- (ZMKnockBuilder*) clone {
  return [ZMKnock builderWithPrototype:resultKnock];
}
- (ZMKnock*) defaultInstance {
  return [ZMKnock defaultInstance];
}
- (ZMKnock*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMKnock*) buildPartial {
  ZMKnock* returnMe = resultKnock;
  self.resultKnock = nil;
  return returnMe;
}
- (ZMKnockBuilder*) mergeFrom:(ZMKnock*) other {
  if (other == [ZMKnock defaultInstance]) {
    return self;
  }
  if (other.hasHotKnock) {
    [self setHotKnock:other.hotKnock];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMKnockBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMKnockBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 8: {
        [self setHotKnock:[input readBool]];
        break;
      }
    }
  }
}
- (BOOL) hasHotKnock {
  return resultKnock.hasHotKnock;
}
- (BOOL) hotKnock {
  return resultKnock.hotKnock;
}
- (ZMKnockBuilder*) setHotKnock:(BOOL) value {
  resultKnock.hasHotKnock = YES;
  resultKnock.hotKnock = value;
  return self;
}
- (ZMKnockBuilder*) clearHotKnock {
  resultKnock.hasHotKnock = NO;
  resultKnock.hotKnock = NO;
  return self;
}
@end

@interface ZMMention ()
@property (strong) NSString* userId;
@property (strong) NSString* userName;
@end

@implementation ZMMention

- (BOOL) hasUserId {
  return !!hasUserId_;
}
- (void) setHasUserId:(BOOL) _value_ {
  hasUserId_ = !!_value_;
}
@synthesize userId;
- (BOOL) hasUserName {
  return !!hasUserName_;
}
- (void) setHasUserName:(BOOL) _value_ {
  hasUserName_ = !!_value_;
}
@synthesize userName;
- (instancetype) init {
  if ((self = [super init])) {
    self.userId = @"";
    self.userName = @"";
  }
  return self;
}
static ZMMention* defaultZMMentionInstance = nil;
+ (void) initialize {
  if (self == [ZMMention class]) {
    defaultZMMentionInstance = [[ZMMention alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMMentionInstance;
}
- (instancetype) defaultInstance {
  return defaultZMMentionInstance;
}
- (BOOL) isInitialized {
  if (!self.hasUserId) {
    return NO;
  }
  if (!self.hasUserName) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasUserId) {
    [output writeString:1 value:self.userId];
  }
  if (self.hasUserName) {
    [output writeString:2 value:self.userName];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasUserId) {
    size_ += computeStringSize(1, self.userId);
  }
  if (self.hasUserName) {
    size_ += computeStringSize(2, self.userName);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMMention*) parseFromData:(NSData*) data {
  return (ZMMention*)[[[ZMMention builder] mergeFromData:data] build];
}
+ (ZMMention*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMention*)[[[ZMMention builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMMention*) parseFromInputStream:(NSInputStream*) input {
  return (ZMMention*)[[[ZMMention builder] mergeFromInputStream:input] build];
}
+ (ZMMention*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMention*)[[[ZMMention builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMMention*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMMention*)[[[ZMMention builder] mergeFromCodedInputStream:input] build];
}
+ (ZMMention*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMention*)[[[ZMMention builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMMentionBuilder*) builder {
  return [[ZMMentionBuilder alloc] init];
}
+ (ZMMentionBuilder*) builderWithPrototype:(ZMMention*) prototype {
  return [[ZMMention builder] mergeFrom:prototype];
}
- (ZMMentionBuilder*) builder {
  return [ZMMention builder];
}
- (ZMMentionBuilder*) toBuilder {
  return [ZMMention builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasUserId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"userId", self.userId];
  }
  if (self.hasUserName) {
    [output appendFormat:@"%@%@: %@\n", indent, @"userName", self.userName];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasUserId) {
    [dictionary setObject: self.userId forKey: @"userId"];
  }
  if (self.hasUserName) {
    [dictionary setObject: self.userName forKey: @"userName"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMMention class]]) {
    return NO;
  }
  ZMMention *otherMessage = other;
  return
      self.hasUserId == otherMessage.hasUserId &&
      (!self.hasUserId || [self.userId isEqual:otherMessage.userId]) &&
      self.hasUserName == otherMessage.hasUserName &&
      (!self.hasUserName || [self.userName isEqual:otherMessage.userName]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasUserId) {
    hashCode = hashCode * 31 + [self.userId hash];
  }
  if (self.hasUserName) {
    hashCode = hashCode * 31 + [self.userName hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMMentionBuilder()
@property (strong) ZMMention* resultMention;
@end

@implementation ZMMentionBuilder
@synthesize resultMention;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultMention = [[ZMMention alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultMention;
}
- (ZMMentionBuilder*) clear {
  self.resultMention = [[ZMMention alloc] init];
  return self;
}
- (ZMMentionBuilder*) clone {
  return [ZMMention builderWithPrototype:resultMention];
}
- (ZMMention*) defaultInstance {
  return [ZMMention defaultInstance];
}
- (ZMMention*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMMention*) buildPartial {
  ZMMention* returnMe = resultMention;
  self.resultMention = nil;
  return returnMe;
}
- (ZMMentionBuilder*) mergeFrom:(ZMMention*) other {
  if (other == [ZMMention defaultInstance]) {
    return self;
  }
  if (other.hasUserId) {
    [self setUserId:other.userId];
  }
  if (other.hasUserName) {
    [self setUserName:other.userName];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMMentionBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMMentionBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setUserId:[input readString]];
        break;
      }
      case 18: {
        [self setUserName:[input readString]];
        break;
      }
    }
  }
}
- (BOOL) hasUserId {
  return resultMention.hasUserId;
}
- (NSString*) userId {
  return resultMention.userId;
}
- (ZMMentionBuilder*) setUserId:(NSString*) value {
  resultMention.hasUserId = YES;
  resultMention.userId = value;
  return self;
}
- (ZMMentionBuilder*) clearUserId {
  resultMention.hasUserId = NO;
  resultMention.userId = @"";
  return self;
}
- (BOOL) hasUserName {
  return resultMention.hasUserName;
}
- (NSString*) userName {
  return resultMention.userName;
}
- (ZMMentionBuilder*) setUserName:(NSString*) value {
  resultMention.hasUserName = YES;
  resultMention.userName = value;
  return self;
}
- (ZMMentionBuilder*) clearUserName {
  resultMention.hasUserName = NO;
  resultMention.userName = @"";
  return self;
}
@end

@interface ZMLastRead ()
@property (strong) NSString* conversationId;
@property SInt64 lastReadTimestamp;
@end

@implementation ZMLastRead

- (BOOL) hasConversationId {
  return !!hasConversationId_;
}
- (void) setHasConversationId:(BOOL) _value_ {
  hasConversationId_ = !!_value_;
}
@synthesize conversationId;
- (BOOL) hasLastReadTimestamp {
  return !!hasLastReadTimestamp_;
}
- (void) setHasLastReadTimestamp:(BOOL) _value_ {
  hasLastReadTimestamp_ = !!_value_;
}
@synthesize lastReadTimestamp;
- (instancetype) init {
  if ((self = [super init])) {
    self.conversationId = @"";
    self.lastReadTimestamp = 0L;
  }
  return self;
}
static ZMLastRead* defaultZMLastReadInstance = nil;
+ (void) initialize {
  if (self == [ZMLastRead class]) {
    defaultZMLastReadInstance = [[ZMLastRead alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMLastReadInstance;
}
- (instancetype) defaultInstance {
  return defaultZMLastReadInstance;
}
- (BOOL) isInitialized {
  if (!self.hasConversationId) {
    return NO;
  }
  if (!self.hasLastReadTimestamp) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasConversationId) {
    [output writeString:1 value:self.conversationId];
  }
  if (self.hasLastReadTimestamp) {
    [output writeInt64:2 value:self.lastReadTimestamp];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasConversationId) {
    size_ += computeStringSize(1, self.conversationId);
  }
  if (self.hasLastReadTimestamp) {
    size_ += computeInt64Size(2, self.lastReadTimestamp);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMLastRead*) parseFromData:(NSData*) data {
  return (ZMLastRead*)[[[ZMLastRead builder] mergeFromData:data] build];
}
+ (ZMLastRead*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMLastRead*)[[[ZMLastRead builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMLastRead*) parseFromInputStream:(NSInputStream*) input {
  return (ZMLastRead*)[[[ZMLastRead builder] mergeFromInputStream:input] build];
}
+ (ZMLastRead*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMLastRead*)[[[ZMLastRead builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMLastRead*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMLastRead*)[[[ZMLastRead builder] mergeFromCodedInputStream:input] build];
}
+ (ZMLastRead*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMLastRead*)[[[ZMLastRead builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMLastReadBuilder*) builder {
  return [[ZMLastReadBuilder alloc] init];
}
+ (ZMLastReadBuilder*) builderWithPrototype:(ZMLastRead*) prototype {
  return [[ZMLastRead builder] mergeFrom:prototype];
}
- (ZMLastReadBuilder*) builder {
  return [ZMLastRead builder];
}
- (ZMLastReadBuilder*) toBuilder {
  return [ZMLastRead builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasConversationId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"conversationId", self.conversationId];
  }
  if (self.hasLastReadTimestamp) {
    [output appendFormat:@"%@%@: %@\n", indent, @"lastReadTimestamp", [NSNumber numberWithLongLong:self.lastReadTimestamp]];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasConversationId) {
    [dictionary setObject: self.conversationId forKey: @"conversationId"];
  }
  if (self.hasLastReadTimestamp) {
    [dictionary setObject: [NSNumber numberWithLongLong:self.lastReadTimestamp] forKey: @"lastReadTimestamp"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMLastRead class]]) {
    return NO;
  }
  ZMLastRead *otherMessage = other;
  return
      self.hasConversationId == otherMessage.hasConversationId &&
      (!self.hasConversationId || [self.conversationId isEqual:otherMessage.conversationId]) &&
      self.hasLastReadTimestamp == otherMessage.hasLastReadTimestamp &&
      (!self.hasLastReadTimestamp || self.lastReadTimestamp == otherMessage.lastReadTimestamp) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasConversationId) {
    hashCode = hashCode * 31 + [self.conversationId hash];
  }
  if (self.hasLastReadTimestamp) {
    hashCode = hashCode * 31 + [[NSNumber numberWithLongLong:self.lastReadTimestamp] hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMLastReadBuilder()
@property (strong) ZMLastRead* resultLastRead;
@end

@implementation ZMLastReadBuilder
@synthesize resultLastRead;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultLastRead = [[ZMLastRead alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultLastRead;
}
- (ZMLastReadBuilder*) clear {
  self.resultLastRead = [[ZMLastRead alloc] init];
  return self;
}
- (ZMLastReadBuilder*) clone {
  return [ZMLastRead builderWithPrototype:resultLastRead];
}
- (ZMLastRead*) defaultInstance {
  return [ZMLastRead defaultInstance];
}
- (ZMLastRead*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMLastRead*) buildPartial {
  ZMLastRead* returnMe = resultLastRead;
  self.resultLastRead = nil;
  return returnMe;
}
- (ZMLastReadBuilder*) mergeFrom:(ZMLastRead*) other {
  if (other == [ZMLastRead defaultInstance]) {
    return self;
  }
  if (other.hasConversationId) {
    [self setConversationId:other.conversationId];
  }
  if (other.hasLastReadTimestamp) {
    [self setLastReadTimestamp:other.lastReadTimestamp];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMLastReadBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMLastReadBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setConversationId:[input readString]];
        break;
      }
      case 16: {
        [self setLastReadTimestamp:[input readInt64]];
        break;
      }
    }
  }
}
- (BOOL) hasConversationId {
  return resultLastRead.hasConversationId;
}
- (NSString*) conversationId {
  return resultLastRead.conversationId;
}
- (ZMLastReadBuilder*) setConversationId:(NSString*) value {
  resultLastRead.hasConversationId = YES;
  resultLastRead.conversationId = value;
  return self;
}
- (ZMLastReadBuilder*) clearConversationId {
  resultLastRead.hasConversationId = NO;
  resultLastRead.conversationId = @"";
  return self;
}
- (BOOL) hasLastReadTimestamp {
  return resultLastRead.hasLastReadTimestamp;
}
- (SInt64) lastReadTimestamp {
  return resultLastRead.lastReadTimestamp;
}
- (ZMLastReadBuilder*) setLastReadTimestamp:(SInt64) value {
  resultLastRead.hasLastReadTimestamp = YES;
  resultLastRead.lastReadTimestamp = value;
  return self;
}
- (ZMLastReadBuilder*) clearLastReadTimestamp {
  resultLastRead.hasLastReadTimestamp = NO;
  resultLastRead.lastReadTimestamp = 0L;
  return self;
}
@end

@interface ZMCleared ()
@property (strong) NSString* conversationId;
@property SInt64 clearedTimestamp;
@end

@implementation ZMCleared

- (BOOL) hasConversationId {
  return !!hasConversationId_;
}
- (void) setHasConversationId:(BOOL) _value_ {
  hasConversationId_ = !!_value_;
}
@synthesize conversationId;
- (BOOL) hasClearedTimestamp {
  return !!hasClearedTimestamp_;
}
- (void) setHasClearedTimestamp:(BOOL) _value_ {
  hasClearedTimestamp_ = !!_value_;
}
@synthesize clearedTimestamp;
- (instancetype) init {
  if ((self = [super init])) {
    self.conversationId = @"";
    self.clearedTimestamp = 0L;
  }
  return self;
}
static ZMCleared* defaultZMClearedInstance = nil;
+ (void) initialize {
  if (self == [ZMCleared class]) {
    defaultZMClearedInstance = [[ZMCleared alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMClearedInstance;
}
- (instancetype) defaultInstance {
  return defaultZMClearedInstance;
}
- (BOOL) isInitialized {
  if (!self.hasConversationId) {
    return NO;
  }
  if (!self.hasClearedTimestamp) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasConversationId) {
    [output writeString:1 value:self.conversationId];
  }
  if (self.hasClearedTimestamp) {
    [output writeInt64:2 value:self.clearedTimestamp];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasConversationId) {
    size_ += computeStringSize(1, self.conversationId);
  }
  if (self.hasClearedTimestamp) {
    size_ += computeInt64Size(2, self.clearedTimestamp);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMCleared*) parseFromData:(NSData*) data {
  return (ZMCleared*)[[[ZMCleared builder] mergeFromData:data] build];
}
+ (ZMCleared*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMCleared*)[[[ZMCleared builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMCleared*) parseFromInputStream:(NSInputStream*) input {
  return (ZMCleared*)[[[ZMCleared builder] mergeFromInputStream:input] build];
}
+ (ZMCleared*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMCleared*)[[[ZMCleared builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMCleared*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMCleared*)[[[ZMCleared builder] mergeFromCodedInputStream:input] build];
}
+ (ZMCleared*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMCleared*)[[[ZMCleared builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMClearedBuilder*) builder {
  return [[ZMClearedBuilder alloc] init];
}
+ (ZMClearedBuilder*) builderWithPrototype:(ZMCleared*) prototype {
  return [[ZMCleared builder] mergeFrom:prototype];
}
- (ZMClearedBuilder*) builder {
  return [ZMCleared builder];
}
- (ZMClearedBuilder*) toBuilder {
  return [ZMCleared builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasConversationId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"conversationId", self.conversationId];
  }
  if (self.hasClearedTimestamp) {
    [output appendFormat:@"%@%@: %@\n", indent, @"clearedTimestamp", [NSNumber numberWithLongLong:self.clearedTimestamp]];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasConversationId) {
    [dictionary setObject: self.conversationId forKey: @"conversationId"];
  }
  if (self.hasClearedTimestamp) {
    [dictionary setObject: [NSNumber numberWithLongLong:self.clearedTimestamp] forKey: @"clearedTimestamp"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMCleared class]]) {
    return NO;
  }
  ZMCleared *otherMessage = other;
  return
      self.hasConversationId == otherMessage.hasConversationId &&
      (!self.hasConversationId || [self.conversationId isEqual:otherMessage.conversationId]) &&
      self.hasClearedTimestamp == otherMessage.hasClearedTimestamp &&
      (!self.hasClearedTimestamp || self.clearedTimestamp == otherMessage.clearedTimestamp) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasConversationId) {
    hashCode = hashCode * 31 + [self.conversationId hash];
  }
  if (self.hasClearedTimestamp) {
    hashCode = hashCode * 31 + [[NSNumber numberWithLongLong:self.clearedTimestamp] hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMClearedBuilder()
@property (strong) ZMCleared* resultCleared;
@end

@implementation ZMClearedBuilder
@synthesize resultCleared;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultCleared = [[ZMCleared alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultCleared;
}
- (ZMClearedBuilder*) clear {
  self.resultCleared = [[ZMCleared alloc] init];
  return self;
}
- (ZMClearedBuilder*) clone {
  return [ZMCleared builderWithPrototype:resultCleared];
}
- (ZMCleared*) defaultInstance {
  return [ZMCleared defaultInstance];
}
- (ZMCleared*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMCleared*) buildPartial {
  ZMCleared* returnMe = resultCleared;
  self.resultCleared = nil;
  return returnMe;
}
- (ZMClearedBuilder*) mergeFrom:(ZMCleared*) other {
  if (other == [ZMCleared defaultInstance]) {
    return self;
  }
  if (other.hasConversationId) {
    [self setConversationId:other.conversationId];
  }
  if (other.hasClearedTimestamp) {
    [self setClearedTimestamp:other.clearedTimestamp];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMClearedBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMClearedBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setConversationId:[input readString]];
        break;
      }
      case 16: {
        [self setClearedTimestamp:[input readInt64]];
        break;
      }
    }
  }
}
- (BOOL) hasConversationId {
  return resultCleared.hasConversationId;
}
- (NSString*) conversationId {
  return resultCleared.conversationId;
}
- (ZMClearedBuilder*) setConversationId:(NSString*) value {
  resultCleared.hasConversationId = YES;
  resultCleared.conversationId = value;
  return self;
}
- (ZMClearedBuilder*) clearConversationId {
  resultCleared.hasConversationId = NO;
  resultCleared.conversationId = @"";
  return self;
}
- (BOOL) hasClearedTimestamp {
  return resultCleared.hasClearedTimestamp;
}
- (SInt64) clearedTimestamp {
  return resultCleared.clearedTimestamp;
}
- (ZMClearedBuilder*) setClearedTimestamp:(SInt64) value {
  resultCleared.hasClearedTimestamp = YES;
  resultCleared.clearedTimestamp = value;
  return self;
}
- (ZMClearedBuilder*) clearClearedTimestamp {
  resultCleared.hasClearedTimestamp = NO;
  resultCleared.clearedTimestamp = 0L;
  return self;
}
@end

@interface ZMMsgDeleted ()
@property (strong) NSString* conversationId;
@property (strong) NSString* messageId;
@end

@implementation ZMMsgDeleted

- (BOOL) hasConversationId {
  return !!hasConversationId_;
}
- (void) setHasConversationId:(BOOL) _value_ {
  hasConversationId_ = !!_value_;
}
@synthesize conversationId;
- (BOOL) hasMessageId {
  return !!hasMessageId_;
}
- (void) setHasMessageId:(BOOL) _value_ {
  hasMessageId_ = !!_value_;
}
@synthesize messageId;
- (instancetype) init {
  if ((self = [super init])) {
    self.conversationId = @"";
    self.messageId = @"";
  }
  return self;
}
static ZMMsgDeleted* defaultZMMsgDeletedInstance = nil;
+ (void) initialize {
  if (self == [ZMMsgDeleted class]) {
    defaultZMMsgDeletedInstance = [[ZMMsgDeleted alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMMsgDeletedInstance;
}
- (instancetype) defaultInstance {
  return defaultZMMsgDeletedInstance;
}
- (BOOL) isInitialized {
  if (!self.hasConversationId) {
    return NO;
  }
  if (!self.hasMessageId) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasConversationId) {
    [output writeString:1 value:self.conversationId];
  }
  if (self.hasMessageId) {
    [output writeString:2 value:self.messageId];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasConversationId) {
    size_ += computeStringSize(1, self.conversationId);
  }
  if (self.hasMessageId) {
    size_ += computeStringSize(2, self.messageId);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMMsgDeleted*) parseFromData:(NSData*) data {
  return (ZMMsgDeleted*)[[[ZMMsgDeleted builder] mergeFromData:data] build];
}
+ (ZMMsgDeleted*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMsgDeleted*)[[[ZMMsgDeleted builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMMsgDeleted*) parseFromInputStream:(NSInputStream*) input {
  return (ZMMsgDeleted*)[[[ZMMsgDeleted builder] mergeFromInputStream:input] build];
}
+ (ZMMsgDeleted*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMsgDeleted*)[[[ZMMsgDeleted builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMMsgDeleted*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMMsgDeleted*)[[[ZMMsgDeleted builder] mergeFromCodedInputStream:input] build];
}
+ (ZMMsgDeleted*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMsgDeleted*)[[[ZMMsgDeleted builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMMsgDeletedBuilder*) builder {
  return [[ZMMsgDeletedBuilder alloc] init];
}
+ (ZMMsgDeletedBuilder*) builderWithPrototype:(ZMMsgDeleted*) prototype {
  return [[ZMMsgDeleted builder] mergeFrom:prototype];
}
- (ZMMsgDeletedBuilder*) builder {
  return [ZMMsgDeleted builder];
}
- (ZMMsgDeletedBuilder*) toBuilder {
  return [ZMMsgDeleted builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasConversationId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"conversationId", self.conversationId];
  }
  if (self.hasMessageId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"messageId", self.messageId];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasConversationId) {
    [dictionary setObject: self.conversationId forKey: @"conversationId"];
  }
  if (self.hasMessageId) {
    [dictionary setObject: self.messageId forKey: @"messageId"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMMsgDeleted class]]) {
    return NO;
  }
  ZMMsgDeleted *otherMessage = other;
  return
      self.hasConversationId == otherMessage.hasConversationId &&
      (!self.hasConversationId || [self.conversationId isEqual:otherMessage.conversationId]) &&
      self.hasMessageId == otherMessage.hasMessageId &&
      (!self.hasMessageId || [self.messageId isEqual:otherMessage.messageId]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasConversationId) {
    hashCode = hashCode * 31 + [self.conversationId hash];
  }
  if (self.hasMessageId) {
    hashCode = hashCode * 31 + [self.messageId hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMMsgDeletedBuilder()
@property (strong) ZMMsgDeleted* resultMsgDeleted;
@end

@implementation ZMMsgDeletedBuilder
@synthesize resultMsgDeleted;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultMsgDeleted = [[ZMMsgDeleted alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultMsgDeleted;
}
- (ZMMsgDeletedBuilder*) clear {
  self.resultMsgDeleted = [[ZMMsgDeleted alloc] init];
  return self;
}
- (ZMMsgDeletedBuilder*) clone {
  return [ZMMsgDeleted builderWithPrototype:resultMsgDeleted];
}
- (ZMMsgDeleted*) defaultInstance {
  return [ZMMsgDeleted defaultInstance];
}
- (ZMMsgDeleted*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMMsgDeleted*) buildPartial {
  ZMMsgDeleted* returnMe = resultMsgDeleted;
  self.resultMsgDeleted = nil;
  return returnMe;
}
- (ZMMsgDeletedBuilder*) mergeFrom:(ZMMsgDeleted*) other {
  if (other == [ZMMsgDeleted defaultInstance]) {
    return self;
  }
  if (other.hasConversationId) {
    [self setConversationId:other.conversationId];
  }
  if (other.hasMessageId) {
    [self setMessageId:other.messageId];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMMsgDeletedBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMMsgDeletedBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setConversationId:[input readString]];
        break;
      }
      case 18: {
        [self setMessageId:[input readString]];
        break;
      }
    }
  }
}
- (BOOL) hasConversationId {
  return resultMsgDeleted.hasConversationId;
}
- (NSString*) conversationId {
  return resultMsgDeleted.conversationId;
}
- (ZMMsgDeletedBuilder*) setConversationId:(NSString*) value {
  resultMsgDeleted.hasConversationId = YES;
  resultMsgDeleted.conversationId = value;
  return self;
}
- (ZMMsgDeletedBuilder*) clearConversationId {
  resultMsgDeleted.hasConversationId = NO;
  resultMsgDeleted.conversationId = @"";
  return self;
}
- (BOOL) hasMessageId {
  return resultMsgDeleted.hasMessageId;
}
- (NSString*) messageId {
  return resultMsgDeleted.messageId;
}
- (ZMMsgDeletedBuilder*) setMessageId:(NSString*) value {
  resultMsgDeleted.hasMessageId = YES;
  resultMsgDeleted.messageId = value;
  return self;
}
- (ZMMsgDeletedBuilder*) clearMessageId {
  resultMsgDeleted.hasMessageId = NO;
  resultMsgDeleted.messageId = @"";
  return self;
}
@end

@interface ZMImageAsset ()
@property (strong) NSString* tag;
@property SInt32 width;
@property SInt32 height;
@property SInt32 originalWidth;
@property SInt32 originalHeight;
@property (strong) NSString* mimeType;
@property SInt32 size;
@property (strong) NSData* otrKey;
@property (strong) NSData* macKey;
@property (strong) NSData* mac;
@property (strong) NSData* sha256;
@end

@implementation ZMImageAsset

- (BOOL) hasTag {
  return !!hasTag_;
}
- (void) setHasTag:(BOOL) _value_ {
  hasTag_ = !!_value_;
}
@synthesize tag;
- (BOOL) hasWidth {
  return !!hasWidth_;
}
- (void) setHasWidth:(BOOL) _value_ {
  hasWidth_ = !!_value_;
}
@synthesize width;
- (BOOL) hasHeight {
  return !!hasHeight_;
}
- (void) setHasHeight:(BOOL) _value_ {
  hasHeight_ = !!_value_;
}
@synthesize height;
- (BOOL) hasOriginalWidth {
  return !!hasOriginalWidth_;
}
- (void) setHasOriginalWidth:(BOOL) _value_ {
  hasOriginalWidth_ = !!_value_;
}
@synthesize originalWidth;
- (BOOL) hasOriginalHeight {
  return !!hasOriginalHeight_;
}
- (void) setHasOriginalHeight:(BOOL) _value_ {
  hasOriginalHeight_ = !!_value_;
}
@synthesize originalHeight;
- (BOOL) hasMimeType {
  return !!hasMimeType_;
}
- (void) setHasMimeType:(BOOL) _value_ {
  hasMimeType_ = !!_value_;
}
@synthesize mimeType;
- (BOOL) hasSize {
  return !!hasSize_;
}
- (void) setHasSize:(BOOL) _value_ {
  hasSize_ = !!_value_;
}
@synthesize size;
- (BOOL) hasOtrKey {
  return !!hasOtrKey_;
}
- (void) setHasOtrKey:(BOOL) _value_ {
  hasOtrKey_ = !!_value_;
}
@synthesize otrKey;
- (BOOL) hasMacKey {
  return !!hasMacKey_;
}
- (void) setHasMacKey:(BOOL) _value_ {
  hasMacKey_ = !!_value_;
}
@synthesize macKey;
- (BOOL) hasMac {
  return !!hasMac_;
}
- (void) setHasMac:(BOOL) _value_ {
  hasMac_ = !!_value_;
}
@synthesize mac;
- (BOOL) hasSha256 {
  return !!hasSha256_;
}
- (void) setHasSha256:(BOOL) _value_ {
  hasSha256_ = !!_value_;
}
@synthesize sha256;
- (instancetype) init {
  if ((self = [super init])) {
    self.tag = @"";
    self.width = 0;
    self.height = 0;
    self.originalWidth = 0;
    self.originalHeight = 0;
    self.mimeType = @"";
    self.size = 0;
    self.otrKey = [NSData data];
    self.macKey = [NSData data];
    self.mac = [NSData data];
    self.sha256 = [NSData data];
  }
  return self;
}
static ZMImageAsset* defaultZMImageAssetInstance = nil;
+ (void) initialize {
  if (self == [ZMImageAsset class]) {
    defaultZMImageAssetInstance = [[ZMImageAsset alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMImageAssetInstance;
}
- (instancetype) defaultInstance {
  return defaultZMImageAssetInstance;
}
- (BOOL) isInitialized {
  if (!self.hasTag) {
    return NO;
  }
  if (!self.hasWidth) {
    return NO;
  }
  if (!self.hasHeight) {
    return NO;
  }
  if (!self.hasOriginalWidth) {
    return NO;
  }
  if (!self.hasOriginalHeight) {
    return NO;
  }
  if (!self.hasMimeType) {
    return NO;
  }
  if (!self.hasSize) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasTag) {
    [output writeString:1 value:self.tag];
  }
  if (self.hasWidth) {
    [output writeInt32:2 value:self.width];
  }
  if (self.hasHeight) {
    [output writeInt32:3 value:self.height];
  }
  if (self.hasOriginalWidth) {
    [output writeInt32:4 value:self.originalWidth];
  }
  if (self.hasOriginalHeight) {
    [output writeInt32:5 value:self.originalHeight];
  }
  if (self.hasMimeType) {
    [output writeString:6 value:self.mimeType];
  }
  if (self.hasSize) {
    [output writeInt32:7 value:self.size];
  }
  if (self.hasOtrKey) {
    [output writeData:8 value:self.otrKey];
  }
  if (self.hasMacKey) {
    [output writeData:9 value:self.macKey];
  }
  if (self.hasMac) {
    [output writeData:10 value:self.mac];
  }
  if (self.hasSha256) {
    [output writeData:11 value:self.sha256];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasTag) {
    size_ += computeStringSize(1, self.tag);
  }
  if (self.hasWidth) {
    size_ += computeInt32Size(2, self.width);
  }
  if (self.hasHeight) {
    size_ += computeInt32Size(3, self.height);
  }
  if (self.hasOriginalWidth) {
    size_ += computeInt32Size(4, self.originalWidth);
  }
  if (self.hasOriginalHeight) {
    size_ += computeInt32Size(5, self.originalHeight);
  }
  if (self.hasMimeType) {
    size_ += computeStringSize(6, self.mimeType);
  }
  if (self.hasSize) {
    size_ += computeInt32Size(7, self.size);
  }
  if (self.hasOtrKey) {
    size_ += computeDataSize(8, self.otrKey);
  }
  if (self.hasMacKey) {
    size_ += computeDataSize(9, self.macKey);
  }
  if (self.hasMac) {
    size_ += computeDataSize(10, self.mac);
  }
  if (self.hasSha256) {
    size_ += computeDataSize(11, self.sha256);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMImageAsset*) parseFromData:(NSData*) data {
  return (ZMImageAsset*)[[[ZMImageAsset builder] mergeFromData:data] build];
}
+ (ZMImageAsset*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMImageAsset*)[[[ZMImageAsset builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMImageAsset*) parseFromInputStream:(NSInputStream*) input {
  return (ZMImageAsset*)[[[ZMImageAsset builder] mergeFromInputStream:input] build];
}
+ (ZMImageAsset*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMImageAsset*)[[[ZMImageAsset builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMImageAsset*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMImageAsset*)[[[ZMImageAsset builder] mergeFromCodedInputStream:input] build];
}
+ (ZMImageAsset*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMImageAsset*)[[[ZMImageAsset builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMImageAssetBuilder*) builder {
  return [[ZMImageAssetBuilder alloc] init];
}
+ (ZMImageAssetBuilder*) builderWithPrototype:(ZMImageAsset*) prototype {
  return [[ZMImageAsset builder] mergeFrom:prototype];
}
- (ZMImageAssetBuilder*) builder {
  return [ZMImageAsset builder];
}
- (ZMImageAssetBuilder*) toBuilder {
  return [ZMImageAsset builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasTag) {
    [output appendFormat:@"%@%@: %@\n", indent, @"tag", self.tag];
  }
  if (self.hasWidth) {
    [output appendFormat:@"%@%@: %@\n", indent, @"width", [NSNumber numberWithInteger:self.width]];
  }
  if (self.hasHeight) {
    [output appendFormat:@"%@%@: %@\n", indent, @"height", [NSNumber numberWithInteger:self.height]];
  }
  if (self.hasOriginalWidth) {
    [output appendFormat:@"%@%@: %@\n", indent, @"originalWidth", [NSNumber numberWithInteger:self.originalWidth]];
  }
  if (self.hasOriginalHeight) {
    [output appendFormat:@"%@%@: %@\n", indent, @"originalHeight", [NSNumber numberWithInteger:self.originalHeight]];
  }
  if (self.hasMimeType) {
    [output appendFormat:@"%@%@: %@\n", indent, @"mimeType", self.mimeType];
  }
  if (self.hasSize) {
    [output appendFormat:@"%@%@: %@\n", indent, @"size", [NSNumber numberWithInteger:self.size]];
  }
  if (self.hasOtrKey) {
    [output appendFormat:@"%@%@: %@\n", indent, @"otrKey", self.otrKey];
  }
  if (self.hasMacKey) {
    [output appendFormat:@"%@%@: %@\n", indent, @"macKey", self.macKey];
  }
  if (self.hasMac) {
    [output appendFormat:@"%@%@: %@\n", indent, @"mac", self.mac];
  }
  if (self.hasSha256) {
    [output appendFormat:@"%@%@: %@\n", indent, @"sha256", self.sha256];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasTag) {
    [dictionary setObject: self.tag forKey: @"tag"];
  }
  if (self.hasWidth) {
    [dictionary setObject: [NSNumber numberWithInteger:self.width] forKey: @"width"];
  }
  if (self.hasHeight) {
    [dictionary setObject: [NSNumber numberWithInteger:self.height] forKey: @"height"];
  }
  if (self.hasOriginalWidth) {
    [dictionary setObject: [NSNumber numberWithInteger:self.originalWidth] forKey: @"originalWidth"];
  }
  if (self.hasOriginalHeight) {
    [dictionary setObject: [NSNumber numberWithInteger:self.originalHeight] forKey: @"originalHeight"];
  }
  if (self.hasMimeType) {
    [dictionary setObject: self.mimeType forKey: @"mimeType"];
  }
  if (self.hasSize) {
    [dictionary setObject: [NSNumber numberWithInteger:self.size] forKey: @"size"];
  }
  if (self.hasOtrKey) {
    [dictionary setObject: self.otrKey forKey: @"otrKey"];
  }
  if (self.hasMacKey) {
    [dictionary setObject: self.macKey forKey: @"macKey"];
  }
  if (self.hasMac) {
    [dictionary setObject: self.mac forKey: @"mac"];
  }
  if (self.hasSha256) {
    [dictionary setObject: self.sha256 forKey: @"sha256"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMImageAsset class]]) {
    return NO;
  }
  ZMImageAsset *otherMessage = other;
  return
      self.hasTag == otherMessage.hasTag &&
      (!self.hasTag || [self.tag isEqual:otherMessage.tag]) &&
      self.hasWidth == otherMessage.hasWidth &&
      (!self.hasWidth || self.width == otherMessage.width) &&
      self.hasHeight == otherMessage.hasHeight &&
      (!self.hasHeight || self.height == otherMessage.height) &&
      self.hasOriginalWidth == otherMessage.hasOriginalWidth &&
      (!self.hasOriginalWidth || self.originalWidth == otherMessage.originalWidth) &&
      self.hasOriginalHeight == otherMessage.hasOriginalHeight &&
      (!self.hasOriginalHeight || self.originalHeight == otherMessage.originalHeight) &&
      self.hasMimeType == otherMessage.hasMimeType &&
      (!self.hasMimeType || [self.mimeType isEqual:otherMessage.mimeType]) &&
      self.hasSize == otherMessage.hasSize &&
      (!self.hasSize || self.size == otherMessage.size) &&
      self.hasOtrKey == otherMessage.hasOtrKey &&
      (!self.hasOtrKey || [self.otrKey isEqual:otherMessage.otrKey]) &&
      self.hasMacKey == otherMessage.hasMacKey &&
      (!self.hasMacKey || [self.macKey isEqual:otherMessage.macKey]) &&
      self.hasMac == otherMessage.hasMac &&
      (!self.hasMac || [self.mac isEqual:otherMessage.mac]) &&
      self.hasSha256 == otherMessage.hasSha256 &&
      (!self.hasSha256 || [self.sha256 isEqual:otherMessage.sha256]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasTag) {
    hashCode = hashCode * 31 + [self.tag hash];
  }
  if (self.hasWidth) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.width] hash];
  }
  if (self.hasHeight) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.height] hash];
  }
  if (self.hasOriginalWidth) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.originalWidth] hash];
  }
  if (self.hasOriginalHeight) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.originalHeight] hash];
  }
  if (self.hasMimeType) {
    hashCode = hashCode * 31 + [self.mimeType hash];
  }
  if (self.hasSize) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.size] hash];
  }
  if (self.hasOtrKey) {
    hashCode = hashCode * 31 + [self.otrKey hash];
  }
  if (self.hasMacKey) {
    hashCode = hashCode * 31 + [self.macKey hash];
  }
  if (self.hasMac) {
    hashCode = hashCode * 31 + [self.mac hash];
  }
  if (self.hasSha256) {
    hashCode = hashCode * 31 + [self.sha256 hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMImageAssetBuilder()
@property (strong) ZMImageAsset* resultImageAsset;
@end

@implementation ZMImageAssetBuilder
@synthesize resultImageAsset;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultImageAsset = [[ZMImageAsset alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultImageAsset;
}
- (ZMImageAssetBuilder*) clear {
  self.resultImageAsset = [[ZMImageAsset alloc] init];
  return self;
}
- (ZMImageAssetBuilder*) clone {
  return [ZMImageAsset builderWithPrototype:resultImageAsset];
}
- (ZMImageAsset*) defaultInstance {
  return [ZMImageAsset defaultInstance];
}
- (ZMImageAsset*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMImageAsset*) buildPartial {
  ZMImageAsset* returnMe = resultImageAsset;
  self.resultImageAsset = nil;
  return returnMe;
}
- (ZMImageAssetBuilder*) mergeFrom:(ZMImageAsset*) other {
  if (other == [ZMImageAsset defaultInstance]) {
    return self;
  }
  if (other.hasTag) {
    [self setTag:other.tag];
  }
  if (other.hasWidth) {
    [self setWidth:other.width];
  }
  if (other.hasHeight) {
    [self setHeight:other.height];
  }
  if (other.hasOriginalWidth) {
    [self setOriginalWidth:other.originalWidth];
  }
  if (other.hasOriginalHeight) {
    [self setOriginalHeight:other.originalHeight];
  }
  if (other.hasMimeType) {
    [self setMimeType:other.mimeType];
  }
  if (other.hasSize) {
    [self setSize:other.size];
  }
  if (other.hasOtrKey) {
    [self setOtrKey:other.otrKey];
  }
  if (other.hasMacKey) {
    [self setMacKey:other.macKey];
  }
  if (other.hasMac) {
    [self setMac:other.mac];
  }
  if (other.hasSha256) {
    [self setSha256:other.sha256];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMImageAssetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMImageAssetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setTag:[input readString]];
        break;
      }
      case 16: {
        [self setWidth:[input readInt32]];
        break;
      }
      case 24: {
        [self setHeight:[input readInt32]];
        break;
      }
      case 32: {
        [self setOriginalWidth:[input readInt32]];
        break;
      }
      case 40: {
        [self setOriginalHeight:[input readInt32]];
        break;
      }
      case 50: {
        [self setMimeType:[input readString]];
        break;
      }
      case 56: {
        [self setSize:[input readInt32]];
        break;
      }
      case 66: {
        [self setOtrKey:[input readData]];
        break;
      }
      case 74: {
        [self setMacKey:[input readData]];
        break;
      }
      case 82: {
        [self setMac:[input readData]];
        break;
      }
      case 90: {
        [self setSha256:[input readData]];
        break;
      }
    }
  }
}
- (BOOL) hasTag {
  return resultImageAsset.hasTag;
}
- (NSString*) tag {
  return resultImageAsset.tag;
}
- (ZMImageAssetBuilder*) setTag:(NSString*) value {
  resultImageAsset.hasTag = YES;
  resultImageAsset.tag = value;
  return self;
}
- (ZMImageAssetBuilder*) clearTag {
  resultImageAsset.hasTag = NO;
  resultImageAsset.tag = @"";
  return self;
}
- (BOOL) hasWidth {
  return resultImageAsset.hasWidth;
}
- (SInt32) width {
  return resultImageAsset.width;
}
- (ZMImageAssetBuilder*) setWidth:(SInt32) value {
  resultImageAsset.hasWidth = YES;
  resultImageAsset.width = value;
  return self;
}
- (ZMImageAssetBuilder*) clearWidth {
  resultImageAsset.hasWidth = NO;
  resultImageAsset.width = 0;
  return self;
}
- (BOOL) hasHeight {
  return resultImageAsset.hasHeight;
}
- (SInt32) height {
  return resultImageAsset.height;
}
- (ZMImageAssetBuilder*) setHeight:(SInt32) value {
  resultImageAsset.hasHeight = YES;
  resultImageAsset.height = value;
  return self;
}
- (ZMImageAssetBuilder*) clearHeight {
  resultImageAsset.hasHeight = NO;
  resultImageAsset.height = 0;
  return self;
}
- (BOOL) hasOriginalWidth {
  return resultImageAsset.hasOriginalWidth;
}
- (SInt32) originalWidth {
  return resultImageAsset.originalWidth;
}
- (ZMImageAssetBuilder*) setOriginalWidth:(SInt32) value {
  resultImageAsset.hasOriginalWidth = YES;
  resultImageAsset.originalWidth = value;
  return self;
}
- (ZMImageAssetBuilder*) clearOriginalWidth {
  resultImageAsset.hasOriginalWidth = NO;
  resultImageAsset.originalWidth = 0;
  return self;
}
- (BOOL) hasOriginalHeight {
  return resultImageAsset.hasOriginalHeight;
}
- (SInt32) originalHeight {
  return resultImageAsset.originalHeight;
}
- (ZMImageAssetBuilder*) setOriginalHeight:(SInt32) value {
  resultImageAsset.hasOriginalHeight = YES;
  resultImageAsset.originalHeight = value;
  return self;
}
- (ZMImageAssetBuilder*) clearOriginalHeight {
  resultImageAsset.hasOriginalHeight = NO;
  resultImageAsset.originalHeight = 0;
  return self;
}
- (BOOL) hasMimeType {
  return resultImageAsset.hasMimeType;
}
- (NSString*) mimeType {
  return resultImageAsset.mimeType;
}
- (ZMImageAssetBuilder*) setMimeType:(NSString*) value {
  resultImageAsset.hasMimeType = YES;
  resultImageAsset.mimeType = value;
  return self;
}
- (ZMImageAssetBuilder*) clearMimeType {
  resultImageAsset.hasMimeType = NO;
  resultImageAsset.mimeType = @"";
  return self;
}
- (BOOL) hasSize {
  return resultImageAsset.hasSize;
}
- (SInt32) size {
  return resultImageAsset.size;
}
- (ZMImageAssetBuilder*) setSize:(SInt32) value {
  resultImageAsset.hasSize = YES;
  resultImageAsset.size = value;
  return self;
}
- (ZMImageAssetBuilder*) clearSize {
  resultImageAsset.hasSize = NO;
  resultImageAsset.size = 0;
  return self;
}
- (BOOL) hasOtrKey {
  return resultImageAsset.hasOtrKey;
}
- (NSData*) otrKey {
  return resultImageAsset.otrKey;
}
- (ZMImageAssetBuilder*) setOtrKey:(NSData*) value {
  resultImageAsset.hasOtrKey = YES;
  resultImageAsset.otrKey = value;
  return self;
}
- (ZMImageAssetBuilder*) clearOtrKey {
  resultImageAsset.hasOtrKey = NO;
  resultImageAsset.otrKey = [NSData data];
  return self;
}
- (BOOL) hasMacKey {
  return resultImageAsset.hasMacKey;
}
- (NSData*) macKey {
  return resultImageAsset.macKey;
}
- (ZMImageAssetBuilder*) setMacKey:(NSData*) value {
  resultImageAsset.hasMacKey = YES;
  resultImageAsset.macKey = value;
  return self;
}
- (ZMImageAssetBuilder*) clearMacKey {
  resultImageAsset.hasMacKey = NO;
  resultImageAsset.macKey = [NSData data];
  return self;
}
- (BOOL) hasMac {
  return resultImageAsset.hasMac;
}
- (NSData*) mac {
  return resultImageAsset.mac;
}
- (ZMImageAssetBuilder*) setMac:(NSData*) value {
  resultImageAsset.hasMac = YES;
  resultImageAsset.mac = value;
  return self;
}
- (ZMImageAssetBuilder*) clearMac {
  resultImageAsset.hasMac = NO;
  resultImageAsset.mac = [NSData data];
  return self;
}
- (BOOL) hasSha256 {
  return resultImageAsset.hasSha256;
}
- (NSData*) sha256 {
  return resultImageAsset.sha256;
}
- (ZMImageAssetBuilder*) setSha256:(NSData*) value {
  resultImageAsset.hasSha256 = YES;
  resultImageAsset.sha256 = value;
  return self;
}
- (ZMImageAssetBuilder*) clearSha256 {
  resultImageAsset.hasSha256 = NO;
  resultImageAsset.sha256 = [NSData data];
  return self;
}
@end

@interface ZMAsset ()
@property (strong) ZMAssetOriginal* original;
@property (strong) ZMAssetPreview* preview;
@property ZMAssetNotUploaded notUploaded;
@property (strong) ZMAssetUploaded* uploaded;
@end

@implementation ZMAsset

- (BOOL) hasOriginal {
  return !!hasOriginal_;
}
- (void) setHasOriginal:(BOOL) _value_ {
  hasOriginal_ = !!_value_;
}
@synthesize original;
- (BOOL) hasPreview {
  return !!hasPreview_;
}
- (void) setHasPreview:(BOOL) _value_ {
  hasPreview_ = !!_value_;
}
@synthesize preview;
- (BOOL) hasNotUploaded {
  return !!hasNotUploaded_;
}
- (void) setHasNotUploaded:(BOOL) _value_ {
  hasNotUploaded_ = !!_value_;
}
@synthesize notUploaded;
- (BOOL) hasUploaded {
  return !!hasUploaded_;
}
- (void) setHasUploaded:(BOOL) _value_ {
  hasUploaded_ = !!_value_;
}
@synthesize uploaded;
- (instancetype) init {
  if ((self = [super init])) {
    self.original = [ZMAssetOriginal defaultInstance];
    self.preview = [ZMAssetPreview defaultInstance];
    self.notUploaded = ZMAssetNotUploadedCANCELLED;
    self.uploaded = [ZMAssetUploaded defaultInstance];
  }
  return self;
}
static ZMAsset* defaultZMAssetInstance = nil;
+ (void) initialize {
  if (self == [ZMAsset class]) {
    defaultZMAssetInstance = [[ZMAsset alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMAssetInstance;
}
- (instancetype) defaultInstance {
  return defaultZMAssetInstance;
}
- (BOOL) isInitialized {
  if (self.hasOriginal) {
    if (!self.original.isInitialized) {
      return NO;
    }
  }
  if (self.hasPreview) {
    if (!self.preview.isInitialized) {
      return NO;
    }
  }
  if (self.hasUploaded) {
    if (!self.uploaded.isInitialized) {
      return NO;
    }
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasOriginal) {
    [output writeMessage:1 value:self.original];
  }
  if (self.hasPreview) {
    [output writeMessage:2 value:self.preview];
  }
  if (self.hasNotUploaded) {
    [output writeEnum:3 value:self.notUploaded];
  }
  if (self.hasUploaded) {
    [output writeMessage:4 value:self.uploaded];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasOriginal) {
    size_ += computeMessageSize(1, self.original);
  }
  if (self.hasPreview) {
    size_ += computeMessageSize(2, self.preview);
  }
  if (self.hasNotUploaded) {
    size_ += computeEnumSize(3, self.notUploaded);
  }
  if (self.hasUploaded) {
    size_ += computeMessageSize(4, self.uploaded);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMAsset*) parseFromData:(NSData*) data {
  return (ZMAsset*)[[[ZMAsset builder] mergeFromData:data] build];
}
+ (ZMAsset*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAsset*)[[[ZMAsset builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMAsset*) parseFromInputStream:(NSInputStream*) input {
  return (ZMAsset*)[[[ZMAsset builder] mergeFromInputStream:input] build];
}
+ (ZMAsset*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAsset*)[[[ZMAsset builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAsset*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMAsset*)[[[ZMAsset builder] mergeFromCodedInputStream:input] build];
}
+ (ZMAsset*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAsset*)[[[ZMAsset builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetBuilder*) builder {
  return [[ZMAssetBuilder alloc] init];
}
+ (ZMAssetBuilder*) builderWithPrototype:(ZMAsset*) prototype {
  return [[ZMAsset builder] mergeFrom:prototype];
}
- (ZMAssetBuilder*) builder {
  return [ZMAsset builder];
}
- (ZMAssetBuilder*) toBuilder {
  return [ZMAsset builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasOriginal) {
    [output appendFormat:@"%@%@ {\n", indent, @"original"];
    [self.original writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasPreview) {
    [output appendFormat:@"%@%@ {\n", indent, @"preview"];
    [self.preview writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasNotUploaded) {
    [output appendFormat:@"%@%@: %@\n", indent, @"notUploaded", NSStringFromZMAssetNotUploaded(self.notUploaded)];
  }
  if (self.hasUploaded) {
    [output appendFormat:@"%@%@ {\n", indent, @"uploaded"];
    [self.uploaded writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasOriginal) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.original storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"original"];
  }
  if (self.hasPreview) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.preview storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"preview"];
  }
  if (self.hasNotUploaded) {
    [dictionary setObject: @(self.notUploaded) forKey: @"notUploaded"];
  }
  if (self.hasUploaded) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.uploaded storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"uploaded"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMAsset class]]) {
    return NO;
  }
  ZMAsset *otherMessage = other;
  return
      self.hasOriginal == otherMessage.hasOriginal &&
      (!self.hasOriginal || [self.original isEqual:otherMessage.original]) &&
      self.hasPreview == otherMessage.hasPreview &&
      (!self.hasPreview || [self.preview isEqual:otherMessage.preview]) &&
      self.hasNotUploaded == otherMessage.hasNotUploaded &&
      (!self.hasNotUploaded || self.notUploaded == otherMessage.notUploaded) &&
      self.hasUploaded == otherMessage.hasUploaded &&
      (!self.hasUploaded || [self.uploaded isEqual:otherMessage.uploaded]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasOriginal) {
    hashCode = hashCode * 31 + [self.original hash];
  }
  if (self.hasPreview) {
    hashCode = hashCode * 31 + [self.preview hash];
  }
  if (self.hasNotUploaded) {
    hashCode = hashCode * 31 + self.notUploaded;
  }
  if (self.hasUploaded) {
    hashCode = hashCode * 31 + [self.uploaded hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

BOOL ZMAssetNotUploadedIsValidValue(ZMAssetNotUploaded value) {
  switch (value) {
    case ZMAssetNotUploadedCANCELLED:
    case ZMAssetNotUploadedFAILED:
      return YES;
    default:
      return NO;
  }
}
NSString *NSStringFromZMAssetNotUploaded(ZMAssetNotUploaded value) {
  switch (value) {
    case ZMAssetNotUploadedCANCELLED:
      return @"ZMAssetNotUploadedCANCELLED";
    case ZMAssetNotUploadedFAILED:
      return @"ZMAssetNotUploadedFAILED";
    default:
      return nil;
  }
}

@interface ZMAssetOriginal ()
@property (strong) NSString* mimeType;
@property UInt64 size;
@property (strong) NSString* name;
@property (strong) ZMAssetImageMetaData* image;
@property (strong) ZMAssetVideoMetaData* video;
@end

@implementation ZMAssetOriginal

- (BOOL) hasMimeType {
  return !!hasMimeType_;
}
- (void) setHasMimeType:(BOOL) _value_ {
  hasMimeType_ = !!_value_;
}
@synthesize mimeType;
- (BOOL) hasSize {
  return !!hasSize_;
}
- (void) setHasSize:(BOOL) _value_ {
  hasSize_ = !!_value_;
}
@synthesize size;
- (BOOL) hasName {
  return !!hasName_;
}
- (void) setHasName:(BOOL) _value_ {
  hasName_ = !!_value_;
}
@synthesize name;
- (BOOL) hasImage {
  return !!hasImage_;
}
- (void) setHasImage:(BOOL) _value_ {
  hasImage_ = !!_value_;
}
@synthesize image;
- (BOOL) hasVideo {
  return !!hasVideo_;
}
- (void) setHasVideo:(BOOL) _value_ {
  hasVideo_ = !!_value_;
}
@synthesize video;
- (instancetype) init {
  if ((self = [super init])) {
    self.mimeType = @"";
    self.size = 0L;
    self.name = @"";
    self.image = [ZMAssetImageMetaData defaultInstance];
    self.video = [ZMAssetVideoMetaData defaultInstance];
  }
  return self;
}
static ZMAssetOriginal* defaultZMAssetOriginalInstance = nil;
+ (void) initialize {
  if (self == [ZMAssetOriginal class]) {
    defaultZMAssetOriginalInstance = [[ZMAssetOriginal alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMAssetOriginalInstance;
}
- (instancetype) defaultInstance {
  return defaultZMAssetOriginalInstance;
}
- (BOOL) isInitialized {
  if (!self.hasMimeType) {
    return NO;
  }
  if (!self.hasSize) {
    return NO;
  }
  if (self.hasImage) {
    if (!self.image.isInitialized) {
      return NO;
    }
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasMimeType) {
    [output writeString:1 value:self.mimeType];
  }
  if (self.hasSize) {
    [output writeUInt64:2 value:self.size];
  }
  if (self.hasName) {
    [output writeString:3 value:self.name];
  }
  if (self.hasImage) {
    [output writeMessage:4 value:self.image];
  }
  if (self.hasVideo) {
    [output writeMessage:5 value:self.video];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasMimeType) {
    size_ += computeStringSize(1, self.mimeType);
  }
  if (self.hasSize) {
    size_ += computeUInt64Size(2, self.size);
  }
  if (self.hasName) {
    size_ += computeStringSize(3, self.name);
  }
  if (self.hasImage) {
    size_ += computeMessageSize(4, self.image);
  }
  if (self.hasVideo) {
    size_ += computeMessageSize(5, self.video);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMAssetOriginal*) parseFromData:(NSData*) data {
  return (ZMAssetOriginal*)[[[ZMAssetOriginal builder] mergeFromData:data] build];
}
+ (ZMAssetOriginal*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetOriginal*)[[[ZMAssetOriginal builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetOriginal*) parseFromInputStream:(NSInputStream*) input {
  return (ZMAssetOriginal*)[[[ZMAssetOriginal builder] mergeFromInputStream:input] build];
}
+ (ZMAssetOriginal*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetOriginal*)[[[ZMAssetOriginal builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetOriginal*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMAssetOriginal*)[[[ZMAssetOriginal builder] mergeFromCodedInputStream:input] build];
}
+ (ZMAssetOriginal*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetOriginal*)[[[ZMAssetOriginal builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetOriginalBuilder*) builder {
  return [[ZMAssetOriginalBuilder alloc] init];
}
+ (ZMAssetOriginalBuilder*) builderWithPrototype:(ZMAssetOriginal*) prototype {
  return [[ZMAssetOriginal builder] mergeFrom:prototype];
}
- (ZMAssetOriginalBuilder*) builder {
  return [ZMAssetOriginal builder];
}
- (ZMAssetOriginalBuilder*) toBuilder {
  return [ZMAssetOriginal builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasMimeType) {
    [output appendFormat:@"%@%@: %@\n", indent, @"mimeType", self.mimeType];
  }
  if (self.hasSize) {
    [output appendFormat:@"%@%@: %@\n", indent, @"size", [NSNumber numberWithLongLong:self.size]];
  }
  if (self.hasName) {
    [output appendFormat:@"%@%@: %@\n", indent, @"name", self.name];
  }
  if (self.hasImage) {
    [output appendFormat:@"%@%@ {\n", indent, @"image"];
    [self.image writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasVideo) {
    [output appendFormat:@"%@%@ {\n", indent, @"video"];
    [self.video writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasMimeType) {
    [dictionary setObject: self.mimeType forKey: @"mimeType"];
  }
  if (self.hasSize) {
    [dictionary setObject: [NSNumber numberWithLongLong:self.size] forKey: @"size"];
  }
  if (self.hasName) {
    [dictionary setObject: self.name forKey: @"name"];
  }
  if (self.hasImage) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.image storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"image"];
  }
  if (self.hasVideo) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.video storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"video"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMAssetOriginal class]]) {
    return NO;
  }
  ZMAssetOriginal *otherMessage = other;
  return
      self.hasMimeType == otherMessage.hasMimeType &&
      (!self.hasMimeType || [self.mimeType isEqual:otherMessage.mimeType]) &&
      self.hasSize == otherMessage.hasSize &&
      (!self.hasSize || self.size == otherMessage.size) &&
      self.hasName == otherMessage.hasName &&
      (!self.hasName || [self.name isEqual:otherMessage.name]) &&
      self.hasImage == otherMessage.hasImage &&
      (!self.hasImage || [self.image isEqual:otherMessage.image]) &&
      self.hasVideo == otherMessage.hasVideo &&
      (!self.hasVideo || [self.video isEqual:otherMessage.video]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasMimeType) {
    hashCode = hashCode * 31 + [self.mimeType hash];
  }
  if (self.hasSize) {
    hashCode = hashCode * 31 + [[NSNumber numberWithLongLong:self.size] hash];
  }
  if (self.hasName) {
    hashCode = hashCode * 31 + [self.name hash];
  }
  if (self.hasImage) {
    hashCode = hashCode * 31 + [self.image hash];
  }
  if (self.hasVideo) {
    hashCode = hashCode * 31 + [self.video hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMAssetOriginalBuilder()
@property (strong) ZMAssetOriginal* resultOriginal;
@end

@implementation ZMAssetOriginalBuilder
@synthesize resultOriginal;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultOriginal = [[ZMAssetOriginal alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultOriginal;
}
- (ZMAssetOriginalBuilder*) clear {
  self.resultOriginal = [[ZMAssetOriginal alloc] init];
  return self;
}
- (ZMAssetOriginalBuilder*) clone {
  return [ZMAssetOriginal builderWithPrototype:resultOriginal];
}
- (ZMAssetOriginal*) defaultInstance {
  return [ZMAssetOriginal defaultInstance];
}
- (ZMAssetOriginal*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMAssetOriginal*) buildPartial {
  ZMAssetOriginal* returnMe = resultOriginal;
  self.resultOriginal = nil;
  return returnMe;
}
- (ZMAssetOriginalBuilder*) mergeFrom:(ZMAssetOriginal*) other {
  if (other == [ZMAssetOriginal defaultInstance]) {
    return self;
  }
  if (other.hasMimeType) {
    [self setMimeType:other.mimeType];
  }
  if (other.hasSize) {
    [self setSize:other.size];
  }
  if (other.hasName) {
    [self setName:other.name];
  }
  if (other.hasImage) {
    [self mergeImage:other.image];
  }
  if (other.hasVideo) {
    [self mergeVideo:other.video];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMAssetOriginalBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMAssetOriginalBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setMimeType:[input readString]];
        break;
      }
      case 16: {
        [self setSize:[input readUInt64]];
        break;
      }
      case 26: {
        [self setName:[input readString]];
        break;
      }
      case 34: {
        ZMAssetImageMetaDataBuilder* subBuilder = [ZMAssetImageMetaData builder];
        if (self.hasImage) {
          [subBuilder mergeFrom:self.image];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setImage:[subBuilder buildPartial]];
        break;
      }
      case 42: {
        ZMAssetVideoMetaDataBuilder* subBuilder = [ZMAssetVideoMetaData builder];
        if (self.hasVideo) {
          [subBuilder mergeFrom:self.video];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setVideo:[subBuilder buildPartial]];
        break;
      }
    }
  }
}
- (BOOL) hasMimeType {
  return resultOriginal.hasMimeType;
}
- (NSString*) mimeType {
  return resultOriginal.mimeType;
}
- (ZMAssetOriginalBuilder*) setMimeType:(NSString*) value {
  resultOriginal.hasMimeType = YES;
  resultOriginal.mimeType = value;
  return self;
}
- (ZMAssetOriginalBuilder*) clearMimeType {
  resultOriginal.hasMimeType = NO;
  resultOriginal.mimeType = @"";
  return self;
}
- (BOOL) hasSize {
  return resultOriginal.hasSize;
}
- (UInt64) size {
  return resultOriginal.size;
}
- (ZMAssetOriginalBuilder*) setSize:(UInt64) value {
  resultOriginal.hasSize = YES;
  resultOriginal.size = value;
  return self;
}
- (ZMAssetOriginalBuilder*) clearSize {
  resultOriginal.hasSize = NO;
  resultOriginal.size = 0L;
  return self;
}
- (BOOL) hasName {
  return resultOriginal.hasName;
}
- (NSString*) name {
  return resultOriginal.name;
}
- (ZMAssetOriginalBuilder*) setName:(NSString*) value {
  resultOriginal.hasName = YES;
  resultOriginal.name = value;
  return self;
}
- (ZMAssetOriginalBuilder*) clearName {
  resultOriginal.hasName = NO;
  resultOriginal.name = @"";
  return self;
}
- (BOOL) hasImage {
  return resultOriginal.hasImage;
}
- (ZMAssetImageMetaData*) image {
  return resultOriginal.image;
}
- (ZMAssetOriginalBuilder*) setImage:(ZMAssetImageMetaData*) value {
  resultOriginal.hasImage = YES;
  resultOriginal.image = value;
  return self;
}
- (ZMAssetOriginalBuilder*) setImageBuilder:(ZMAssetImageMetaDataBuilder*) builderForValue {
  return [self setImage:[builderForValue build]];
}
- (ZMAssetOriginalBuilder*) mergeImage:(ZMAssetImageMetaData*) value {
  if (resultOriginal.hasImage &&
      resultOriginal.image != [ZMAssetImageMetaData defaultInstance]) {
    resultOriginal.image =
      [[[ZMAssetImageMetaData builderWithPrototype:resultOriginal.image] mergeFrom:value] buildPartial];
  } else {
    resultOriginal.image = value;
  }
  resultOriginal.hasImage = YES;
  return self;
}
- (ZMAssetOriginalBuilder*) clearImage {
  resultOriginal.hasImage = NO;
  resultOriginal.image = [ZMAssetImageMetaData defaultInstance];
  return self;
}
- (BOOL) hasVideo {
  return resultOriginal.hasVideo;
}
- (ZMAssetVideoMetaData*) video {
  return resultOriginal.video;
}
- (ZMAssetOriginalBuilder*) setVideo:(ZMAssetVideoMetaData*) value {
  resultOriginal.hasVideo = YES;
  resultOriginal.video = value;
  return self;
}
- (ZMAssetOriginalBuilder*) setVideoBuilder:(ZMAssetVideoMetaDataBuilder*) builderForValue {
  return [self setVideo:[builderForValue build]];
}
- (ZMAssetOriginalBuilder*) mergeVideo:(ZMAssetVideoMetaData*) value {
  if (resultOriginal.hasVideo &&
      resultOriginal.video != [ZMAssetVideoMetaData defaultInstance]) {
    resultOriginal.video =
      [[[ZMAssetVideoMetaData builderWithPrototype:resultOriginal.video] mergeFrom:value] buildPartial];
  } else {
    resultOriginal.video = value;
  }
  resultOriginal.hasVideo = YES;
  return self;
}
- (ZMAssetOriginalBuilder*) clearVideo {
  resultOriginal.hasVideo = NO;
  resultOriginal.video = [ZMAssetVideoMetaData defaultInstance];
  return self;
}
@end

@interface ZMAssetPreview ()
@property (strong) NSString* mimeType;
@property (strong) NSData* otrKey;
@property (strong) NSData* sha256;
@property UInt64 size;
@property (strong) ZMAssetImageMetaData* image;
@end

@implementation ZMAssetPreview

- (BOOL) hasMimeType {
  return !!hasMimeType_;
}
- (void) setHasMimeType:(BOOL) _value_ {
  hasMimeType_ = !!_value_;
}
@synthesize mimeType;
- (BOOL) hasOtrKey {
  return !!hasOtrKey_;
}
- (void) setHasOtrKey:(BOOL) _value_ {
  hasOtrKey_ = !!_value_;
}
@synthesize otrKey;
- (BOOL) hasSha256 {
  return !!hasSha256_;
}
- (void) setHasSha256:(BOOL) _value_ {
  hasSha256_ = !!_value_;
}
@synthesize sha256;
- (BOOL) hasSize {
  return !!hasSize_;
}
- (void) setHasSize:(BOOL) _value_ {
  hasSize_ = !!_value_;
}
@synthesize size;
- (BOOL) hasImage {
  return !!hasImage_;
}
- (void) setHasImage:(BOOL) _value_ {
  hasImage_ = !!_value_;
}
@synthesize image;
- (instancetype) init {
  if ((self = [super init])) {
    self.mimeType = @"";
    self.otrKey = [NSData data];
    self.sha256 = [NSData data];
    self.size = 0L;
    self.image = [ZMAssetImageMetaData defaultInstance];
  }
  return self;
}
static ZMAssetPreview* defaultZMAssetPreviewInstance = nil;
+ (void) initialize {
  if (self == [ZMAssetPreview class]) {
    defaultZMAssetPreviewInstance = [[ZMAssetPreview alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMAssetPreviewInstance;
}
- (instancetype) defaultInstance {
  return defaultZMAssetPreviewInstance;
}
- (BOOL) isInitialized {
  if (!self.hasMimeType) {
    return NO;
  }
  if (!self.hasOtrKey) {
    return NO;
  }
  if (!self.hasSha256) {
    return NO;
  }
  if (!self.hasSize) {
    return NO;
  }
  if (self.hasImage) {
    if (!self.image.isInitialized) {
      return NO;
    }
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasMimeType) {
    [output writeString:1 value:self.mimeType];
  }
  if (self.hasOtrKey) {
    [output writeData:2 value:self.otrKey];
  }
  if (self.hasSha256) {
    [output writeData:3 value:self.sha256];
  }
  if (self.hasSize) {
    [output writeUInt64:4 value:self.size];
  }
  if (self.hasImage) {
    [output writeMessage:5 value:self.image];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasMimeType) {
    size_ += computeStringSize(1, self.mimeType);
  }
  if (self.hasOtrKey) {
    size_ += computeDataSize(2, self.otrKey);
  }
  if (self.hasSha256) {
    size_ += computeDataSize(3, self.sha256);
  }
  if (self.hasSize) {
    size_ += computeUInt64Size(4, self.size);
  }
  if (self.hasImage) {
    size_ += computeMessageSize(5, self.image);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMAssetPreview*) parseFromData:(NSData*) data {
  return (ZMAssetPreview*)[[[ZMAssetPreview builder] mergeFromData:data] build];
}
+ (ZMAssetPreview*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetPreview*)[[[ZMAssetPreview builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetPreview*) parseFromInputStream:(NSInputStream*) input {
  return (ZMAssetPreview*)[[[ZMAssetPreview builder] mergeFromInputStream:input] build];
}
+ (ZMAssetPreview*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetPreview*)[[[ZMAssetPreview builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetPreview*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMAssetPreview*)[[[ZMAssetPreview builder] mergeFromCodedInputStream:input] build];
}
+ (ZMAssetPreview*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetPreview*)[[[ZMAssetPreview builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetPreviewBuilder*) builder {
  return [[ZMAssetPreviewBuilder alloc] init];
}
+ (ZMAssetPreviewBuilder*) builderWithPrototype:(ZMAssetPreview*) prototype {
  return [[ZMAssetPreview builder] mergeFrom:prototype];
}
- (ZMAssetPreviewBuilder*) builder {
  return [ZMAssetPreview builder];
}
- (ZMAssetPreviewBuilder*) toBuilder {
  return [ZMAssetPreview builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasMimeType) {
    [output appendFormat:@"%@%@: %@\n", indent, @"mimeType", self.mimeType];
  }
  if (self.hasOtrKey) {
    [output appendFormat:@"%@%@: %@\n", indent, @"otrKey", self.otrKey];
  }
  if (self.hasSha256) {
    [output appendFormat:@"%@%@: %@\n", indent, @"sha256", self.sha256];
  }
  if (self.hasSize) {
    [output appendFormat:@"%@%@: %@\n", indent, @"size", [NSNumber numberWithLongLong:self.size]];
  }
  if (self.hasImage) {
    [output appendFormat:@"%@%@ {\n", indent, @"image"];
    [self.image writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasMimeType) {
    [dictionary setObject: self.mimeType forKey: @"mimeType"];
  }
  if (self.hasOtrKey) {
    [dictionary setObject: self.otrKey forKey: @"otrKey"];
  }
  if (self.hasSha256) {
    [dictionary setObject: self.sha256 forKey: @"sha256"];
  }
  if (self.hasSize) {
    [dictionary setObject: [NSNumber numberWithLongLong:self.size] forKey: @"size"];
  }
  if (self.hasImage) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.image storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"image"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMAssetPreview class]]) {
    return NO;
  }
  ZMAssetPreview *otherMessage = other;
  return
      self.hasMimeType == otherMessage.hasMimeType &&
      (!self.hasMimeType || [self.mimeType isEqual:otherMessage.mimeType]) &&
      self.hasOtrKey == otherMessage.hasOtrKey &&
      (!self.hasOtrKey || [self.otrKey isEqual:otherMessage.otrKey]) &&
      self.hasSha256 == otherMessage.hasSha256 &&
      (!self.hasSha256 || [self.sha256 isEqual:otherMessage.sha256]) &&
      self.hasSize == otherMessage.hasSize &&
      (!self.hasSize || self.size == otherMessage.size) &&
      self.hasImage == otherMessage.hasImage &&
      (!self.hasImage || [self.image isEqual:otherMessage.image]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasMimeType) {
    hashCode = hashCode * 31 + [self.mimeType hash];
  }
  if (self.hasOtrKey) {
    hashCode = hashCode * 31 + [self.otrKey hash];
  }
  if (self.hasSha256) {
    hashCode = hashCode * 31 + [self.sha256 hash];
  }
  if (self.hasSize) {
    hashCode = hashCode * 31 + [[NSNumber numberWithLongLong:self.size] hash];
  }
  if (self.hasImage) {
    hashCode = hashCode * 31 + [self.image hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMAssetPreviewBuilder()
@property (strong) ZMAssetPreview* resultPreview;
@end

@implementation ZMAssetPreviewBuilder
@synthesize resultPreview;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultPreview = [[ZMAssetPreview alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultPreview;
}
- (ZMAssetPreviewBuilder*) clear {
  self.resultPreview = [[ZMAssetPreview alloc] init];
  return self;
}
- (ZMAssetPreviewBuilder*) clone {
  return [ZMAssetPreview builderWithPrototype:resultPreview];
}
- (ZMAssetPreview*) defaultInstance {
  return [ZMAssetPreview defaultInstance];
}
- (ZMAssetPreview*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMAssetPreview*) buildPartial {
  ZMAssetPreview* returnMe = resultPreview;
  self.resultPreview = nil;
  return returnMe;
}
- (ZMAssetPreviewBuilder*) mergeFrom:(ZMAssetPreview*) other {
  if (other == [ZMAssetPreview defaultInstance]) {
    return self;
  }
  if (other.hasMimeType) {
    [self setMimeType:other.mimeType];
  }
  if (other.hasOtrKey) {
    [self setOtrKey:other.otrKey];
  }
  if (other.hasSha256) {
    [self setSha256:other.sha256];
  }
  if (other.hasSize) {
    [self setSize:other.size];
  }
  if (other.hasImage) {
    [self mergeImage:other.image];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMAssetPreviewBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMAssetPreviewBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setMimeType:[input readString]];
        break;
      }
      case 18: {
        [self setOtrKey:[input readData]];
        break;
      }
      case 26: {
        [self setSha256:[input readData]];
        break;
      }
      case 32: {
        [self setSize:[input readUInt64]];
        break;
      }
      case 42: {
        ZMAssetImageMetaDataBuilder* subBuilder = [ZMAssetImageMetaData builder];
        if (self.hasImage) {
          [subBuilder mergeFrom:self.image];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setImage:[subBuilder buildPartial]];
        break;
      }
    }
  }
}
- (BOOL) hasMimeType {
  return resultPreview.hasMimeType;
}
- (NSString*) mimeType {
  return resultPreview.mimeType;
}
- (ZMAssetPreviewBuilder*) setMimeType:(NSString*) value {
  resultPreview.hasMimeType = YES;
  resultPreview.mimeType = value;
  return self;
}
- (ZMAssetPreviewBuilder*) clearMimeType {
  resultPreview.hasMimeType = NO;
  resultPreview.mimeType = @"";
  return self;
}
- (BOOL) hasOtrKey {
  return resultPreview.hasOtrKey;
}
- (NSData*) otrKey {
  return resultPreview.otrKey;
}
- (ZMAssetPreviewBuilder*) setOtrKey:(NSData*) value {
  resultPreview.hasOtrKey = YES;
  resultPreview.otrKey = value;
  return self;
}
- (ZMAssetPreviewBuilder*) clearOtrKey {
  resultPreview.hasOtrKey = NO;
  resultPreview.otrKey = [NSData data];
  return self;
}
- (BOOL) hasSha256 {
  return resultPreview.hasSha256;
}
- (NSData*) sha256 {
  return resultPreview.sha256;
}
- (ZMAssetPreviewBuilder*) setSha256:(NSData*) value {
  resultPreview.hasSha256 = YES;
  resultPreview.sha256 = value;
  return self;
}
- (ZMAssetPreviewBuilder*) clearSha256 {
  resultPreview.hasSha256 = NO;
  resultPreview.sha256 = [NSData data];
  return self;
}
- (BOOL) hasSize {
  return resultPreview.hasSize;
}
- (UInt64) size {
  return resultPreview.size;
}
- (ZMAssetPreviewBuilder*) setSize:(UInt64) value {
  resultPreview.hasSize = YES;
  resultPreview.size = value;
  return self;
}
- (ZMAssetPreviewBuilder*) clearSize {
  resultPreview.hasSize = NO;
  resultPreview.size = 0L;
  return self;
}
- (BOOL) hasImage {
  return resultPreview.hasImage;
}
- (ZMAssetImageMetaData*) image {
  return resultPreview.image;
}
- (ZMAssetPreviewBuilder*) setImage:(ZMAssetImageMetaData*) value {
  resultPreview.hasImage = YES;
  resultPreview.image = value;
  return self;
}
- (ZMAssetPreviewBuilder*) setImageBuilder:(ZMAssetImageMetaDataBuilder*) builderForValue {
  return [self setImage:[builderForValue build]];
}
- (ZMAssetPreviewBuilder*) mergeImage:(ZMAssetImageMetaData*) value {
  if (resultPreview.hasImage &&
      resultPreview.image != [ZMAssetImageMetaData defaultInstance]) {
    resultPreview.image =
      [[[ZMAssetImageMetaData builderWithPrototype:resultPreview.image] mergeFrom:value] buildPartial];
  } else {
    resultPreview.image = value;
  }
  resultPreview.hasImage = YES;
  return self;
}
- (ZMAssetPreviewBuilder*) clearImage {
  resultPreview.hasImage = NO;
  resultPreview.image = [ZMAssetImageMetaData defaultInstance];
  return self;
}
@end

@interface ZMAssetImageMetaData ()
@property SInt32 width;
@property SInt32 height;
@property (strong) NSString* tag;
@end

@implementation ZMAssetImageMetaData

- (BOOL) hasWidth {
  return !!hasWidth_;
}
- (void) setHasWidth:(BOOL) _value_ {
  hasWidth_ = !!_value_;
}
@synthesize width;
- (BOOL) hasHeight {
  return !!hasHeight_;
}
- (void) setHasHeight:(BOOL) _value_ {
  hasHeight_ = !!_value_;
}
@synthesize height;
- (BOOL) hasTag {
  return !!hasTag_;
}
- (void) setHasTag:(BOOL) _value_ {
  hasTag_ = !!_value_;
}
@synthesize tag;
- (instancetype) init {
  if ((self = [super init])) {
    self.width = 0;
    self.height = 0;
    self.tag = @"";
  }
  return self;
}
static ZMAssetImageMetaData* defaultZMAssetImageMetaDataInstance = nil;
+ (void) initialize {
  if (self == [ZMAssetImageMetaData class]) {
    defaultZMAssetImageMetaDataInstance = [[ZMAssetImageMetaData alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMAssetImageMetaDataInstance;
}
- (instancetype) defaultInstance {
  return defaultZMAssetImageMetaDataInstance;
}
- (BOOL) isInitialized {
  if (!self.hasWidth) {
    return NO;
  }
  if (!self.hasHeight) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasWidth) {
    [output writeInt32:1 value:self.width];
  }
  if (self.hasHeight) {
    [output writeInt32:2 value:self.height];
  }
  if (self.hasTag) {
    [output writeString:3 value:self.tag];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasWidth) {
    size_ += computeInt32Size(1, self.width);
  }
  if (self.hasHeight) {
    size_ += computeInt32Size(2, self.height);
  }
  if (self.hasTag) {
    size_ += computeStringSize(3, self.tag);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMAssetImageMetaData*) parseFromData:(NSData*) data {
  return (ZMAssetImageMetaData*)[[[ZMAssetImageMetaData builder] mergeFromData:data] build];
}
+ (ZMAssetImageMetaData*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetImageMetaData*)[[[ZMAssetImageMetaData builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetImageMetaData*) parseFromInputStream:(NSInputStream*) input {
  return (ZMAssetImageMetaData*)[[[ZMAssetImageMetaData builder] mergeFromInputStream:input] build];
}
+ (ZMAssetImageMetaData*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetImageMetaData*)[[[ZMAssetImageMetaData builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetImageMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMAssetImageMetaData*)[[[ZMAssetImageMetaData builder] mergeFromCodedInputStream:input] build];
}
+ (ZMAssetImageMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetImageMetaData*)[[[ZMAssetImageMetaData builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetImageMetaDataBuilder*) builder {
  return [[ZMAssetImageMetaDataBuilder alloc] init];
}
+ (ZMAssetImageMetaDataBuilder*) builderWithPrototype:(ZMAssetImageMetaData*) prototype {
  return [[ZMAssetImageMetaData builder] mergeFrom:prototype];
}
- (ZMAssetImageMetaDataBuilder*) builder {
  return [ZMAssetImageMetaData builder];
}
- (ZMAssetImageMetaDataBuilder*) toBuilder {
  return [ZMAssetImageMetaData builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasWidth) {
    [output appendFormat:@"%@%@: %@\n", indent, @"width", [NSNumber numberWithInteger:self.width]];
  }
  if (self.hasHeight) {
    [output appendFormat:@"%@%@: %@\n", indent, @"height", [NSNumber numberWithInteger:self.height]];
  }
  if (self.hasTag) {
    [output appendFormat:@"%@%@: %@\n", indent, @"tag", self.tag];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasWidth) {
    [dictionary setObject: [NSNumber numberWithInteger:self.width] forKey: @"width"];
  }
  if (self.hasHeight) {
    [dictionary setObject: [NSNumber numberWithInteger:self.height] forKey: @"height"];
  }
  if (self.hasTag) {
    [dictionary setObject: self.tag forKey: @"tag"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMAssetImageMetaData class]]) {
    return NO;
  }
  ZMAssetImageMetaData *otherMessage = other;
  return
      self.hasWidth == otherMessage.hasWidth &&
      (!self.hasWidth || self.width == otherMessage.width) &&
      self.hasHeight == otherMessage.hasHeight &&
      (!self.hasHeight || self.height == otherMessage.height) &&
      self.hasTag == otherMessage.hasTag &&
      (!self.hasTag || [self.tag isEqual:otherMessage.tag]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasWidth) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.width] hash];
  }
  if (self.hasHeight) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.height] hash];
  }
  if (self.hasTag) {
    hashCode = hashCode * 31 + [self.tag hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMAssetImageMetaDataBuilder()
@property (strong) ZMAssetImageMetaData* resultImageMetaData;
@end

@implementation ZMAssetImageMetaDataBuilder
@synthesize resultImageMetaData;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultImageMetaData = [[ZMAssetImageMetaData alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultImageMetaData;
}
- (ZMAssetImageMetaDataBuilder*) clear {
  self.resultImageMetaData = [[ZMAssetImageMetaData alloc] init];
  return self;
}
- (ZMAssetImageMetaDataBuilder*) clone {
  return [ZMAssetImageMetaData builderWithPrototype:resultImageMetaData];
}
- (ZMAssetImageMetaData*) defaultInstance {
  return [ZMAssetImageMetaData defaultInstance];
}
- (ZMAssetImageMetaData*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMAssetImageMetaData*) buildPartial {
  ZMAssetImageMetaData* returnMe = resultImageMetaData;
  self.resultImageMetaData = nil;
  return returnMe;
}
- (ZMAssetImageMetaDataBuilder*) mergeFrom:(ZMAssetImageMetaData*) other {
  if (other == [ZMAssetImageMetaData defaultInstance]) {
    return self;
  }
  if (other.hasWidth) {
    [self setWidth:other.width];
  }
  if (other.hasHeight) {
    [self setHeight:other.height];
  }
  if (other.hasTag) {
    [self setTag:other.tag];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMAssetImageMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMAssetImageMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 8: {
        [self setWidth:[input readInt32]];
        break;
      }
      case 16: {
        [self setHeight:[input readInt32]];
        break;
      }
      case 26: {
        [self setTag:[input readString]];
        break;
      }
    }
  }
}
- (BOOL) hasWidth {
  return resultImageMetaData.hasWidth;
}
- (SInt32) width {
  return resultImageMetaData.width;
}
- (ZMAssetImageMetaDataBuilder*) setWidth:(SInt32) value {
  resultImageMetaData.hasWidth = YES;
  resultImageMetaData.width = value;
  return self;
}
- (ZMAssetImageMetaDataBuilder*) clearWidth {
  resultImageMetaData.hasWidth = NO;
  resultImageMetaData.width = 0;
  return self;
}
- (BOOL) hasHeight {
  return resultImageMetaData.hasHeight;
}
- (SInt32) height {
  return resultImageMetaData.height;
}
- (ZMAssetImageMetaDataBuilder*) setHeight:(SInt32) value {
  resultImageMetaData.hasHeight = YES;
  resultImageMetaData.height = value;
  return self;
}
- (ZMAssetImageMetaDataBuilder*) clearHeight {
  resultImageMetaData.hasHeight = NO;
  resultImageMetaData.height = 0;
  return self;
}
- (BOOL) hasTag {
  return resultImageMetaData.hasTag;
}
- (NSString*) tag {
  return resultImageMetaData.tag;
}
- (ZMAssetImageMetaDataBuilder*) setTag:(NSString*) value {
  resultImageMetaData.hasTag = YES;
  resultImageMetaData.tag = value;
  return self;
}
- (ZMAssetImageMetaDataBuilder*) clearTag {
  resultImageMetaData.hasTag = NO;
  resultImageMetaData.tag = @"";
  return self;
}
@end

@interface ZMAssetVideoMetaData ()
@property SInt32 width;
@property SInt32 height;
@property UInt64 durationInMillis;
@end

@implementation ZMAssetVideoMetaData

- (BOOL) hasWidth {
  return !!hasWidth_;
}
- (void) setHasWidth:(BOOL) _value_ {
  hasWidth_ = !!_value_;
}
@synthesize width;
- (BOOL) hasHeight {
  return !!hasHeight_;
}
- (void) setHasHeight:(BOOL) _value_ {
  hasHeight_ = !!_value_;
}
@synthesize height;
- (BOOL) hasDurationInMillis {
  return !!hasDurationInMillis_;
}
- (void) setHasDurationInMillis:(BOOL) _value_ {
  hasDurationInMillis_ = !!_value_;
}
@synthesize durationInMillis;
- (instancetype) init {
  if ((self = [super init])) {
    self.width = 0;
    self.height = 0;
    self.durationInMillis = 0L;
  }
  return self;
}
static ZMAssetVideoMetaData* defaultZMAssetVideoMetaDataInstance = nil;
+ (void) initialize {
  if (self == [ZMAssetVideoMetaData class]) {
    defaultZMAssetVideoMetaDataInstance = [[ZMAssetVideoMetaData alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMAssetVideoMetaDataInstance;
}
- (instancetype) defaultInstance {
  return defaultZMAssetVideoMetaDataInstance;
}
- (BOOL) isInitialized {
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasWidth) {
    [output writeInt32:1 value:self.width];
  }
  if (self.hasHeight) {
    [output writeInt32:2 value:self.height];
  }
  if (self.hasDurationInMillis) {
    [output writeUInt64:3 value:self.durationInMillis];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasWidth) {
    size_ += computeInt32Size(1, self.width);
  }
  if (self.hasHeight) {
    size_ += computeInt32Size(2, self.height);
  }
  if (self.hasDurationInMillis) {
    size_ += computeUInt64Size(3, self.durationInMillis);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMAssetVideoMetaData*) parseFromData:(NSData*) data {
  return (ZMAssetVideoMetaData*)[[[ZMAssetVideoMetaData builder] mergeFromData:data] build];
}
+ (ZMAssetVideoMetaData*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetVideoMetaData*)[[[ZMAssetVideoMetaData builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetVideoMetaData*) parseFromInputStream:(NSInputStream*) input {
  return (ZMAssetVideoMetaData*)[[[ZMAssetVideoMetaData builder] mergeFromInputStream:input] build];
}
+ (ZMAssetVideoMetaData*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetVideoMetaData*)[[[ZMAssetVideoMetaData builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetVideoMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMAssetVideoMetaData*)[[[ZMAssetVideoMetaData builder] mergeFromCodedInputStream:input] build];
}
+ (ZMAssetVideoMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetVideoMetaData*)[[[ZMAssetVideoMetaData builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetVideoMetaDataBuilder*) builder {
  return [[ZMAssetVideoMetaDataBuilder alloc] init];
}
+ (ZMAssetVideoMetaDataBuilder*) builderWithPrototype:(ZMAssetVideoMetaData*) prototype {
  return [[ZMAssetVideoMetaData builder] mergeFrom:prototype];
}
- (ZMAssetVideoMetaDataBuilder*) builder {
  return [ZMAssetVideoMetaData builder];
}
- (ZMAssetVideoMetaDataBuilder*) toBuilder {
  return [ZMAssetVideoMetaData builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasWidth) {
    [output appendFormat:@"%@%@: %@\n", indent, @"width", [NSNumber numberWithInteger:self.width]];
  }
  if (self.hasHeight) {
    [output appendFormat:@"%@%@: %@\n", indent, @"height", [NSNumber numberWithInteger:self.height]];
  }
  if (self.hasDurationInMillis) {
    [output appendFormat:@"%@%@: %@\n", indent, @"durationInMillis", [NSNumber numberWithLongLong:self.durationInMillis]];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasWidth) {
    [dictionary setObject: [NSNumber numberWithInteger:self.width] forKey: @"width"];
  }
  if (self.hasHeight) {
    [dictionary setObject: [NSNumber numberWithInteger:self.height] forKey: @"height"];
  }
  if (self.hasDurationInMillis) {
    [dictionary setObject: [NSNumber numberWithLongLong:self.durationInMillis] forKey: @"durationInMillis"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMAssetVideoMetaData class]]) {
    return NO;
  }
  ZMAssetVideoMetaData *otherMessage = other;
  return
      self.hasWidth == otherMessage.hasWidth &&
      (!self.hasWidth || self.width == otherMessage.width) &&
      self.hasHeight == otherMessage.hasHeight &&
      (!self.hasHeight || self.height == otherMessage.height) &&
      self.hasDurationInMillis == otherMessage.hasDurationInMillis &&
      (!self.hasDurationInMillis || self.durationInMillis == otherMessage.durationInMillis) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasWidth) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.width] hash];
  }
  if (self.hasHeight) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.height] hash];
  }
  if (self.hasDurationInMillis) {
    hashCode = hashCode * 31 + [[NSNumber numberWithLongLong:self.durationInMillis] hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMAssetVideoMetaDataBuilder()
@property (strong) ZMAssetVideoMetaData* resultVideoMetaData;
@end

@implementation ZMAssetVideoMetaDataBuilder
@synthesize resultVideoMetaData;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultVideoMetaData = [[ZMAssetVideoMetaData alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultVideoMetaData;
}
- (ZMAssetVideoMetaDataBuilder*) clear {
  self.resultVideoMetaData = [[ZMAssetVideoMetaData alloc] init];
  return self;
}
- (ZMAssetVideoMetaDataBuilder*) clone {
  return [ZMAssetVideoMetaData builderWithPrototype:resultVideoMetaData];
}
- (ZMAssetVideoMetaData*) defaultInstance {
  return [ZMAssetVideoMetaData defaultInstance];
}
- (ZMAssetVideoMetaData*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMAssetVideoMetaData*) buildPartial {
  ZMAssetVideoMetaData* returnMe = resultVideoMetaData;
  self.resultVideoMetaData = nil;
  return returnMe;
}
- (ZMAssetVideoMetaDataBuilder*) mergeFrom:(ZMAssetVideoMetaData*) other {
  if (other == [ZMAssetVideoMetaData defaultInstance]) {
    return self;
  }
  if (other.hasWidth) {
    [self setWidth:other.width];
  }
  if (other.hasHeight) {
    [self setHeight:other.height];
  }
  if (other.hasDurationInMillis) {
    [self setDurationInMillis:other.durationInMillis];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMAssetVideoMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMAssetVideoMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 8: {
        [self setWidth:[input readInt32]];
        break;
      }
      case 16: {
        [self setHeight:[input readInt32]];
        break;
      }
      case 24: {
        [self setDurationInMillis:[input readUInt64]];
        break;
      }
    }
  }
}
- (BOOL) hasWidth {
  return resultVideoMetaData.hasWidth;
}
- (SInt32) width {
  return resultVideoMetaData.width;
}
- (ZMAssetVideoMetaDataBuilder*) setWidth:(SInt32) value {
  resultVideoMetaData.hasWidth = YES;
  resultVideoMetaData.width = value;
  return self;
}
- (ZMAssetVideoMetaDataBuilder*) clearWidth {
  resultVideoMetaData.hasWidth = NO;
  resultVideoMetaData.width = 0;
  return self;
}
- (BOOL) hasHeight {
  return resultVideoMetaData.hasHeight;
}
- (SInt32) height {
  return resultVideoMetaData.height;
}
- (ZMAssetVideoMetaDataBuilder*) setHeight:(SInt32) value {
  resultVideoMetaData.hasHeight = YES;
  resultVideoMetaData.height = value;
  return self;
}
- (ZMAssetVideoMetaDataBuilder*) clearHeight {
  resultVideoMetaData.hasHeight = NO;
  resultVideoMetaData.height = 0;
  return self;
}
- (BOOL) hasDurationInMillis {
  return resultVideoMetaData.hasDurationInMillis;
}
- (UInt64) durationInMillis {
  return resultVideoMetaData.durationInMillis;
}
- (ZMAssetVideoMetaDataBuilder*) setDurationInMillis:(UInt64) value {
  resultVideoMetaData.hasDurationInMillis = YES;
  resultVideoMetaData.durationInMillis = value;
  return self;
}
- (ZMAssetVideoMetaDataBuilder*) clearDurationInMillis {
  resultVideoMetaData.hasDurationInMillis = NO;
  resultVideoMetaData.durationInMillis = 0L;
  return self;
}
@end

@interface ZMAssetUploaded ()
@property (strong) NSData* otrKey;
@property (strong) NSData* sha256;
@end

@implementation ZMAssetUploaded

- (BOOL) hasOtrKey {
  return !!hasOtrKey_;
}
- (void) setHasOtrKey:(BOOL) _value_ {
  hasOtrKey_ = !!_value_;
}
@synthesize otrKey;
- (BOOL) hasSha256 {
  return !!hasSha256_;
}
- (void) setHasSha256:(BOOL) _value_ {
  hasSha256_ = !!_value_;
}
@synthesize sha256;
- (instancetype) init {
  if ((self = [super init])) {
    self.otrKey = [NSData data];
    self.sha256 = [NSData data];
  }
  return self;
}
static ZMAssetUploaded* defaultZMAssetUploadedInstance = nil;
+ (void) initialize {
  if (self == [ZMAssetUploaded class]) {
    defaultZMAssetUploadedInstance = [[ZMAssetUploaded alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMAssetUploadedInstance;
}
- (instancetype) defaultInstance {
  return defaultZMAssetUploadedInstance;
}
- (BOOL) isInitialized {
  if (!self.hasOtrKey) {
    return NO;
  }
  if (!self.hasSha256) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasOtrKey) {
    [output writeData:1 value:self.otrKey];
  }
  if (self.hasSha256) {
    [output writeData:2 value:self.sha256];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasOtrKey) {
    size_ += computeDataSize(1, self.otrKey);
  }
  if (self.hasSha256) {
    size_ += computeDataSize(2, self.sha256);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMAssetUploaded*) parseFromData:(NSData*) data {
  return (ZMAssetUploaded*)[[[ZMAssetUploaded builder] mergeFromData:data] build];
}
+ (ZMAssetUploaded*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetUploaded*)[[[ZMAssetUploaded builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetUploaded*) parseFromInputStream:(NSInputStream*) input {
  return (ZMAssetUploaded*)[[[ZMAssetUploaded builder] mergeFromInputStream:input] build];
}
+ (ZMAssetUploaded*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetUploaded*)[[[ZMAssetUploaded builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetUploaded*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMAssetUploaded*)[[[ZMAssetUploaded builder] mergeFromCodedInputStream:input] build];
}
+ (ZMAssetUploaded*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetUploaded*)[[[ZMAssetUploaded builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetUploadedBuilder*) builder {
  return [[ZMAssetUploadedBuilder alloc] init];
}
+ (ZMAssetUploadedBuilder*) builderWithPrototype:(ZMAssetUploaded*) prototype {
  return [[ZMAssetUploaded builder] mergeFrom:prototype];
}
- (ZMAssetUploadedBuilder*) builder {
  return [ZMAssetUploaded builder];
}
- (ZMAssetUploadedBuilder*) toBuilder {
  return [ZMAssetUploaded builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasOtrKey) {
    [output appendFormat:@"%@%@: %@\n", indent, @"otrKey", self.otrKey];
  }
  if (self.hasSha256) {
    [output appendFormat:@"%@%@: %@\n", indent, @"sha256", self.sha256];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasOtrKey) {
    [dictionary setObject: self.otrKey forKey: @"otrKey"];
  }
  if (self.hasSha256) {
    [dictionary setObject: self.sha256 forKey: @"sha256"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMAssetUploaded class]]) {
    return NO;
  }
  ZMAssetUploaded *otherMessage = other;
  return
      self.hasOtrKey == otherMessage.hasOtrKey &&
      (!self.hasOtrKey || [self.otrKey isEqual:otherMessage.otrKey]) &&
      self.hasSha256 == otherMessage.hasSha256 &&
      (!self.hasSha256 || [self.sha256 isEqual:otherMessage.sha256]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasOtrKey) {
    hashCode = hashCode * 31 + [self.otrKey hash];
  }
  if (self.hasSha256) {
    hashCode = hashCode * 31 + [self.sha256 hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMAssetUploadedBuilder()
@property (strong) ZMAssetUploaded* resultUploaded;
@end

@implementation ZMAssetUploadedBuilder
@synthesize resultUploaded;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultUploaded = [[ZMAssetUploaded alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultUploaded;
}
- (ZMAssetUploadedBuilder*) clear {
  self.resultUploaded = [[ZMAssetUploaded alloc] init];
  return self;
}
- (ZMAssetUploadedBuilder*) clone {
  return [ZMAssetUploaded builderWithPrototype:resultUploaded];
}
- (ZMAssetUploaded*) defaultInstance {
  return [ZMAssetUploaded defaultInstance];
}
- (ZMAssetUploaded*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMAssetUploaded*) buildPartial {
  ZMAssetUploaded* returnMe = resultUploaded;
  self.resultUploaded = nil;
  return returnMe;
}
- (ZMAssetUploadedBuilder*) mergeFrom:(ZMAssetUploaded*) other {
  if (other == [ZMAssetUploaded defaultInstance]) {
    return self;
  }
  if (other.hasOtrKey) {
    [self setOtrKey:other.otrKey];
  }
  if (other.hasSha256) {
    [self setSha256:other.sha256];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMAssetUploadedBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMAssetUploadedBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setOtrKey:[input readData]];
        break;
      }
      case 18: {
        [self setSha256:[input readData]];
        break;
      }
    }
  }
}
- (BOOL) hasOtrKey {
  return resultUploaded.hasOtrKey;
}
- (NSData*) otrKey {
  return resultUploaded.otrKey;
}
- (ZMAssetUploadedBuilder*) setOtrKey:(NSData*) value {
  resultUploaded.hasOtrKey = YES;
  resultUploaded.otrKey = value;
  return self;
}
- (ZMAssetUploadedBuilder*) clearOtrKey {
  resultUploaded.hasOtrKey = NO;
  resultUploaded.otrKey = [NSData data];
  return self;
}
- (BOOL) hasSha256 {
  return resultUploaded.hasSha256;
}
- (NSData*) sha256 {
  return resultUploaded.sha256;
}
- (ZMAssetUploadedBuilder*) setSha256:(NSData*) value {
  resultUploaded.hasSha256 = YES;
  resultUploaded.sha256 = value;
  return self;
}
- (ZMAssetUploadedBuilder*) clearSha256 {
  resultUploaded.hasSha256 = NO;
  resultUploaded.sha256 = [NSData data];
  return self;
}
@end

@interface ZMAssetBuilder()
@property (strong) ZMAsset* resultAsset;
@end

@implementation ZMAssetBuilder
@synthesize resultAsset;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultAsset = [[ZMAsset alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultAsset;
}
- (ZMAssetBuilder*) clear {
  self.resultAsset = [[ZMAsset alloc] init];
  return self;
}
- (ZMAssetBuilder*) clone {
  return [ZMAsset builderWithPrototype:resultAsset];
}
- (ZMAsset*) defaultInstance {
  return [ZMAsset defaultInstance];
}
- (ZMAsset*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMAsset*) buildPartial {
  ZMAsset* returnMe = resultAsset;
  self.resultAsset = nil;
  return returnMe;
}
- (ZMAssetBuilder*) mergeFrom:(ZMAsset*) other {
  if (other == [ZMAsset defaultInstance]) {
    return self;
  }
  if (other.hasOriginal) {
    [self mergeOriginal:other.original];
  }
  if (other.hasPreview) {
    [self mergePreview:other.preview];
  }
  if (other.hasNotUploaded) {
    [self setNotUploaded:other.notUploaded];
  }
  if (other.hasUploaded) {
    [self mergeUploaded:other.uploaded];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMAssetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMAssetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        ZMAssetOriginalBuilder* subBuilder = [ZMAssetOriginal builder];
        if (self.hasOriginal) {
          [subBuilder mergeFrom:self.original];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setOriginal:[subBuilder buildPartial]];
        break;
      }
      case 18: {
        ZMAssetPreviewBuilder* subBuilder = [ZMAssetPreview builder];
        if (self.hasPreview) {
          [subBuilder mergeFrom:self.preview];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setPreview:[subBuilder buildPartial]];
        break;
      }
      case 24: {
        ZMAssetNotUploaded value = (ZMAssetNotUploaded)[input readEnum];
        if (ZMAssetNotUploadedIsValidValue(value)) {
          [self setNotUploaded:value];
        } else {
          [unknownFields mergeVarintField:3 value:value];
        }
        break;
      }
      case 34: {
        ZMAssetUploadedBuilder* subBuilder = [ZMAssetUploaded builder];
        if (self.hasUploaded) {
          [subBuilder mergeFrom:self.uploaded];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setUploaded:[subBuilder buildPartial]];
        break;
      }
    }
  }
}
- (BOOL) hasOriginal {
  return resultAsset.hasOriginal;
}
- (ZMAssetOriginal*) original {
  return resultAsset.original;
}
- (ZMAssetBuilder*) setOriginal:(ZMAssetOriginal*) value {
  resultAsset.hasOriginal = YES;
  resultAsset.original = value;
  return self;
}
- (ZMAssetBuilder*) setOriginalBuilder:(ZMAssetOriginalBuilder*) builderForValue {
  return [self setOriginal:[builderForValue build]];
}
- (ZMAssetBuilder*) mergeOriginal:(ZMAssetOriginal*) value {
  if (resultAsset.hasOriginal &&
      resultAsset.original != [ZMAssetOriginal defaultInstance]) {
    resultAsset.original =
      [[[ZMAssetOriginal builderWithPrototype:resultAsset.original] mergeFrom:value] buildPartial];
  } else {
    resultAsset.original = value;
  }
  resultAsset.hasOriginal = YES;
  return self;
}
- (ZMAssetBuilder*) clearOriginal {
  resultAsset.hasOriginal = NO;
  resultAsset.original = [ZMAssetOriginal defaultInstance];
  return self;
}
- (BOOL) hasPreview {
  return resultAsset.hasPreview;
}
- (ZMAssetPreview*) preview {
  return resultAsset.preview;
}
- (ZMAssetBuilder*) setPreview:(ZMAssetPreview*) value {
  resultAsset.hasPreview = YES;
  resultAsset.preview = value;
  return self;
}
- (ZMAssetBuilder*) setPreviewBuilder:(ZMAssetPreviewBuilder*) builderForValue {
  return [self setPreview:[builderForValue build]];
}
- (ZMAssetBuilder*) mergePreview:(ZMAssetPreview*) value {
  if (resultAsset.hasPreview &&
      resultAsset.preview != [ZMAssetPreview defaultInstance]) {
    resultAsset.preview =
      [[[ZMAssetPreview builderWithPrototype:resultAsset.preview] mergeFrom:value] buildPartial];
  } else {
    resultAsset.preview = value;
  }
  resultAsset.hasPreview = YES;
  return self;
}
- (ZMAssetBuilder*) clearPreview {
  resultAsset.hasPreview = NO;
  resultAsset.preview = [ZMAssetPreview defaultInstance];
  return self;
}
- (BOOL) hasNotUploaded {
  return resultAsset.hasNotUploaded;
}
- (ZMAssetNotUploaded) notUploaded {
  return resultAsset.notUploaded;
}
- (ZMAssetBuilder*) setNotUploaded:(ZMAssetNotUploaded) value {
  resultAsset.hasNotUploaded = YES;
  resultAsset.notUploaded = value;
  return self;
}
- (ZMAssetBuilder*) clearNotUploaded {
  resultAsset.hasNotUploaded = NO;
  resultAsset.notUploaded = ZMAssetNotUploadedCANCELLED;
  return self;
}
- (BOOL) hasUploaded {
  return resultAsset.hasUploaded;
}
- (ZMAssetUploaded*) uploaded {
  return resultAsset.uploaded;
}
- (ZMAssetBuilder*) setUploaded:(ZMAssetUploaded*) value {
  resultAsset.hasUploaded = YES;
  resultAsset.uploaded = value;
  return self;
}
- (ZMAssetBuilder*) setUploadedBuilder:(ZMAssetUploadedBuilder*) builderForValue {
  return [self setUploaded:[builderForValue build]];
}
- (ZMAssetBuilder*) mergeUploaded:(ZMAssetUploaded*) value {
  if (resultAsset.hasUploaded &&
      resultAsset.uploaded != [ZMAssetUploaded defaultInstance]) {
    resultAsset.uploaded =
      [[[ZMAssetUploaded builderWithPrototype:resultAsset.uploaded] mergeFrom:value] buildPartial];
  } else {
    resultAsset.uploaded = value;
  }
  resultAsset.hasUploaded = YES;
  return self;
}
- (ZMAssetBuilder*) clearUploaded {
  resultAsset.hasUploaded = NO;
  resultAsset.uploaded = [ZMAssetUploaded defaultInstance];
  return self;
}
@end

@interface ZMExternal ()
@property (strong) NSData* otrKey;
@property (strong) NSData* sha256;
@end

@implementation ZMExternal

- (BOOL) hasOtrKey {
  return !!hasOtrKey_;
}
- (void) setHasOtrKey:(BOOL) _value_ {
  hasOtrKey_ = !!_value_;
}
@synthesize otrKey;
- (BOOL) hasSha256 {
  return !!hasSha256_;
}
- (void) setHasSha256:(BOOL) _value_ {
  hasSha256_ = !!_value_;
}
@synthesize sha256;
- (instancetype) init {
  if ((self = [super init])) {
    self.otrKey = [NSData data];
    self.sha256 = [NSData data];
  }
  return self;
}
static ZMExternal* defaultZMExternalInstance = nil;
+ (void) initialize {
  if (self == [ZMExternal class]) {
    defaultZMExternalInstance = [[ZMExternal alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMExternalInstance;
}
- (instancetype) defaultInstance {
  return defaultZMExternalInstance;
}
- (BOOL) isInitialized {
  if (!self.hasOtrKey) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasOtrKey) {
    [output writeData:1 value:self.otrKey];
  }
  if (self.hasSha256) {
    [output writeData:2 value:self.sha256];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasOtrKey) {
    size_ += computeDataSize(1, self.otrKey);
  }
  if (self.hasSha256) {
    size_ += computeDataSize(2, self.sha256);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMExternal*) parseFromData:(NSData*) data {
  return (ZMExternal*)[[[ZMExternal builder] mergeFromData:data] build];
}
+ (ZMExternal*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMExternal*)[[[ZMExternal builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMExternal*) parseFromInputStream:(NSInputStream*) input {
  return (ZMExternal*)[[[ZMExternal builder] mergeFromInputStream:input] build];
}
+ (ZMExternal*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMExternal*)[[[ZMExternal builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMExternal*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMExternal*)[[[ZMExternal builder] mergeFromCodedInputStream:input] build];
}
+ (ZMExternal*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMExternal*)[[[ZMExternal builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMExternalBuilder*) builder {
  return [[ZMExternalBuilder alloc] init];
}
+ (ZMExternalBuilder*) builderWithPrototype:(ZMExternal*) prototype {
  return [[ZMExternal builder] mergeFrom:prototype];
}
- (ZMExternalBuilder*) builder {
  return [ZMExternal builder];
}
- (ZMExternalBuilder*) toBuilder {
  return [ZMExternal builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasOtrKey) {
    [output appendFormat:@"%@%@: %@\n", indent, @"otrKey", self.otrKey];
  }
  if (self.hasSha256) {
    [output appendFormat:@"%@%@: %@\n", indent, @"sha256", self.sha256];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasOtrKey) {
    [dictionary setObject: self.otrKey forKey: @"otrKey"];
  }
  if (self.hasSha256) {
    [dictionary setObject: self.sha256 forKey: @"sha256"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMExternal class]]) {
    return NO;
  }
  ZMExternal *otherMessage = other;
  return
      self.hasOtrKey == otherMessage.hasOtrKey &&
      (!self.hasOtrKey || [self.otrKey isEqual:otherMessage.otrKey]) &&
      self.hasSha256 == otherMessage.hasSha256 &&
      (!self.hasSha256 || [self.sha256 isEqual:otherMessage.sha256]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasOtrKey) {
    hashCode = hashCode * 31 + [self.otrKey hash];
  }
  if (self.hasSha256) {
    hashCode = hashCode * 31 + [self.sha256 hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMExternalBuilder()
@property (strong) ZMExternal* resultExternal;
@end

@implementation ZMExternalBuilder
@synthesize resultExternal;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultExternal = [[ZMExternal alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultExternal;
}
- (ZMExternalBuilder*) clear {
  self.resultExternal = [[ZMExternal alloc] init];
  return self;
}
- (ZMExternalBuilder*) clone {
  return [ZMExternal builderWithPrototype:resultExternal];
}
- (ZMExternal*) defaultInstance {
  return [ZMExternal defaultInstance];
}
- (ZMExternal*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMExternal*) buildPartial {
  ZMExternal* returnMe = resultExternal;
  self.resultExternal = nil;
  return returnMe;
}
- (ZMExternalBuilder*) mergeFrom:(ZMExternal*) other {
  if (other == [ZMExternal defaultInstance]) {
    return self;
  }
  if (other.hasOtrKey) {
    [self setOtrKey:other.otrKey];
  }
  if (other.hasSha256) {
    [self setSha256:other.sha256];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMExternalBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMExternalBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setOtrKey:[input readData]];
        break;
      }
      case 18: {
        [self setSha256:[input readData]];
        break;
      }
    }
  }
}
- (BOOL) hasOtrKey {
  return resultExternal.hasOtrKey;
}
- (NSData*) otrKey {
  return resultExternal.otrKey;
}
- (ZMExternalBuilder*) setOtrKey:(NSData*) value {
  resultExternal.hasOtrKey = YES;
  resultExternal.otrKey = value;
  return self;
}
- (ZMExternalBuilder*) clearOtrKey {
  resultExternal.hasOtrKey = NO;
  resultExternal.otrKey = [NSData data];
  return self;
}
- (BOOL) hasSha256 {
  return resultExternal.hasSha256;
}
- (NSData*) sha256 {
  return resultExternal.sha256;
}
- (ZMExternalBuilder*) setSha256:(NSData*) value {
  resultExternal.hasSha256 = YES;
  resultExternal.sha256 = value;
  return self;
}
- (ZMExternalBuilder*) clearSha256 {
  resultExternal.hasSha256 = NO;
  resultExternal.sha256 = [NSData data];
  return self;
}
@end

@interface ZMCalling ()
@property (strong) NSString* content;
@end

@implementation ZMCalling

- (BOOL) hasContent {
  return !!hasContent_;
}
- (void) setHasContent:(BOOL) _value_ {
  hasContent_ = !!_value_;
}
@synthesize content;
- (instancetype) init {
  if ((self = [super init])) {
    self.content = @"";
  }
  return self;
}
static ZMCalling* defaultZMCallingInstance = nil;
+ (void) initialize {
  if (self == [ZMCalling class]) {
    defaultZMCallingInstance = [[ZMCalling alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMCallingInstance;
}
- (instancetype) defaultInstance {
  return defaultZMCallingInstance;
}
- (BOOL) isInitialized {
  if (!self.hasContent) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasContent) {
    [output writeString:1 value:self.content];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasContent) {
    size_ += computeStringSize(1, self.content);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMCalling*) parseFromData:(NSData*) data {
  return (ZMCalling*)[[[ZMCalling builder] mergeFromData:data] build];
}
+ (ZMCalling*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMCalling*)[[[ZMCalling builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMCalling*) parseFromInputStream:(NSInputStream*) input {
  return (ZMCalling*)[[[ZMCalling builder] mergeFromInputStream:input] build];
}
+ (ZMCalling*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMCalling*)[[[ZMCalling builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMCalling*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMCalling*)[[[ZMCalling builder] mergeFromCodedInputStream:input] build];
}
+ (ZMCalling*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMCalling*)[[[ZMCalling builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMCallingBuilder*) builder {
  return [[ZMCallingBuilder alloc] init];
}
+ (ZMCallingBuilder*) builderWithPrototype:(ZMCalling*) prototype {
  return [[ZMCalling builder] mergeFrom:prototype];
}
- (ZMCallingBuilder*) builder {
  return [ZMCalling builder];
}
- (ZMCallingBuilder*) toBuilder {
  return [ZMCalling builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasContent) {
    [output appendFormat:@"%@%@: %@\n", indent, @"content", self.content];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasContent) {
    [dictionary setObject: self.content forKey: @"content"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMCalling class]]) {
    return NO;
  }
  ZMCalling *otherMessage = other;
  return
      self.hasContent == otherMessage.hasContent &&
      (!self.hasContent || [self.content isEqual:otherMessage.content]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasContent) {
    hashCode = hashCode * 31 + [self.content hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMCallingBuilder()
@property (strong) ZMCalling* resultCalling;
@end

@implementation ZMCallingBuilder
@synthesize resultCalling;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultCalling = [[ZMCalling alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultCalling;
}
- (ZMCallingBuilder*) clear {
  self.resultCalling = [[ZMCalling alloc] init];
  return self;
}
- (ZMCallingBuilder*) clone {
  return [ZMCalling builderWithPrototype:resultCalling];
}
- (ZMCalling*) defaultInstance {
  return [ZMCalling defaultInstance];
}
- (ZMCalling*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMCalling*) buildPartial {
  ZMCalling* returnMe = resultCalling;
  self.resultCalling = nil;
  return returnMe;
}
- (ZMCallingBuilder*) mergeFrom:(ZMCalling*) other {
  if (other == [ZMCalling defaultInstance]) {
    return self;
  }
  if (other.hasContent) {
    [self setContent:other.content];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMCallingBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMCallingBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  PBUnknownFieldSetBuilder* unknownFields = [PBUnknownFieldSet builderWithUnknownFields:self.unknownFields];
  while (YES) {
    SInt32 tag = [input readTag];
    switch (tag) {
      case 0:
        [self setUnknownFields:[unknownFields build]];
        return self;
      default: {
        if (![self parseUnknownField:input unknownFields:unknownFields extensionRegistry:extensionRegistry tag:tag]) {
          [self setUnknownFields:[unknownFields build]];
          return self;
        }
        break;
      }
      case 10: {
        [self setContent:[input readString]];
        break;
      }
    }
  }
}
- (BOOL) hasContent {
  return resultCalling.hasContent;
}
- (NSString*) content {
  return resultCalling.content;
}
- (ZMCallingBuilder*) setContent:(NSString*) value {
  resultCalling.hasContent = YES;
  resultCalling.content = value;
  return self;
}
- (ZMCallingBuilder*) clearContent {
  resultCalling.hasContent = NO;
  resultCalling.content = @"";
  return self;
}
@end


// @@protoc_insertion_point(global_scope)
