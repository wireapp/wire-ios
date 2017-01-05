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


extension ZMConversation: Conversation {

    public var name: String { return displayName }
    
    public var image: Data? {
        guard conversationType == .oneOnOne  else { return nil }
        return (otherActiveParticipants.firstObject as? ZMBareUser)?.imageSmallProfileData
    }
    
    public func appendTextMessage(_ message: String) -> Sendable? {
        return appendMessage(withText: message) as? Sendable
    }
    
    public func appendImage(_ url: URL) -> Sendable? {
        return appendMessageWithImage(at: url) as? Sendable
    }
    
    public func appendImage(_ data: Data) -> Sendable? {
        return appendMessage(withImageData: data) as? Sendable
    }
    
    public func appendFile(_ metaData: ZMFileMetadata) -> Sendable? {
        return appendMessage(with: metaData) as? Sendable
    }
    
    public func appendLocation(_ location: LocationData) -> Sendable? {
        return appendMessage(with: location) as? Sendable
    }

}
