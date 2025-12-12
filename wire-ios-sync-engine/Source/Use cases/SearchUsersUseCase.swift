//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import CoreData
import WireUtilities

public final class SearchUsersUseCase: SearchUsersUseCaseProtocol {

    // MARK: - Properties

    public let context: NSManagedObjectContext

    private let searchDirectory: SearchDirectory
    private let isFederationUsageAllowed: Bool
    private var activeSearchTask: SearchTask?
    private let isMLSEnabled: Bool

    deinit {
        DispatchQueue.main.async { [searchDirectory] in
            searchDirectory.tearDown()
        }
    }

    // MARK: - Initialization

    init(
        context: NSManagedObjectContext,
        searchDirectory: SearchDirectory,
        isFederationUsageAllowed: Bool,
        isMLSEnabled: Bool
    ) {
        self.context = context
        self.searchDirectory = searchDirectory
        self.isFederationUsageAllowed = isFederationUsageAllowed
        self.isMLSEnabled = isMLSEnabled
    }

    // MARK: - Public Interface

    public func invoke(
        query: String,
        options: SearchOptions,
        messageProtocol: MessageProtocol?
    ) async throws -> SearchResult {
        activeSearchTask?.cancel()
        activeSearchTask = nil

        await searchDirectory.updateIncompleteMetadataIfNeeded()

        let (selfDomain, team) = await context.perform { [context] in
            let selfUser = ZMUser.selfUser(in: context)
            return (selfUser.domain, selfUser.membership?.team)
        }

        let searchDomain = isOtherDomainSearchAllowed(messageProtocol) ? nil : selfDomain
        let request = SearchRequest(
            query: query.trim(),
            searchDomain: searchDomain,
            searchOptions: options,
            team: team
        )

        return try await withCheckedThrowingContinuation { continuation in
            guard !Task.isCancelled else {
                continuation.resume(throwing: CancellationError())
                self.activeSearchTask = nil
                return
            }

            let task = searchDirectory.perform(request)
            task.addResultHandler { result, isCompleted in
                if isCompleted {
                    continuation.resume(returning: result)
                    self.activeSearchTask = nil
                }
            }
            task.start()
            activeSearchTask = task
        }
    }

    // MARK: - Private methods

    private func isOtherDomainSearchAllowed(_ messageProtocol: MessageProtocol?) -> Bool {
        guard let messageProtocol else {
            return isFederationUsageAllowed
        }
        return isMLSEnabled ? messageProtocol != .proteus : true
    }

}
