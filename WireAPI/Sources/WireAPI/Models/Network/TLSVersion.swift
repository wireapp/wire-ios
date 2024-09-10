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

/// Supported TLS versions.

public enum TLSVersion {

    /// TLS version 1.2

    case v1_2

    /// TLS version 1.3

    case v1_3

    var secValue: tls_protocol_version_t {
        switch self {
        case .v1_2:
            .TLSv12

        case .v1_3:
            .TLSv13
        }
    }
}
