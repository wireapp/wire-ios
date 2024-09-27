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
import WireCoreCrypto

// MARK: - IsSelfUserE2EICertifiedUseCase

/// A wrapper use case around `IsUserE2EICertifiedUseCaseProtocol` which gets the
/// self-user and the self-mls-conversation from a managed object context in order to pass it to
/// the wrapped use case and provide an argument-less `invoke` method.
public struct IsSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol {
    // MARK: Lifecycle

    /// - Parameters:
    ///   - context: A managed object context to retrieve the self-user and the self-mls-conversation from.
    ///   - isUserE2EICertifiedUseCase: The use case which contains the actual business logic.
    public init(
        context: NSManagedObjectContext,
        featureRepository: FeatureRepositoryInterface,
        featureRepositoryContext: NSManagedObjectContext,
        isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol
    ) {
        self.context = context
        self.featureRepository = featureRepository
        self.featureRepositoryContext = featureRepositoryContext
        self.isUserE2EICertifiedUseCase = isUserE2EICertifiedUseCase
    }

    // MARK: Public

    public func invoke() async throws -> Bool {
        let isE2EIEnabled = await featureRepositoryContext.perform {
            featureRepository.fetchE2EI().isEnabled
        }
        guard isE2EIEnabled else {
            return false
        }

        let (selfUser, selfMLSConversation) = await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
            let selfMLSConversation = ZMConversation.fetchSelfMLSConversation(in: context)
            return (selfUser, selfMLSConversation)
        }
        guard let selfMLSConversation else {
            throw Error.failedToGetTheSelfMLSConversation
        }

        return try await isUserE2EICertifiedUseCase.invoke(
            conversation: selfMLSConversation,
            user: selfUser
        )
    }

    // MARK: Private

    private let context: NSManagedObjectContext
    private let featureRepository: FeatureRepositoryInterface
    /// The `featureRepository` operates on a context, so every operation must be dispatched
    /// on that context's queue. Since `FeatureRepositoryInterface` doesn't contain any
    /// `context` property, we inject the context here.
    private let featureRepositoryContext: NSManagedObjectContext
    private let isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol
}

// MARK: IsSelfUserE2EICertifiedUseCase.Error

extension IsSelfUserE2EICertifiedUseCase {
    enum Error: Swift.Error {
        case failedToGetTheSelfMLSConversation
    }
}
