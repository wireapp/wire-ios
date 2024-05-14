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

public final class MLSGroupVerificationStatusProcessor {

    // MARK: - Properties

    private let updateMLSGroupVerificationStatusUseCase: any UpdateMLSGroupVerificationStatusUseCaseProtocol
    private let mlsService: MLSServiceInterface
    private let syncContext: NSManagedObjectContext

    private var observingTask: Task<Void, Never>?

    // MARK: - Life cycle

    public init(
        updateMLSGroupVerificationStatusUseCase: any UpdateMLSGroupVerificationStatusUseCaseProtocol,
        mlsService: MLSServiceInterface,
        syncContext: NSManagedObjectContext
    ) {
        self.updateMLSGroupVerificationStatusUseCase = updateMLSGroupVerificationStatusUseCase
        self.mlsService = mlsService
        self.syncContext = syncContext
    }

    deinit {
        observingTask?.cancel()
    }

    public func startObserving() {
        observingTask = .detached { [mlsService, weak self] in
            for await groupID in mlsService.epochChanges() {
                await self?.processConversation(with: groupID)
            }
        }
    }

    private func processConversation(with groupID: MLSGroupID) async {
        guard let conversation = await syncContext.perform({
            ZMConversation.fetch(with: groupID, in: self.syncContext)
        }) else {
            return WireLogger.e2ei.warn("failed to fetch the conversation by mlsGroupID \(groupID)")
        }

        do {
            try await updateMLSGroupVerificationStatusUseCase.invoke(for: conversation, groupID: groupID)
        } catch {
            WireLogger.e2ei.warn("failed to update MLS group: \(groupID) verification status: \(error)")
        }
    }
}
