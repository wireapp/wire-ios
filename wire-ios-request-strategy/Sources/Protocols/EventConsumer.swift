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

@objc
public protocol ZMEventConsumer: NSObjectProtocol {
    /// Process events received either through a live update (websocket / notification / notification stream)
    /// or through history download
    /// @param liveEvents true if the events were received through websocket / notifications / notification stream,
    ///    false if received from history download
    /// @param prefetchResult prefetched conversations and messages that the events belong to, indexed by remote
    /// identifier and
    func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?)

    /// If conforming to these mothods the object strategy will be asked to extract relevant messages (by nonce)
    /// and conversations from the events array. All messages and conversations will be prefetched and
    /// passed to @c processEvents:liveEvents:prefetchResult as last parameter

    @objc
    optional func processEventsWhileInBackground(_ events: [ZMUpdateEvent])

    @objc
    optional func messageNoncesToPrefetch(toProcessEvents events: [ZMUpdateEvent]) -> Set<UUID>

    @objc
    optional func conversationRemoteIdentifiersToPrefetch(toProcessEvents events: [ZMUpdateEvent]) -> Set<UUID>
}

@objc
public protocol ZMEventAsyncConsumer: NSObjectProtocol {
    /// Process events received either through a live update (websocket / notification / notification stream)
    /// or through history download
    func processEvents(_ events: [ZMUpdateEvent]) async
}
