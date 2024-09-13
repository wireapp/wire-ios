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

import WireTransport

@testable import WireSyncEngine

extension MessagingTest {
    @discardableResult
    func createSelfUser() -> ZMUser {
        let selfUser = ZMUser.selfUser(in: syncMOC)
        selfUser.remoteIdentifier = UUID()
        syncMOC.saveOrRollback()
        return selfUser
    }

    func createClient(for user: ZMUser) -> UserClient {
        let client = UserClient.insertNewObject(in: syncMOC)
        client.user = user
        client.remoteIdentifier = UUID().transportString()
        return client
    }

    public func createClientTextMessage() -> ZMClientMessage? {
        createClientTextMessageWith(text: name)
    }

    public func createClientTextMessageWith(text: String) -> ZMClientMessage? {
        let nonce = UUID.create()
        let message = ZMClientMessage(nonce: nonce, managedObjectContext: syncMOC)
        let textMessage = GenericMessage(content: Text(
            content: text,
            mentions: [],
            linkPreviews: [],
            replyingTo: nil
        ), nonce: nonce)
        do {
            try message.setUnderlyingMessage(textMessage)
        } catch {
            return nil
        }
        return message
    }

    @discardableResult
    func createMLSSelfConversation() -> ZMConversation {
        let selfConversation = ZMConversation.insertNewObject(in: syncMOC)
        selfConversation.conversationType = .`self`
        selfConversation.remoteIdentifier = UUID.create()
        selfConversation.mlsGroupID = MLSGroupID(Data.secureRandomData(length: 8))
        selfConversation.messageProtocol = .mls
        selfConversation.mlsStatus = .ready
        return selfConversation
    }

    @objc
    public func createCoreDataStack() -> CoreDataStack {
        let account = Account(userName: "", userIdentifier: userIdentifier)
        let stack = CoreDataStack(
            account: account,
            applicationContainer: sharedContainerURL,
            inMemoryStore: shouldUseInMemoryStore,
            dispatchGroup: dispatchGroup
        )

        stack.loadStores(completionHandler: { error in
            XCTAssertNil(error)
        })

        return stack
    }

    @objc
    public func setBackendInfoDefaults() {
        BackendInfo.apiVersion = .v0
        BackendInfo.domain = "example.com"

        var proteusViaCoreCrypto = DeveloperFlag.proteusViaCoreCrypto
        proteusViaCoreCrypto.isOn = false
    }
}
