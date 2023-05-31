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

/// Fetches the metadata of a single conversation and stores it locally
/// in the database.

final class SyncConversationAction: EntityAction {

    typealias Result = Void

    enum Failure: Error, Equatable {

        case malformedRequestPayload
        case invalidBody
        case invalidResponsePayload
        case conversationNotFound
        case unknownError(code: Int, label: String, message: String)

    }

    // MARK: - Properties

    let qualifiedID: QualifiedID
    var resultHandler: ResultHandler?

    // MARK: - Life cycle

    init(
        qualifiedID: QualifiedID,
        resultHandler: ResultHandler? = nil
    ) {
        self.qualifiedID = qualifiedID
        self.resultHandler = resultHandler
    }

}
