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

// MARK: - WebsitePages

// swiftformat:sort
private enum WebsitePages {
    case legal
    case privacyPolicy
    case termsOfServices
}

// MARK: - TeamSource

enum TeamSource: Int {
    case onboarding
    case settings

    // MARK: Internal

    var parameterValue: String {
        switch self {
        case .onboarding: "client_landing"
        case .settings: "client_settings"
        }
    }
}

extension URL {
    var appendingLocaleParameter: URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        let localeQueryItem = URLQueryItem(name: "hl", value: Locale.current.identifier)

        var queryItems = components.queryItems ?? []
        queryItems.append(localeQueryItem)
        components.queryItems = queryItems

        return components.url ?? self
    }

    static func manageTeam(source: TeamSource) -> URL {
        let baseURL = BackendEnvironment.shared.teamsURL

        let queryItems = [
            URLQueryItem(name: "utm_source", value: source.parameterValue),
            URLQueryItem(name: "utm_term", value: "ios"),
        ]

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)

        components?.queryItems = queryItems

        return components!.url!.appendingLocaleParameter
    }
}

// MARK: - Wire URLs

extension URL {
    static var selfUserProfileLink: URL? {
        BackendEnvironment.selfUserProfileLink
    }
}

// MARK: - BackendEnvironment Standard URLs

extension BackendEnvironment {
    fileprivate static func websiteLink(path: String) -> URL {
        shared.websiteURL.appendingPathComponent(path)
    }

    fileprivate static func accountsLink(path: String) -> URL {
        shared.accountsURL.appendingPathComponent(path)
    }

    fileprivate static var selfUserProfileLink: URL? {
        guard let userID = SelfUser.provider?.providedSelfUser.remoteIdentifier?.uuidString else {
            return nil
        }
        return shared.accountsURL.appendingPathComponent("user-profile/?id=\(userID)")
    }
}
