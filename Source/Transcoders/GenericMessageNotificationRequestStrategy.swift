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


public final class GenericMessageNotificationRequestStrategy: GenericMessageRequestStrategy {

    private var token: NotificationCenterObserverToken?

    public init(managedObjectContext: NSManagedObjectContext, clientRegistrationDelegate: ClientRegistrationDelegate) {
        super.init(context: managedObjectContext, clientRegistrationDelegate: clientRegistrationDelegate)
        setupObserver()
    }

    private func setupObserver() {
        token = NotificationCenterObserverToken(name: GenericMessageScheduleNotification.name) { [weak self] note in
            guard let `self` = self, let (message, conversation) = note.object as? (ZMGenericMessage, ZMConversation) else { return }
            let identifier = conversation.objectID
            self.context.performGroupedBlock {
                guard let syncConversation = (try? self.context.existingObject(with: identifier)) as? ZMConversation else { return }
                self.schedule(message: message, inConversation: syncConversation, completionHandler: nil)
            }
        }
    }

}
