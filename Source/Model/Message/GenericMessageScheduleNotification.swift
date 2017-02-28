//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


public class GenericMessageScheduleNotification: NSObject {

    public static let name = Notification.Name("GenericMessageScheduleNotification")
    let message: ZMGenericMessage
    let conversation: ZMConversation

    public init(message: ZMGenericMessage, conversation: ZMConversation) {
        self.message = message
        self.conversation = conversation
    }

    public func post() {
        NotificationCenter.default.post(name: GenericMessageScheduleNotification.name, object: (message, conversation))
    }
    
}
