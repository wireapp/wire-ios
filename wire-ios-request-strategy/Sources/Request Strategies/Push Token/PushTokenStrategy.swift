//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireDataModel

public class PushTokenStrategy: AbstractRequestStrategy, ZMEventConsumer {
    // MARK: Lifecycle

    @objc
    override public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        self.registerPushTokenActionHandler = RegisterPushTokenActionHandler(context: managedObjectContext)
        self.removePushTokenActionHandler = RemovePushTokenActionHandler(context: managedObjectContext)
        self.getPushTokensActionHandler = GetPushTokensActionHandler(context: managedObjectContext)

        self.actionSync = EntityActionSync(actionHandlers: [
            registerPushTokenActionHandler,
            removePushTokenActionHandler,
            getPushTokensActionHandler,
        ])

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
    }

    // MARK: Public

    // MARK: - Requests

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        actionSync.nextRequest(for: apiVersion)
    }

    // MARK: - ZMEventConsumer

    public func processEvents(
        _ events: [ZMUpdateEvent],
        liveEvents: Bool,
        prefetchResult: ZMFetchRequestBatchResult?
    ) {
        guard liveEvents else {
            return
        }
        events.forEach(process(updateEvent:))
    }

    // MARK: Internal

    func process(updateEvent event: ZMUpdateEvent) {
        guard event.type == .userPushRemove else {
            return
        }

        // expected payload:
        // { "type: "user.push-remove",
        //   "token":
        //    { "transport": "APNS",
        //            "app": "name of the app",
        //          "token": "the token you get from apple"
        //    }
        // }

        // We ignore the payload and remove the local push token
        PushTokenStorage.pushToken = nil
    }

    // MARK: Private

    // MARK: - Properties

    private let registerPushTokenActionHandler: RegisterPushTokenActionHandler
    private let removePushTokenActionHandler: RemovePushTokenActionHandler
    private let getPushTokensActionHandler: GetPushTokensActionHandler
    private let actionSync: EntityActionSync
}
