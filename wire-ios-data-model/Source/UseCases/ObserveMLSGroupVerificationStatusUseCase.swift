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

public protocol ObserveMLSGroupVerificationStatusUseCaseProtocol {

    func invoke() async

}

public final class ObserveMLSGroupVerificationStatusUseCase: ObserveMLSGroupVerificationStatusUseCaseProtocol {

    // MARK: - Properties

    private let mlsService: MLSServiceInterface
    private let updateMLSGroupVerificationStatusUseCase: UpdateMLSGroupVerificationStatusUseCaseProtocol
    private let syncContext: NSManagedObjectContext

    private var epochChangesListenerTask: Task<Void, Error>?

    // MARK: - Life cycle

    public init(
        mlsService: MLSServiceInterface,
        updateMLSGroupVerificationStatusUseCase: UpdateMLSGroupVerificationStatusUseCaseProtocol,
        syncContext: NSManagedObjectContext
    ) {
        self.mlsService = mlsService
        self.updateMLSGroupVerificationStatusUseCase = updateMLSGroupVerificationStatusUseCase
        self.syncContext = syncContext
    }

    deinit {
        epochChangesListenerTask?.cancel()
    }

    // MARK: - Methods

    public func invoke() async {
        epochChangesListenerTask = listenForEpochChanges()
        try? await epochChangesListenerTask?.value
    }

    private func listenForEpochChanges() -> Task<Void, Error> {
        return Task.detached {
            for try await groupID in self.mlsService.epochChanges() {
                do {
                    guard let conversation = await self.syncContext.perform({
                        ZMConversation.fetch(with: groupID, in: self.syncContext)
                    }) else {
                        WireLogger.e2ei.warn("failed to fetch the conversation by mlsGroupID \(groupID)")
                        return
                    }

                    try await self.updateMLSGroupVerificationStatusUseCase.invoke(for: conversation, groupID: groupID)
                } catch {
                    WireLogger.e2ei.warn("failed to update MLS group: \(groupID) verification status: \(error)")
                }
            }
        }
    }

}
