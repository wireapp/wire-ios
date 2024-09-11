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

@objc
public protocol TransportSessionType: ZMBackgroundable, ZMRequestCancellation, TearDownCapable {
    var reachability: ReachabilityProvider & TearDownCapable { get }

    var pushChannel: ZMPushChannel { get }

    var cookieStorage: ZMPersistentCookieStorage { get }

    var requestLoopDetectionCallback: ((_ path: String) -> Void)? { get set }

    @objc(enqueueOneTimeRequest:)
    func enqueueOneTime(_ request: ZMTransportRequest)

    @objc(enqueueRequest:queue:completionHandler:)
    func enqueue(_ request: ZMTransportRequest, queue: GroupQueue) async -> ZMTransportResponse

    @objc(attemptToEnqueueSyncRequestWithGenerator:)
    func attemptToEnqueueSyncRequest(generator: ZMTransportRequestGenerator) -> ZMTransportEnqueueResult

    @objc(setAccessTokenRenewalFailureHandler:)
    func setAccessTokenRenewalFailureHandler(_ handler: @escaping ZMCompletionHandlerBlock)

    @objc(setAccessTokenRenewalSuccessHandler:)
    func setAccessTokenRenewalSuccessHandler(_ handler: @escaping ZMAccessTokenHandlerBlock)

    func setNetworkStateDelegate(_ delegate: ZMNetworkStateDelegate?)

    @objc(addCompletionHandlerForBackgroundSessionWithIdentifier:handler:)
    func addCompletionHandlerForBackgroundSession(identifier: String, handler: @escaping () -> Void)

    @objc(configurePushChannelWithConsumer:groupQueue:)
    func configurePushChannel(consumer: ZMPushChannelConsumer, groupQueue: GroupQueue)

    @objc(renewAccessTokenWithClientID:)
    func renewAccessToken(with clientID: String)
}

extension ZMTransportSession: TransportSessionType {}

@objc
extension ZMTransportSession {
    public static func foregroundSessionConfiguration(minTLSVersion: String?) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral

        // If not data is transmitted for this amount of time for a request, it will time out.
        // <https://wearezeta.atlassian.net/browse/MEC-622>.
        // Note that it is ok for the request to take longer, we just require there to be _some_ data to be transmitted
        // within this time window.
        configuration.timeoutIntervalForRequest = 60

        // This is a conservative (!) upper bound for a requested resource:
        configuration.timeoutIntervalForResource = 12 * 60

        // NB.: that TCP will on it's own retry. We should be very careful not to stop a request too early. It is better for a request to complete after 50 s (on a high latency network) in stead of continuously trying and timing out after 30 s.
        setUpConfiguration(configuration, minTLSVersion: minTLSVersion)
        return configuration
    }

    public static func backgroundSessionConfiguration(
        sharedContainerIdentifier: String,
        userIdentifier: UUID,
        minTLSVersion: String?
    ) -> URLSessionConfiguration {
        let bundleIdentifier = Bundle.main.bundleIdentifier
        let resolvedBundleIdentifier = bundleIdentifier ?? "com.wire.background-session"
        let identifier = identifierWith(
            prefix: resolvedBundleIdentifier,
            userIdentifier: userIdentifier
        )
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        setUpConfiguration(configuration, minTLSVersion: minTLSVersion)
        configuration.sharedContainerIdentifier = sharedContainerIdentifier
        return configuration
    }

    public static func setUpConfiguration(
        _ configuration: URLSessionConfiguration,
        minTLSVersion: String?
    ) {
        // Don't accept any cookies. We store these ourselves.
        configuration.httpCookieAcceptPolicy = .never

        // Turn on HTTP pipelining
        // RFC 2616 recommends no more than 2 connections per host when using pipelining.
        // https://tools.ietf.org/html/rfc2616
        configuration.httpShouldUsePipelining = true
        configuration.httpMaximumConnectionsPerHost = 1

        let minTLSVersion = TLSVersion.minVersionFrom(minTLSVersion)
        configuration.tlsMinimumSupportedProtocolVersion = minTLSVersion.secValue

        configuration.urlCache = nil
    }

    public static func identifierWith(
        prefix: String,
        userIdentifier: UUID
    ) -> String {
        "\(prefix)-\(userIdentifier.transportString())"
    }
}
