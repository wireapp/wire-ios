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

enum CoreDataMessagingMigrationVersion: String, CoreDataMigrationVersion {

    private enum Constant {
        static let dataModelPrefix = "zmessaging"
        static let modelDirectory = "zmessaging.momd"
        static let resourceExtension = "mom"
    }

    // MARK: -

    // Note: add new versions here in first position!
    case v119 = "zmessaging2.119.0"
    case v118 = "zmessaging2.118.0"
    case v117 = "zmessaging2.117.0"
    case v116 = "zmessaging2.116.0"
    case v115 = "zmessaging2.115.0"
    case v114 = "zmessaging2.114.0"
    case v113 = "zmessaging2.113.0"
    case v112 = "zmessaging2.112.0"
    case v111 = "zmessaging2.111.0"
    case v110 = "zmessaging2.110.0"
    case v109 = "zmessaging2.109.0"
    case v108 = "zmessaging2.108.0"
    case v107 = "zmessaging2.107.0"
    case v106 = "zmessaging2.106.0"
    case v105 = "zmessaging2.105.0"
    case v104 = "zmessaging2.104.0"
    case v103 = "zmessaging2.103.0"
    case v102 = "zmessaging2.102.0"
    case v101 = "zmessaging2.101.0"
    case v100 = "zmessaging2.100.0"
    case v99 = "zmessaging2.99.0"
    case v98 = "zmessaging2.98.0"
    case v97 = "zmessaging2.97.0"
    case v96 = "zmessaging2.96.0"
    case v95 = "zmessaging2.95.0"
    case v94 = "zmessaging2.94.0"
    case v93 = "zmessaging2.93.0"
    case v92 = "zmessaging2.92.0"
    case v91 = "zmessaging2.91.0"
    case v90 = "zmessaging2.90.0"
    case v89 = "zmessaging2.89.0"
    case v88 = "zmessaging2.88.0"
    case v87 = "zmessaging2.87.0"
    case v86 = "zmessaging2.86.0"
    case v85 = "zmessaging2.85.0"
    case v84 = "zmessaging2.84.0"
    case v83 = "zmessaging2.83.0"
    case v82 = "zmessaging2.82.0"
    case v81 = "zmessaging2.81.0"
    case v80 = "zmessaging2.80.0"

    var nextVersion: Self? {
        switch self {
        case .v119:
            return nil
        case .v116, .v117, .v118:
            return .v119
        case .v115,
                .v114:
            return .v116 // destination version runs custom migration actions
        case .v111,
                .v112,
                .v113:
            return .v114 // destination version runs custom migration actions
        case .v110:
            return .v111 // destination version runs custom migration actions
        case .v107,
                .v108,
                .v109:
            return .v110
        case .v106:
            return .v107 // destination version runs custom migration actions
        case .v80,
                .v81,
                .v82,
                .v83,
                .v84,
                .v85,
                .v86,
                .v87,
                .v88,
                .v89,
                .v90,
                .v91,
                .v92,
                .v93,
                .v94,
                .v95,
                .v96,
                .v97,
                .v98,
                .v99,
                .v100,
                .v101,
                .v102,
                .v103,
                .v104,
                .v105:
            return .v106
        }
    }

    /// Returns the version used in `.xcdatamodel`, like "2.3" for data model "zmessaging2.3".
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

    static var allFixtureVersions: [String] {
        allCases.map {
            $0.dataModelVersion.replacingOccurrences(of: ".", with: "-")
        }
    }
}
