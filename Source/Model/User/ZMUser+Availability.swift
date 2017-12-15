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

@objc
public enum Availability : Int {
    case none, available, away, busy
}

extension Availability {
    
    public init(_ proto : ZMAvailability) {
        switch proto.type {
        case .NONE:
            self = .none
        case .AVAILABLE:
            self = .available
        case .AWAY:
            self = .away
        case .BUSY:
            self = .busy
        }
    }
    
}

extension ZMUser {
    
    public static func connectionsAndTeamMembers(in context: NSManagedObjectContext) -> Set<ZMUser> {
        var connectionsAndTeamMembers : Set<ZMUser> = Set()
        
        let selfUser = ZMUser.selfUser(in: context)
        let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
        request.predicate = ZMUser.predicateForUsers(withConnectionStatuses: [ZMConnectionStatus.accepted.rawValue])
        
        let connectedUsers = context.fetchOrAssert(request: request)
        connectionsAndTeamMembers.formUnion(connectedUsers)
        
        if let teamUsers = selfUser.team?.members.flatMap({ $0.user }) {
            connectionsAndTeamMembers.formUnion(teamUsers)
        }
        
        return connectionsAndTeamMembers
    }
    
    public var availability : Availability {
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
    
    public func updateAvailability(from genericMessage : ZMGenericMessage) {
        guard let availabilityProtobuffer = genericMessage.availability else { return }
        
        updateAvailability(Availability(availabilityProtobuffer))
    }
    
}
