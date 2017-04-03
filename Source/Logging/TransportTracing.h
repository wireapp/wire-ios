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



#import "TransportTracingProbes.h"
#import <WireTransport/NSString+UUID.h>
#import <WireTransport/NSObject+ZMTransportEncoding.h>





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
