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
import WireAPI

extension ZMOperationLoop: ZMPushChannelConsumer {

    public func pushChannelDidReceive(_ data: Data) {
        if isDeveloperModeEnabled {
            // TODO: [WPB-9612] remove event decoding monitoring.
            // Since update event models aren't documented, we aren't yet completely sure
            // that the new type-safe UpdateEvent model can successfully decode all event
            // types. To test correctness, we try to decode every update event received
            // through the push channel and simply log when it fails so we know how to
            // fix it. Once we're sure it works, we should remove this.
            do {
                let decoder = JSONDecoder.defaultDecoder
                _ = try decoder.decode(UpdateEventEnvelope.self, from: data)
            } catch {
                WireLogger.updateEvent.error("failed to decode 'UpdateEventEnvelope': \(error)")
            }
        }

        guard let transportData = try? JSONSerialization.jsonObject(
            with: data,
            options: []
        ) as? ZMTransportData else {
            WireLogger.updateEvent.error("failed to deserialize push channel data")
            return
        }

        if let events = ZMUpdateEvent.eventsArray(fromPushChannelData: transportData), !events.isEmpty {
            WireLogger.eventProcessing.info("Received \(events.count) events from push channel")
            events.forEach {
                WireLogger.updateEvent.info("received event", attributes: $0.logAttributes(source: .pushChannel))
                $0.appendDebugInformation("from push channel (web socket)")
            }

            if syncStatus.isSyncing {
                WaitingGroupTask(context: syncMOC) {
                    await self.updateEventProcessor.bufferEvents(events)
                }
            } else {
                WaitingGroupTask(context: syncMOC) {
                    do {
                        try await self.updateEventProcessor.processEvents(events)
                    } catch {
                        events.forEach {
                            WireLogger.updateEvent.error("Failed to process event from push channel (web socket)", attributes: $0.logAttributes(source: .pushChannel))
                        }
                    }
                }
            }
        }
    }

    public func pushChannelDidClose() {
        NotificationInContext(name: ZMOperationLoop.pushChannelStateChangeNotificationName,
                              context: syncMOC.notificationContext,
                              object: self,
                              userInfo: [ ZMPushChannelIsOpenKey: false]).post()

        syncStatus.pushChannelDidClose()
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

    public func pushChannelDidOpen() {
        NotificationInContext(name: ZMOperationLoop.pushChannelStateChangeNotificationName,
                              context: syncMOC.notificationContext,
                              object: self,
                              userInfo: [ ZMPushChannelIsOpenKey: true]).post()

        syncStatus.pushChannelDidOpen()
        RequestAvailableNotification.notifyNewRequestsAvailable(nil)
    }

}
