//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

/// Delegate steps of LiveSync
/// sourcery: AutoMockable
public protocol LiveSyncDelegate: AnyObject {
    func isUpToDate(sync: IncrementalSyncV2)
    func didMissedEvents(sync: IncrementalSyncV2) async
    func didFail(sync: IncrementalSyncV2, error: any Error)
    func didStart(sync: IncrementalSyncV2)

    func didStartProcessingEvents(sync: IncrementalSyncV2)
    func didFinishProcessingEvents(sync: IncrementalSyncV2)
}
