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

/// A list of HTTP status codes (https://developer.mozilla.org/en-US/docs/Web/HTTP/Status#successful_responses)

enum HTTPStatusCode: Int {

    // MARK: Success - 2xx

    /// ok - 200

    case ok = 200

    // MARK: Client Errors - 4xx

    /// bad request - 400

    case badRequest = 400

    /// not found - 404

    case notFound = 404

    /// forbidden - 403

    case forbidden = 403

    // MARK: Server Errors - 5xx

    /// service unavailable - 503

    case serviceUnavailable = 503

}
