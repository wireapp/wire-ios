//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireNetwork

// sourcery: AutoMockable
/// Facilitate access to meeting related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol MeetingRepositoryProtocol {

    /// Pulls a meeting from the server and stores it locally.
    /// If the meeting no longer exists on the server, the locally stored copy is deleted.
    ///
    /// - Parameter id: The qualified id of the meeting to pull.

    func pullMeeting(id: WireNetwork.QualifiedID) async throws

    /// Deletes a locally stored meeting without contacting the server.
    ///
    /// - Parameters:
    ///   - id: The id of the meeting to delete.
    ///   - domain: The domain of the meeting to delete.

    func deleteLocalMeeting(id: UUID, domain: String) async

}
