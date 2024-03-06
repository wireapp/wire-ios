////
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

enum CoreDataMessagingMigrationVersion: String, CaseIterable {

    private enum Constant {
        static let dataModelPrefix = "zmessaging"
        static let modelDirectory = "zmessaging.momd"
        static let resourceExtension = "mom"
    }

    // MARK: -

    // Note: add new versions here in first position!
    case version2_111 = "zmessaging2.111.0"
    case version2_110 = "zmessaging2.110.0"
    case version2_109 = "zmessaging2.109.0"
    case version2_108 = "zmessaging2.108.0"
    case version2_107 = "zmessaging2.107.0"
    case version2_106 = "zmessaging2.106.0"
    case version2_105 = "zmessaging2.105.0"
    case version2_104 = "zmessaging2.104.0"
    case version2_103 = "zmessaging2.103.0"
    case version2_102 = "zmessaging2.102.0"
    case version2_101 = "zmessaging2.101.0"
    case version2_100 = "zmessaging2.100.0"
    case version2_99 = "zmessaging2.99.0"
    case version2_98 = "zmessaging2.98.0"
    case version2_97 = "zmessaging2.97.0"
    case version2_96 = "zmessaging2.96.0"
    case version2_95 = "zmessaging2.95.0"
    case version2_94 = "zmessaging2.94.0"
    case version2_93 = "zmessaging2.93.0"
    case version2_92 = "zmessaging2.92.0"
    case version2_91 = "zmessaging2.91.0"
    case version2_90 = "zmessaging2.90.0"
    case version2_89 = "zmessaging2.89.0"
    case version2_88 = "zmessaging2.88.0"
    case version2_87 = "zmessaging2.87.0"
    case version2_86 = "zmessaging2.86.0"
    case version2_85 = "zmessaging2.85.0"
    case version2_84 = "zmessaging2.84.0"
    case version2_83 = "zmessaging2.83.0"
    case version2_82 = "zmessaging2.82.0"
    case version2_81 = "zmessaging2.81.0"
    case version2_80 = "zmessaging2.80.0"

    var nextVersion: Self? {
        switch self {
        case .version2_111:
            return nil
        case .version2_110:
            return .version2_111
        case .version2_109:
            return .version2_110
        case .version2_108:
            return .version2_109
        case .version2_107:
            return .version2_108
        case .version2_106:
            return .version2_107
        case .version2_80,
                .version2_81,
                .version2_82,
                .version2_83,
                .version2_84,
                .version2_85,
                .version2_86,
                .version2_87,
                .version2_88,
                .version2_89,
                .version2_90,
                .version2_91,
                .version2_92,
                .version2_93,
                .version2_94,
                .version2_95,
                .version2_96,
                .version2_97,
                .version2_98,
                .version2_99,
                .version2_100,
                .version2_101,
                .version2_102,
                .version2_103,
                .version2_104,
                .version2_105:
            return .version2_106
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
}
