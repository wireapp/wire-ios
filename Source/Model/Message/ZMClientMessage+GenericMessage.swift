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
    
    public var underlyingMessage: GenericMessage? {
        guard !isZombieObject else {
            return nil
        }
        
        if cachedUnderlyingMessage == nil {
            cachedUnderlyingMessage = underlyingMessageMergedFromDataSet()
        }
        return cachedUnderlyingMessage
    }
    
    private func underlyingMessageMergedFromDataSet() -> GenericMessage? {
        let filteredData = dataSet.lazy
            .compactMap { ($0 as? ZMGenericMessageData)?.underlyingMessage }
            .filter { $0.knownMessage && $0.imageAssetData == nil }
            .compactMap { try? $0.serializedData() }
        
        guard !Array(filteredData).isEmpty else {
            return nil
        }
        
        var message = GenericMessage()
        filteredData.forEach {
            try? message.merge(serializedData: $0)
        }
        return message
    }
    
    @objc(addData:)
    public func add(_ data: Data?) {
        guard let data = data else {
            return
        }
        let messageData = mergeWithExistingData(data)
        
        if (nonce == nil) {
            nonce = UUID(uuidString: messageData?.underlyingMessage?.messageID ?? "")
        }
        updateCategoryCache()
        setLocallyModifiedKeys([#keyPath(ZMClientMessage.dataSet)])
    }
}
