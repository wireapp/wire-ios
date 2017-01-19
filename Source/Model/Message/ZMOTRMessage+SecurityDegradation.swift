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

extension ZMOTRMessage {
    
    /// Whether the message caused security level degradation (from verified to unverified)
    /// in this user session (i.e. since the app was started. This will be kept in memory
    /// and not persisted). This flag can be set only from the sync context. It can be read
    /// from any context.
    override public var causedSecurityLevelDegradation : Bool {
        get {
            return self.managedObjectContext?.messagesThatCausedSecurityLevelDegradation.contains(self.objectID) ?? false
        }
        set {
            guard let moc = self.managedObjectContext else { return }
            guard moc.zm_isSyncContext else { fatal("Cannot set security level on non-sync moc") }
            if self.objectID.isTemporaryID {
                try! moc.obtainPermanentIDs(for: [self])
            }
            var set = moc.messagesThatCausedSecurityLevelDegradation
            if newValue {
                set.insert(self.objectID)
            } else {
                set.remove(self.objectID)
            }
            moc.messagesThatCausedSecurityLevelDegradation = set
        }
    }
    
}

private let messagesThatCausedSecurityLevelDegradationKey = "ZM_messagesThatCausedSecurityLevelDegradation"

extension NSManagedObjectContext {
    
    /// Non-persisted list of messages that caused security level degradation
    fileprivate(set) var messagesThatCausedSecurityLevelDegradation : Set<NSManagedObjectID> {
        get {
            return self.userInfo[messagesThatCausedSecurityLevelDegradationKey] as? Set<NSManagedObjectID> ?? Set<NSManagedObjectID>()
        }
        set {
            self.userInfo[messagesThatCausedSecurityLevelDegradationKey] = newValue
        }
    }
    
    /// Merge list of messages that caused security level degradation from one message to another
    func mergeSecurityLevelDegradationInfo(fromUserInfo userInfo: [String: Any]) {
        guard self.zm_isUserInterfaceContext else { return } // we don't merge anything to sync, sync is autoritative
        self.messagesThatCausedSecurityLevelDegradation = userInfo[messagesThatCausedSecurityLevelDegradationKey] as? Set<NSManagedObjectID> ?? Set<NSManagedObjectID>()
    }
    
}
