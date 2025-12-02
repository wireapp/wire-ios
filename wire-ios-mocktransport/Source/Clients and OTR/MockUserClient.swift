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

import CoreData
import Foundation

@objc
public class MockUserClient: NSManagedObject {

    /// User that owns the client
    @NSManaged public var user: MockUser?

    /// Remote identifier
    @NSManaged public var identifier: String?

    /// Device label
    @NSManaged public var label: String?

    /// Device type
    @NSManaged public var type: String?

    /// IP address of registration
    @NSManaged public var address: String?

    /// Device class
    @NSManaged public var deviceClass: String?

    /// Registration location latitude
    @NSManaged public var locationLatitude: Double

    /// Registration location longitude
    @NSManaged public var locationLongitude: Double

    /// Device model
    @NSManaged public var model: String?

    /// Time of registration
    @NSManaged public var time: Date?

    /// Encryption key for APS signalling
    @NSManaged public var enckey: String?

    /// Hashing key for APS signalling
    @NSManaged public var mackey: String?

    /// Prekeys registered for this client
    @NSManaged public var prekeys: Set<MockPreKey>

    /// Last prekeys registered for this client
    @NSManaged public var lastPrekey: MockPreKey

}

public extension MockUserClient {

    /// Returns a fetch request to fetch MockUserClients with the given predicate
    @objc
    static func fetchRequest(predicate: NSPredicate) -> NSFetchRequest<MockUserClient> {
        let request = NSFetchRequest<MockUserClient>(entityName: "UserClient")
        request.predicate = predicate
        return request
    }
}

// MARK: - Legal Hold

public extension MockUserClient {

    var isLegalHoldDevice: Bool {
        type == "legalhold" || deviceClass == "legalhold"
    }

}

// MARK: - JSON de/serialization

@objc
public extension MockUserClient {

    /// Creates a new client from JSON payload
    static func insertClient(payload: [String: Any], context: NSManagedObjectContext) -> MockUserClient? {

        let label = payload["label"] as? String
        let deviceClass = payload["class"] as? String
        let model = payload["model"] as? String

        guard let type = payload["type"] as? String, validClientTypes.contains(type),
              let sigkeysPayload = payload["sigkeys"] as? [String: Any],
              let lastKeyPayload = payload["lastkey"] as? [String: Any],
              let prekeysPayload = payload["prekeys"] as? [[String: Any]],
              let mackey = sigkeysPayload["mackey"] as? String,
              let enckey = sigkeysPayload["enckey"] as? String,
              let prekeyNumber = lastKeyPayload["id"] as? Int, prekeyNumber == 0xFFFF
        else {
            return nil
        }

        let newClient = NSEntityDescription.insertNewObject(
            forEntityName: "UserClient",
            into: context
        ) as! MockUserClient
        newClient.label = label
        newClient.type = type
        newClient.identifier = String.randomClientIdentifier()
        newClient.mackey = mackey
        newClient.enckey = enckey
        newClient.deviceClass = deviceClass
        newClient.model = model
        newClient.locationLatitude = 52.5167
        newClient.locationLongitude = 13.3833
        newClient.address = "62.96.148.44"
        newClient.time = Date()

        let prekeys = MockPreKey.insertNewKeys(withPayload: prekeysPayload, context: context)
        prekeys.forEach {
            $0.client = newClient
        }

        let lastPreKey = MockPreKey.insertNewKey(withPayload: lastKeyPayload, context: context)!
        lastPreKey.client = newClient

        newClient.prekeys = prekeys
        newClient.lastPrekey = lastPreKey

        return newClient
    }

    /// Insert a new client, automatically generate prekeys and last key
    @objc(insertClientWithLabel:type:deviceClass:user:context:)
    static func insertClient(
        label: String,
        type: String = "permanent",
        deviceClass: String = "phone",
        for user: MockUser,
        in context: NSManagedObjectContext
    ) -> MockUserClient? {
        let newClient = NSEntityDescription.insertNewObject(
            forEntityName: "UserClient",
            into: context
        ) as! MockUserClient

        newClient.user = user
        newClient.identifier = String.randomClientIdentifier()
        newClient.label = label
        newClient.type = type
        newClient.deviceClass = deviceClass
        newClient.time = Date()

        // Generate mock prekey strings (no encryption needed for mock transport)
        let mockPrekeys = (0..<5).map { _ in UUID().uuidString }
        let mockLastPrekey = UUID().uuidString

        let prekeys = MockPreKey.insertNewKeys(
            withPayload: mockPrekeys,
            context: context
        )
        newClient.prekeys = Set(prekeys)

        let lastPrekey = MockPreKey.insertNewKey(withPrekey: mockLastPrekey, for: newClient, in: context)
        lastPrekey.identifier = Int(UInt16.max)
        newClient.lastPrekey = lastPrekey

        return newClient
    }

    /// JSON representation
    var transportData: ZMTransportData {

        var data = [String: Any]()
        data["id"] = identifier
        if label != nil {
            data["label"] = label
        }
        data["type"] = type
        if let time {
            data["time"] = time.transportString()
        }
        if let model {
            data["model"] = model
        }
        if let device = deviceClass {
            data["class"] = device
        }
        data["address"] = address
        data["location"] = [
            "lat": locationLatitude,
            "lon": locationLongitude
        ]
        return data as NSDictionary
    }
}

/// Allowed client types
private let validClientTypes = Set(["temporary", "permanent", "legalhold"])
