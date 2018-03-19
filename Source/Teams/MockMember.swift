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
import WireDataModel


@objc public final class MockMember: NSManagedObject, EntityNamedProtocol {
    @NSManaged public var team: MockTeam
    @NSManaged public var user: MockUser
    
    @NSManaged private var permissionsRawValue: Int64
    
    public var permissions: Permissions {
        get { return Permissions(rawValue: permissionsRawValue) }
        set { permissionsRawValue = newValue.rawValue }
    }
    
    public static let entityName = "Member"
}


extension MockMember {
    var payload: ZMTransportData {
        let data: [String : Any] = [
            "user": user.identifier,
            "permissions": ["self": NSNumber(value: permissions.rawValue), "copy": 0]
        ]
        return data as NSDictionary
    }
    
    @objc(insertInContext:forUser:inTeam:)
    public static func insert(in context: NSManagedObjectContext, for user: MockUser, in team: MockTeam) -> MockMember {
        let member: MockMember = insert(in: context)
        member.permissions = .member
        member.user = user
        member.team = team
        return member
    }
}
