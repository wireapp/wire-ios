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


@import ZMTransport;
@import ZMCDataModel;

#import "ZMTracingProbes.h"



#pragma mark - ZMOperationLoop & ZMSyncStrategy

/// d = 0: enqueue
/// d = 1: stop enqueueing
/// d = 2: enqueueing, e = enqueue count
/// d = 3: on sync context, e = enqueue count
/// d = 4: created request, e -> request
/// d = 5: tried to enqueue request, e = 1 -> did have less than max
/// d = 6: request completion handler
static inline void ZMTraceOperationLoopEnqueueRequest(int d, int identifier, intptr_t e) {
    SYNCENGINE_SYNC_OPERATION_LOOP_ENQUEUE(d, identifier, e);
}
static inline void ZMTraceOperationLoopEnqueueRequest_id(int d, int identifier, id e) {
    SYNCENGINE_SYNC_OPERATION_LOOP_ENQUEUE(d, identifier, (intptr_t) (__bridge void *) e);
}

/// d = 0: start
/// d = 1: stop
static inline void ZMTraceOperationLoopPushChannelData(int d, int count) {
    SYNCENGINE_SYNC_OPERATION_LOOP_PUSH_CHANNEL_DATA(d, count);
}

/// d -> state
static inline void ZMTraceSyncStrategyGoToState(NSString* state) {
    if(state == nil) {
        state = @"<nil>";
    }
    SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE([state UTF8String]);
}
static inline void ZMTraceSyncStrategyDidLeaveState(NSString* state) {
    if(state == nil) {
        state = @"<nil>";
    }
    SYNCENGINE_SYNC_STRATEGY_LEAVE_STATE([state UTF8String]);
}
static inline BOOL ZMTraceSyncStrategyGoToStateEnabled(void) {
    return (BOOL) SYNCENGINE_SYNC_STRATEGY_GO_TO_STATE_ENABLED();
}
static inline BOOL ZMTraceSyncStrategyDidLeaveStateEnabled(void) {
    return (BOOL) SYNCENGINE_SYNC_STRATEGY_LEAVE_STATE_ENABLED();
}
/// d = 0: consume
static inline void ZMTraceSyncStrategyUpdateEvent(int d, int type) {
    SYNCENGINE_SYNC_STRATEGY_UPDATE_EVENT(d, type);
}
static inline BOOL ZMTraceSyncStrategyUpdateEventString_Enabled(void) {
    return (BOOL) SYNCENGINE_SYNC_STRATEGY_UPDATE_EVENT_STRING_ENABLED();
}
static inline void ZMTraceSyncStrategyUpdateEventString(int d, char const * type) {
    SYNCENGINE_SYNC_STRATEGY_UPDATE_EVENT_STRING(d, type);
}


#pragma mark - UI Notifications

/// d:
///   0 : ZMVoiceChannelStateChangedNotification
///       uuid1: conversation
///       e: previous, f: current (ZMVoiceChannelState)
///   1 : ZMVoiceChannelParticipantStateChangedNotification
///       uuid1: conversation
///       uuid2: user
///       e: previousJoined, f: currentJoined, g: connectionState
///   2 : ZMMessageChangeNotification
///   3 : ZMConversationChangeNotification
///       e: change flags
///   4 : ZMConversationListChangeNotification
///   5 : ZMUserChangeNotification
///       e: change flags
///   6 : ZMConversationMessageWindowNotification
///       e: change flags
///   7 : ZMNetworkAvailabilityChangeNotification
///       e: network state
static inline BOOL ZMTraceUserInterfaceNotificationEnabled(void) {
    return (BOOL) SYNCENGINE_UI_NOTIFICATION_ENABLED();
}
static inline void ZMTraceUserInterfaceNotification_UUID(int d, NSObject *obj, NSUUID *remoteID1, NSUUID *remoteID2, int e, int f, int g, int h) {
    if (SYNCENGINE_UI_NOTIFICATION_ENABLED()) {
        SYNCENGINE_UI_NOTIFICATION(d, (intptr_t) (__bridge void *) obj, remoteID1.transportString.UTF8String, remoteID2.transportString.UTF8String, e, f, g, h);
    }
}
static inline void ZMTraceUserInterfaceNotification_String(int d, NSObject *obj, NSUUID *remoteID1, NSString *string, int e, int f, int g, int h) {
    if (SYNCENGINE_UI_NOTIFICATION_ENABLED()) {
        SYNCENGINE_UI_NOTIFICATION(d, (intptr_t) (__bridge void *) obj, remoteID1.transportString.UTF8String, string.UTF8String, e, f, g, h);
    }
}


#pragma mark - Transcoders

static inline void ZMTraceTranscoderCallStateRequestUpdateIsJoined(int d, NSUUID * remoteIdentifier, int e) {
    if (SYNCENGINE_TRANSCODER_CALL_STATE_REQ_UPDATE_IS_JOINED_ENABLED()) {
        SYNCENGINE_TRANSCODER_CALL_STATE_REQ_UPDATE_IS_JOINED(d, remoteIdentifier.transportString.UTF8String, e);
    }
}



#pragma mark - ZMTransportSession and related

/// d = 0: sent an access token request
/// d = 1:  received an access token response, statusCode = HTTP status
/// d = 12: received an access token response, statusCode = URL error code
/// d = 2: parsed the access token response, statusCode = 'expires in'
/// d = 3: got new access token
/// d = 4: permanent error
/// d = 5: token failure
/// d = 6: permanent token failure
///
/// d = 100: send acces token request, but there's an old request already
/// d = 101: re-sending access token request
/// d = 102: access token task canceled, because scheduler can not send requests
/// d = 103: access token request finished successfully
static inline void ZMTraceTransportSessionAccessTokenRequest(int d, int statusCode, NSUInteger taskID) {
    SYNCENGINE_TRANSPORT_ACCESS_TOKEN_REQUEST(d, statusCode, (intptr_t) taskID);
}


/// d = 0: Creating new push channel
/// d = 1: Need to request new access token first
/// d = 2: Closing and removing consumer
/// d = 4: Open if closed. e = isOpen
///
/// d = 10: Creating new push channel, e: 1 -> was already open, exiting
/// d = 11: Consumer or group queue is invalid
/// d = 12: Is already creating
/// d = 13: Creating ZMPushChannel instance
/// d = 14: Creating now
/// d = 15: Creating with backoff
/// d = 16: Backoff timer expired -> enqueueing creating
static inline void ZMTraceTransportSessionPushChannel(int d, id pc, int e) {
    SYNCENGINE_TRANSPORT_PUSH_CHANNEL_CREATION(d, (intptr_t) (__bridge void *) pc, e);
}

static inline void ZMTraceTransportSessionPushChannelBackoff(int c, int milliseconds) {
    SYNCENGINE_TRANSPORT_PUSH_CHANNEL_CREATION_BACKOFF(c, milliseconds);
}

/// d = 0: did receive data
/// d = 1: did open
/// d = 2: did close
static inline void ZMTraceTransportSessionPushChannelEvent(int d, id pc, int e) {
    SYNCENGINE_TRANSPORT_PUSH_CHANNEL_CREATION_EVENT(d, (intptr_t) (__bridge void *) pc, e);
}


/// d = 0: all completed tasks
/// d = 1: access token response
static inline void ZMTraceTransportSessionTaskCompletedWithError(int d, NSUInteger taskID, NSError *error) {
    if (SYNCENGINE_TRANSPORT_SESSION_TASK_ERROR_ENABLED() && (error != nil)) {
        SYNCENGINE_TRANSPORT_SESSION_TASK_ERROR(d, (intptr_t) taskID, error.domain.UTF8String, (intptr_t) error.code);
    }
}

static inline void ZMTraceTransportSessionReachability(int d, int e) {
    SYNCENGINE_TRANSPORT_SESSION_REACHABILITY(d, e);
}


/// d = 0: set state, e = state
/// d = 1: set request count limit, e = count
/// d = 10: processing HTTP response, e = HTTP status, f = error code
/// d = 11: did receive access token, e = pending item count
/// d = 100: timer fired, e = 1 -> retry normal; e = 2 -> rate limit retry
static inline void ZMTraceTransportRequestScheduler(int d, int e, int f) {
    SYNCENGINE_TRANSPORT_REQUEST_SCHEDULER(d, e, f);
}
static inline void ZMTraceTransportRequestSchedulerObject(int d, id obj) {
    SYNCENGINE_TRANSPORT_REQUEST_SCHEDULER(d, (intptr_t) (__bridge void *) obj, 0);
}



/// d = 0: start
/// d = 1: stop
static inline void ZMTracePushChannelPingStartStop(id pc, int d, int milliseconds) {
    SYNCENGINE_TRANSPORT_PUSH_CHANNEL_PING_START_STOP((intptr_t) (__bridge void *) pc, d, milliseconds);
}

static inline void ZMTracePushChannelPingFired(id pc) {
    SYNCENGINE_TRANSPORT_PUSH_CHANNEL_PING_FIRED((intptr_t) (__bridge void *) pc);
}

/// d = 0: did complete handshake
/// d = 1: did receive text frame
/// d = 2: did receive binary frame
/// d = 3: did close
/// d = 100: webSocket created
static inline void ZMTracePushChannelEvent(id pc, id ws, int d) {
    SYNCENGINE_TRANSPORT_PUSH_CHANNEL_EVENT((intptr_t) (__bridge void *) pc, (intptr_t) (__bridge void *) ws, d);
}

/// d = 100: network socket pair created
/// d = 101: network socket did open
/// d = 102: network socket did receive data
/// d = 103: network socket did receive data, e -> frame type
/// d = 104: network socket did close
/// d = 105: network socket did receive data, failed to parse frame
/// d = 0: WebSocket open
/// d = 1: parsed handshake, e contains result
/// d = 2: Closing WebSocket
/// d = 3: Closing WebSocket and network socket
/// d = 4: Sending frame, e is frame type
/// d = 5: Delaying sending of frame: handshake did not complete, yet
static inline void ZMTraceWebSocketEvent(id ws, id ns, int d, int e) {
    SYNCENGINE_TRANSPORT_WEB_SOCKET_EVENT((intptr_t) (__bridge void *) ws, (intptr_t) (__bridge void *) ns, d, e);
}

/// d = 100: closing socket, e: 0 -> input, 1 -> output
/// d = 101: created socket, e: 0 -> input, 1 -> output
/// d = 102: socket event, e -> event code (NSStreamEvent)
/// d = 0: network socket init
/// d = 2: network socket open
/// d = 1: network socket close
/// d = 3: network socket read data from network, e -> byte count
/// d = 4: network socket wrote data to network, e -> byte count
static inline void ZMTraceNetworkSocketEvent(id ns, id sock, int d, int e) {
    SYNCENGINE_TRANSPORT_NETWORK_SOCKET_EVENT((intptr_t) (__bridge void *) ns, (intptr_t) (__bridge void *) sock, d, e);
}


#pragma mark - Calling

static inline BOOL ZMTraceCallSessionEnabled() {
    return (BOOL) SYNCENGINE_CALLING_SESSION_ENABLED();
}
static inline void ZMTraceCallSession(NSString *session) {
    SYNCENGINE_CALLING_SESSION(session.UTF8String);
}

static inline void ZMTraceCallDeviceIsActive(NSUUID *remoteIdentifier, int d) {
    if (SYNCENGINE_CALLING_DEVICE_IS_ACTIVE_ENABLED()) {
        SYNCENGINE_CALLING_DEVICE_IS_ACTIVE(remoteIdentifier.transportString.UTF8String, d);
    }
}

static inline void ZMTraceFlowManagerCategory(NSString *remoteIdentifier, int d) {
    if (SYNCENGINE_CALLING_FLOW_MANAGER_CATEGORY_ENABLED()) {
        SYNCENGINE_CALLING_FLOW_MANAGER_CATEGORY(remoteIdentifier.UTF8String, d);
    }
}

/// d = 0: push channel event
/// d = 1: downstream sync event
/// d = 2: upstream sync event
/// e = 0: user is idle
/// e = 1: user is joined
/// f = 0: user is other user
/// f = 1: user is self user
static inline void ZMTraceCallEventParticipant(NSUUID *conversation, NSUUID *user, int d, int e, int f) {
    if (SYNCENGINE_CALLING_PUSH_EVENT_PARTICIPANT_ENABLED() && d == 0) {
        SYNCENGINE_CALLING_PUSH_EVENT_PARTICIPANT(conversation.transportString.UTF8String, user.transportString.UTF8String, e, f);
    }
    if (SYNCENGINE_CALLING_DOWNSTREAM_EVENT_PARTICIPANT_ENABLED() && d == 1) {
        SYNCENGINE_CALLING_DOWNSTREAM_EVENT_PARTICIPANT(conversation.transportString.UTF8String, user.transportString.UTF8String, e, f);
    }
    if (SYNCENGINE_CALLING_UPSTREAM_EVENT_PARTICIPANT_ENABLED() && d == 2) {
        SYNCENGINE_CALLING_UPSTREAM_EVENT_PARTICIPANT(conversation.transportString.UTF8String, user.transportString.UTF8String, e, f);
    }
}

/// d = 0: push channel event
/// d = 1: downstream sync event
/// d = 2: upstream sync event
static inline void ZMTraceCallEventSelf(NSUUID *conversation, int d, int backendState, int currentState) {
    if (SYNCENGINE_CALLING_PUSH_EVENT_SELF_ENABLED() && d == 0) {
        SYNCENGINE_CALLING_PUSH_EVENT_SELF(conversation.transportString.UTF8String, backendState, currentState);
    }
    if (SYNCENGINE_CALLING_DOWNSTREAM_EVENT_SELF_ENABLED() && d == 1) {
        SYNCENGINE_CALLING_DOWNSTREAM_EVENT_SELF(conversation.transportString.UTF8String, backendState, currentState);
    }
    if (SYNCENGINE_CALLING_UPSTREAM_EVENT_SELF_ENABLED() && d == 2) {
        SYNCENGINE_CALLING_UPSTREAM_EVENT_SELF(conversation.transportString.UTF8String, backendState, currentState);
    }
}

static inline void ZMTraceCallFlowAcquire(NSString *conversation) {
    if (SYNCENGINE_CALLING_FLOW_ACQUIRE_ENABLED()) {
        SYNCENGINE_CALLING_FLOW_ACQUIRE(conversation.UTF8String);
    }
}
static inline void ZMTraceCallFlowRelease(NSString *conversation) {
    if (SYNCENGINE_CALLING_FLOW_RELEASE_ENABLED()) {
        SYNCENGINE_CALLING_FLOW_RELEASE(conversation.UTF8String);
    }
}

static inline void ZMTraceCallVoiceGain(NSUUID *conversation, NSUUID *user, double gain) {
    if (SYNCENGINE_CALLING_VOICE_GAIN_ENABLED()) {
        SYNCENGINE_CALLING_VOICE_GAIN(conversation.transportString.UTF8String, user.transportString.UTF8String, gain);
    }
}

#pragma mark - CoreData

static inline void ZMTraceObjectContextEnqueueSave(int d, int e, int f) {
    SYNCENGINE_CORE_DATA_ENQUEUE_SAVE(d, e, f);
}

static inline int managedObjectContextType(NSManagedObjectContext *moc) {
    if(moc.zm_isSyncContext) {
        return 1; // Sync
    }
    else if(moc.zm_isSearchContext) {
        return 2; // Search
    }
    return 0; // UI
}

static inline void ZMTraceObjectContextPerformStart(NSManagedObjectContext *moc) {
    if (SYNCENGINE_CORE_DATA_PERFORM_GROUP_ENTER_ENABLED()) {
        SYNCENGINE_CORE_DATA_PERFORM_GROUP_ENTER(managedObjectContextType(moc));
    }
}

static inline void ZMTraceObjectContextManualRefresh(NSManagedObject *managedObject) {
    if (SYNCENGINE_CORE_DATA_MANUAL_REFRESH_ENABLED()) {
        SYNCENGINE_CORE_DATA_MANUAL_REFRESH(managedObject.objectID.URIRepresentation.absoluteString.UTF8String, managedObjectContextType(managedObject.managedObjectContext));
    }
}

static inline void ZMTraceObjectContextPerformEnd() {
    SYNCENGINE_CORE_DATA_PERFORM_GROUP_EXIT();
}

#pragma mark - Auth

/// d = 0: OK
/// d = 1: Not found
/// d = 2: Error
static inline void ZMTraceAuthDeleteCookie(int d) {
    SYNCENGINE_AUTH_DELETE_COOKIE_DATA(d);
}

/// d = 0: OK
/// d = 1: Not found
/// d = 2: Error
static inline void ZMTraceAuthAddCookieData(int d) {
    SYNCENGINE_AUTH_ADD_COOKIE_DATA(d);
}

/// d = 0: OK
/// d = 1: Not found
/// d = 2: Error
static inline void ZMTraceAuthUpdateCookieData(int d) {
    SYNCENGINE_AUTH_UPDATE_COOKIE_DATA(d);
}

static inline void ZMTraceAuthLockedKeychainDetected() {
    SYNCENGINE_AUTH_DETECTED_LOCKED_KEYCHAIN();
}

static inline void ZMTraceAuthUserSessionStarted(BOOL hasCookie, BOOL hasCredentials) {
    SYNCENGINE_AUTH_USER_SESSION_STARTED(hasCookie, hasCredentials);
}

static inline void ZMTraceAuthUserSessionLogin(NSString* email, NSUInteger passwordLength) {
    SYNCENGINE_AUTH_USER_SESSION_LOGIN(email.UTF8String, (int) passwordLength);
}

static inline void ZMTraceAuthCredentialsDeleted() {
    SYNCENGINE_AUTH_CREDENTIALS_DELETED();
}

static inline void ZMTraceAuthCredentialsSet() {
    SYNCENGINE_AUTH_CREDENTIALS_SET();
}

static inline void ZMTraceAuthLoginStateFiredLoginTimer() {
    SYNCENGINE_AUTH_LOGIN_STATE_FIRE_LOGIN_TIMER();
}

/*
 d =    0: Credentials set, started login timer
        1: Self user is not complete, set needs slow sync
        2: Is done with login, start quick sync
        3: Entered
 */
static inline void ZMTraceAuthLoginStateEnter(int d) {
    SYNCENGINE_AUTH_LOGIN_STATE_ENTER(d);
}

/*
 d =    0: Has unregistered user, goto registration state
        1: No auth center, abort
        2: Done with login, goto quick sync
        3: Not logged in and credentials, create login request
        4: Logged in but no self user, create self user request
 */
@class ZMTransportRequest;
static inline void ZMTraceAuthLoginStateNextRequest(int d, ZMTransportRequest* request) {
    SYNCENGINE_AUTH_LOGIN_STATE_NEXT_REQUEST(d, request != nil);
}

static inline void ZMTraceAuthRequestWillContainToken(NSString *path) {
    SYNCENGINE_AUTH_REQUEST_WILL_CONTAIN_TOKEN(path.UTF8String);
}

static inline void ZMTraceAuthRequestWillContainCookie(NSString *path) {
    SYNCENGINE_AUTH_REQUEST_WILL_CONTAIN_COOKIE(path.UTF8String);
}

static inline void ZMTraceAuthTokenResponse(NSInteger httpStatus, BOOL hasNewAccessTokenData)
{
    SYNCENGINE_AUTH_ACCESS_TOKEN_RESPONSE((int) httpStatus, hasNewAccessTokenData);
}

#pragma mark - Images

static inline void ZMTraceImageDownsampleOriginal(NSUInteger size, NSString *format)
{
    SYNCENGINE_IMAGE_DOWNSAMPLE_ORIGINAL(size, format.UTF8String);
}

static inline void ZMTraceImageDownsampleScale(NSUInteger size, NSString *format)
{
    SYNCENGINE_IMAGE_DOWNSAMPLE_SCALE(size, format.UTF8String);
}

static inline void ZMTraceImageDownsampleRecompress(NSUInteger size, NSString *format)
{
    SYNCENGINE_IMAGE_DOWNSAMPLE_RECOMPRESS(size, format.UTF8String);
}
