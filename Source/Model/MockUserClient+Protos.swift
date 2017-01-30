//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import ZMProtos

extension MockUserClient {
    
    /// Returns an OTR message builder with the recipients correctly set
    @objc(OTRMessageBuilderWithRecipientsForClients:plainText:)
    public func otrMessageBuilderWithRecipients(for clients: [MockUserClient], plainText: Data) -> ZMNewOtrMessageBuilder {
        
        let messageBuilder = ZMNewOtrMessage.builder()!
        let senderBuilder = ZMClientId.builder()!
        
        senderBuilder.setClient(self.identifier!.asHexEncodedUInt)
        messageBuilder.setSender(senderBuilder)
        messageBuilder.setRecipientsArray(self.userEntries(for: clients, plainText: plainText))
        return messageBuilder
    }
    
    /// Returns an OTR asset message builder with the recipients correctly set
    @objc(OTRAssetMessageBuilderWithRecipientsForClients:plainText:)
    public func otrAssetMessageBuilderWithRecipients(for clients: [MockUserClient], plainText: Data) -> ZMOtrAssetMetaBuilder {
        
        let messageBuilder = ZMOtrAssetMeta.builder()!
        let senderBuilder = ZMClientId.builder()!
        
        senderBuilder.setClient(self.identifier!.asHexEncodedUInt)
        messageBuilder.setSender(senderBuilder)
        messageBuilder.setRecipientsArray(self.userEntries(for: clients, plainText: plainText))
        return messageBuilder
    }
    
    /// Create user entries for all received of a message
    private func userEntries(for clients: [MockUserClient], plainText: Data) -> [ZMUserEntry] {
        return MockUserClient.createUserToClientMapping(for: clients).map { (user: MockUser, clients: [MockUserClient]) -> ZMUserEntry in
            let userEntryBuilder = ZMUserEntry.builder()!
            let userIdBuilder = ZMUserId.builder()!
            userIdBuilder.setUuid((UUID(uuidString: user.identifier)! as NSUUID).data())
            userEntryBuilder.setUser(userIdBuilder.build())
            
            let clientEntries = clients.map { client -> ZMClientEntry in
                let clientIdBuilder = ZMClientId.builder()!
                clientIdBuilder.setClient(client.identifier!.asHexEncodedUInt)
                let clientEntryBuilder = ZMClientEntry.builder()!
                clientEntryBuilder.setClient(clientIdBuilder.build())
                let encrypted = MockUserClient.encrypted(data: plainText, from: self, to: client)
                clientEntryBuilder.setText(encrypted)
                
                return clientEntryBuilder.build()
            }
            
            userEntryBuilder.setClientsArray(clientEntries)
            return userEntryBuilder.build()
        }
    }
    
    /// Map a list of clients to a lookup by user
    static private func createUserToClientMapping(for clients: [MockUserClient]) -> [MockUser: [MockUserClient]]{
        var mapped = [MockUser: [MockUserClient]]()
        clients.forEach { client in
            var previous = mapped[client.user!] ?? [MockUserClient]()
            previous.append(client)
            mapped[client.user!] = previous
        }
        return mapped
    }
    
}

extension String {
    
    /// Parses the string as if it was a hex representation of a number
    fileprivate var asHexEncodedUInt: UInt64 {
        var scannedIdentifier: UInt64 = 0
        Scanner(string: self).scanHexInt64(&scannedIdentifier)
        return scannedIdentifier
    }
}
