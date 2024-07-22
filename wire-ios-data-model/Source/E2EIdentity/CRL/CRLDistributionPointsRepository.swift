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

// TODO: copy the code from `CRLExpirationDatesRepository` and update the API to provide endpoints to get the list of distributions points + list of DP that don't have an expiry date yet

public protocol CRLDistributionPointsRepositoryProtocol {

}

public class CRLDistributionPointsRepository: CRLDistributionPointsRepositoryProtocol {

    enum Key: DefaultsKey {
        case expirationDate(dp: String)
        case distributionPoints

        var rawValue: String {
            switch self {
            case .expirationDate(let distributionPoint):
                "CRL_expirationDate_\(distributionPoint)"
            case .distributionPoints:
                "CRL_distributionPoints"
            }
        }
    }

    init(storage: PrivateUserDefaults<Key>) {

    }
}
