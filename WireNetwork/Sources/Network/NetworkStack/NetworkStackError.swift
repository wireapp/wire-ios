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

/// Errors originating from `NetworkStack`.

public enum NetworkStackError: Error {

    /// Proxy credentials are required but none are
    /// available

    case proxyCredentialsRequired

    /// The API version of the connected backend is
    /// too old for this client, i.e the max available
    /// API version is lower than the min API version
    /// that this client supports.

    case backendAPIVersionObsolete

    /// The API version of this client is too old
    /// for the connected backend, i.e the max API version
    /// that this client supports is lower than the min
    /// available API version on the backend.

    case clientAPIVersionObsolete

}
