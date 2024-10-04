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

import WireFoundation

// sourcery: AutoMockable
public protocol CRLExpirationDatesRepositoryProtocol {
    func crlExpirationDateExists(for distributionPoint: URL) -> Bool
    func storeCRLExpirationDate(_ expirationDate: Date, for distributionPoint: URL)
    func fetchAllCRLExpirationDates() -> [URL: Date]
}

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
        let expirationDateKey = Key.expirationDate(dp: dpString)

        storeDistributionPointIfNeeded(dpString)

        if DeveloperFlag.forceCRLExpiryAfterOneMinute.isOn {
            storage.set(
                Calendar.current.date(byAdding: .minute, value: 1, to: .now)!,
                forKey: expirationDateKey
            )
        } else {
            storage.set(expirationDate, forKey: expirationDateKey)
        }
    }

    public func fetchAllCRLExpirationDates() -> [URL: Date] {
        guard let knownDistributionPoints = storage.object(forKey: Key.distributionPoints) as? [String] else {
            return [:]
        }

        var expirationDatesByDistributionPoint = [URL: Date]()

        for distributionPoint in knownDistributionPoints {
            let expirationDate = storage.date(forKey: .expirationDate(dp: distributionPoint))

            guard
                let expirationDate,
                let url = URL(string: distributionPoint)
            else {
                continue
            }

            expirationDatesByDistributionPoint[url] = expirationDate
        }

        return expirationDatesByDistributionPoint
    }

    public func removeAllExpirationDates() {
        guard let knownDistributionPoints = storage.object(forKey: Key.distributionPoints) as? [String] else {
            return
        }

        knownDistributionPoints.forEach {
            storage.removeObject(forKey: .expirationDate(dp: $0))
        }
    }

    // MARK: - Helpers

    private func storeDistributionPointIfNeeded(_ dpString: String) {
        let knownDistributionPoints = storage.object(forKey: Key.distributionPoints) as? [String]

        if var knownDistributionPoints, !knownDistributionPoints.contains(dpString) {
            knownDistributionPoints.append(dpString)
            storage.set(knownDistributionPoints, forKey: .distributionPoints)
            return
        }

        if knownDistributionPoints == nil {
            storage.set([dpString], forKey: .distributionPoints)
            return
        }
    }

    private func fetchCRLExpirationDate(for distributionPoint: URL) -> Date? {
        storage.date(forKey: .expirationDate(dp: distributionPoint.absoluteString))
    }

}
