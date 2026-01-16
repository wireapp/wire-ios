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
public import WireLogging

public final class WireDatadog {

    public var userIdentifier: String? {
        nil
    }

    public init(
        applicationID: String,
        buildVersion: String,
        buildNumber: String,
        clientToken: String,
        identifierForVendor: UUID?,
        environmentName: String
    ) {
        // do nothing
    }

    public func enable() {
        // do nothing
    }

    public func log(
        level: WireLogType,
        message: String,
        error: (any Error)? = nil,
        attributes: [String: any Encodable]
    ) {
        // do nothing
    }

    public func addAttribute(forKey key: String, value: String) {
        // do nothing
    }

    public func removeAttribute(forKey key: String) {
        // do nothing
    }
}
