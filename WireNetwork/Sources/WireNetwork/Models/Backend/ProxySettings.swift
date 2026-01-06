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

import Foundation

/// Proxy settings for communicating with a backend server.

public enum ProxySettings: Sendable {

    /// Settings for an unauthenticated proxy.

    case unauthenticated(host: String, port: Int)

    /// Settings for an authenticated proxy.

    case authenticated(host: String, port: Int, username: String, password: String)

    /// Dictionary to be used with `URLSessionConfiguration.connectionProxyDictionary`.

    func proxyDictionary() -> [AnyHashable: Any] {
        let socksEnable = "SOCKSEnable"
        let socksProxy = "SOCKSProxy"
        let socksPort = "SOCKSPort"

        var result: [AnyHashable: Any] = [
            socksEnable: 1,
            kCFProxyTypeKey: kCFProxyTypeSOCKS,
            kCFStreamPropertySOCKSVersion: kCFStreamSocketSOCKSVersion5
        ]

        switch self {
        case let .unauthenticated(host, port):
            result[socksProxy] = host
            result[socksPort] = port
        case let .authenticated(host, port, username, password):
            result[socksProxy] = host
            result[socksPort] = port
            result[kCFStreamPropertySOCKSUser] = username
            result[kCFStreamPropertySOCKSPassword] = password
        }

        return result
    }

}

#if DEBUG
    extension ProxySettings: Equatable {}
#endif
