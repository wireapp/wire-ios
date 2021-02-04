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


    /// Fetch the instance for the given name.
    ///
    /// If more than one instance is found, this method will crash.
    ///
    /// - Parameters:
    ///     - name: The name of the feature to fetch.
    ///     - context: The context in which to fetch the instance.
    ///
    /// - Returns: An instance, if it exists, otherwise `nil`.

    public static func fetch(name: Name,
                             context: NSManagedObjectContext) -> Feature? {

        let fetchRequest = NSFetchRequest<Feature>(entityName: Feature.entityName())
        fetchRequest.predicate = NSPredicate(format: "nameValue == %@", name.rawValue)
        fetchRequest.fetchLimit = 2

        let results = context.fetchOrAssert(request: fetchRequest)
        require(results.count <= 1, "More than instance for feature: \(name.rawValue)")
        return results.first
    }

    /// Update the feature instance with the given name.
    ///
    /// - Parameters:
    ///     - name: The name of the feature to update.
    ///     - context: The context in which to fetch the instance.
    ///     - changes: A closure to mutate the fetched instance.

    public static func update(havingName name: Name,
                              in context: NSManagedObjectContext,
                              changes: (Feature) -> Void) {

        guard let existing = fetch(name: name, context: context) else { return }
        changes(existing)
    }
    
    /// Creates the default instance for the given feature name, if none already exists.
    ///
    /// The **context is expected to be the sync context**, otherwise the method will
    /// crash.
    ///
    /// - Parameters:
    ///     - name: The name of the feature to create.
    ///     - team: The team which the feature is associated to.
    ///     - context: The context in which to create the instance.

    public static func createDefaultInstanceIfNeeded(name: Name,
                                                     team: Team,
                                                     context: NSManagedObjectContext) {

        guard fetch(name: name, context: context) == nil else { return }

        switch name {
        case .appLock:
            let defaultInstance = Feature.AppLock()

            guard let defaultConfigData = try? JSONEncoder().encode(defaultInstance.config) else {
                fatalError("Failed to encode default config for: \(name)")
            }

            insert(name: name,
                   status: defaultInstance.status,
                   config: defaultConfigData,
                   team: team,
                   context: context)
        }
    }

    private static func insert(name: Name,
                               status: Status,
                               config: Data?,
                               team: Team,
                               context: NSManagedObjectContext) {

        // There should be at most one instance per feature, so only allow inserting
        // on a single context to avoid race conditions.
        assert(context.zm_isSyncContext, "Can only insert `Feature` instance on the sync context")

        let feature = Feature.insertNewObject(in: context)
        feature.name = name
        feature.status = status
        feature.config = config
        feature.team = team
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
