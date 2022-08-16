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

    // MARK: - Types

    enum MockError: Error {

        case unmockedMethodCalled

    }

    struct Calls {

        var uploadKeyPackagesIfNeeded: [Void] = []
        var createGroup = [MLSGroupID]()
        var conversationExists = [MLSGroupID]()
        var processWelcomeMessage = [String]()
        var enccrypt = [(Bytes, MLSGroupID)]()
        var decrypt = [(String, MLSGroupID)]()
        var addMembersToConversation = [([MLSUser], MLSGroupID)]()
        var removeMembersFromConversation = [([MLSClientID], MLSGroupID)]()

    }

    // MARK: - Properties

    var calls = Calls()

    // MARK: - Key packages

    func uploadKeyPackagesIfNeeded() {
        calls.uploadKeyPackagesIfNeeded.append(())
    }

    // MARK: - Create group

    func createGroup(for groupID: MLSGroupID) throws {
        calls.createGroup.append(groupID)
    }

    // MARK: - Conversation exists

    typealias ConversationExistsMock = (MLSGroupID) -> Bool

    var conversationExistsMock: ConversationExistsMock?

    func conversationExists(groupID: MLSGroupID) -> Bool {
        calls.conversationExists.append(groupID)
        return conversationExistsMock?(groupID) ?? false
    }

    // MARK: - Process welcome message

    typealias ProcessWelcomeMessageMock = (String) throws -> MLSGroupID

    var processWelcomeMessageMock: ProcessWelcomeMessageMock?

    func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID {
        calls.processWelcomeMessage.append(welcomeMessage)
        guard let mock = processWelcomeMessageMock else { throw MockError.unmockedMethodCalled }
        return try mock(welcomeMessage)
    }

    // MARK: - Encrypt

    typealias EncryptMock = (Bytes, MLSGroupID) throws -> Bytes

    var encryptMock: EncryptMock?

    func encrypt(message: Bytes, for groupID: MLSGroupID) throws -> Bytes {
        calls.enccrypt.append((message, groupID))
        guard let mock = encryptMock else { throw MockError.unmockedMethodCalled }
        return try mock(message, groupID)
    }

    // MARK: - Decrypt

    typealias DecryptMock = (String, MLSGroupID) throws -> Data?

    var decryptMock: DecryptMock?

    func decrypt(message: String, for groupID: MLSGroupID) throws -> Data? {
        calls.decrypt.append((message, groupID))
        guard let mock = decryptMock else { throw MockError.unmockedMethodCalled }
        return try mock(message, groupID)
    }

    // MARK: - Add members

    func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) throws {
        calls.addMembersToConversation.append((users, groupID))
    }

    // MARK: - Remove members

    func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) throws {
        calls.removeMembersFromConversation.append((clientIds, groupID))
    }

}
