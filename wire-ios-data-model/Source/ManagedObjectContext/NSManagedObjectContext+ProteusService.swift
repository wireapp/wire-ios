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

extension NSManagedObjectContext {

    private static let proteusServiceUserInfoKey = "ProteusServiceUserInfoKey"

    public var isProteusServiceInitialized: Bool {
        return proteusService != nil
    }

    public var proteusService: ProteusServiceInterface? {
        precondition(zm_isSyncContext, "ProteusService should only be accessed on the sync context")
        return userInfo[Self.proteusServiceUserInfoKey] as? ProteusServiceInterface
    }

    public func initializeProteusService(coreCrypto: CoreCryptoProtocol) {
        precondition(zm_isSyncContext, "ProteusService should only be accessed on the sync context")
        userInfo[Self.proteusServiceUserInfoKey] = ProteusService(coreCrypto: coreCrypto)
    }

}
