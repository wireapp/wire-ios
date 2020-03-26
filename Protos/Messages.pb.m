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

BOOL ZMEncryptionAlgorithmIsValidValue(ZMEncryptionAlgorithm value) {
  switch (value) {
    case ZMEncryptionAlgorithmAESCBC:
    case ZMEncryptionAlgorithmAESGCM:
      return YES;
    default:
      return NO;
  }
}
NSString *NSStringFromZMEncryptionAlgorithm(ZMEncryptionAlgorithm value) {
  switch (value) {
    case ZMEncryptionAlgorithmAESCBC:
      return @"ZMEncryptionAlgorithmAESCBC";
    case ZMEncryptionAlgorithmAESGCM:
      return @"ZMEncryptionAlgorithmAESGCM";
    default:
      return nil;
  }
}

BOOL ZMLegalHoldStatusIsValidValue(ZMLegalHoldStatus value) {
  switch (value) {
    case ZMLegalHoldStatusUNKNOWN:
    case ZMLegalHoldStatusDISABLED:
    case ZMLegalHoldStatusENABLED:
      return YES;
    default:
      return NO;
  }
}
NSString *NSStringFromZMLegalHoldStatus(ZMLegalHoldStatus value) {
  switch (value) {
    case ZMLegalHoldStatusUNKNOWN:
      return @"ZMLegalHoldStatusUNKNOWN";
    case ZMLegalHoldStatusDISABLED:
      return @"ZMLegalHoldStatusDISABLED";
    case ZMLegalHoldStatusENABLED:
      return @"ZMLegalHoldStatusENABLED";
    default:
      return nil;
  }
}

@interface ZMGenericMessage ()
@property (strong) NSString* messageId;
@property (strong) ZMText* text;
@property (strong) ZMImageAsset* image;
@property (strong) ZMKnock* knock;
@property (strong) ZMLastRead* lastRead;
@property (strong) ZMCleared* cleared;
@property (strong) ZMExternal* external;
@property ZMClientAction clientAction;
@property (strong) ZMCalling* calling;
@property (strong) ZMAsset* asset;
@property (strong) ZMMessageHide* hidden;
@property (strong) ZMLocation* location;
@property (strong) ZMMessageDelete* deleted;
@property (strong) ZMMessageEdit* edited;
@property (strong) ZMConfirmation* confirmation;
@property (strong) ZMReaction* reaction;
@property (strong) ZMEphemeral* ephemeral;
@property (strong) ZMAvailability* availability;
@property (strong) ZMComposite* composite;
@property (strong) ZMButtonAction* buttonAction;
@property (strong) ZMButtonActionConfirmation* buttonActionConfirmation;
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
- (BOOL) hasHidden {
  return !!hasHidden_;
}
- (void) setHasHidden:(BOOL) _value_ {
  hasHidden_ = !!_value_;
}
@synthesize hidden;
- (BOOL) hasLocation {
  return !!hasLocation_;
}
- (void) setHasLocation:(BOOL) _value_ {
  hasLocation_ = !!_value_;
}
@synthesize location;
- (BOOL) hasDeleted {
  return !!hasDeleted_;
}
- (void) setHasDeleted:(BOOL) _value_ {
  hasDeleted_ = !!_value_;
}
@synthesize deleted;
- (BOOL) hasEdited {
  return !!hasEdited_;
}
- (void) setHasEdited:(BOOL) _value_ {
  hasEdited_ = !!_value_;
}
@synthesize edited;
- (BOOL) hasConfirmation {
  return !!hasConfirmation_;
}
- (void) setHasConfirmation:(BOOL) _value_ {
  hasConfirmation_ = !!_value_;
}
@synthesize confirmation;
- (BOOL) hasReaction {
  return !!hasReaction_;
}
- (void) setHasReaction:(BOOL) _value_ {
  hasReaction_ = !!_value_;
}
@synthesize reaction;
- (BOOL) hasEphemeral {
  return !!hasEphemeral_;
}
- (void) setHasEphemeral:(BOOL) _value_ {
  hasEphemeral_ = !!_value_;
}
@synthesize ephemeral;
- (BOOL) hasAvailability {
  return !!hasAvailability_;
}
- (void) setHasAvailability:(BOOL) _value_ {
  hasAvailability_ = !!_value_;
}
@synthesize availability;
- (BOOL) hasComposite {
  return !!hasComposite_;
}
- (void) setHasComposite:(BOOL) _value_ {
  hasComposite_ = !!_value_;
}
@synthesize composite;
- (BOOL) hasButtonAction {
  return !!hasButtonAction_;
}
- (void) setHasButtonAction:(BOOL) _value_ {
  hasButtonAction_ = !!_value_;
}
@synthesize buttonAction;
- (BOOL) hasButtonActionConfirmation {
  return !!hasButtonActionConfirmation_;
}
- (void) setHasButtonActionConfirmation:(BOOL) _value_ {
  hasButtonActionConfirmation_ = !!_value_;
}
@synthesize buttonActionConfirmation;
- (instancetype) init {
  if ((self = [super init])) {
    self.messageId = @"";
    self.text = [ZMText defaultInstance];
    self.image = [ZMImageAsset defaultInstance];
    self.knock = [ZMKnock defaultInstance];
    self.lastRead = [ZMLastRead defaultInstance];
    self.cleared = [ZMCleared defaultInstance];
    self.external = [ZMExternal defaultInstance];
    self.clientAction = ZMClientActionRESETSESSION;
    self.calling = [ZMCalling defaultInstance];
    self.asset = [ZMAsset defaultInstance];
    self.hidden = [ZMMessageHide defaultInstance];
    self.location = [ZMLocation defaultInstance];
    self.deleted = [ZMMessageDelete defaultInstance];
    self.edited = [ZMMessageEdit defaultInstance];
    self.confirmation = [ZMConfirmation defaultInstance];
    self.reaction = [ZMReaction defaultInstance];
    self.ephemeral = [ZMEphemeral defaultInstance];
    self.availability = [ZMAvailability defaultInstance];
    self.composite = [ZMComposite defaultInstance];
    self.buttonAction = [ZMButtonAction defaultInstance];
    self.buttonActionConfirmation = [ZMButtonActionConfirmation defaultInstance];
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
  if (self.hasHidden) {
    if (!self.hidden.isInitialized) {
      return NO;
    }
  }
  if (self.hasLocation) {
    if (!self.location.isInitialized) {
      return NO;
    }
  }
  if (self.hasDeleted) {
    if (!self.deleted.isInitialized) {
      return NO;
    }
  }
  if (self.hasEdited) {
    if (!self.edited.isInitialized) {
      return NO;
    }
  }
  if (self.hasConfirmation) {
    if (!self.confirmation.isInitialized) {
      return NO;
    }
  }
  if (self.hasReaction) {
    if (!self.reaction.isInitialized) {
      return NO;
    }
  }
  if (self.hasEphemeral) {
    if (!self.ephemeral.isInitialized) {
      return NO;
    }
  }
  if (self.hasAvailability) {
    if (!self.availability.isInitialized) {
      return NO;
    }
  }
  if (self.hasComposite) {
    if (!self.composite.isInitialized) {
      return NO;
    }
  }
  if (self.hasButtonAction) {
    if (!self.buttonAction.isInitialized) {
      return NO;
    }
  }
  if (self.hasButtonActionConfirmation) {
    if (!self.buttonActionConfirmation.isInitialized) {
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
  if (self.hasHidden) {
    [output writeMessage:12 value:self.hidden];
  }
  if (self.hasLocation) {
    [output writeMessage:13 value:self.location];
  }
  if (self.hasDeleted) {
    [output writeMessage:14 value:self.deleted];
  }
  if (self.hasEdited) {
    [output writeMessage:15 value:self.edited];
  }
  if (self.hasConfirmation) {
    [output writeMessage:16 value:self.confirmation];
  }
  if (self.hasReaction) {
    [output writeMessage:17 value:self.reaction];
  }
  if (self.hasEphemeral) {
    [output writeMessage:18 value:self.ephemeral];
  }
  if (self.hasAvailability) {
    [output writeMessage:19 value:self.availability];
  }
  if (self.hasComposite) {
    [output writeMessage:20 value:self.composite];
  }
  if (self.hasButtonAction) {
    [output writeMessage:21 value:self.buttonAction];
  }
  if (self.hasButtonActionConfirmation) {
    [output writeMessage:22 value:self.buttonActionConfirmation];
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
  if (self.hasHidden) {
    size_ += computeMessageSize(12, self.hidden);
  }
  if (self.hasLocation) {
    size_ += computeMessageSize(13, self.location);
  }
  if (self.hasDeleted) {
    size_ += computeMessageSize(14, self.deleted);
  }
  if (self.hasEdited) {
    size_ += computeMessageSize(15, self.edited);
  }
  if (self.hasConfirmation) {
    size_ += computeMessageSize(16, self.confirmation);
  }
  if (self.hasReaction) {
    size_ += computeMessageSize(17, self.reaction);
  }
  if (self.hasEphemeral) {
    size_ += computeMessageSize(18, self.ephemeral);
  }
  if (self.hasAvailability) {
    size_ += computeMessageSize(19, self.availability);
  }
  if (self.hasComposite) {
    size_ += computeMessageSize(20, self.composite);
  }
  if (self.hasButtonAction) {
    size_ += computeMessageSize(21, self.buttonAction);
  }
  if (self.hasButtonActionConfirmation) {
    size_ += computeMessageSize(22, self.buttonActionConfirmation);
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
  if (self.hasHidden) {
    [output appendFormat:@"%@%@ {\n", indent, @"hidden"];
    [self.hidden writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasLocation) {
    [output appendFormat:@"%@%@ {\n", indent, @"location"];
    [self.location writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasDeleted) {
    [output appendFormat:@"%@%@ {\n", indent, @"deleted"];
    [self.deleted writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasEdited) {
    [output appendFormat:@"%@%@ {\n", indent, @"edited"];
    [self.edited writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasConfirmation) {
    [output appendFormat:@"%@%@ {\n", indent, @"confirmation"];
    [self.confirmation writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasReaction) {
    [output appendFormat:@"%@%@ {\n", indent, @"reaction"];
    [self.reaction writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasEphemeral) {
    [output appendFormat:@"%@%@ {\n", indent, @"ephemeral"];
    [self.ephemeral writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasAvailability) {
    [output appendFormat:@"%@%@ {\n", indent, @"availability"];
    [self.availability writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasComposite) {
    [output appendFormat:@"%@%@ {\n", indent, @"composite"];
    [self.composite writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasButtonAction) {
    [output appendFormat:@"%@%@ {\n", indent, @"buttonAction"];
    [self.buttonAction writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasButtonActionConfirmation) {
    [output appendFormat:@"%@%@ {\n", indent, @"buttonActionConfirmation"];
    [self.buttonActionConfirmation writeDescriptionTo:output
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
  if (self.hasHidden) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.hidden storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"hidden"];
  }
  if (self.hasLocation) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.location storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"location"];
  }
  if (self.hasDeleted) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.deleted storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"deleted"];
  }
  if (self.hasEdited) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.edited storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"edited"];
  }
  if (self.hasConfirmation) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.confirmation storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"confirmation"];
  }
  if (self.hasReaction) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.reaction storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"reaction"];
  }
  if (self.hasEphemeral) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.ephemeral storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"ephemeral"];
  }
  if (self.hasAvailability) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.availability storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"availability"];
  }
  if (self.hasComposite) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.composite storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"composite"];
  }
  if (self.hasButtonAction) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.buttonAction storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"buttonAction"];
  }
  if (self.hasButtonActionConfirmation) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.buttonActionConfirmation storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"buttonActionConfirmation"];
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
      self.hasHidden == otherMessage.hasHidden &&
      (!self.hasHidden || [self.hidden isEqual:otherMessage.hidden]) &&
      self.hasLocation == otherMessage.hasLocation &&
      (!self.hasLocation || [self.location isEqual:otherMessage.location]) &&
      self.hasDeleted == otherMessage.hasDeleted &&
      (!self.hasDeleted || [self.deleted isEqual:otherMessage.deleted]) &&
      self.hasEdited == otherMessage.hasEdited &&
      (!self.hasEdited || [self.edited isEqual:otherMessage.edited]) &&
      self.hasConfirmation == otherMessage.hasConfirmation &&
      (!self.hasConfirmation || [self.confirmation isEqual:otherMessage.confirmation]) &&
      self.hasReaction == otherMessage.hasReaction &&
      (!self.hasReaction || [self.reaction isEqual:otherMessage.reaction]) &&
      self.hasEphemeral == otherMessage.hasEphemeral &&
      (!self.hasEphemeral || [self.ephemeral isEqual:otherMessage.ephemeral]) &&
      self.hasAvailability == otherMessage.hasAvailability &&
      (!self.hasAvailability || [self.availability isEqual:otherMessage.availability]) &&
      self.hasComposite == otherMessage.hasComposite &&
      (!self.hasComposite || [self.composite isEqual:otherMessage.composite]) &&
      self.hasButtonAction == otherMessage.hasButtonAction &&
      (!self.hasButtonAction || [self.buttonAction isEqual:otherMessage.buttonAction]) &&
      self.hasButtonActionConfirmation == otherMessage.hasButtonActionConfirmation &&
      (!self.hasButtonActionConfirmation || [self.buttonActionConfirmation isEqual:otherMessage.buttonActionConfirmation]) &&
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
  if (self.hasHidden) {
    hashCode = hashCode * 31 + [self.hidden hash];
  }
  if (self.hasLocation) {
    hashCode = hashCode * 31 + [self.location hash];
  }
  if (self.hasDeleted) {
    hashCode = hashCode * 31 + [self.deleted hash];
  }
  if (self.hasEdited) {
    hashCode = hashCode * 31 + [self.edited hash];
  }
  if (self.hasConfirmation) {
    hashCode = hashCode * 31 + [self.confirmation hash];
  }
  if (self.hasReaction) {
    hashCode = hashCode * 31 + [self.reaction hash];
  }
  if (self.hasEphemeral) {
    hashCode = hashCode * 31 + [self.ephemeral hash];
  }
  if (self.hasAvailability) {
    hashCode = hashCode * 31 + [self.availability hash];
  }
  if (self.hasComposite) {
    hashCode = hashCode * 31 + [self.composite hash];
  }
  if (self.hasButtonAction) {
    hashCode = hashCode * 31 + [self.buttonAction hash];
  }
  if (self.hasButtonActionConfirmation) {
    hashCode = hashCode * 31 + [self.buttonActionConfirmation hash];
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
  if (other.hasHidden) {
    [self mergeHidden:other.hidden];
  }
  if (other.hasLocation) {
    [self mergeLocation:other.location];
  }
  if (other.hasDeleted) {
    [self mergeDeleted:other.deleted];
  }
  if (other.hasEdited) {
    [self mergeEdited:other.edited];
  }
  if (other.hasConfirmation) {
    [self mergeConfirmation:other.confirmation];
  }
  if (other.hasReaction) {
    [self mergeReaction:other.reaction];
  }
  if (other.hasEphemeral) {
    [self mergeEphemeral:other.ephemeral];
  }
  if (other.hasAvailability) {
    [self mergeAvailability:other.availability];
  }
  if (other.hasComposite) {
    [self mergeComposite:other.composite];
  }
  if (other.hasButtonAction) {
    [self mergeButtonAction:other.buttonAction];
  }
  if (other.hasButtonActionConfirmation) {
    [self mergeButtonActionConfirmation:other.buttonActionConfirmation];
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
        ZMMessageHideBuilder* subBuilder = [ZMMessageHide builder];
        if (self.hasHidden) {
          [subBuilder mergeFrom:self.hidden];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setHidden:[subBuilder buildPartial]];
        break;
      }
      case 106: {
        ZMLocationBuilder* subBuilder = [ZMLocation builder];
        if (self.hasLocation) {
          [subBuilder mergeFrom:self.location];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setLocation:[subBuilder buildPartial]];
        break;
      }
      case 114: {
        ZMMessageDeleteBuilder* subBuilder = [ZMMessageDelete builder];
        if (self.hasDeleted) {
          [subBuilder mergeFrom:self.deleted];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setDeleted:[subBuilder buildPartial]];
        break;
      }
      case 122: {
        ZMMessageEditBuilder* subBuilder = [ZMMessageEdit builder];
        if (self.hasEdited) {
          [subBuilder mergeFrom:self.edited];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setEdited:[subBuilder buildPartial]];
        break;
      }
      case 130: {
        ZMConfirmationBuilder* subBuilder = [ZMConfirmation builder];
        if (self.hasConfirmation) {
          [subBuilder mergeFrom:self.confirmation];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setConfirmation:[subBuilder buildPartial]];
        break;
      }
      case 138: {
        ZMReactionBuilder* subBuilder = [ZMReaction builder];
        if (self.hasReaction) {
          [subBuilder mergeFrom:self.reaction];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setReaction:[subBuilder buildPartial]];
        break;
      }
      case 146: {
        ZMEphemeralBuilder* subBuilder = [ZMEphemeral builder];
        if (self.hasEphemeral) {
          [subBuilder mergeFrom:self.ephemeral];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setEphemeral:[subBuilder buildPartial]];
        break;
      }
      case 154: {
        ZMAvailabilityBuilder* subBuilder = [ZMAvailability builder];
        if (self.hasAvailability) {
          [subBuilder mergeFrom:self.availability];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setAvailability:[subBuilder buildPartial]];
        break;
      }
      case 162: {
        ZMCompositeBuilder* subBuilder = [ZMComposite builder];
        if (self.hasComposite) {
          [subBuilder mergeFrom:self.composite];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setComposite:[subBuilder buildPartial]];
        break;
      }
      case 170: {
        ZMButtonActionBuilder* subBuilder = [ZMButtonAction builder];
        if (self.hasButtonAction) {
          [subBuilder mergeFrom:self.buttonAction];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setButtonAction:[subBuilder buildPartial]];
        break;
      }
      case 178: {
        ZMButtonActionConfirmationBuilder* subBuilder = [ZMButtonActionConfirmation builder];
        if (self.hasButtonActionConfirmation) {
          [subBuilder mergeFrom:self.buttonActionConfirmation];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setButtonActionConfirmation:[subBuilder buildPartial]];
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
- (BOOL) hasHidden {
  return resultGenericMessage.hasHidden;
}
- (ZMMessageHide*) hidden {
  return resultGenericMessage.hidden;
}
- (ZMGenericMessageBuilder*) setHidden:(ZMMessageHide*) value {
  resultGenericMessage.hasHidden = YES;
  resultGenericMessage.hidden = value;
  return self;
}
- (ZMGenericMessageBuilder*) setHiddenBuilder:(ZMMessageHideBuilder*) builderForValue {
  return [self setHidden:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeHidden:(ZMMessageHide*) value {
  if (resultGenericMessage.hasHidden &&
      resultGenericMessage.hidden != [ZMMessageHide defaultInstance]) {
    resultGenericMessage.hidden =
      [[[ZMMessageHide builderWithPrototype:resultGenericMessage.hidden] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.hidden = value;
  }
  resultGenericMessage.hasHidden = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearHidden {
  resultGenericMessage.hasHidden = NO;
  resultGenericMessage.hidden = [ZMMessageHide defaultInstance];
  return self;
}
- (BOOL) hasLocation {
  return resultGenericMessage.hasLocation;
}
- (ZMLocation*) location {
  return resultGenericMessage.location;
}
- (ZMGenericMessageBuilder*) setLocation:(ZMLocation*) value {
  resultGenericMessage.hasLocation = YES;
  resultGenericMessage.location = value;
  return self;
}
- (ZMGenericMessageBuilder*) setLocationBuilder:(ZMLocationBuilder*) builderForValue {
  return [self setLocation:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeLocation:(ZMLocation*) value {
  if (resultGenericMessage.hasLocation &&
      resultGenericMessage.location != [ZMLocation defaultInstance]) {
    resultGenericMessage.location =
      [[[ZMLocation builderWithPrototype:resultGenericMessage.location] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.location = value;
  }
  resultGenericMessage.hasLocation = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearLocation {
  resultGenericMessage.hasLocation = NO;
  resultGenericMessage.location = [ZMLocation defaultInstance];
  return self;
}
- (BOOL) hasDeleted {
  return resultGenericMessage.hasDeleted;
}
- (ZMMessageDelete*) deleted {
  return resultGenericMessage.deleted;
}
- (ZMGenericMessageBuilder*) setDeleted:(ZMMessageDelete*) value {
  resultGenericMessage.hasDeleted = YES;
  resultGenericMessage.deleted = value;
  return self;
}
- (ZMGenericMessageBuilder*) setDeletedBuilder:(ZMMessageDeleteBuilder*) builderForValue {
  return [self setDeleted:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeDeleted:(ZMMessageDelete*) value {
  if (resultGenericMessage.hasDeleted &&
      resultGenericMessage.deleted != [ZMMessageDelete defaultInstance]) {
    resultGenericMessage.deleted =
      [[[ZMMessageDelete builderWithPrototype:resultGenericMessage.deleted] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.deleted = value;
  }
  resultGenericMessage.hasDeleted = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearDeleted {
  resultGenericMessage.hasDeleted = NO;
  resultGenericMessage.deleted = [ZMMessageDelete defaultInstance];
  return self;
}
- (BOOL) hasEdited {
  return resultGenericMessage.hasEdited;
}
- (ZMMessageEdit*) edited {
  return resultGenericMessage.edited;
}
- (ZMGenericMessageBuilder*) setEdited:(ZMMessageEdit*) value {
  resultGenericMessage.hasEdited = YES;
  resultGenericMessage.edited = value;
  return self;
}
- (ZMGenericMessageBuilder*) setEditedBuilder:(ZMMessageEditBuilder*) builderForValue {
  return [self setEdited:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeEdited:(ZMMessageEdit*) value {
  if (resultGenericMessage.hasEdited &&
      resultGenericMessage.edited != [ZMMessageEdit defaultInstance]) {
    resultGenericMessage.edited =
      [[[ZMMessageEdit builderWithPrototype:resultGenericMessage.edited] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.edited = value;
  }
  resultGenericMessage.hasEdited = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearEdited {
  resultGenericMessage.hasEdited = NO;
  resultGenericMessage.edited = [ZMMessageEdit defaultInstance];
  return self;
}
- (BOOL) hasConfirmation {
  return resultGenericMessage.hasConfirmation;
}
- (ZMConfirmation*) confirmation {
  return resultGenericMessage.confirmation;
}
- (ZMGenericMessageBuilder*) setConfirmation:(ZMConfirmation*) value {
  resultGenericMessage.hasConfirmation = YES;
  resultGenericMessage.confirmation = value;
  return self;
}
- (ZMGenericMessageBuilder*) setConfirmationBuilder:(ZMConfirmationBuilder*) builderForValue {
  return [self setConfirmation:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeConfirmation:(ZMConfirmation*) value {
  if (resultGenericMessage.hasConfirmation &&
      resultGenericMessage.confirmation != [ZMConfirmation defaultInstance]) {
    resultGenericMessage.confirmation =
      [[[ZMConfirmation builderWithPrototype:resultGenericMessage.confirmation] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.confirmation = value;
  }
  resultGenericMessage.hasConfirmation = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearConfirmation {
  resultGenericMessage.hasConfirmation = NO;
  resultGenericMessage.confirmation = [ZMConfirmation defaultInstance];
  return self;
}
- (BOOL) hasReaction {
  return resultGenericMessage.hasReaction;
}
- (ZMReaction*) reaction {
  return resultGenericMessage.reaction;
}
- (ZMGenericMessageBuilder*) setReaction:(ZMReaction*) value {
  resultGenericMessage.hasReaction = YES;
  resultGenericMessage.reaction = value;
  return self;
}
- (ZMGenericMessageBuilder*) setReactionBuilder:(ZMReactionBuilder*) builderForValue {
  return [self setReaction:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeReaction:(ZMReaction*) value {
  if (resultGenericMessage.hasReaction &&
      resultGenericMessage.reaction != [ZMReaction defaultInstance]) {
    resultGenericMessage.reaction =
      [[[ZMReaction builderWithPrototype:resultGenericMessage.reaction] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.reaction = value;
  }
  resultGenericMessage.hasReaction = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearReaction {
  resultGenericMessage.hasReaction = NO;
  resultGenericMessage.reaction = [ZMReaction defaultInstance];
  return self;
}
- (BOOL) hasEphemeral {
  return resultGenericMessage.hasEphemeral;
}
- (ZMEphemeral*) ephemeral {
  return resultGenericMessage.ephemeral;
}
- (ZMGenericMessageBuilder*) setEphemeral:(ZMEphemeral*) value {
  resultGenericMessage.hasEphemeral = YES;
  resultGenericMessage.ephemeral = value;
  return self;
}
- (ZMGenericMessageBuilder*) setEphemeralBuilder:(ZMEphemeralBuilder*) builderForValue {
  return [self setEphemeral:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeEphemeral:(ZMEphemeral*) value {
  if (resultGenericMessage.hasEphemeral &&
      resultGenericMessage.ephemeral != [ZMEphemeral defaultInstance]) {
    resultGenericMessage.ephemeral =
      [[[ZMEphemeral builderWithPrototype:resultGenericMessage.ephemeral] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.ephemeral = value;
  }
  resultGenericMessage.hasEphemeral = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearEphemeral {
  resultGenericMessage.hasEphemeral = NO;
  resultGenericMessage.ephemeral = [ZMEphemeral defaultInstance];
  return self;
}
- (BOOL) hasAvailability {
  return resultGenericMessage.hasAvailability;
}
- (ZMAvailability*) availability {
  return resultGenericMessage.availability;
}
- (ZMGenericMessageBuilder*) setAvailability:(ZMAvailability*) value {
  resultGenericMessage.hasAvailability = YES;
  resultGenericMessage.availability = value;
  return self;
}
- (ZMGenericMessageBuilder*) setAvailabilityBuilder:(ZMAvailabilityBuilder*) builderForValue {
  return [self setAvailability:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeAvailability:(ZMAvailability*) value {
  if (resultGenericMessage.hasAvailability &&
      resultGenericMessage.availability != [ZMAvailability defaultInstance]) {
    resultGenericMessage.availability =
      [[[ZMAvailability builderWithPrototype:resultGenericMessage.availability] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.availability = value;
  }
  resultGenericMessage.hasAvailability = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearAvailability {
  resultGenericMessage.hasAvailability = NO;
  resultGenericMessage.availability = [ZMAvailability defaultInstance];
  return self;
}
- (BOOL) hasComposite {
  return resultGenericMessage.hasComposite;
}
- (ZMComposite*) composite {
  return resultGenericMessage.composite;
}
- (ZMGenericMessageBuilder*) setComposite:(ZMComposite*) value {
  resultGenericMessage.hasComposite = YES;
  resultGenericMessage.composite = value;
  return self;
}
- (ZMGenericMessageBuilder*) setCompositeBuilder:(ZMCompositeBuilder*) builderForValue {
  return [self setComposite:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeComposite:(ZMComposite*) value {
  if (resultGenericMessage.hasComposite &&
      resultGenericMessage.composite != [ZMComposite defaultInstance]) {
    resultGenericMessage.composite =
      [[[ZMComposite builderWithPrototype:resultGenericMessage.composite] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.composite = value;
  }
  resultGenericMessage.hasComposite = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearComposite {
  resultGenericMessage.hasComposite = NO;
  resultGenericMessage.composite = [ZMComposite defaultInstance];
  return self;
}
- (BOOL) hasButtonAction {
  return resultGenericMessage.hasButtonAction;
}
- (ZMButtonAction*) buttonAction {
  return resultGenericMessage.buttonAction;
}
- (ZMGenericMessageBuilder*) setButtonAction:(ZMButtonAction*) value {
  resultGenericMessage.hasButtonAction = YES;
  resultGenericMessage.buttonAction = value;
  return self;
}
- (ZMGenericMessageBuilder*) setButtonActionBuilder:(ZMButtonActionBuilder*) builderForValue {
  return [self setButtonAction:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeButtonAction:(ZMButtonAction*) value {
  if (resultGenericMessage.hasButtonAction &&
      resultGenericMessage.buttonAction != [ZMButtonAction defaultInstance]) {
    resultGenericMessage.buttonAction =
      [[[ZMButtonAction builderWithPrototype:resultGenericMessage.buttonAction] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.buttonAction = value;
  }
  resultGenericMessage.hasButtonAction = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearButtonAction {
  resultGenericMessage.hasButtonAction = NO;
  resultGenericMessage.buttonAction = [ZMButtonAction defaultInstance];
  return self;
}
- (BOOL) hasButtonActionConfirmation {
  return resultGenericMessage.hasButtonActionConfirmation;
}
- (ZMButtonActionConfirmation*) buttonActionConfirmation {
  return resultGenericMessage.buttonActionConfirmation;
}
- (ZMGenericMessageBuilder*) setButtonActionConfirmation:(ZMButtonActionConfirmation*) value {
  resultGenericMessage.hasButtonActionConfirmation = YES;
  resultGenericMessage.buttonActionConfirmation = value;
  return self;
}
- (ZMGenericMessageBuilder*) setButtonActionConfirmationBuilder:(ZMButtonActionConfirmationBuilder*) builderForValue {
  return [self setButtonActionConfirmation:[builderForValue build]];
}
- (ZMGenericMessageBuilder*) mergeButtonActionConfirmation:(ZMButtonActionConfirmation*) value {
  if (resultGenericMessage.hasButtonActionConfirmation &&
      resultGenericMessage.buttonActionConfirmation != [ZMButtonActionConfirmation defaultInstance]) {
    resultGenericMessage.buttonActionConfirmation =
      [[[ZMButtonActionConfirmation builderWithPrototype:resultGenericMessage.buttonActionConfirmation] mergeFrom:value] buildPartial];
  } else {
    resultGenericMessage.buttonActionConfirmation = value;
  }
  resultGenericMessage.hasButtonActionConfirmation = YES;
  return self;
}
- (ZMGenericMessageBuilder*) clearButtonActionConfirmation {
  resultGenericMessage.hasButtonActionConfirmation = NO;
  resultGenericMessage.buttonActionConfirmation = [ZMButtonActionConfirmation defaultInstance];
  return self;
}
@end

@interface ZMComposite ()
@property (strong) NSMutableArray<ZMCompositeItem*> * itemsArray;
@property BOOL expectsReadConfirmation;
@property ZMLegalHoldStatus legalHoldStatus;
@end

@implementation ZMComposite

@synthesize itemsArray;
@dynamic items;
- (BOOL) hasExpectsReadConfirmation {
  return !!hasExpectsReadConfirmation_;
}
- (void) setHasExpectsReadConfirmation:(BOOL) _value_ {
  hasExpectsReadConfirmation_ = !!_value_;
}
- (BOOL) expectsReadConfirmation {
  return !!expectsReadConfirmation_;
}
- (void) setExpectsReadConfirmation:(BOOL) _value_ {
  expectsReadConfirmation_ = !!_value_;
}
- (BOOL) hasLegalHoldStatus {
  return !!hasLegalHoldStatus_;
}
- (void) setHasLegalHoldStatus:(BOOL) _value_ {
  hasLegalHoldStatus_ = !!_value_;
}
@synthesize legalHoldStatus;
- (instancetype) init {
  if ((self = [super init])) {
    self.expectsReadConfirmation = NO;
    self.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
  }
  return self;
}
static ZMComposite* defaultZMCompositeInstance = nil;
+ (void) initialize {
  if (self == [ZMComposite class]) {
    defaultZMCompositeInstance = [[ZMComposite alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMCompositeInstance;
}
- (instancetype) defaultInstance {
  return defaultZMCompositeInstance;
}
- (NSArray<ZMCompositeItem*> *)items {
  return itemsArray;
}
- (ZMCompositeItem*)itemsAtIndex:(NSUInteger)index {
  return [itemsArray objectAtIndex:index];
}
- (BOOL) isInitialized {
  __block BOOL isInititems = YES;
   [self.items enumerateObjectsUsingBlock:^(ZMCompositeItem *element, NSUInteger idx, BOOL *stop) {
    if (!element.isInitialized) {
      isInititems = NO;
      *stop = YES;
    }
  }];
  if (!isInititems) return isInititems;
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  [self.itemsArray enumerateObjectsUsingBlock:^(ZMCompositeItem *element, NSUInteger idx, BOOL *stop) {
    [output writeMessage:1 value:element];
  }];
  if (self.hasExpectsReadConfirmation) {
    [output writeBool:2 value:self.expectsReadConfirmation];
  }
  if (self.hasLegalHoldStatus) {
    [output writeEnum:3 value:self.legalHoldStatus];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  [self.itemsArray enumerateObjectsUsingBlock:^(ZMCompositeItem *element, NSUInteger idx, BOOL *stop) {
    size_ += computeMessageSize(1, element);
  }];
  if (self.hasExpectsReadConfirmation) {
    size_ += computeBoolSize(2, self.expectsReadConfirmation);
  }
  if (self.hasLegalHoldStatus) {
    size_ += computeEnumSize(3, self.legalHoldStatus);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMComposite*) parseFromData:(NSData*) data {
  return (ZMComposite*)[[[ZMComposite builder] mergeFromData:data] build];
}
+ (ZMComposite*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMComposite*)[[[ZMComposite builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMComposite*) parseFromInputStream:(NSInputStream*) input {
  return (ZMComposite*)[[[ZMComposite builder] mergeFromInputStream:input] build];
}
+ (ZMComposite*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMComposite*)[[[ZMComposite builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMComposite*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMComposite*)[[[ZMComposite builder] mergeFromCodedInputStream:input] build];
}
+ (ZMComposite*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMComposite*)[[[ZMComposite builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMCompositeBuilder*) builder {
  return [[ZMCompositeBuilder alloc] init];
}
+ (ZMCompositeBuilder*) builderWithPrototype:(ZMComposite*) prototype {
  return [[ZMComposite builder] mergeFrom:prototype];
}
- (ZMCompositeBuilder*) builder {
  return [ZMComposite builder];
}
- (ZMCompositeBuilder*) toBuilder {
  return [ZMComposite builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  [self.itemsArray enumerateObjectsUsingBlock:^(ZMCompositeItem *element, NSUInteger idx, BOOL *stop) {
    [output appendFormat:@"%@%@ {\n", indent, @"items"];
    [element writeDescriptionTo:output
                     withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }];
  if (self.hasExpectsReadConfirmation) {
    [output appendFormat:@"%@%@: %@\n", indent, @"expectsReadConfirmation", [NSNumber numberWithBool:self.expectsReadConfirmation]];
  }
  if (self.hasLegalHoldStatus) {
    [output appendFormat:@"%@%@: %@\n", indent, @"legalHoldStatus", NSStringFromZMLegalHoldStatus(self.legalHoldStatus)];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  for (ZMCompositeItem* element in self.itemsArray) {
    NSMutableDictionary *elementDictionary = [NSMutableDictionary dictionary];
    [element storeInDictionary:elementDictionary];
    [dictionary setObject:[NSDictionary dictionaryWithDictionary:elementDictionary] forKey:@"items"];
  }
  if (self.hasExpectsReadConfirmation) {
    [dictionary setObject: [NSNumber numberWithBool:self.expectsReadConfirmation] forKey: @"expectsReadConfirmation"];
  }
  if (self.hasLegalHoldStatus) {
    [dictionary setObject: @(self.legalHoldStatus) forKey: @"legalHoldStatus"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMComposite class]]) {
    return NO;
  }
  ZMComposite *otherMessage = other;
  return
      [self.itemsArray isEqualToArray:otherMessage.itemsArray] &&
      self.hasExpectsReadConfirmation == otherMessage.hasExpectsReadConfirmation &&
      (!self.hasExpectsReadConfirmation || self.expectsReadConfirmation == otherMessage.expectsReadConfirmation) &&
      self.hasLegalHoldStatus == otherMessage.hasLegalHoldStatus &&
      (!self.hasLegalHoldStatus || self.legalHoldStatus == otherMessage.legalHoldStatus) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  [self.itemsArray enumerateObjectsUsingBlock:^(ZMCompositeItem *element, NSUInteger idx, BOOL *stop) {
    hashCode = hashCode * 31 + [element hash];
  }];
  if (self.hasExpectsReadConfirmation) {
    hashCode = hashCode * 31 + [[NSNumber numberWithBool:self.expectsReadConfirmation] hash];
  }
  if (self.hasLegalHoldStatus) {
    hashCode = hashCode * 31 + self.legalHoldStatus;
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMCompositeItem ()
@property (strong) ZMText* text;
@property (strong) ZMButton* button;
@end

@implementation ZMCompositeItem

- (BOOL) hasText {
  return !!hasText_;
}
- (void) setHasText:(BOOL) _value_ {
  hasText_ = !!_value_;
}
@synthesize text;
- (BOOL) hasButton {
  return !!hasButton_;
}
- (void) setHasButton:(BOOL) _value_ {
  hasButton_ = !!_value_;
}
@synthesize button;
- (instancetype) init {
  if ((self = [super init])) {
    self.text = [ZMText defaultInstance];
    self.button = [ZMButton defaultInstance];
  }
  return self;
}
static ZMCompositeItem* defaultZMCompositeItemInstance = nil;
+ (void) initialize {
  if (self == [ZMCompositeItem class]) {
    defaultZMCompositeItemInstance = [[ZMCompositeItem alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMCompositeItemInstance;
}
- (instancetype) defaultInstance {
  return defaultZMCompositeItemInstance;
}
- (BOOL) isInitialized {
  if (self.hasText) {
    if (!self.text.isInitialized) {
      return NO;
    }
  }
  if (self.hasButton) {
    if (!self.button.isInitialized) {
      return NO;
    }
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasText) {
    [output writeMessage:1 value:self.text];
  }
  if (self.hasButton) {
    [output writeMessage:2 value:self.button];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasText) {
    size_ += computeMessageSize(1, self.text);
  }
  if (self.hasButton) {
    size_ += computeMessageSize(2, self.button);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMCompositeItem*) parseFromData:(NSData*) data {
  return (ZMCompositeItem*)[[[ZMCompositeItem builder] mergeFromData:data] build];
}
+ (ZMCompositeItem*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMCompositeItem*)[[[ZMCompositeItem builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMCompositeItem*) parseFromInputStream:(NSInputStream*) input {
  return (ZMCompositeItem*)[[[ZMCompositeItem builder] mergeFromInputStream:input] build];
}
+ (ZMCompositeItem*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMCompositeItem*)[[[ZMCompositeItem builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMCompositeItem*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMCompositeItem*)[[[ZMCompositeItem builder] mergeFromCodedInputStream:input] build];
}
+ (ZMCompositeItem*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMCompositeItem*)[[[ZMCompositeItem builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMCompositeItemBuilder*) builder {
  return [[ZMCompositeItemBuilder alloc] init];
}
+ (ZMCompositeItemBuilder*) builderWithPrototype:(ZMCompositeItem*) prototype {
  return [[ZMCompositeItem builder] mergeFrom:prototype];
}
- (ZMCompositeItemBuilder*) builder {
  return [ZMCompositeItem builder];
}
- (ZMCompositeItemBuilder*) toBuilder {
  return [ZMCompositeItem builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasText) {
    [output appendFormat:@"%@%@ {\n", indent, @"text"];
    [self.text writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasButton) {
    [output appendFormat:@"%@%@ {\n", indent, @"button"];
    [self.button writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasText) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.text storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"text"];
  }
  if (self.hasButton) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.button storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"button"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMCompositeItem class]]) {
    return NO;
  }
  ZMCompositeItem *otherMessage = other;
  return
      self.hasText == otherMessage.hasText &&
      (!self.hasText || [self.text isEqual:otherMessage.text]) &&
      self.hasButton == otherMessage.hasButton &&
      (!self.hasButton || [self.button isEqual:otherMessage.button]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasText) {
    hashCode = hashCode * 31 + [self.text hash];
  }
  if (self.hasButton) {
    hashCode = hashCode * 31 + [self.button hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMCompositeItemBuilder()
@property (strong) ZMCompositeItem* resultItem;
@end

@implementation ZMCompositeItemBuilder
@synthesize resultItem;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultItem = [[ZMCompositeItem alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultItem;
}
- (ZMCompositeItemBuilder*) clear {
  self.resultItem = [[ZMCompositeItem alloc] init];
  return self;
}
- (ZMCompositeItemBuilder*) clone {
  return [ZMCompositeItem builderWithPrototype:resultItem];
}
- (ZMCompositeItem*) defaultInstance {
  return [ZMCompositeItem defaultInstance];
}
- (ZMCompositeItem*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMCompositeItem*) buildPartial {
  ZMCompositeItem* returnMe = resultItem;
  self.resultItem = nil;
  return returnMe;
}
- (ZMCompositeItemBuilder*) mergeFrom:(ZMCompositeItem*) other {
  if (other == [ZMCompositeItem defaultInstance]) {
    return self;
  }
  if (other.hasText) {
    [self mergeText:other.text];
  }
  if (other.hasButton) {
    [self mergeButton:other.button];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMCompositeItemBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMCompositeItemBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        ZMTextBuilder* subBuilder = [ZMText builder];
        if (self.hasText) {
          [subBuilder mergeFrom:self.text];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setText:[subBuilder buildPartial]];
        break;
      }
      case 18: {
        ZMButtonBuilder* subBuilder = [ZMButton builder];
        if (self.hasButton) {
          [subBuilder mergeFrom:self.button];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setButton:[subBuilder buildPartial]];
        break;
      }
    }
  }
}
- (BOOL) hasText {
  return resultItem.hasText;
}
- (ZMText*) text {
  return resultItem.text;
}
- (ZMCompositeItemBuilder*) setText:(ZMText*) value {
  resultItem.hasText = YES;
  resultItem.text = value;
  return self;
}
- (ZMCompositeItemBuilder*) setTextBuilder:(ZMTextBuilder*) builderForValue {
  return [self setText:[builderForValue build]];
}
- (ZMCompositeItemBuilder*) mergeText:(ZMText*) value {
  if (resultItem.hasText &&
      resultItem.text != [ZMText defaultInstance]) {
    resultItem.text =
      [[[ZMText builderWithPrototype:resultItem.text] mergeFrom:value] buildPartial];
  } else {
    resultItem.text = value;
  }
  resultItem.hasText = YES;
  return self;
}
- (ZMCompositeItemBuilder*) clearText {
  resultItem.hasText = NO;
  resultItem.text = [ZMText defaultInstance];
  return self;
}
- (BOOL) hasButton {
  return resultItem.hasButton;
}
- (ZMButton*) button {
  return resultItem.button;
}
- (ZMCompositeItemBuilder*) setButton:(ZMButton*) value {
  resultItem.hasButton = YES;
  resultItem.button = value;
  return self;
}
- (ZMCompositeItemBuilder*) setButtonBuilder:(ZMButtonBuilder*) builderForValue {
  return [self setButton:[builderForValue build]];
}
- (ZMCompositeItemBuilder*) mergeButton:(ZMButton*) value {
  if (resultItem.hasButton &&
      resultItem.button != [ZMButton defaultInstance]) {
    resultItem.button =
      [[[ZMButton builderWithPrototype:resultItem.button] mergeFrom:value] buildPartial];
  } else {
    resultItem.button = value;
  }
  resultItem.hasButton = YES;
  return self;
}
- (ZMCompositeItemBuilder*) clearButton {
  resultItem.hasButton = NO;
  resultItem.button = [ZMButton defaultInstance];
  return self;
}
@end

@interface ZMCompositeBuilder()
@property (strong) ZMComposite* resultComposite;
@end

@implementation ZMCompositeBuilder
@synthesize resultComposite;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultComposite = [[ZMComposite alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultComposite;
}
- (ZMCompositeBuilder*) clear {
  self.resultComposite = [[ZMComposite alloc] init];
  return self;
}
- (ZMCompositeBuilder*) clone {
  return [ZMComposite builderWithPrototype:resultComposite];
}
- (ZMComposite*) defaultInstance {
  return [ZMComposite defaultInstance];
}
- (ZMComposite*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMComposite*) buildPartial {
  ZMComposite* returnMe = resultComposite;
  self.resultComposite = nil;
  return returnMe;
}
- (ZMCompositeBuilder*) mergeFrom:(ZMComposite*) other {
  if (other == [ZMComposite defaultInstance]) {
    return self;
  }
  if (other.itemsArray.count > 0) {
    if (resultComposite.itemsArray == nil) {
      resultComposite.itemsArray = [[NSMutableArray alloc] initWithArray:other.itemsArray];
    } else {
      [resultComposite.itemsArray addObjectsFromArray:other.itemsArray];
    }
  }
  if (other.hasExpectsReadConfirmation) {
    [self setExpectsReadConfirmation:other.expectsReadConfirmation];
  }
  if (other.hasLegalHoldStatus) {
    [self setLegalHoldStatus:other.legalHoldStatus];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMCompositeBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMCompositeBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        ZMCompositeItemBuilder* subBuilder = [ZMCompositeItem builder];
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self addItems:[subBuilder buildPartial]];
        break;
      }
      case 16: {
        [self setExpectsReadConfirmation:[input readBool]];
        break;
      }
      case 24: {
        ZMLegalHoldStatus value = (ZMLegalHoldStatus)[input readEnum];
        if (ZMLegalHoldStatusIsValidValue(value)) {
          [self setLegalHoldStatus:value];
        } else {
          [unknownFields mergeVarintField:3 value:value];
        }
        break;
      }
    }
  }
}
- (NSMutableArray<ZMCompositeItem*> *)items {
  return resultComposite.itemsArray;
}
- (ZMCompositeItem*)itemsAtIndex:(NSUInteger)index {
  return [resultComposite itemsAtIndex:index];
}
- (ZMCompositeBuilder *)addItems:(ZMCompositeItem*)value {
  if (resultComposite.itemsArray == nil) {
    resultComposite.itemsArray = [[NSMutableArray alloc]init];
  }
  [resultComposite.itemsArray addObject:value];
  return self;
}
- (ZMCompositeBuilder *)setItemsArray:(NSArray<ZMCompositeItem*> *)array {
  resultComposite.itemsArray = [[NSMutableArray alloc]initWithArray:array];
  return self;
}
- (ZMCompositeBuilder *)clearItems {
  resultComposite.itemsArray = nil;
  return self;
}
- (BOOL) hasExpectsReadConfirmation {
  return resultComposite.hasExpectsReadConfirmation;
}
- (BOOL) expectsReadConfirmation {
  return resultComposite.expectsReadConfirmation;
}
- (ZMCompositeBuilder*) setExpectsReadConfirmation:(BOOL) value {
  resultComposite.hasExpectsReadConfirmation = YES;
  resultComposite.expectsReadConfirmation = value;
  return self;
}
- (ZMCompositeBuilder*) clearExpectsReadConfirmation {
  resultComposite.hasExpectsReadConfirmation = NO;
  resultComposite.expectsReadConfirmation = NO;
  return self;
}
- (BOOL) hasLegalHoldStatus {
  return resultComposite.hasLegalHoldStatus;
}
- (ZMLegalHoldStatus) legalHoldStatus {
  return resultComposite.legalHoldStatus;
}
- (ZMCompositeBuilder*) setLegalHoldStatus:(ZMLegalHoldStatus) value {
  resultComposite.hasLegalHoldStatus = YES;
  resultComposite.legalHoldStatus = value;
  return self;
}
- (ZMCompositeBuilder*) clearLegalHoldStatus {
  resultComposite.hasLegalHoldStatus = NO;
  resultComposite.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
  return self;
}
@end

@interface ZMButton ()
@property (strong) NSString* text;
@property (strong) NSString* id;
@end

@implementation ZMButton

- (BOOL) hasText {
  return !!hasText_;
}
- (void) setHasText:(BOOL) _value_ {
  hasText_ = !!_value_;
}
@synthesize text;
- (BOOL) hasId {
  return !!hasId_;
}
- (void) setHasId:(BOOL) _value_ {
  hasId_ = !!_value_;
}
@synthesize id;
- (instancetype) init {
  if ((self = [super init])) {
    self.text = @"";
    self.id = @"";
  }
  return self;
}
static ZMButton* defaultZMButtonInstance = nil;
+ (void) initialize {
  if (self == [ZMButton class]) {
    defaultZMButtonInstance = [[ZMButton alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMButtonInstance;
}
- (instancetype) defaultInstance {
  return defaultZMButtonInstance;
}
- (BOOL) isInitialized {
  if (!self.hasText) {
    return NO;
  }
  if (!self.hasId) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasText) {
    [output writeString:1 value:self.text];
  }
  if (self.hasId) {
    [output writeString:2 value:self.id];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasText) {
    size_ += computeStringSize(1, self.text);
  }
  if (self.hasId) {
    size_ += computeStringSize(2, self.id);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMButton*) parseFromData:(NSData*) data {
  return (ZMButton*)[[[ZMButton builder] mergeFromData:data] build];
}
+ (ZMButton*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMButton*)[[[ZMButton builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMButton*) parseFromInputStream:(NSInputStream*) input {
  return (ZMButton*)[[[ZMButton builder] mergeFromInputStream:input] build];
}
+ (ZMButton*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMButton*)[[[ZMButton builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMButton*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMButton*)[[[ZMButton builder] mergeFromCodedInputStream:input] build];
}
+ (ZMButton*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMButton*)[[[ZMButton builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMButtonBuilder*) builder {
  return [[ZMButtonBuilder alloc] init];
}
+ (ZMButtonBuilder*) builderWithPrototype:(ZMButton*) prototype {
  return [[ZMButton builder] mergeFrom:prototype];
}
- (ZMButtonBuilder*) builder {
  return [ZMButton builder];
}
- (ZMButtonBuilder*) toBuilder {
  return [ZMButton builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasText) {
    [output appendFormat:@"%@%@: %@\n", indent, @"text", self.text];
  }
  if (self.hasId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"id", self.id];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasText) {
    [dictionary setObject: self.text forKey: @"text"];
  }
  if (self.hasId) {
    [dictionary setObject: self.id forKey: @"id"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMButton class]]) {
    return NO;
  }
  ZMButton *otherMessage = other;
  return
      self.hasText == otherMessage.hasText &&
      (!self.hasText || [self.text isEqual:otherMessage.text]) &&
      self.hasId == otherMessage.hasId &&
      (!self.hasId || [self.id isEqual:otherMessage.id]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasText) {
    hashCode = hashCode * 31 + [self.text hash];
  }
  if (self.hasId) {
    hashCode = hashCode * 31 + [self.id hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMButtonBuilder()
@property (strong) ZMButton* resultButton;
@end

@implementation ZMButtonBuilder
@synthesize resultButton;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultButton = [[ZMButton alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultButton;
}
- (ZMButtonBuilder*) clear {
  self.resultButton = [[ZMButton alloc] init];
  return self;
}
- (ZMButtonBuilder*) clone {
  return [ZMButton builderWithPrototype:resultButton];
}
- (ZMButton*) defaultInstance {
  return [ZMButton defaultInstance];
}
- (ZMButton*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMButton*) buildPartial {
  ZMButton* returnMe = resultButton;
  self.resultButton = nil;
  return returnMe;
}
- (ZMButtonBuilder*) mergeFrom:(ZMButton*) other {
  if (other == [ZMButton defaultInstance]) {
    return self;
  }
  if (other.hasText) {
    [self setText:other.text];
  }
  if (other.hasId) {
    [self setId:other.id];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMButtonBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMButtonBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setText:[input readString]];
        break;
      }
      case 18: {
        [self setId:[input readString]];
        break;
      }
    }
  }
}
- (BOOL) hasText {
  return resultButton.hasText;
}
- (NSString*) text {
  return resultButton.text;
}
- (ZMButtonBuilder*) setText:(NSString*) value {
  resultButton.hasText = YES;
  resultButton.text = value;
  return self;
}
- (ZMButtonBuilder*) clearText {
  resultButton.hasText = NO;
  resultButton.text = @"";
  return self;
}
- (BOOL) hasId {
  return resultButton.hasId;
}
- (NSString*) id {
  return resultButton.id;
}
- (ZMButtonBuilder*) setId:(NSString*) value {
  resultButton.hasId = YES;
  resultButton.id = value;
  return self;
}
- (ZMButtonBuilder*) clearId {
  resultButton.hasId = NO;
  resultButton.id = @"";
  return self;
}
@end

@interface ZMButtonAction ()
@property (strong) NSString* buttonId;
@property (strong) NSString* referenceMessageId;
@end

@implementation ZMButtonAction

- (BOOL) hasButtonId {
  return !!hasButtonId_;
}
- (void) setHasButtonId:(BOOL) _value_ {
  hasButtonId_ = !!_value_;
}
@synthesize buttonId;
- (BOOL) hasReferenceMessageId {
  return !!hasReferenceMessageId_;
}
- (void) setHasReferenceMessageId:(BOOL) _value_ {
  hasReferenceMessageId_ = !!_value_;
}
@synthesize referenceMessageId;
- (instancetype) init {
  if ((self = [super init])) {
    self.buttonId = @"";
    self.referenceMessageId = @"";
  }
  return self;
}
static ZMButtonAction* defaultZMButtonActionInstance = nil;
+ (void) initialize {
  if (self == [ZMButtonAction class]) {
    defaultZMButtonActionInstance = [[ZMButtonAction alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMButtonActionInstance;
}
- (instancetype) defaultInstance {
  return defaultZMButtonActionInstance;
}
- (BOOL) isInitialized {
  if (!self.hasButtonId) {
    return NO;
  }
  if (!self.hasReferenceMessageId) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasButtonId) {
    [output writeString:1 value:self.buttonId];
  }
  if (self.hasReferenceMessageId) {
    [output writeString:2 value:self.referenceMessageId];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasButtonId) {
    size_ += computeStringSize(1, self.buttonId);
  }
  if (self.hasReferenceMessageId) {
    size_ += computeStringSize(2, self.referenceMessageId);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMButtonAction*) parseFromData:(NSData*) data {
  return (ZMButtonAction*)[[[ZMButtonAction builder] mergeFromData:data] build];
}
+ (ZMButtonAction*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMButtonAction*)[[[ZMButtonAction builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMButtonAction*) parseFromInputStream:(NSInputStream*) input {
  return (ZMButtonAction*)[[[ZMButtonAction builder] mergeFromInputStream:input] build];
}
+ (ZMButtonAction*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMButtonAction*)[[[ZMButtonAction builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMButtonAction*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMButtonAction*)[[[ZMButtonAction builder] mergeFromCodedInputStream:input] build];
}
+ (ZMButtonAction*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMButtonAction*)[[[ZMButtonAction builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMButtonActionBuilder*) builder {
  return [[ZMButtonActionBuilder alloc] init];
}
+ (ZMButtonActionBuilder*) builderWithPrototype:(ZMButtonAction*) prototype {
  return [[ZMButtonAction builder] mergeFrom:prototype];
}
- (ZMButtonActionBuilder*) builder {
  return [ZMButtonAction builder];
}
- (ZMButtonActionBuilder*) toBuilder {
  return [ZMButtonAction builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasButtonId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"buttonId", self.buttonId];
  }
  if (self.hasReferenceMessageId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"referenceMessageId", self.referenceMessageId];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasButtonId) {
    [dictionary setObject: self.buttonId forKey: @"buttonId"];
  }
  if (self.hasReferenceMessageId) {
    [dictionary setObject: self.referenceMessageId forKey: @"referenceMessageId"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMButtonAction class]]) {
    return NO;
  }
  ZMButtonAction *otherMessage = other;
  return
      self.hasButtonId == otherMessage.hasButtonId &&
      (!self.hasButtonId || [self.buttonId isEqual:otherMessage.buttonId]) &&
      self.hasReferenceMessageId == otherMessage.hasReferenceMessageId &&
      (!self.hasReferenceMessageId || [self.referenceMessageId isEqual:otherMessage.referenceMessageId]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasButtonId) {
    hashCode = hashCode * 31 + [self.buttonId hash];
  }
  if (self.hasReferenceMessageId) {
    hashCode = hashCode * 31 + [self.referenceMessageId hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMButtonActionBuilder()
@property (strong) ZMButtonAction* resultButtonAction;
@end

@implementation ZMButtonActionBuilder
@synthesize resultButtonAction;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultButtonAction = [[ZMButtonAction alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultButtonAction;
}
- (ZMButtonActionBuilder*) clear {
  self.resultButtonAction = [[ZMButtonAction alloc] init];
  return self;
}
- (ZMButtonActionBuilder*) clone {
  return [ZMButtonAction builderWithPrototype:resultButtonAction];
}
- (ZMButtonAction*) defaultInstance {
  return [ZMButtonAction defaultInstance];
}
- (ZMButtonAction*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMButtonAction*) buildPartial {
  ZMButtonAction* returnMe = resultButtonAction;
  self.resultButtonAction = nil;
  return returnMe;
}
- (ZMButtonActionBuilder*) mergeFrom:(ZMButtonAction*) other {
  if (other == [ZMButtonAction defaultInstance]) {
    return self;
  }
  if (other.hasButtonId) {
    [self setButtonId:other.buttonId];
  }
  if (other.hasReferenceMessageId) {
    [self setReferenceMessageId:other.referenceMessageId];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMButtonActionBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMButtonActionBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setButtonId:[input readString]];
        break;
      }
      case 18: {
        [self setReferenceMessageId:[input readString]];
        break;
      }
    }
  }
}
- (BOOL) hasButtonId {
  return resultButtonAction.hasButtonId;
}
- (NSString*) buttonId {
  return resultButtonAction.buttonId;
}
- (ZMButtonActionBuilder*) setButtonId:(NSString*) value {
  resultButtonAction.hasButtonId = YES;
  resultButtonAction.buttonId = value;
  return self;
}
- (ZMButtonActionBuilder*) clearButtonId {
  resultButtonAction.hasButtonId = NO;
  resultButtonAction.buttonId = @"";
  return self;
}
- (BOOL) hasReferenceMessageId {
  return resultButtonAction.hasReferenceMessageId;
}
- (NSString*) referenceMessageId {
  return resultButtonAction.referenceMessageId;
}
- (ZMButtonActionBuilder*) setReferenceMessageId:(NSString*) value {
  resultButtonAction.hasReferenceMessageId = YES;
  resultButtonAction.referenceMessageId = value;
  return self;
}
- (ZMButtonActionBuilder*) clearReferenceMessageId {
  resultButtonAction.hasReferenceMessageId = NO;
  resultButtonAction.referenceMessageId = @"";
  return self;
}
@end

@interface ZMButtonActionConfirmation ()
@property (strong) NSString* referenceMessageId;
@property (strong) NSString* buttonId;
@end

@implementation ZMButtonActionConfirmation

- (BOOL) hasReferenceMessageId {
  return !!hasReferenceMessageId_;
}
- (void) setHasReferenceMessageId:(BOOL) _value_ {
  hasReferenceMessageId_ = !!_value_;
}
@synthesize referenceMessageId;
- (BOOL) hasButtonId {
  return !!hasButtonId_;
}
- (void) setHasButtonId:(BOOL) _value_ {
  hasButtonId_ = !!_value_;
}
@synthesize buttonId;
- (instancetype) init {
  if ((self = [super init])) {
    self.referenceMessageId = @"";
    self.buttonId = @"";
  }
  return self;
}
static ZMButtonActionConfirmation* defaultZMButtonActionConfirmationInstance = nil;
+ (void) initialize {
  if (self == [ZMButtonActionConfirmation class]) {
    defaultZMButtonActionConfirmationInstance = [[ZMButtonActionConfirmation alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMButtonActionConfirmationInstance;
}
- (instancetype) defaultInstance {
  return defaultZMButtonActionConfirmationInstance;
}
- (BOOL) isInitialized {
  if (!self.hasReferenceMessageId) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasReferenceMessageId) {
    [output writeString:1 value:self.referenceMessageId];
  }
  if (self.hasButtonId) {
    [output writeString:2 value:self.buttonId];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasReferenceMessageId) {
    size_ += computeStringSize(1, self.referenceMessageId);
  }
  if (self.hasButtonId) {
    size_ += computeStringSize(2, self.buttonId);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMButtonActionConfirmation*) parseFromData:(NSData*) data {
  return (ZMButtonActionConfirmation*)[[[ZMButtonActionConfirmation builder] mergeFromData:data] build];
}
+ (ZMButtonActionConfirmation*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMButtonActionConfirmation*)[[[ZMButtonActionConfirmation builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMButtonActionConfirmation*) parseFromInputStream:(NSInputStream*) input {
  return (ZMButtonActionConfirmation*)[[[ZMButtonActionConfirmation builder] mergeFromInputStream:input] build];
}
+ (ZMButtonActionConfirmation*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMButtonActionConfirmation*)[[[ZMButtonActionConfirmation builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMButtonActionConfirmation*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMButtonActionConfirmation*)[[[ZMButtonActionConfirmation builder] mergeFromCodedInputStream:input] build];
}
+ (ZMButtonActionConfirmation*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMButtonActionConfirmation*)[[[ZMButtonActionConfirmation builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMButtonActionConfirmationBuilder*) builder {
  return [[ZMButtonActionConfirmationBuilder alloc] init];
}
+ (ZMButtonActionConfirmationBuilder*) builderWithPrototype:(ZMButtonActionConfirmation*) prototype {
  return [[ZMButtonActionConfirmation builder] mergeFrom:prototype];
}
- (ZMButtonActionConfirmationBuilder*) builder {
  return [ZMButtonActionConfirmation builder];
}
- (ZMButtonActionConfirmationBuilder*) toBuilder {
  return [ZMButtonActionConfirmation builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasReferenceMessageId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"referenceMessageId", self.referenceMessageId];
  }
  if (self.hasButtonId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"buttonId", self.buttonId];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasReferenceMessageId) {
    [dictionary setObject: self.referenceMessageId forKey: @"referenceMessageId"];
  }
  if (self.hasButtonId) {
    [dictionary setObject: self.buttonId forKey: @"buttonId"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMButtonActionConfirmation class]]) {
    return NO;
  }
  ZMButtonActionConfirmation *otherMessage = other;
  return
      self.hasReferenceMessageId == otherMessage.hasReferenceMessageId &&
      (!self.hasReferenceMessageId || [self.referenceMessageId isEqual:otherMessage.referenceMessageId]) &&
      self.hasButtonId == otherMessage.hasButtonId &&
      (!self.hasButtonId || [self.buttonId isEqual:otherMessage.buttonId]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasReferenceMessageId) {
    hashCode = hashCode * 31 + [self.referenceMessageId hash];
  }
  if (self.hasButtonId) {
    hashCode = hashCode * 31 + [self.buttonId hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMButtonActionConfirmationBuilder()
@property (strong) ZMButtonActionConfirmation* resultButtonActionConfirmation;
@end

@implementation ZMButtonActionConfirmationBuilder
@synthesize resultButtonActionConfirmation;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultButtonActionConfirmation = [[ZMButtonActionConfirmation alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultButtonActionConfirmation;
}
- (ZMButtonActionConfirmationBuilder*) clear {
  self.resultButtonActionConfirmation = [[ZMButtonActionConfirmation alloc] init];
  return self;
}
- (ZMButtonActionConfirmationBuilder*) clone {
  return [ZMButtonActionConfirmation builderWithPrototype:resultButtonActionConfirmation];
}
- (ZMButtonActionConfirmation*) defaultInstance {
  return [ZMButtonActionConfirmation defaultInstance];
}
- (ZMButtonActionConfirmation*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMButtonActionConfirmation*) buildPartial {
  ZMButtonActionConfirmation* returnMe = resultButtonActionConfirmation;
  self.resultButtonActionConfirmation = nil;
  return returnMe;
}
- (ZMButtonActionConfirmationBuilder*) mergeFrom:(ZMButtonActionConfirmation*) other {
  if (other == [ZMButtonActionConfirmation defaultInstance]) {
    return self;
  }
  if (other.hasReferenceMessageId) {
    [self setReferenceMessageId:other.referenceMessageId];
  }
  if (other.hasButtonId) {
    [self setButtonId:other.buttonId];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMButtonActionConfirmationBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMButtonActionConfirmationBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setReferenceMessageId:[input readString]];
        break;
      }
      case 18: {
        [self setButtonId:[input readString]];
        break;
      }
    }
  }
}
- (BOOL) hasReferenceMessageId {
  return resultButtonActionConfirmation.hasReferenceMessageId;
}
- (NSString*) referenceMessageId {
  return resultButtonActionConfirmation.referenceMessageId;
}
- (ZMButtonActionConfirmationBuilder*) setReferenceMessageId:(NSString*) value {
  resultButtonActionConfirmation.hasReferenceMessageId = YES;
  resultButtonActionConfirmation.referenceMessageId = value;
  return self;
}
- (ZMButtonActionConfirmationBuilder*) clearReferenceMessageId {
  resultButtonActionConfirmation.hasReferenceMessageId = NO;
  resultButtonActionConfirmation.referenceMessageId = @"";
  return self;
}
- (BOOL) hasButtonId {
  return resultButtonActionConfirmation.hasButtonId;
}
- (NSString*) buttonId {
  return resultButtonActionConfirmation.buttonId;
}
- (ZMButtonActionConfirmationBuilder*) setButtonId:(NSString*) value {
  resultButtonActionConfirmation.hasButtonId = YES;
  resultButtonActionConfirmation.buttonId = value;
  return self;
}
- (ZMButtonActionConfirmationBuilder*) clearButtonId {
  resultButtonActionConfirmation.hasButtonId = NO;
  resultButtonActionConfirmation.buttonId = @"";
  return self;
}
@end

@interface ZMAvailability ()
@property ZMAvailabilityType type;
@end

@implementation ZMAvailability

- (BOOL) hasType {
  return !!hasType_;
}
- (void) setHasType:(BOOL) _value_ {
  hasType_ = !!_value_;
}
@synthesize type;
- (instancetype) init {
  if ((self = [super init])) {
    self.type = ZMAvailabilityTypeNONE;
  }
  return self;
}
static ZMAvailability* defaultZMAvailabilityInstance = nil;
+ (void) initialize {
  if (self == [ZMAvailability class]) {
    defaultZMAvailabilityInstance = [[ZMAvailability alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMAvailabilityInstance;
}
- (instancetype) defaultInstance {
  return defaultZMAvailabilityInstance;
}
- (BOOL) isInitialized {
  if (!self.hasType) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasType) {
    [output writeEnum:1 value:self.type];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasType) {
    size_ += computeEnumSize(1, self.type);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMAvailability*) parseFromData:(NSData*) data {
  return (ZMAvailability*)[[[ZMAvailability builder] mergeFromData:data] build];
}
+ (ZMAvailability*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAvailability*)[[[ZMAvailability builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMAvailability*) parseFromInputStream:(NSInputStream*) input {
  return (ZMAvailability*)[[[ZMAvailability builder] mergeFromInputStream:input] build];
}
+ (ZMAvailability*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAvailability*)[[[ZMAvailability builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAvailability*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMAvailability*)[[[ZMAvailability builder] mergeFromCodedInputStream:input] build];
}
+ (ZMAvailability*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAvailability*)[[[ZMAvailability builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAvailabilityBuilder*) builder {
  return [[ZMAvailabilityBuilder alloc] init];
}
+ (ZMAvailabilityBuilder*) builderWithPrototype:(ZMAvailability*) prototype {
  return [[ZMAvailability builder] mergeFrom:prototype];
}
- (ZMAvailabilityBuilder*) builder {
  return [ZMAvailability builder];
}
- (ZMAvailabilityBuilder*) toBuilder {
  return [ZMAvailability builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasType) {
    [output appendFormat:@"%@%@: %@\n", indent, @"type", NSStringFromZMAvailabilityType(self.type)];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasType) {
    [dictionary setObject: @(self.type) forKey: @"type"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMAvailability class]]) {
    return NO;
  }
  ZMAvailability *otherMessage = other;
  return
      self.hasType == otherMessage.hasType &&
      (!self.hasType || self.type == otherMessage.type) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasType) {
    hashCode = hashCode * 31 + self.type;
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

BOOL ZMAvailabilityTypeIsValidValue(ZMAvailabilityType value) {
  switch (value) {
    case ZMAvailabilityTypeNONE:
    case ZMAvailabilityTypeAVAILABLE:
    case ZMAvailabilityTypeAWAY:
    case ZMAvailabilityTypeBUSY:
      return YES;
    default:
      return NO;
  }
}
NSString *NSStringFromZMAvailabilityType(ZMAvailabilityType value) {
  switch (value) {
    case ZMAvailabilityTypeNONE:
      return @"ZMAvailabilityTypeNONE";
    case ZMAvailabilityTypeAVAILABLE:
      return @"ZMAvailabilityTypeAVAILABLE";
    case ZMAvailabilityTypeAWAY:
      return @"ZMAvailabilityTypeAWAY";
    case ZMAvailabilityTypeBUSY:
      return @"ZMAvailabilityTypeBUSY";
    default:
      return nil;
  }
}

@interface ZMAvailabilityBuilder()
@property (strong) ZMAvailability* resultAvailability;
@end

@implementation ZMAvailabilityBuilder
@synthesize resultAvailability;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultAvailability = [[ZMAvailability alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultAvailability;
}
- (ZMAvailabilityBuilder*) clear {
  self.resultAvailability = [[ZMAvailability alloc] init];
  return self;
}
- (ZMAvailabilityBuilder*) clone {
  return [ZMAvailability builderWithPrototype:resultAvailability];
}
- (ZMAvailability*) defaultInstance {
  return [ZMAvailability defaultInstance];
}
- (ZMAvailability*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMAvailability*) buildPartial {
  ZMAvailability* returnMe = resultAvailability;
  self.resultAvailability = nil;
  return returnMe;
}
- (ZMAvailabilityBuilder*) mergeFrom:(ZMAvailability*) other {
  if (other == [ZMAvailability defaultInstance]) {
    return self;
  }
  if (other.hasType) {
    [self setType:other.type];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMAvailabilityBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMAvailabilityBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        ZMAvailabilityType value = (ZMAvailabilityType)[input readEnum];
        if (ZMAvailabilityTypeIsValidValue(value)) {
          [self setType:value];
        } else {
          [unknownFields mergeVarintField:1 value:value];
        }
        break;
      }
    }
  }
}
- (BOOL) hasType {
  return resultAvailability.hasType;
}
- (ZMAvailabilityType) type {
  return resultAvailability.type;
}
- (ZMAvailabilityBuilder*) setType:(ZMAvailabilityType) value {
  resultAvailability.hasType = YES;
  resultAvailability.type = value;
  return self;
}
- (ZMAvailabilityBuilder*) clearType {
  resultAvailability.hasType = NO;
  resultAvailability.type = ZMAvailabilityTypeNONE;
  return self;
}
@end

@interface ZMEphemeral ()
@property SInt64 expireAfterMillis;
@property (strong) ZMText* text;
@property (strong) ZMImageAsset* image;
@property (strong) ZMKnock* knock;
@property (strong) ZMAsset* asset;
@property (strong) ZMLocation* location;
@end

@implementation ZMEphemeral

- (BOOL) hasExpireAfterMillis {
  return !!hasExpireAfterMillis_;
}
- (void) setHasExpireAfterMillis:(BOOL) _value_ {
  hasExpireAfterMillis_ = !!_value_;
}
@synthesize expireAfterMillis;
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
- (BOOL) hasAsset {
  return !!hasAsset_;
}
- (void) setHasAsset:(BOOL) _value_ {
  hasAsset_ = !!_value_;
}
@synthesize asset;
- (BOOL) hasLocation {
  return !!hasLocation_;
}
- (void) setHasLocation:(BOOL) _value_ {
  hasLocation_ = !!_value_;
}
@synthesize location;
- (instancetype) init {
  if ((self = [super init])) {
    self.expireAfterMillis = 0L;
    self.text = [ZMText defaultInstance];
    self.image = [ZMImageAsset defaultInstance];
    self.knock = [ZMKnock defaultInstance];
    self.asset = [ZMAsset defaultInstance];
    self.location = [ZMLocation defaultInstance];
  }
  return self;
}
static ZMEphemeral* defaultZMEphemeralInstance = nil;
+ (void) initialize {
  if (self == [ZMEphemeral class]) {
    defaultZMEphemeralInstance = [[ZMEphemeral alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMEphemeralInstance;
}
- (instancetype) defaultInstance {
  return defaultZMEphemeralInstance;
}
- (BOOL) isInitialized {
  if (!self.hasExpireAfterMillis) {
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
  if (self.hasAsset) {
    if (!self.asset.isInitialized) {
      return NO;
    }
  }
  if (self.hasLocation) {
    if (!self.location.isInitialized) {
      return NO;
    }
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasExpireAfterMillis) {
    [output writeInt64:1 value:self.expireAfterMillis];
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
  if (self.hasAsset) {
    [output writeMessage:5 value:self.asset];
  }
  if (self.hasLocation) {
    [output writeMessage:6 value:self.location];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasExpireAfterMillis) {
    size_ += computeInt64Size(1, self.expireAfterMillis);
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
  if (self.hasAsset) {
    size_ += computeMessageSize(5, self.asset);
  }
  if (self.hasLocation) {
    size_ += computeMessageSize(6, self.location);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMEphemeral*) parseFromData:(NSData*) data {
  return (ZMEphemeral*)[[[ZMEphemeral builder] mergeFromData:data] build];
}
+ (ZMEphemeral*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMEphemeral*)[[[ZMEphemeral builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMEphemeral*) parseFromInputStream:(NSInputStream*) input {
  return (ZMEphemeral*)[[[ZMEphemeral builder] mergeFromInputStream:input] build];
}
+ (ZMEphemeral*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMEphemeral*)[[[ZMEphemeral builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMEphemeral*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMEphemeral*)[[[ZMEphemeral builder] mergeFromCodedInputStream:input] build];
}
+ (ZMEphemeral*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMEphemeral*)[[[ZMEphemeral builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMEphemeralBuilder*) builder {
  return [[ZMEphemeralBuilder alloc] init];
}
+ (ZMEphemeralBuilder*) builderWithPrototype:(ZMEphemeral*) prototype {
  return [[ZMEphemeral builder] mergeFrom:prototype];
}
- (ZMEphemeralBuilder*) builder {
  return [ZMEphemeral builder];
}
- (ZMEphemeralBuilder*) toBuilder {
  return [ZMEphemeral builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasExpireAfterMillis) {
    [output appendFormat:@"%@%@: %@\n", indent, @"expireAfterMillis", [NSNumber numberWithLongLong:self.expireAfterMillis]];
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
  if (self.hasAsset) {
    [output appendFormat:@"%@%@ {\n", indent, @"asset"];
    [self.asset writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasLocation) {
    [output appendFormat:@"%@%@ {\n", indent, @"location"];
    [self.location writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasExpireAfterMillis) {
    [dictionary setObject: [NSNumber numberWithLongLong:self.expireAfterMillis] forKey: @"expireAfterMillis"];
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
  if (self.hasAsset) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.asset storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"asset"];
  }
  if (self.hasLocation) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.location storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"location"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMEphemeral class]]) {
    return NO;
  }
  ZMEphemeral *otherMessage = other;
  return
      self.hasExpireAfterMillis == otherMessage.hasExpireAfterMillis &&
      (!self.hasExpireAfterMillis || self.expireAfterMillis == otherMessage.expireAfterMillis) &&
      self.hasText == otherMessage.hasText &&
      (!self.hasText || [self.text isEqual:otherMessage.text]) &&
      self.hasImage == otherMessage.hasImage &&
      (!self.hasImage || [self.image isEqual:otherMessage.image]) &&
      self.hasKnock == otherMessage.hasKnock &&
      (!self.hasKnock || [self.knock isEqual:otherMessage.knock]) &&
      self.hasAsset == otherMessage.hasAsset &&
      (!self.hasAsset || [self.asset isEqual:otherMessage.asset]) &&
      self.hasLocation == otherMessage.hasLocation &&
      (!self.hasLocation || [self.location isEqual:otherMessage.location]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasExpireAfterMillis) {
    hashCode = hashCode * 31 + [[NSNumber numberWithLongLong:self.expireAfterMillis] hash];
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
  if (self.hasAsset) {
    hashCode = hashCode * 31 + [self.asset hash];
  }
  if (self.hasLocation) {
    hashCode = hashCode * 31 + [self.location hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMEphemeralBuilder()
@property (strong) ZMEphemeral* resultEphemeral;
@end

@implementation ZMEphemeralBuilder
@synthesize resultEphemeral;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultEphemeral = [[ZMEphemeral alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultEphemeral;
}
- (ZMEphemeralBuilder*) clear {
  self.resultEphemeral = [[ZMEphemeral alloc] init];
  return self;
}
- (ZMEphemeralBuilder*) clone {
  return [ZMEphemeral builderWithPrototype:resultEphemeral];
}
- (ZMEphemeral*) defaultInstance {
  return [ZMEphemeral defaultInstance];
}
- (ZMEphemeral*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMEphemeral*) buildPartial {
  ZMEphemeral* returnMe = resultEphemeral;
  self.resultEphemeral = nil;
  return returnMe;
}
- (ZMEphemeralBuilder*) mergeFrom:(ZMEphemeral*) other {
  if (other == [ZMEphemeral defaultInstance]) {
    return self;
  }
  if (other.hasExpireAfterMillis) {
    [self setExpireAfterMillis:other.expireAfterMillis];
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
  if (other.hasAsset) {
    [self mergeAsset:other.asset];
  }
  if (other.hasLocation) {
    [self mergeLocation:other.location];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMEphemeralBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMEphemeralBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setExpireAfterMillis:[input readInt64]];
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
      case 42: {
        ZMAssetBuilder* subBuilder = [ZMAsset builder];
        if (self.hasAsset) {
          [subBuilder mergeFrom:self.asset];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setAsset:[subBuilder buildPartial]];
        break;
      }
      case 50: {
        ZMLocationBuilder* subBuilder = [ZMLocation builder];
        if (self.hasLocation) {
          [subBuilder mergeFrom:self.location];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setLocation:[subBuilder buildPartial]];
        break;
      }
    }
  }
}
- (BOOL) hasExpireAfterMillis {
  return resultEphemeral.hasExpireAfterMillis;
}
- (SInt64) expireAfterMillis {
  return resultEphemeral.expireAfterMillis;
}
- (ZMEphemeralBuilder*) setExpireAfterMillis:(SInt64) value {
  resultEphemeral.hasExpireAfterMillis = YES;
  resultEphemeral.expireAfterMillis = value;
  return self;
}
- (ZMEphemeralBuilder*) clearExpireAfterMillis {
  resultEphemeral.hasExpireAfterMillis = NO;
  resultEphemeral.expireAfterMillis = 0L;
  return self;
}
- (BOOL) hasText {
  return resultEphemeral.hasText;
}
- (ZMText*) text {
  return resultEphemeral.text;
}
- (ZMEphemeralBuilder*) setText:(ZMText*) value {
  resultEphemeral.hasText = YES;
  resultEphemeral.text = value;
  return self;
}
- (ZMEphemeralBuilder*) setTextBuilder:(ZMTextBuilder*) builderForValue {
  return [self setText:[builderForValue build]];
}
- (ZMEphemeralBuilder*) mergeText:(ZMText*) value {
  if (resultEphemeral.hasText &&
      resultEphemeral.text != [ZMText defaultInstance]) {
    resultEphemeral.text =
      [[[ZMText builderWithPrototype:resultEphemeral.text] mergeFrom:value] buildPartial];
  } else {
    resultEphemeral.text = value;
  }
  resultEphemeral.hasText = YES;
  return self;
}
- (ZMEphemeralBuilder*) clearText {
  resultEphemeral.hasText = NO;
  resultEphemeral.text = [ZMText defaultInstance];
  return self;
}
- (BOOL) hasImage {
  return resultEphemeral.hasImage;
}
- (ZMImageAsset*) image {
  return resultEphemeral.image;
}
- (ZMEphemeralBuilder*) setImage:(ZMImageAsset*) value {
  resultEphemeral.hasImage = YES;
  resultEphemeral.image = value;
  return self;
}
- (ZMEphemeralBuilder*) setImageBuilder:(ZMImageAssetBuilder*) builderForValue {
  return [self setImage:[builderForValue build]];
}
- (ZMEphemeralBuilder*) mergeImage:(ZMImageAsset*) value {
  if (resultEphemeral.hasImage &&
      resultEphemeral.image != [ZMImageAsset defaultInstance]) {
    resultEphemeral.image =
      [[[ZMImageAsset builderWithPrototype:resultEphemeral.image] mergeFrom:value] buildPartial];
  } else {
    resultEphemeral.image = value;
  }
  resultEphemeral.hasImage = YES;
  return self;
}
- (ZMEphemeralBuilder*) clearImage {
  resultEphemeral.hasImage = NO;
  resultEphemeral.image = [ZMImageAsset defaultInstance];
  return self;
}
- (BOOL) hasKnock {
  return resultEphemeral.hasKnock;
}
- (ZMKnock*) knock {
  return resultEphemeral.knock;
}
- (ZMEphemeralBuilder*) setKnock:(ZMKnock*) value {
  resultEphemeral.hasKnock = YES;
  resultEphemeral.knock = value;
  return self;
}
- (ZMEphemeralBuilder*) setKnockBuilder:(ZMKnockBuilder*) builderForValue {
  return [self setKnock:[builderForValue build]];
}
- (ZMEphemeralBuilder*) mergeKnock:(ZMKnock*) value {
  if (resultEphemeral.hasKnock &&
      resultEphemeral.knock != [ZMKnock defaultInstance]) {
    resultEphemeral.knock =
      [[[ZMKnock builderWithPrototype:resultEphemeral.knock] mergeFrom:value] buildPartial];
  } else {
    resultEphemeral.knock = value;
  }
  resultEphemeral.hasKnock = YES;
  return self;
}
- (ZMEphemeralBuilder*) clearKnock {
  resultEphemeral.hasKnock = NO;
  resultEphemeral.knock = [ZMKnock defaultInstance];
  return self;
}
- (BOOL) hasAsset {
  return resultEphemeral.hasAsset;
}
- (ZMAsset*) asset {
  return resultEphemeral.asset;
}
- (ZMEphemeralBuilder*) setAsset:(ZMAsset*) value {
  resultEphemeral.hasAsset = YES;
  resultEphemeral.asset = value;
  return self;
}
- (ZMEphemeralBuilder*) setAssetBuilder:(ZMAssetBuilder*) builderForValue {
  return [self setAsset:[builderForValue build]];
}
- (ZMEphemeralBuilder*) mergeAsset:(ZMAsset*) value {
  if (resultEphemeral.hasAsset &&
      resultEphemeral.asset != [ZMAsset defaultInstance]) {
    resultEphemeral.asset =
      [[[ZMAsset builderWithPrototype:resultEphemeral.asset] mergeFrom:value] buildPartial];
  } else {
    resultEphemeral.asset = value;
  }
  resultEphemeral.hasAsset = YES;
  return self;
}
- (ZMEphemeralBuilder*) clearAsset {
  resultEphemeral.hasAsset = NO;
  resultEphemeral.asset = [ZMAsset defaultInstance];
  return self;
}
- (BOOL) hasLocation {
  return resultEphemeral.hasLocation;
}
- (ZMLocation*) location {
  return resultEphemeral.location;
}
- (ZMEphemeralBuilder*) setLocation:(ZMLocation*) value {
  resultEphemeral.hasLocation = YES;
  resultEphemeral.location = value;
  return self;
}
- (ZMEphemeralBuilder*) setLocationBuilder:(ZMLocationBuilder*) builderForValue {
  return [self setLocation:[builderForValue build]];
}
- (ZMEphemeralBuilder*) mergeLocation:(ZMLocation*) value {
  if (resultEphemeral.hasLocation &&
      resultEphemeral.location != [ZMLocation defaultInstance]) {
    resultEphemeral.location =
      [[[ZMLocation builderWithPrototype:resultEphemeral.location] mergeFrom:value] buildPartial];
  } else {
    resultEphemeral.location = value;
  }
  resultEphemeral.hasLocation = YES;
  return self;
}
- (ZMEphemeralBuilder*) clearLocation {
  resultEphemeral.hasLocation = NO;
  resultEphemeral.location = [ZMLocation defaultInstance];
  return self;
}
@end

@interface ZMText ()
@property (strong) NSString* content;
@property (strong) NSMutableArray<ZMLinkPreview*> * linkPreviewArray;
@property (strong) NSMutableArray<ZMMention*> * mentionsArray;
@property (strong) ZMQuote* quote;
@property BOOL expectsReadConfirmation;
@property ZMLegalHoldStatus legalHoldStatus;
@end

@implementation ZMText

- (BOOL) hasContent {
  return !!hasContent_;
}
- (void) setHasContent:(BOOL) _value_ {
  hasContent_ = !!_value_;
}
@synthesize content;
@synthesize linkPreviewArray;
@dynamic linkPreview;
@synthesize mentionsArray;
@dynamic mentions;
- (BOOL) hasQuote {
  return !!hasQuote_;
}
- (void) setHasQuote:(BOOL) _value_ {
  hasQuote_ = !!_value_;
}
@synthesize quote;
- (BOOL) hasExpectsReadConfirmation {
  return !!hasExpectsReadConfirmation_;
}
- (void) setHasExpectsReadConfirmation:(BOOL) _value_ {
  hasExpectsReadConfirmation_ = !!_value_;
}
- (BOOL) expectsReadConfirmation {
  return !!expectsReadConfirmation_;
}
- (void) setExpectsReadConfirmation:(BOOL) _value_ {
  expectsReadConfirmation_ = !!_value_;
}
- (BOOL) hasLegalHoldStatus {
  return !!hasLegalHoldStatus_;
}
- (void) setHasLegalHoldStatus:(BOOL) _value_ {
  hasLegalHoldStatus_ = !!_value_;
}
@synthesize legalHoldStatus;
- (instancetype) init {
  if ((self = [super init])) {
    self.content = @"";
    self.quote = [ZMQuote defaultInstance];
    self.expectsReadConfirmation = NO;
    self.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
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
- (NSArray<ZMLinkPreview*> *)linkPreview {
  return linkPreviewArray;
}
- (ZMLinkPreview*)linkPreviewAtIndex:(NSUInteger)index {
  return [linkPreviewArray objectAtIndex:index];
}
- (NSArray<ZMMention*> *)mentions {
  return mentionsArray;
}
- (ZMMention*)mentionsAtIndex:(NSUInteger)index {
  return [mentionsArray objectAtIndex:index];
}
- (BOOL) isInitialized {
  if (!self.hasContent) {
    return NO;
  }
  __block BOOL isInitlinkPreview = YES;
   [self.linkPreview enumerateObjectsUsingBlock:^(ZMLinkPreview *element, NSUInteger idx, BOOL *stop) {
    if (!element.isInitialized) {
      isInitlinkPreview = NO;
      *stop = YES;
    }
  }];
  if (!isInitlinkPreview) return isInitlinkPreview;
  __block BOOL isInitmentions = YES;
   [self.mentions enumerateObjectsUsingBlock:^(ZMMention *element, NSUInteger idx, BOOL *stop) {
    if (!element.isInitialized) {
      isInitmentions = NO;
      *stop = YES;
    }
  }];
  if (!isInitmentions) return isInitmentions;
  if (self.hasQuote) {
    if (!self.quote.isInitialized) {
      return NO;
    }
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasContent) {
    [output writeString:1 value:self.content];
  }
  [self.linkPreviewArray enumerateObjectsUsingBlock:^(ZMLinkPreview *element, NSUInteger idx, BOOL *stop) {
    [output writeMessage:3 value:element];
  }];
  [self.mentionsArray enumerateObjectsUsingBlock:^(ZMMention *element, NSUInteger idx, BOOL *stop) {
    [output writeMessage:4 value:element];
  }];
  if (self.hasQuote) {
    [output writeMessage:5 value:self.quote];
  }
  if (self.hasExpectsReadConfirmation) {
    [output writeBool:6 value:self.expectsReadConfirmation];
  }
  if (self.hasLegalHoldStatus) {
    [output writeEnum:7 value:self.legalHoldStatus];
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
  [self.linkPreviewArray enumerateObjectsUsingBlock:^(ZMLinkPreview *element, NSUInteger idx, BOOL *stop) {
    size_ += computeMessageSize(3, element);
  }];
  [self.mentionsArray enumerateObjectsUsingBlock:^(ZMMention *element, NSUInteger idx, BOOL *stop) {
    size_ += computeMessageSize(4, element);
  }];
  if (self.hasQuote) {
    size_ += computeMessageSize(5, self.quote);
  }
  if (self.hasExpectsReadConfirmation) {
    size_ += computeBoolSize(6, self.expectsReadConfirmation);
  }
  if (self.hasLegalHoldStatus) {
    size_ += computeEnumSize(7, self.legalHoldStatus);
  }
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
  [self.linkPreviewArray enumerateObjectsUsingBlock:^(ZMLinkPreview *element, NSUInteger idx, BOOL *stop) {
    [output appendFormat:@"%@%@ {\n", indent, @"linkPreview"];
    [element writeDescriptionTo:output
                     withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }];
  [self.mentionsArray enumerateObjectsUsingBlock:^(ZMMention *element, NSUInteger idx, BOOL *stop) {
    [output appendFormat:@"%@%@ {\n", indent, @"mentions"];
    [element writeDescriptionTo:output
                     withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }];
  if (self.hasQuote) {
    [output appendFormat:@"%@%@ {\n", indent, @"quote"];
    [self.quote writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasExpectsReadConfirmation) {
    [output appendFormat:@"%@%@: %@\n", indent, @"expectsReadConfirmation", [NSNumber numberWithBool:self.expectsReadConfirmation]];
  }
  if (self.hasLegalHoldStatus) {
    [output appendFormat:@"%@%@: %@\n", indent, @"legalHoldStatus", NSStringFromZMLegalHoldStatus(self.legalHoldStatus)];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasContent) {
    [dictionary setObject: self.content forKey: @"content"];
  }
  for (ZMLinkPreview* element in self.linkPreviewArray) {
    NSMutableDictionary *elementDictionary = [NSMutableDictionary dictionary];
    [element storeInDictionary:elementDictionary];
    [dictionary setObject:[NSDictionary dictionaryWithDictionary:elementDictionary] forKey:@"linkPreview"];
  }
  for (ZMMention* element in self.mentionsArray) {
    NSMutableDictionary *elementDictionary = [NSMutableDictionary dictionary];
    [element storeInDictionary:elementDictionary];
    [dictionary setObject:[NSDictionary dictionaryWithDictionary:elementDictionary] forKey:@"mentions"];
  }
  if (self.hasQuote) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.quote storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"quote"];
  }
  if (self.hasExpectsReadConfirmation) {
    [dictionary setObject: [NSNumber numberWithBool:self.expectsReadConfirmation] forKey: @"expectsReadConfirmation"];
  }
  if (self.hasLegalHoldStatus) {
    [dictionary setObject: @(self.legalHoldStatus) forKey: @"legalHoldStatus"];
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
      [self.linkPreviewArray isEqualToArray:otherMessage.linkPreviewArray] &&
      [self.mentionsArray isEqualToArray:otherMessage.mentionsArray] &&
      self.hasQuote == otherMessage.hasQuote &&
      (!self.hasQuote || [self.quote isEqual:otherMessage.quote]) &&
      self.hasExpectsReadConfirmation == otherMessage.hasExpectsReadConfirmation &&
      (!self.hasExpectsReadConfirmation || self.expectsReadConfirmation == otherMessage.expectsReadConfirmation) &&
      self.hasLegalHoldStatus == otherMessage.hasLegalHoldStatus &&
      (!self.hasLegalHoldStatus || self.legalHoldStatus == otherMessage.legalHoldStatus) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasContent) {
    hashCode = hashCode * 31 + [self.content hash];
  }
  [self.linkPreviewArray enumerateObjectsUsingBlock:^(ZMLinkPreview *element, NSUInteger idx, BOOL *stop) {
    hashCode = hashCode * 31 + [element hash];
  }];
  [self.mentionsArray enumerateObjectsUsingBlock:^(ZMMention *element, NSUInteger idx, BOOL *stop) {
    hashCode = hashCode * 31 + [element hash];
  }];
  if (self.hasQuote) {
    hashCode = hashCode * 31 + [self.quote hash];
  }
  if (self.hasExpectsReadConfirmation) {
    hashCode = hashCode * 31 + [[NSNumber numberWithBool:self.expectsReadConfirmation] hash];
  }
  if (self.hasLegalHoldStatus) {
    hashCode = hashCode * 31 + self.legalHoldStatus;
  }
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
  if (other.linkPreviewArray.count > 0) {
    if (resultText.linkPreviewArray == nil) {
      resultText.linkPreviewArray = [[NSMutableArray alloc] initWithArray:other.linkPreviewArray];
    } else {
      [resultText.linkPreviewArray addObjectsFromArray:other.linkPreviewArray];
    }
  }
  if (other.mentionsArray.count > 0) {
    if (resultText.mentionsArray == nil) {
      resultText.mentionsArray = [[NSMutableArray alloc] initWithArray:other.mentionsArray];
    } else {
      [resultText.mentionsArray addObjectsFromArray:other.mentionsArray];
    }
  }
  if (other.hasQuote) {
    [self mergeQuote:other.quote];
  }
  if (other.hasExpectsReadConfirmation) {
    [self setExpectsReadConfirmation:other.expectsReadConfirmation];
  }
  if (other.hasLegalHoldStatus) {
    [self setLegalHoldStatus:other.legalHoldStatus];
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
      case 26: {
        ZMLinkPreviewBuilder* subBuilder = [ZMLinkPreview builder];
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self addLinkPreview:[subBuilder buildPartial]];
        break;
      }
      case 34: {
        ZMMentionBuilder* subBuilder = [ZMMention builder];
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self addMentions:[subBuilder buildPartial]];
        break;
      }
      case 42: {
        ZMQuoteBuilder* subBuilder = [ZMQuote builder];
        if (self.hasQuote) {
          [subBuilder mergeFrom:self.quote];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setQuote:[subBuilder buildPartial]];
        break;
      }
      case 48: {
        [self setExpectsReadConfirmation:[input readBool]];
        break;
      }
      case 56: {
        ZMLegalHoldStatus value = (ZMLegalHoldStatus)[input readEnum];
        if (ZMLegalHoldStatusIsValidValue(value)) {
          [self setLegalHoldStatus:value];
        } else {
          [unknownFields mergeVarintField:7 value:value];
        }
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
- (NSMutableArray<ZMLinkPreview*> *)linkPreview {
  return resultText.linkPreviewArray;
}
- (ZMLinkPreview*)linkPreviewAtIndex:(NSUInteger)index {
  return [resultText linkPreviewAtIndex:index];
}
- (ZMTextBuilder *)addLinkPreview:(ZMLinkPreview*)value {
  if (resultText.linkPreviewArray == nil) {
    resultText.linkPreviewArray = [[NSMutableArray alloc]init];
  }
  [resultText.linkPreviewArray addObject:value];
  return self;
}
- (ZMTextBuilder *)setLinkPreviewArray:(NSArray<ZMLinkPreview*> *)array {
  resultText.linkPreviewArray = [[NSMutableArray alloc]initWithArray:array];
  return self;
}
- (ZMTextBuilder *)clearLinkPreview {
  resultText.linkPreviewArray = nil;
  return self;
}
- (NSMutableArray<ZMMention*> *)mentions {
  return resultText.mentionsArray;
}
- (ZMMention*)mentionsAtIndex:(NSUInteger)index {
  return [resultText mentionsAtIndex:index];
}
- (ZMTextBuilder *)addMentions:(ZMMention*)value {
  if (resultText.mentionsArray == nil) {
    resultText.mentionsArray = [[NSMutableArray alloc]init];
  }
  [resultText.mentionsArray addObject:value];
  return self;
}
- (ZMTextBuilder *)setMentionsArray:(NSArray<ZMMention*> *)array {
  resultText.mentionsArray = [[NSMutableArray alloc]initWithArray:array];
  return self;
}
- (ZMTextBuilder *)clearMentions {
  resultText.mentionsArray = nil;
  return self;
}
- (BOOL) hasQuote {
  return resultText.hasQuote;
}
- (ZMQuote*) quote {
  return resultText.quote;
}
- (ZMTextBuilder*) setQuote:(ZMQuote*) value {
  resultText.hasQuote = YES;
  resultText.quote = value;
  return self;
}
- (ZMTextBuilder*) setQuoteBuilder:(ZMQuoteBuilder*) builderForValue {
  return [self setQuote:[builderForValue build]];
}
- (ZMTextBuilder*) mergeQuote:(ZMQuote*) value {
  if (resultText.hasQuote &&
      resultText.quote != [ZMQuote defaultInstance]) {
    resultText.quote =
      [[[ZMQuote builderWithPrototype:resultText.quote] mergeFrom:value] buildPartial];
  } else {
    resultText.quote = value;
  }
  resultText.hasQuote = YES;
  return self;
}
- (ZMTextBuilder*) clearQuote {
  resultText.hasQuote = NO;
  resultText.quote = [ZMQuote defaultInstance];
  return self;
}
- (BOOL) hasExpectsReadConfirmation {
  return resultText.hasExpectsReadConfirmation;
}
- (BOOL) expectsReadConfirmation {
  return resultText.expectsReadConfirmation;
}
- (ZMTextBuilder*) setExpectsReadConfirmation:(BOOL) value {
  resultText.hasExpectsReadConfirmation = YES;
  resultText.expectsReadConfirmation = value;
  return self;
}
- (ZMTextBuilder*) clearExpectsReadConfirmation {
  resultText.hasExpectsReadConfirmation = NO;
  resultText.expectsReadConfirmation = NO;
  return self;
}
- (BOOL) hasLegalHoldStatus {
  return resultText.hasLegalHoldStatus;
}
- (ZMLegalHoldStatus) legalHoldStatus {
  return resultText.legalHoldStatus;
}
- (ZMTextBuilder*) setLegalHoldStatus:(ZMLegalHoldStatus) value {
  resultText.hasLegalHoldStatus = YES;
  resultText.legalHoldStatus = value;
  return self;
}
- (ZMTextBuilder*) clearLegalHoldStatus {
  resultText.hasLegalHoldStatus = NO;
  resultText.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
  return self;
}
@end

@interface ZMKnock ()
@property BOOL hotKnock;
@property BOOL expectsReadConfirmation;
@property ZMLegalHoldStatus legalHoldStatus;
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
- (BOOL) hasExpectsReadConfirmation {
  return !!hasExpectsReadConfirmation_;
}
- (void) setHasExpectsReadConfirmation:(BOOL) _value_ {
  hasExpectsReadConfirmation_ = !!_value_;
}
- (BOOL) expectsReadConfirmation {
  return !!expectsReadConfirmation_;
}
- (void) setExpectsReadConfirmation:(BOOL) _value_ {
  expectsReadConfirmation_ = !!_value_;
}
- (BOOL) hasLegalHoldStatus {
  return !!hasLegalHoldStatus_;
}
- (void) setHasLegalHoldStatus:(BOOL) _value_ {
  hasLegalHoldStatus_ = !!_value_;
}
@synthesize legalHoldStatus;
- (instancetype) init {
  if ((self = [super init])) {
    self.hotKnock = NO;
    self.expectsReadConfirmation = NO;
    self.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
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
  if (self.hasExpectsReadConfirmation) {
    [output writeBool:2 value:self.expectsReadConfirmation];
  }
  if (self.hasLegalHoldStatus) {
    [output writeEnum:3 value:self.legalHoldStatus];
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
  if (self.hasExpectsReadConfirmation) {
    size_ += computeBoolSize(2, self.expectsReadConfirmation);
  }
  if (self.hasLegalHoldStatus) {
    size_ += computeEnumSize(3, self.legalHoldStatus);
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
  if (self.hasExpectsReadConfirmation) {
    [output appendFormat:@"%@%@: %@\n", indent, @"expectsReadConfirmation", [NSNumber numberWithBool:self.expectsReadConfirmation]];
  }
  if (self.hasLegalHoldStatus) {
    [output appendFormat:@"%@%@: %@\n", indent, @"legalHoldStatus", NSStringFromZMLegalHoldStatus(self.legalHoldStatus)];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasHotKnock) {
    [dictionary setObject: [NSNumber numberWithBool:self.hotKnock] forKey: @"hotKnock"];
  }
  if (self.hasExpectsReadConfirmation) {
    [dictionary setObject: [NSNumber numberWithBool:self.expectsReadConfirmation] forKey: @"expectsReadConfirmation"];
  }
  if (self.hasLegalHoldStatus) {
    [dictionary setObject: @(self.legalHoldStatus) forKey: @"legalHoldStatus"];
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
      self.hasExpectsReadConfirmation == otherMessage.hasExpectsReadConfirmation &&
      (!self.hasExpectsReadConfirmation || self.expectsReadConfirmation == otherMessage.expectsReadConfirmation) &&
      self.hasLegalHoldStatus == otherMessage.hasLegalHoldStatus &&
      (!self.hasLegalHoldStatus || self.legalHoldStatus == otherMessage.legalHoldStatus) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasHotKnock) {
    hashCode = hashCode * 31 + [[NSNumber numberWithBool:self.hotKnock] hash];
  }
  if (self.hasExpectsReadConfirmation) {
    hashCode = hashCode * 31 + [[NSNumber numberWithBool:self.expectsReadConfirmation] hash];
  }
  if (self.hasLegalHoldStatus) {
    hashCode = hashCode * 31 + self.legalHoldStatus;
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
  if (other.hasExpectsReadConfirmation) {
    [self setExpectsReadConfirmation:other.expectsReadConfirmation];
  }
  if (other.hasLegalHoldStatus) {
    [self setLegalHoldStatus:other.legalHoldStatus];
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
      case 16: {
        [self setExpectsReadConfirmation:[input readBool]];
        break;
      }
      case 24: {
        ZMLegalHoldStatus value = (ZMLegalHoldStatus)[input readEnum];
        if (ZMLegalHoldStatusIsValidValue(value)) {
          [self setLegalHoldStatus:value];
        } else {
          [unknownFields mergeVarintField:3 value:value];
        }
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
- (BOOL) hasExpectsReadConfirmation {
  return resultKnock.hasExpectsReadConfirmation;
}
- (BOOL) expectsReadConfirmation {
  return resultKnock.expectsReadConfirmation;
}
- (ZMKnockBuilder*) setExpectsReadConfirmation:(BOOL) value {
  resultKnock.hasExpectsReadConfirmation = YES;
  resultKnock.expectsReadConfirmation = value;
  return self;
}
- (ZMKnockBuilder*) clearExpectsReadConfirmation {
  resultKnock.hasExpectsReadConfirmation = NO;
  resultKnock.expectsReadConfirmation = NO;
  return self;
}
- (BOOL) hasLegalHoldStatus {
  return resultKnock.hasLegalHoldStatus;
}
- (ZMLegalHoldStatus) legalHoldStatus {
  return resultKnock.legalHoldStatus;
}
- (ZMKnockBuilder*) setLegalHoldStatus:(ZMLegalHoldStatus) value {
  resultKnock.hasLegalHoldStatus = YES;
  resultKnock.legalHoldStatus = value;
  return self;
}
- (ZMKnockBuilder*) clearLegalHoldStatus {
  resultKnock.hasLegalHoldStatus = NO;
  resultKnock.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
  return self;
}
@end

@interface ZMLinkPreview ()
@property (strong) NSString* url;
@property SInt32 urlOffset;
@property (strong) ZMArticle* article;
@property (strong) NSString* permanentUrl;
@property (strong) NSString* title;
@property (strong) NSString* summary;
@property (strong) ZMAsset* image;
@property (strong) ZMTweet* tweet;
@end

@implementation ZMLinkPreview

- (BOOL) hasUrl {
  return !!hasUrl_;
}
- (void) setHasUrl:(BOOL) _value_ {
  hasUrl_ = !!_value_;
}
@synthesize url;
- (BOOL) hasUrlOffset {
  return !!hasUrlOffset_;
}
- (void) setHasUrlOffset:(BOOL) _value_ {
  hasUrlOffset_ = !!_value_;
}
@synthesize urlOffset;
- (BOOL) hasArticle {
  return !!hasArticle_;
}
- (void) setHasArticle:(BOOL) _value_ {
  hasArticle_ = !!_value_;
}
@synthesize article;
- (BOOL) hasPermanentUrl {
  return !!hasPermanentUrl_;
}
- (void) setHasPermanentUrl:(BOOL) _value_ {
  hasPermanentUrl_ = !!_value_;
}
@synthesize permanentUrl;
- (BOOL) hasTitle {
  return !!hasTitle_;
}
- (void) setHasTitle:(BOOL) _value_ {
  hasTitle_ = !!_value_;
}
@synthesize title;
- (BOOL) hasSummary {
  return !!hasSummary_;
}
- (void) setHasSummary:(BOOL) _value_ {
  hasSummary_ = !!_value_;
}
@synthesize summary;
- (BOOL) hasImage {
  return !!hasImage_;
}
- (void) setHasImage:(BOOL) _value_ {
  hasImage_ = !!_value_;
}
@synthesize image;
- (BOOL) hasTweet {
  return !!hasTweet_;
}
- (void) setHasTweet:(BOOL) _value_ {
  hasTweet_ = !!_value_;
}
@synthesize tweet;
- (instancetype) init {
  if ((self = [super init])) {
    self.url = @"";
    self.urlOffset = 0;
    self.article = [ZMArticle defaultInstance];
    self.permanentUrl = @"";
    self.title = @"";
    self.summary = @"";
    self.image = [ZMAsset defaultInstance];
    self.tweet = [ZMTweet defaultInstance];
  }
  return self;
}
static ZMLinkPreview* defaultZMLinkPreviewInstance = nil;
+ (void) initialize {
  if (self == [ZMLinkPreview class]) {
    defaultZMLinkPreviewInstance = [[ZMLinkPreview alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMLinkPreviewInstance;
}
- (instancetype) defaultInstance {
  return defaultZMLinkPreviewInstance;
}
- (BOOL) isInitialized {
  if (!self.hasUrl) {
    return NO;
  }
  if (!self.hasUrlOffset) {
    return NO;
  }
  if (self.hasArticle) {
    if (!self.article.isInitialized) {
      return NO;
    }
  }
  if (self.hasImage) {
    if (!self.image.isInitialized) {
      return NO;
    }
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasUrl) {
    [output writeString:1 value:self.url];
  }
  if (self.hasUrlOffset) {
    [output writeInt32:2 value:self.urlOffset];
  }
  if (self.hasArticle) {
    [output writeMessage:3 value:self.article];
  }
  if (self.hasPermanentUrl) {
    [output writeString:5 value:self.permanentUrl];
  }
  if (self.hasTitle) {
    [output writeString:6 value:self.title];
  }
  if (self.hasSummary) {
    [output writeString:7 value:self.summary];
  }
  if (self.hasImage) {
    [output writeMessage:8 value:self.image];
  }
  if (self.hasTweet) {
    [output writeMessage:9 value:self.tweet];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasUrl) {
    size_ += computeStringSize(1, self.url);
  }
  if (self.hasUrlOffset) {
    size_ += computeInt32Size(2, self.urlOffset);
  }
  if (self.hasArticle) {
    size_ += computeMessageSize(3, self.article);
  }
  if (self.hasPermanentUrl) {
    size_ += computeStringSize(5, self.permanentUrl);
  }
  if (self.hasTitle) {
    size_ += computeStringSize(6, self.title);
  }
  if (self.hasSummary) {
    size_ += computeStringSize(7, self.summary);
  }
  if (self.hasImage) {
    size_ += computeMessageSize(8, self.image);
  }
  if (self.hasTweet) {
    size_ += computeMessageSize(9, self.tweet);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMLinkPreview*) parseFromData:(NSData*) data {
  return (ZMLinkPreview*)[[[ZMLinkPreview builder] mergeFromData:data] build];
}
+ (ZMLinkPreview*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMLinkPreview*)[[[ZMLinkPreview builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMLinkPreview*) parseFromInputStream:(NSInputStream*) input {
  return (ZMLinkPreview*)[[[ZMLinkPreview builder] mergeFromInputStream:input] build];
}
+ (ZMLinkPreview*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMLinkPreview*)[[[ZMLinkPreview builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMLinkPreview*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMLinkPreview*)[[[ZMLinkPreview builder] mergeFromCodedInputStream:input] build];
}
+ (ZMLinkPreview*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMLinkPreview*)[[[ZMLinkPreview builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMLinkPreviewBuilder*) builder {
  return [[ZMLinkPreviewBuilder alloc] init];
}
+ (ZMLinkPreviewBuilder*) builderWithPrototype:(ZMLinkPreview*) prototype {
  return [[ZMLinkPreview builder] mergeFrom:prototype];
}
- (ZMLinkPreviewBuilder*) builder {
  return [ZMLinkPreview builder];
}
- (ZMLinkPreviewBuilder*) toBuilder {
  return [ZMLinkPreview builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasUrl) {
    [output appendFormat:@"%@%@: %@\n", indent, @"url", self.url];
  }
  if (self.hasUrlOffset) {
    [output appendFormat:@"%@%@: %@\n", indent, @"urlOffset", [NSNumber numberWithInteger:self.urlOffset]];
  }
  if (self.hasArticle) {
    [output appendFormat:@"%@%@ {\n", indent, @"article"];
    [self.article writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasPermanentUrl) {
    [output appendFormat:@"%@%@: %@\n", indent, @"permanentUrl", self.permanentUrl];
  }
  if (self.hasTitle) {
    [output appendFormat:@"%@%@: %@\n", indent, @"title", self.title];
  }
  if (self.hasSummary) {
    [output appendFormat:@"%@%@: %@\n", indent, @"summary", self.summary];
  }
  if (self.hasImage) {
    [output appendFormat:@"%@%@ {\n", indent, @"image"];
    [self.image writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasTweet) {
    [output appendFormat:@"%@%@ {\n", indent, @"tweet"];
    [self.tweet writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasUrl) {
    [dictionary setObject: self.url forKey: @"url"];
  }
  if (self.hasUrlOffset) {
    [dictionary setObject: [NSNumber numberWithInteger:self.urlOffset] forKey: @"urlOffset"];
  }
  if (self.hasArticle) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.article storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"article"];
  }
  if (self.hasPermanentUrl) {
    [dictionary setObject: self.permanentUrl forKey: @"permanentUrl"];
  }
  if (self.hasTitle) {
    [dictionary setObject: self.title forKey: @"title"];
  }
  if (self.hasSummary) {
    [dictionary setObject: self.summary forKey: @"summary"];
  }
  if (self.hasImage) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.image storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"image"];
  }
  if (self.hasTweet) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.tweet storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"tweet"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMLinkPreview class]]) {
    return NO;
  }
  ZMLinkPreview *otherMessage = other;
  return
      self.hasUrl == otherMessage.hasUrl &&
      (!self.hasUrl || [self.url isEqual:otherMessage.url]) &&
      self.hasUrlOffset == otherMessage.hasUrlOffset &&
      (!self.hasUrlOffset || self.urlOffset == otherMessage.urlOffset) &&
      self.hasArticle == otherMessage.hasArticle &&
      (!self.hasArticle || [self.article isEqual:otherMessage.article]) &&
      self.hasPermanentUrl == otherMessage.hasPermanentUrl &&
      (!self.hasPermanentUrl || [self.permanentUrl isEqual:otherMessage.permanentUrl]) &&
      self.hasTitle == otherMessage.hasTitle &&
      (!self.hasTitle || [self.title isEqual:otherMessage.title]) &&
      self.hasSummary == otherMessage.hasSummary &&
      (!self.hasSummary || [self.summary isEqual:otherMessage.summary]) &&
      self.hasImage == otherMessage.hasImage &&
      (!self.hasImage || [self.image isEqual:otherMessage.image]) &&
      self.hasTweet == otherMessage.hasTweet &&
      (!self.hasTweet || [self.tweet isEqual:otherMessage.tweet]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasUrl) {
    hashCode = hashCode * 31 + [self.url hash];
  }
  if (self.hasUrlOffset) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.urlOffset] hash];
  }
  if (self.hasArticle) {
    hashCode = hashCode * 31 + [self.article hash];
  }
  if (self.hasPermanentUrl) {
    hashCode = hashCode * 31 + [self.permanentUrl hash];
  }
  if (self.hasTitle) {
    hashCode = hashCode * 31 + [self.title hash];
  }
  if (self.hasSummary) {
    hashCode = hashCode * 31 + [self.summary hash];
  }
  if (self.hasImage) {
    hashCode = hashCode * 31 + [self.image hash];
  }
  if (self.hasTweet) {
    hashCode = hashCode * 31 + [self.tweet hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMLinkPreviewBuilder()
@property (strong) ZMLinkPreview* resultLinkPreview;
@end

@implementation ZMLinkPreviewBuilder
@synthesize resultLinkPreview;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultLinkPreview = [[ZMLinkPreview alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultLinkPreview;
}
- (ZMLinkPreviewBuilder*) clear {
  self.resultLinkPreview = [[ZMLinkPreview alloc] init];
  return self;
}
- (ZMLinkPreviewBuilder*) clone {
  return [ZMLinkPreview builderWithPrototype:resultLinkPreview];
}
- (ZMLinkPreview*) defaultInstance {
  return [ZMLinkPreview defaultInstance];
}
- (ZMLinkPreview*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMLinkPreview*) buildPartial {
  ZMLinkPreview* returnMe = resultLinkPreview;
  self.resultLinkPreview = nil;
  return returnMe;
}
- (ZMLinkPreviewBuilder*) mergeFrom:(ZMLinkPreview*) other {
  if (other == [ZMLinkPreview defaultInstance]) {
    return self;
  }
  if (other.hasUrl) {
    [self setUrl:other.url];
  }
  if (other.hasUrlOffset) {
    [self setUrlOffset:other.urlOffset];
  }
  if (other.hasArticle) {
    [self mergeArticle:other.article];
  }
  if (other.hasPermanentUrl) {
    [self setPermanentUrl:other.permanentUrl];
  }
  if (other.hasTitle) {
    [self setTitle:other.title];
  }
  if (other.hasSummary) {
    [self setSummary:other.summary];
  }
  if (other.hasImage) {
    [self mergeImage:other.image];
  }
  if (other.hasTweet) {
    [self mergeTweet:other.tweet];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMLinkPreviewBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMLinkPreviewBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setUrl:[input readString]];
        break;
      }
      case 16: {
        [self setUrlOffset:[input readInt32]];
        break;
      }
      case 26: {
        ZMArticleBuilder* subBuilder = [ZMArticle builder];
        if (self.hasArticle) {
          [subBuilder mergeFrom:self.article];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setArticle:[subBuilder buildPartial]];
        break;
      }
      case 42: {
        [self setPermanentUrl:[input readString]];
        break;
      }
      case 50: {
        [self setTitle:[input readString]];
        break;
      }
      case 58: {
        [self setSummary:[input readString]];
        break;
      }
      case 66: {
        ZMAssetBuilder* subBuilder = [ZMAsset builder];
        if (self.hasImage) {
          [subBuilder mergeFrom:self.image];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setImage:[subBuilder buildPartial]];
        break;
      }
      case 74: {
        ZMTweetBuilder* subBuilder = [ZMTweet builder];
        if (self.hasTweet) {
          [subBuilder mergeFrom:self.tweet];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setTweet:[subBuilder buildPartial]];
        break;
      }
    }
  }
}
- (BOOL) hasUrl {
  return resultLinkPreview.hasUrl;
}
- (NSString*) url {
  return resultLinkPreview.url;
}
- (ZMLinkPreviewBuilder*) setUrl:(NSString*) value {
  resultLinkPreview.hasUrl = YES;
  resultLinkPreview.url = value;
  return self;
}
- (ZMLinkPreviewBuilder*) clearUrl {
  resultLinkPreview.hasUrl = NO;
  resultLinkPreview.url = @"";
  return self;
}
- (BOOL) hasUrlOffset {
  return resultLinkPreview.hasUrlOffset;
}
- (SInt32) urlOffset {
  return resultLinkPreview.urlOffset;
}
- (ZMLinkPreviewBuilder*) setUrlOffset:(SInt32) value {
  resultLinkPreview.hasUrlOffset = YES;
  resultLinkPreview.urlOffset = value;
  return self;
}
- (ZMLinkPreviewBuilder*) clearUrlOffset {
  resultLinkPreview.hasUrlOffset = NO;
  resultLinkPreview.urlOffset = 0;
  return self;
}
- (BOOL) hasArticle {
  return resultLinkPreview.hasArticle;
}
- (ZMArticle*) article {
  return resultLinkPreview.article;
}
- (ZMLinkPreviewBuilder*) setArticle:(ZMArticle*) value {
  resultLinkPreview.hasArticle = YES;
  resultLinkPreview.article = value;
  return self;
}
- (ZMLinkPreviewBuilder*) setArticleBuilder:(ZMArticleBuilder*) builderForValue {
  return [self setArticle:[builderForValue build]];
}
- (ZMLinkPreviewBuilder*) mergeArticle:(ZMArticle*) value {
  if (resultLinkPreview.hasArticle &&
      resultLinkPreview.article != [ZMArticle defaultInstance]) {
    resultLinkPreview.article =
      [[[ZMArticle builderWithPrototype:resultLinkPreview.article] mergeFrom:value] buildPartial];
  } else {
    resultLinkPreview.article = value;
  }
  resultLinkPreview.hasArticle = YES;
  return self;
}
- (ZMLinkPreviewBuilder*) clearArticle {
  resultLinkPreview.hasArticle = NO;
  resultLinkPreview.article = [ZMArticle defaultInstance];
  return self;
}
- (BOOL) hasPermanentUrl {
  return resultLinkPreview.hasPermanentUrl;
}
- (NSString*) permanentUrl {
  return resultLinkPreview.permanentUrl;
}
- (ZMLinkPreviewBuilder*) setPermanentUrl:(NSString*) value {
  resultLinkPreview.hasPermanentUrl = YES;
  resultLinkPreview.permanentUrl = value;
  return self;
}
- (ZMLinkPreviewBuilder*) clearPermanentUrl {
  resultLinkPreview.hasPermanentUrl = NO;
  resultLinkPreview.permanentUrl = @"";
  return self;
}
- (BOOL) hasTitle {
  return resultLinkPreview.hasTitle;
}
- (NSString*) title {
  return resultLinkPreview.title;
}
- (ZMLinkPreviewBuilder*) setTitle:(NSString*) value {
  resultLinkPreview.hasTitle = YES;
  resultLinkPreview.title = value;
  return self;
}
- (ZMLinkPreviewBuilder*) clearTitle {
  resultLinkPreview.hasTitle = NO;
  resultLinkPreview.title = @"";
  return self;
}
- (BOOL) hasSummary {
  return resultLinkPreview.hasSummary;
}
- (NSString*) summary {
  return resultLinkPreview.summary;
}
- (ZMLinkPreviewBuilder*) setSummary:(NSString*) value {
  resultLinkPreview.hasSummary = YES;
  resultLinkPreview.summary = value;
  return self;
}
- (ZMLinkPreviewBuilder*) clearSummary {
  resultLinkPreview.hasSummary = NO;
  resultLinkPreview.summary = @"";
  return self;
}
- (BOOL) hasImage {
  return resultLinkPreview.hasImage;
}
- (ZMAsset*) image {
  return resultLinkPreview.image;
}
- (ZMLinkPreviewBuilder*) setImage:(ZMAsset*) value {
  resultLinkPreview.hasImage = YES;
  resultLinkPreview.image = value;
  return self;
}
- (ZMLinkPreviewBuilder*) setImageBuilder:(ZMAssetBuilder*) builderForValue {
  return [self setImage:[builderForValue build]];
}
- (ZMLinkPreviewBuilder*) mergeImage:(ZMAsset*) value {
  if (resultLinkPreview.hasImage &&
      resultLinkPreview.image != [ZMAsset defaultInstance]) {
    resultLinkPreview.image =
      [[[ZMAsset builderWithPrototype:resultLinkPreview.image] mergeFrom:value] buildPartial];
  } else {
    resultLinkPreview.image = value;
  }
  resultLinkPreview.hasImage = YES;
  return self;
}
- (ZMLinkPreviewBuilder*) clearImage {
  resultLinkPreview.hasImage = NO;
  resultLinkPreview.image = [ZMAsset defaultInstance];
  return self;
}
- (BOOL) hasTweet {
  return resultLinkPreview.hasTweet;
}
- (ZMTweet*) tweet {
  return resultLinkPreview.tweet;
}
- (ZMLinkPreviewBuilder*) setTweet:(ZMTweet*) value {
  resultLinkPreview.hasTweet = YES;
  resultLinkPreview.tweet = value;
  return self;
}
- (ZMLinkPreviewBuilder*) setTweetBuilder:(ZMTweetBuilder*) builderForValue {
  return [self setTweet:[builderForValue build]];
}
- (ZMLinkPreviewBuilder*) mergeTweet:(ZMTweet*) value {
  if (resultLinkPreview.hasTweet &&
      resultLinkPreview.tweet != [ZMTweet defaultInstance]) {
    resultLinkPreview.tweet =
      [[[ZMTweet builderWithPrototype:resultLinkPreview.tweet] mergeFrom:value] buildPartial];
  } else {
    resultLinkPreview.tweet = value;
  }
  resultLinkPreview.hasTweet = YES;
  return self;
}
- (ZMLinkPreviewBuilder*) clearTweet {
  resultLinkPreview.hasTweet = NO;
  resultLinkPreview.tweet = [ZMTweet defaultInstance];
  return self;
}
@end

@interface ZMTweet ()
@property (strong) NSString* author;
@property (strong) NSString* username;
@end

@implementation ZMTweet

- (BOOL) hasAuthor {
  return !!hasAuthor_;
}
- (void) setHasAuthor:(BOOL) _value_ {
  hasAuthor_ = !!_value_;
}
@synthesize author;
- (BOOL) hasUsername {
  return !!hasUsername_;
}
- (void) setHasUsername:(BOOL) _value_ {
  hasUsername_ = !!_value_;
}
@synthesize username;
- (instancetype) init {
  if ((self = [super init])) {
    self.author = @"";
    self.username = @"";
  }
  return self;
}
static ZMTweet* defaultZMTweetInstance = nil;
+ (void) initialize {
  if (self == [ZMTweet class]) {
    defaultZMTweetInstance = [[ZMTweet alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMTweetInstance;
}
- (instancetype) defaultInstance {
  return defaultZMTweetInstance;
}
- (BOOL) isInitialized {
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasAuthor) {
    [output writeString:1 value:self.author];
  }
  if (self.hasUsername) {
    [output writeString:2 value:self.username];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasAuthor) {
    size_ += computeStringSize(1, self.author);
  }
  if (self.hasUsername) {
    size_ += computeStringSize(2, self.username);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMTweet*) parseFromData:(NSData*) data {
  return (ZMTweet*)[[[ZMTweet builder] mergeFromData:data] build];
}
+ (ZMTweet*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMTweet*)[[[ZMTweet builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMTweet*) parseFromInputStream:(NSInputStream*) input {
  return (ZMTweet*)[[[ZMTweet builder] mergeFromInputStream:input] build];
}
+ (ZMTweet*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMTweet*)[[[ZMTweet builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMTweet*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMTweet*)[[[ZMTweet builder] mergeFromCodedInputStream:input] build];
}
+ (ZMTweet*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMTweet*)[[[ZMTweet builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMTweetBuilder*) builder {
  return [[ZMTweetBuilder alloc] init];
}
+ (ZMTweetBuilder*) builderWithPrototype:(ZMTweet*) prototype {
  return [[ZMTweet builder] mergeFrom:prototype];
}
- (ZMTweetBuilder*) builder {
  return [ZMTweet builder];
}
- (ZMTweetBuilder*) toBuilder {
  return [ZMTweet builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasAuthor) {
    [output appendFormat:@"%@%@: %@\n", indent, @"author", self.author];
  }
  if (self.hasUsername) {
    [output appendFormat:@"%@%@: %@\n", indent, @"username", self.username];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasAuthor) {
    [dictionary setObject: self.author forKey: @"author"];
  }
  if (self.hasUsername) {
    [dictionary setObject: self.username forKey: @"username"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMTweet class]]) {
    return NO;
  }
  ZMTweet *otherMessage = other;
  return
      self.hasAuthor == otherMessage.hasAuthor &&
      (!self.hasAuthor || [self.author isEqual:otherMessage.author]) &&
      self.hasUsername == otherMessage.hasUsername &&
      (!self.hasUsername || [self.username isEqual:otherMessage.username]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasAuthor) {
    hashCode = hashCode * 31 + [self.author hash];
  }
  if (self.hasUsername) {
    hashCode = hashCode * 31 + [self.username hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMTweetBuilder()
@property (strong) ZMTweet* resultTweet;
@end

@implementation ZMTweetBuilder
@synthesize resultTweet;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultTweet = [[ZMTweet alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultTweet;
}
- (ZMTweetBuilder*) clear {
  self.resultTweet = [[ZMTweet alloc] init];
  return self;
}
- (ZMTweetBuilder*) clone {
  return [ZMTweet builderWithPrototype:resultTweet];
}
- (ZMTweet*) defaultInstance {
  return [ZMTweet defaultInstance];
}
- (ZMTweet*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMTweet*) buildPartial {
  ZMTweet* returnMe = resultTweet;
  self.resultTweet = nil;
  return returnMe;
}
- (ZMTweetBuilder*) mergeFrom:(ZMTweet*) other {
  if (other == [ZMTweet defaultInstance]) {
    return self;
  }
  if (other.hasAuthor) {
    [self setAuthor:other.author];
  }
  if (other.hasUsername) {
    [self setUsername:other.username];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMTweetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMTweetBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setAuthor:[input readString]];
        break;
      }
      case 18: {
        [self setUsername:[input readString]];
        break;
      }
    }
  }
}
- (BOOL) hasAuthor {
  return resultTweet.hasAuthor;
}
- (NSString*) author {
  return resultTweet.author;
}
- (ZMTweetBuilder*) setAuthor:(NSString*) value {
  resultTweet.hasAuthor = YES;
  resultTweet.author = value;
  return self;
}
- (ZMTweetBuilder*) clearAuthor {
  resultTweet.hasAuthor = NO;
  resultTweet.author = @"";
  return self;
}
- (BOOL) hasUsername {
  return resultTweet.hasUsername;
}
- (NSString*) username {
  return resultTweet.username;
}
- (ZMTweetBuilder*) setUsername:(NSString*) value {
  resultTweet.hasUsername = YES;
  resultTweet.username = value;
  return self;
}
- (ZMTweetBuilder*) clearUsername {
  resultTweet.hasUsername = NO;
  resultTweet.username = @"";
  return self;
}
@end

@interface ZMArticle ()
@property (strong) NSString* permanentUrl;
@property (strong) NSString* title;
@property (strong) NSString* summary;
@property (strong) ZMAsset* image;
@end

@implementation ZMArticle

- (BOOL) hasPermanentUrl {
  return !!hasPermanentUrl_;
}
- (void) setHasPermanentUrl:(BOOL) _value_ {
  hasPermanentUrl_ = !!_value_;
}
@synthesize permanentUrl;
- (BOOL) hasTitle {
  return !!hasTitle_;
}
- (void) setHasTitle:(BOOL) _value_ {
  hasTitle_ = !!_value_;
}
@synthesize title;
- (BOOL) hasSummary {
  return !!hasSummary_;
}
- (void) setHasSummary:(BOOL) _value_ {
  hasSummary_ = !!_value_;
}
@synthesize summary;
- (BOOL) hasImage {
  return !!hasImage_;
}
- (void) setHasImage:(BOOL) _value_ {
  hasImage_ = !!_value_;
}
@synthesize image;
- (instancetype) init {
  if ((self = [super init])) {
    self.permanentUrl = @"";
    self.title = @"";
    self.summary = @"";
    self.image = [ZMAsset defaultInstance];
  }
  return self;
}
static ZMArticle* defaultZMArticleInstance = nil;
+ (void) initialize {
  if (self == [ZMArticle class]) {
    defaultZMArticleInstance = [[ZMArticle alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMArticleInstance;
}
- (instancetype) defaultInstance {
  return defaultZMArticleInstance;
}
- (BOOL) isInitialized {
  if (!self.hasPermanentUrl) {
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
  if (self.hasPermanentUrl) {
    [output writeString:1 value:self.permanentUrl];
  }
  if (self.hasTitle) {
    [output writeString:2 value:self.title];
  }
  if (self.hasSummary) {
    [output writeString:3 value:self.summary];
  }
  if (self.hasImage) {
    [output writeMessage:4 value:self.image];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasPermanentUrl) {
    size_ += computeStringSize(1, self.permanentUrl);
  }
  if (self.hasTitle) {
    size_ += computeStringSize(2, self.title);
  }
  if (self.hasSummary) {
    size_ += computeStringSize(3, self.summary);
  }
  if (self.hasImage) {
    size_ += computeMessageSize(4, self.image);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMArticle*) parseFromData:(NSData*) data {
  return (ZMArticle*)[[[ZMArticle builder] mergeFromData:data] build];
}
+ (ZMArticle*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMArticle*)[[[ZMArticle builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMArticle*) parseFromInputStream:(NSInputStream*) input {
  return (ZMArticle*)[[[ZMArticle builder] mergeFromInputStream:input] build];
}
+ (ZMArticle*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMArticle*)[[[ZMArticle builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMArticle*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMArticle*)[[[ZMArticle builder] mergeFromCodedInputStream:input] build];
}
+ (ZMArticle*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMArticle*)[[[ZMArticle builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMArticleBuilder*) builder {
  return [[ZMArticleBuilder alloc] init];
}
+ (ZMArticleBuilder*) builderWithPrototype:(ZMArticle*) prototype {
  return [[ZMArticle builder] mergeFrom:prototype];
}
- (ZMArticleBuilder*) builder {
  return [ZMArticle builder];
}
- (ZMArticleBuilder*) toBuilder {
  return [ZMArticle builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasPermanentUrl) {
    [output appendFormat:@"%@%@: %@\n", indent, @"permanentUrl", self.permanentUrl];
  }
  if (self.hasTitle) {
    [output appendFormat:@"%@%@: %@\n", indent, @"title", self.title];
  }
  if (self.hasSummary) {
    [output appendFormat:@"%@%@: %@\n", indent, @"summary", self.summary];
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
  if (self.hasPermanentUrl) {
    [dictionary setObject: self.permanentUrl forKey: @"permanentUrl"];
  }
  if (self.hasTitle) {
    [dictionary setObject: self.title forKey: @"title"];
  }
  if (self.hasSummary) {
    [dictionary setObject: self.summary forKey: @"summary"];
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
  if (![other isKindOfClass:[ZMArticle class]]) {
    return NO;
  }
  ZMArticle *otherMessage = other;
  return
      self.hasPermanentUrl == otherMessage.hasPermanentUrl &&
      (!self.hasPermanentUrl || [self.permanentUrl isEqual:otherMessage.permanentUrl]) &&
      self.hasTitle == otherMessage.hasTitle &&
      (!self.hasTitle || [self.title isEqual:otherMessage.title]) &&
      self.hasSummary == otherMessage.hasSummary &&
      (!self.hasSummary || [self.summary isEqual:otherMessage.summary]) &&
      self.hasImage == otherMessage.hasImage &&
      (!self.hasImage || [self.image isEqual:otherMessage.image]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasPermanentUrl) {
    hashCode = hashCode * 31 + [self.permanentUrl hash];
  }
  if (self.hasTitle) {
    hashCode = hashCode * 31 + [self.title hash];
  }
  if (self.hasSummary) {
    hashCode = hashCode * 31 + [self.summary hash];
  }
  if (self.hasImage) {
    hashCode = hashCode * 31 + [self.image hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMArticleBuilder()
@property (strong) ZMArticle* resultArticle;
@end

@implementation ZMArticleBuilder
@synthesize resultArticle;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultArticle = [[ZMArticle alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultArticle;
}
- (ZMArticleBuilder*) clear {
  self.resultArticle = [[ZMArticle alloc] init];
  return self;
}
- (ZMArticleBuilder*) clone {
  return [ZMArticle builderWithPrototype:resultArticle];
}
- (ZMArticle*) defaultInstance {
  return [ZMArticle defaultInstance];
}
- (ZMArticle*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMArticle*) buildPartial {
  ZMArticle* returnMe = resultArticle;
  self.resultArticle = nil;
  return returnMe;
}
- (ZMArticleBuilder*) mergeFrom:(ZMArticle*) other {
  if (other == [ZMArticle defaultInstance]) {
    return self;
  }
  if (other.hasPermanentUrl) {
    [self setPermanentUrl:other.permanentUrl];
  }
  if (other.hasTitle) {
    [self setTitle:other.title];
  }
  if (other.hasSummary) {
    [self setSummary:other.summary];
  }
  if (other.hasImage) {
    [self mergeImage:other.image];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMArticleBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMArticleBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setPermanentUrl:[input readString]];
        break;
      }
      case 18: {
        [self setTitle:[input readString]];
        break;
      }
      case 26: {
        [self setSummary:[input readString]];
        break;
      }
      case 34: {
        ZMAssetBuilder* subBuilder = [ZMAsset builder];
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
- (BOOL) hasPermanentUrl {
  return resultArticle.hasPermanentUrl;
}
- (NSString*) permanentUrl {
  return resultArticle.permanentUrl;
}
- (ZMArticleBuilder*) setPermanentUrl:(NSString*) value {
  resultArticle.hasPermanentUrl = YES;
  resultArticle.permanentUrl = value;
  return self;
}
- (ZMArticleBuilder*) clearPermanentUrl {
  resultArticle.hasPermanentUrl = NO;
  resultArticle.permanentUrl = @"";
  return self;
}
- (BOOL) hasTitle {
  return resultArticle.hasTitle;
}
- (NSString*) title {
  return resultArticle.title;
}
- (ZMArticleBuilder*) setTitle:(NSString*) value {
  resultArticle.hasTitle = YES;
  resultArticle.title = value;
  return self;
}
- (ZMArticleBuilder*) clearTitle {
  resultArticle.hasTitle = NO;
  resultArticle.title = @"";
  return self;
}
- (BOOL) hasSummary {
  return resultArticle.hasSummary;
}
- (NSString*) summary {
  return resultArticle.summary;
}
- (ZMArticleBuilder*) setSummary:(NSString*) value {
  resultArticle.hasSummary = YES;
  resultArticle.summary = value;
  return self;
}
- (ZMArticleBuilder*) clearSummary {
  resultArticle.hasSummary = NO;
  resultArticle.summary = @"";
  return self;
}
- (BOOL) hasImage {
  return resultArticle.hasImage;
}
- (ZMAsset*) image {
  return resultArticle.image;
}
- (ZMArticleBuilder*) setImage:(ZMAsset*) value {
  resultArticle.hasImage = YES;
  resultArticle.image = value;
  return self;
}
- (ZMArticleBuilder*) setImageBuilder:(ZMAssetBuilder*) builderForValue {
  return [self setImage:[builderForValue build]];
}
- (ZMArticleBuilder*) mergeImage:(ZMAsset*) value {
  if (resultArticle.hasImage &&
      resultArticle.image != [ZMAsset defaultInstance]) {
    resultArticle.image =
      [[[ZMAsset builderWithPrototype:resultArticle.image] mergeFrom:value] buildPartial];
  } else {
    resultArticle.image = value;
  }
  resultArticle.hasImage = YES;
  return self;
}
- (ZMArticleBuilder*) clearImage {
  resultArticle.hasImage = NO;
  resultArticle.image = [ZMAsset defaultInstance];
  return self;
}
@end

@interface ZMMention ()
@property SInt32 start;
@property SInt32 length;
@property (strong) NSString* userId;
@end

@implementation ZMMention

- (BOOL) hasStart {
  return !!hasStart_;
}
- (void) setHasStart:(BOOL) _value_ {
  hasStart_ = !!_value_;
}
@synthesize start;
- (BOOL) hasLength {
  return !!hasLength_;
}
- (void) setHasLength:(BOOL) _value_ {
  hasLength_ = !!_value_;
}
@synthesize length;
- (BOOL) hasUserId {
  return !!hasUserId_;
}
- (void) setHasUserId:(BOOL) _value_ {
  hasUserId_ = !!_value_;
}
@synthesize userId;
- (instancetype) init {
  if ((self = [super init])) {
    self.start = 0;
    self.length = 0;
    self.userId = @"";
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
  if (!self.hasStart) {
    return NO;
  }
  if (!self.hasLength) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasStart) {
    [output writeInt32:1 value:self.start];
  }
  if (self.hasLength) {
    [output writeInt32:2 value:self.length];
  }
  if (self.hasUserId) {
    [output writeString:3 value:self.userId];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasStart) {
    size_ += computeInt32Size(1, self.start);
  }
  if (self.hasLength) {
    size_ += computeInt32Size(2, self.length);
  }
  if (self.hasUserId) {
    size_ += computeStringSize(3, self.userId);
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
  if (self.hasStart) {
    [output appendFormat:@"%@%@: %@\n", indent, @"start", [NSNumber numberWithInteger:self.start]];
  }
  if (self.hasLength) {
    [output appendFormat:@"%@%@: %@\n", indent, @"length", [NSNumber numberWithInteger:self.length]];
  }
  if (self.hasUserId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"userId", self.userId];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasStart) {
    [dictionary setObject: [NSNumber numberWithInteger:self.start] forKey: @"start"];
  }
  if (self.hasLength) {
    [dictionary setObject: [NSNumber numberWithInteger:self.length] forKey: @"length"];
  }
  if (self.hasUserId) {
    [dictionary setObject: self.userId forKey: @"userId"];
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
      self.hasStart == otherMessage.hasStart &&
      (!self.hasStart || self.start == otherMessage.start) &&
      self.hasLength == otherMessage.hasLength &&
      (!self.hasLength || self.length == otherMessage.length) &&
      self.hasUserId == otherMessage.hasUserId &&
      (!self.hasUserId || [self.userId isEqual:otherMessage.userId]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasStart) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.start] hash];
  }
  if (self.hasLength) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.length] hash];
  }
  if (self.hasUserId) {
    hashCode = hashCode * 31 + [self.userId hash];
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
  if (other.hasStart) {
    [self setStart:other.start];
  }
  if (other.hasLength) {
    [self setLength:other.length];
  }
  if (other.hasUserId) {
    [self setUserId:other.userId];
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
      case 8: {
        [self setStart:[input readInt32]];
        break;
      }
      case 16: {
        [self setLength:[input readInt32]];
        break;
      }
      case 26: {
        [self setUserId:[input readString]];
        break;
      }
    }
  }
}
- (BOOL) hasStart {
  return resultMention.hasStart;
}
- (SInt32) start {
  return resultMention.start;
}
- (ZMMentionBuilder*) setStart:(SInt32) value {
  resultMention.hasStart = YES;
  resultMention.start = value;
  return self;
}
- (ZMMentionBuilder*) clearStart {
  resultMention.hasStart = NO;
  resultMention.start = 0;
  return self;
}
- (BOOL) hasLength {
  return resultMention.hasLength;
}
- (SInt32) length {
  return resultMention.length;
}
- (ZMMentionBuilder*) setLength:(SInt32) value {
  resultMention.hasLength = YES;
  resultMention.length = value;
  return self;
}
- (ZMMentionBuilder*) clearLength {
  resultMention.hasLength = NO;
  resultMention.length = 0;
  return self;
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

@interface ZMMessageHide ()
@property (strong) NSString* conversationId;
@property (strong) NSString* messageId;
@end

@implementation ZMMessageHide

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
static ZMMessageHide* defaultZMMessageHideInstance = nil;
+ (void) initialize {
  if (self == [ZMMessageHide class]) {
    defaultZMMessageHideInstance = [[ZMMessageHide alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMMessageHideInstance;
}
- (instancetype) defaultInstance {
  return defaultZMMessageHideInstance;
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
+ (ZMMessageHide*) parseFromData:(NSData*) data {
  return (ZMMessageHide*)[[[ZMMessageHide builder] mergeFromData:data] build];
}
+ (ZMMessageHide*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMessageHide*)[[[ZMMessageHide builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMMessageHide*) parseFromInputStream:(NSInputStream*) input {
  return (ZMMessageHide*)[[[ZMMessageHide builder] mergeFromInputStream:input] build];
}
+ (ZMMessageHide*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMessageHide*)[[[ZMMessageHide builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMMessageHide*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMMessageHide*)[[[ZMMessageHide builder] mergeFromCodedInputStream:input] build];
}
+ (ZMMessageHide*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMessageHide*)[[[ZMMessageHide builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMMessageHideBuilder*) builder {
  return [[ZMMessageHideBuilder alloc] init];
}
+ (ZMMessageHideBuilder*) builderWithPrototype:(ZMMessageHide*) prototype {
  return [[ZMMessageHide builder] mergeFrom:prototype];
}
- (ZMMessageHideBuilder*) builder {
  return [ZMMessageHide builder];
}
- (ZMMessageHideBuilder*) toBuilder {
  return [ZMMessageHide builderWithPrototype:self];
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
  if (![other isKindOfClass:[ZMMessageHide class]]) {
    return NO;
  }
  ZMMessageHide *otherMessage = other;
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

@interface ZMMessageHideBuilder()
@property (strong) ZMMessageHide* resultMessageHide;
@end

@implementation ZMMessageHideBuilder
@synthesize resultMessageHide;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultMessageHide = [[ZMMessageHide alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultMessageHide;
}
- (ZMMessageHideBuilder*) clear {
  self.resultMessageHide = [[ZMMessageHide alloc] init];
  return self;
}
- (ZMMessageHideBuilder*) clone {
  return [ZMMessageHide builderWithPrototype:resultMessageHide];
}
- (ZMMessageHide*) defaultInstance {
  return [ZMMessageHide defaultInstance];
}
- (ZMMessageHide*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMMessageHide*) buildPartial {
  ZMMessageHide* returnMe = resultMessageHide;
  self.resultMessageHide = nil;
  return returnMe;
}
- (ZMMessageHideBuilder*) mergeFrom:(ZMMessageHide*) other {
  if (other == [ZMMessageHide defaultInstance]) {
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
- (ZMMessageHideBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMMessageHideBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
  return resultMessageHide.hasConversationId;
}
- (NSString*) conversationId {
  return resultMessageHide.conversationId;
}
- (ZMMessageHideBuilder*) setConversationId:(NSString*) value {
  resultMessageHide.hasConversationId = YES;
  resultMessageHide.conversationId = value;
  return self;
}
- (ZMMessageHideBuilder*) clearConversationId {
  resultMessageHide.hasConversationId = NO;
  resultMessageHide.conversationId = @"";
  return self;
}
- (BOOL) hasMessageId {
  return resultMessageHide.hasMessageId;
}
- (NSString*) messageId {
  return resultMessageHide.messageId;
}
- (ZMMessageHideBuilder*) setMessageId:(NSString*) value {
  resultMessageHide.hasMessageId = YES;
  resultMessageHide.messageId = value;
  return self;
}
- (ZMMessageHideBuilder*) clearMessageId {
  resultMessageHide.hasMessageId = NO;
  resultMessageHide.messageId = @"";
  return self;
}
@end

@interface ZMMessageDelete ()
@property (strong) NSString* messageId;
@end

@implementation ZMMessageDelete

- (BOOL) hasMessageId {
  return !!hasMessageId_;
}
- (void) setHasMessageId:(BOOL) _value_ {
  hasMessageId_ = !!_value_;
}
@synthesize messageId;
- (instancetype) init {
  if ((self = [super init])) {
    self.messageId = @"";
  }
  return self;
}
static ZMMessageDelete* defaultZMMessageDeleteInstance = nil;
+ (void) initialize {
  if (self == [ZMMessageDelete class]) {
    defaultZMMessageDeleteInstance = [[ZMMessageDelete alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMMessageDeleteInstance;
}
- (instancetype) defaultInstance {
  return defaultZMMessageDeleteInstance;
}
- (BOOL) isInitialized {
  if (!self.hasMessageId) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasMessageId) {
    [output writeString:1 value:self.messageId];
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
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMMessageDelete*) parseFromData:(NSData*) data {
  return (ZMMessageDelete*)[[[ZMMessageDelete builder] mergeFromData:data] build];
}
+ (ZMMessageDelete*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMessageDelete*)[[[ZMMessageDelete builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMMessageDelete*) parseFromInputStream:(NSInputStream*) input {
  return (ZMMessageDelete*)[[[ZMMessageDelete builder] mergeFromInputStream:input] build];
}
+ (ZMMessageDelete*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMessageDelete*)[[[ZMMessageDelete builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMMessageDelete*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMMessageDelete*)[[[ZMMessageDelete builder] mergeFromCodedInputStream:input] build];
}
+ (ZMMessageDelete*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMessageDelete*)[[[ZMMessageDelete builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMMessageDeleteBuilder*) builder {
  return [[ZMMessageDeleteBuilder alloc] init];
}
+ (ZMMessageDeleteBuilder*) builderWithPrototype:(ZMMessageDelete*) prototype {
  return [[ZMMessageDelete builder] mergeFrom:prototype];
}
- (ZMMessageDeleteBuilder*) builder {
  return [ZMMessageDelete builder];
}
- (ZMMessageDeleteBuilder*) toBuilder {
  return [ZMMessageDelete builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasMessageId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"messageId", self.messageId];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasMessageId) {
    [dictionary setObject: self.messageId forKey: @"messageId"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMMessageDelete class]]) {
    return NO;
  }
  ZMMessageDelete *otherMessage = other;
  return
      self.hasMessageId == otherMessage.hasMessageId &&
      (!self.hasMessageId || [self.messageId isEqual:otherMessage.messageId]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasMessageId) {
    hashCode = hashCode * 31 + [self.messageId hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMMessageDeleteBuilder()
@property (strong) ZMMessageDelete* resultMessageDelete;
@end

@implementation ZMMessageDeleteBuilder
@synthesize resultMessageDelete;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultMessageDelete = [[ZMMessageDelete alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultMessageDelete;
}
- (ZMMessageDeleteBuilder*) clear {
  self.resultMessageDelete = [[ZMMessageDelete alloc] init];
  return self;
}
- (ZMMessageDeleteBuilder*) clone {
  return [ZMMessageDelete builderWithPrototype:resultMessageDelete];
}
- (ZMMessageDelete*) defaultInstance {
  return [ZMMessageDelete defaultInstance];
}
- (ZMMessageDelete*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMMessageDelete*) buildPartial {
  ZMMessageDelete* returnMe = resultMessageDelete;
  self.resultMessageDelete = nil;
  return returnMe;
}
- (ZMMessageDeleteBuilder*) mergeFrom:(ZMMessageDelete*) other {
  if (other == [ZMMessageDelete defaultInstance]) {
    return self;
  }
  if (other.hasMessageId) {
    [self setMessageId:other.messageId];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMMessageDeleteBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMMessageDeleteBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
    }
  }
}
- (BOOL) hasMessageId {
  return resultMessageDelete.hasMessageId;
}
- (NSString*) messageId {
  return resultMessageDelete.messageId;
}
- (ZMMessageDeleteBuilder*) setMessageId:(NSString*) value {
  resultMessageDelete.hasMessageId = YES;
  resultMessageDelete.messageId = value;
  return self;
}
- (ZMMessageDeleteBuilder*) clearMessageId {
  resultMessageDelete.hasMessageId = NO;
  resultMessageDelete.messageId = @"";
  return self;
}
@end

@interface ZMMessageEdit ()
@property (strong) NSString* replacingMessageId;
@property (strong) ZMText* text;
@property (strong) ZMComposite* composite;
@end

@implementation ZMMessageEdit

- (BOOL) hasReplacingMessageId {
  return !!hasReplacingMessageId_;
}
- (void) setHasReplacingMessageId:(BOOL) _value_ {
  hasReplacingMessageId_ = !!_value_;
}
@synthesize replacingMessageId;
- (BOOL) hasText {
  return !!hasText_;
}
- (void) setHasText:(BOOL) _value_ {
  hasText_ = !!_value_;
}
@synthesize text;
- (BOOL) hasComposite {
  return !!hasComposite_;
}
- (void) setHasComposite:(BOOL) _value_ {
  hasComposite_ = !!_value_;
}
@synthesize composite;
- (instancetype) init {
  if ((self = [super init])) {
    self.replacingMessageId = @"";
    self.text = [ZMText defaultInstance];
    self.composite = [ZMComposite defaultInstance];
  }
  return self;
}
static ZMMessageEdit* defaultZMMessageEditInstance = nil;
+ (void) initialize {
  if (self == [ZMMessageEdit class]) {
    defaultZMMessageEditInstance = [[ZMMessageEdit alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMMessageEditInstance;
}
- (instancetype) defaultInstance {
  return defaultZMMessageEditInstance;
}
- (BOOL) isInitialized {
  if (!self.hasReplacingMessageId) {
    return NO;
  }
  if (self.hasText) {
    if (!self.text.isInitialized) {
      return NO;
    }
  }
  if (self.hasComposite) {
    if (!self.composite.isInitialized) {
      return NO;
    }
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasReplacingMessageId) {
    [output writeString:1 value:self.replacingMessageId];
  }
  if (self.hasText) {
    [output writeMessage:2 value:self.text];
  }
  if (self.hasComposite) {
    [output writeMessage:3 value:self.composite];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasReplacingMessageId) {
    size_ += computeStringSize(1, self.replacingMessageId);
  }
  if (self.hasText) {
    size_ += computeMessageSize(2, self.text);
  }
  if (self.hasComposite) {
    size_ += computeMessageSize(3, self.composite);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMMessageEdit*) parseFromData:(NSData*) data {
  return (ZMMessageEdit*)[[[ZMMessageEdit builder] mergeFromData:data] build];
}
+ (ZMMessageEdit*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMessageEdit*)[[[ZMMessageEdit builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMMessageEdit*) parseFromInputStream:(NSInputStream*) input {
  return (ZMMessageEdit*)[[[ZMMessageEdit builder] mergeFromInputStream:input] build];
}
+ (ZMMessageEdit*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMessageEdit*)[[[ZMMessageEdit builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMMessageEdit*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMMessageEdit*)[[[ZMMessageEdit builder] mergeFromCodedInputStream:input] build];
}
+ (ZMMessageEdit*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMMessageEdit*)[[[ZMMessageEdit builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMMessageEditBuilder*) builder {
  return [[ZMMessageEditBuilder alloc] init];
}
+ (ZMMessageEditBuilder*) builderWithPrototype:(ZMMessageEdit*) prototype {
  return [[ZMMessageEdit builder] mergeFrom:prototype];
}
- (ZMMessageEditBuilder*) builder {
  return [ZMMessageEdit builder];
}
- (ZMMessageEditBuilder*) toBuilder {
  return [ZMMessageEdit builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasReplacingMessageId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"replacingMessageId", self.replacingMessageId];
  }
  if (self.hasText) {
    [output appendFormat:@"%@%@ {\n", indent, @"text"];
    [self.text writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasComposite) {
    [output appendFormat:@"%@%@ {\n", indent, @"composite"];
    [self.composite writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasReplacingMessageId) {
    [dictionary setObject: self.replacingMessageId forKey: @"replacingMessageId"];
  }
  if (self.hasText) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.text storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"text"];
  }
  if (self.hasComposite) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.composite storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"composite"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMMessageEdit class]]) {
    return NO;
  }
  ZMMessageEdit *otherMessage = other;
  return
      self.hasReplacingMessageId == otherMessage.hasReplacingMessageId &&
      (!self.hasReplacingMessageId || [self.replacingMessageId isEqual:otherMessage.replacingMessageId]) &&
      self.hasText == otherMessage.hasText &&
      (!self.hasText || [self.text isEqual:otherMessage.text]) &&
      self.hasComposite == otherMessage.hasComposite &&
      (!self.hasComposite || [self.composite isEqual:otherMessage.composite]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasReplacingMessageId) {
    hashCode = hashCode * 31 + [self.replacingMessageId hash];
  }
  if (self.hasText) {
    hashCode = hashCode * 31 + [self.text hash];
  }
  if (self.hasComposite) {
    hashCode = hashCode * 31 + [self.composite hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMMessageEditBuilder()
@property (strong) ZMMessageEdit* resultMessageEdit;
@end

@implementation ZMMessageEditBuilder
@synthesize resultMessageEdit;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultMessageEdit = [[ZMMessageEdit alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultMessageEdit;
}
- (ZMMessageEditBuilder*) clear {
  self.resultMessageEdit = [[ZMMessageEdit alloc] init];
  return self;
}
- (ZMMessageEditBuilder*) clone {
  return [ZMMessageEdit builderWithPrototype:resultMessageEdit];
}
- (ZMMessageEdit*) defaultInstance {
  return [ZMMessageEdit defaultInstance];
}
- (ZMMessageEdit*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMMessageEdit*) buildPartial {
  ZMMessageEdit* returnMe = resultMessageEdit;
  self.resultMessageEdit = nil;
  return returnMe;
}
- (ZMMessageEditBuilder*) mergeFrom:(ZMMessageEdit*) other {
  if (other == [ZMMessageEdit defaultInstance]) {
    return self;
  }
  if (other.hasReplacingMessageId) {
    [self setReplacingMessageId:other.replacingMessageId];
  }
  if (other.hasText) {
    [self mergeText:other.text];
  }
  if (other.hasComposite) {
    [self mergeComposite:other.composite];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMMessageEditBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMMessageEditBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setReplacingMessageId:[input readString]];
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
        ZMCompositeBuilder* subBuilder = [ZMComposite builder];
        if (self.hasComposite) {
          [subBuilder mergeFrom:self.composite];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setComposite:[subBuilder buildPartial]];
        break;
      }
    }
  }
}
- (BOOL) hasReplacingMessageId {
  return resultMessageEdit.hasReplacingMessageId;
}
- (NSString*) replacingMessageId {
  return resultMessageEdit.replacingMessageId;
}
- (ZMMessageEditBuilder*) setReplacingMessageId:(NSString*) value {
  resultMessageEdit.hasReplacingMessageId = YES;
  resultMessageEdit.replacingMessageId = value;
  return self;
}
- (ZMMessageEditBuilder*) clearReplacingMessageId {
  resultMessageEdit.hasReplacingMessageId = NO;
  resultMessageEdit.replacingMessageId = @"";
  return self;
}
- (BOOL) hasText {
  return resultMessageEdit.hasText;
}
- (ZMText*) text {
  return resultMessageEdit.text;
}
- (ZMMessageEditBuilder*) setText:(ZMText*) value {
  resultMessageEdit.hasText = YES;
  resultMessageEdit.text = value;
  return self;
}
- (ZMMessageEditBuilder*) setTextBuilder:(ZMTextBuilder*) builderForValue {
  return [self setText:[builderForValue build]];
}
- (ZMMessageEditBuilder*) mergeText:(ZMText*) value {
  if (resultMessageEdit.hasText &&
      resultMessageEdit.text != [ZMText defaultInstance]) {
    resultMessageEdit.text =
      [[[ZMText builderWithPrototype:resultMessageEdit.text] mergeFrom:value] buildPartial];
  } else {
    resultMessageEdit.text = value;
  }
  resultMessageEdit.hasText = YES;
  return self;
}
- (ZMMessageEditBuilder*) clearText {
  resultMessageEdit.hasText = NO;
  resultMessageEdit.text = [ZMText defaultInstance];
  return self;
}
- (BOOL) hasComposite {
  return resultMessageEdit.hasComposite;
}
- (ZMComposite*) composite {
  return resultMessageEdit.composite;
}
- (ZMMessageEditBuilder*) setComposite:(ZMComposite*) value {
  resultMessageEdit.hasComposite = YES;
  resultMessageEdit.composite = value;
  return self;
}
- (ZMMessageEditBuilder*) setCompositeBuilder:(ZMCompositeBuilder*) builderForValue {
  return [self setComposite:[builderForValue build]];
}
- (ZMMessageEditBuilder*) mergeComposite:(ZMComposite*) value {
  if (resultMessageEdit.hasComposite &&
      resultMessageEdit.composite != [ZMComposite defaultInstance]) {
    resultMessageEdit.composite =
      [[[ZMComposite builderWithPrototype:resultMessageEdit.composite] mergeFrom:value] buildPartial];
  } else {
    resultMessageEdit.composite = value;
  }
  resultMessageEdit.hasComposite = YES;
  return self;
}
- (ZMMessageEditBuilder*) clearComposite {
  resultMessageEdit.hasComposite = NO;
  resultMessageEdit.composite = [ZMComposite defaultInstance];
  return self;
}
@end

@interface ZMQuote ()
@property (strong) NSString* quotedMessageId;
@property (strong) NSData* quotedMessageSha256;
@end

@implementation ZMQuote

- (BOOL) hasQuotedMessageId {
  return !!hasQuotedMessageId_;
}
- (void) setHasQuotedMessageId:(BOOL) _value_ {
  hasQuotedMessageId_ = !!_value_;
}
@synthesize quotedMessageId;
- (BOOL) hasQuotedMessageSha256 {
  return !!hasQuotedMessageSha256_;
}
- (void) setHasQuotedMessageSha256:(BOOL) _value_ {
  hasQuotedMessageSha256_ = !!_value_;
}
@synthesize quotedMessageSha256;
- (instancetype) init {
  if ((self = [super init])) {
    self.quotedMessageId = @"";
    self.quotedMessageSha256 = [NSData data];
  }
  return self;
}
static ZMQuote* defaultZMQuoteInstance = nil;
+ (void) initialize {
  if (self == [ZMQuote class]) {
    defaultZMQuoteInstance = [[ZMQuote alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMQuoteInstance;
}
- (instancetype) defaultInstance {
  return defaultZMQuoteInstance;
}
- (BOOL) isInitialized {
  if (!self.hasQuotedMessageId) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasQuotedMessageId) {
    [output writeString:1 value:self.quotedMessageId];
  }
  if (self.hasQuotedMessageSha256) {
    [output writeData:2 value:self.quotedMessageSha256];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasQuotedMessageId) {
    size_ += computeStringSize(1, self.quotedMessageId);
  }
  if (self.hasQuotedMessageSha256) {
    size_ += computeDataSize(2, self.quotedMessageSha256);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMQuote*) parseFromData:(NSData*) data {
  return (ZMQuote*)[[[ZMQuote builder] mergeFromData:data] build];
}
+ (ZMQuote*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMQuote*)[[[ZMQuote builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMQuote*) parseFromInputStream:(NSInputStream*) input {
  return (ZMQuote*)[[[ZMQuote builder] mergeFromInputStream:input] build];
}
+ (ZMQuote*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMQuote*)[[[ZMQuote builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMQuote*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMQuote*)[[[ZMQuote builder] mergeFromCodedInputStream:input] build];
}
+ (ZMQuote*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMQuote*)[[[ZMQuote builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMQuoteBuilder*) builder {
  return [[ZMQuoteBuilder alloc] init];
}
+ (ZMQuoteBuilder*) builderWithPrototype:(ZMQuote*) prototype {
  return [[ZMQuote builder] mergeFrom:prototype];
}
- (ZMQuoteBuilder*) builder {
  return [ZMQuote builder];
}
- (ZMQuoteBuilder*) toBuilder {
  return [ZMQuote builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasQuotedMessageId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"quotedMessageId", self.quotedMessageId];
  }
  if (self.hasQuotedMessageSha256) {
    [output appendFormat:@"%@%@: %@\n", indent, @"quotedMessageSha256", self.quotedMessageSha256];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasQuotedMessageId) {
    [dictionary setObject: self.quotedMessageId forKey: @"quotedMessageId"];
  }
  if (self.hasQuotedMessageSha256) {
    [dictionary setObject: self.quotedMessageSha256 forKey: @"quotedMessageSha256"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMQuote class]]) {
    return NO;
  }
  ZMQuote *otherMessage = other;
  return
      self.hasQuotedMessageId == otherMessage.hasQuotedMessageId &&
      (!self.hasQuotedMessageId || [self.quotedMessageId isEqual:otherMessage.quotedMessageId]) &&
      self.hasQuotedMessageSha256 == otherMessage.hasQuotedMessageSha256 &&
      (!self.hasQuotedMessageSha256 || [self.quotedMessageSha256 isEqual:otherMessage.quotedMessageSha256]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasQuotedMessageId) {
    hashCode = hashCode * 31 + [self.quotedMessageId hash];
  }
  if (self.hasQuotedMessageSha256) {
    hashCode = hashCode * 31 + [self.quotedMessageSha256 hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMQuoteBuilder()
@property (strong) ZMQuote* resultQuote;
@end

@implementation ZMQuoteBuilder
@synthesize resultQuote;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultQuote = [[ZMQuote alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultQuote;
}
- (ZMQuoteBuilder*) clear {
  self.resultQuote = [[ZMQuote alloc] init];
  return self;
}
- (ZMQuoteBuilder*) clone {
  return [ZMQuote builderWithPrototype:resultQuote];
}
- (ZMQuote*) defaultInstance {
  return [ZMQuote defaultInstance];
}
- (ZMQuote*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMQuote*) buildPartial {
  ZMQuote* returnMe = resultQuote;
  self.resultQuote = nil;
  return returnMe;
}
- (ZMQuoteBuilder*) mergeFrom:(ZMQuote*) other {
  if (other == [ZMQuote defaultInstance]) {
    return self;
  }
  if (other.hasQuotedMessageId) {
    [self setQuotedMessageId:other.quotedMessageId];
  }
  if (other.hasQuotedMessageSha256) {
    [self setQuotedMessageSha256:other.quotedMessageSha256];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMQuoteBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMQuoteBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setQuotedMessageId:[input readString]];
        break;
      }
      case 18: {
        [self setQuotedMessageSha256:[input readData]];
        break;
      }
    }
  }
}
- (BOOL) hasQuotedMessageId {
  return resultQuote.hasQuotedMessageId;
}
- (NSString*) quotedMessageId {
  return resultQuote.quotedMessageId;
}
- (ZMQuoteBuilder*) setQuotedMessageId:(NSString*) value {
  resultQuote.hasQuotedMessageId = YES;
  resultQuote.quotedMessageId = value;
  return self;
}
- (ZMQuoteBuilder*) clearQuotedMessageId {
  resultQuote.hasQuotedMessageId = NO;
  resultQuote.quotedMessageId = @"";
  return self;
}
- (BOOL) hasQuotedMessageSha256 {
  return resultQuote.hasQuotedMessageSha256;
}
- (NSData*) quotedMessageSha256 {
  return resultQuote.quotedMessageSha256;
}
- (ZMQuoteBuilder*) setQuotedMessageSha256:(NSData*) value {
  resultQuote.hasQuotedMessageSha256 = YES;
  resultQuote.quotedMessageSha256 = value;
  return self;
}
- (ZMQuoteBuilder*) clearQuotedMessageSha256 {
  resultQuote.hasQuotedMessageSha256 = NO;
  resultQuote.quotedMessageSha256 = [NSData data];
  return self;
}
@end

@interface ZMConfirmation ()
@property ZMConfirmationType type;
@property (strong) NSString* firstMessageId;
@property (strong) NSMutableArray * moreMessageIdsArray;
@end

@implementation ZMConfirmation

- (BOOL) hasType {
  return !!hasType_;
}
- (void) setHasType:(BOOL) _value_ {
  hasType_ = !!_value_;
}
@synthesize type;
- (BOOL) hasFirstMessageId {
  return !!hasFirstMessageId_;
}
- (void) setHasFirstMessageId:(BOOL) _value_ {
  hasFirstMessageId_ = !!_value_;
}
@synthesize firstMessageId;
@synthesize moreMessageIdsArray;
@dynamic moreMessageIds;
- (instancetype) init {
  if ((self = [super init])) {
    self.type = ZMConfirmationTypeDELIVERED;
    self.firstMessageId = @"";
  }
  return self;
}
static ZMConfirmation* defaultZMConfirmationInstance = nil;
+ (void) initialize {
  if (self == [ZMConfirmation class]) {
    defaultZMConfirmationInstance = [[ZMConfirmation alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMConfirmationInstance;
}
- (instancetype) defaultInstance {
  return defaultZMConfirmationInstance;
}
- (NSArray *)moreMessageIds {
  return moreMessageIdsArray;
}
- (NSString*)moreMessageIdsAtIndex:(NSUInteger)index {
  return [moreMessageIdsArray objectAtIndex:index];
}
- (BOOL) isInitialized {
  if (!self.hasType) {
    return NO;
  }
  if (!self.hasFirstMessageId) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasFirstMessageId) {
    [output writeString:1 value:self.firstMessageId];
  }
  if (self.hasType) {
    [output writeEnum:2 value:self.type];
  }
  [self.moreMessageIdsArray enumerateObjectsUsingBlock:^(NSString *element, NSUInteger idx, BOOL *stop) {
    [output writeString:3 value:element];
  }];
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasFirstMessageId) {
    size_ += computeStringSize(1, self.firstMessageId);
  }
  if (self.hasType) {
    size_ += computeEnumSize(2, self.type);
  }
  {
    __block SInt32 dataSize = 0;
    const NSUInteger count = self.moreMessageIdsArray.count;
    [self.moreMessageIdsArray enumerateObjectsUsingBlock:^(NSString *element, NSUInteger idx, BOOL *stop) {
      dataSize += computeStringSizeNoTag(element);
    }];
    size_ += dataSize;
    size_ += (SInt32)(1 * count);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMConfirmation*) parseFromData:(NSData*) data {
  return (ZMConfirmation*)[[[ZMConfirmation builder] mergeFromData:data] build];
}
+ (ZMConfirmation*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMConfirmation*)[[[ZMConfirmation builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMConfirmation*) parseFromInputStream:(NSInputStream*) input {
  return (ZMConfirmation*)[[[ZMConfirmation builder] mergeFromInputStream:input] build];
}
+ (ZMConfirmation*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMConfirmation*)[[[ZMConfirmation builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMConfirmation*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMConfirmation*)[[[ZMConfirmation builder] mergeFromCodedInputStream:input] build];
}
+ (ZMConfirmation*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMConfirmation*)[[[ZMConfirmation builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMConfirmationBuilder*) builder {
  return [[ZMConfirmationBuilder alloc] init];
}
+ (ZMConfirmationBuilder*) builderWithPrototype:(ZMConfirmation*) prototype {
  return [[ZMConfirmation builder] mergeFrom:prototype];
}
- (ZMConfirmationBuilder*) builder {
  return [ZMConfirmation builder];
}
- (ZMConfirmationBuilder*) toBuilder {
  return [ZMConfirmation builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasFirstMessageId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"firstMessageId", self.firstMessageId];
  }
  if (self.hasType) {
    [output appendFormat:@"%@%@: %@\n", indent, @"type", NSStringFromZMConfirmationType(self.type)];
  }
  [self.moreMessageIdsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    [output appendFormat:@"%@%@: %@\n", indent, @"moreMessageIds", obj];
  }];
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasFirstMessageId) {
    [dictionary setObject: self.firstMessageId forKey: @"firstMessageId"];
  }
  if (self.hasType) {
    [dictionary setObject: @(self.type) forKey: @"type"];
  }
  [dictionary setObject:self.moreMessageIds forKey: @"moreMessageIds"];
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMConfirmation class]]) {
    return NO;
  }
  ZMConfirmation *otherMessage = other;
  return
      self.hasFirstMessageId == otherMessage.hasFirstMessageId &&
      (!self.hasFirstMessageId || [self.firstMessageId isEqual:otherMessage.firstMessageId]) &&
      self.hasType == otherMessage.hasType &&
      (!self.hasType || self.type == otherMessage.type) &&
      [self.moreMessageIdsArray isEqualToArray:otherMessage.moreMessageIdsArray] &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasFirstMessageId) {
    hashCode = hashCode * 31 + [self.firstMessageId hash];
  }
  if (self.hasType) {
    hashCode = hashCode * 31 + self.type;
  }
  [self.moreMessageIdsArray enumerateObjectsUsingBlock:^(NSString *element, NSUInteger idx, BOOL *stop) {
    hashCode = hashCode * 31 + [element hash];
  }];
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

BOOL ZMConfirmationTypeIsValidValue(ZMConfirmationType value) {
  switch (value) {
    case ZMConfirmationTypeDELIVERED:
    case ZMConfirmationTypeREAD:
      return YES;
    default:
      return NO;
  }
}
NSString *NSStringFromZMConfirmationType(ZMConfirmationType value) {
  switch (value) {
    case ZMConfirmationTypeDELIVERED:
      return @"ZMConfirmationTypeDELIVERED";
    case ZMConfirmationTypeREAD:
      return @"ZMConfirmationTypeREAD";
    default:
      return nil;
  }
}

@interface ZMConfirmationBuilder()
@property (strong) ZMConfirmation* resultConfirmation;
@end

@implementation ZMConfirmationBuilder
@synthesize resultConfirmation;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultConfirmation = [[ZMConfirmation alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultConfirmation;
}
- (ZMConfirmationBuilder*) clear {
  self.resultConfirmation = [[ZMConfirmation alloc] init];
  return self;
}
- (ZMConfirmationBuilder*) clone {
  return [ZMConfirmation builderWithPrototype:resultConfirmation];
}
- (ZMConfirmation*) defaultInstance {
  return [ZMConfirmation defaultInstance];
}
- (ZMConfirmation*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMConfirmation*) buildPartial {
  ZMConfirmation* returnMe = resultConfirmation;
  self.resultConfirmation = nil;
  return returnMe;
}
- (ZMConfirmationBuilder*) mergeFrom:(ZMConfirmation*) other {
  if (other == [ZMConfirmation defaultInstance]) {
    return self;
  }
  if (other.hasType) {
    [self setType:other.type];
  }
  if (other.hasFirstMessageId) {
    [self setFirstMessageId:other.firstMessageId];
  }
  if (other.moreMessageIdsArray.count > 0) {
    if (resultConfirmation.moreMessageIdsArray == nil) {
      resultConfirmation.moreMessageIdsArray = [[NSMutableArray alloc] initWithArray:other.moreMessageIdsArray];
    } else {
      [resultConfirmation.moreMessageIdsArray addObjectsFromArray:other.moreMessageIdsArray];
    }
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMConfirmationBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMConfirmationBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setFirstMessageId:[input readString]];
        break;
      }
      case 16: {
        ZMConfirmationType value = (ZMConfirmationType)[input readEnum];
        if (ZMConfirmationTypeIsValidValue(value)) {
          [self setType:value];
        } else {
          [unknownFields mergeVarintField:2 value:value];
        }
        break;
      }
      case 26: {
        [self addMoreMessageIds:[input readString]];
        break;
      }
    }
  }
}
- (BOOL) hasType {
  return resultConfirmation.hasType;
}
- (ZMConfirmationType) type {
  return resultConfirmation.type;
}
- (ZMConfirmationBuilder*) setType:(ZMConfirmationType) value {
  resultConfirmation.hasType = YES;
  resultConfirmation.type = value;
  return self;
}
- (ZMConfirmationBuilder*) clearType {
  resultConfirmation.hasType = NO;
  resultConfirmation.type = ZMConfirmationTypeDELIVERED;
  return self;
}
- (BOOL) hasFirstMessageId {
  return resultConfirmation.hasFirstMessageId;
}
- (NSString*) firstMessageId {
  return resultConfirmation.firstMessageId;
}
- (ZMConfirmationBuilder*) setFirstMessageId:(NSString*) value {
  resultConfirmation.hasFirstMessageId = YES;
  resultConfirmation.firstMessageId = value;
  return self;
}
- (ZMConfirmationBuilder*) clearFirstMessageId {
  resultConfirmation.hasFirstMessageId = NO;
  resultConfirmation.firstMessageId = @"";
  return self;
}
- (NSMutableArray *)moreMessageIds {
  return resultConfirmation.moreMessageIdsArray;
}
- (NSString*)moreMessageIdsAtIndex:(NSUInteger)index {
  return [resultConfirmation moreMessageIdsAtIndex:index];
}
- (ZMConfirmationBuilder *)addMoreMessageIds:(NSString*)value {
  if (resultConfirmation.moreMessageIdsArray == nil) {
    resultConfirmation.moreMessageIdsArray = [[NSMutableArray alloc]init];
  }
  [resultConfirmation.moreMessageIdsArray addObject:value];
  return self;
}
- (ZMConfirmationBuilder *)setMoreMessageIdsArray:(NSArray *)array {
  resultConfirmation.moreMessageIdsArray = [[NSMutableArray alloc] initWithArray:array];
  return self;
}
- (ZMConfirmationBuilder *)clearMoreMessageIds {
  resultConfirmation.moreMessageIdsArray = nil;
  return self;
}
@end

@interface ZMLocation ()
@property Float32 longitude;
@property Float32 latitude;
@property (strong) NSString* name;
@property SInt32 zoom;
@property BOOL expectsReadConfirmation;
@property ZMLegalHoldStatus legalHoldStatus;
@end

@implementation ZMLocation

- (BOOL) hasLongitude {
  return !!hasLongitude_;
}
- (void) setHasLongitude:(BOOL) _value_ {
  hasLongitude_ = !!_value_;
}
@synthesize longitude;
- (BOOL) hasLatitude {
  return !!hasLatitude_;
}
- (void) setHasLatitude:(BOOL) _value_ {
  hasLatitude_ = !!_value_;
}
@synthesize latitude;
- (BOOL) hasName {
  return !!hasName_;
}
- (void) setHasName:(BOOL) _value_ {
  hasName_ = !!_value_;
}
@synthesize name;
- (BOOL) hasZoom {
  return !!hasZoom_;
}
- (void) setHasZoom:(BOOL) _value_ {
  hasZoom_ = !!_value_;
}
@synthesize zoom;
- (BOOL) hasExpectsReadConfirmation {
  return !!hasExpectsReadConfirmation_;
}
- (void) setHasExpectsReadConfirmation:(BOOL) _value_ {
  hasExpectsReadConfirmation_ = !!_value_;
}
- (BOOL) expectsReadConfirmation {
  return !!expectsReadConfirmation_;
}
- (void) setExpectsReadConfirmation:(BOOL) _value_ {
  expectsReadConfirmation_ = !!_value_;
}
- (BOOL) hasLegalHoldStatus {
  return !!hasLegalHoldStatus_;
}
- (void) setHasLegalHoldStatus:(BOOL) _value_ {
  hasLegalHoldStatus_ = !!_value_;
}
@synthesize legalHoldStatus;
- (instancetype) init {
  if ((self = [super init])) {
    self.longitude = 0;
    self.latitude = 0;
    self.name = @"";
    self.zoom = 0;
    self.expectsReadConfirmation = NO;
    self.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
  }
  return self;
}
static ZMLocation* defaultZMLocationInstance = nil;
+ (void) initialize {
  if (self == [ZMLocation class]) {
    defaultZMLocationInstance = [[ZMLocation alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMLocationInstance;
}
- (instancetype) defaultInstance {
  return defaultZMLocationInstance;
}
- (BOOL) isInitialized {
  if (!self.hasLongitude) {
    return NO;
  }
  if (!self.hasLatitude) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasLongitude) {
    [output writeFloat:1 value:self.longitude];
  }
  if (self.hasLatitude) {
    [output writeFloat:2 value:self.latitude];
  }
  if (self.hasName) {
    [output writeString:3 value:self.name];
  }
  if (self.hasZoom) {
    [output writeInt32:4 value:self.zoom];
  }
  if (self.hasExpectsReadConfirmation) {
    [output writeBool:5 value:self.expectsReadConfirmation];
  }
  if (self.hasLegalHoldStatus) {
    [output writeEnum:6 value:self.legalHoldStatus];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasLongitude) {
    size_ += computeFloatSize(1, self.longitude);
  }
  if (self.hasLatitude) {
    size_ += computeFloatSize(2, self.latitude);
  }
  if (self.hasName) {
    size_ += computeStringSize(3, self.name);
  }
  if (self.hasZoom) {
    size_ += computeInt32Size(4, self.zoom);
  }
  if (self.hasExpectsReadConfirmation) {
    size_ += computeBoolSize(5, self.expectsReadConfirmation);
  }
  if (self.hasLegalHoldStatus) {
    size_ += computeEnumSize(6, self.legalHoldStatus);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMLocation*) parseFromData:(NSData*) data {
  return (ZMLocation*)[[[ZMLocation builder] mergeFromData:data] build];
}
+ (ZMLocation*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMLocation*)[[[ZMLocation builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMLocation*) parseFromInputStream:(NSInputStream*) input {
  return (ZMLocation*)[[[ZMLocation builder] mergeFromInputStream:input] build];
}
+ (ZMLocation*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMLocation*)[[[ZMLocation builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMLocation*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMLocation*)[[[ZMLocation builder] mergeFromCodedInputStream:input] build];
}
+ (ZMLocation*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMLocation*)[[[ZMLocation builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMLocationBuilder*) builder {
  return [[ZMLocationBuilder alloc] init];
}
+ (ZMLocationBuilder*) builderWithPrototype:(ZMLocation*) prototype {
  return [[ZMLocation builder] mergeFrom:prototype];
}
- (ZMLocationBuilder*) builder {
  return [ZMLocation builder];
}
- (ZMLocationBuilder*) toBuilder {
  return [ZMLocation builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasLongitude) {
    [output appendFormat:@"%@%@: %@\n", indent, @"longitude", [NSNumber numberWithFloat:self.longitude]];
  }
  if (self.hasLatitude) {
    [output appendFormat:@"%@%@: %@\n", indent, @"latitude", [NSNumber numberWithFloat:self.latitude]];
  }
  if (self.hasName) {
    [output appendFormat:@"%@%@: %@\n", indent, @"name", self.name];
  }
  if (self.hasZoom) {
    [output appendFormat:@"%@%@: %@\n", indent, @"zoom", [NSNumber numberWithInteger:self.zoom]];
  }
  if (self.hasExpectsReadConfirmation) {
    [output appendFormat:@"%@%@: %@\n", indent, @"expectsReadConfirmation", [NSNumber numberWithBool:self.expectsReadConfirmation]];
  }
  if (self.hasLegalHoldStatus) {
    [output appendFormat:@"%@%@: %@\n", indent, @"legalHoldStatus", NSStringFromZMLegalHoldStatus(self.legalHoldStatus)];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasLongitude) {
    [dictionary setObject: [NSNumber numberWithFloat:self.longitude] forKey: @"longitude"];
  }
  if (self.hasLatitude) {
    [dictionary setObject: [NSNumber numberWithFloat:self.latitude] forKey: @"latitude"];
  }
  if (self.hasName) {
    [dictionary setObject: self.name forKey: @"name"];
  }
  if (self.hasZoom) {
    [dictionary setObject: [NSNumber numberWithInteger:self.zoom] forKey: @"zoom"];
  }
  if (self.hasExpectsReadConfirmation) {
    [dictionary setObject: [NSNumber numberWithBool:self.expectsReadConfirmation] forKey: @"expectsReadConfirmation"];
  }
  if (self.hasLegalHoldStatus) {
    [dictionary setObject: @(self.legalHoldStatus) forKey: @"legalHoldStatus"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMLocation class]]) {
    return NO;
  }
  ZMLocation *otherMessage = other;
  return
      self.hasLongitude == otherMessage.hasLongitude &&
      (!self.hasLongitude || self.longitude == otherMessage.longitude) &&
      self.hasLatitude == otherMessage.hasLatitude &&
      (!self.hasLatitude || self.latitude == otherMessage.latitude) &&
      self.hasName == otherMessage.hasName &&
      (!self.hasName || [self.name isEqual:otherMessage.name]) &&
      self.hasZoom == otherMessage.hasZoom &&
      (!self.hasZoom || self.zoom == otherMessage.zoom) &&
      self.hasExpectsReadConfirmation == otherMessage.hasExpectsReadConfirmation &&
      (!self.hasExpectsReadConfirmation || self.expectsReadConfirmation == otherMessage.expectsReadConfirmation) &&
      self.hasLegalHoldStatus == otherMessage.hasLegalHoldStatus &&
      (!self.hasLegalHoldStatus || self.legalHoldStatus == otherMessage.legalHoldStatus) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasLongitude) {
    hashCode = hashCode * 31 + [[NSNumber numberWithFloat:self.longitude] hash];
  }
  if (self.hasLatitude) {
    hashCode = hashCode * 31 + [[NSNumber numberWithFloat:self.latitude] hash];
  }
  if (self.hasName) {
    hashCode = hashCode * 31 + [self.name hash];
  }
  if (self.hasZoom) {
    hashCode = hashCode * 31 + [[NSNumber numberWithInteger:self.zoom] hash];
  }
  if (self.hasExpectsReadConfirmation) {
    hashCode = hashCode * 31 + [[NSNumber numberWithBool:self.expectsReadConfirmation] hash];
  }
  if (self.hasLegalHoldStatus) {
    hashCode = hashCode * 31 + self.legalHoldStatus;
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMLocationBuilder()
@property (strong) ZMLocation* resultLocation;
@end

@implementation ZMLocationBuilder
@synthesize resultLocation;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultLocation = [[ZMLocation alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultLocation;
}
- (ZMLocationBuilder*) clear {
  self.resultLocation = [[ZMLocation alloc] init];
  return self;
}
- (ZMLocationBuilder*) clone {
  return [ZMLocation builderWithPrototype:resultLocation];
}
- (ZMLocation*) defaultInstance {
  return [ZMLocation defaultInstance];
}
- (ZMLocation*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMLocation*) buildPartial {
  ZMLocation* returnMe = resultLocation;
  self.resultLocation = nil;
  return returnMe;
}
- (ZMLocationBuilder*) mergeFrom:(ZMLocation*) other {
  if (other == [ZMLocation defaultInstance]) {
    return self;
  }
  if (other.hasLongitude) {
    [self setLongitude:other.longitude];
  }
  if (other.hasLatitude) {
    [self setLatitude:other.latitude];
  }
  if (other.hasName) {
    [self setName:other.name];
  }
  if (other.hasZoom) {
    [self setZoom:other.zoom];
  }
  if (other.hasExpectsReadConfirmation) {
    [self setExpectsReadConfirmation:other.expectsReadConfirmation];
  }
  if (other.hasLegalHoldStatus) {
    [self setLegalHoldStatus:other.legalHoldStatus];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMLocationBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMLocationBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
      case 13: {
        [self setLongitude:[input readFloat]];
        break;
      }
      case 21: {
        [self setLatitude:[input readFloat]];
        break;
      }
      case 26: {
        [self setName:[input readString]];
        break;
      }
      case 32: {
        [self setZoom:[input readInt32]];
        break;
      }
      case 40: {
        [self setExpectsReadConfirmation:[input readBool]];
        break;
      }
      case 48: {
        ZMLegalHoldStatus value = (ZMLegalHoldStatus)[input readEnum];
        if (ZMLegalHoldStatusIsValidValue(value)) {
          [self setLegalHoldStatus:value];
        } else {
          [unknownFields mergeVarintField:6 value:value];
        }
        break;
      }
    }
  }
}
- (BOOL) hasLongitude {
  return resultLocation.hasLongitude;
}
- (Float32) longitude {
  return resultLocation.longitude;
}
- (ZMLocationBuilder*) setLongitude:(Float32) value {
  resultLocation.hasLongitude = YES;
  resultLocation.longitude = value;
  return self;
}
- (ZMLocationBuilder*) clearLongitude {
  resultLocation.hasLongitude = NO;
  resultLocation.longitude = 0;
  return self;
}
- (BOOL) hasLatitude {
  return resultLocation.hasLatitude;
}
- (Float32) latitude {
  return resultLocation.latitude;
}
- (ZMLocationBuilder*) setLatitude:(Float32) value {
  resultLocation.hasLatitude = YES;
  resultLocation.latitude = value;
  return self;
}
- (ZMLocationBuilder*) clearLatitude {
  resultLocation.hasLatitude = NO;
  resultLocation.latitude = 0;
  return self;
}
- (BOOL) hasName {
  return resultLocation.hasName;
}
- (NSString*) name {
  return resultLocation.name;
}
- (ZMLocationBuilder*) setName:(NSString*) value {
  resultLocation.hasName = YES;
  resultLocation.name = value;
  return self;
}
- (ZMLocationBuilder*) clearName {
  resultLocation.hasName = NO;
  resultLocation.name = @"";
  return self;
}
- (BOOL) hasZoom {
  return resultLocation.hasZoom;
}
- (SInt32) zoom {
  return resultLocation.zoom;
}
- (ZMLocationBuilder*) setZoom:(SInt32) value {
  resultLocation.hasZoom = YES;
  resultLocation.zoom = value;
  return self;
}
- (ZMLocationBuilder*) clearZoom {
  resultLocation.hasZoom = NO;
  resultLocation.zoom = 0;
  return self;
}
- (BOOL) hasExpectsReadConfirmation {
  return resultLocation.hasExpectsReadConfirmation;
}
- (BOOL) expectsReadConfirmation {
  return resultLocation.expectsReadConfirmation;
}
- (ZMLocationBuilder*) setExpectsReadConfirmation:(BOOL) value {
  resultLocation.hasExpectsReadConfirmation = YES;
  resultLocation.expectsReadConfirmation = value;
  return self;
}
- (ZMLocationBuilder*) clearExpectsReadConfirmation {
  resultLocation.hasExpectsReadConfirmation = NO;
  resultLocation.expectsReadConfirmation = NO;
  return self;
}
- (BOOL) hasLegalHoldStatus {
  return resultLocation.hasLegalHoldStatus;
}
- (ZMLegalHoldStatus) legalHoldStatus {
  return resultLocation.legalHoldStatus;
}
- (ZMLocationBuilder*) setLegalHoldStatus:(ZMLegalHoldStatus) value {
  resultLocation.hasLegalHoldStatus = YES;
  resultLocation.legalHoldStatus = value;
  return self;
}
- (ZMLocationBuilder*) clearLegalHoldStatus {
  resultLocation.hasLegalHoldStatus = NO;
  resultLocation.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
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
@property ZMAssetNotUploaded notUploaded;
@property (strong) ZMAssetRemoteData* uploaded;
@property (strong) ZMAssetPreview* preview;
@property BOOL expectsReadConfirmation;
@property ZMLegalHoldStatus legalHoldStatus;
@end

@implementation ZMAsset

- (BOOL) hasOriginal {
  return !!hasOriginal_;
}
- (void) setHasOriginal:(BOOL) _value_ {
  hasOriginal_ = !!_value_;
}
@synthesize original;
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
- (BOOL) hasPreview {
  return !!hasPreview_;
}
- (void) setHasPreview:(BOOL) _value_ {
  hasPreview_ = !!_value_;
}
@synthesize preview;
- (BOOL) hasExpectsReadConfirmation {
  return !!hasExpectsReadConfirmation_;
}
- (void) setHasExpectsReadConfirmation:(BOOL) _value_ {
  hasExpectsReadConfirmation_ = !!_value_;
}
- (BOOL) expectsReadConfirmation {
  return !!expectsReadConfirmation_;
}
- (void) setExpectsReadConfirmation:(BOOL) _value_ {
  expectsReadConfirmation_ = !!_value_;
}
- (BOOL) hasLegalHoldStatus {
  return !!hasLegalHoldStatus_;
}
- (void) setHasLegalHoldStatus:(BOOL) _value_ {
  hasLegalHoldStatus_ = !!_value_;
}
@synthesize legalHoldStatus;
- (instancetype) init {
  if ((self = [super init])) {
    self.original = [ZMAssetOriginal defaultInstance];
    self.notUploaded = ZMAssetNotUploadedCANCELLED;
    self.uploaded = [ZMAssetRemoteData defaultInstance];
    self.preview = [ZMAssetPreview defaultInstance];
    self.expectsReadConfirmation = NO;
    self.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
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
  if (self.hasUploaded) {
    if (!self.uploaded.isInitialized) {
      return NO;
    }
  }
  if (self.hasPreview) {
    if (!self.preview.isInitialized) {
      return NO;
    }
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasOriginal) {
    [output writeMessage:1 value:self.original];
  }
  if (self.hasNotUploaded) {
    [output writeEnum:3 value:self.notUploaded];
  }
  if (self.hasUploaded) {
    [output writeMessage:4 value:self.uploaded];
  }
  if (self.hasPreview) {
    [output writeMessage:5 value:self.preview];
  }
  if (self.hasExpectsReadConfirmation) {
    [output writeBool:6 value:self.expectsReadConfirmation];
  }
  if (self.hasLegalHoldStatus) {
    [output writeEnum:7 value:self.legalHoldStatus];
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
  if (self.hasNotUploaded) {
    size_ += computeEnumSize(3, self.notUploaded);
  }
  if (self.hasUploaded) {
    size_ += computeMessageSize(4, self.uploaded);
  }
  if (self.hasPreview) {
    size_ += computeMessageSize(5, self.preview);
  }
  if (self.hasExpectsReadConfirmation) {
    size_ += computeBoolSize(6, self.expectsReadConfirmation);
  }
  if (self.hasLegalHoldStatus) {
    size_ += computeEnumSize(7, self.legalHoldStatus);
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
  if (self.hasNotUploaded) {
    [output appendFormat:@"%@%@: %@\n", indent, @"notUploaded", NSStringFromZMAssetNotUploaded(self.notUploaded)];
  }
  if (self.hasUploaded) {
    [output appendFormat:@"%@%@ {\n", indent, @"uploaded"];
    [self.uploaded writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasPreview) {
    [output appendFormat:@"%@%@ {\n", indent, @"preview"];
    [self.preview writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasExpectsReadConfirmation) {
    [output appendFormat:@"%@%@: %@\n", indent, @"expectsReadConfirmation", [NSNumber numberWithBool:self.expectsReadConfirmation]];
  }
  if (self.hasLegalHoldStatus) {
    [output appendFormat:@"%@%@: %@\n", indent, @"legalHoldStatus", NSStringFromZMLegalHoldStatus(self.legalHoldStatus)];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasOriginal) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.original storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"original"];
  }
  if (self.hasNotUploaded) {
    [dictionary setObject: @(self.notUploaded) forKey: @"notUploaded"];
  }
  if (self.hasUploaded) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.uploaded storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"uploaded"];
  }
  if (self.hasPreview) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.preview storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"preview"];
  }
  if (self.hasExpectsReadConfirmation) {
    [dictionary setObject: [NSNumber numberWithBool:self.expectsReadConfirmation] forKey: @"expectsReadConfirmation"];
  }
  if (self.hasLegalHoldStatus) {
    [dictionary setObject: @(self.legalHoldStatus) forKey: @"legalHoldStatus"];
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
      self.hasNotUploaded == otherMessage.hasNotUploaded &&
      (!self.hasNotUploaded || self.notUploaded == otherMessage.notUploaded) &&
      self.hasUploaded == otherMessage.hasUploaded &&
      (!self.hasUploaded || [self.uploaded isEqual:otherMessage.uploaded]) &&
      self.hasPreview == otherMessage.hasPreview &&
      (!self.hasPreview || [self.preview isEqual:otherMessage.preview]) &&
      self.hasExpectsReadConfirmation == otherMessage.hasExpectsReadConfirmation &&
      (!self.hasExpectsReadConfirmation || self.expectsReadConfirmation == otherMessage.expectsReadConfirmation) &&
      self.hasLegalHoldStatus == otherMessage.hasLegalHoldStatus &&
      (!self.hasLegalHoldStatus || self.legalHoldStatus == otherMessage.legalHoldStatus) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasOriginal) {
    hashCode = hashCode * 31 + [self.original hash];
  }
  if (self.hasNotUploaded) {
    hashCode = hashCode * 31 + self.notUploaded;
  }
  if (self.hasUploaded) {
    hashCode = hashCode * 31 + [self.uploaded hash];
  }
  if (self.hasPreview) {
    hashCode = hashCode * 31 + [self.preview hash];
  }
  if (self.hasExpectsReadConfirmation) {
    hashCode = hashCode * 31 + [[NSNumber numberWithBool:self.expectsReadConfirmation] hash];
  }
  if (self.hasLegalHoldStatus) {
    hashCode = hashCode * 31 + self.legalHoldStatus;
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
@property (strong) ZMAssetAudioMetaData* audio;
@property (strong) NSString* source;
@property (strong) NSString* caption;
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
- (BOOL) hasAudio {
  return !!hasAudio_;
}
- (void) setHasAudio:(BOOL) _value_ {
  hasAudio_ = !!_value_;
}
@synthesize audio;
- (BOOL) hasSource {
  return !!hasSource_;
}
- (void) setHasSource:(BOOL) _value_ {
  hasSource_ = !!_value_;
}
@synthesize source;
- (BOOL) hasCaption {
  return !!hasCaption_;
}
- (void) setHasCaption:(BOOL) _value_ {
  hasCaption_ = !!_value_;
}
@synthesize caption;
- (instancetype) init {
  if ((self = [super init])) {
    self.mimeType = @"";
    self.size = 0L;
    self.name = @"";
    self.image = [ZMAssetImageMetaData defaultInstance];
    self.video = [ZMAssetVideoMetaData defaultInstance];
    self.audio = [ZMAssetAudioMetaData defaultInstance];
    self.source = @"";
    self.caption = @"";
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
  if (self.hasAudio) {
    [output writeMessage:6 value:self.audio];
  }
  if (self.hasSource) {
    [output writeString:7 value:self.source];
  }
  if (self.hasCaption) {
    [output writeString:8 value:self.caption];
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
  if (self.hasAudio) {
    size_ += computeMessageSize(6, self.audio);
  }
  if (self.hasSource) {
    size_ += computeStringSize(7, self.source);
  }
  if (self.hasCaption) {
    size_ += computeStringSize(8, self.caption);
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
  if (self.hasAudio) {
    [output appendFormat:@"%@%@ {\n", indent, @"audio"];
    [self.audio writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
  }
  if (self.hasSource) {
    [output appendFormat:@"%@%@: %@\n", indent, @"source", self.source];
  }
  if (self.hasCaption) {
    [output appendFormat:@"%@%@: %@\n", indent, @"caption", self.caption];
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
  if (self.hasAudio) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.audio storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"audio"];
  }
  if (self.hasSource) {
    [dictionary setObject: self.source forKey: @"source"];
  }
  if (self.hasCaption) {
    [dictionary setObject: self.caption forKey: @"caption"];
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
      self.hasAudio == otherMessage.hasAudio &&
      (!self.hasAudio || [self.audio isEqual:otherMessage.audio]) &&
      self.hasSource == otherMessage.hasSource &&
      (!self.hasSource || [self.source isEqual:otherMessage.source]) &&
      self.hasCaption == otherMessage.hasCaption &&
      (!self.hasCaption || [self.caption isEqual:otherMessage.caption]) &&
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
  if (self.hasAudio) {
    hashCode = hashCode * 31 + [self.audio hash];
  }
  if (self.hasSource) {
    hashCode = hashCode * 31 + [self.source hash];
  }
  if (self.hasCaption) {
    hashCode = hashCode * 31 + [self.caption hash];
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
  if (other.hasAudio) {
    [self mergeAudio:other.audio];
  }
  if (other.hasSource) {
    [self setSource:other.source];
  }
  if (other.hasCaption) {
    [self setCaption:other.caption];
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
      case 50: {
        ZMAssetAudioMetaDataBuilder* subBuilder = [ZMAssetAudioMetaData builder];
        if (self.hasAudio) {
          [subBuilder mergeFrom:self.audio];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setAudio:[subBuilder buildPartial]];
        break;
      }
      case 58: {
        [self setSource:[input readString]];
        break;
      }
      case 66: {
        [self setCaption:[input readString]];
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
- (BOOL) hasAudio {
  return resultOriginal.hasAudio;
}
- (ZMAssetAudioMetaData*) audio {
  return resultOriginal.audio;
}
- (ZMAssetOriginalBuilder*) setAudio:(ZMAssetAudioMetaData*) value {
  resultOriginal.hasAudio = YES;
  resultOriginal.audio = value;
  return self;
}
- (ZMAssetOriginalBuilder*) setAudioBuilder:(ZMAssetAudioMetaDataBuilder*) builderForValue {
  return [self setAudio:[builderForValue build]];
}
- (ZMAssetOriginalBuilder*) mergeAudio:(ZMAssetAudioMetaData*) value {
  if (resultOriginal.hasAudio &&
      resultOriginal.audio != [ZMAssetAudioMetaData defaultInstance]) {
    resultOriginal.audio =
      [[[ZMAssetAudioMetaData builderWithPrototype:resultOriginal.audio] mergeFrom:value] buildPartial];
  } else {
    resultOriginal.audio = value;
  }
  resultOriginal.hasAudio = YES;
  return self;
}
- (ZMAssetOriginalBuilder*) clearAudio {
  resultOriginal.hasAudio = NO;
  resultOriginal.audio = [ZMAssetAudioMetaData defaultInstance];
  return self;
}
- (BOOL) hasSource {
  return resultOriginal.hasSource;
}
- (NSString*) source {
  return resultOriginal.source;
}
- (ZMAssetOriginalBuilder*) setSource:(NSString*) value {
  resultOriginal.hasSource = YES;
  resultOriginal.source = value;
  return self;
}
- (ZMAssetOriginalBuilder*) clearSource {
  resultOriginal.hasSource = NO;
  resultOriginal.source = @"";
  return self;
}
- (BOOL) hasCaption {
  return resultOriginal.hasCaption;
}
- (NSString*) caption {
  return resultOriginal.caption;
}
- (ZMAssetOriginalBuilder*) setCaption:(NSString*) value {
  resultOriginal.hasCaption = YES;
  resultOriginal.caption = value;
  return self;
}
- (ZMAssetOriginalBuilder*) clearCaption {
  resultOriginal.hasCaption = NO;
  resultOriginal.caption = @"";
  return self;
}
@end

@interface ZMAssetPreview ()
@property (strong) NSString* mimeType;
@property UInt64 size;
@property (strong) ZMAssetRemoteData* remote;
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
- (BOOL) hasSize {
  return !!hasSize_;
}
- (void) setHasSize:(BOOL) _value_ {
  hasSize_ = !!_value_;
}
@synthesize size;
- (BOOL) hasRemote {
  return !!hasRemote_;
}
- (void) setHasRemote:(BOOL) _value_ {
  hasRemote_ = !!_value_;
}
@synthesize remote;
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
    self.size = 0L;
    self.remote = [ZMAssetRemoteData defaultInstance];
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
  if (!self.hasSize) {
    return NO;
  }
  if (self.hasRemote) {
    if (!self.remote.isInitialized) {
      return NO;
    }
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
  if (self.hasRemote) {
    [output writeMessage:3 value:self.remote];
  }
  if (self.hasImage) {
    [output writeMessage:4 value:self.image];
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
  if (self.hasRemote) {
    size_ += computeMessageSize(3, self.remote);
  }
  if (self.hasImage) {
    size_ += computeMessageSize(4, self.image);
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
  if (self.hasSize) {
    [output appendFormat:@"%@%@: %@\n", indent, @"size", [NSNumber numberWithLongLong:self.size]];
  }
  if (self.hasRemote) {
    [output appendFormat:@"%@%@ {\n", indent, @"remote"];
    [self.remote writeDescriptionTo:output
                         withIndent:[NSString stringWithFormat:@"%@  ", indent]];
    [output appendFormat:@"%@}\n", indent];
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
  if (self.hasSize) {
    [dictionary setObject: [NSNumber numberWithLongLong:self.size] forKey: @"size"];
  }
  if (self.hasRemote) {
   NSMutableDictionary *messageDictionary = [NSMutableDictionary dictionary]; 
   [self.remote storeInDictionary:messageDictionary];
   [dictionary setObject:[NSDictionary dictionaryWithDictionary:messageDictionary] forKey:@"remote"];
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
      self.hasSize == otherMessage.hasSize &&
      (!self.hasSize || self.size == otherMessage.size) &&
      self.hasRemote == otherMessage.hasRemote &&
      (!self.hasRemote || [self.remote isEqual:otherMessage.remote]) &&
      self.hasImage == otherMessage.hasImage &&
      (!self.hasImage || [self.image isEqual:otherMessage.image]) &&
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
  if (self.hasRemote) {
    hashCode = hashCode * 31 + [self.remote hash];
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
  if (other.hasSize) {
    [self setSize:other.size];
  }
  if (other.hasRemote) {
    [self mergeRemote:other.remote];
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
      case 16: {
        [self setSize:[input readUInt64]];
        break;
      }
      case 26: {
        ZMAssetRemoteDataBuilder* subBuilder = [ZMAssetRemoteData builder];
        if (self.hasRemote) {
          [subBuilder mergeFrom:self.remote];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setRemote:[subBuilder buildPartial]];
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
- (BOOL) hasRemote {
  return resultPreview.hasRemote;
}
- (ZMAssetRemoteData*) remote {
  return resultPreview.remote;
}
- (ZMAssetPreviewBuilder*) setRemote:(ZMAssetRemoteData*) value {
  resultPreview.hasRemote = YES;
  resultPreview.remote = value;
  return self;
}
- (ZMAssetPreviewBuilder*) setRemoteBuilder:(ZMAssetRemoteDataBuilder*) builderForValue {
  return [self setRemote:[builderForValue build]];
}
- (ZMAssetPreviewBuilder*) mergeRemote:(ZMAssetRemoteData*) value {
  if (resultPreview.hasRemote &&
      resultPreview.remote != [ZMAssetRemoteData defaultInstance]) {
    resultPreview.remote =
      [[[ZMAssetRemoteData builderWithPrototype:resultPreview.remote] mergeFrom:value] buildPartial];
  } else {
    resultPreview.remote = value;
  }
  resultPreview.hasRemote = YES;
  return self;
}
- (ZMAssetPreviewBuilder*) clearRemote {
  resultPreview.hasRemote = NO;
  resultPreview.remote = [ZMAssetRemoteData defaultInstance];
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

@interface ZMAssetAudioMetaData ()
@property UInt64 durationInMillis;
@property (strong) NSData* normalizedLoudness;
@end

@implementation ZMAssetAudioMetaData

- (BOOL) hasDurationInMillis {
  return !!hasDurationInMillis_;
}
- (void) setHasDurationInMillis:(BOOL) _value_ {
  hasDurationInMillis_ = !!_value_;
}
@synthesize durationInMillis;
- (BOOL) hasNormalizedLoudness {
  return !!hasNormalizedLoudness_;
}
- (void) setHasNormalizedLoudness:(BOOL) _value_ {
  hasNormalizedLoudness_ = !!_value_;
}
@synthesize normalizedLoudness;
- (instancetype) init {
  if ((self = [super init])) {
    self.durationInMillis = 0L;
    self.normalizedLoudness = [NSData data];
  }
  return self;
}
static ZMAssetAudioMetaData* defaultZMAssetAudioMetaDataInstance = nil;
+ (void) initialize {
  if (self == [ZMAssetAudioMetaData class]) {
    defaultZMAssetAudioMetaDataInstance = [[ZMAssetAudioMetaData alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMAssetAudioMetaDataInstance;
}
- (instancetype) defaultInstance {
  return defaultZMAssetAudioMetaDataInstance;
}
- (BOOL) isInitialized {
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasDurationInMillis) {
    [output writeUInt64:1 value:self.durationInMillis];
  }
  if (self.hasNormalizedLoudness) {
    [output writeData:3 value:self.normalizedLoudness];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasDurationInMillis) {
    size_ += computeUInt64Size(1, self.durationInMillis);
  }
  if (self.hasNormalizedLoudness) {
    size_ += computeDataSize(3, self.normalizedLoudness);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMAssetAudioMetaData*) parseFromData:(NSData*) data {
  return (ZMAssetAudioMetaData*)[[[ZMAssetAudioMetaData builder] mergeFromData:data] build];
}
+ (ZMAssetAudioMetaData*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetAudioMetaData*)[[[ZMAssetAudioMetaData builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetAudioMetaData*) parseFromInputStream:(NSInputStream*) input {
  return (ZMAssetAudioMetaData*)[[[ZMAssetAudioMetaData builder] mergeFromInputStream:input] build];
}
+ (ZMAssetAudioMetaData*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetAudioMetaData*)[[[ZMAssetAudioMetaData builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetAudioMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMAssetAudioMetaData*)[[[ZMAssetAudioMetaData builder] mergeFromCodedInputStream:input] build];
}
+ (ZMAssetAudioMetaData*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetAudioMetaData*)[[[ZMAssetAudioMetaData builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetAudioMetaDataBuilder*) builder {
  return [[ZMAssetAudioMetaDataBuilder alloc] init];
}
+ (ZMAssetAudioMetaDataBuilder*) builderWithPrototype:(ZMAssetAudioMetaData*) prototype {
  return [[ZMAssetAudioMetaData builder] mergeFrom:prototype];
}
- (ZMAssetAudioMetaDataBuilder*) builder {
  return [ZMAssetAudioMetaData builder];
}
- (ZMAssetAudioMetaDataBuilder*) toBuilder {
  return [ZMAssetAudioMetaData builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasDurationInMillis) {
    [output appendFormat:@"%@%@: %@\n", indent, @"durationInMillis", [NSNumber numberWithLongLong:self.durationInMillis]];
  }
  if (self.hasNormalizedLoudness) {
    [output appendFormat:@"%@%@: %@\n", indent, @"normalizedLoudness", self.normalizedLoudness];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasDurationInMillis) {
    [dictionary setObject: [NSNumber numberWithLongLong:self.durationInMillis] forKey: @"durationInMillis"];
  }
  if (self.hasNormalizedLoudness) {
    [dictionary setObject: self.normalizedLoudness forKey: @"normalizedLoudness"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMAssetAudioMetaData class]]) {
    return NO;
  }
  ZMAssetAudioMetaData *otherMessage = other;
  return
      self.hasDurationInMillis == otherMessage.hasDurationInMillis &&
      (!self.hasDurationInMillis || self.durationInMillis == otherMessage.durationInMillis) &&
      self.hasNormalizedLoudness == otherMessage.hasNormalizedLoudness &&
      (!self.hasNormalizedLoudness || [self.normalizedLoudness isEqual:otherMessage.normalizedLoudness]) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasDurationInMillis) {
    hashCode = hashCode * 31 + [[NSNumber numberWithLongLong:self.durationInMillis] hash];
  }
  if (self.hasNormalizedLoudness) {
    hashCode = hashCode * 31 + [self.normalizedLoudness hash];
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMAssetAudioMetaDataBuilder()
@property (strong) ZMAssetAudioMetaData* resultAudioMetaData;
@end

@implementation ZMAssetAudioMetaDataBuilder
@synthesize resultAudioMetaData;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultAudioMetaData = [[ZMAssetAudioMetaData alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultAudioMetaData;
}
- (ZMAssetAudioMetaDataBuilder*) clear {
  self.resultAudioMetaData = [[ZMAssetAudioMetaData alloc] init];
  return self;
}
- (ZMAssetAudioMetaDataBuilder*) clone {
  return [ZMAssetAudioMetaData builderWithPrototype:resultAudioMetaData];
}
- (ZMAssetAudioMetaData*) defaultInstance {
  return [ZMAssetAudioMetaData defaultInstance];
}
- (ZMAssetAudioMetaData*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMAssetAudioMetaData*) buildPartial {
  ZMAssetAudioMetaData* returnMe = resultAudioMetaData;
  self.resultAudioMetaData = nil;
  return returnMe;
}
- (ZMAssetAudioMetaDataBuilder*) mergeFrom:(ZMAssetAudioMetaData*) other {
  if (other == [ZMAssetAudioMetaData defaultInstance]) {
    return self;
  }
  if (other.hasDurationInMillis) {
    [self setDurationInMillis:other.durationInMillis];
  }
  if (other.hasNormalizedLoudness) {
    [self setNormalizedLoudness:other.normalizedLoudness];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMAssetAudioMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMAssetAudioMetaDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setDurationInMillis:[input readUInt64]];
        break;
      }
      case 26: {
        [self setNormalizedLoudness:[input readData]];
        break;
      }
    }
  }
}
- (BOOL) hasDurationInMillis {
  return resultAudioMetaData.hasDurationInMillis;
}
- (UInt64) durationInMillis {
  return resultAudioMetaData.durationInMillis;
}
- (ZMAssetAudioMetaDataBuilder*) setDurationInMillis:(UInt64) value {
  resultAudioMetaData.hasDurationInMillis = YES;
  resultAudioMetaData.durationInMillis = value;
  return self;
}
- (ZMAssetAudioMetaDataBuilder*) clearDurationInMillis {
  resultAudioMetaData.hasDurationInMillis = NO;
  resultAudioMetaData.durationInMillis = 0L;
  return self;
}
- (BOOL) hasNormalizedLoudness {
  return resultAudioMetaData.hasNormalizedLoudness;
}
- (NSData*) normalizedLoudness {
  return resultAudioMetaData.normalizedLoudness;
}
- (ZMAssetAudioMetaDataBuilder*) setNormalizedLoudness:(NSData*) value {
  resultAudioMetaData.hasNormalizedLoudness = YES;
  resultAudioMetaData.normalizedLoudness = value;
  return self;
}
- (ZMAssetAudioMetaDataBuilder*) clearNormalizedLoudness {
  resultAudioMetaData.hasNormalizedLoudness = NO;
  resultAudioMetaData.normalizedLoudness = [NSData data];
  return self;
}
@end

@interface ZMAssetRemoteData ()
@property (strong) NSData* otrKey;
@property (strong) NSData* sha256;
@property (strong) NSString* assetId;
@property (strong) NSString* assetToken;
@property ZMEncryptionAlgorithm encryption;
@end

@implementation ZMAssetRemoteData

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
- (BOOL) hasAssetId {
  return !!hasAssetId_;
}
- (void) setHasAssetId:(BOOL) _value_ {
  hasAssetId_ = !!_value_;
}
@synthesize assetId;
- (BOOL) hasAssetToken {
  return !!hasAssetToken_;
}
- (void) setHasAssetToken:(BOOL) _value_ {
  hasAssetToken_ = !!_value_;
}
@synthesize assetToken;
- (BOOL) hasEncryption {
  return !!hasEncryption_;
}
- (void) setHasEncryption:(BOOL) _value_ {
  hasEncryption_ = !!_value_;
}
@synthesize encryption;
- (instancetype) init {
  if ((self = [super init])) {
    self.otrKey = [NSData data];
    self.sha256 = [NSData data];
    self.assetId = @"";
    self.assetToken = @"";
    self.encryption = ZMEncryptionAlgorithmAESCBC;
  }
  return self;
}
static ZMAssetRemoteData* defaultZMAssetRemoteDataInstance = nil;
+ (void) initialize {
  if (self == [ZMAssetRemoteData class]) {
    defaultZMAssetRemoteDataInstance = [[ZMAssetRemoteData alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMAssetRemoteDataInstance;
}
- (instancetype) defaultInstance {
  return defaultZMAssetRemoteDataInstance;
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
  if (self.hasAssetId) {
    [output writeString:3 value:self.assetId];
  }
  if (self.hasAssetToken) {
    [output writeString:5 value:self.assetToken];
  }
  if (self.hasEncryption) {
    [output writeEnum:6 value:self.encryption];
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
  if (self.hasAssetId) {
    size_ += computeStringSize(3, self.assetId);
  }
  if (self.hasAssetToken) {
    size_ += computeStringSize(5, self.assetToken);
  }
  if (self.hasEncryption) {
    size_ += computeEnumSize(6, self.encryption);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMAssetRemoteData*) parseFromData:(NSData*) data {
  return (ZMAssetRemoteData*)[[[ZMAssetRemoteData builder] mergeFromData:data] build];
}
+ (ZMAssetRemoteData*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetRemoteData*)[[[ZMAssetRemoteData builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetRemoteData*) parseFromInputStream:(NSInputStream*) input {
  return (ZMAssetRemoteData*)[[[ZMAssetRemoteData builder] mergeFromInputStream:input] build];
}
+ (ZMAssetRemoteData*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetRemoteData*)[[[ZMAssetRemoteData builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetRemoteData*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMAssetRemoteData*)[[[ZMAssetRemoteData builder] mergeFromCodedInputStream:input] build];
}
+ (ZMAssetRemoteData*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMAssetRemoteData*)[[[ZMAssetRemoteData builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMAssetRemoteDataBuilder*) builder {
  return [[ZMAssetRemoteDataBuilder alloc] init];
}
+ (ZMAssetRemoteDataBuilder*) builderWithPrototype:(ZMAssetRemoteData*) prototype {
  return [[ZMAssetRemoteData builder] mergeFrom:prototype];
}
- (ZMAssetRemoteDataBuilder*) builder {
  return [ZMAssetRemoteData builder];
}
- (ZMAssetRemoteDataBuilder*) toBuilder {
  return [ZMAssetRemoteData builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasOtrKey) {
    [output appendFormat:@"%@%@: %@\n", indent, @"otrKey", self.otrKey];
  }
  if (self.hasSha256) {
    [output appendFormat:@"%@%@: %@\n", indent, @"sha256", self.sha256];
  }
  if (self.hasAssetId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"assetId", self.assetId];
  }
  if (self.hasAssetToken) {
    [output appendFormat:@"%@%@: %@\n", indent, @"assetToken", self.assetToken];
  }
  if (self.hasEncryption) {
    [output appendFormat:@"%@%@: %@\n", indent, @"encryption", NSStringFromZMEncryptionAlgorithm(self.encryption)];
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
  if (self.hasAssetId) {
    [dictionary setObject: self.assetId forKey: @"assetId"];
  }
  if (self.hasAssetToken) {
    [dictionary setObject: self.assetToken forKey: @"assetToken"];
  }
  if (self.hasEncryption) {
    [dictionary setObject: @(self.encryption) forKey: @"encryption"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMAssetRemoteData class]]) {
    return NO;
  }
  ZMAssetRemoteData *otherMessage = other;
  return
      self.hasOtrKey == otherMessage.hasOtrKey &&
      (!self.hasOtrKey || [self.otrKey isEqual:otherMessage.otrKey]) &&
      self.hasSha256 == otherMessage.hasSha256 &&
      (!self.hasSha256 || [self.sha256 isEqual:otherMessage.sha256]) &&
      self.hasAssetId == otherMessage.hasAssetId &&
      (!self.hasAssetId || [self.assetId isEqual:otherMessage.assetId]) &&
      self.hasAssetToken == otherMessage.hasAssetToken &&
      (!self.hasAssetToken || [self.assetToken isEqual:otherMessage.assetToken]) &&
      self.hasEncryption == otherMessage.hasEncryption &&
      (!self.hasEncryption || self.encryption == otherMessage.encryption) &&
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
  if (self.hasAssetId) {
    hashCode = hashCode * 31 + [self.assetId hash];
  }
  if (self.hasAssetToken) {
    hashCode = hashCode * 31 + [self.assetToken hash];
  }
  if (self.hasEncryption) {
    hashCode = hashCode * 31 + self.encryption;
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMAssetRemoteDataBuilder()
@property (strong) ZMAssetRemoteData* resultRemoteData;
@end

@implementation ZMAssetRemoteDataBuilder
@synthesize resultRemoteData;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultRemoteData = [[ZMAssetRemoteData alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultRemoteData;
}
- (ZMAssetRemoteDataBuilder*) clear {
  self.resultRemoteData = [[ZMAssetRemoteData alloc] init];
  return self;
}
- (ZMAssetRemoteDataBuilder*) clone {
  return [ZMAssetRemoteData builderWithPrototype:resultRemoteData];
}
- (ZMAssetRemoteData*) defaultInstance {
  return [ZMAssetRemoteData defaultInstance];
}
- (ZMAssetRemoteData*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMAssetRemoteData*) buildPartial {
  ZMAssetRemoteData* returnMe = resultRemoteData;
  self.resultRemoteData = nil;
  return returnMe;
}
- (ZMAssetRemoteDataBuilder*) mergeFrom:(ZMAssetRemoteData*) other {
  if (other == [ZMAssetRemoteData defaultInstance]) {
    return self;
  }
  if (other.hasOtrKey) {
    [self setOtrKey:other.otrKey];
  }
  if (other.hasSha256) {
    [self setSha256:other.sha256];
  }
  if (other.hasAssetId) {
    [self setAssetId:other.assetId];
  }
  if (other.hasAssetToken) {
    [self setAssetToken:other.assetToken];
  }
  if (other.hasEncryption) {
    [self setEncryption:other.encryption];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMAssetRemoteDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMAssetRemoteDataBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
      case 26: {
        [self setAssetId:[input readString]];
        break;
      }
      case 42: {
        [self setAssetToken:[input readString]];
        break;
      }
      case 48: {
        ZMEncryptionAlgorithm value = (ZMEncryptionAlgorithm)[input readEnum];
        if (ZMEncryptionAlgorithmIsValidValue(value)) {
          [self setEncryption:value];
        } else {
          [unknownFields mergeVarintField:6 value:value];
        }
        break;
      }
    }
  }
}
- (BOOL) hasOtrKey {
  return resultRemoteData.hasOtrKey;
}
- (NSData*) otrKey {
  return resultRemoteData.otrKey;
}
- (ZMAssetRemoteDataBuilder*) setOtrKey:(NSData*) value {
  resultRemoteData.hasOtrKey = YES;
  resultRemoteData.otrKey = value;
  return self;
}
- (ZMAssetRemoteDataBuilder*) clearOtrKey {
  resultRemoteData.hasOtrKey = NO;
  resultRemoteData.otrKey = [NSData data];
  return self;
}
- (BOOL) hasSha256 {
  return resultRemoteData.hasSha256;
}
- (NSData*) sha256 {
  return resultRemoteData.sha256;
}
- (ZMAssetRemoteDataBuilder*) setSha256:(NSData*) value {
  resultRemoteData.hasSha256 = YES;
  resultRemoteData.sha256 = value;
  return self;
}
- (ZMAssetRemoteDataBuilder*) clearSha256 {
  resultRemoteData.hasSha256 = NO;
  resultRemoteData.sha256 = [NSData data];
  return self;
}
- (BOOL) hasAssetId {
  return resultRemoteData.hasAssetId;
}
- (NSString*) assetId {
  return resultRemoteData.assetId;
}
- (ZMAssetRemoteDataBuilder*) setAssetId:(NSString*) value {
  resultRemoteData.hasAssetId = YES;
  resultRemoteData.assetId = value;
  return self;
}
- (ZMAssetRemoteDataBuilder*) clearAssetId {
  resultRemoteData.hasAssetId = NO;
  resultRemoteData.assetId = @"";
  return self;
}
- (BOOL) hasAssetToken {
  return resultRemoteData.hasAssetToken;
}
- (NSString*) assetToken {
  return resultRemoteData.assetToken;
}
- (ZMAssetRemoteDataBuilder*) setAssetToken:(NSString*) value {
  resultRemoteData.hasAssetToken = YES;
  resultRemoteData.assetToken = value;
  return self;
}
- (ZMAssetRemoteDataBuilder*) clearAssetToken {
  resultRemoteData.hasAssetToken = NO;
  resultRemoteData.assetToken = @"";
  return self;
}
- (BOOL) hasEncryption {
  return resultRemoteData.hasEncryption;
}
- (ZMEncryptionAlgorithm) encryption {
  return resultRemoteData.encryption;
}
- (ZMAssetRemoteDataBuilder*) setEncryption:(ZMEncryptionAlgorithm) value {
  resultRemoteData.hasEncryption = YES;
  resultRemoteData.encryption = value;
  return self;
}
- (ZMAssetRemoteDataBuilder*) clearEncryption {
  resultRemoteData.hasEncryption = NO;
  resultRemoteData.encryption = ZMEncryptionAlgorithmAESCBC;
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
  if (other.hasNotUploaded) {
    [self setNotUploaded:other.notUploaded];
  }
  if (other.hasUploaded) {
    [self mergeUploaded:other.uploaded];
  }
  if (other.hasPreview) {
    [self mergePreview:other.preview];
  }
  if (other.hasExpectsReadConfirmation) {
    [self setExpectsReadConfirmation:other.expectsReadConfirmation];
  }
  if (other.hasLegalHoldStatus) {
    [self setLegalHoldStatus:other.legalHoldStatus];
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
        ZMAssetRemoteDataBuilder* subBuilder = [ZMAssetRemoteData builder];
        if (self.hasUploaded) {
          [subBuilder mergeFrom:self.uploaded];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setUploaded:[subBuilder buildPartial]];
        break;
      }
      case 42: {
        ZMAssetPreviewBuilder* subBuilder = [ZMAssetPreview builder];
        if (self.hasPreview) {
          [subBuilder mergeFrom:self.preview];
        }
        [input readMessage:subBuilder extensionRegistry:extensionRegistry];
        [self setPreview:[subBuilder buildPartial]];
        break;
      }
      case 48: {
        [self setExpectsReadConfirmation:[input readBool]];
        break;
      }
      case 56: {
        ZMLegalHoldStatus value = (ZMLegalHoldStatus)[input readEnum];
        if (ZMLegalHoldStatusIsValidValue(value)) {
          [self setLegalHoldStatus:value];
        } else {
          [unknownFields mergeVarintField:7 value:value];
        }
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
- (ZMAssetRemoteData*) uploaded {
  return resultAsset.uploaded;
}
- (ZMAssetBuilder*) setUploaded:(ZMAssetRemoteData*) value {
  resultAsset.hasUploaded = YES;
  resultAsset.uploaded = value;
  return self;
}
- (ZMAssetBuilder*) setUploadedBuilder:(ZMAssetRemoteDataBuilder*) builderForValue {
  return [self setUploaded:[builderForValue build]];
}
- (ZMAssetBuilder*) mergeUploaded:(ZMAssetRemoteData*) value {
  if (resultAsset.hasUploaded &&
      resultAsset.uploaded != [ZMAssetRemoteData defaultInstance]) {
    resultAsset.uploaded =
      [[[ZMAssetRemoteData builderWithPrototype:resultAsset.uploaded] mergeFrom:value] buildPartial];
  } else {
    resultAsset.uploaded = value;
  }
  resultAsset.hasUploaded = YES;
  return self;
}
- (ZMAssetBuilder*) clearUploaded {
  resultAsset.hasUploaded = NO;
  resultAsset.uploaded = [ZMAssetRemoteData defaultInstance];
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
- (BOOL) hasExpectsReadConfirmation {
  return resultAsset.hasExpectsReadConfirmation;
}
- (BOOL) expectsReadConfirmation {
  return resultAsset.expectsReadConfirmation;
}
- (ZMAssetBuilder*) setExpectsReadConfirmation:(BOOL) value {
  resultAsset.hasExpectsReadConfirmation = YES;
  resultAsset.expectsReadConfirmation = value;
  return self;
}
- (ZMAssetBuilder*) clearExpectsReadConfirmation {
  resultAsset.hasExpectsReadConfirmation = NO;
  resultAsset.expectsReadConfirmation = NO;
  return self;
}
- (BOOL) hasLegalHoldStatus {
  return resultAsset.hasLegalHoldStatus;
}
- (ZMLegalHoldStatus) legalHoldStatus {
  return resultAsset.legalHoldStatus;
}
- (ZMAssetBuilder*) setLegalHoldStatus:(ZMLegalHoldStatus) value {
  resultAsset.hasLegalHoldStatus = YES;
  resultAsset.legalHoldStatus = value;
  return self;
}
- (ZMAssetBuilder*) clearLegalHoldStatus {
  resultAsset.hasLegalHoldStatus = NO;
  resultAsset.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
  return self;
}
@end

@interface ZMExternal ()
@property (strong) NSData* otrKey;
@property (strong) NSData* sha256;
@property ZMEncryptionAlgorithm encryption;
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
- (BOOL) hasEncryption {
  return !!hasEncryption_;
}
- (void) setHasEncryption:(BOOL) _value_ {
  hasEncryption_ = !!_value_;
}
@synthesize encryption;
- (instancetype) init {
  if ((self = [super init])) {
    self.otrKey = [NSData data];
    self.sha256 = [NSData data];
    self.encryption = ZMEncryptionAlgorithmAESCBC;
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
  if (self.hasEncryption) {
    [output writeEnum:3 value:self.encryption];
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
  if (self.hasEncryption) {
    size_ += computeEnumSize(3, self.encryption);
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
  if (self.hasEncryption) {
    [output appendFormat:@"%@%@: %@\n", indent, @"encryption", NSStringFromZMEncryptionAlgorithm(self.encryption)];
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
  if (self.hasEncryption) {
    [dictionary setObject: @(self.encryption) forKey: @"encryption"];
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
      self.hasEncryption == otherMessage.hasEncryption &&
      (!self.hasEncryption || self.encryption == otherMessage.encryption) &&
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
  if (self.hasEncryption) {
    hashCode = hashCode * 31 + self.encryption;
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
  if (other.hasEncryption) {
    [self setEncryption:other.encryption];
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
      case 24: {
        ZMEncryptionAlgorithm value = (ZMEncryptionAlgorithm)[input readEnum];
        if (ZMEncryptionAlgorithmIsValidValue(value)) {
          [self setEncryption:value];
        } else {
          [unknownFields mergeVarintField:3 value:value];
        }
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
- (BOOL) hasEncryption {
  return resultExternal.hasEncryption;
}
- (ZMEncryptionAlgorithm) encryption {
  return resultExternal.encryption;
}
- (ZMExternalBuilder*) setEncryption:(ZMEncryptionAlgorithm) value {
  resultExternal.hasEncryption = YES;
  resultExternal.encryption = value;
  return self;
}
- (ZMExternalBuilder*) clearEncryption {
  resultExternal.hasEncryption = NO;
  resultExternal.encryption = ZMEncryptionAlgorithmAESCBC;
  return self;
}
@end

@interface ZMReaction ()
@property (strong) NSString* emoji;
@property (strong) NSString* messageId;
@property ZMLegalHoldStatus legalHoldStatus;
@end

@implementation ZMReaction

- (BOOL) hasEmoji {
  return !!hasEmoji_;
}
- (void) setHasEmoji:(BOOL) _value_ {
  hasEmoji_ = !!_value_;
}
@synthesize emoji;
- (BOOL) hasMessageId {
  return !!hasMessageId_;
}
- (void) setHasMessageId:(BOOL) _value_ {
  hasMessageId_ = !!_value_;
}
@synthesize messageId;
- (BOOL) hasLegalHoldStatus {
  return !!hasLegalHoldStatus_;
}
- (void) setHasLegalHoldStatus:(BOOL) _value_ {
  hasLegalHoldStatus_ = !!_value_;
}
@synthesize legalHoldStatus;
- (instancetype) init {
  if ((self = [super init])) {
    self.emoji = @"";
    self.messageId = @"";
    self.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
  }
  return self;
}
static ZMReaction* defaultZMReactionInstance = nil;
+ (void) initialize {
  if (self == [ZMReaction class]) {
    defaultZMReactionInstance = [[ZMReaction alloc] init];
  }
}
+ (instancetype) defaultInstance {
  return defaultZMReactionInstance;
}
- (instancetype) defaultInstance {
  return defaultZMReactionInstance;
}
- (BOOL) isInitialized {
  if (!self.hasMessageId) {
    return NO;
  }
  return YES;
}
- (void) writeToCodedOutputStream:(PBCodedOutputStream*) output {
  if (self.hasEmoji) {
    [output writeString:1 value:self.emoji];
  }
  if (self.hasMessageId) {
    [output writeString:2 value:self.messageId];
  }
  if (self.hasLegalHoldStatus) {
    [output writeEnum:3 value:self.legalHoldStatus];
  }
  [self.unknownFields writeToCodedOutputStream:output];
}
- (SInt32) serializedSize {
  __block SInt32 size_ = memoizedSerializedSize;
  if (size_ != -1) {
    return size_;
  }

  size_ = 0;
  if (self.hasEmoji) {
    size_ += computeStringSize(1, self.emoji);
  }
  if (self.hasMessageId) {
    size_ += computeStringSize(2, self.messageId);
  }
  if (self.hasLegalHoldStatus) {
    size_ += computeEnumSize(3, self.legalHoldStatus);
  }
  size_ += self.unknownFields.serializedSize;
  memoizedSerializedSize = size_;
  return size_;
}
+ (ZMReaction*) parseFromData:(NSData*) data {
  return (ZMReaction*)[[[ZMReaction builder] mergeFromData:data] build];
}
+ (ZMReaction*) parseFromData:(NSData*) data extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMReaction*)[[[ZMReaction builder] mergeFromData:data extensionRegistry:extensionRegistry] build];
}
+ (ZMReaction*) parseFromInputStream:(NSInputStream*) input {
  return (ZMReaction*)[[[ZMReaction builder] mergeFromInputStream:input] build];
}
+ (ZMReaction*) parseFromInputStream:(NSInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMReaction*)[[[ZMReaction builder] mergeFromInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMReaction*) parseFromCodedInputStream:(PBCodedInputStream*) input {
  return (ZMReaction*)[[[ZMReaction builder] mergeFromCodedInputStream:input] build];
}
+ (ZMReaction*) parseFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
  return (ZMReaction*)[[[ZMReaction builder] mergeFromCodedInputStream:input extensionRegistry:extensionRegistry] build];
}
+ (ZMReactionBuilder*) builder {
  return [[ZMReactionBuilder alloc] init];
}
+ (ZMReactionBuilder*) builderWithPrototype:(ZMReaction*) prototype {
  return [[ZMReaction builder] mergeFrom:prototype];
}
- (ZMReactionBuilder*) builder {
  return [ZMReaction builder];
}
- (ZMReactionBuilder*) toBuilder {
  return [ZMReaction builderWithPrototype:self];
}
- (void) writeDescriptionTo:(NSMutableString*) output withIndent:(NSString*) indent {
  if (self.hasEmoji) {
    [output appendFormat:@"%@%@: %@\n", indent, @"emoji", self.emoji];
  }
  if (self.hasMessageId) {
    [output appendFormat:@"%@%@: %@\n", indent, @"messageId", self.messageId];
  }
  if (self.hasLegalHoldStatus) {
    [output appendFormat:@"%@%@: %@\n", indent, @"legalHoldStatus", NSStringFromZMLegalHoldStatus(self.legalHoldStatus)];
  }
  [self.unknownFields writeDescriptionTo:output withIndent:indent];
}
- (void) storeInDictionary:(NSMutableDictionary *)dictionary {
  if (self.hasEmoji) {
    [dictionary setObject: self.emoji forKey: @"emoji"];
  }
  if (self.hasMessageId) {
    [dictionary setObject: self.messageId forKey: @"messageId"];
  }
  if (self.hasLegalHoldStatus) {
    [dictionary setObject: @(self.legalHoldStatus) forKey: @"legalHoldStatus"];
  }
  [self.unknownFields storeInDictionary:dictionary];
}
- (BOOL) isEqual:(id)other {
  if (other == self) {
    return YES;
  }
  if (![other isKindOfClass:[ZMReaction class]]) {
    return NO;
  }
  ZMReaction *otherMessage = other;
  return
      self.hasEmoji == otherMessage.hasEmoji &&
      (!self.hasEmoji || [self.emoji isEqual:otherMessage.emoji]) &&
      self.hasMessageId == otherMessage.hasMessageId &&
      (!self.hasMessageId || [self.messageId isEqual:otherMessage.messageId]) &&
      self.hasLegalHoldStatus == otherMessage.hasLegalHoldStatus &&
      (!self.hasLegalHoldStatus || self.legalHoldStatus == otherMessage.legalHoldStatus) &&
      (self.unknownFields == otherMessage.unknownFields || (self.unknownFields != nil && [self.unknownFields isEqual:otherMessage.unknownFields]));
}
- (NSUInteger) hash {
  __block NSUInteger hashCode = 7;
  if (self.hasEmoji) {
    hashCode = hashCode * 31 + [self.emoji hash];
  }
  if (self.hasMessageId) {
    hashCode = hashCode * 31 + [self.messageId hash];
  }
  if (self.hasLegalHoldStatus) {
    hashCode = hashCode * 31 + self.legalHoldStatus;
  }
  hashCode = hashCode * 31 + [self.unknownFields hash];
  return hashCode;
}
@end

@interface ZMReactionBuilder()
@property (strong) ZMReaction* resultReaction;
@end

@implementation ZMReactionBuilder
@synthesize resultReaction;
- (instancetype) init {
  if ((self = [super init])) {
    self.resultReaction = [[ZMReaction alloc] init];
  }
  return self;
}
- (PBGeneratedMessage*) internalGetResult {
  return resultReaction;
}
- (ZMReactionBuilder*) clear {
  self.resultReaction = [[ZMReaction alloc] init];
  return self;
}
- (ZMReactionBuilder*) clone {
  return [ZMReaction builderWithPrototype:resultReaction];
}
- (ZMReaction*) defaultInstance {
  return [ZMReaction defaultInstance];
}
- (ZMReaction*) build {
  [self checkInitialized];
  return [self buildPartial];
}
- (ZMReaction*) buildPartial {
  ZMReaction* returnMe = resultReaction;
  self.resultReaction = nil;
  return returnMe;
}
- (ZMReactionBuilder*) mergeFrom:(ZMReaction*) other {
  if (other == [ZMReaction defaultInstance]) {
    return self;
  }
  if (other.hasEmoji) {
    [self setEmoji:other.emoji];
  }
  if (other.hasMessageId) {
    [self setMessageId:other.messageId];
  }
  if (other.hasLegalHoldStatus) {
    [self setLegalHoldStatus:other.legalHoldStatus];
  }
  [self mergeUnknownFields:other.unknownFields];
  return self;
}
- (ZMReactionBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input {
  return [self mergeFromCodedInputStream:input extensionRegistry:[PBExtensionRegistry emptyRegistry]];
}
- (ZMReactionBuilder*) mergeFromCodedInputStream:(PBCodedInputStream*) input extensionRegistry:(PBExtensionRegistry*) extensionRegistry {
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
        [self setEmoji:[input readString]];
        break;
      }
      case 18: {
        [self setMessageId:[input readString]];
        break;
      }
      case 24: {
        ZMLegalHoldStatus value = (ZMLegalHoldStatus)[input readEnum];
        if (ZMLegalHoldStatusIsValidValue(value)) {
          [self setLegalHoldStatus:value];
        } else {
          [unknownFields mergeVarintField:3 value:value];
        }
        break;
      }
    }
  }
}
- (BOOL) hasEmoji {
  return resultReaction.hasEmoji;
}
- (NSString*) emoji {
  return resultReaction.emoji;
}
- (ZMReactionBuilder*) setEmoji:(NSString*) value {
  resultReaction.hasEmoji = YES;
  resultReaction.emoji = value;
  return self;
}
- (ZMReactionBuilder*) clearEmoji {
  resultReaction.hasEmoji = NO;
  resultReaction.emoji = @"";
  return self;
}
- (BOOL) hasMessageId {
  return resultReaction.hasMessageId;
}
- (NSString*) messageId {
  return resultReaction.messageId;
}
- (ZMReactionBuilder*) setMessageId:(NSString*) value {
  resultReaction.hasMessageId = YES;
  resultReaction.messageId = value;
  return self;
}
- (ZMReactionBuilder*) clearMessageId {
  resultReaction.hasMessageId = NO;
  resultReaction.messageId = @"";
  return self;
}
- (BOOL) hasLegalHoldStatus {
  return resultReaction.hasLegalHoldStatus;
}
- (ZMLegalHoldStatus) legalHoldStatus {
  return resultReaction.legalHoldStatus;
}
- (ZMReactionBuilder*) setLegalHoldStatus:(ZMLegalHoldStatus) value {
  resultReaction.hasLegalHoldStatus = YES;
  resultReaction.legalHoldStatus = value;
  return self;
}
- (ZMReactionBuilder*) clearLegalHoldStatus {
  resultReaction.hasLegalHoldStatus = NO;
  resultReaction.legalHoldStatus = ZMLegalHoldStatusUNKNOWN;
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
