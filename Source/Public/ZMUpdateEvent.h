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


@import Foundation;
@import WireSystem;



@protocol ZMTransportData;

typedef NS_ENUM(NSInteger, ZMUpdateEventsPolicy) {
    ZMUpdateEventPolicyBuffer, ///< store live events in a buffer, to be processed later
    ZMUpdateEventPolicyIgnore, ///< process events received through /notifications or /conversation/.../events
    ZMUpdateEventPolicyProcess ///< process events received through the push channel
    
};

typedef NS_ENUM(NSInteger, ZMUpdateEventSource) {
    ZMUpdateEventSourceWebSocket,
    ZMUpdateEventSourcePushNotification,
    ZMUpdateEventSourceDownload
};

typedef NS_ENUM(NSUInteger, ZMUpdateEventType) {
    
    ZMUpdateEventUnknown = 0,
    
    ZMUpdateEventConversationAssetAdd,
    ZMUpdateEventConversationConnectRequest,
    ZMUpdateEventConversationCreate,
    ZMUpdateEventConversationKnock,
    ZMUpdateEventConversationMemberJoin,
    ZMUpdateEventConversationMemberLeave,
    ZMUpdateEventConversationMemberUpdate,
    ZMUpdateEventConversationMessageAdd,
    ZMUpdateEventConversationClientMessageAdd,
    ZMUpdateEventConversationOtrMessageAdd,
    ZMUpdateEventConversationOtrAssetAdd,
    ZMUpdateEventConversationRename,
    ZMUpdateEventConversationTyping,
    ZMUpdateEventUserConnection,
    ZMUpdateEventUserNew,
    ZMUpdateEventUserUpdate,
    ZMUpdateEventUserPushRemove,
    ZMUpdateEventUserContactJoin,
    ZMUpdateEventUserClientAdd,
    ZMUpdateEventUserClientRemove,
    ZMUpdateEventTeamCreate,
    ZMUpdateEventTeamDelete,
    ZMUpdateEventTeamUpdate,
    ZMUpdateEventTeamMemberJoin,
    ZMUpdateEventTeamMemberLeave,
    ZMUpdateEventTeamConversationCreate,
    ZMUpdateEventTeamConversationDelete,
    ZMUpdateEventTeamMemberUpdate,
    
    ZMUpdateEvent_LAST  /// ->->->->->!!! Keep this at the end of this enum !!!<-<-<-<-<-
                        /// It is used to enumerate values. Hardcoding the values of this enums in tests gets very easily out of sync
};



@interface ZMUpdateEvent : NSObject

@property (nonatomic, readonly, copy, nonnull) NSDictionary *payload;
@property (nonatomic, readonly) ZMUpdateEventType type;
@property (nonatomic, readonly) ZMUpdateEventSource source;
@property (nonatomic, readonly, copy, nullable) NSUUID *uuid;

/// True if the event will not appear in the notification stream
@property (nonatomic, readonly) BOOL isTransient;

/// True if the event contains cryptobox-encrypted data
@property (nonatomic, readonly) BOOL isEncrypted;

/// True if the event is encoded with ZMGenericMessage
@property (nonatomic, readonly) BOOL isGenericMessageEvent;

/// True if the event had encrypted payload but now it has decrypted payload
@property (nonatomic, readonly) BOOL wasDecrypted;

/// Debug information
@property (nonatomic, readonly, nullable) NSString *debugInformation;

+ (nullable NSArray<ZMUpdateEvent *> *)eventsArrayFromPushChannelData:(nonnull id<ZMTransportData>)transportData;

/// Returns an array of @c ZMUpdateEvent from the given push channel data, the source will be set to @c
/// ZMUpdateEventSourceWebSocket, if a non-nil @c NSUUID is given for the @c pushStartingAt parameter, all
/// events earlier or equal to this uuid will have a source of @c ZMUpdateEventSourcePushNotification
+ (nullable NSArray *)eventsArrayFromPushChannelData:(nonnull id<ZMTransportData>)transportData pushStartingAt:(nullable NSUUID *)threshold;
+ (nullable NSArray<ZMUpdateEvent *> *)eventsArrayFromTransportData:(nonnull id<ZMTransportData>)transportData source:(ZMUpdateEventSource)source;

/// Creates an update event
+ (nullable instancetype)eventFromEventStreamPayload:(nonnull id<ZMTransportData>)payload uuid:(nullable NSUUID *)uuid;

/// Creates an update event that was encrypted and it's now decrypted
+ (nullable instancetype)decryptedUpdateEventFromEventStreamPayload:(nonnull id<ZMTransportData>)payload uuid:(nullable NSUUID *)uuid transient:(BOOL)transient source:(ZMUpdateEventSource)source;

+ (ZMUpdateEventType)updateEventTypeForEventTypeString:(nonnull NSString *)string;
+ (nullable NSString *)eventTypeStringForUpdateEventType:(ZMUpdateEventType)type;


/// True if this event type could have two versions, encrypted and non-encrypted, during the transition phase
- (BOOL)hasEncryptedAndUnencryptedVersion;

/// Adds debug information
- (void)appendDebugInformation:(nonnull NSString *)debugInformation;

@end




