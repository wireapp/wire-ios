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
import ZMCDataModel


public class FileMetaData : ZMFileMetadata {
    
}


private extension ZMMessage {

    var reportsProgress: Bool {
        return fileMessageData != nil || imageMessageData != nil
    }

}

extension ZMMessage: Sendable {

    public var deliveryProgress: Float? {
        if let asset = self as? ZMAssetClientMessage, reportsProgress {
            return asset.progress
        }
        
        return nil
    }
    
    public func registerObserverToken(_ observer: SendableObserver) -> SendableObserverToken {
//        let token =  NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: managedObjectContext, queue: .main) { (notification) in
//            print("context did change")
//            
//            if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
//                print("updatedObjects: ", updatedObjects)
//                
//                if updatedObjects.contains(self) {
//                    observer.onDeliveryChanged()
//                }
//            }
//        }
        
        let token = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: managedObjectContext?.zm_sync, queue: .main) { (notification) in
            print("context did save")
            
            if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                print("updatedObjects: ", updatedObjects)
                
                if updatedObjects.flatMap({ $0.objectID }).contains(self.objectID) {
                    observer.onDeliveryChanged()
                }
            }
        }
        
        return SendableObserverToken(token: token)
    }
    
    
    public func remove(_ observerToken: SendableObserverToken) {
        NotificationCenter.default.removeObserver(observerToken.token)
    }
    
}
