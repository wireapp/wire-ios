//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import GenericMessageProtocol
import XCTest

@testable import WireDataModel
@testable import WireDataModelSupport

extension ZMBaseManagedObjectTest {

    var storageDirectory: URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
    }

    func createClientTextMessage(in context: NSManagedObjectContext? = nil) -> ZMClientMessage? {
        createClientTextMessage(withText: name, in: context)
    }

    func createClientTextMessage(withText text: String, in context: NSManagedObjectContext? = nil) -> ZMClientMessage? {
        let nonce = UUID.create()
        let message = ZMClientMessage(nonce: nonce, managedObjectContext: context ?? uiMOC)
        let textMessage = GenericMessage(
            content: Text(content: text, mentions: [], linkPreviews: [], replyingTo: nil),
            nonce: nonce
        )
        do {
            try message.setUnderlyingMessage(textMessage)
        } catch {
            XCTFail()
        }
        return message
    }

    @objc(createClientForUser:onMOC:)
    func createClient(
        for user: ZMUser,
        onMOC moc: NSManagedObjectContext
    ) -> UserClient {
        if user.remoteIdentifier == nil {
            user.remoteIdentifier = UUID.create()
        }

        let userClient = UserClient.insertNewObject(in: moc)
        userClient.remoteIdentifier = String.randomClientIdentifier()
        userClient.user = user

        return userClient
    }

    @objc
    func createCoreDataStack() async throws -> CoreDataStack {
        let account = Account(userName: "", userIdentifier: userIdentifier)
        let stack = CoreDataStack(
            account: account,
            applicationContainer: storageDirectory,
            inMemoryStore: shouldUseInMemoryStore,
            dispatchGroup: dispatchGroup,
            localDomain: "wire.com",
            isFederationEnabled: false
        )

        try await stack.load()

        return stack
    }

    @objc
    func deleteStorageDirectory() throws {
        let files = try FileManager.default
            .contentsOfDirectory(
                at: storageDirectory,
                includingPropertiesForKeys: nil,
                options: []
            )

        try files.forEach { try FileManager.default.removeItem(at: $0) }
    }
}
