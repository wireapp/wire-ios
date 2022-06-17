//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

public final class MLSRequestStrategy: AbstractRequestStrategy {

    // MARK: - Properties

    private let entitySync: EntityActionSync

    // MARK: - Life cycle

    public override init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {

        entitySync = EntityActionSync(actionHandlers: [
            ClaimMLSKeyPackageActionHandler(context: managedObjectContext)
        ])

        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )
    }

    // MARK: - Requests

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return entitySync.nextRequest(for: apiVersion)
    }

}
