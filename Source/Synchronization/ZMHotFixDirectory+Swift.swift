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
            selfClient.needsToUploadSignalingKeys = true
            selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientNeedsToUpdateSignalingKeysKey))
        }
        
        context.enqueueDelayedSave()
    }
}
