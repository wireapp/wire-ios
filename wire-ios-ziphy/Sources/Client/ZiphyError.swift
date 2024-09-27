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

/// The list of errors that can occur when interacting with the Giphy service.

public enum ZiphyError: Error {
    case malformedURL(String)
    case networkError(Error)
    case badResponseCode(Int)
    case badResponse(String)
    case jsonSerialization(Error)
    case noSuchResource
    case noMorePages
    case unknownError(Error)
    case requestRejected(Error)

    // MARK: Lifecycle

    init(_ error: Error) {
        self = (error as? ZiphyError) ?? .unknownError(error)
    }
}
