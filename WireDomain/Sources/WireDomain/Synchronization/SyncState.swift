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

/// Describes the current syncing state of the app.

public enum SyncState: Equatable {

    /// The app is not syncing.

    case idle

    /// Initial sync is ongoing.

    case initialSyncing(InitialSyncState)

    /// Incremental sync is ongoing.

    case incrementalSyncing(IncrementalSyncState)

    /// App is up to date and processing live events.

    case liveSyncing(LiveSyncState)

    /// Sync was suspended

    case suspended

    public enum InitialSyncState: Equatable {

        case pullLastEventID
        case pullResources
        case pushSupportedProtocols
        case resolveOneOnOneConversations

    }

    public enum IncrementalSyncState: Equatable {

        case createPushChannel
        case openPushChannel
        case pullPendingEvents
        case processPendingEvents
        case receivingLiveEvents // with consumable-notifications sync system (IncrementalSyncV2), we don't do
        // pullPendingEvents, the pushChannel is open
        // and events are received until we're up to date come from the websocket.

    }

    public enum LiveSyncState: Equatable {
        case ongoing
        case finished
    }

}
