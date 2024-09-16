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

// sourcery: AutoMockable
/// Make a direct connection to a server to receive update events.
public protocol PushChannelProtocol {

    /// Open the push channel and start receiving update events.
    ///
    /// - Returns: An async stream of live update event envelopes.

    func open() throws -> AsyncThrowingStream<UpdateEventEnvelope, any Error>

    /// Close the push channel and stop receiving update events.

    func close()

}
