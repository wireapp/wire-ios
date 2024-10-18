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

enum CoreDataEventsMigrationVersion: String, CoreDataMigrationVersion {

    private enum Constant {
        static let dataModelPrefix = "ZMEventModel"
        static let modelDirectory = "ZMEventModel.momd"
        static let resourceExtension = "mom"
    }

    // Note: add new versions here in first position!
    case v06 = "ZMEventModel6.0"
    case v05 = "ZMEventModel5.0"
    case v04 = "ZMEventModel4.0"
    case v03 = "ZMEventModel3.0"
    case v02 = "ZMEventModel2.0"
    case v01 = "ZMEventModel"

    var nextVersion: Self? {
        switch self {
        case .v06:
            return nil
        case .v05:
            return .v06
        case .v04:
            return .v05
        case .v01, .v02, .v03:
            return .v04
        }
    }

    /// Returns the version used in `.xcdatamodel`, like "2.3" for data model "ZMEventModel2.0".
    var dataModelVersion: String {
        rawValue.replacingOccurrences(of: Constant.dataModelPrefix, with: "")
    }

    // MARK: Current

    static let current: Self = {
        guard let current = allCases.first else {
            fatalError("no model versions found")
        }
        return current
    }()

    // MARK: Store URL

    func managedObjectModelURL() -> URL? {
        WireDataModelBundle.bundle.url(
            forResource: rawValue,
            withExtension: Constant.resourceExtension,
            subdirectory: Constant.modelDirectory
        )
    }
}
