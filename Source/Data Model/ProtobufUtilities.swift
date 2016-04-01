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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


/// Convenience functions to simplify the creation of
/// the protobuf objects without using the provided builder

public extension ZMGenericMessage {
    
    public static func genericMessage(withExternal external: ZMExternal, messageID: String) -> ZMGenericMessage {
        let builder = ZMGenericMessage.builder()
        builder.setExternal(external)
        builder.setMessageId(messageID)
        return builder.build()
    }
    
    
    public static func genericMessage(withKeyWithChecksum keys: ZMEncryptionKeyWithChecksum, messageID: String) -> ZMGenericMessage {
        let external = ZMExternal.external(withKeyWithChecksum: keys)
        return ZMGenericMessage.genericMessage(withExternal: external, messageID: messageID)
    }
    
}

public extension ZMExternal {
    
    public static func external(withOTRKey otrKey: NSData, sha256: NSData) -> ZMExternal {
        let builder = ZMExternal.builder()
        builder.setOtrKey(otrKey)
        builder.setSha256(sha256)
        return builder.build()
    }
    
    public static func external(withKeyWithChecksum keys: ZMEncryptionKeyWithChecksum) -> ZMExternal {
        return ZMExternal.external(withOTRKey: keys.aesKey, sha256: keys.sha256)
    }
    
}

public extension ZMClientEntry {
    
    public static func entry(withClient client: UserClient, data: NSData) -> ZMClientEntry {
        let builder = ZMClientEntry.builder()
        builder.setClient(client.clientId)
        builder.setText(data)
        return builder.build()
    }
    
}

public extension ZMUserEntry {
    
    public static func entry(withUser user: ZMUser, clientEntries: [ZMClientEntry]) -> ZMUserEntry {
        let builder = ZMUserEntry.builder()
        builder.setUser(user.userId())
        builder.setClientsArray(clientEntries)
        return builder.build()
    }
    
}

public extension ZMNewOtrMessage {
    
    public static func message(withSender sender: UserClient, nativePush: Bool, recipients: [ZMUserEntry], blob: NSData? = nil) -> ZMNewOtrMessage {
        let builder = ZMNewOtrMessage.builder()
        builder.setNativePush(nativePush)
        builder.setSender(sender.clientId)
        builder.setRecipientsArray(recipients)
        if nil != blob {
            builder.setBlob(blob)
        }
        return builder.build()
    }
    
}
