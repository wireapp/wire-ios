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

public final class MockEnvironment: NSObject, BackendEnvironmentProvider {
    // MARK: Public

    public var title = "Example"
    public var backendURL = URL(string: "http://example.com")!
    public var backendWSURL = URL(string: "http://example.com")!
    public var blackListURL = URL(string: "http://example.com")!
    public var teamsURL = URL(string: "http://example.com")!
    public var accountsURL = URL(string: "http://example.com")!
    public var websiteURL = URL(string: "http://example.com")!
    public var countlyURL: URL? = URL(string: "http://example.com")!
    public var proxy: ProxySettingsProvider? = ProxySettings(
        host: "socks5.example.com",
        port: 8080,
        needsAuthentication: true
    )
    public var environmentType = EnvironmentTypeProvider(environmentType: .production)

    public func verifyServerTrust(trust: SecTrust, host: String?) -> Bool {
        isServerTrusted
    }

    // MARK: Internal

    var isServerTrusted = true
}
