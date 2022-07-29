//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireDataModel

class MockMLSController: MLSControllerProtocol {
    var mockDecryptedData: Data?
    var mockDecryptionError: MLSController.MLSMessageDecryptionError?
    var decryptCalls = [(String, MLSGroupID)]()

    func decrypt(message: String, for groupID: MLSGroupID) throws -> Data? {
        decryptCalls.append((message, groupID))

        if let error = mockDecryptionError {
            throw error
        }

        return mockDecryptedData
    }

    var hasWelcomeMessageBeenProcessed = false

    func conversationExists(groupID: MLSGroupID) -> Bool {
        return hasWelcomeMessageBeenProcessed
    }

    var processedWelcomeMessage: String?
    var groupID: MLSGroupID?

    @discardableResult
    func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID {
        processedWelcomeMessage = welcomeMessage
        return groupID ?? MLSGroupID(Data())
    }

    func uploadKeyPackagesIfNeeded() {

    }

    var createGroupCalls = [MLSGroupID]()

    func createGroup(for groupID: MLSGroupID) throws {
        createGroupCalls.append(groupID)
    }

    func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) async throws {

    }
}
