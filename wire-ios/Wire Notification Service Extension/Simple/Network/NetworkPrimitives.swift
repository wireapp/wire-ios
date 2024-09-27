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

// MARK: - NetworkRequest

struct NetworkRequest {
    let path: String
    let httpMethod: HTTPMethod
    let contentType: ContentType
    let acceptType: AcceptType
}

// MARK: - HTTPMethod

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

// MARK: - ContentType

enum ContentType: String {
    case json = "application/json"
}

// MARK: - AcceptType

enum AcceptType: String {
    case json = "application/json"
}

// MARK: - NetworkResponse

enum NetworkResponse: CustomStringConvertible {
    case success(SuccessResponse)
    case failure(ErrorResponse)

    // MARK: Internal

    var description: String {
        switch self {
        case let .success(response):
            response.description

        case let .failure(response):
            response.description
        }
    }
}

// MARK: - SuccessResponse

struct SuccessResponse: CustomStringConvertible {
    let status: Int
    let data: Data

    var description: String {
        "status: \(status), data: \(data)"
    }
}

// MARK: - ErrorResponse

struct ErrorResponse: Codable, Equatable, CustomStringConvertible {
    let code: Int
    let label: String
    let message: String

    var description: String {
        "code: \(code), label: \(label), message: \(message)"
    }
}
