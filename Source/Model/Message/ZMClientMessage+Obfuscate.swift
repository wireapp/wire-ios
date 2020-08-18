//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension ZMClientMessage {
    override open func obfuscate() {
        super.obfuscate()
        if underlyingMessage?.knockData == nil {
            guard let obfuscatedMessage = underlyingMessage?.obfuscatedMessage() else {
                return
            }
            deleteContent()
            do {
                let data = try obfuscatedMessage.serializedData()
                mergeWithExistingData(data)
            }  catch {}
        }
    }
    
    @objc(mergeWithExistingData:)
    func mergeWithExistingData(_ data: Data) -> ZMGenericMessageData? {
        cachedUnderlyingMessage = nil
        
        let existingMessageData = dataSet
            .compactMap { $0 as? ZMGenericMessageData }
            .first
        
        guard existingMessageData != nil else {
            return createNewGenericMessage(with: data)
            
        }
        existingMessageData?.setProtobuf(data)
        return existingMessageData
    }
    
    private func createNewGenericMessage(with data: Data) -> ZMGenericMessageData? {
        guard let moc = self.managedObjectContext else {
            fatalError()
        }
        let messageData = ZMGenericMessageData.insertNewObject(in: moc)
        messageData.setProtobuf(data)
        messageData.message = self
        return messageData
    }
}
