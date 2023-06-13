//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireCoreCrypto

extension NSManagedObjectContext {

    private static let mlsServiceUserInfoKey = "MLSServiceUserInfoKey"

    public var mlsService: MLSServiceInterface? {
        get {
            precondition(zm_isSyncContext, "MLSService should only be accessed on the sync context")
            return userInfo[Self.mlsServiceUserInfoKey] as? MLSServiceInterface
        }

        set {
            precondition(zm_isSyncContext, "MLSService should only be accessed on the sync context")
            userInfo[Self.mlsServiceUserInfoKey] = newValue
        }
    }

    private static let mlsDecryptionServiceUserInfoKey = "MLSDecryptionServiceUserInfoKey"

    public var mlsDecryptionService: MLSDecryptionServiceInterface? {
        get {
            precondition(zm_isSyncContext, "MLDecryptionSService should only be accessed on the sync context")
            return mlsService ?? userInfo[Self.mlsDecryptionServiceUserInfoKey] as? MLSDecryptionServiceInterface
        }

        set {
            precondition(zm_isSyncContext, "MLDecryptionSService should only be accessed on the sync context")
            userInfo[Self.mlsDecryptionServiceUserInfoKey] = newValue
        }
    }

    private static let mlsEncryptionServiceUserInfoKey = "MLSEncryptionServiceUserInfoKey"

    public var mlsEncryptionService: MLSEncryptionServiceInterface? {
        get {
            precondition(zm_isSyncContext, "MLEncryptionSService should only be accessed on the sync context")
            return mlsService ?? userInfo[Self.mlsEncryptionServiceUserInfoKey] as? MLSEncryptionServiceInterface
        }

        set {
            precondition(zm_isSyncContext, "MLEncryptionSService should only be accessed on the sync context")
            userInfo[Self.mlsEncryptionServiceUserInfoKey] = newValue
        }
    }

}
