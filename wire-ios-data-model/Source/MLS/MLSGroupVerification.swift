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

public struct MLSGroupVerification {

    public let statusUpdater: any MLSConversationVerificationStatusUpdating
    public let updateUseCase: any UpdateMLSGroupVerificationStatusUseCaseProtocol

    let processor: MLSGroupVerificationStatusProcessor

    public init(
        e2eiVerificationStatusService: any E2EIVerificationStatusServiceInterface,
        featureRepository: any FeatureRepositoryInterface,
        mlsService: any MLSServiceInterface,
        syncContext: NSManagedObjectContext
    ) {
        let updateUseCase = UpdateMLSGroupVerificationStatusUseCase(
            e2eIVerificationStatusService: e2eiVerificationStatusService,
            syncContext: syncContext,
            featureRepository: featureRepository
        )

        self.updateUseCase = updateUseCase
        self.statusUpdater = MLSConversationVerificationStatusUpdater(
            updateMLSGroupVerificationStatus: updateUseCase,
            syncContext: syncContext
        )
        self.processor = MLSGroupVerificationStatusProcessor(
            updateMLSGroupVerificationStatusUseCase: updateUseCase,
            mlsService: mlsService,
            syncContext: syncContext
        )
    }

    public func startObserving() {
        processor.startObserving()
    }
}
