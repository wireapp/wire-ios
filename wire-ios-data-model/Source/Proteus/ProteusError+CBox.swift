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
import WireCryptobox

public extension ProteusError {

    init?(cboxResult: CBoxResult) {
        switch cboxResult {
        case CBOX_STORAGE_ERROR:
            self = .storageError

        case CBOX_SESSION_NOT_FOUND:
            self = .sessionNotFound

        case CBOX_DECODE_ERROR:
            self = .decodeError

        case CBOX_REMOTE_IDENTITY_CHANGED:
            self = .remoteIdentityChanged

        case CBOX_INVALID_SIGNATURE:
            self = .invalidSignature

        case CBOX_INVALID_MESSAGE:
            self = .invalidMessage

        case CBOX_DUPLICATE_MESSAGE:
            self = .duplicateMessage

        case CBOX_TOO_DISTANT_FUTURE:
            self = .tooDistantFuture

        case CBOX_OUTDATED_MESSAGE:
            self = .outdatedMessage

        case CBOX_IDENTITY_ERROR:
            self = .identityError

        case CBOX_PREKEY_NOT_FOUND:
            self = .prekeyNotFound

        case CBOX_PANIC:
            self = .panic

        default:
            return nil
        }
    }

}
