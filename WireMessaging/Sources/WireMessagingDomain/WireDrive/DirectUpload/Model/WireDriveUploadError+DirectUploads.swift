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

package import Foundation

package extension WireDriveUploadError {

    /// Whether retrying the upload could plausibly succeed.

    var isRetryable: Bool {
        switch self {
        case .fileNotFound:
            false
        case .insufficientStorage:
            false
        case .urlError, .other, .unauthorized, .cancelledBySystem:
            true
        case let .serverError(statusCode):
            (500 ... 599).contains(statusCode)
        }
    }

    // MARK: - Persistence

    enum ReasonCode: Int16, Sendable, CaseIterable {
        case none = 0
        case fileNotFound = 1
        case urlError = 2
        case other = 3
        case serverError = 4
        case unauthorized = 5
        case insufficientStorage = 6
        case cancelledBySystem = 7
    }

    var reasonCode: ReasonCode {
        switch self {
        case .fileNotFound: .fileNotFound
        case .urlError: .urlError
        case .other: .other
        case .serverError: .serverError
        case .unauthorized: .unauthorized
        case .insufficientStorage: .insufficientStorage
        case .cancelledBySystem: .cancelledBySystem
        }
    }

    var reasonMessage: String? {
        switch self {
        case let .urlError(error): String(error.errorCode)
        case let .other(message): message
        case let .serverError(statusCode): String(statusCode)
        case .fileNotFound, .unauthorized, .insufficientStorage, .cancelledBySystem: nil
        }
    }

    init?(reasonCode: ReasonCode, message: String?) {
        switch reasonCode {
        case .none:
            return nil
        case .fileNotFound:
            self = .fileNotFound
        case .urlError:
            let code = message.flatMap(Int.init) ?? URLError.unknown.rawValue
            self = .urlError(error: URLError(URLError.Code(rawValue: code)))
        case .other:
            self = .other(message: message ?? "")
        case .serverError:
            self = .serverError(statusCode: message.flatMap(Int.init) ?? 0)
        case .unauthorized:
            self = .unauthorized
        case .insufficientStorage:
            self = .insufficientStorage
        case .cancelledBySystem:
            self = .cancelledBySystem
        }
    }
}
