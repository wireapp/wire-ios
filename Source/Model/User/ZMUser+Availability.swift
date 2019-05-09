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


import Foundation

@objc public enum Availability : Int, CaseIterable {
    case none, available, busy, away
}

extension Availability {
    
    public init(_ proto : ZMAvailability) {
        ///TODO: change ZMAvailabilityType to NS_CLOSED_ENUM
        switch proto.type {
        case .NONE:
            self = .none
        case .AVAILABLE:
            self = .available
        case .AWAY:
            self = .away
        case .BUSY:
            self = .busy
        @unknown default:
            self = .none
        }
    }

}

/// Describes how the user should be notified about a change.
public struct NotificationMethod: OptionSet {
    
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Alert user by local notification
    public static let notification = NotificationMethod(rawValue: 1 << 0)
    /// Alert user by alert dialogue
    public static let alert = NotificationMethod(rawValue: 1 << 1)
    
    public static let all: NotificationMethod = [.notification, .alert]
    
}

extension ZMUser {
    
    @objc public static func connectionsAndTeamMembers(in context: NSManagedObjectContext) -> Set<ZMUser> {
        var connectionsAndTeamMembers : Set<ZMUser> = Set()
        
        let selfUser = ZMUser.selfUser(in: context)
        let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
        request.predicate = ZMUser.predicateForUsers(withConnectionStatuses: [ZMConnectionStatus.accepted.rawValue])
        
        let connectedUsers = context.fetchOrAssert(request: request)
        connectionsAndTeamMembers.formUnion(connectedUsers)
        
        if let teamUsers = selfUser.team?.members.compactMap({ $0.user }) {
            connectionsAndTeamMembers.formUnion(teamUsers)
        }
        
        return connectionsAndTeamMembers
    }
    
    @objc public var availability : Availability {
        get {
            self.willAccessValue(forKey: AvailabilityKey)
            let value = (self.primitiveValue(forKey: AvailabilityKey) as? NSNumber) ?? NSNumber(value: 0)
            self.didAccessValue(forKey: AvailabilityKey)
            
            return Availability(rawValue: value.intValue) ?? .none
        }
        
        set {
            guard isSelfUser else { return } // TODO move this setter to ZMEditableUser
            
            updateAvailability(newValue)
        }
    }
    
    internal func updateAvailability(_ newValue : Availability) {
        self.willChangeValue(forKey: AvailabilityKey)
        self.setPrimitiveValue(NSNumber(value: newValue.rawValue), forKey: AvailabilityKey)
        self.didChangeValue(forKey: AvailabilityKey)
    }
    
    @objc public func updateAvailability(from genericMessage : ZMGenericMessage) {
        guard let availabilityProtobuffer = genericMessage.availability else { return }
        
        updateAvailability(Availability(availabilityProtobuffer))
    }
    
    private static let needsToNotifyAvailabilityBehaviourChangeKey = "needsToNotifyAvailabilityBehaviourChange"
    
    /// Returns an option set describing how we should notify the user about the change in behaviour for the availability feature
    public var needsToNotifyAvailabilityBehaviourChange: NotificationMethod {
        get {
            guard let rawValue = managedObjectContext?.persistentStoreMetadata(forKey: type(of: self).needsToNotifyAvailabilityBehaviourChangeKey) as? Int else { return [] }
            
            return NotificationMethod(rawValue: rawValue)
        }
        set {
            managedObjectContext?.setPersistentStoreMetadata(newValue.rawValue, key: type(of: self).needsToNotifyAvailabilityBehaviourChangeKey)
        }
    }
    
}
