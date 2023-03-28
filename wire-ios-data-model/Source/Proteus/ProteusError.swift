//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public enum ProteusError: Error, Equatable {

    case storageError
    case sessionNotFound
    case decodeError
    case remoteIdentityChanged
    case invalidSignature
    case invalidMessage
    case duplicateMessage
    case tooDistantFuture
    case outdatedMessage
    case identityError
    case prekeyNotFound
    case panic
    case unknown(code: UInt32)

    init?(code: UInt32) {
        switch code {
        case 0:
            return nil

        case 501:
            self = .storageError

        case 102:
            self = .sessionNotFound

        case 3, 301, 302, 303:
            self = .decodeError

        case 204:
            self = .remoteIdentityChanged

        case 206, 207, 210:
            self = .invalidSignature

        case 200, 201, 202, 205, 213:
            self = .invalidMessage

        case 209:
            self = .duplicateMessage

        case 211, 212:
            self = .tooDistantFuture

        case 208:
            self = .outdatedMessage

        case 300:
            self = .identityError

        case 101:
            self = .prekeyNotFound

        case 5:
            self = .panic

        default:
            self = .unknown(code: code)
        }
    }

}

