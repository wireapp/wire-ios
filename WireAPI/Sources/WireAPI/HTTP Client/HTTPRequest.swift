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

/// A http request to be sent to a server.

public struct HTTPRequest: Equatable {
    // MARK: Lifecycle

    /// Create a new request.

    public init(
        path: String,
        method: HTTPRequest.Method,
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.body = body
    }

    // MARK: Public

    /// A type of http request.

    public enum Method {
        case delete
        case get
        case head
        case post
        case put
    }

    /// The path of the endpoint.

    public var path: String

    /// The http method.

    public var method: Method

    /// The request payload data.

    public var body: Data?
}
