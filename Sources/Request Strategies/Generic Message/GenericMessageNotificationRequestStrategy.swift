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

import WireDataModel

@objc
public final class GenericMessageNotificationRequestStrategy: NSObject, RequestStrategy {

    private var token: Any?
    private let managedObjectContext: NSManagedObjectContext
    fileprivate let genericMessageStrategy: GenericMessageRequestStrategy

    public init(managedObjectContext: NSManagedObjectContext, clientRegistrationDelegate: ClientRegistrationDelegate) {
        self.managedObjectContext = managedObjectContext
        self.genericMessageStrategy = GenericMessageRequestStrategy(
            context: managedObjectContext,
            clientRegistrationDelegate: clientRegistrationDelegate
        )
        super.init()
        setupObserver()
    }

    private func setupObserver() {
        self.token = GenericMessageScheduleNotification.addObserver(managedObjectContext: self.managedObjectContext) { [weak self] (message, conversation) in
            guard let `self` = self  else { return }
            let identifier = conversation.objectID
            self.managedObjectContext.performGroupedBlock {
                guard let syncConversation = (try? self.managedObjectContext.existingObject(with: identifier)) as? ZMConversation else { return }
                self.genericMessageStrategy.schedule(message: message, inConversation: syncConversation, completionHandler: nil)
            }
        }
    }

    public func nextRequest() -> ZMTransportRequest? {
        return genericMessageStrategy.nextRequest()
    }

}


extension GenericMessageNotificationRequestStrategy: ZMContextChangeTracker, ZMContextChangeTrackerSource {

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [genericMessageStrategy]
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        return nil
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        // no-op
    }

    public func objectsDidChange(_ objects: Set<NSManagedObject>) {
        // no-op
    }

}
