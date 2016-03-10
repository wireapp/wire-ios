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


// @@protoc_insertion_point(global_scope)
