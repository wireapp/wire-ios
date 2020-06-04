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
    
    func genericMessageDataFromDataSet(for format: ZMImageFormat) -> ZMGenericMessageData? {
        return self.dataSet.lazy
            .compactMap { $0 as? ZMGenericMessageData }
            .first(where: {$0.underlyingMessage?.imageAssetData?.imageFormat() == format} )
    }
    
    public var mediumGenericMessage: GenericMessage? {
        return self.genericMessageDataFromDataSet(for: .medium)?.underlyingMessage
    }
    
    static func keyPathsForValuesAffectingMediumGenericMessage() -> Set<String> {
        return Set([#keyPath(ZMOTRMessage.dataSet), #keyPath(ZMOTRMessage.dataSet)+".data"])
    }
    
    public var previewGenericMessage: GenericMessage? {
        return self.genericMessageDataFromDataSet(for: .preview)?.underlyingMessage
    }
    
    static func keyPathsForValuesAffectingPreviewGenericMessage() -> Set<String> {
        return Set([#keyPath(ZMOTRMessage.dataSet), #keyPath(ZMOTRMessage.dataSet)+".data"])
    }
    
    public var underlyingMessage: GenericMessage? {
        guard !isZombieObject else { return nil }
        
        if cachedUnderlyingAssetMessage == nil {
            cachedUnderlyingAssetMessage = underlyingMessageMergedFromDataSet(filter: {
                $0.assetData != nil
            })
        }
        return cachedUnderlyingAssetMessage
    }
    
    public func add(_ genericMessage: GenericMessage) {
        do {
        _ = self.mergeWithExistingData(data: try genericMessage.serializedData())
        } catch {
            return
        }
    }
    
    func mergeWithExistingData(data: Data) -> ZMGenericMessageData? {
        cachedUnderlyingAssetMessage = nil
      
        guard let genericMessage = try? GenericMessage(serializedData: data) else {
            return nil
        }

        if let imageFormat = genericMessage.imageAssetData?.imageFormat(),
            let existingMessageData = genericMessageDataFromDataSet(for: imageFormat)
        {
            existingMessageData.data = data
            return existingMessageData
        } else {
            return createNewGenericMessage(with: data)
        }
    }
    
    /// Creates a new generic message from the given data
    func createNewGenericMessage(with data: Data) -> ZMGenericMessageData {
        guard let moc = self.managedObjectContext else { fatalError() }
        let messageData = ZMGenericMessageData.insertNewObject(in: moc)
        messageData.data = data
        messageData.asset = self
        moc.processPendingChanges()
        return messageData
    }
    
    func underlyingMessageMergedFromDataSet(filter: (GenericMessage)->Bool) -> GenericMessage? {
        let filteredData = self.dataSet
            .compactMap { ($0 as? ZMGenericMessageData)?.underlyingMessage }
            .filter(filter)
            .compactMap { try? $0.serializedData() }
        
        guard !filteredData.isEmpty else {
            return nil
        }
        
        var message = GenericMessage()
        filteredData.forEach {
            try? message.merge(serializedData: $0)
        }
        return message
    }
    
    /// Returns the generic message for the given representation
    func genericMessage(dataType: AssetClientMessageDataType) -> GenericMessage? {
        
        if self.fileMessageData != nil {
            switch dataType {
            case .fullAsset:
                guard let genericMessage = self.underlyingMessage,
                    let assetData = genericMessage.assetData,
                    case .uploaded? = assetData.status
                    else { return nil }
                return genericMessage
            case .placeholder:
                return self.underlyingMessageMergedFromDataSet(filter: { (message) -> Bool in
                    guard let assetData = message.assetData else { return false }
                    guard case .notUploaded? = assetData.status else {
                        return assetData.hasOriginal
                    }
                    return true
                })
            case .thumbnail:
                return self.underlyingMessageMergedFromDataSet(filter: { (message) -> Bool in
                    guard let assetData = message.assetData else { return false }
                    if let status = assetData.status {
                        guard case .notUploaded = status else { return false }
                        return assetData.hasPreview
                    }
                    return assetData.hasPreview
                })
            }
        }
        
        if self.imageMessageData != nil {
            switch dataType {
            case .fullAsset:
                return self.mediumGenericMessage
            case .placeholder:
                return self.previewGenericMessage
            default:
                return nil
            }
        }
        
        return nil
    }
    
    
    override public var imageMessageData: ZMImageMessageData? {
        return self.asset?.imageMessageData
    }
    
    override public var fileMessageData: ZMFileMessageData? {
        let isFileMessage = underlyingMessage?.assetData != nil
        return isFileMessage ? self : nil
    }
}
