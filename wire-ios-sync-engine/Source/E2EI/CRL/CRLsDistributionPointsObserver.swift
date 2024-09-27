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

import Combine
import Foundation
import WireDataModel

// MARK: - CRLsDistributionPointsObserving

public protocol CRLsDistributionPointsObserving {
    func startObservingNewCRLsDistributionPoints(
        from publisher: AnyPublisher<CRLsDistributionPoints, Never>
    )
}

// MARK: - CRLsDistributionPointsObserver

public class CRLsDistributionPointsObserver: CRLsDistributionPointsObserving {
    // MARK: Lifecycle

    public init(cRLsChecker: CertificateRevocationListsChecking) {
        self.cRLsChecker = cRLsChecker
    }

    // MARK: Public

    public func startObservingNewCRLsDistributionPoints(
        from publisher: AnyPublisher<CRLsDistributionPoints, Never>
    ) {
        publisher.sink { [weak self] distributionPoints in
            let cRLsChecker = self?.cRLsChecker
            Task {
                await cRLsChecker?.checkNewCRLs(from: distributionPoints)
            }
        }
        .store(in: &cancellables)
    }

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []
    private let cRLsChecker: CertificateRevocationListsChecking
}
