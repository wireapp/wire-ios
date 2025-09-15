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

import Foundation

public enum Locators {

    public enum Buttons {
        public static let next = "Next"
        public static let createAccount = "Create account"
        public static let ok = "OK"
        public static let conversations = "bottomBarRecentListButton"
        public static let settings = "Settings"
        
        
        public static let videoCall = "videoCallBarButton"
        public static let sendMessage = "sendButton"
        public static let backToConversation = "ConversationBackButton"
        public static let conversationHeader = "conversation_title_button"
        public static let conversationDetails = "Conversation Details"
    }

    public enum TextFields {
        public static let emailField = "Email or SSO code"
        public static let enterEmail = "Enter email"
        public static let usernameField = "UsernameField"
        public static let nameFieldValue = "NameField"
        
    }
    
    public enum TextViews {
        public static let messageInput = "inputField"
        public static let message = "Message"
        public static let sender = "author.name"
        
    }
    
    public enum StaticTexts {
        public static let logout = "Log Out"
        public static let emailFieldValue = "EmailField"
        public static let usernameFieldValue = "UsernameField"
        public static let backUpOrRestore = "Back up or RestoreField"
        public static let deleteAccount = "Delete Account"
        
    }

    public enum SecureTextFields {
        public static let enterPassword = "Enter password"
    }

    public enum Cells {
        public static let account = "Account"
    }
}
