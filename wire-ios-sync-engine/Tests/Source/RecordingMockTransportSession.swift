//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import Foundation
import WireTransport

@objcMembers
class RecordingMockTransportSession: NSObject, TransportSessionType {
    // MARK: Lifecycle

    init(cookieStorage: ZMPersistentCookieStorage, pushChannel: ZMPushChannel) {
        self.pushChannel = pushChannel
        self.cookieStorage = cookieStorage

        super.init()
    }

    // MARK: Internal

    var pushChannel: ZMPushChannel
    var cookieStorage: ZMPersistentCookieStorage
    var requestLoopDetectionCallback: ((String) -> Void)?

    let mockReachability = MockReachability()
    var didCallEnterBackground = false
    var didCallEnterForeground = false
    var lastEnqueuedRequest: ZMTransportRequest?
    var didCallSetNetworkStateDelegate = false
    var didCallConfigurePushChannel = false
    var renewAccessTokenCalls = [String]()

    var reachability: ReachabilityProvider & TearDownCapable {
        mockReachability
    }

    func tearDown() {}

    func enterBackground() {
        didCallEnterBackground = true
    }

    func enterForeground() {
        didCallEnterForeground = true
    }

    func prepareForSuspendedState() {}

    func cancelTask(with taskIdentifier: ZMTaskIdentifier) {}

    func enqueue(_ request: ZMTransportRequest, queue: GroupQueue) async -> ZMTransportResponse {
        lastEnqueuedRequest = request
        return ZMTransportResponse(payload: nil, httpStatus: 200, transportSessionError: nil, apiVersion: 0)
    }

    func enqueueOneTime(_ request: ZMTransportRequest) {
        lastEnqueuedRequest = request
    }

    func attemptToEnqueueSyncRequest(generator: () -> ZMTransportRequest?) -> ZMTransportEnqueueResult {
        guard let request = generator() else {
            return ZMTransportEnqueueResult(didHaveLessRequestsThanMax: true, didGenerateNonNullRequest: false)
        }

        lastEnqueuedRequest = request

        return ZMTransportEnqueueResult(didHaveLessRequestsThanMax: true, didGenerateNonNullRequest: true)
    }

    func setAccessTokenRenewalFailureHandler(_: @escaping ZMCompletionHandlerBlock) {}

    func setAccessTokenRenewalSuccessHandler(_: @escaping ZMAccessTokenHandlerBlock) {}

    func setAccessTokenRenewalSuccessHandler(handler: @escaping ZMAccessTokenHandlerBlock) {}

    func setNetworkStateDelegate(_: ZMNetworkStateDelegate?) {
        didCallSetNetworkStateDelegate = true
    }

    func addCompletionHandlerForBackgroundSession(identifier: String, handler: @escaping () -> Void) {}

    func configurePushChannel(consumer: ZMPushChannelConsumer, groupQueue: GroupQueue) {
        didCallConfigurePushChannel = true
    }

    func renewAccessToken(with clientID: String) {
        renewAccessTokenCalls.append(clientID)
    }
}
