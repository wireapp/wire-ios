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

extension ZMUserSession {
    func setupCertificateRevocationLists() {
        guard let mlsGroupVerification else {
            WireLogger.e2ei.error("requires 'mlsGroupVerification' to setup 'cRLsChecker'!", attributes: .safePublic)
            assertionFailure("requires 'mlsGroupVerification' to setup 'cRLsChecker'!")
            return
        }

        let cRLsChecker = CertificateRevocationListsChecker(
            userID: userId,
            crlAPI: CertificateRevocationListAPI(),
            mlsGroupVerification: mlsGroupVerification,
            selfClientCertificateProvider: selfClientCertificateProvider,
            fetchE2EIFeatureConfig: { [weak self] in
                guard let self else { return nil }

                let featureRepository = FeatureRepository(context: coreDataStack.syncContext)
                return featureRepository.fetchE2EI().config
            },
            coreCryptoProvider: coreCryptoProvider,
            context: coreDataStack.syncContext
        )
        self.cRLsChecker = cRLsChecker

        let cRLsDistributionPointsObserver = CRLsDistributionPointsObserver(cRLsChecker: cRLsChecker)
        cRLsDistributionPointsObserver.startObservingNewCRLsDistributionPoints(
            from: mlsService.onNewCRLsDistributionPoints()
        )
        self.cRLsDistributionPointsObserver = cRLsDistributionPointsObserver
    }

    func checkExpiredCertificateRevocationLists() {
        guard let cRLsChecker else {
            WireLogger.e2ei.error("requires 'cRLsChecker' to check expired CRLs!", attributes: .safePublic)
            return
        }

        Task {
            let isE2EIFeatureEnabled = await managedObjectContext.perform { self.e2eiFeature.isEnabled }
            if isE2EIFeatureEnabled {
                await cRLsChecker.checkExpiredCRLs()
            }
        }
    }
}
