//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

public import Foundation

public struct URLSessionConfigurationFactory {

    let minTLSVersion: TLSVersion
    let proxySettings: ProxySettings?

    public init(
        minTLSVersion: TLSVersion,
        proxySettings: ProxySettings?
    ) {
        self.minTLSVersion = minTLSVersion
        self.proxySettings = proxySettings
    }

    public func makeRESTAPISessionConfiguration() -> URLSessionConfiguration {
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

        if let proxySettings {
            configuration.connectionProxyDictionary = proxySettings.proxyDictionary()
        }

        return configuration
    }

    public func makeWebSocketSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.tlsMinimumSupportedProtocolVersion = minTLSVersion.secValue

        if let proxySettings {
            configuration.connectionProxyDictionary = proxySettings.proxyDictionary()
        }

        return configuration
    }

    public func makeBlacklistSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.tlsMinimumSupportedProtocolVersion = minTLSVersion.secValue
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        if let proxySettings {
            configuration.connectionProxyDictionary = proxySettings.proxyDictionary()
            configuration.httpShouldUsePipelining = true
        }

        return configuration
    }

}
