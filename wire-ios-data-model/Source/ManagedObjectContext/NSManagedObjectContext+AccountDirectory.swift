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

public extension NSManagedObjectContext {

    private static let AccountDirectoryURLKey = "AccountDirectoryURLKey"

    var accountDirectoryURL: URL? {
        get {
            precondition(zm_isSyncContext, "accountDirectoryURL should only be accessed on the sync context")
            return userInfo[Self.AccountDirectoryURLKey] as? URL
        }

        set {
            precondition(zm_isSyncContext, "accountDirectoryURL should only be accessed on the sync context")
            userInfo[Self.AccountDirectoryURLKey] = newValue
        }
    }

    private static let ApplicationContainerURLKey = "ApplicationContainerURLKey"

    var applicationContainerURL: URL? {
        get {
            precondition(zm_isSyncContext, "applicationContainerURL should only be accessed on the sync context")
            return userInfo[Self.ApplicationContainerURLKey] as? URL
        }

        set {
            precondition(zm_isSyncContext, "applicationContainerURL should only be accessed on the sync context")
            userInfo[Self.ApplicationContainerURLKey] = newValue
        }
    }

}
