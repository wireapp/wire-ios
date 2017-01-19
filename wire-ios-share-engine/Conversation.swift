//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import ZMCDataModel

/// A conversation
public protocol Conversation : SharingTarget {
    
    /// User defined name for a group conversation, or standard name
    var name : String { get }
    
    /// Type of the conversation
    var conversationType : ZMConversationType { get }
    
    /// Image associated with conversation
    /// E.g. will be nil for group conversation and will 
    /// be user's image for one-to-one
    var image : Data? { get }
    
    /// Returns true if the conversation is trusted (all participants are trusted)
    var isTrusted : Bool { get }
    
    /// Adds an observer for when the conversation verification status degrades
    func add(conversationVerificationDegradedObserver: @escaping (ConversationDegradationInfo)->()) -> TearDownCapable
    
    /// Resends all those messages that caused conversation security degradation
    func resendMessagesThatCausedConversationSecurityDegradation()
    
    /// Do not resend all those messages that caused conversation security degradation
    func doNotResendMessagesThatCausedDegradation()
}


/// Object that can be torn down when not needed anymore
public protocol TearDownCapable {
    
    func tearDown()
    
}
