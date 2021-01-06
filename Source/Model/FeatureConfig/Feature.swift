//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

private let zmLog = ZMSLog(tag: "Feature")

@objcMembers
public class Feature: ZMManagedObject {

    // MARK: - Types

    // IMPORTANT
    //
    // Only add new cases to these enums. Deleting or modifying the raw values
    // of these cases may lead to a corrupt database.

    public enum Name: String, Codable, CaseIterable {
        case appLock
    }

    public enum Status: String, Codable {
        case enabled
        case disabled
    }

    // MARK: - Properties

    @NSManaged private var nameValue: String
    @NSManaged private var statusValue: String
    @NSManaged private var configData: Data?
    @NSManaged public var needsToNotifyUser: Bool

    @NSManaged public var team: Team?
    
    public var config: Data? {
        get {
            return configData
        }
        set {
            updateNeedsToNotifyUser(oldData: configData, newData: newValue)
            configData = newValue
        }
    }
    
    public var name: Name {
        get {
            guard let name = Name(rawValue: nameValue) else {
                fatalError("Failed to decode nameValue: \(nameValue)")
            }

            return name
        }

        set {
            nameValue = newValue.rawValue
        }
    }
    
    public var status: Status {
        get {
            guard let status = Status(rawValue: statusValue) else {
                fatalError("Failed to decode statusValue: \(statusValue)")
            }

            return status
        }
        set {
            statusValue = newValue.rawValue
        }
    }

    // MARK: - Methods
    
    public override static func entityName() -> String {
        return "Feature"
    }

    public override static func sortKey() -> String {
        return #keyPath(Feature.nameValue)
    }

    @discardableResult
    public static func fetch(name: Name,
                             context: NSManagedObjectContext) -> Feature? {
        
        let fetchRequest = NSFetchRequest<Feature>(entityName: Feature.entityName())
        fetchRequest.predicate = NSPredicate(format: "nameValue == %@", name.rawValue)
        fetchRequest.fetchLimit = 2

        let results = context.fetchOrAssert(request: fetchRequest)
        require(results.count <= 1, "More than instance for feature: \(name.rawValue)")
        return results.first
    }
    
    // Fetch or create the default feature
    static func fetchOrCreate(name: Name,
                              team: Team,
                              context: NSManagedObjectContext) -> Feature {
        
        let fetchRequest = NSFetchRequest<Feature>(entityName: Feature.entityName())
        fetchRequest.predicate = NSPredicate(format: "nameValue == %@", name.rawValue)
        fetchRequest.fetchLimit = 2
        
        let results = context.fetchOrAssert(request: fetchRequest)
        require(results.count <= 1, "More than one instance for feature: \(name.rawValue)")
        guard let feature = results.first else {
            switch name {
            case .appLock:
                let defaultInstance = Feature.AppLock()
                guard let defaultConfigData = try? JSONEncoder().encode(defaultInstance.config) else {
                    fatalError("Failed to encode default config for: \(name)")
                }

                let feature = insert(name: name,
                                     status: defaultInstance.status,
                                     config: defaultConfigData,
                                     team: team,
                                     context: context)
                return feature
            }
        }
        return feature
    }

    @discardableResult
    public static func createOrUpdate(name: Name,
                                      status: Status,
                                      config: Data?,
                                      team: Team,
                                      context: NSManagedObjectContext) -> Feature {
        if let existing = fetch(name: name, context: context) {
            existing.status = status
            existing.config = config
            existing.team = team
            existing.needsToBeUpdatedFromBackend = false
            return existing
        }
        
        let feature = insert(name: name,
                             status: status,
                             config: config,
                             team: team,
                             context: context)
        return feature
    }
    
    @discardableResult
    public static func insert(name: Name,
                              status: Status,
                              config: Data?,
                              team: Team,
                              context: NSManagedObjectContext) -> Feature {
        let feature = Feature.insertNewObject(in: context)
        feature.name = name
        feature.status = status
        feature.config = config
        feature.team = team
        return feature
    }

    public func updateNeedsToNotifyUser(oldData: Data?, newData: Data?) {
        switch name {
        case .appLock:
            guard !needsToNotifyUser else { return }
            
            let decoder = JSONDecoder()
            guard let oldValue = oldData,
                let newValue = newData,
                let oldConfig = try? decoder.decode(Feature.AppLock.Config.self, from: oldValue),
                let newConfig = try? decoder.decode(Feature.AppLock.Config.self, from: newValue) else {
                    return
            }
            needsToNotifyUser = oldConfig.enforceAppLock != newConfig.enforceAppLock
        }
    }
}
