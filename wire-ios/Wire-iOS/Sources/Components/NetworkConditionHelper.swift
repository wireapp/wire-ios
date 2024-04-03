// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import CoreTelephony
import WireSyncEngine

enum NetworkQualityType: Int, Comparable {
    case unknown = 0
    case type2G
    case type3G
    case type4G
    case typeWifi

    static func < (lhs: NetworkQualityType, rhs: NetworkQualityType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

struct NetworkConditionHelper {

    private let networkInfo = CTTelephonyNetworkInfo()
    private let serverConnection: ServerConnection

    init(serverConnection: ServerConnection) {
        self.serverConnection = serverConnection
    }

    func qualityType() -> NetworkQualityType {
        if serverConnection.isOffline {
            return .unknown
        }

        guard serverConnection.isMobileConnection else {
            return .typeWifi
        }

        return findBestQualityType()
    }

    private func findBestQualityType() -> NetworkQualityType {
        guard let cellularTypeDict = networkInfo.serviceCurrentRadioAccessTechnology else {
            return .unknown
        }

        return cellularTypeDict.values
            .map(qualityType(from:))
            .sorted()
            .last ?? .unknown
    }

    private func qualityType(from cellularTypeString: String) -> NetworkQualityType {
        switch cellularTypeString {
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            return .type2G

        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            return .type3G

        case CTRadioAccessTechnologyLTE:
            return .type4G

        default:
            return .unknown
        }
    }
}
