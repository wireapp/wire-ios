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

public protocol CRLExpirationDatesRepositoryProtocol {
    func crlExpirationDateExists(for distributionPoint: URL) -> Bool
    func storeCRLExpirationDate(_ expirationDate: Date, for distributionPoint: URL)
    func fetchAllCRLExpirationDates() -> [URL: Date]
}

// TODO: Use userDefaults for storage
public class CRLExpirationDatesRepository: CRLExpirationDatesRepositoryProtocol {

    var crlExpirationDateByDistributionPoint: [URL: Date] = [:]

    public func crlExpirationDateExists(for distributionPoint: URL) -> Bool {
        return fetchCRLExpirationDate(for: distributionPoint) != nil
    }

    public func storeCRLExpirationDate(_ expirationDate: Date, for distributionPoint: URL) {
        crlExpirationDateByDistributionPoint[distributionPoint] = expirationDate
    }

    public func fetchAllCRLExpirationDates() -> [URL: Date] {
        return crlExpirationDateByDistributionPoint
    }

    private func fetchCRLExpirationDate(for distributionPoint: URL) -> Date? {
        return crlExpirationDateByDistributionPoint[distributionPoint]
    }

}
