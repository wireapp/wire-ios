//
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

public protocol MLSConversationVerificationManagerInterface {

    func startObservingMLSConversationVerificationStatus()

}

public final class MLSConversationVerificationManager: MLSConversationVerificationManagerInterface {

    // MARK: - Properties

    var mlsService: MLSServiceInterface
    var mlsConversationVerificationStatusUpdater: MLSConversationVerificationStatusUpdating?

    // MARK: - Life cycle

    public init(mlsService: MLSServiceInterface,
                mlsConversationVerificationStatusUpdater: MLSConversationVerificationStatusUpdating?) {
        self.mlsService = mlsService
        self.mlsConversationVerificationStatusUpdater = mlsConversationVerificationStatusUpdater
    }

    // MARK: - Methods

    public func startObservingMLSConversationVerificationStatus() {
        Task {
            for try await groupID in mlsService.epochChanges() {
                try await mlsConversationVerificationStatusUpdater?.updateStatus(groupID)
            }
        }
    }

}
