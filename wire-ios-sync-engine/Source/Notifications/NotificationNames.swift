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

extension Notification.Name {

    static let calculateBadgeCount = Self(rawValue: "calculateBadgeCountNotication")

    /// Published before the first event is processed.
    static let eventProcessorDidStartProcessingEventsNotification = Self("EventProcessorDidStartProcessingEvents")

    /// Published after the last event has been processed.
    static let eventProcessorDidFinishProcessingEventsNotification = Self("EventProcessorDidFinishProcessingEvents")
}

public extension Notification.Name {

    static let initialSync = Notification.Name("ZMInitialSyncCompletedNotification")
    static let resyncResources = Notification.Name("resyncResourcesNotificationName")

    internal static let triggerQuickSync = Notification.Name("triggerQuickSync")

}
