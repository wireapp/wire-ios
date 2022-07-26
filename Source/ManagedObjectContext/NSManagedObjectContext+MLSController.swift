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

extension NSManagedObjectContext {

    private static let mlsControllerUserInfoKey = "MLSControllerUserInfoKey"

    public var isMLSControllerInitialized: Bool {
        return mlsController != nil
    }

    public var mlsController: MLSControllerProtocol? {
        precondition(zm_isSyncContext, "MLSController should only be accessed on the sync context")
        return userInfo[Self.mlsControllerUserInfoKey] as? MLSControllerProtocol
    }

    public func initializeMLSController(coreCrypto: CoreCryptoProtocol) {
        precondition(zm_isSyncContext, "MLSController should only be accessed on the sync context")
        let mlsController = MLSController(context: self, coreCrypto: coreCrypto)
        userInfo[Self.mlsControllerUserInfoKey] = mlsController
    }

    /// Test helper for setting a mock controller.
    ///
    /// Unfortunately this is necessary as we have test logic in other frameworks.

    public func test_setMockMLSController(_ controller: MLSControllerProtocol) {
        userInfo[Self.mlsControllerUserInfoKey] = controller
    }

}
