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
import WireLogging
import WireNetwork

struct UpdateEventProcessor: UpdateEventProcessorProtocol {

    let conversationEventProcessor: any ConversationEventProcessorProtocol
    let featureConfigEventProcessor: any FeatureConfigEventProcessorProtocol
    let federationEventProcessor: any FederationEventProcessorProtocol
    let userEventProcessor: any UserEventProcessorProtocol
    let teamEventProcessor: any TeamEventProcessorProtocol

    func processEvent(_ event: UpdateEvent) async throws {
        WireLogger.eventProcessing.info("process event", attributes: [.eventType: event.name], .safePublic)

        switch event {
        case let .conversation(event):
            try await conversationEventProcessor.processEvent(event)

        case let .featureConfig(event):
            await featureConfigEventProcessor.processEvent(event)

        case let .federation(event):
            try await federationEventProcessor.processEvent(event)

        case let .user(event):
            try await userEventProcessor.processEvent(event)

        case let .team(event):
            try await teamEventProcessor.processEvent(event)

        case let .unknown(event):
            WireLogger.eventProcessing.warn("can not process unknown event: \(event)")
        }
    }

}
