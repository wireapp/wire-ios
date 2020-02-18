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


public struct GenericMessageScheduleNotification {

    private enum UserInfoKey: String {
        case message
        case conversation
    }
    
    private static let name = Notification.Name("GenericMessageScheduleNotification")

    private init() {}
    
    public static func post(message: GenericMessage, conversation: ZMConversation) {
        let userInfo: [String : Any] = [
            UserInfoKey.message.rawValue: message,
            UserInfoKey.conversation.rawValue: conversation
            ]
        NotificationInContext(name: self.name,
                              context: conversation.managedObjectContext!.notificationContext,
                              userInfo: userInfo
        ).post()
    }
    
    public static func addObserver(managedObjectContext: NSManagedObjectContext,
                                using block: @escaping (GenericMessage, ZMConversation)->()) -> Any
    {
        return NotificationInContext.addObserver(name: self.name,
                                                 context: managedObjectContext.notificationContext)
        { note in
            guard let message = note.userInfo[UserInfoKey.message.rawValue] as? GenericMessage,
                let conversation = note.userInfo[UserInfoKey.conversation.rawValue] as? ZMConversation
                else { return }
            block(message, conversation)
        }
    }
}
