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

#import "Otr.pb.h"
// @@protoc_insertion_point(imports)

@implementation ZMOtrRoot
static PBExtensionRegistry* extensionRegistry = nil;
+ (PBExtensionRegistry*) extensionRegistry {
  return extensionRegistry;
}

+ (void) initialize {
  if (self == [ZMOtrRoot class]) {
    PBMutableExtensionRegistry* registry = [PBMutableExtensionRegistry registry];
    [self registerAllExtensions:registry];
    [ObjectivecDescriptorRoot registerAllExtensions:registry];
    extensionRegistry = registry;
  }
}
+ (void) registerAllExtensions:(PBMutableExtensionRegistry*) registry {
}
@end

@interface ZMUserId ()
@property (strong) NSData* uuid;
@end

@implementation ZMUserId

- (BOOL) hasUuid {
  return !!hasUuid_;
}
- (void) setHasUuid:(BOOL) _value_ {
  hasUuid_ = !!_value_;
}
@synthesize uuid;
- (instancetype) init {
  if ((self = [super init])) {
    self.uuid = [NSData data];
  }
  return self;
}
static ZMUserId* defaultZMUserIdInstance = nil;
+ (void) initialize {
  if (self == [ZMUserId class]) {
    defaultZMUserIdInstance = [[ZMUserId alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMUserIdInstance;
}
- (instancetype) defaultInstance {
  return defaultZMUserIdInstance;
}
- (BOOL) isInitialized {
  if (!self.hasUuid) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasUuid) {
    [output writeData:1 value:self.uuid];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasUuid) {
    size_ += computeDataSize(1, self.uuid);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMUserId*) parseFromData:(NSData*) data {
  return (ZMUserId*)[[[ZMUserId builder] mergeFromData:data] build];
}
+ (ZMUserId*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMUserId*)[[[ZMUserId builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMUserId*) parseFromInputStream:(NSInputStream*) input {
  return (ZMUserId*)[[[ZMUserId builder] mergeFromInputStream:input] build];
}
+ (ZMUserId*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMUserId*)[[[ZMUserId builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMUserId*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMUserId*)[[[ZMUserId builder] mergeFromCodedInputStream:input] build];
}
+ (ZMUserId*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMUserId*)[[[ZMUserId builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMUserIdBuilder*) builder {
  return [[ZMUserIdBuilder alloc] init];
}
+ (ZMUserIdBuilder*) builderWithPrototype:(ZMUserId*) prototype {
  return [[ZMUserId builder] mergeFrom:prototype];
}
- (ZMUserIdBuilder*) builder {
  return [ZMUserId builder];
}
- (ZMUserIdBuilder*) toBuilder {
  return [ZMUserId builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasUuid) {
    [output appendFormat:@"%@%@: %@\n", indent, @"uuid", self.uuid];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasUuid) {
    [dictionary setObject: self.uuid forKey: @"uuid"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMUserId class]]) {
    return NO;
  }
  ZMUserId *otherMessage = other;
  return
      self.hasUuid == otherMessage.hasUuid &&
      (!self.hasUuid || [self.uuid isEqual:otherMessage.uuid]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasUuid) {
    hashCode = hashCode * 31 + [self.uuid hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMUserIdBuilder()
@property (strong) ZMUserId* resultUserId;
@end

@implementation ZMUserIdBuilder
@synthesize resultUserId;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultUserId = [[ZMUserId alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultUserId;
}
- (ZMUserIdBuilder*) clear {
  self.resultUserId = [[ZMUserId alloc] init];
  return self;
}
- (ZMUserIdBuilder*) clone {
  return [ZMUserId builderWithPrototype:resultUserId];
}
- (ZMUserId*) defaultInstance {
  return [ZMUserId defaultInstance];
}
- (ZMUserId*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMUserId*) buildPartial {
  ZMUserId* returnMe = resultUserId;
  self.resultUserId = nil;
  return returnMe;
}
- (ZMUserIdBuilder*) mergeFrom:(ZMUserId*) other {
  if (other == [ZMUserId defaultInstance]) {
    return self;
  }
  if (other.hasUuid) {
    [self setUuid:other.uuid];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMUserIdBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMUserIdBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setUuid:[input readData]];
        break;
      }
    }
  }
}
- (BOOL) hasUuid {
  return resultUserId.hasUuid;
}
- (NSData*) uuid {
  return resultUserId.uuid;
}
- (ZMUserIdBuilder*) setUuid:(NSData*) value {
  resultUserId.hasUuid = YES;
  resultUserId.uuid = value;
  return self;
}
- (ZMUserIdBuilder*) clearUuid {
  resultUserId.hasUuid = NO;
  resultUserId.uuid = [NSData data];
  return self;
}
@end

@interface ZMClientId ()
@property UInt64 client;
@end

@implementation ZMClientId

- (BOOL) hasClient {
  return !!hasClient_;
}
- (void) setHasClient:(BOOL) _value_ {
  hasClient_ = !!_value_;
}
@synthesize client;
- (instancetype) init {
  if ((self = [super init])) {
    self.client = 0L;
  }
  return self;
}
static ZMClientId* defaultZMClientIdInstance = nil;
+ (void) initialize {
  if (self == [ZMClientId class]) {
    defaultZMClientIdInstance = [[ZMClientId alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMClientIdInstance;
}
- (instancetype) defaultInstance {
  return defaultZMClientIdInstance;
}
- (BOOL) isInitialized {
  if (!self.hasClient) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasClient) {
    [output writeUInt64:1 value:self.client];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasClient) {
    size_ += computeUInt64Size(1, self.client);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMClientId*) parseFromData:(NSData*) data {
  return (ZMClientId*)[[[ZMClientId builder] mergeFromData:data] build];
}
+ (ZMClientId*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMClientId*)[[[ZMClientId builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMClientId*) parseFromInputStream:(NSInputStream*) input {
  return (ZMClientId*)[[[ZMClientId builder] mergeFromInputStream:input] build];
}
+ (ZMClientId*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMClientId*)[[[ZMClientId builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMClientId*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMClientId*)[[[ZMClientId builder] mergeFromCodedInputStream:input] build];
}
+ (ZMClientId*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMClientId*)[[[ZMClientId builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMClientIdBuilder*) builder {
  return [[ZMClientIdBuilder alloc] init];
}
+ (ZMClientIdBuilder*) builderWithPrototype:(ZMClientId*) prototype {
  return [[ZMClientId builder] mergeFrom:prototype];
}
- (ZMClientIdBuilder*) builder {
  return [ZMClientId builder];
}
- (ZMClientIdBuilder*) toBuilder {
  return [ZMClientId builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasClient) {
    [output appendFormat:@"%@%@: %@\n", indent, @"client", [NSNumber numberWithLongLong:self.client]];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasClient) {
    [dictionary setObject: [NSNumber numberWithLongLong:self.client] forKey: @"client"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMClientId class]]) {
    return NO;
  }
  ZMClientId *otherMessage = other;
  return
      self.hasClient == otherMessage.hasClient &&
      (!self.hasClient || self.client == otherMessage.client) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasClient) {
    hashCode = hashCode * 31 + [[NSNumber numberWithLongLong:self.client] hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMClientIdBuilder()
@property (strong) ZMClientId* resultClientId;
@end

@implementation ZMClientIdBuilder
@synthesize resultClientId;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultClientId = [[ZMClientId alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultClientId;
}
- (ZMClientIdBuilder*) clear {
  self.resultClientId = [[ZMClientId alloc] init];
  return self;
}
- (ZMClientIdBuilder*) clone {
  return [ZMClientId builderWithPrototype:resultClientId];
}
- (ZMClientId*) defaultInstance {
  return [ZMClientId defaultInstance];
}
- (ZMClientId*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMClientId*) buildPartial {
  ZMClientId* returnMe = resultClientId;
  self.resultClientId = nil;
  return returnMe;
}
- (ZMClientIdBuilder*) mergeFrom:(ZMClientId*) other {
  if (other == [ZMClientId defaultInstance]) {
    return self;
  }
  if (other.hasClient) {
    [self setClient:other.client];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMClientIdBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMClientIdBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setClient:[input readUInt64]];
        break;
      }
    }
  }
}
- (BOOL) hasClient {
  return resultClientId.hasClient;
}
- (UInt64) client {
  return resultClientId.client;
}
- (ZMClientIdBuilder*) setClient:(UInt64) value {
  resultClientId.hasClient = YES;
  resultClientId.client = value;
  return self;
}
- (ZMClientIdBuilder*) clearClient {
  resultClientId.hasClient = NO;
  resultClientId.client = 0L;
  return self;
}
@end

@interface ZMClientEntry ()
@property (strong) ZMClientId* client;
@property (strong) NSData* text;
@end

@implementation ZMClientEntry

- (BOOL) hasClient {
  return !!hasClient_;
}
- (void) setHasClient:(BOOL) _value_ {
  hasClient_ = !!_value_;
}
@synthesize client;
- (BOOL) hasText {
  return !!hasText_;
}
- (void) setHasText:(BOOL) _value_ {
  hasText_ = !!_value_;
}
@synthesize text;
- (instancetype) init {
  if ((self = [super init])) {
    self.client = [ZMClientId defaultInstance];
    self.text = [NSData data];
  }
  return self;
}
static ZMClientEntry* defaultZMClientEntryInstance = nil;
+ (void) initialize {
  if (self == [ZMClientEntry class]) {
    defaultZMClientEntryInstance = [[ZMClientEntry alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMClientEntryInstance;
}
- (instancetype) defaultInstance {
  return defaultZMClientEntryInstance;
}
- (BOOL) isInitialized {
  if (!self.hasClient) {
    return NO;
  }
  if (!self.hasText) {
    return NO;
  }
  if (!self.client.isInitialized) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasClient) {
    [output writeMessage:1 value:self.client];
  }
  if (self.hasText) {
    [output writeData:2 value:self.text];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasClient) {
    size_ += computeMessageSize(1, self.client);
  }
  if (self.hasText) {
    size_ += computeDataSize(2, self.text);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMClientEntry*) parseFromData:(NSData*) data {
  return (ZMClientEntry*)[[[ZMClientEntry builder] mergeFromData:data] build];
}
+ (ZMClientEntry*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMClientEntry*)[[[ZMClientEntry builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMClientEntry*) parseFromInputStream:(NSInputStream*) input {
  return (ZMClientEntry*)[[[ZMClientEntry builder] mergeFromInputStream:input] build];
}
+ (ZMClientEntry*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMClientEntry*)[[[ZMClientEntry builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMClientEntry*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMClientEntry*)[[[ZMClientEntry builder] mergeFromCodedInputStream:input] build];
}
+ (ZMClientEntry*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMClientEntry*)[[[ZMClientEntry builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMClientEntryBuilder*) builder {
  return [[ZMClientEntryBuilder alloc] init];
}
+ (ZMClientEntryBuilder*) builderWithPrototype:(ZMClientEntry*) prototype {
  return [[ZMClientEntry builder] mergeFrom:prototype];
}
- (ZMClientEntryBuilder*) builder {
  return [ZMClientEntry builder];
}
- (ZMClientEntryBuilder*) toBuilder {
  return [ZMClientEntry builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasClient) {
    [output appendFormat:@"%@%@ {\n", indent, @"client"];
    [self.client writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasText) {
    [output appendFormat:@"%@%@: %@\n", indent, @"text", self.text];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasClient) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.client storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"client"];
  }
  if (self.hasText) {
    [dictionary setObject: self.text forKey: @"text"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMClientEntry class]]) {
    return NO;
  }
  ZMClientEntry *otherMessage = other;
  return
      self.hasClient == otherMessage.hasClient &&
      (!self.hasClient || [self.client isEqual:otherMessage.client]) &&
      self.hasText == otherMessage.hasText &&
      (!self.hasText || [self.text isEqual:otherMessage.text]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasClient) {
    hashCode = hashCode * 31 + [self.client hash];
  }
  if (self.hasText) {
    hashCode = hashCode * 31 + [self.text hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMClientEntryBuilder()
@property (strong) ZMClientEntry* resultClientEntry;
@end

@implementation ZMClientEntryBuilder
@synthesize resultClientEntry;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultClientEntry = [[ZMClientEntry alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultClientEntry;
}
- (ZMClientEntryBuilder*) clear {
  self.resultClientEntry = [[ZMClientEntry alloc] init];
  return self;
}
- (ZMClientEntryBuilder*) clone {
  return [ZMClientEntry builderWithPrototype:resultClientEntry];
}
- (ZMClientEntry*) defaultInstance {
  return [ZMClientEntry defaultInstance];
}
- (ZMClientEntry*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMClientEntry*) buildPartial {
  ZMClientEntry* returnMe = resultClientEntry;
  self.resultClientEntry = nil;
  return returnMe;
}
- (ZMClientEntryBuilder*) mergeFrom:(ZMClientEntry*) other {
  if (other == [ZMClientEntry defaultInstance]) {
    return self;
  }
  if (other.hasClient) {
    [self mergeClient:other.client];
  }
  if (other.hasText) {
    [self setText:other.text];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMClientEntryBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMClientEntryBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        ZMClientIdBuilder* subBuilder = [ZMClientId builder];
        if (self.hasClient) {
          [subBuilder mergeFrom:self.client];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setClient:[subBuilder buildPartial]];
        break;
      }
      case 18: {
        [self setText:[input readData]];
        break;
      }
    }
  }
}
- (BOOL) hasClient {
  return resultClientEntry.hasClient;
}
- (ZMClientId*) client {
  return resultClientEntry.client;
}
- (ZMClientEntryBuilder*) setClient:(ZMClientId*) value {
  resultClientEntry.hasClient = YES;
  resultClientEntry.client = value;
  return self;
}
- (ZMClientEntryBuilder*) setClientBuilder:(ZMClientIdBuilder*) builderForValue {
  return [self setClient:[builderForValue build]];
}
- (ZMClientEntryBuilder*) mergeClient:(ZMClientId*) value {
  if (resultClientEntry.hasClient &&
      resultClientEntry.client != [ZMClientId defaultInstance]) {
    resultClientEntry.client =
      [[[ZMClientId builderWithPrototype:resultClientEntry.client] mergeFrom:value] buildPartial];
  } else {
    resultClientEntry.client = value;
  }
  resultClientEntry.hasClient = YES;
  return self;
}
- (ZMClientEntryBuilder*) clearClient {
  resultClientEntry.hasClient = NO;
  resultClientEntry.client = [ZMClientId defaultInstance];
  return self;
}
- (BOOL) hasText {
  return resultClientEntry.hasText;
}
- (NSData*) text {
  return resultClientEntry.text;
}
- (ZMClientEntryBuilder*) setText:(NSData*) value {
  resultClientEntry.hasText = YES;
  resultClientEntry.text = value;
  return self;
}
- (ZMClientEntryBuilder*) clearText {
  resultClientEntry.hasText = NO;
  resultClientEntry.text = [NSData data];
  return self;
}
@end

@interface ZMUserEntry ()
@property (strong) ZMUserId* user;
@property (strong) NSMutableArray<ZMClientEntry*> * clientsArray;
@end

@implementation ZMUserEntry

- (BOOL) hasUser {
  return !!hasUser_;
}
- (void) setHasUser:(BOOL) _value_ {
  hasUser_ = !!_value_;
}
@synthesize user;
@synthesize clientsArray;
@dynamic clients;
- (instancetype) init {
  if ((self = [super init])) {
    self.user = [ZMUserId defaultInstance];
  }
  return self;
}
static ZMUserEntry* defaultZMUserEntryInstance = nil;
+ (void) initialize {
  if (self == [ZMUserEntry class]) {
    defaultZMUserEntryInstance = [[ZMUserEntry alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMUserEntryInstance;
}
- (instancetype) defaultInstance {
  return defaultZMUserEntryInstance;
}
- (NSArray<ZMClientEntry*> *)clients {
  return clientsArray;
}
- (ZMClientEntry*)clientsAtIndex:(NSUInteger)index {
  return [clientsArray objectAtIndex:index];
}
- (BOOL) isInitialized {
  if (!self.hasUser) {
    return NO;
  }
  if (!self.user.isInitialized) {
    return NO;
  }
  __block BOOL isInitclients = YES;
   [self.clients enumerateObjectsUsingBlock:^(ZMClientEntry *element, NSUInteger idx, BOOL *stop) {
    if (!element.isInitialized) {
      isInitclients = NO;
      *stop = YES;
    }
  }];
  if (!isInitclients) return isInitclients;
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasUser) {
    [output writeMessage:1 value:self.user];
  }
  [self.clientsArray enumerateObjectsUsingBlock:^(ZMClientEntry *element, NSUInteger idx, BOOL *stop) {
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
  if (self.hasUser) {
    size_ += computeMessageSize(1, self.user);
  }
  [self.clientsArray enumerateObjectsUsingBlock:^(ZMClientEntry *element, NSUInteger idx, BOOL *stop) {
    size_ += computeMessageSize(2, element);
  }];
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMUserEntry*) parseFromData:(NSData*) data {
  return (ZMUserEntry*)[[[ZMUserEntry builder] mergeFromData:data] build];
}
+ (ZMUserEntry*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMUserEntry*)[[[ZMUserEntry builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMUserEntry*) parseFromInputStream:(NSInputStream*) input {
  return (ZMUserEntry*)[[[ZMUserEntry builder] mergeFromInputStream:input] build];
}
+ (ZMUserEntry*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMUserEntry*)[[[ZMUserEntry builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMUserEntry*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMUserEntry*)[[[ZMUserEntry builder] mergeFromCodedInputStream:input] build];
}
+ (ZMUserEntry*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMUserEntry*)[[[ZMUserEntry builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMUserEntryBuilder*) builder {
  return [[ZMUserEntryBuilder alloc] init];
}
+ (ZMUserEntryBuilder*) builderWithPrototype:(ZMUserEntry*) prototype {
  return [[ZMUserEntry builder] mergeFrom:prototype];
}
- (ZMUserEntryBuilder*) builder {
  return [ZMUserEntry builder];
}
- (ZMUserEntryBuilder*) toBuilder {
  return [ZMUserEntry builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasUser) {
    [output appendFormat:@"%@%@ {\n", indent, @"user"];
    [self.user writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  [self.clientsArray enumerateObjectsUsingBlock:^(ZMClientEntry *element, NSUInteger idx, BOOL *stop) {
    [output appendFormat:@"%@%@ {\n", indent, @"clients"];
    [element writeDescriptionTo:output
                     withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }];
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasUser) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.user storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"user"];
  }
  for (ZMClientEntry* element in self.clientsArray) {
    NSMutableDictionary *elementDictionary = [NSMutableDictionary dictionary];
    [element storeInDictionary:elementDictionary];
    [dictionary setObject:[NSDictionary dictionaryWithDictionary:elementDictionary] forKey:@"clients"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMUserEntry class]]) {
    return NO;
  }
  ZMUserEntry *otherMessage = other;
  return
      self.hasUser == otherMessage.hasUser &&
      (!self.hasUser || [self.user isEqual:otherMessage.user]) &&
      [self.clientsArray isEqualToArray:otherMessage.clientsArray] &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasUser) {
    hashCode = hashCode * 31 + [self.user hash];
  }
  [self.clientsArray enumerateObjectsUsingBlock:^(ZMClientEntry *element, NSUInteger idx, BOOL *stop) {
    hashCode = hashCode * 31 + [element hash];
  }];
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMUserEntryBuilder()
@property (strong) ZMUserEntry* resultUserEntry;
@end

@implementation ZMUserEntryBuilder
@synthesize resultUserEntry;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultUserEntry = [[ZMUserEntry alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultUserEntry;
}
- (ZMUserEntryBuilder*) clear {
  self.resultUserEntry = [[ZMUserEntry alloc] init];
  return self;
}
- (ZMUserEntryBuilder*) clone {
  return [ZMUserEntry builderWithPrototype:resultUserEntry];
}
- (ZMUserEntry*) defaultInstance {
  return [ZMUserEntry defaultInstance];
}
- (ZMUserEntry*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMUserEntry*) buildPartial {
  ZMUserEntry* returnMe = resultUserEntry;
  self.resultUserEntry = nil;
  return returnMe;
}
- (ZMUserEntryBuilder*) mergeFrom:(ZMUserEntry*) other {
  if (other == [ZMUserEntry defaultInstance]) {
    return self;
  }
  if (other.hasUser) {
    [self mergeUser:other.user];
  }
  if (other.clientsArray.count > 0) {
    if (resultUserEntry.clientsArray == nil) {
      resultUserEntry.clientsArray = [[NSMutableArray alloc] initWithArray:other.clientsArray];
    } else {
      [resultUserEntry.clientsArray addObjectsFromArray:other.clientsArray];
    }
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMUserEntryBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMUserEntryBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        ZMUserIdBuilder* subBuilder = [ZMUserId builder];
        if (self.hasUser) {
          [subBuilder mergeFrom:self.user];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setUser:[subBuilder buildPartial]];
        break;
      }
      case 18: {
        ZMClientEntryBuilder* subBuilder = [ZMClientEntry builder];
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self addClients:[subBuilder buildPartial]];
        break;
      }
    }
  }
}
- (BOOL) hasUser {
  return resultUserEntry.hasUser;
}
- (ZMUserId*) user {
  return resultUserEntry.user;
}
- (ZMUserEntryBuilder*) setUser:(ZMUserId*) value {
  resultUserEntry.hasUser = YES;
  resultUserEntry.user = value;
  return self;
}
- (ZMUserEntryBuilder*) setUserBuilder:(ZMUserIdBuilder*) builderForValue {
  return [self setUser:[builderForValue build]];
}
- (ZMUserEntryBuilder*) mergeUser:(ZMUserId*) value {
  if (resultUserEntry.hasUser &&
      resultUserEntry.user != [ZMUserId defaultInstance]) {
    resultUserEntry.user =
      [[[ZMUserId builderWithPrototype:resultUserEntry.user] mergeFrom:value] buildPartial];
  } else {
    resultUserEntry.user = value;
  }
  resultUserEntry.hasUser = YES;
  return self;
}
- (ZMUserEntryBuilder*) clearUser {
  resultUserEntry.hasUser = NO;
  resultUserEntry.user = [ZMUserId defaultInstance];
  return self;
}
- (NSMutableArray<ZMClientEntry*> *)clients {
  return resultUserEntry.clientsArray;
}
- (ZMClientEntry*)clientsAtIndex:(NSUInteger)index {
  return [resultUserEntry clientsAtIndex:index];
}
- (ZMUserEntryBuilder *)addClients:(ZMClientEntry*)value {
  if (resultUserEntry.clientsArray == nil) {
    resultUserEntry.clientsArray = [[NSMutableArray alloc]init];
  }
  [resultUserEntry.clientsArray addObject:value];
  return self;
}
- (ZMUserEntryBuilder *)setClientsArray:(NSArray<ZMClientEntry*> *)array {
  resultUserEntry.clientsArray = [[NSMutableArray alloc]initWithArray:array];
  return self;
}
- (ZMUserEntryBuilder *)clearClients {
  resultUserEntry.clientsArray = nil;
  return self;
}
@end

@interface ZMNewOtrMessage ()
@property (strong) ZMClientId* sender;
@property (strong) NSMutableArray<ZMUserEntry*> * recipientsArray;
@property BOOL nativePush;
@property (strong) NSData* blob;
@property ZMNewOtrMessagePriority nativePriority;
@property BOOL transient;
@property (strong) NSMutableArray<ZMUserId*> * reportMissingArray;
@end

@implementation ZMNewOtrMessage

- (BOOL) hasSender {
  return !!hasSender_;
}
- (void) setHasSender:(BOOL) _value_ {
  hasSender_ = !!_value_;
}
@synthesize sender;
@synthesize recipientsArray;
@dynamic recipients;
- (BOOL) hasNativePush {
  return !!hasNativePush_;
}
- (void) setHasNativePush:(BOOL) _value_ {
  hasNativePush_ = !!_value_;
}
- (BOOL) nativePush {
  return !!nativePush_;
}
- (void) setNativePush:(BOOL) _value_ {
  nativePush_ = !!_value_;
}
- (BOOL) hasBlob {
  return !!hasBlob_;
}
- (void) setHasBlob:(BOOL) _value_ {
  hasBlob_ = !!_value_;
}
@synthesize blob;
- (BOOL) hasNativePriority {
  return !!hasNativePriority_;
}
- (void) setHasNativePriority:(BOOL) _value_ {
  hasNativePriority_ = !!_value_;
}
@synthesize nativePriority;
- (BOOL) hasTransient {
  return !!hasTransient_;
}
- (void) setHasTransient:(BOOL) _value_ {
  hasTransient_ = !!_value_;
}
- (BOOL) transient {
  return !!transient_;
}
- (void) setTransient:(BOOL) _value_ {
  transient_ = !!_value_;
}
@synthesize reportMissingArray;
@dynamic reportMissing;
- (instancetype) init {
  if ((self = [super init])) {
    self.sender = [ZMClientId defaultInstance];
    self.nativePush = YES;
    self.blob = [NSData data];
    self.nativePriority = ZMNewOtrMessagePriorityLOWPRIORITY;
    self.transient = NO;
  }
  return self;
}
static ZMNewOtrMessage* defaultZMNewOtrMessageInstance = nil;
+ (void) initialize {
  if (self == [ZMNewOtrMessage class]) {
    defaultZMNewOtrMessageInstance = [[ZMNewOtrMessage alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMNewOtrMessageInstance;
}
- (instancetype) defaultInstance {
  return defaultZMNewOtrMessageInstance;
}
- (NSArray<ZMUserEntry*> *)recipients {
  return recipientsArray;
}
- (ZMUserEntry*)recipientsAtIndex:(NSUInteger)index {
  return [recipientsArray objectAtIndex:index];
}
- (NSArray<ZMUserId*> *)reportMissing {
  return reportMissingArray;
}
- (ZMUserId*)reportMissingAtIndex:(NSUInteger)index {
  return [reportMissingArray objectAtIndex:index];
}
- (BOOL) isInitialized {
  if (!self.hasSender) {
    return NO;
  }
  if (!self.sender.isInitialized) {
    return NO;
  }
  __block BOOL isInitrecipients = YES;
   [self.recipients enumerateObjectsUsingBlock:^(ZMUserEntry *element, NSUInteger idx, BOOL *stop) {
    if (!element.isInitialized) {
      isInitrecipients = NO;
      *stop = YES;
    }
  }];
  if (!isInitrecipients) return isInitrecipients;
  __block BOOL isInitreportMissing = YES;
   [self.reportMissing enumerateObjectsUsingBlock:^(ZMUserId *element, NSUInteger idx, BOOL *stop) {
    if (!element.isInitialized) {
      isInitreportMissing = NO;
      *stop = YES;
    }
  }];
  if (!isInitreportMissing) return isInitreportMissing;
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasSender) {
    [output writeMessage:1 value:self.sender];
  }
  [self.recipientsArray enumerateObjectsUsingBlock:^(ZMUserEntry *element, NSUInteger idx, BOOL *stop) {
    [output writeMessage:2 value:element];
  }];
  if (self.hasNativePush) {
    [output writeBool:3 value:self.nativePush];
  }
  if (self.hasBlob) {
    [output writeData:4 value:self.blob];
  }
  if (self.hasNativePriority) {
    [output writeEnum:5 value:self.nativePriority];
  }
  if (self.hasTransient) {
    [output writeBool:6 value:self.transient];
  }
  [self.reportMissingArray enumerateObjectsUsingBlock:^(ZMUserId *element, NSUInteger idx, BOOL *stop) {
    [output writeMessage:7 value:element];
  }];
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasSender) {
    size_ += computeMessageSize(1, self.sender);
  }
  [self.recipientsArray enumerateObjectsUsingBlock:^(ZMUserEntry *element, NSUInteger idx, BOOL *stop) {
    size_ += computeMessageSize(2, element);
  }];
  if (self.hasNativePush) {
    size_ += computeBoolSize(3, self.nativePush);
  }
  if (self.hasBlob) {
    size_ += computeDataSize(4, self.blob);
  }
  if (self.hasNativePriority) {
    size_ += computeEnumSize(5, self.nativePriority);
  }
  if (self.hasTransient) {
    size_ += computeBoolSize(6, self.transient);
  }
  [self.reportMissingArray enumerateObjectsUsingBlock:^(ZMUserId *element, NSUInteger idx, BOOL *stop) {
    size_ += computeMessageSize(7, element);
  }];
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMNewOtrMessage*) parseFromData:(NSData*) data {
  return (ZMNewOtrMessage*)[[[ZMNewOtrMessage builder] mergeFromData:data] build];
}
+ (ZMNewOtrMessage*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMNewOtrMessage*)[[[ZMNewOtrMessage builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMNewOtrMessage*) parseFromInputStream:(NSInputStream*) input {
  return (ZMNewOtrMessage*)[[[ZMNewOtrMessage builder] mergeFromInputStream:input] build];
}
+ (ZMNewOtrMessage*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMNewOtrMessage*)[[[ZMNewOtrMessage builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMNewOtrMessage*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMNewOtrMessage*)[[[ZMNewOtrMessage builder] mergeFromCodedInputStream:input] build];
}
+ (ZMNewOtrMessage*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMNewOtrMessage*)[[[ZMNewOtrMessage builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMNewOtrMessageBuilder*) builder {
  return [[ZMNewOtrMessageBuilder alloc] init];
}
+ (ZMNewOtrMessageBuilder*) builderWithPrototype:(ZMNewOtrMessage*) prototype {
  return [[ZMNewOtrMessage builder] mergeFrom:prototype];
}
- (ZMNewOtrMessageBuilder*) builder {
  return [ZMNewOtrMessage builder];
}
- (ZMNewOtrMessageBuilder*) toBuilder {
  return [ZMNewOtrMessage builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasSender) {
    [output appendFormat:@"%@%@ {\n", indent, @"sender"];
    [self.sender writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  [self.recipientsArray enumerateObjectsUsingBlock:^(ZMUserEntry *element, NSUInteger idx, BOOL *stop) {
    [output appendFormat:@"%@%@ {\n", indent, @"recipients"];
    [element writeDescriptionTo:output
                     withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }];
  if (self.hasNativePush) {
    [output appendFormat:@"%@%@: %@\n", indent, @"nativePush", [NSNumber numberWithBool:self.nativePush]];
  }
  if (self.hasBlob) {
    [output appendFormat:@"%@%@: %@\n", indent, @"blob", self.blob];
  }
  if (self.hasNativePriority) {
    [output appendFormat:@"%@%@: %@\n", indent, @"nativePriority", NSStringFromZMNewOtrMessagePriority(self.nativePriority)];
  }
  if (self.hasTransient) {
    [output appendFormat:@"%@%@: %@\n", indent, @"transient", [NSNumber numberWithBool:self.transient]];
  }
  [self.reportMissingArray enumerateObjectsUsingBlock:^(ZMUserId *element, NSUInteger idx, BOOL *stop) {
    [output appendFormat:@"%@%@ {\n", indent, @"reportMissing"];
    [element writeDescriptionTo:output
                     withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }];
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasSender) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.sender storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"sender"];
  }
  for (ZMUserEntry* element in self.recipientsArray) {
    NSMutableDictionary *elementDictionary = [NSMutableDictionary dictionary];
    [element storeInDictionary:elementDictionary];
    [dictionary setObject:[NSDictionary dictionaryWithDictionary:elementDictionary] forKey:@"recipients"];
  }
  if (self.hasNativePush) {
    [dictionary setObject: [NSNumber numberWithBool:self.nativePush] forKey: @"nativePush"];
  }
  if (self.hasBlob) {
    [dictionary setObject: self.blob forKey: @"blob"];
  }
  if (self.hasNativePriority) {
    [dictionary setObject: @(self.nativePriority) forKey: @"nativePriority"];
  }
  if (self.hasTransient) {
    [dictionary setObject: [NSNumber numberWithBool:self.transient] forKey: @"transient"];
  }
  for (ZMUserId* element in self.reportMissingArray) {
    NSMutableDictionary *elementDictionary = [NSMutableDictionary dictionary];
    [element storeInDictionary:elementDictionary];
    [dictionary setObject:[NSDictionary dictionaryWithDictionary:elementDictionary] forKey:@"reportMissing"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMNewOtrMessage class]]) {
    return NO;
  }
  ZMNewOtrMessage *otherMessage = other;
  return
      self.hasSender == otherMessage.hasSender &&
      (!self.hasSender || [self.sender isEqual:otherMessage.sender]) &&
      [self.recipientsArray isEqualToArray:otherMessage.recipientsArray] &&
      self.hasNativePush == otherMessage.hasNativePush &&
      (!self.hasNativePush || self.nativePush == otherMessage.nativePush) &&
      self.hasBlob == otherMessage.hasBlob &&
      (!self.hasBlob || [self.blob isEqual:otherMessage.blob]) &&
      self.hasNativePriority == otherMessage.hasNativePriority &&
      (!self.hasNativePriority || self.nativePriority == otherMessage.nativePriority) &&
      self.hasTransient == otherMessage.hasTransient &&
      (!self.hasTransient || self.transient == otherMessage.transient) &&
      [self.reportMissingArray isEqualToArray:otherMessage.reportMissingArray] &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasSender) {
    hashCode = hashCode * 31 + [self.sender hash];
  }
  [self.recipientsArray enumerateObjectsUsingBlock:^(ZMUserEntry *element, NSUInteger idx, BOOL *stop) {
    hashCode = hashCode * 31 + [element hash];
  }];
  if (self.hasNativePush) {
    hashCode = hashCode * 31 + [[NSNumber numberWithBool:self.nativePush] hash];
  }
  if (self.hasBlob) {
    hashCode = hashCode * 31 + [self.blob hash];
  }
  if (self.hasNativePriority) {
    hashCode = hashCode * 31 + self.nativePriority;
  }
  if (self.hasTransient) {
    hashCode = hashCode * 31 + [[NSNumber numberWithBool:self.transient] hash];
  }
  [self.reportMissingArray enumerateObjectsUsingBlock:^(ZMUserId *element, NSUInteger idx, BOOL *stop) {
    hashCode = hashCode * 31 + [element hash];
  }];
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

BOOL ZMNewOtrMessagePriorityIsValidValue(ZMNewOtrMessagePriority value) {
  switch (value) {
    case ZMNewOtrMessagePriorityLOWPRIORITY:
    case ZMNewOtrMessagePriorityHIGHPRIORITY:
      return YES;
    default:
      return NO;
  }
}
NSString *NSStringFromZMNewOtrMessagePriority(ZMNewOtrMessagePriority value) {
  switch (value) {
    case ZMNewOtrMessagePriorityLOWPRIORITY:
      return @"ZMNewOtrMessagePriorityLOWPRIORITY";
    case ZMNewOtrMessagePriorityHIGHPRIORITY:
      return @"ZMNewOtrMessagePriorityHIGHPRIORITY";
    default:
      return nil;
  }
}

@interface ZMNewOtrMessageBuilder()
@property (strong) ZMNewOtrMessage* resultNewOtrMessage;
@end

@implementation ZMNewOtrMessageBuilder
@synthesize resultNewOtrMessage;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultNewOtrMessage = [[ZMNewOtrMessage alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultNewOtrMessage;
}
- (ZMNewOtrMessageBuilder*) clear {
  self.resultNewOtrMessage = [[ZMNewOtrMessage alloc] init];
  return self;
}
- (ZMNewOtrMessageBuilder*) clone {
  return [ZMNewOtrMessage builderWithPrototype:resultNewOtrMessage];
}
- (ZMNewOtrMessage*) defaultInstance {
  return [ZMNewOtrMessage defaultInstance];
}
- (ZMNewOtrMessage*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMNewOtrMessage*) buildPartial {
  ZMNewOtrMessage* returnMe = resultNewOtrMessage;
  self.resultNewOtrMessage = nil;
  return returnMe;
}
- (ZMNewOtrMessageBuilder*) mergeFrom:(ZMNewOtrMessage*) other {
  if (other == [ZMNewOtrMessage defaultInstance]) {
    return self;
  }
  if (other.hasSender) {
    [self mergeSender:other.sender];
  }
  if (other.recipientsArray.count > 0) {
    if (resultNewOtrMessage.recipientsArray == nil) {
      resultNewOtrMessage.recipientsArray = [[NSMutableArray alloc] initWithArray:other.recipientsArray];
    } else {
      [resultNewOtrMessage.recipientsArray addObjectsFromArray:other.recipientsArray];
    }
  }
  if (other.hasNativePush) {
    [self setNativePush:other.nativePush];
  }
  if (other.hasBlob) {
    [self setBlob:other.blob];
  }
  if (other.hasNativePriority) {
    [self setNativePriority:other.nativePriority];
  }
  if (other.hasTransient) {
    [self setTransient:other.transient];
  }
  if (other.reportMissingArray.count > 0) {
    if (resultNewOtrMessage.reportMissingArray == nil) {
      resultNewOtrMessage.reportMissingArray = [[NSMutableArray alloc] initWithArray:other.reportMissingArray];
    } else {
      [resultNewOtrMessage.reportMissingArray addObjectsFromArray:other.reportMissingArray];
    }
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMNewOtrMessageBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMNewOtrMessageBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        ZMClientIdBuilder* subBuilder = [ZMClientId builder];
        if (self.hasSender) {
          [subBuilder mergeFrom:self.sender];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setSender:[subBuilder buildPartial]];
        break;
      }
      case 18: {
        ZMUserEntryBuilder* subBuilder = [ZMUserEntry builder];
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self addRecipients:[subBuilder buildPartial]];
        break;
      }
      case 24: {
        [self setNativePush:[input readBool]];
        break;
      }
      case 34: {
        [self setBlob:[input readData]];
        break;
      }
      case 40: {
        ZMNewOtrMessagePriority value = (ZMNewOtrMessagePriority)[input readEnum];
        if (ZMNewOtrMessagePriorityIsValidValue(value)) {
          [self setNativePriority:value];
        } else {
          [unknownFields mergeVarintField:5 value:value];
        }
        break;
      }
      case 48: {
        [self setTransient:[input readBool]];
        break;
      }
      case 58: {
        ZMUserIdBuilder* subBuilder = [ZMUserId builder];
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self addReportMissing:[subBuilder buildPartial]];
        break;
      }
    }
  }
}
- (BOOL) hasSender {
  return resultNewOtrMessage.hasSender;
}
- (ZMClientId*) sender {
  return resultNewOtrMessage.sender;
}
- (ZMNewOtrMessageBuilder*) setSender:(ZMClientId*) value {
  resultNewOtrMessage.hasSender = YES;
  resultNewOtrMessage.sender = value;
  return self;
}
- (ZMNewOtrMessageBuilder*) setSenderBuilder:(ZMClientIdBuilder*) builderForValue {
  return [self setSender:[builderForValue build]];
}
- (ZMNewOtrMessageBuilder*) mergeSender:(ZMClientId*) value {
  if (resultNewOtrMessage.hasSender &&
      resultNewOtrMessage.sender != [ZMClientId defaultInstance]) {
    resultNewOtrMessage.sender =
      [[[ZMClientId builderWithPrototype:resultNewOtrMessage.sender] mergeFrom:value] buildPartial];
  } else {
    resultNewOtrMessage.sender = value;
  }
  resultNewOtrMessage.hasSender = YES;
  return self;
}
- (ZMNewOtrMessageBuilder*) clearSender {
  resultNewOtrMessage.hasSender = NO;
  resultNewOtrMessage.sender = [ZMClientId defaultInstance];
  return self;
}
- (NSMutableArray<ZMUserEntry*> *)recipients {
  return resultNewOtrMessage.recipientsArray;
}
- (ZMUserEntry*)recipientsAtIndex:(NSUInteger)index {
  return [resultNewOtrMessage recipientsAtIndex:index];
}
- (ZMNewOtrMessageBuilder *)addRecipients:(ZMUserEntry*)value {
  if (resultNewOtrMessage.recipientsArray == nil) {
    resultNewOtrMessage.recipientsArray = [[NSMutableArray alloc]init];
  }
  [resultNewOtrMessage.recipientsArray addObject:value];
  return self;
}
- (ZMNewOtrMessageBuilder *)setRecipientsArray:(NSArray<ZMUserEntry*> *)array {
  resultNewOtrMessage.recipientsArray = [[NSMutableArray alloc]initWithArray:array];
  return self;
}
- (ZMNewOtrMessageBuilder *)clearRecipients {
  resultNewOtrMessage.recipientsArray = nil;
  return self;
}
- (BOOL) hasNativePush {
  return resultNewOtrMessage.hasNativePush;
}
- (BOOL) nativePush {
  return resultNewOtrMessage.nativePush;
}
- (ZMNewOtrMessageBuilder*) setNativePush:(BOOL) value {
  resultNewOtrMessage.hasNativePush = YES;
  resultNewOtrMessage.nativePush = value;
  return self;
}
- (ZMNewOtrMessageBuilder*) clearNativePush {
  resultNewOtrMessage.hasNativePush = NO;
  resultNewOtrMessage.nativePush = YES;
  return self;
}
- (BOOL) hasBlob {
  return resultNewOtrMessage.hasBlob;
}
- (NSData*) blob {
  return resultNewOtrMessage.blob;
}
- (ZMNewOtrMessageBuilder*) setBlob:(NSData*) value {
  resultNewOtrMessage.hasBlob = YES;
  resultNewOtrMessage.blob = value;
  return self;
}
- (ZMNewOtrMessageBuilder*) clearBlob {
  resultNewOtrMessage.hasBlob = NO;
  resultNewOtrMessage.blob = [NSData data];
  return self;
}
- (BOOL) hasNativePriority {
  return resultNewOtrMessage.hasNativePriority;
}
- (ZMNewOtrMessagePriority) nativePriority {
  return resultNewOtrMessage.nativePriority;
}
- (ZMNewOtrMessageBuilder*) setNativePriority:(ZMNewOtrMessagePriority) value {
  resultNewOtrMessage.hasNativePriority = YES;
  resultNewOtrMessage.nativePriority = value;
  return self;
}
- (ZMNewOtrMessageBuilder*) clearNativePriority {
  resultNewOtrMessage.hasNativePriority = NO;
  resultNewOtrMessage.nativePriority = ZMNewOtrMessagePriorityLOWPRIORITY;
  return self;
}
- (BOOL) hasTransient {
  return resultNewOtrMessage.hasTransient;
}
- (BOOL) transient {
  return resultNewOtrMessage.transient;
}
- (ZMNewOtrMessageBuilder*) setTransient:(BOOL) value {
  resultNewOtrMessage.hasTransient = YES;
  resultNewOtrMessage.transient = value;
  return self;
}
- (ZMNewOtrMessageBuilder*) clearTransient {
  resultNewOtrMessage.hasTransient = NO;
  resultNewOtrMessage.transient = NO;
  return self;
}
- (NSMutableArray<ZMUserId*> *)reportMissing {
  return resultNewOtrMessage.reportMissingArray;
}
- (ZMUserId*)reportMissingAtIndex:(NSUInteger)index {
  return [resultNewOtrMessage reportMissingAtIndex:index];
}
- (ZMNewOtrMessageBuilder *)addReportMissing:(ZMUserId*)value {
  if (resultNewOtrMessage.reportMissingArray == nil) {
    resultNewOtrMessage.reportMissingArray = [[NSMutableArray alloc]init];
  }
  [resultNewOtrMessage.reportMissingArray addObject:value];
  return self;
}
- (ZMNewOtrMessageBuilder *)setReportMissingArray:(NSArray<ZMUserId*> *)array {
  resultNewOtrMessage.reportMissingArray = [[NSMutableArray alloc]initWithArray:array];
  return self;
}
- (ZMNewOtrMessageBuilder *)clearReportMissing {
  resultNewOtrMessage.reportMissingArray = nil;
  return self;
}
@end

@interface ZMOtrAssetMeta ()
@property (strong) ZMClientId* sender;
@property (strong) NSMutableArray<ZMUserEntry*> * recipientsArray;
@property BOOL isInline;
@property BOOL nativePush;
@end

@implementation ZMOtrAssetMeta

- (BOOL) hasSender {
  return !!hasSender_;
}
- (void) setHasSender:(BOOL) _value_ {
  hasSender_ = !!_value_;
}
@synthesize sender;
@synthesize recipientsArray;
@dynamic recipients;
- (BOOL) hasIsInline {
  return !!hasIsInline_;
}
- (void) setHasIsInline:(BOOL) _value_ {
  hasIsInline_ = !!_value_;
}
- (BOOL) isInline {
  return !!isInline_;
}
- (void) setIsInline:(BOOL) _value_ {
  isInline_ = !!_value_;
}
- (BOOL) hasNativePush {
  return !!hasNativePush_;
}
- (void) setHasNativePush:(BOOL) _value_ {
  hasNativePush_ = !!_value_;
}
- (BOOL) nativePush {
  return !!nativePush_;
}
- (void) setNativePush:(BOOL) _value_ {
  nativePush_ = !!_value_;
}
- (instancetype) init {
  if ((self = [super init])) {
    self.sender = [ZMClientId defaultInstance];
    self.isInline = NO;
    self.nativePush = YES;
  }
  return self;
}
static ZMOtrAssetMeta* defaultZMOtrAssetMetaInstance = nil;
+ (void) initialize {
  if (self == [ZMOtrAssetMeta class]) {
    defaultZMOtrAssetMetaInstance = [[ZMOtrAssetMeta alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMOtrAssetMetaInstance;
}
- (instancetype) defaultInstance {
  return defaultZMOtrAssetMetaInstance;
}
- (NSArray<ZMUserEntry*> *)recipients {
  return recipientsArray;
}
- (ZMUserEntry*)recipientsAtIndex:(NSUInteger)index {
  return [recipientsArray objectAtIndex:index];
}
- (BOOL) isInitialized {
  if (!self.hasSender) {
    return NO;
  }
  if (!self.sender.isInitialized) {
    return NO;
  }
  __block BOOL isInitrecipients = YES;
   [self.recipients enumerateObjectsUsingBlock:^(ZMUserEntry *element, NSUInteger idx, BOOL *stop) {
    if (!element.isInitialized) {
      isInitrecipients = NO;
      *stop = YES;
    }
  }];
  if (!isInitrecipients) return isInitrecipients;
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasSender) {
    [output writeMessage:1 value:self.sender];
  }
  [self.recipientsArray enumerateObjectsUsingBlock:^(ZMUserEntry *element, NSUInteger idx, BOOL *stop) {
    [output writeMessage:2 value:element];
  }];
  if (self.hasIsInline) {
    [output writeBool:3 value:self.isInline];
  }
  if (self.hasNativePush) {
    [output writeBool:4 value:self.nativePush];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasSender) {
    size_ += computeMessageSize(1, self.sender);
  }
  [self.recipientsArray enumerateObjectsUsingBlock:^(ZMUserEntry *element, NSUInteger idx, BOOL *stop) {
    size_ += computeMessageSize(2, element);
  }];
  if (self.hasIsInline) {
    size_ += computeBoolSize(3, self.isInline);
  }
  if (self.hasNativePush) {
    size_ += computeBoolSize(4, self.nativePush);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMOtrAssetMeta*) parseFromData:(NSData*) data {
  return (ZMOtrAssetMeta*)[[[ZMOtrAssetMeta builder] mergeFromData:data] build];
}
+ (ZMOtrAssetMeta*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMOtrAssetMeta*)[[[ZMOtrAssetMeta builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMOtrAssetMeta*) parseFromInputStream:(NSInputStream*) input {
  return (ZMOtrAssetMeta*)[[[ZMOtrAssetMeta builder] mergeFromInputStream:input] build];
}
+ (ZMOtrAssetMeta*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMOtrAssetMeta*)[[[ZMOtrAssetMeta builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMOtrAssetMeta*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMOtrAssetMeta*)[[[ZMOtrAssetMeta builder] mergeFromCodedInputStream:input] build];
}
+ (ZMOtrAssetMeta*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMOtrAssetMeta*)[[[ZMOtrAssetMeta builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMOtrAssetMetaBuilder*) builder {
  return [[ZMOtrAssetMetaBuilder alloc] init];
}
+ (ZMOtrAssetMetaBuilder*) builderWithPrototype:(ZMOtrAssetMeta*) prototype {
  return [[ZMOtrAssetMeta builder] mergeFrom:prototype];
}
- (ZMOtrAssetMetaBuilder*) builder {
  return [ZMOtrAssetMeta builder];
}
- (ZMOtrAssetMetaBuilder*) toBuilder {
  return [ZMOtrAssetMeta builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasSender) {
    [output appendFormat:@"%@%@ {\n", indent, @"sender"];
    [self.sender writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  [self.recipientsArray enumerateObjectsUsingBlock:^(ZMUserEntry *element, NSUInteger idx, BOOL *stop) {
    [output appendFormat:@"%@%@ {\n", indent, @"recipients"];
    [element writeDescriptionTo:output
                     withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }];
  if (self.hasIsInline) {
    [output appendFormat:@"%@%@: %@\n", indent, @"isInline", [NSNumber numberWithBool:self.isInline]];
  }
  if (self.hasNativePush) {
    [output appendFormat:@"%@%@: %@\n", indent, @"nativePush", [NSNumber numberWithBool:self.nativePush]];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasSender) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.sender storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"sender"];
  }
  for (ZMUserEntry* element in self.recipientsArray) {
    NSMutableDictionary *elementDictionary = [NSMutableDictionary dictionary];
    [element storeInDictionary:elementDictionary];
    [dictionary setObject:[NSDictionary dictionaryWithDictionary:elementDictionary] forKey:@"recipients"];
  }
  if (self.hasIsInline) {
    [dictionary setObject: [NSNumber numberWithBool:self.isInline] forKey: @"isInline"];
  }
  if (self.hasNativePush) {
    [dictionary setObject: [NSNumber numberWithBool:self.nativePush] forKey: @"nativePush"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMOtrAssetMeta class]]) {
    return NO;
  }
  ZMOtrAssetMeta *otherMessage = other;
  return
      self.hasSender == otherMessage.hasSender &&
      (!self.hasSender || [self.sender isEqual:otherMessage.sender]) &&
      [self.recipientsArray isEqualToArray:otherMessage.recipientsArray] &&
      self.hasIsInline == otherMessage.hasIsInline &&
      (!self.hasIsInline || self.isInline == otherMessage.isInline) &&
      self.hasNativePush == otherMessage.hasNativePush &&
      (!self.hasNativePush || self.nativePush == otherMessage.nativePush) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasSender) {
    hashCode = hashCode * 31 + [self.sender hash];
  }
  [self.recipientsArray enumerateObjectsUsingBlock:^(ZMUserEntry *element, NSUInteger idx, BOOL *stop) {
    hashCode = hashCode * 31 + [element hash];
  }];
  if (self.hasIsInline) {
    hashCode = hashCode * 31 + [[NSNumber numberWithBool:self.isInline] hash];
  }
  if (self.hasNativePush) {
    hashCode = hashCode * 31 + [[NSNumber numberWithBool:self.nativePush] hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMOtrAssetMetaBuilder()
@property (strong) ZMOtrAssetMeta* resultOtrAssetMeta;
@end

@implementation ZMOtrAssetMetaBuilder
@synthesize resultOtrAssetMeta;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultOtrAssetMeta = [[ZMOtrAssetMeta alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultOtrAssetMeta;
}
- (ZMOtrAssetMetaBuilder*) clear {
  self.resultOtrAssetMeta = [[ZMOtrAssetMeta alloc] init];
  return self;
}
- (ZMOtrAssetMetaBuilder*) clone {
  return [ZMOtrAssetMeta builderWithPrototype:resultOtrAssetMeta];
}
- (ZMOtrAssetMeta*) defaultInstance {
  return [ZMOtrAssetMeta defaultInstance];
}
- (ZMOtrAssetMeta*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMOtrAssetMeta*) buildPartial {
  ZMOtrAssetMeta* returnMe = resultOtrAssetMeta;
  self.resultOtrAssetMeta = nil;
  return returnMe;
}
- (ZMOtrAssetMetaBuilder*) mergeFrom:(ZMOtrAssetMeta*) other {
  if (other == [ZMOtrAssetMeta defaultInstance]) {
    return self;
  }
  if (other.hasSender) {
    [self mergeSender:other.sender];
  }
  if (other.recipientsArray.count > 0) {
    if (resultOtrAssetMeta.recipientsArray == nil) {
      resultOtrAssetMeta.recipientsArray = [[NSMutableArray alloc] initWithArray:other.recipientsArray];
    } else {
      [resultOtrAssetMeta.recipientsArray addObjectsFromArray:other.recipientsArray];
    }
  }
  if (other.hasIsInline) {
    [self setIsInline:other.isInline];
  }
  if (other.hasNativePush) {
    [self setNativePush:other.nativePush];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMOtrAssetMetaBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMOtrAssetMetaBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        ZMClientIdBuilder* subBuilder = [ZMClientId builder];
        if (self.hasSender) {
          [subBuilder mergeFrom:self.sender];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setSender:[subBuilder buildPartial]];
        break;
      }
      case 18: {
        ZMUserEntryBuilder* subBuilder = [ZMUserEntry builder];
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self addRecipients:[subBuilder buildPartial]];
        break;
      }
      case 24: {
        [self setIsInline:[input readBool]];
        break;
      }
      case 32: {
        [self setNativePush:[input readBool]];
        break;
      }
    }
  }
}
- (BOOL) hasSender {
  return resultOtrAssetMeta.hasSender;
}
- (ZMClientId*) sender {
  return resultOtrAssetMeta.sender;
}
- (ZMOtrAssetMetaBuilder*) setSender:(ZMClientId*) value {
  resultOtrAssetMeta.hasSender = YES;
  resultOtrAssetMeta.sender = value;
  return self;
}
- (ZMOtrAssetMetaBuilder*) setSenderBuilder:(ZMClientIdBuilder*) builderForValue {
  return [self setSender:[builderForValue build]];
}
- (ZMOtrAssetMetaBuilder*) mergeSender:(ZMClientId*) value {
  if (resultOtrAssetMeta.hasSender &&
      resultOtrAssetMeta.sender != [ZMClientId defaultInstance]) {
    resultOtrAssetMeta.sender =
      [[[ZMClientId builderWithPrototype:resultOtrAssetMeta.sender] mergeFrom:value] buildPartial];
  } else {
    resultOtrAssetMeta.sender = value;
  }
  resultOtrAssetMeta.hasSender = YES;
  return self;
}
- (ZMOtrAssetMetaBuilder*) clearSender {
  resultOtrAssetMeta.hasSender = NO;
  resultOtrAssetMeta.sender = [ZMClientId defaultInstance];
  return self;
}
- (NSMutableArray<ZMUserEntry*> *)recipients {
  return resultOtrAssetMeta.recipientsArray;
}
- (ZMUserEntry*)recipientsAtIndex:(NSUInteger)index {
  return [resultOtrAssetMeta recipientsAtIndex:index];
}
- (ZMOtrAssetMetaBuilder *)addRecipients:(ZMUserEntry*)value {
  if (resultOtrAssetMeta.recipientsArray == nil) {
    resultOtrAssetMeta.recipientsArray = [[NSMutableArray alloc]init];
  }
  [resultOtrAssetMeta.recipientsArray addObject:value];
  return self;
}
- (ZMOtrAssetMetaBuilder *)setRecipientsArray:(NSArray<ZMUserEntry*> *)array {
  resultOtrAssetMeta.recipientsArray = [[NSMutableArray alloc]initWithArray:array];
  return self;
}
- (ZMOtrAssetMetaBuilder *)clearRecipients {
  resultOtrAssetMeta.recipientsArray = nil;
  return self;
}
- (BOOL) hasIsInline {
  return resultOtrAssetMeta.hasIsInline;
}
- (BOOL) isInline {
  return resultOtrAssetMeta.isInline;
}
- (ZMOtrAssetMetaBuilder*) setIsInline:(BOOL) value {
  resultOtrAssetMeta.hasIsInline = YES;
  resultOtrAssetMeta.isInline = value;
  return self;
}
- (ZMOtrAssetMetaBuilder*) clearIsInline {
  resultOtrAssetMeta.hasIsInline = NO;
  resultOtrAssetMeta.isInline = NO;
  return self;
}
- (BOOL) hasNativePush {
  return resultOtrAssetMeta.hasNativePush;
}
- (BOOL) nativePush {
  return resultOtrAssetMeta.nativePush;
}
- (ZMOtrAssetMetaBuilder*) setNativePush:(BOOL) value {
  resultOtrAssetMeta.hasNativePush = YES;
  resultOtrAssetMeta.nativePush = value;
  return self;
}
- (ZMOtrAssetMetaBuilder*) clearNativePush {
  resultOtrAssetMeta.hasNativePush = NO;
  resultOtrAssetMeta.nativePush = YES;
  return self;
}
@end


// @@protoc_insertion_point(global_scope)
