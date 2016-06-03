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


import Foundation


extension ZMHotFixDirectory {

    public static func moveOrUpdateSignalingKeysInContext(context: NSManagedObjectContext) {
        guard let selfClient = ZMUser.selfUserInContext(context).selfClient()
              where selfClient.apsVerificationKey == nil && selfClient.apsDecryptionKey == nil
        else { return }
        
        if let keys = APSSignalingKeysStore.keysStoredInKeyChain() {
            selfClient.apsVerificationKey = keys.verificationKey
            selfClient.apsDecryptionKey = keys.decryptionKey
            APSSignalingKeysStore.clearSignalingKeysInKeyChain()
        } else {
            UserClient.resetSignalingKeysInContext(context)
        }
        
        context.enqueueDelayedSave()
    }
    
    /// In the model schema version 2.6 we removed the flags `needsToUploadMedium` and `needsToUploadPreview` on `ZMAssetClientMessage`
    /// and introduced an enum called `ZMAssetUploadedState`. During the migration this value will be set to `.Done` on all `ZMAssetClientMessages`.
    /// There is an edge case in which the user has such a message in his database which is not yet uploaded and we want to upload it again, thus
    /// not set the state to `.Done` in this case. We fetch all asset messages without an assetID and set set their uploaded state 
    /// to `.UploadingFailed`, in case this message represents an image we also expire it.
    public static func updateUploadedStateForNotUploadedFileMessages(context: NSManagedObjectContext) {
        let selfUser = ZMUser.selfUserInContext(context)
        let predicate = NSPredicate(format: "sender == %@ AND assetId_data == NULL", selfUser)
        let fetchRequest = ZMAssetClientMessage.sortedFetchRequestWithPredicate(predicate)
        guard let messages = context.executeFetchRequestOrAssert(fetchRequest) as? [ZMAssetClientMessage] else { return }
        
        messages.forEach { message in
            message.uploadState = .UploadingFailed
            if nil != message.imageMessageData {
                message.expire()
            }
        }
        
        context.enqueueDelayedSave()
    }
}
