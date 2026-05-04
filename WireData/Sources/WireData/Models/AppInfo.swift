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

import CoreData

/// Additional information about an app.

public final class AppInfo: NSManagedObject {

    /// The name of the associated Core Data entity.

    public static let entityName = "AppInfo"

    /// The category name of the app (e.g., `"other"`).

    @NSManaged public var category: String

    /// A short description of the app (max 300 characters).
    ///
    /// - Note: This corresponds to the `description` field in the API
    ///   but is renamed to avoid shadowing `NSObject.description`.

    @NSManaged public var appDescription: String

}
