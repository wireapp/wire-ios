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

// MARK: - SelfClientCertificateProviderProtocol

// sourcery: AutoMockable
public protocol SelfClientCertificateProviderProtocol {
    var hasCertificate: Bool { get async }
    func getCertificate() async throws -> E2eIdentityCertificate?
}

// MARK: - SelfClientCertificateProvider

public final class SelfClientCertificateProvider: SelfClientCertificateProviderProtocol {
    // MARK: Lifecycle

    init(
        getE2eIdentityCertificatesUseCase: GetE2eIdentityCertificatesUseCaseProtocol,
        context: NSManagedObjectContext
    ) {
        self.getE2eIdentityCertificatesUseCase = getE2eIdentityCertificatesUseCase
        self.context = context
    }

    // MARK: Public

    public var hasCertificate: Bool {
        get async {
            let certificate = try? await getCertificate()
            return certificate != nil
        }
    }

    public func getCertificate() async throws -> E2eIdentityCertificate? {
        let (conversationID, clientID) = try await context.perform {
            guard let selfConversation = ZMConversation.fetchSelfMLSConversation(in: self.context) else {
                throw Error.couldNotFetchMLSSelfConversation
            }
            guard let mlsGroupID = selfConversation.mlsGroupID else {
                throw Error.failedToGetMLSGroupID(selfConversation)
            }

            guard let selfClient = ZMUser.selfUser(in: self.context).selfClient(),
                  let mlsSelfClient = MLSClientID(userClient: selfClient)
            else {
                throw Error.failedToGetSelfClientID
            }

            return (mlsGroupID, mlsSelfClient)
        }

        return try await getE2eIdentityCertificatesUseCase.invoke(
            mlsGroupId: conversationID,
            clientIds: [clientID]
        ).first
    }

    // MARK: Internal

    enum Error: Swift.Error {
        case couldNotFetchMLSSelfConversation
        case failedToGetMLSGroupID(_ conversation: Conversation)
        case failedToGetSelfClientID
    }

    // MARK: Private

    // MARK: - Properties

    private let getE2eIdentityCertificatesUseCase: GetE2eIdentityCertificatesUseCaseProtocol
    private let context: NSManagedObjectContext
}
