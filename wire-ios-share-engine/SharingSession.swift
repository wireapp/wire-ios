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

/// A Wire session to share content from a share extension
/// - note: this is the entry point of this framework. Users of 
/// the framework should create an instance as soon as possible in
/// the lifetime of the extension, and hold on to that session
/// for the entire lifetime.
/// - warning: creating multiple sessions in the same process
/// is not supported and will result in undefined behaviour
public class SharingSession {
    
    /// List of non-archived conversations in which the user can write
    /// The list will be sorted by relevance
    var writeableNonArchivedConversations : [Conversation] {
        // TODO
        return []
    }
    
    /// List of archived conversations in which the user can write
    var writebleArchivedConversations : [Conversation] {
        // TODO
        return []
    }
    
    /// Cancel all pending tasks.
    /// Should be called when the extension is dismissed
    func cancelAllPendingTasks() {
        // TODO
    }
    
    init() {
        // TODO
    }
}
