//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

public class LinkPreviewUpdateRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource, FederationAware {

    let modifiedKeysSync: ModifiedKeyObjectSync<LinkPreviewUpdateRequestStrategy>
    let messageSync: ProteusMessageSync<ZMClientMessage>

    public var useFederationEndpoint: Bool {
        set {
            messageSync.isFederationEndpointAvailable = newValue
        }
        get {
            messageSync.isFederationEndpointAvailable
        }
    }

    static func linkPreviewIsUploadedPredicate(context: NSManagedObjectContext) -> NSPredicate {
        return NSPredicate(format: "%K == %@ AND %K == %d",
                           #keyPath(ZMClientMessage.sender), ZMUser.selfUser(in: context),
                           #keyPath(ZMClientMessage.linkPreviewState), ZMLinkPreviewState.uploaded.rawValue)
    }

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext,
                  applicationStatus: ApplicationStatus) {

        let modifiedPredicate = Self.linkPreviewIsUploadedPredicate(context: managedObjectContext)
        self.modifiedKeysSync = ModifiedKeyObjectSync(trackedKey: ZMClientMessage.linkPreviewStateKey,
                                                      modifiedPredicate: modifiedPredicate)
        self.messageSync = ProteusMessageSync<ZMClientMessage>(context: managedObjectContext,
                                                               applicationStatus: applicationStatus)

        super.init(withManagedObjectContext: managedObjectContext,
                   applicationStatus: applicationStatus)

        self.configuration = .allowsRequestsWhileOnline
        self.modifiedKeysSync.transcoder = self
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [modifiedKeysSync] + messageSync.contextChangeTrackers
    }

    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return messageSync.nextRequest()
    }

}

extension LinkPreviewUpdateRequestStrategy: ModifiedKeyObjectSyncTranscoder {

    typealias Object = ZMClientMessage

    func synchronize(key: String, for object: ZMClientMessage, completion: @escaping () -> Void) {
        messageSync.sync(object) { (result, _) in
            object.linkPreviewState = .done
            completion()
        }
    }

}
