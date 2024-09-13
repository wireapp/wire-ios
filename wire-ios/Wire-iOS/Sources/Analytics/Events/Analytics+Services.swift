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
import WireDataModel

// swiftlint:disable:next todo_requires_jira_link
// TODO: move to DM
extension ZMConversation {
    fileprivate var otherNonServiceParticipants: [UserType] {
        let users = Array(localParticipants)
        return users.filter { !$0.isServiceUser }
    }
}

struct ServiceAddedEvent: Event {
    enum Keys {
        static let serviceID = "service_id"
        static let conversationSize = "conversation_size"
        static let servicesSize = "services_size"
        static let methods = "methods"
    }

    enum Context: String {
        case startUI = "start_ui"
        case conversationDetails = "conversation_details"
    }

    private let conversationSize, servicesSize: Int
    private let serviceIdentifier: String
    private let context: Context

    init(service: ServiceUser, conversation: ZMConversation, context: Context) {
        self.serviceIdentifier = service.serviceIdentifier ?? ""
        self.conversationSize = conversation.otherNonServiceParticipants.count // Without service users
        self.servicesSize = conversation.localParticipants.count - conversationSize
        self.context = context
    }

    var name: String {
        "integration.added_service"
    }

    var attributes: [AnyHashable: Any]? {
        [
            Keys.serviceID: serviceIdentifier,
            Keys.conversationSize: conversationSize,
            Keys.servicesSize: servicesSize,
            Keys.methods: context.rawValue,
        ]
    }
}

struct ServiceRemovedEvent: Event {
    enum Keys {
        static let serviceID = "service_id"
    }

    private let serviceIdentifier: String

    init(service: ServiceUser) {
        self.serviceIdentifier = service.serviceIdentifier ?? ""
    }

    var name: String {
        "integration.removed_service"
    }

    var attributes: [AnyHashable: Any]? {
        [Keys.serviceID: serviceIdentifier]
    }
}

extension Analytics {
    @objc
    func tagDidRemoveService(_ serviceUser: ServiceUser) {
        tag(ServiceRemovedEvent(service: serviceUser))
    }
}
