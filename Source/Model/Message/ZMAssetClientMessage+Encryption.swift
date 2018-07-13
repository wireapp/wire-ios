//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

extension ZMAssetClientMessage {
    
    fileprivate func validSelfClient() -> UserClient? {
        guard let managedObjectContext = self.managedObjectContext,
              let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient(), selfClient.remoteIdentifier != nil
        else { return nil }
        
        return selfClient
    }
    
    /// Returns the binary data of the encrypted `Asset.Uploaded` protobuf message or `nil`
    /// in case the receiver does not contain a `Asset.Uploaded` generic message.
    /// Also returns `nil` for messages representing an image
    public func encryptedMessagePayloadForDataType(_ dataType: AssetClientMessageDataType) -> (data: Data, strategy: MissingClientsStrategy)? {
        
        guard let selfClient = validSelfClient() else {return nil}
        guard let genericMessage = genericMessage(dataType: dataType) else { return nil }
        guard let (recipients, strategy) = userEntriesAndStrategy(for: genericMessage, selfClient: selfClient) else { return nil }
        
        var data : Data?
        if dataType == .fullAsset || dataType == .thumbnail {
            data = ZMOtrAssetMeta.otrAssetMeta(withSender: selfClient, nativePush: true, inline: false, recipients: recipients).data()
        } else if dataType == .placeholder {
            data = ZMNewOtrMessage.message(withSender: selfClient, nativePush: true, recipients: recipients, blob: nil).data()
        }
        
        if let data = data {
            return (data, strategy)
        }
        return nil
    }
    
    /// Returns the OTR asset meta for the image format
    public func encryptedMessagePayloadForImageFormat(_ imageFormat: ZMImageFormat) -> (otrMessageData: ZMOtrAssetMeta, strategy: MissingClientsStrategy)? {
        
        guard let selfClient = validSelfClient() else {return nil}
        guard let genericMessage = imageAssetStorage.genericMessage(for: imageFormat) else { return nil }
        guard let (recipients, strategy) = userEntriesAndStrategy(for: genericMessage, selfClient: selfClient) else { return nil }
        
        let builder = ZMOtrAssetMeta.builder()!
        builder.setIsInline(imageAssetStorage.isInline(for: imageFormat))
        builder.setNativePush(imageAssetStorage.isUsingNativePush(for: imageFormat))
        builder.setSender(selfClient.clientId)
        builder.setRecipientsArray(recipients)
        
        if let otrMessageData = builder.build() {
            return (otrMessageData, strategy)
        }
        return nil
    }
    
    fileprivate func userEntriesAndStrategy(for genericMessage: ZMGenericMessage, selfClient: UserClient) ->
        (userEnries: [ZMUserEntry], strategy: MissingClientsStrategy)? {
        guard let conversation = self.conversation else { return nil }
            
        let (recipientUsers, strategy) = genericMessage.recipientUsersForMessage(in: conversation, selfUser: selfClient.user!)
        var recipients : [ZMUserEntry] = []
        selfClient.keysStore.encryptionContext.perform { (sessionsDirectory) in
            recipients = genericMessage.recipientsWithEncryptedData(selfClient, recipients: recipientUsers, sessionDirectory: sessionsDirectory)
        }
        return (recipients, strategy)
    }
}

