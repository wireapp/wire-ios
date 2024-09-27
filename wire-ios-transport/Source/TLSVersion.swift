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

public enum TLSVersion {
    case v1_2
    case v1_3

    // MARK: Lifecycle

    public init?(_ string: String) {
        switch string {
        case "1.2":
            self = .v1_2

        case "1.3":
            self = .v1_3

        default:
            return nil
        }
    }

    // MARK: Public

    public var secValue: tls_protocol_version_t {
        switch self {
        case .v1_2:
            .TLSv12

        case .v1_3:
            .TLSv13
        }
    }

    public static func minVersionFrom(_ string: String?) -> TLSVersion {
        string.flatMap(TLSVersion.init) ?? .v1_2
    }
}
