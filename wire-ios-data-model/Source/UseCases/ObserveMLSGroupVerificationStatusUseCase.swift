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

// sourcery: AutoMockable
public protocol ObserveMLSGroupVerificationStatusUseCaseProtocol {

    func invoke()

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

    public func invoke() {
        epochChangesListenerTask = listenForEpochChanges()
    }

    private func listenForEpochChanges() -> Task<Void, Error> {
        return .detached { [mlsService, syncContext, updateMLSGroupVerificationStatusUseCase] in
            for try await groupID in mlsService.epochChanges() {
                do {
                    guard let conversation = await syncContext.perform({
                        ZMConversation.fetch(with: groupID, in: syncContext)
                    }) else {
                        return
                    }

                    try await updateMLSGroupVerificationStatusUseCase.invoke(for: conversation, groupID: groupID)
                } catch {
                    WireLogger.e2ei.warn("failed to update MLS group: \(groupID) verification status: \(error)")
                }
            }
        }
    }
}
