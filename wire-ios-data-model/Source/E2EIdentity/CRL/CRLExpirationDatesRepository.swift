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

// TODO: Perhaps it's better to use core data?
// Seems less error prone to have a well defined entity 
// that stores the distribution point and the expiration date
// in a single place rather than maintaining a list of distribution points
// separately from expiration dates in user defaults
//
// However, I'm not sure the scaffolding around setting up a new core data entity is worth it

public class CRLExpirationDatesRepository: CRLExpirationDatesRepositoryProtocol {

    // MARK: - Types

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

    // MARK: - Properties

    private let storage: PrivateUserDefaults<Key>

    // MARK: - Life cycle

    convenience public init(userID: UUID) {
        self.init(storage: .init(userID: userID))
    }

    init(storage: PrivateUserDefaults<Key>) {
        self.storage = storage
    }

    // MARK: - Interface

    public func crlExpirationDateExists(for distributionPoint: URL) -> Bool {
        return fetchCRLExpirationDate(for: distributionPoint) != nil
    }

    public func storeCRLExpirationDate(_ expirationDate: Date, for distributionPoint: URL) {
        let dpString = distributionPoint.absoluteString
        storeDistributionPointIfNeeded(dpString)
        storage.set(expirationDate, forKey: Key.expirationDate(dp: distributionPoint.absoluteString))
    }

    public func fetchAllCRLExpirationDates() -> [URL: Date] {
        guard let knownDistributionPoints = storage.object(forKey: Key.distributionPoints) as? Set<String> else {
            return [:]
        }

        var expirationDatesByDistributionPoint = [URL: Date]()

        for distributionPoint in knownDistributionPoints {
            let expirationDate = storage.date(forKey: .expirationDate(dp: distributionPoint))

            guard
                let expirationDate = expirationDate,
                let url = URL(string: distributionPoint)
            else {
                continue
            }

            expirationDatesByDistributionPoint[url] = expirationDate
        }

        return expirationDatesByDistributionPoint
    }

    // MARK: - Helpers

    private func storeDistributionPointIfNeeded(_ dpString: String) {
        if var knownDistributionPoints = storage.object(forKey: Key.distributionPoints) as? Set<String> {
            knownDistributionPoints.insert(dpString)
            storage.set(knownDistributionPoints, forKey: .distributionPoints)
        } else {
            storage.set(Set([dpString]) as Any, forKey: .distributionPoints)
        }
    }

    private func fetchCRLExpirationDate(for distributionPoint: URL) -> Date? {
        storage.date(forKey: .expirationDate(dp: distributionPoint.absoluteString))
    }

}
