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
        static let modelDirectory = "zmessaging.momd"
        static let resourceExtension = "mom"
    }

    // TODO: add more old versions!
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
    case version2_79 = "zmessaging2.79.0"
    case version2_78 = "zmessaging2.78.0"
    case version2_77 = "zmessaging2.77.0"
    case version2_76 = "zmessaging2.76.0"
    case version2_75 = "zmessaging2.75.0"
    case version2_74 = "zmessaging2.74.0"
    case version2_73 = "zmessaging2.73.0"
    case version2_72 = "zmessaging2.72.0"
    case version2_71 = "zmessaging2.71.0"
    case version2_70 = "zmessaging2.70.0"
    case version2_69 = "zmessaging2.69.0"
    case version2_68 = "zmessaging2.68.0"
    case version2_67 = "zmessaging2.67.0"
    case version2_66 = "zmessaging2.66.0"
    case version2_65 = "zmessaging2.65.0"
    case version2_64 = "zmessaging2.64.0"
    case version2_63 = "zmessaging2.63.0"
    case version2_62 = "zmessaging2.62.0"
    case version2_61 = "zmessaging2.61.0"
    case version2_60 = "zmessaging2.60.0"
    case version2_59 = "zmessaging2.59.0"
    case version2_58 = "zmessaging2.58.0"
    case version2_57 = "zmessaging2.57.0"
    case version2_56 = "zmessaging2.56.0"
    case version2_55 = "zmessaging2.55.0"
    case version2_54 = "zmessaging2.54.0"
    case version2_53 = "zmessaging2.53.0"
    case version2_52 = "zmessaging2.52.0"
    case version2_51 = "zmessaging2.51.0"
    case version2_50 = "zmessaging2.50.0"
    case version2_49 = "zmessaging2.49.0"
    case version2_48 = "zmessaging2.48.0"
    case version2_47 = "zmessaging2.47.0"
    case version2_46 = "zmessaging2.46.0"
    case version2_45 = "zmessaging2.45.0"
    case version2_44 = "zmessaging2.44.0"
    case version2_43 = "zmessaging2.43.0"
    case version2_42 = "zmessaging2.42.0"
    case version2_41 = "zmessaging2.41.0"
    case version2_40 = "zmessaging2.40.0"
    case version2_39 = "zmessaging2.39.0"
    case version2_31 = "zmessaging2.31.0"
    case version2_30 = "zmessaging2.30.0"
    case version2_29 = "zmessaging2.29.0"
    case version2_28 = "zmessaging2.28.0"
    case version2_27 = "zmessaging2.27.0"
    case version2_26 = "zmessaging2.26.0"
    case version2_25 = "zmessaging2.25.0"
    case version2_24_1 = "zmessaging2.24.1"
    case version2_24 = "zmessaging2.24"
    case version2_21_2 = "zmessaging2.21.2"
    case version2_21_1 = "zmessaging2.21.1"
    case version2_21 = "zmessaging2.21.0"
    case version2_18 = "zmessaging2.18.0"
    case version2_17 = "zmessaging2.17.0"
    case version2_15 = "zmessaging2.15.0"
    case version2_11 = "zmessaging2.11"
    case version2_10 = "zmessaging2.10"
    case version2_9 = "zmessaging2.9"
    case version2_8 = "zmessaging2.8"
    case version2_7 = "zmessaging2.7"
    case version2_6 = "zmessaging2.6"
    case version2_5 = "zmessaging2.5"
    case version2_4 = "zmessaging2.4"
    case version2_3 = "zmessaging2.3"
    case version1_28 = "zmessaging1.28"
    case version1_27 = "zmessaging1.27"
    case version1 = "zmessaging"

    var nextVersion: Self? {
        switch self {
        case .version2_109:
            return nil
        case .version2_108:
            return .version2_109
        case .version2_107:
            return .version2_108
        case .version2_106:
            return .version2_107
        default:
            // old the oldest version can be inferred to 106
            return .version2_106
        }
    }

    // MARK: - Current

    static let current: Self = {
        guard let current = allCases.first else {
            fatalError("no model versions found")
        }

        return current
    }()

    func managedObjectModelURL() -> URL? {
        WireDataModelBundle.bundle.url(
            forResource: rawValue,
            withExtension: Constant.resourceExtension,
            subdirectory: Constant.modelDirectory
        )
    }
}
