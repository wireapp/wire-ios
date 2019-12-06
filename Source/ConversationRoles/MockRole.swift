//
//  MockRole.swift
//  WireMockTransport
//
//  Created by Katerina on 06.12.19.
//  Copyright © 2019 Zeta Project. All rights reserved.
//

import Foundation
import CoreData

@objc public final class MockRole: NSManagedObject, EntityNamedProtocol {
    @NSManaged public var name: String
    @NSManaged public var actions: Set<MockAction>
    @NSManaged public var team: MockTeam
    
    public static var entityName = "Role"
}

extension MockRole {
    @objc
    public static func insert(in context: NSManagedObjectContext, name: String, actions: Set<MockAction>) -> MockRole {
        let role: MockRole = insert(in: context)
        role.name = name
        role.actions = actions
        
        return role
    }
    
    var payloadValues: [String : Any?] {
        return [
            "conversation_role" : name,
            "actions" : actions.map({$0.payload})
        ]
    }
    
    var payload: ZMTransportData {
        return payloadValues as NSDictionary
    }
}
