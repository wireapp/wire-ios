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

public final class BackendEndpoints: NSObject, BackendEndpointsProvider, Codable {

    public let backendURL: URL
    public let backendWSURL: URL
    public let blackListURL: URL
    public let teamsURL: URL
    public let accountsURL: URL
    public let websiteURL: URL
    public let countlyURL: URL?

    public init(
        backendURL: URL,
        backendWSURL: URL,
        blackListURL: URL,
        teamsURL: URL,
        accountsURL: URL,
        websiteURL: URL,
        countlyURL: URL?
    ) {
        self.backendURL = backendURL
        self.backendWSURL = backendWSURL
        self.blackListURL = blackListURL
        self.teamsURL = teamsURL
        self.accountsURL = accountsURL
        self.websiteURL = websiteURL
        self.countlyURL = countlyURL

        super.init()
    }
}
