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

public class ResetSessionRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {
    
    fileprivate let keyPathSync: KeyPathObjectSync<ResetSessionRequestStrategy>
    fileprivate let genericMessageStrategy: GenericMessageRequestStrategy

    public init(managedObjectContext: NSManagedObjectContext,
                applicationStatus: ApplicationStatus,
                clientRegistrationDelegate: ClientRegistrationDelegate) {
        
        self.keyPathSync = KeyPathObjectSync(entityName: UserClient.entityName(), \.needsToNotifyOtherUserAboutSessionReset)
        self.genericMessageStrategy = GenericMessageRequestStrategy(
            context: managedObjectContext,
            clientRegistrationDelegate: clientRegistrationDelegate
        )
        
        super.init(withManagedObjectContext: managedObjectContext,
                   applicationStatus: applicationStatus)
        
        keyPathSync.transcoder = self
    }
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return genericMessageStrategy.nextRequest()
    }
    
    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [genericMessageStrategy, keyPathSync]
    }

}

extension ResetSessionRequestStrategy: KeyPathObjectSyncTranscoder {

    typealias T = UserClient
            
    func synchronize(_ userClient: UserClient, completion: @escaping () -> Void) {
                
        guard let converation = userClient.user?.oneToOneConversation else {
            return
        }
        
        genericMessageStrategy.schedule(message: GenericMessage(clientAction: .resetSession),
                                        inConversation: converation)
        { (response) in
            
            switch response.result {
            case .success, .permanentError:
                userClient.resolveDecryptionFailedSystemMessages()
                completion()
            default:
                break
            }
        }
    }
    
}
