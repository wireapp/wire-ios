//
//  MockAction.swift
//  WireMockTransport
//
//  Created by Katerina on 06.12.19.
//  Copyright © 2019 Zeta Project. All rights reserved.
//

import Foundation
import CoreData

@objc public final class MockAction: NSManagedObject, EntityNamedProtocol {
    @NSManaged public var name: String
    @NSManaged public var roles: Set<MockRole>
    
    public static var entityName = "Action"
}

extension MockAction {
    @objc
    public static func insert(in context: NSManagedObjectContext, name: String) -> MockAction {
        let action: MockAction = insert(in: context)
        action.name = name
        
        return action
    }
    
    var payload: ZMTransportData {
        return name as NSString
    }
}

