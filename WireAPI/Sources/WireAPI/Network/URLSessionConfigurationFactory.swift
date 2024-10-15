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

struct URLSessionConfigurationFactory {

    let minTLSVersion: TLSVersion

    func makeRESTAPISessionConfiguration() -> URLSessionConfiguration {
        // TODO: [WPB-10447] support proxy mode
        let configuration = URLSessionConfiguration.ephemeral

        // If no data is transmitted for this amount of time for a request, it will time out.
        configuration.timeoutIntervalForRequest = 60

        // This is a conservative upper bound for a requested resource.
        configuration.timeoutIntervalForResource = 12 * 60

        // Don't accept any cookies. We store these ourselves.
        configuration.httpCookieAcceptPolicy = .never

        // Turn on HTTP pipelining.
        // RFC 2616 recommends no more than 2 connections per host when using pipelining.
        // https://tools.ietf.org/html/rfc2616
        configuration.httpShouldUsePipelining = true
        configuration.httpMaximumConnectionsPerHost = 1

        configuration.tlsMinimumSupportedProtocolVersion = minTLSVersion.secValue
        configuration.urlCache = nil
        return configuration
    }

    func makeWebSocketSessionConfiguration() -> URLSessionConfiguration {
        // TODO: [WPB-10447] support proxy mode
        let configuration = URLSessionConfiguration.ephemeral
        configuration.tlsMinimumSupportedProtocolVersion = minTLSVersion.secValue
        return configuration
    }

}
